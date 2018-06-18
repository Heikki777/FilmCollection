//
//  SortingRule
//  FilmCollection
//
//  Created by Heikki Hämälistö on 23/02/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

enum SortingRule: String{
    case title
    case year
    case rating
    
    static var all: [SortingRule]{
        return [.title, .year, .rating]
    }
}
