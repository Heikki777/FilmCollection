//
//  Youtube.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 21.2.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

struct Youtube{
    static func createVideoEmbedURL(withID id: String) -> URL?{
        guard let youtubeURL = URL(string: "https://www.youtube.com/embed/\(id)?playsinline=1&autoplay=true") else {
            return nil
        }
        return youtubeURL
    }
}
