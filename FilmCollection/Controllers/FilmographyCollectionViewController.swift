//
//  FilmographyCollectionViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 19/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import PromiseKit
import Firebase


private let reuseIdentifier = "filmographyMovieCell"

enum FilmographyCollectionViewControllerError: Error{
    case PosterPathMissing
}

class FilmographyCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var user: User?
    var personCredits: PersonCredits = PersonCredits()
    var backgroundImage: UIImage?{
        didSet{
            backgroundImageView.image = backgroundImage
        }
    }
    var postersDictionary: [String: UIImage] = [:]
    
    lazy var api: TMDBApi = {
        return TMDBApi.shared
    }()
    
    // Firebase
    lazy var databaseRef: DatabaseReference = {
        return Database.database().reference()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = Auth.auth().currentUser
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        navigationItem.title = personCredits.name
        backgroundImageView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3)
        backgroundImageView.image = backgroundImage
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setup(){
        let loadingIndicator = LoadingIndicatorViewController(title: "Loading \(personCredits.name) movies", message: "", complete: {
            self.collectionView.reloadData()
        })
        
        var thingsToLoad: Int = 0
        var thingsLoaded: Int = 0{
            didSet{
                let progress = Float(thingsLoaded) / Float(thingsToLoad)
                loadingIndicator.setProgress(progress)
                if thingsLoaded == thingsToLoad{
                    loadingIndicator.finish()
                }
            }
        }
        
        // Load background image
        if let profilePath = personCredits.profilePath{
            thingsToLoad += 1
            let url = TMDBApi.getPosterURL(size: .w780, imagePath: profilePath)
            Downloader.shared.loadImage(url: url)
            .done({ (image) in
                self.backgroundImage = image
            })
            .catch({ (error) in
                print(error.localizedDescription)
            })
            .finally {
                thingsLoaded += 1
            }
        }
        
        // Load movie posters
        thingsToLoad += personCredits.castRoles.count + personCredits.crewRoles.count
        
        self.tabBarController?.present(loadingIndicator, animated: true, completion: nil)
        
        let allPosterPaths: [(title: String?, posterPath: String?)] = personCredits.castRoles.map { (title: $0.title, posterPath:$0.posterPath) } + personCredits.crewRoles.map { ($0.title, posterPath:$0.posterPath) }
        
        allPosterPaths.forEach { (movie) in
            if let title = movie.title{
                if let path = movie.posterPath {
                    let url = TMDBApi.getPosterURL(size: .w92, imagePath: path)
                    attempt{
                        Downloader.shared.loadImage(url: url)
                    }
                    .done({ image in
                        self.postersDictionary[title] = image
                    })
                    .catch({ error in
                        self.postersDictionary[title] = #imageLiteral(resourceName: "placeholder_image")
                    })
                    .finally{
                        thingsLoaded += 1
                    }
                }
                else{
                    self.postersDictionary[title] = #imageLiteral(resourceName: "placeholder_image")
                    thingsLoaded += 1
                }
            }
            else{
                thingsLoaded += 1
            }
        }
        
    }

}

extension FilmographyCollectionViewController: UICollectionViewDataSource{
    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section{
        case 0:
            return personCredits.castRoles.count
        case 1:
            return personCredits.crewRoles.count
        default:
            return 0
        }
       
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FilmographyCollectionViewCell
        cell.imageView.image = nil
        cell.backgroundColor = UIColor.clear
        
        // CastMember
        if indexPath.section == 0 {
            let role = personCredits.castRoles[indexPath.row]
            if let title = role.title{
                cell.titleLabel.text = title
                if let image = postersDictionary[title]{
                    cell.imageView.image = image
                    if image == #imageLiteral(resourceName: "placeholder_image"){
                        cell.imageView.backgroundColor = UIColor.lightGray
                    }
                }
                cell.roleLabel.text = role.character ?? ""
            }
        }
        
        // CrewMember
        else {
            let role = personCredits.crewRoles[indexPath.row]
            if let title = role.title{
                if let image = postersDictionary[title]{
                    cell.imageView.image = image
                    if image == #imageLiteral(resourceName: "placeholder_image"){
                        cell.imageView.backgroundColor = UIColor.lightGray
                    }
                }
                cell.titleLabel.text = title
                cell.roleLabel.text = role.job ?? ""
            }
        }
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FilmographyCollectionReusableView.reuseIdentifier, for: indexPath) as! FilmographyCollectionReusableView

        switch indexPath.section {
        
        case 0:
            view.label.text = "Cast"
        case 1:
            view.label.text = "Crew"
        default:
            view.label.text = ""
        }

        return view
    }
}

