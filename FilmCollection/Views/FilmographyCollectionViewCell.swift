//
//  FilmographyCollectionViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 19/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class FilmographyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    
    func reset(){
        imageView.image = #imageLiteral(resourceName: "placeholder_image")
        titleLabel.text = ""
        roleLabel.text = ""
    }
}

