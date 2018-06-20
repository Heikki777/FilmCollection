//
//  MovieImages.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 23/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import UIKit

class MovieImages{
    var posters: [(data: ImageData, image: UIImage)]
    var backdrops: [(data: ImageData, image: UIImage)]
    
    let groupTitles: [String] = ["Posters", "Backdrops"]
    
    var count: Int{
        return posters.count + backdrops.count
    }
    
    var isEmpty: Bool{
        return self.count == 0
    }
    
    var all: [(data: ImageData, image: UIImage)]{
        return groupTitles.flatMap({ (groupTitle) -> [(data: ImageData, image: UIImage)] in
            self[groupTitle]
        })
    }
    
    var toDictionary: [String: [UIImage]]{
        return [
            "Posters": posters.map{ $0.image },
            "Backdrops": backdrops.map{ $0.image},
        ]
    }
    
    subscript(key: String) -> [(data: ImageData, image: UIImage)] {
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
