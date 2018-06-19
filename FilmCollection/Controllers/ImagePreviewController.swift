//
//  ImagePreviewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 31.1.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class ImagePreviewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var identifier: String = ""
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.contentMode = .scaleAspectFit
        if let image = image{
            imageView.image = image
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
