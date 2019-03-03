//
//  CrewCollectionViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 03/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class CrewCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var personNameLabel: UILabel!
    @IBOutlet weak var jobLabel: UILabel!
    
    var imageUrl: URL?
    
    func reset(){
        personNameLabel.text = ""
        jobLabel.text = ""
        imageView.image = nil
    }
    
    func configure(with crewMember: CrewMember, imageUrl: URL?){
        // Reset
        reset()
        
        // Actor name
        personNameLabel.text = crewMember.name
        
        // Character name
        jobLabel.text = crewMember.job
        
        // Image
        self.imageUrl = imageUrl
        if let imageUrl = imageUrl {
            Nuke.loadImage(with: imageUrl, into: imageView)
        }

    }
}
