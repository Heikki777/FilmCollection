//
//  FilmographyCollectionViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 19/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

private let reuseIdentifier = "filmographyMovieCell"

enum FilmographyCollectionViewControllerError: Error{
    case PosterPathMissing
}

class FilmographyCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let filmCollection = FilmCollection.shared
    var personCredits: Credits?
    var personName: String?
    var profilePath: String?
    var postersDictionary: [String: URL] = [:]
    
    lazy var api: TMDBApi = {
        return TMDBApi.shared
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        backgroundImageView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setup(){
        
        guard let personCredits = self.personCredits else {
            return
        }
        
        navigationItem.title = personName ?? ""
        
        // Load background image
        if let profilePath = profilePath {
            let url = TMDBApi.getImageURL(size: .w780, imagePath: profilePath)
            Nuke.loadImage(with: url, into: backgroundImageView)
        }
        
        // Load movie posters
        let castRolesPosterPaths = personCredits.cast.map { (title: $0.title, posterPath:$0.posterPath) }.filter { $0.title != nil }
        let crewRolesPosterPaths = personCredits.crew.map { (title: $0.title, posterPath:$0.posterPath) }.filter { $0.title != nil }
        var allPosterPaths = castRolesPosterPaths + crewRolesPosterPaths
        allPosterPaths = allPosterPaths.filter { $0.title != nil }

        allPosterPaths.forEach { (movie) in
            let title = movie.title!
            if let path = movie.posterPath {
                let url = TMDBApi.getImageURL(size: .w92, imagePath: path)
                self.postersDictionary[title] = url
            }
        }
        collectionView.reloadData()
    }

}

extension FilmographyCollectionViewController: UICollectionViewDataSource{
    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let personCredits = personCredits else {
            return 0
        }
        
        switch section{
        case 0:
            return personCredits.cast.count
        case 1:
            return personCredits.crew.count
        default:
            return 0
        }
       
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FilmographyCollectionViewCell
        
        guard let personCredits = personCredits else {
            return cell
        }
        
        cell.imageView.image = nil
        
        // CastMember
        if indexPath.section == 0 {
            let role = personCredits.cast[indexPath.row]
            let imageURL: URL? = (role.title != nil) ? postersDictionary[role.title!] : nil
            cell.configure(withCastRole: role, imageURL: imageURL)
        }
        
        // CrewMember
        else {
            let role = personCredits.crew[indexPath.row]
            let imageURL: URL? = (role.title != nil) ? postersDictionary[role.title!] : nil
            cell.configure(withCrewRole: role, imageURL: imageURL)
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
        
        guard let personCredits = personCredits else { return }
        
        guard let filmID = (indexPath.section == 0) ? personCredits.cast[indexPath.row].id : personCredits.crew[indexPath.row].id else {
            return
        }
        
        guard let filmTitle = (indexPath.section == 0) ? personCredits.cast[indexPath.row].title : personCredits.crew[indexPath.row].title else {
            return
        }
            
        let filmIsInCollection = appDelegate.filmEntities.filter { Int($0.id) == filmID }.count > 0
        let message = filmIsInCollection ? "In the collection" : "Not in the collection"
        let alert = UIAlertController.init(title: filmTitle, message: message, preferredStyle: .actionSheet)
        
        if !filmIsInCollection{
            // The film is not in the collection
            
            // Add film action
            let addMovieToCollectionAction = UIAlertAction(title: "Add to collection", style: .default, handler: { (action) in
                
                let context = self.appDelegate.persistentContainer.viewContext
                let newFilm = FilmEntity(context: context)
                newFilm.id = Int32(filmID)
                
                if self.appDelegate.filmEntities.filter({ $0.id == filmID }).isEmpty {
                    let title = "Add a new film"
                    let message = "Are you sure that you want to add the film: \"\(filmTitle)\" to your collection?"
                    let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
                    let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { _ in
                        FilmCollection.shared.addNewFilm(withId: filmID)
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alert.addAction(cancelAction)
                    alert.addAction(yesAction)
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    let title = "The film was not added"
                    let message = "The film: \"\(filmTitle)\" is already in the collection"
                    let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
                    let okAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            })
            
            // Show film detail action
            let showMovieDetailAction = UIAlertAction(title: "Show film detail", style: .default, handler: { (action) in
            })
        
            alert.addAction(showMovieDetailAction)
            alert.addAction(addMovieToCollectionAction)
        }
        else{
            // The movie is in the collection
            
            // Show movie detail action
            let showMovieDetailAction = UIAlertAction(title: "Show film detail", style: .default, handler: { (action) in
                if let filmDetailVC = (self.navigationController?.viewControllers.filter({ (vc) -> Bool in
                    return vc is FilmDetailViewController
                }).first as? FilmDetailViewController){
                    filmDetailVC.reset()
                    filmDetailVC.film = self.filmCollection.getFilm(withId: filmID)
                    filmDetailVC.setup()
                    self.navigationController?.popToViewController(filmDetailVC, animated: true)
                }
            })
            
            let removeMovieFromCollectionAction = UIAlertAction(title: "Remove from the collection", style: .destructive, handler: { (action) in
                if let film = FilmCollection.shared.getFilm(withId: filmID){
                    FilmCollection.shared.removeFilm(film)
                }
            })
            
            alert.addAction(showMovieDetailAction)
            alert.addAction(removeMovieFromCollectionAction)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
