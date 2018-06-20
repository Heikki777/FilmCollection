//
//  CastMember.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 04/05/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct CastMember: Decodable{
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
    
    private enum CodingKeys: String, CodingKey{
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
