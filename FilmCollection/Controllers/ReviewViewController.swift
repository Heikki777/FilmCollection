//
//  ReviewViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import CoreData
import Nuke

class ReviewViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ratingControl: RatingControl!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    
    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
    weak var film: Film?
    
    deinit {
        print("deinit ReviewViewController")
    }
    
    @IBAction func save(_ sender: Any) {
        
        guard let film = film else{
            return
        }
        
        if let filmEntity = film.entity {
            filmEntity.review = textView.text
            filmEntity.rating = Int16(ratingControl.rating.rawValue)
            film.review = textView.text
            film.rating = ratingControl.rating
            appDelegate?.saveContext()
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.filmReviewed.name, object: film)
            self.showAlert(title: "Saved", message: "The review has been saved")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let film = film else{
            return
        }
        
        titleLabel.text = "Review the movie: \(film.titleYear)"
        ratingControl.ratingControlDelegate = self
        ratingControl.rating = film.rating
        textView.layer.cornerRadius = 5
        textView.text = film.review
        
        if let posterPath = film.posterPath {
            Nuke.loadImage(with: TMDBApi.getImageURL(size: .w780, imagePath: posterPath), into: backgroundImageView)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ReviewViewController: RatingControlDelegate{
    
    func ratingChanged(newRating: Rating) {
        ratingLabel.text = newRating.description
    }
}