extension FilmographyCollectionViewController: UICollectionViewDelegate{
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let user = user else{
            print("Error! No user")
            return
        }
        
        guard let id = (indexPath.section == 0) ? personCredits.castRoles[indexPath.row].id : personCredits.crewRoles[indexPath.row].id else{
            return
        }
        
        guard let movieTitle = (indexPath.section == 0) ? personCredits.castRoles[indexPath.row].title : personCredits.crewRoles[indexPath.row].title else {
            return
        }
        
        databaseRef.child("user-movies").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshotValue = snapshot.value as? [String:[String:Any]] else{
                print("No snapshot value")
                return
            }
            
            let movieIsInCollection = snapshotValue["\(id)"] != nil
            let message = movieIsInCollection ? "In the collection" : "Not in the collection"
            let alert = UIAlertController.init(title: movieTitle, message: message, preferredStyle: .actionSheet)
            
            
            if !movieIsInCollection{
                // The movie is not in the collection
                
                // Add movie action
                let addMovieToCollectionAction = UIAlertAction(title: "Add to collection", style: .default, handler: { (action) in
            
                    let title = "Movie added"
                    let message = "The movie \(movieTitle) was added."
            
                    self.databaseRef.child("user-movies").child("\(user.uid)").child("\(id)").setValue(
                        [
                            "id": id,
                            "rating": Rating.NotRated.rawValue,
                            "review": ""
                        ]
                    )
            
                    let movieAdditionAlert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
                    movieAdditionAlert.addAction(okAction)
                    self.present(movieAdditionAlert, animated: true, completion: nil)
                })
                
                // Show movie detail action
                let showMovieDetailAction = UIAlertAction(title: "Show movie detail", style: .default, handler: { (action) in
                    let loadingIndicator = LoadingIndicatorViewController(title: "Loading movie", message: movieTitle, complete: nil)
                    var progress: Float = 0
                    var loaded: Float = 0
                    let thingsToLoad: Float = 1
                    
                    self.tabBarController?.present(loadingIndicator, animated: true, completion: nil)
                    
                    let progressChanged: (String) -> () = { (infoMessage) in
                        print(infoMessage)
                        loaded += 1
                        progress = loaded / thingsToLoad
                        loadingIndicator.setProgress(progress)
                        if loaded == thingsToLoad{
                            loadingIndicator.finish()
                        }
                    }
                    
                    loadingIndicator.setProgress(progress)
                    attempt{
                        self.api.loadMovie(id, append: ["credits"]).ensure { progressChanged("Movie loaded") }
                    }
                    .done{ (movie) in
                        if let filmCollectionVC = (self.navigationController?.viewControllers.filter({ (vc) -> Bool in
                            return vc is FilmCollectionTableViewController
                        }).first as? FilmCollectionTableViewController){
                            
                            if let filmDetailVC = (self.navigationController?.viewControllers.filter({ (vc) -> Bool in
                                return vc is FilmDetailViewController
                            }).first as? FilmDetailViewController){
                                filmDetailVC.reset()
                                filmDetailVC.movie = movie
                                filmDetailVC.setup()
                                self.navigationController?.popToViewController(filmDetailVC, animated: true)
                                
                            }
                        }
                        
                    }
                    .catch{ (error) in
                        print(error.localizedDescription)
                    }
                })
            
                alert.addAction(showMovieDetailAction)
                alert.addAction(addMovieToCollectionAction)
            }
            else{
                // The movie is in the collection
                
                // Show movie detail action
                let showMovieDetailAction = UIAlertAction(title: "Show movie detail", style: .default, handler: { (action) in
                    if let filmCollectionVC = (self.navigationController?.viewControllers.filter({ (vc) -> Bool in
                        return vc is FilmCollectionTableViewController
                    }).first as? FilmCollectionTableViewController){
                        
                        if let filmDetailVC = (self.navigationController?.viewControllers.filter({ (vc) -> Bool in
                            return vc is FilmDetailViewController
                        }).first as? FilmDetailViewController){
                            filmDetailVC.reset()
                            filmDetailVC.movie = filmCollectionVC.getMovie(withId: id)
                            filmDetailVC.setup()
                            self.navigationController?.popToViewController(filmDetailVC, animated: true)
                            
                        }
                    }
                })
                
                let removeMovieFromCollectionAction = UIAlertAction(title: "Remove from the collection", style: .destructive, handler: { (action) in
                    if let user = self.user{
                        self.databaseRef.child("user-movies").child(user.uid).child("\(id)").removeValue()
                    }
                })
                
                alert.addAction(showMovieDetailAction)
                alert.addAction(removeMovieFromCollectionAction)
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
}
