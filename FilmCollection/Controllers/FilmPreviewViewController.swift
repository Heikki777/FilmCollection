//
//  FilmPreviewViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 22/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class FilmPreviewViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var film: Film?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let film = film else { return }
        
        if let posterPath = film.posterPath {
            let posterURL = TMDBApi.getImageURL(size: .w500, imagePath: posterPath)
            Nuke.loadImage(with: posterURL, into: imageView)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
