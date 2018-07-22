//
//  HomeTabBarController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 08/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class HomeTabBarController: UITabBarController {

    let loadingIndicator: LoadingIndicatorViewController = LoadingIndicatorViewController(title: nil, message: nil, complete: nil)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        createObservers()
        
        guard let layoutOption = Settings.FilmCollectionLayoutOption.init(rawValue: appDelegate.settings.filmCollectionLayout) else{
            return
        }
        
        guard let navigationVC = self.viewControllers?.first as? UINavigationController else{
            return
        }
        
        switch layoutOption {
        case .poster:
            let vc = storyboard?.instantiateViewController(withIdentifier: "FilmPosterCollectionViewController") as! FilmPosterCollectionViewController
            navigationVC.setViewControllers([vc], animated: false)
        default:
            let vc = storyboard?.instantiateViewController(withIdentifier: "FilmCollectionTableViewController") as! FilmCollectionTableViewController
            navigationVC.setViewControllers([vc], animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    func createObservers(){
        
        // Observer for network reachability status
        NotificationCenter.default.addObserver(forName: NetworkReachabilityChanged, object: nil, queue: nil, using: {
            (notification) in
            if let userInfo = notification.userInfo {
                if let messageTitle = userInfo["summary"] as? String, let reachableOrNot = userInfo["reachableOrNot"] as? String, let reachableStatus = userInfo["reachabilityStatus"] as? String {
                    let messageFullBody = "\(reachableOrNot)\n\(reachableStatus)"
                    let alertController = UIAlertController(title: messageTitle, message: messageFullBody, preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(OKAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionLayoutChange(notification:)), name: filmCollectionLayoutChanged, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc func handleCollectionLayoutChange(notification: NSNotification){
        print("handleCollectionLayoutChange")
        guard let layoutOption = notification.object as? Settings.FilmCollectionLayoutOption else{
            return
        }
        
        guard let navigationVC = self.viewControllers?.first as? UINavigationController else{
            return
        }
        
        switch layoutOption {
        case .poster:
            let vc = storyboard?.instantiateViewController(withIdentifier: "FilmPosterCollectionViewController") as! FilmPosterCollectionViewController
            navigationVC.setViewControllers([vc], animated: false)
        default:
            let vc = storyboard?.instantiateViewController(withIdentifier: "FilmCollectionTableViewController") as! FilmCollectionTableViewController
            navigationVC.setViewControllers([vc], animated: false)
        }
    }
    
    func showLoadingIndicator(withTitle title: String?, message: String?, progress: Float?, complete: (() -> ())?){
        loadingIndicator.title = title
        loadingIndicator.message = message
        loadingIndicator.complete = complete
        if let progress = progress{
            loadingIndicator.setProgress(progress)
        }
        
        if(self.loadingIndicator.presentingViewController == nil){
            self.present(self.loadingIndicator, animated: false, completion: complete)
        }

    }

}
