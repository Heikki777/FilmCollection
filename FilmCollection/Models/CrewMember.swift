//
//  CrewMember.swift
//  FilmCollection
//
//  Created by Sofia Digital on 04/05/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct CrewMember: Decodable{
    var name: String?
    var creditId: String?
    var department: String?
    var id: Int?
    var gender: Int?
    var title: String?
    var job: String?
    var profilePath: String?
    var genreIDs: [Int]?
    var backdropPath: String?
    var posterPath: String?
    var originalLanguage: String?
    var originalTitle: String?
    var order: Int?
    
    private enum CodingKeys: String, CodingKey{
        case name
        case creditId = "credit_id"
        case department
        case id
        case job
        case title
        case gender
        case order
        case profilePath = "profile_path"
        case genreIDs = "genre_ids"
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
    }
}
