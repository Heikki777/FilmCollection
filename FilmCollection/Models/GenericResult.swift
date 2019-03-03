//
//  GenericResult.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 26/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import Foundation

enum GenericResult<T> {
    case success(T)
    case failure(Error)
}
