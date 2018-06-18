//
//  Viewing.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 15/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

class Viewing{
    
    let date: Date
    let title: String
    let id: Int
    
    init(date: Date, title: String, id: Int){
        self.date = date
        self.title = title
        self.id = id
    }
}
