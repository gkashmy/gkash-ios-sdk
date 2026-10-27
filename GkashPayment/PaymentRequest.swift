//
//  PaymentRequest.swift
//  GkashPayment
//
//  Created by Gkash on 05/09/2022.
//

import CommonCrypto
import Foundation

public class PaymentRequest{
  public var walletScheme : [String] = ["apaylater://app.apaylater.com",
                                        "stage-onlinepayment.boostorium.com",
                                        "sarawakpay://",
                                        "weixin://"]
  public let prodWalletScheme : [String] = ["apaylater://app.apaylater.com",
                                            "stage-onlinepayment.boostorium.com",
                                            "sarawakpay://",
                                            "weixin://"]
  public var HOST_URL : String = "https://api-staging.pay.asia"
  public let version: String = "1.5.0"
  public var cid: String = ""
  public var signatureKey: String = ""
  public let currency: String = "MYR"
  public var amount: String = ""
  public var cartId: String = ""
  public var callbackUrl: String = ""
  public var email: String = ""
  public var mobileNo: String = ""
  public var firstName: String = ""
  public var lastName: String = ""
  public var productDescription: String = ""
  public var billingStreet: String = ""
  public var billingPostCode: String = ""
  public var billingCity: String = ""
  public var billingState: String = ""
  public var billingCountry: String = ""
  public var returnUrl: String = ""
  public var isProd:Bool = false
  //set recurringType (eg: MONTHLY) to bind the card for future charges
  public var recurringType: String = ""
  //epKey returned from a bind payment, used to charge the bound card
  public var epKey: String = ""
  //set to true to charge the bound card host to host without showing the payment page
  public var hostToHost: Bool = false
  public var callback: TransStatusCallback? = nil
  private var hostToHostSubmitted: Bool = false
  public init(){}
    public init(cid: String = "", signatureKey: String = "", amount: String = "", cartId: String = "", isProd: Bool = false,
                returnUrl: String = "", callback : TransStatusCallback?, callbackUrl: String = "",
                recurringType: String = "", epKey: String = "", hostToHost: Bool = false){
    self.cid = cid
    self.signatureKey = signatureKey
    self.amount = amount
    self.cartId = cartId
    self.callback = callback
    if(returnUrl == ""){
      self.returnUrl = "gkash://returntoapp"
    }else{
      self.returnUrl = returnUrl
    }
    self.callbackUrl = callbackUrl
    self.recurringType = recurringType
    self.epKey = epKey
    self.hostToHost = hostToHost
    self.isProd = isProd
    if(isProd){
      self.HOST_URL = "https://api.gkash.my"
      walletScheme = prodWalletScheme
    }
    walletScheme.append(self.returnUrl)
  }
  public func generateSignature() -> String {
    let amount : String = formattedAmount().replacingOccurrences(of: ".", with: "")
    let sign : String = (signatureKey + ";" + cid + ";" + cartId + ";" +
              amount + ";" + currency).uppercased()
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    if let data = sign.data(using: String.Encoding.utf8) {
      let value = data as NSData
      CC_SHA512(value.bytes, CC_LONG(data.count), &digest)
    }
    var digestHex = ""
    for index in 0..<Int(CC_SHA512_DIGEST_LENGTH) {
      digestHex += String(format: "%02x", digest[index])
    }
    return digestHex
  }

  private func formattedAmount() -> String {
    return String(format: "%.2f", Double(amount) ?? 0)
  }

  //x-www-form-urlencoded body for both the payment page and host to host submit
  func formBody() -> Data {
    let params : [(String, String)] = [
      ("version", version),
      ("CID", cid),
      ("v_currency", currency),
      ("v_amount", formattedAmount()),
      ("v_cartid", cartId),
      ("v_firstname", firstName),
      ("v_lastname", lastName),
      ("v_billemail", email),
      ("v_billstreet", billingStreet),
      ("v_billpost", billingPostCode),
      ("v_billcity", billingCity),
      ("v_billstate", billingState),
      ("v_billcountry", billingCountry),
      ("v_billphone", mobileNo),
      ("returnurl", returnUrl),
      ("callbackurl", callbackUrl),
      ("v_productdesc", productDescription),
      ("recurringtype", recurringType),
      ("epkey", epKey),
      ("signature", generateSignature()),
    ]
    let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._*")
    let body = params.map { name, value in
      name + "=" + (value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")
    }.joined(separator: "&")
    return Data(body.utf8)
  }

  //Host to host returns JSON instead of a payment page, so post it directly
  func submitHostToHost(){
    if(hostToHostSubmitted){
      return
    }
    hostToHostSubmitted = true
    var urlRequest : URLRequest = URLRequest(url: URL(string: HOST_URL + "/api/payment/submit")!)
    urlRequest.httpMethod = "POST"
    urlRequest.timeoutInterval = 60
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    urlRequest.httpBody = formBody()
    URLSession.shared.dataTask(with: urlRequest) { data, response, error in
      if let error = error {
        print("Host to host error: " + error.localizedDescription)
      }
      DispatchQueue.main.async {
        self.HostToHostStatusCallback(data: data)
      }
    }.resume()
  }

  private func HostToHostStatusCallback(data : Data?){
    guard let data = data,
          let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
      print("Host to host response is not valid JSON")
      let resp : PaymentResponse = PaymentResponse(Status: "Request failed", Amount: formattedAmount(), CartId: cartId,
                                                   Description: data == nil ? "Unable to reach payment server" : "Invalid response from payment server",
                                                   Currency: currency, CID: cid, EpKey: epKey)
      callback?.getStatus(response: resp)
      return
    }
    var params : [String: String] = [:]
    for (key, value) in json where !(value is NSNull) {
      params[key] = "\(value)"
    }
    DeliverStatus(params: params)
  }

public func StatusCallback(url : URL){
    print("MyWebView :" + url.absoluteString)
    var params : [String: String] = [:]
    for item in URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [] {
      params[item.name] = item.value ?? ""
    }
    DeliverStatus(params: params)
}

private func DeliverStatus(params : [String: String]){
    let status : String = (params["status"] ?? "Unknown status").replacingOccurrences(of: "+", with: " ")
    let description : String = (params["description"] ?? "").replacingOccurrences(of: "+", with: " ")
    let PaymentType : String = (params["PaymentType"] ?? "").replacingOccurrences(of: "+", with: " ")
    let resp : PaymentResponse = PaymentResponse(Status: status, Amount: params["amount"] ?? "", CartId: params["cartid"] ?? "",
                                                 Description: description, Currency: params["currency"] ?? "", POID: params["POID"] ?? "",
                                                 CID: params["CID"] ?? "", PaymentType: PaymentType, EpKey: params["epkey"] ?? "")
    if(!resp.validateSignature(signature: params["signature"] ?? "", request: self)){
      resp.status = "11 - Pending"
      resp.description = "Invalid Signature"
    }
    callback?.getStatus(response: resp)
}
}

public protocol TransStatusCallback {
    func getStatus(response : PaymentResponse) -> Void
}
