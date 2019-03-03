//
//  PersonCredits.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 21/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

class PersonCredits: Decodable {
    var name: String
    var profilePath: String?
    var crew: [CrewMember]
    var cast: [CastMember]
    
    init(name: String, profilePath: String?, crewRoles: [CrewMember], castRoles: [CastMember]) {
        self.name = name
        self.profilePath = profilePath
        self.crew = crewRoles
        self.cast = castRoles
    }
}
