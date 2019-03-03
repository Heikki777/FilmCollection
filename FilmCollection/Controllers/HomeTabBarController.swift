//
//  HomeTabBarController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 08/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class HomeTabBarController: UITabBarController {

    var loadingIndicator: LoadingIndicatorViewController = LoadingIndicatorViewController()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createObservers()
        
        let layoutOption = FilmCollectionLayoutOption.init(rawValue: appDelegate.settings.filmCollectionLayout) ?? FilmCollectionLayoutOption.title
        
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
        
        self.loadingIndicator = LoadingIndicatorViewController(delegate: self, title: "Loading film collection", message: nil)
        FilmCollection.shared.loadingIndicatorDataSource = self.loadingIndicator
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    private func disableTabBarItems(){
        tabBar.items?.forEach({ (tabBarItem) in
            tabBarItem.isEnabled = false
        })
    }
    
    func createObservers(){
        
        // Observer for network reachability status
        NotificationCenter.default.addObserver(forName: NetworkReachabilityChanged, object: nil, queue: nil, using: {
            (notification) in
            if let userInfo = notification.userInfo {
                if let messageTitle = userInfo["summary"] as? String,
                let reachableOrNot = userInfo["reachableOrNot"] as? String,
                let reachableStatus = userInfo["reachabilityStatus"] as? Bool {
                    if reachableStatus == false{
                        let messageFullBody = "\(reachableOrNot)\n\(reachableStatus)"
                        let alertController = UIAlertController(title: messageTitle, message: messageFullBody, preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default)
                        alertController.addAction(OKAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionLayoutChange(notification:)), name: Notifications.SettingsNotification.filmCollectionLayoutChanged.name, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionLoaded), name: Notifications.FilmCollectionNotification.filmCollectionValueChanged.name, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (loadingIndicator.presentingViewController == nil){
            self.present(loadingIndicator, animated: true, completion: nil)
        }
    }
    
    @objc func handleCollectionLoaded(notification: NSNotification) {
        print("HomeTabBarController: collection loaded")
        tabBar.items?.forEach({ (tabBarItem) in
            tabBarItem.isEnabled = true
        })
    }
    
    @objc func handleCollectionLayoutChange(notification: NSNotification){
        guard let layoutOption = notification.object as? FilmCollectionLayoutOption else{
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
    
    func showBasicAlert(withTitle title: String, message: String? = ""){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alert, sender: self)
    }
}

extension HomeTabBarController: LoadingIndicatorViewControllerDelegate {
    
    func shouldShowCancelButton() -> Bool {
        return false
    }
    
    func loadingIndicatorViewControllerCancelButtonPressed() {}
}
