//
//  VideoPlayerViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 21.2.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import WebKit

class VideoPlayerViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        if let url = url{
            var youtubeRequest = URLRequest(url: url)
            youtubeRequest.setValue("https://www.youtube.com", forHTTPHeaderField: "Referer")
            webView.load( youtubeRequest )
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - Webkit Navigation Delegate
extension VideoPlayerViewController: WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.alpha = 0
        webView.isHidden = false
        UIView.animate(withDuration: 1) {
            webView.alpha = 1
        }
    }
}
