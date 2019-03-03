//
//  FilmographyCollectionViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 19/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class FilmographyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    
    static let placeHolder = UIImage(named: "placeholder_image")
    
    func reset(){
        imageView.image = FilmographyCollectionViewCell.placeHolder
        titleLabel.text = ""
        roleLabel.text = ""
    }
    
    func configure(withCastRole role: CastMember, imageURL: URL?){
        titleLabel.text = role.title
        roleLabel.text = role.character
        setImage(withURL: imageURL)
    }
    
    func configure(withCrewRole role: CrewMember, imageURL: URL?){
        titleLabel.text = role.title
        roleLabel.text = role.job
        setImage(withURL: imageURL)
    }
    
    private func setImage(withURL url: URL?){
        if let imageURL = url {
            Nuke.loadImage(
                with: imageURL,
                options: ImageLoadingOptions(
                    placeholder: FilmographyCollectionViewCell.placeHolder,
                    transition: .fadeIn(duration: 0.33),
                    failureImage: FilmographyCollectionViewCell.placeHolder,
                    failureImageTransition: .fadeIn(duration: 0.33),
                    contentModes: nil
                ),
                into: imageView,
                progress: nil,
                completion: nil
            )
        }
        else {
            imageView.image = FilmographyCollectionViewCell.placeHolder
        }
    }
}

