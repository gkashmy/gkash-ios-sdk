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
                  "uat.shopee.com.my/","gkash://returntoapp"]
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
  public init(){}
  public init(cid: String, signatureKey: String, amount: String, cartId: String, isProd: Bool, returnUrl: String){
    self.cid = cid
    self.signatureKey = signatureKey
    self.amount = amount
    self.cartId = cartId
    if(returnUrl == ""){
      self.returnUrl = "gkash://returntoapp"
    }else{
      self.returnUrl = returnUrl
    }
    self.isProd = isProd
    if(isProd){
      self.HOST_URL = "https://api.gkash.my"
      walletScheme = prodWalletScheme
    }
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
}

public protocol TransStatusCallback {
    func getStatus(response : PaymentResponse) -> Void
}
