//
//  CrewCollectionViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 03/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class CrewCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var personNameLabel: UILabel!
    @IBOutlet weak var jobLabel: UILabel!
    
    func reset(){
        personNameLabel.text = ""
        jobLabel.text = ""
        imageView.image = nil
    }
    
    func configure(with crewMember: CrewMember, image: UIImage?){
        // Reset
        reset()
        
        // Actor name
        personNameLabel.text = crewMember.name
        
        // Character name
        jobLabel.text = crewMember.job
        
        // Image
        self.imageView.image = image

    }
}
