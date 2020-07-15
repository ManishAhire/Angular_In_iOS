//
//  ViewController.swift
//  POC_CouplAR
//
//  Created by Manish Ahire on 14/07/20.
//  Copyright © 2020 Manish Ahire. All rights reserved.
//

import UIKit
import WebKit
import GCDWebServer
import WKWebViewJavascriptBridge

enum LoadDemoPageError: Error {
    case nilPath
}

class ViewController: UIViewController {

     let webView = WKWebView(frame: CGRect(), configuration: WKWebViewConfiguration())
       var bridge: WKWebViewJavascriptBridge!
    var webServer = GCDWebServer()

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.frame = view.bounds
        view.addSubview(webView)

        bridge = WKWebViewJavascriptBridge(webView: webView)
                bridge.isLogEnable = true
                bridge.register(handlerName: "testiOSCallback") { (paramters, callback) in
                    print("Received data from JS")
                    print("testiOSCallback called: \(String(describing: paramters))")
                    self.showAlert(data: String(describing: paramters!))
                    callback?("Response from testiOSCallback")
                }

        initWebServer()

        let basePath = URL(string: "http://192.168.1.6:8080/index.html", relativeTo: nil)
        let request = URLRequest(url: basePath!)
        webView.load(request)


    }

        func showAlert(data: String) {
            let alert = UIAlertController(title: "Data From JS", message: data, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    func initWebServer() {

        webServer = GCDWebServer()

        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { request in

            var response = GCDWebServerDataResponse()

            let page = request.url.lastPathComponent

            if page.hasSuffix("html") {

                do {
                    let pagePath = Bundle.main.path(forResource: "index", ofType: "html")
                    let html = try String(contentsOfFile: pagePath!, encoding: .utf8)
                    response = GCDWebServerDataResponse(html: html)!
                } catch let error {
                    print("HTML Error", error)
                }

            } else {

                if page != "/" {
                    let fileName = URL(fileURLWithPath: page).deletingPathExtension().lastPathComponent
                    let fileExtension = URL(fileURLWithPath: page).pathExtension
                    let pagePath = Bundle.main.path(forResource: fileName, ofType: fileExtension)
                    let data = NSData(contentsOfFile: pagePath!)

                    if data == nil {
                        response = GCDWebServerDataResponse(html:"<html><body><p>Hello World</p></body></html>")!
                    } else {
                        var type = "image/jpeg"

                        if page.hasSuffix("jpg") {
                            type = "image/jpeg"
                        } else if page.hasSuffix("png") {
                            type = "image/png"
                        } else if page.hasSuffix("css") {
                            type = "text/css"
                        } else if page.hasSuffix("js") {
                            type = "text/javascript"
                        }

                        response = GCDWebServerDataResponse(data: data! as Data, contentType: type)
                    }
                }
            }
            return response
        })
        webServer.start(withPort: 8080, bonjourName: "GCD Web Server")
    }
}

