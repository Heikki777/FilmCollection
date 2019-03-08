//
//  RatingControlDelegate.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 4.2.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

protocol RatingControlDelegate: class {
    
    func ratingChanged(newRating: Rating)
    
}
