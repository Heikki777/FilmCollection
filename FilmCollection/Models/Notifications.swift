//
//  Notifications.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 25/08/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct Notifications{
    
    enum SettingsNotification: String{
        case filmCollectionLayoutChanged = "filmCollectionLayoutChanged"
        case notificationsOnChanged = "notificationsOnChanged"
        case notificationStartDateChanged = "notificationStartDateChanged"
        
        var notification: NSNotification{
            return NSNotification.init(name: self.name, object: nil)
        }
        
        var name: NSNotification.Name{
            return NSNotification.Name(rawValue: self.rawValue)
        }
    }

    enum FilmCollectionNotification: String{
        case filmCollectionValueChanged = "filmCollectionValueChangedNotification"
        case filmAddedToCollection = "filmAddedToCollectionNotification"
        case filmChanged = "filmChangedNotification"
        case filmRemoved = "filmRemovedNotification"
        case filmReviewed = "filmReviewed"
        case loadingProgressChanged = "loadingProgressChangedNotification"
        case filmDictionaryChanged = "filmDictionaryChangedNotification"
        case newSectionAddedToDictionary = "newSectionAddedToDictionaryNotification"
        case sectionRemovedFromDictionary = "sectionRemovedFromDictionaryNotification"
        case beginUpdates = "beginUpdatesNotification"
        case endUpdates = "endUpdatesNotification"
        case collectionFiltered = "collectionFilteredNotification"
        
        var notification: NSNotification{
            return NSNotification.init(name: self.name, object: nil)
        }
        
        var name: NSNotification.Name{
            return NSNotification.Name(rawValue: self.rawValue)
        }
    }
}
