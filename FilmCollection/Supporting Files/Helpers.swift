//
//  Helpers.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 31.1.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

func pluralS(_ word: String, count: Int) -> String{
    return (count > 1) ? "\(word)s" : "\(word)"
}
