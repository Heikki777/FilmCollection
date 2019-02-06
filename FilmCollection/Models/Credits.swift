//
//  Credits.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 28/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

class Credits: Decodable {
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
    
    required init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            crew = try values.decode([CrewMember].self, forKey: .crew)
            cast = try values.decode([CastMember].self, forKey: .cast)
        }
        catch let error {
            print(error.localizedDescription)
            crew = []
            cast = []
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case crew
        case cast
    }
    

}

extension Credits: Encodable {
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(crew, forKey: .crew)
        try container.encode(cast, forKey: .cast)
    }
    
}
