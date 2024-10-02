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
                  "uat.shopee.com.my/"]
  public let prodWalletScheme : [String] = ["apaylater://app.apaylater.com",
                     "stage-onlinepayment.boostorium.com",
                     "uat.shopee.com.my/"]
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
  public var callback: TransStatusCallback? = nil
  public init(){}
    public init(cid: String = "", signatureKey: String = "", amount: String = "", cartId: String = "", isProd: Bool = false, 
                returnUrl: String = "", callback : TransStatusCallback?, callbackUrl: String = ""){
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
    self.isProd = isProd
    if(isProd){
      self.HOST_URL = "https://api.gkash.my"
      walletScheme = prodWalletScheme
    }
    walletScheme.append(self.returnUrl)
  }
  public func generateSignature() -> String {
    let doubleAmount : Double? = Double(amount)
    let amount : String = String(format: "%.2f", doubleAmount!).replacingOccurrences(of: ".", with: "")
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
    
public func StatusCallback(url : URL){
    print("MyWebView :" + url.absoluteString)
    var status : String = getQueryStringParameter(url: url.absoluteString, param: "status") ?? "Unknown status"
    status = status.replacingOccurrences(of: "+", with: " ")
    let description : String = getQueryStringParameter(url: url.absoluteString, param: "description") ?? ""
    let CID : String = getQueryStringParameter(url: url.absoluteString, param: "CID") ?? ""
    let POID : String = getQueryStringParameter(url: url.absoluteString, param: "POID") ?? ""
    let cartid : String = getQueryStringParameter(url: url.absoluteString, param: "cartid") ?? ""
    let amount : String = getQueryStringParameter(url: url.absoluteString, param: "amount") ?? ""
    let currency : String = getQueryStringParameter(url: url.absoluteString, param: "currency") ?? ""
    var PaymentType : String = getQueryStringParameter(url: url.absoluteString, param: "PaymentType") ?? ""
    PaymentType = PaymentType.replacingOccurrences(of: "+", with: " ")
    let signature : String = getQueryStringParameter(url: url.absoluteString, param: "signature") ?? ""
    let resp : PaymentResponse = PaymentResponse(Status: status, Amount: amount, CartId: cartid, Description: description, Currency: currency, POID: POID, CID: CID, PaymentType: PaymentType)
    if(resp.validateSignature(signature: signature, request: self)){
      callback!.getStatus(response: resp)
    }else{
      resp.status = "11 - Pending"
      resp.description = "Invalid Signature"
      callback!.getStatus(response: resp)
    }
}
        
private func getQueryStringParameter(url: String, param: String) -> String? {
   guard let url = URLComponents(string: url) else { return nil }
   return url.queryItems?.first(where: { $0.name == param })?.value
  }
}

public protocol TransStatusCallback {
    func getStatus(response : PaymentResponse) -> Void
}
