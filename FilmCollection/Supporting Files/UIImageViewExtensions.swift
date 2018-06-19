//
//  UIImageViewExtensions.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 19/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = self.image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }
        
        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.size.width / image.size.width
        } else {
            scale = bounds.size.height / image.size.height
        }
        
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        return CGRect(x: self.frame.minX, y: self.frame.minY, width: size.width, height: size.height)
    }
}
