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
        print("getStatus: " + response.status)
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
        request = PaymentRequest(cid: "M161-U-xxx", signatureKey: "YourSignatureKey", amount: amount, cartId: "IOSSDK" + String(format: "%.0f",  NSDate().timeIntervalSince1970), isProd: false, returnUrl: "", callback: self, callbackUrl: "")
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
                    Button(action: {
                                if let url = URL(string: "sarawakpay://safari?lk=h5pay&mallId=M100068722&transFlows=ZF202506261000634537&merName=GKASH%20QA&orderAmt=0.10&detailURL=https://api-staging.pay.asia/api/SarawakPay/Return?PoRemId=M161-PO-242005&mdrMode=0&serviceCharge=0&merOrderNo=M161-PO-242005&description=GKASH%20QA&successUrl=https://api-staging.pay.asia/api/SarawakPay/Return?PoRemId=M161-PO-242005") {
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    } else {
                                        print("App not installed or URL can't be opened.")
                                    }
                                }
                            }) {
                                Text("Open Sarawak App")
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                }.padding(30).navigationBarHidden(true)
            }
        case "ResponsePage":
            VStack{
                Text("Status: " + paymentResponse.status)
                Text("Description: " + paymentResponse.description)
                Text("POID: " + paymentResponse.POID)
                Text("Amount: " + paymentResponse.currency + paymentResponse.amount)
                Text("CartId: " + paymentResponse.cartid)
                Text("PaymentType: " + paymentResponse.PaymentType)
                Text("CID: " + paymentResponse.cid)
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
