//
//  HtmlPreviewViewController.swift
//  Mailings
//
//  Created on 18.07.18.
//

import UIKit
import WebKit

/**
 Displays the htmlText as a webpage.
 */
class HtmlPreviewViewController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView
    
    var htmlText: String? {
        didSet {
            if let text = htmlText {
                if HtmlUtil.isHtml(text) {
                    loadHtmlPage()
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRect.zero)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
    }

    private func loadHtmlPage() {
        webView.loadHTMLString(htmlText!, baseURL: nil)
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Page loading done")
        if let webViewTitle = webView.title {
            title = webViewTitle
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Error loading page \(error)")
    }
}
