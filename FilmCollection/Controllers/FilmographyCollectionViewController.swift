//
//  FilmographyCollectionViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 19/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import PromiseKit

private let reuseIdentifier = "filmographyMovieCell"

enum FilmographyCollectionViewControllerError: Error{
    case PosterPathMissing
}

class FilmographyCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let filmCollection = FilmCollection.shared
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        guard let filmID = (indexPath.section == 0) ? personCredits.castRoles[indexPath.row].id : personCredits.crewRoles[indexPath.row].id else {
            return
        }
        
        guard let filmTitle = (indexPath.section == 0) ? personCredits.castRoles[indexPath.row].title : personCredits.crewRoles[indexPath.row].title else {
            return
        }
    
        let filmIsInCollection = appDelegate.filmEntities.filter { Int($0.id) == filmID }.count == 1
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
                        self.appDelegate.filmCollectionEntity.addToFilms(newFilm)
                        self.appDelegate.saveContext()
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
                let loadingIndicator = LoadingIndicatorViewController(title: "Loading film", message: filmTitle, complete: nil)
                var progress: Float = 0
                var loaded: Float = 0
                let thingsToLoad: Float = 1
                
                self.tabBarController?.present(loadingIndicator, animated: true, completion: {
                    
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
                        self.api.loadMovie(filmID, append: ["credits"]).ensure { progressChanged("Film loaded") }
                    }
                    .done{ (film) in
                        if let filmDetailVC = (self.navigationController?.viewControllers.filter({ (vc) -> Bool in
                            return vc is FilmDetailViewController
                        }).first as? FilmDetailViewController){
                            filmDetailVC.reset()
                            filmDetailVC.film = film
                            filmDetailVC.setup()
                            self.navigationController?.popToViewController(filmDetailVC, animated: true)
                        }
                    }
                    .catch{ (error) in
                        print(error.localizedDescription)
                    }
                })
            })
        
            alert.addAction(showMovieDetailAction)
            alert.addAction(addMovieToCollectionAction)
        }
        else{
            // The movie is in the collection
            
            // Show movie detail action
            let showMovieDetailAction = UIAlertAction(title: "Show movie detail", style: .default, handler: { (action) in
                if let filmDetailVC = (self.navigationController?.viewControllers.filter({ (vc) -> Bool in
                    return vc is FilmDetailViewController
                }).first as? FilmDetailViewController){
                    filmDetailVC.reset()
                    filmDetailVC.film = self.filmCollection.getMovie(withId: filmID)
                    filmDetailVC.setup()
                    self.navigationController?.popToViewController(filmDetailVC, animated: true)
                }
            })
            
            let removeMovieFromCollectionAction = UIAlertAction(title: "Remove from the collection", style: .destructive, handler: { (action) in
                if let film = FilmCollection.shared.getMovie(withId: filmID){
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
