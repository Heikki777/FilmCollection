//
//  SortOrder.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 25.2.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

enum SortOrder{
    case ascending
    case descending
    
    var symbol: Character{
        return (self == .descending) ? "↓" : "↑"
    }
    
    mutating func toggle(){
        switch self {
        case .ascending:
            self = .descending
        case .descending:
            self = .ascending
        }
    }
}
