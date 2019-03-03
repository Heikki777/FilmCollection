//
//  FilmPosterCollectionViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 07/07/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class FilmPosterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var posterImageView: UIImageView!

    var film: Film?
    
    func configure(withFilm film: Film?){
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.posterImageView.image = nil
            strongSelf.film = film
            
            // Image
            if let posterPath = film?.posterPath {
                let posterURL = TMDBApi.getImageURL(size: .w92, imagePath: posterPath)
                Nuke.loadImage(with: posterURL, into: strongSelf.posterImageView)
            }
        }
    }
    
}
