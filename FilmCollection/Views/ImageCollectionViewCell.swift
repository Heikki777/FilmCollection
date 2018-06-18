//
//  ImageCollectionViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 23/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func configure(image: UIImage?){
        imageView.image = image
    }
}
