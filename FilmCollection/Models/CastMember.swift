//
//  CastMember.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 04/05/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct CastMember: Codable{
    var castId: Int?
    var gender: Int?
    var name: String?
    var character: String?
    var creditId: String?
    var releaseDate: String?
    var title: String?
    var genreIDs: [Int]?
    var originalLanguage: String?
    var originalTitle: String?
    var id: Int?
    var profilePath: String?
    var backdropPath: String?
    var posterPath: String?
    var overview: String?
    var order: Int?
    
    enum CodingKeys: String, CodingKey{
        case character
        case castId = "cast_id"
        case creditId = "credit_id"
        case id
        case gender
        case title
        case profilePath = "profile_path"
        case genreIDs = "genre_ids"
        case releaseDate = "release_date"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case order
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case overview
        case name
    }
}

//extension CastMember: Encodable {
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(name, forKey: .name)
//        try container.encode(creditId, forKey: .creditId)
//        try container.encode(castId, forKey: .castId)
//        try container.encode(id, forKey: .id)
//        try container.encode(character, forKey: .character)
//        try container.encode(title, forKey: .title)
//        try container.encode(gender, forKey: .gender)
//        try container.encode(order, forKey: .order)
//        try container.encode(profilePath, forKey: .profilePath)
//        try container.encode(genreIDs, forKey: .genreIDs)
//        try container.encode(backdropPath, forKey: .backdropPath)
//        try container.encode(posterPath, forKey: .posterPath)
//        try container.encode(originalLanguage, forKey: .originalLanguage)
//        try container.encode(originalTitle, forKey: .originalTitle)
//        try container.encode(overview, forKey: .overview)
//        try container.encode(order, forKey: .order)
//
//    }
//}
