//
//  Segue.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 31/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation

enum Segue: String{
    case showFilmDetailSegue
    case unwindFromDetailToFilmPosterCollectionVC
    case unwindToFilmDetailFromReviewSegue
    case showVideoPlayerSegue
    case showSortOptionsSegue
    case showReviewSegue
    case postSignInSegue
    case showFilmographySegue
    case showBiographySegue
    case showNotificationRepetitionOptions
}
