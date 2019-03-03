//
//  ImagePreviewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 31.1.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class ImagePreviewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var identifier: String = ""
    var imageUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.contentMode = .scaleAspectFit
        if let imageUrl = imageUrl {
            Nuke.loadImage(with: imageUrl, into: imageView)
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
