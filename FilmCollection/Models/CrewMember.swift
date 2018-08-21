//
//  CrewMember.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 04/05/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct CrewMember: Codable{
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
    
    enum CodingKeys: String, CodingKey{
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
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case posterPath = "poster_path"
    }
}


//extension CrewMember: Encodable {
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(name, forKey: .name)
//        try container.encode(creditId, forKey: .creditId)
//        try container.encode(department, forKey: .department)
//        try container.encode(id, forKey: .id)
//        try container.encode(job, forKey: .job)
//        try container.encode(title, forKey: .title)
//        try container.encode(gender, forKey: .gender)
//        try container.encode(order, forKey: .order)
//        try container.encode(profilePath, forKey: .profilePath)
//        try container.encode(genreIDs, forKey: .genreIDs)
//        try container.encode(backdropPath, forKey: .backdropPath)
//        try container.encode(posterPath, forKey: .posterPath)
//        try container.encode(originalLanguage, forKey: .originalLanguage)
//        try container.encode(originalTitle, forKey: .originalTitle)
//    }
//}
