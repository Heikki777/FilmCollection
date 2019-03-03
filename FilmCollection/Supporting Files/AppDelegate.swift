//
//  AppDelegate.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import CoreData
import AFNetworking
import EventKit

let NetworkReachabilityChanged = NSNotification.Name("NetworkReachabilityChanged")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var previousNetworkReachabilityStatus: AFNetworkReachabilityStatus = .unknown
    var filmIdWithinNotification: Int?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setupNetworkReachabilityManager()
        
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
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
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
    
    
    lazy var filmCollectionEntity: FilmCollectionEntity = {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FilmCollectionEntity")
        
        do {
            if let filmCollectionEntity = try (context.fetch(request) as? [FilmCollectionEntity])?.first {
                return filmCollectionEntity
            }
        }
        catch let error {
            print(error.localizedDescription)
        }
        
        let filmCollectionEntity = FilmCollectionEntity(context: context)
        saveContext()
        return filmCollectionEntity
    }()
    
    var filmEntities: Set<FilmEntity> {
        return self.filmCollectionEntity.films as! Set<FilmEntity>
    }
    
    var viewingEntities: [Viewing] {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Viewing")
        
        do {
            if let viewings = try (context.fetch(request) as? [Viewing]){
                return viewings
            }
        }
        catch let error {
            print(error.localizedDescription)
        }
        
        return []
    }

}

