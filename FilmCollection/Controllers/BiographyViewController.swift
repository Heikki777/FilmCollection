//
//  BiographyViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 25/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class BiographyViewController: UIViewController {

    var personImage: UIImage?
    var personDetailInformation: PersonDetailInformation?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var biographyTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let personDetailInformation = personDetailInformation else{
            print("BiographyViewController: Error! personDetailInformation is nil")
            return
        }
        
        imageView.contentMode = .scaleAspectFit
        navigationItem.title = personDetailInformation.name
        biographyTextView.text = personDetailInformation.biography
        
        if let personImage = personImage{
            self.imageView.image = personImage
        }
        else if let profilePath = personDetailInformation.profilePath{
            let url = TMDBApi.getPosterURL(size: .w342, imagePath: profilePath)
            Downloader.shared.loadImage(url: url)
            .done({ (image) in
                self.personImage = image
                self.imageView.image = image
            })
            .catch({ (error) in
                print(error.localizedDescription)
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
