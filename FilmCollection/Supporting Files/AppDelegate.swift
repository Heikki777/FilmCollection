//
//  AppDelegate.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import PromiseKit
import Firebase
import UserNotifications
import CoreData
import AFNetworking

let NetworkReachabilityChanged = NSNotification.Name("NetworkReachabilityChanged")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var previousNetworkReachabilityStatus: AFNetworkReachabilityStatus = .unknown
    var filmIdWithinNotification: Int?{
        didSet{
            print("filmDetailToBeShown: \(String(describing: filmIdWithinNotification))")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let currentUser = user{
                NotificationCenter.default.post(name: Notifications.AuthorizationNotification.SignedIn.name, object: user)
            }
            else{
                NotificationCenter.default.post(name: Notifications.AuthorizationNotification.SignedOut.name, object: user)
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            print("granted")
        }
        configureUserNotificationsCenter()
        
        setupNetworkReachabilityManager()
        createObservers()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func setupNetworkReachabilityManager(){
        
        AFNetworkReachabilityManager.shared().startMonitoring()
        AFNetworkReachabilityManager.shared().setReachabilityStatusChange { (status) in
            let reachabilityStatus = AFStringFromNetworkReachabilityStatus(status)
            var reachableOrNot = ""
            var networkSummary = ""
            var reachableStatusBool = false
            
            switch (status){
            case .reachableViaWWAN, .reachableViaWiFi:
                // Reachable
                reachableOrNot = "Reachable"
                networkSummary = "Connected to Network"
                reachableStatusBool = true
            default:
                // Not reachable
                reachableOrNot = "Not Reachable"
                networkSummary = "Disconnected from Network"
                reachableStatusBool = false
            }
            
            if (self.previousNetworkReachabilityStatus != .unknown && status != self.previousNetworkReachabilityStatus){
                NotificationCenter.default.post(name: NetworkReachabilityChanged, object: nil, userInfo: [
                    "reachabilityStatus": "Connection Status : \(reachabilityStatus)",
                    "reachableOrNot": "Network Connection \(reachableOrNot)",
                    "summary" : networkSummary,
                    "reachableStatus" : reachableStatusBool
                ])
            }
            self.previousNetworkReachabilityStatus = status
        }
    }
    
    
    func createObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionLoaded(notification:)), name: Notifications.SettingsNotification.filmCollectionLayoutChanged.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationsOnChanged(notification:)), name: Notifications.SettingsNotification.notificationsOnChanged.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationsStartDateChanged(notification:)), name: Notifications.SettingsNotification.notificationStartDateChanged.name, object: nil)
    }
    
    @objc func handleCollectionLoaded(notification: NSNotification){
        registerForLocalNotifications()
    }
    
    @objc func handleNotificationsOnChanged(notification: NSNotification){
        print("AppDelegate: handleNotificationsOnChanged")
        
        if settings.notificationsOn {
            registerForFilmRecommendationNotifications()
        }
        else{
            unsubscribeNotifications()
        }
    }
    
    @objc func handleNotificationsStartDateChanged(notification: NSNotification){
        print("AppDelegate: handleNotificationsStartDateChanged")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [FilmNotification.Category.randomRecommendation])
        registerForFilmRecommendationNotifications()
    }

    // MARK: - Notifications
    func registerForLocalNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        registerForFilmRecommendationNotifications()
    }
    
    func unsubscribeNotifications(){
        // Remove all pending notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [FilmNotification.Category.randomRecommendation])
        
        // Turn of the notifications
        settings.notificationsOn = false
        saveContext()
        
        guard let homeTabBarController = window?.rootViewController as? HomeTabBarController else{
            print("No homeTabBarController")
            return
        }
        
        homeTabBarController.showBasicAlert(withTitle: "Unsubscribed", message: "You no longer receive notifications.")
    }
    
    
    private func configureUserNotificationsCenter() {
        // Configure User Notification Center
        UNUserNotificationCenter.current().delegate = self
        
        // Define Actions
        let actionShowDetails = UNNotificationAction(identifier: FilmNotification.Action.showDetails, title: "Show Details", options: [.foreground])
        let actionUnsubscribe = UNNotificationAction(identifier: FilmNotification.Action.unsubscribe, title: "Unsubscribe", options: [.destructive, .authenticationRequired])

        // Define Category
        let recommendationCategory = UNNotificationCategory(identifier: FilmNotification.Category.randomRecommendation, actions: [actionShowDetails, actionUnsubscribe], intentIdentifiers: [], options: [])
        
        // Register Category
        UNUserNotificationCenter.current().setNotificationCategories([recommendationCategory])
    }
    
    func registerForFilmRecommendationNotifications(){
        print("AppDelegate.registerForLocalNotifications")
        let filmCollection = FilmCollection.shared
        
        guard let startDate = settings.notificationStartDate else {
            print("notificationStartDate is nil")
            return
        }
        
        let repetitionOption = settings.notificationRepetitionOption
        
        if repetitionOption == .Never{
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Notifications permission granted: \(granted)")
            
            guard granted && filmCollection.size > 0 else{
                return
            }
            
            guard let randomFilm = filmCollection.randomFilm() else{
                return
            }
                
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = "Film recommendation"
            notificationContent.subtitle = "Watch today"
            notificationContent.body = randomFilm.title
            notificationContent.sound = UNNotificationSound.default()
            notificationContent.badge = 0
            notificationContent.userInfo["filmID"] = randomFilm.id
            notificationContent.categoryIdentifier = FilmNotification.Category.randomRecommendation
            
            let calendar = Locale.current.calendar
            var dateComponents = DateComponents()
            
            switch repetitionOption{
            case .Never:
                dateComponents = calendar.dateComponents(Set([.day, .hour, .minute]), from: startDate)
            case .EveryDay:
                dateComponents = calendar.dateComponents(Set([.hour, .minute]), from: startDate)
            case .EveryWeek:
                dateComponents = calendar.dateComponents(Set([.weekday, .hour, .minute]), from: startDate)
            case .EveryMonth:
                dateComponents = calendar.dateComponents(Set([.day, .hour, .minute]), from: startDate)
            }
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: FilmNotification.Category.randomRecommendation, content: notificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(request)

        }
    }
    
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "FilmCollection")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        print("saveContext")
        let context = persistentContainer.viewContext
        if context.hasChanges {
            print("Context has changes")
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Settings
    
    lazy var settings: Settings = {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
        
        do{
            if let settingsArray = try context.fetch(request) as? [Settings], let settings = settingsArray.first{
                print("settings array")
                print(settingsArray)
                return settings
            }
        }
        catch let error {
            print(error.localizedDescription)
        }
        
        let settings = Settings(context: context)
        saveContext()
        return settings
    }()
    
}

