//
//  PersonCredits.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 21/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

class PersonCredits{
    var name: String
    var profilePath: String?
    var crewRoles: [CrewMember]
    var castRoles: [CastMember]
    
    init(name: String, profilePath: String?, crewRoles: [CrewMember], castRoles: [CastMember]) {
        self.name = name
        self.profilePath = profilePath
        self.crewRoles = crewRoles
        self.castRoles = castRoles
    }
    
    convenience init() {
        self.init(name: "", profilePath: nil, crewRoles: [], castRoles: [])
    }
}
