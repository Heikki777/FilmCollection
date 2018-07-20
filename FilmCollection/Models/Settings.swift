//
//  Settings.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 24/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import CoreData

typealias FilmCollectionLayoutOption = Settings.FilmCollectionLayoutOption
typealias NotificationSettings = Settings.Notification

class Settings: NSManagedObject{
    @NSManaged var filmCollectionLayout: String
    @NSManaged var notificationsOn: Bool
    @NSManaged var notificationStartDate: Date?

    var sections: [String] = [
        SectionTitle.FilmCollectionLayout.rawValue,
        SectionTitle.Notifications.rawValue
    ]
    
    var dictionary: [String: [String]]{
        return [
            SectionTitle.FilmCollectionLayout.rawValue: FilmCollectionLayoutOption.all.map{ $0.rawValue },
            SectionTitle.Notifications.rawValue: Notification.all.map { $0.rawValue }
        ]
    }
    
    enum SectionTitle: String {
        case FilmCollectionLayout = "Film collection layout"
        case Notifications = "Notifications"
        
        var index: Int{
            switch self {
            case .FilmCollectionLayout:
                return 0
            case .Notifications:
                return 1
            }
        }
    }
    
    enum FilmCollectionLayoutOption: String {
        case poster = "Poster"
        case posterTitleOverview = "Poster, title and overview"
        case title = "Title"
        
        static var all: [FilmCollectionLayoutOption]{
            return [.poster, .posterTitleOverview, .title]
        }
    }
    
    enum Notification: String {
        case IsOn = "Notifications on"
        case Starts
        case Repeat
        
        var index: Int{
            return Notification.all.index(of: self)!
        }
        
        static var all: [Notification]{
            return [.IsOn, .Starts, .Repeat]
        }
        
    }

}

