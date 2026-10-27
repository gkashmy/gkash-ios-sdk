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
  @State private var progress: Double = 0

  public init(request : PaymentRequest) {
    self.request = request
  }
  public var body: some View {
    Group {
      if request.hostToHost {
        HostToHostView(request: request)
      } else {
        VStack(spacing: 0) {
          ProgressView(value: progress)
            .progressViewStyle(LinearProgressViewStyle())
            .opacity(progress < 1 ? 1 : 0)
          MyWebView(request: request, progress: $progress)
        }
      }
    }.onOpenURL { url in
        print("onOpenURL")
        request.StatusCallback(url: url)
    }
  }
}

struct HostToHostView: View {
  var request: PaymentRequest
  var body: some View {
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onAppear {
        request.submitHostToHost()
      }
  }
}

struct MyWebView: UIViewRepresentable{
  var request: PaymentRequest
  @Binding var progress: Double
  func makeUIView(context: Context) -> WKWebView {
    print("make UI View")
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    context.coordinator.observeProgress(of: webView)
    // Load once here, updateUIView runs on every SwiftUI update and must not post the payment again
    var urlRequest: URLRequest = URLRequest(url: URL(string: request.HOST_URL + "/api/PaymentForm.aspx")!)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = request.formBody()
    webView.load(urlRequest)
    return webView
  }
  func updateUIView(_ uiView: WKWebView, context: Context) {
  }
  class Coordinator : NSObject, WKNavigationDelegate {
    static let wechatCheckMwebPrefix = "https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb"
    var parent: MyWebView
    var request: PaymentRequest
    private var progressObservation: NSKeyValueObservation?
    init(_ uiWebView: MyWebView, request: PaymentRequest) {
      print("Coordinator init")
      self.parent = uiWebView
      self.request = request
    }
    func observeProgress(of webView: WKWebView) {
      progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
        // The first change fires inside makeUIView, so update SwiftUI state after the view update ends
        DispatchQueue.main.async {
          self?.parent.progress = webView.estimatedProgress
        }
      }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      guard let url = navigationAction.request.url else {
        decisionHandler(.allow)
        return
      }
      let urlString = url.absoluteString
      print("currenturl: " + urlString)
      if urlString.hasPrefix(request.returnUrl) {
        print("StatusCallback")
        request.StatusCallback(url: url)
        decisionHandler(.cancel)
        return
      }
      // WeChat Pay H5 only accepts the checkmweb page when the Referer is the merchant domain
      if urlString.hasPrefix(Coordinator.wechatCheckMwebPrefix) && navigationAction.request.value(forHTTPHeaderField: "Referer") == nil {
        print("add header to wechat")
        var wechatRequest = navigationAction.request
        wechatRequest.setValue(request.HOST_URL + "/", forHTTPHeaderField: "Referer")
        webView.load(wechatRequest)
        decisionHandler(.cancel)
        return
      }
      // Wallet links and any non web scheme are handed over to the app that handles them
      let isWebScheme = ["http", "https", "about", "data", "blob"].contains(url.scheme?.lowercased() ?? "")
      if !isWebScheme || request.walletScheme.contains(where: { urlString.contains($0) }) {
        print("launch third party payment app to complete payment")
        UIApplication.shared.open(url) { opened in
          if !opened {
            print("Unable to launch " + urlString)
          }
        }
        decisionHandler(.cancel)
        return
      }
      // This allows the navigation
      decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      print("load failed: " + error.localizedDescription)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      print("load failed: " + error.localizedDescription)
    }
  }

  func makeCoordinator() -> Coordinator {
    print("Coordinator")
    return Coordinator(self, request: request)
  }
}
