//
//  GkashPaymentSDK.swift
//  GkashPayment
//
//  Created by Gkash on 05/09/2022.
//

import SwiftUI
import SwiftUI
import WebKit
public struct GkashPaymentSDK: View {
  var request: PaymentRequest
  var callback: TransStatusCallback
  
  public init(request : PaymentRequest, callback: TransStatusCallback) {
    self.request = request
    self.callback = callback
  }
  public var body: some View {
    MyWebView(request: request).onOpenURL { url in
      print("MyWebView :" + url.absoluteString)
      let status : String = getQueryStringParameter(url: url.absoluteString, param: "status") ?? "Unknown status"
      let description : String = getQueryStringParameter(url: url.absoluteString, param: "description") ?? ""
      let CID : String = getQueryStringParameter(url: url.absoluteString, param: "CID") ?? ""
      let POID : String = getQueryStringParameter(url: url.absoluteString, param: "POID") ?? ""
      let cartid : String = getQueryStringParameter(url: url.absoluteString, param: "cartid") ?? ""
      let amount : String = getQueryStringParameter(url: url.absoluteString, param: "amount") ?? ""
      let currency : String = getQueryStringParameter(url: url.absoluteString, param: "currency") ?? ""
      let PaymentType : String = getQueryStringParameter(url: url.absoluteString, param: "PaymentType") ?? ""
      let signature : String = getQueryStringParameter(url: url.absoluteString, param: "signature") ?? ""
      let resp : PaymentResponse = PaymentResponse(Status: status, Amount: amount, CartId: cartid, Description: description, Currency: currency, POID: POID, CID: CID, PaymentType: PaymentType)
      if(resp.validateSignature(signature: signature, request: request)){
        callback.getStatus(response: resp)
      }else{
        resp.Status = "11 - Pending"
        resp.Description = "Invalid Signature"
        callback.getStatus(response: resp)
      }
    }
  }
  public func getQueryStringParameter(url: String, param: String) -> String? {
   guard let url = URLComponents(string: url) else { return nil }
   return url.queryItems?.first(where: { $0.name == param })?.value
  }
}
struct MyWebView: UIViewRepresentable{
  var request: PaymentRequest
  var webView: WKWebView
  init(request: PaymentRequest){
    self.request = request
    webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1))
  }
  func makeUIView(context: Context) -> WKWebView {
    print("make UI View")
  //  return WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1))
    return self.webView
  }
  func updateUIView(_ uiView: WKWebView, context: Context) {
    let url: String = request.HOST_URL + "/api/PaymentForm.aspx"
    print("update ui view")
    uiView.navigationDelegate = context.coordinator
    var urlRequest: URLRequest = URLRequest(url: URL(string: url)!)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    var components = URLComponents(url: URL(string: url)!, resolvingAgainstBaseURL: false)!
    components.queryItems = [
      URLQueryItem(name: "version", value: request.version),
      URLQueryItem(name: "CID", value: request.cid),
      URLQueryItem(name: "v_currency", value: request.currency),
      URLQueryItem(name: "v_amount", value: request.amount),
      URLQueryItem(name: "v_cartid", value: request.cartId),
      URLQueryItem(name: "v_firstname", value: request.firstName),
      URLQueryItem(name: "v_lastname", value: request.lastName),
      URLQueryItem(name: "v_billemail", value: request.email),
      URLQueryItem(name: "v_billphone", value: request.mobileNo),
      URLQueryItem(name: "signature", value: request.generateSignature()),
      URLQueryItem(name: "returnurl", value: request.returnUrl),
    ]
    let query = components.url!.query
    urlRequest.httpBody = Data(query!.utf8)
    uiView.load(urlRequest)
  }
  class Coordinator : NSObject, WKNavigationDelegate, UISceneDelegate, UIApplicationDelegate {
    var parent: MyWebView
    var request: PaymentRequest
    init(_ uiWebView: MyWebView, request: PaymentRequest) {
      print("Coordinator init")
      self.parent = uiWebView
      self.request = request
    }
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
      print("scene")
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      print("application")
      return true
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      // Hides loader
      print("webview1")
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      // Hides loader
      print("webview2")
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
      // Shows loader
      print("webview3")
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      print("webview4")
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      // Suppose you don't want your user to go a restricted site
      // Here you can get many information about new url from 'navigationAction.request.description'
      print("webview5")
      let url = navigationAction.request.url?.absoluteString
      print(url ?? "url is null")
      for item in request.walletScheme{
        if (url?.contains(item) ?? false){
          print("launching app: " + url!)
          let schemeURL = URL(string: url!)
          if UIApplication.shared.canOpenURL(schemeURL!)
          {
            UIApplication.shared.open(schemeURL!)
            decisionHandler(.cancel)
            return
          }
        }
      }
      // This allows the navigation
      decisionHandler(.allow)
    }
  }
  func makeCoordinator() -> Coordinator {
    print("Coordinator")
    return Coordinator(self, request: request)
  }
}
