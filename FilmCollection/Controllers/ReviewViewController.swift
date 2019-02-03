//
//  ReviewViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import CoreData

class ReviewViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ratingControl: RatingControl!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var film: Movie?
    var backgroundImage: UIImage?
    
    @IBAction func save(_ sender: Any) {
        
        guard let film = film else{
            return
        }
        
        if let filmEntity = film.entity {
            filmEntity.review = textView.text
            filmEntity.rating = Int16(ratingControl.rating.rawValue)
            film.review = textView.text
            film.rating = ratingControl.rating
            appDelegate.saveContext()
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.filmReviewed.name, object: film)
            self.showAlert(title: "Saved", message: "The review has been saved")
        }
    }
    
    func showAlert(title: String, message: String){
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let film = film else{
            print("ReviewViewController Error! No movie")
            return
        }
        
        titleLabel.text = "Review the movie: \(film.titleYear)"
        ratingControl.delegate = self
        ratingControl.rating = film.rating
        textView.layer.cornerRadius = 5
        textView.text = film.review
        
        backgroundImageView.image = backgroundImage
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
