//
//  Rating.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 3.2.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

enum Rating: Int, Comparable{
    case NotRated = 0
    case Awful
    case Weak
    case OK
    case Good
    case VeryGood
    case Excellent
    case Masterpiece
    
    static let all: [Rating] = [.NotRated, .Awful, .Weak, .OK, .Good, .VeryGood, Excellent, .Masterpiece]
    
    static func <(lhs: Rating, rhs: Rating) -> Bool{
        return lhs.rawValue < rhs.rawValue
    }
    
    static func >(lhs: Rating, rhs: Rating) -> Bool{
        return lhs.rawValue > rhs.rawValue
    }
    
    init?(string: String) {
        switch string {
        case Rating.NotRated.description: self = .NotRated
        case Rating.Awful.description: self = .Awful
        case Rating.Weak.description: self = .Weak
        case Rating.OK.description: self = .OK
        case Rating.Good.description: self = .Good
        case Rating.Excellent.description: self = .Excellent
        case Rating.Masterpiece.description: self = .Masterpiece
        default: return nil
        }
    }
    
    var description: String{
        switch self {
        case .NotRated:
            return "Not rated"
        case .Awful:
            return "Awful"
        case .Weak:
            return "Weak"
        case .OK:
            return "OK"
        case .Good:
            return "Good"
        case .VeryGood:
            return "Very good"
        case .Excellent:
            return "Excellent"
        case .Masterpiece:
            return "Masterpiece"
        }
    }
}
