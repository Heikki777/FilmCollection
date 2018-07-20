//
//  FilmNotification.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 16/07/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct FilmNotification{
    struct Category {
        static let randomRecommendation = "randomRecommendation"
    }
    
    struct Action {
        static let showDetails = "showDetails"
        static let unsubscribe = "unsubscribe"
    }
}
