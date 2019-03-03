//
//  BiographyViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 25/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class BiographyViewController: UIViewController {

    var personImageURL: URL!
    var personDetailInformation: PersonDetailInformation!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var biographyTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let personDetailInformation = personDetailInformation else{
            return
        }
        
        imageView.contentMode = .scaleAspectFit
        navigationItem.title = personDetailInformation.name
        biographyTextView.text = personDetailInformation.biography
        
        Nuke.loadImage(with: personImageURL, options: ImageLoadingOptions(placeholder: nil, transition: .fadeIn(duration: 0.33), failureImage: nil, failureImageTransition: nil, contentModes: nil), into: imageView, progress: nil, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
