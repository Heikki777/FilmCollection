//
//  Settings.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 24/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import CoreData

class Settings: NSManagedObject{
    @NSManaged var filmCollectionLayout: String

    var dictionary: [String: [String]]{
        return [
            SectionTitle.FilmCollectionLayout.rawValue: FilmCollectionLayoutOption.all.map{ $0.rawValue }
        ]
    }
    
    enum SectionTitle: String{
        case FilmCollectionLayout = "Film collection layout"
    }
}

enum FilmCollectionLayoutOption: String{
    case poster = "Poster"
    case posterTitleOverview = "Poster, title and overview"
    case title = "Title"

    static var all: [FilmCollectionLayoutOption]{
        return [.poster, .posterTitleOverview, .title]
    }
}
