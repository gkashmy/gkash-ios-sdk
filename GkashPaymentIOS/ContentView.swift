//
//  ContentView.swift
//  GkashPaymentIOS
//
//  Created by Gkash on 07/09/2022.
//

import SwiftUI
import GkashPayment

struct ContentView: View, TransStatusCallback {
    func getStatus(response: PaymentResponse) {
        print("Status: " + response.Status)
    }
    
    @State private var amount: String = ""
    
    func generateRequest() -> PaymentRequest{
        //cartId must be unique
        //returnUrl will be your URL Scheme. eg: gkash
        return PaymentRequest(cid: "M102-U-XXX", signatureKey: "YourSignatureKey", amount: amount, cartId: "IOSSDK" + String(format: "%.1f",  NSDate().timeIntervalSince1970), isProd: false, returnUrl: "")
    }
    
    var body: some View {
        NavigationView{
            VStack {
                TextField("Amount", text: $amount).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                NavigationLink(destination: GkashPaymentSDK(request: generateRequest(), callback: self)){
                    Text("Submit")
                }
                Spacer()
            }.padding(20)
        }
    }
}
