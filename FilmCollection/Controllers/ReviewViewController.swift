//
//  ReviewViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class ReviewViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ratingControl: RatingControl!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    
    var film: Movie?
    var backgroundImage: UIImage?
    
    lazy var databaseRef: DatabaseReference = {
        return Database.database().reference()
    }()
    
    @IBAction func save(_ sender: Any) {
        
        guard let film = film else{
            return
        }
        
        let loadingIndicator = LoadingIndicatorViewController(title: "Saving", message: nil, complete: nil)
        loadingIndicator.progressView.isHidden = true
        present(loadingIndicator, animated: true, completion: nil)
        
        guard let user = Auth.auth().currentUser else {
            loadingIndicator.finish()
            self.showAlert(title: "Error", message: "The changes could not be saved")
            return
        }
    
        self.databaseRef.child("user-movies").child("\(user.uid)").child("\(film.id)").updateChildValues([
            "rating":ratingControl.rating.rawValue,
            "review":textView.text
        ])
        
        loadingIndicator.finish()
        self.showAlert(title: "Saved", message: "The review was saved successfully")
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
