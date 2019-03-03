//
//  ImageCollectionViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 23/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func configure(imageUrl: URL?){
        self.backgroundColor = .black
        guard let imageUrl = imageUrl else {
            imageView.image = nil
            return
        }
        Nuke.loadImage(with: imageUrl, options: ImageLoadingOptions(transition: .fadeIn(duration: 0.33)), into: imageView, progress: nil, completion: nil)
    }
}
