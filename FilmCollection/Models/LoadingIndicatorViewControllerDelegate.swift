//
//  LoadingIndicatorViewControllerDelegate.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 21/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import Foundation

protocol LoadingIndicatorViewControllerDelegate: class {
    
    func shouldShowCancelButton() -> Bool
    
    func loadingIndicatorViewControllerCancelButtonPressed()
}
