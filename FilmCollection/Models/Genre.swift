//
//  Genre.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

enum Genre: String{
    case Action
    case Comedy
    case Drama
    case Horror
    case Thriller
    
    static let all: [Genre] = [.Action, .Comedy, .Drama, .Horror, .Thriller]
}



