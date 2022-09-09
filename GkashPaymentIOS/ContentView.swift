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
        print("getStatus: " + response.Status)
        paymentResponse = response
        currentPage = "ResponsePage"
        isShowingView = false
    }
    
    @State private var amount: String = "0.10"
    @State private var request : PaymentRequest = PaymentRequest()
    @State private var paymentResponse: PaymentResponse = PaymentResponse()
    @State private var currentPage = "MainPage"
    @State private var isShowingView = false
    
    func generateRequest(){
        //Update your cid and signaturekey
        //cartId must be unique
        //returnUrl will be your APP URL Scheme. eg: gkash
        //if production purpose set isProd to true
        request = PaymentRequest(cid: "M102-U-XXX", signatureKey: "YourSignatureKey", amount: amount, cartId: "IOSSDK" + String(format: "%.0f",  NSDate().timeIntervalSince1970), isProd: false, returnUrl: "", callback: self)
    }
    
    var body: some View {
        switch currentPage{
        case "MainPage":
            NavigationView{
                VStack{
                    TextField("Amount", text: $amount).keyboardType(.numberPad).textFieldStyle(.roundedBorder).padding(.bottom)
                    Button {
                    } label: {
                        NavigationLink(destination:  GkashPaymentSDK(request: request), isActive: $isShowingView) {
                            Button{
                                
                            }label: {
                                Text("Submit")
                                
                            }.buttonStyle(.borderedProminent)
                       }
                    }.simultaneousGesture(TapGesture().onEnded{
                        isShowingView = true
                        generateRequest()
                    })
                    Spacer()
                }.padding(30).navigationBarHidden(true)
            }
        case "ResponsePage":
            VStack{
                Text("Status: " + paymentResponse.Status)
                Text("Description: " + paymentResponse.Description)
                Text("POID: " + paymentResponse.POID)
                Text("Amount: " + paymentResponse.Currency + paymentResponse.Amount)
                Text("CartId: " + paymentResponse.CartId)
                Text("PaymentType: " + paymentResponse.PaymentType)
                Text("CID: " + paymentResponse.CID)
                Button {
                    currentPage = "MainPage"
                } label: {
                    Text("Next payment")
                }.buttonStyle(.borderedProminent)
            }.navigationBarHidden(true)
        default:
            Text("default")
            
        }

    }
}
