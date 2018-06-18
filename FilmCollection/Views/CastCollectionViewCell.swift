//
//  CastCollectionViewCell
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import PromiseKit

class CastCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var actorNameLabel: UILabel!
    @IBOutlet weak var characterNameLabel: UILabel!
    
    func reset(){
        actorNameLabel.text = ""
        characterNameLabel.text = ""
        imageView.image = nil
    }
    
    func configure(with castMember: CastMember, image: UIImage?){
        // Reset
        reset()
        
        // Actor name
        actorNameLabel.text = castMember.name
        
        // Character name
        characterNameLabel.text = castMember.character
        
        // Image
        self.imageView.image = image
    }
}
