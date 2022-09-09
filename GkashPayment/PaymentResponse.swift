//
//  PaymentResponse.swift
//  GkashPayment
//
//  Created by Gkash on 05/09/2022.
//
import CommonCrypto
import Foundation

public class PaymentResponse {
   public var Status: String = ""
   public var Amount: String = ""
   public var CartId: String = ""
   public var Description: String = ""
   public var Currency: String = ""
   public var POID: String = ""
   public var CID: String = ""
   public var PaymentType: String = ""
   public var Signature: String = ""
   public init(Status : String = "", Amount: String = "", CartId: String = "", Description: String = "", Currency: String = "", POID: String = "", CID: String = "", PaymentType: String = "") {
       self.Status = Status
       self.Amount = Amount
       self.CartId = CartId
       self.Description = Description
       self.Currency = Currency
       self.POID = POID
       self.CID = CID
       self.PaymentType = PaymentType
     }
    
   public func validateSignature(signature : String, request: PaymentRequest) -> Bool {
     let doubleAmount : Double? = Double(Amount)
     let amount : String = String(format: "%.2f", doubleAmount!).replacingOccurrences(of: ".", with: "")
     let sign : String = (request.signatureKey + ";" + CID + ";" + POID + ";" + CartId + ";" +
                          amount + ";" + Currency + ";" + Status).uppercased()
     var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
     if let data = sign.data(using: String.Encoding.utf8) {
       let value = data as NSData
       CC_SHA512(value.bytes, CC_LONG(data.count), &digest)
     }
     var digestHex = ""
     for index in 0..<Int(CC_SHA512_DIGEST_LENGTH) {
       digestHex += String(format: "%02x", digest[index])
     }
     if(digestHex == signature){
       return true
     }else{
       return false
     }
   }
}
