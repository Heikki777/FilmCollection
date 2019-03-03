//
//  FilmImages.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 23/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import UIKit

struct FilmImages {
    var posters: [URL]
    var backdrops: [URL]

    let groupTitles: [String] = ["Posters", "Backdrops"]

    var count: Int{
        return posters.count + backdrops.count
    }

    var isEmpty: Bool{
        return self.count == 0
    }

    var all: [URL] {
        return groupTitles.flatMap({ (groupTitle) -> [URL] in
            self[groupTitle]
        })
    }

    var toDictionary: [String: [URL]]{
        return [
            "Posters": posters,
            "Backdrops": backdrops
        ]
    }

    subscript(key: String) -> [URL] {
        get {
            switch key.capitalized{
            case "Posters":
                return posters
            case "Backdrops":
                return backdrops
            default:
                return []
            }
        }
        set(newValue) {
            switch key.capitalized{
            case "Posters":
                posters = newValue
            case "Backdrops":
                backdrops = newValue
            default:
                break
            }
        }
    }

    init(){
        self.posters = []
        self.backdrops = []
    }
}