enum NotificationRequest: String{
    case randomFilmRecommendation
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("willPresent")
        //If you don't want to show notification when app is open, do something here else and make a return here.
        //Even you don't implement this delegate method, you will not see the notification on the specified controller. So, you have to implement this delegate and make sure the below line execute. i.e. completionHandler.
        
        if notification.request.identifier == FilmNotification.Category.randomRecommendation{
            if settings.notificationRepetitionOption != .Never{
                print("Repeat notification")
                registerForFilmRecommendationNotifications()
            }
        }
    }
    
    // For handling tap and user actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("userNotificationCenter: didReceive: \(response)")
        
        switch response.notification.request.identifier {
        case FilmNotification.Category.randomRecommendation:
            switch response.actionIdentifier{
            case FilmNotification.Action.showDetails:
                print("Show details of the recommended film")
                if let filmID = response.notification.request.content.userInfo["filmID"] as? Int{
                    print("Film in notification: \(filmID)")
                    if let film = FilmCollection.shared.getMovie(withId: filmID){
                        print(film.titleYear)
                        
                        guard let homeTabBarController = window?.rootViewController as? HomeTabBarController else{
                            print("No homeTabBarController")
                            return
                        }
                        
                        guard let navigationController = homeTabBarController.childViewControllers.filter({
                            $0.title == "CollectionTabNavigationController" }).first as? UINavigationController else {
                                print("CollectionTabNavigationController could not be found")
                                return
                        }
                        
                        guard let indexPath = FilmCollection.shared.getIndexPath(for: film) else{
                            print("The film has no indexPath")
                            return
                        }
                        
                        if let filmCollectionTableViewController = navigationController.childViewControllers.first as? FilmCollectionTableViewController{
                            print("FilmCollectionTableViewController")
                            filmCollectionTableViewController.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
                            filmCollectionTableViewController.performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
                        }
                        else if let filmPosterCollectionViewController = navigationController.childViewControllers.first as? FilmPosterCollectionViewController{
                            print("FilmPosterCollectionViewController")
                            filmPosterCollectionViewController.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .top)
                            filmPosterCollectionViewController.performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
                        }
                        else{
                            print("ERROR!")
                        }
                        
                        homeTabBarController.selectedIndex = 0
                        
                    }
                }
                
            case FilmNotification.Action.unsubscribe:
                unsubscribeNotifications()
            
            default:
                // Show film details
                guard let filmID = response.notification.request.content.userInfo["filmID"] as? Int else{
                    return
                }
                
                filmIdWithinNotification = filmID
                NotificationCenter.default.post(name: NSNotification.Name.init("showDetailOfNotifiedFilm"), object: filmID)
            }

        default:
            break
        }
        completionHandler()
    }
    
}

