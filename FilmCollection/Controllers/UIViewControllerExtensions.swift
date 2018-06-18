//
//  UIViewControllerExtensions.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 03/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    var isVisible: Bool{
        return self.isViewLoaded && (self.view.window != nil)
    }
}
