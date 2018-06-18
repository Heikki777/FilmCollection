//
//  Credits.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 28/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct Credits: Decodable{
    var crew: [CrewMember] = []
    var cast: [CastMember] = []
    
    init(){
        self.crew = []
        self.cast = []
    }
    
    init(crew: [CrewMember], cast: [CastMember]){
        self.crew = crew
        self.cast = cast
    }
    
    private enum CodingKeys: String, CodingKey {
        case crew
        case cast
    }
}
