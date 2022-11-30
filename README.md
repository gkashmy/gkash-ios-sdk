# Gkash Payment SDK for IOS

This library allows you to integrate Gkash Payment Gateway into your IOS App.

## Installation with CocoaPods

To integrate GkashPayment into your Xcode project using CocoaPods, specify it in your Podfile:

```
pod 'GkashPayment', '~> 0.5'
```

Run pod install and open the .xcworkspace file to launch Xcode.

## Return URL
To get your transaction status you need to pass your URL scheme to GkashPaymentSDK

Apps can declare any custom URL schemes they support. Use the URL Types section of the Info tab to specify the custom URL schemes that your app handles.
![Screenshot 2022-09-12 at 1 04 17 PM](https://user-images.githubusercontent.com/72077476/189577588-53a41833-3c4d-47b5-ab5a-6e755787fc8d.png)

Example 
```Swift
import SwiftUI
import GkashPayment

//Implement TransStatusCallback to get your transaction status
struct ContentView: View, TransStatusCallback {

    //Implementation of TransStatusCallback
    //You'll get your transaction details here
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
    
    //Generate PaymentRequest and pass to GkashPaymentSDK
    //in order to get the transaction status, pass your app's URL scheme as returnUrl
    //cid is your Gkash's User ID and signatureKey is your User's SignatureKey
    //cartId must be an unique reference ID
    //pass isProd: false if in staging environment, isProd: true in production environment
    func generateRequest(){
        request = PaymentRequest(cid: "M102-U-XXX", signatureKey: "YourSignatureKey", amount: amount, cartId: "IOSSDK" + String(format: "%.0f",  NSDate().timeIntervalSince1970), isProd: false, returnUrl: "YourUrlScheme", callback: self)
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
```
