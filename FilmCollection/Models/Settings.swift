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

class Settings: NSManagedObject {
    @NSManaged var filmCollectionLayout: String

    var sections: [String] = [
        SectionTitle.FilmCollectionLayout.rawValue
    ]
    
    var dictionary: [String: [String]]{
        return [
            SectionTitle.FilmCollectionLayout.rawValue: FilmCollectionLayoutOption.all.map{ $0.rawValue }
        ]
    }
    
    enum SectionTitle: String {
        case FilmCollectionLayout = "Film collection layout"
        
        var index: Int{
            switch self {
            case .FilmCollectionLayout:
                return 0
            }
        }
    }
    
    enum FilmCollectionLayoutOption: String {
        case poster = "Poster"
        case posterAndBriefInfo = "Poster and brief info"
        case title = "Title"
        
        static var all: [FilmCollectionLayoutOption]{
            return [.poster, .posterAndBriefInfo, .title]
        }
    }
}

