//
//  GkashPaymentSDK.swift
//  GkashPayment
//
//  Created by Gkash on 05/09/2022.
//

import SwiftUI
import WebKit
public struct GkashPaymentSDK: View {
  var request: PaymentRequest
  
  public init(request : PaymentRequest) {
    self.request = request
  }
  public var body: some View {
    MyWebView(request: request).onOpenURL { url in
        print("onOpenURL")
        request.StatusCallback(url: url)
    }
 //     MyWebView(request: request)
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
	  URLQueryItem(name: "callbackurl", value: request.callbackUrl),
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
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      print("application")
      return true
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      // Suppose you don't want your user to go a restricted site
      // Here you can get many information about new url from 'navigationAction.request.description'
      let url = navigationAction.request.url?.absoluteString
      print(url ?? "url is null")
      for item in request.walletScheme{
        if (url?.contains(item) ?? false){
          print("walletScheme: " + url!)
          let schemeURL = URL(string: url!)
          if UIApplication.shared.canOpenURL(schemeURL!)
          {
            if url?.contains(request.returnUrl) ?? false {
                print("StatusCallback")
                request.StatusCallback(url: navigationAction.request.url!)
            }else{
                print("launch")
                UIApplication.shared.open(schemeURL!)
            }
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
