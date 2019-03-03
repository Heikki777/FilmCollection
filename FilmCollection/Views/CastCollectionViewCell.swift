//
//  CastCollectionViewCell
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class CastCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var actorNameLabel: UILabel!
    @IBOutlet weak var characterNameLabel: UILabel!
    
    var imageUrl: URL?
    
    func reset(){
        actorNameLabel.text = ""
        characterNameLabel.text = ""
        imageView.image = nil
    }
    
    func configure(with castMember: CastMember, imageUrl: URL?){
        // Reset
        reset()
        
        // Actor name
        actorNameLabel.text = castMember.name
        
        // Character name
        characterNameLabel.text = castMember.character
        
        // Image
        self.imageUrl = imageUrl
        if let imageUrl = imageUrl {
            Nuke.loadImage(with: imageUrl, into: imageView)
        }
    }
}
