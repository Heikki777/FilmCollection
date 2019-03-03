//
//  FilmDetailViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 31/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Alamofire
import EventKit
import Nuke

class FilmDetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var directorLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var imdbLogo: UIImageView!
    @IBOutlet weak var imdbRatingLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var playVideoButton: UIButton!
    @IBOutlet weak var castCollectionView: UICollectionView!
    @IBOutlet weak var crewCollectionView: UICollectionView!
    @IBOutlet weak var additionBarButton: UIBarButtonItem!
    @IBOutlet weak var removeBarButton: UIBarButtonItem!
    @IBOutlet weak var watchedBarButton: UIBarButtonItem!
    @IBOutlet weak var reviewBarButton: UIBarButtonItem!
    @IBOutlet weak var castHeaderLabel: UILabel!
    @IBOutlet weak var crewHeaderLabel: UILabel!
    @IBOutlet weak var reviewHeaderLabel: UILabel!
    @IBOutlet weak var reviewTextView: UITextView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let castLabel = UILabel()
    let crewLabel = UILabel()
    
    lazy var calendarManager: CalendarManager = {
       return CalendarManager(userViewController: self)
    }()
    
    @IBAction func removeFilm(_ sender: Any) {
        guard let film = film else{
            return
        }
        
        guard let filmEntities: Set<FilmEntity> = appDelegate.filmCollectionEntity.films as? Set<FilmEntity> else { return }
        if let filmEntity = filmEntities.filter({ Int($0.id) == film.id }).first {
            let alert = UIAlertController.init(title: "Remove film", message: "Are you sure that you want to remove the film \"\(film.title)\" from the collection?", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Remove", style: .destructive, handler: { (action) in
                // Remove
                self.appDelegate.filmCollectionEntity.removeFromFilms(filmEntity)
                self.appDelegate.saveContext()
                FilmCollection.shared.removeFilm(film)
                self.navigationController?.popViewController(animated: true)
            }))
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func handlePlusButtonTap(_ sender: UIBarButtonItem) {
        guard let film = film else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let newFilm = FilmEntity(context: context)
        newFilm.id = Int32(film.id)
        
        if appDelegate.filmEntities.filter({ $0.id == film.id }).isEmpty {
            let title = "Add a new film"
            let message = "Are you sure that you want to add the film: \"\(film.title)\" to your collection?"
            let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { _ in
                self.appDelegate.filmCollectionEntity.addToFilms(newFilm)
                self.appDelegate.saveContext()
                FilmCollection.shared.addFilm(film, resetDictionary: true)
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            alert.addAction(yesAction)
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let title = "The film was not added"
            let message = "The film: \"\(film.title)\" is already in the collection"
            let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func watched(_ sender: UIBarButtonItem) {
        
        guard let film = film else{
            return
        }
        if let filmEntity = appDelegate.filmEntities.filter({ (entity) -> Bool in
            return Int(entity.id) == film.id
        }).first {
            let context = appDelegate.persistentContainer.viewContext
            let viewing = Viewing(context: context)
            viewing.date = Date()
            viewing.title = film.title
            filmEntity.addToViewings(viewing)
            appDelegate.saveContext()
            self.showAlert(title: "Viewing saved", message: "\(film.title)\n\(self.dateFormatter.string(from: viewing.date!))")
        }
    }
    
    var fadeableViews: [UIView] = []
    
    enum ReuseIdentifiers: String{
        case creditCollectionViewCell
    }
    
    var film: Film?
    
    var featuredVideo: Video?{
        didSet{
            if let featuredVideo = featuredVideo{
                playVideoButton.isHidden = false
                playVideoButton.setTitle("Play \(featuredVideo.type) ▶︎", for: .normal)
            }
        }
    }
    
    var filmImages: FilmImages?
    
    var videos: [Video] = []{
        didSet{
            setFeaturedVideo()
        }
    }
    
    var castMembersWithImage: [CastMember]{
        return film?.credits.cast.filter({ (castMember) -> Bool in
            return castMember.profilePath != nil
        }) ?? []
    }
    
    var crewMembersWithImage: [CrewMember]{
        return film?.credits.crew.filter({ (crewMember) -> Bool in
            return crewMember.profilePath != nil
        }) ?? []
    }
    
    var castImages: [URL] = []
    var crewImages: [URL] = []
    
    var selectedCastMember: CastMember?
    var selectedCrewMember: CrewMember?

    lazy var api: TMDBApi = {
        return TMDBApi.shared
    }()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm"
        return formatter
    }()
    
    lazy var jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmReviewed(notification:)), name: Notifications.FilmCollectionNotification.filmReviewed.name, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {

        setup()
        fadeableViews.forEach { (view) in
            view.alpha = 0.0
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setContentHeight()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fadeIn()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        castCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
        crewCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setContentHeight()
    }
    
    @objc func handleFilmReviewed(notification: Notification) {
        guard let film = notification.object as? Film else { return }
        if let filmEntity = film.entity {
            film.rating = Rating(rawValue: Int(filmEntity.rating)) ?? .NotRated
            film.review = filmEntity.review
        }
        ratingLabel.text = film.rating.description
        reviewTextView.text = film.review
    }
    
    func setContentHeight(){
        var contentRect = CGRect.zero
        
        if let homeTabBarController = self.tabBarController as? HomeTabBarController {
            let tabBarHeight = homeTabBarController.tabBar.frame.height
            contentRect.union(CGRect(origin: .zero, size: CGSize(width: 0, height: tabBarHeight)))
        }
        
        for view in contentView.subviews {
            contentRect = contentRect.union(view.frame)
        }
        scrollView.contentSize = contentRect.size
    }
    
    func reset(){
        film = nil
        backgroundImageView.image = nil
        imageView.image = nil
        titleLabel.text = ""
        genreLabel.text = ""
        ratingLabel.text = ""
        directorLabel.text = ""
        durationLabel.text = ""
        playVideoButton.titleLabel?.text = ""
        playVideoButton.isHidden = true
        castImages = []
        crewImages = []
        castCollectionView.reloadData()
        crewCollectionView.reloadData()
    }
    
    
    func fadeIn(){
        let slowest = 3.0
        let fastest = 2.0
        let slowestFastestDiff = slowest - fastest
        var duration = 2.0
        
        fadeableViews.forEach { (view) in
            UIView.animate(withDuration: duration, animations: {
                view.alpha = 1.0
            })
            duration -= (slowestFastestDiff / Double(fadeableViews.count))
        }

    }
    
    func setup(){
        
        fadeableViews = [
            imageView,
            titleLabel,
            directorLabel,
            ratingLabel,
            imdbLogo,
            imdbRatingLabel,
            descriptionTextView,
            genreLabel,
            durationLabel,
            playVideoButton,
            castHeaderLabel,
            castLabel,
            castCollectionView,
            crewHeaderLabel,
            crewLabel,
            crewCollectionView,
            castHeaderLabel,
            crewHeaderLabel,
            reviewHeaderLabel,
            reviewTextView
        ]
                
        playVideoButton.isHidden = true
        
        guard let film = film else { return }
        
        // Bar buttons
        let filmIsInCollection = FilmCollection.shared.contains(film)
        additionBarButton.isEnabled = !filmIsInCollection
        removeBarButton.isEnabled = filmIsInCollection
        
        // Videos
        self.api.loadVideos(film.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let videoResponse):
                    self.videos = videoResponse.results
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        
        // Add tap gesture recognizer to the image view
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(imageTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        // Check if 3D Touch is available
        if traitCollection.forceTouchCapability == .available{
            registerForPreviewing(with: self, sourceView: view)
        }
        
        // MARK: - Set the movie title
        titleLabel.text = film.titleYear
        
        // Images
        if let posterPath = film.posterPath {
            // Small poster image
            Nuke.loadImage(with: TMDBApi.getImageURL(size: .w92, imagePath: posterPath), into: imageView)
            // Background image
            Nuke.loadImage(with: TMDBApi.getImageURL(size: .w780, imagePath: posterPath), into: backgroundImageView)
        }
        
        // Overview
        if let overview = film.overview{
            descriptionTextView.text = overview
            descriptionTextView.isScrollEnabled = false
            descriptionTextView.sizeToFit()
        }
        
        // Genre
        genreLabel.text = film.genres?.map({ (genre) -> String in
            return genre.name
        }).joined(separator: ", ")
        
        // Duration
        if let runtime = film.runtime{
            let hours = Int(runtime / 60)
            let minutes = runtime % 60
            var durationText = ""
            durationText += (hours > 0) ? "\(hours)h " : ""
            durationText += (minutes > 0) ? "\(minutes)min" : ""
            durationLabel.text = durationText
        }
        
        // Director
        let directors = film.directors
        directorLabel.isHidden = true
        if directors.count > 0{
            let directorsString = directors.compactMap{$0.name}.joined(separator: ", ")
            directorLabel.text = "\(pluralS("Director", count: directors.count)): \(directorsString)"
            directorLabel.isHidden = false
        }
        
        // Rating
        ratingLabel.text = "Rating: \(film.rating.description)"
        
        // IMDb Rating
        imdbRatingLabel.text = ""
        imdbLogo.isHidden = true
        imdbRatingLabel.isHidden = true
        
        if let imdbId = film.imdbId {
            IMDbAPI.shared.ratingForFilm(withIMDbId: imdbId) { result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .success(let imdbRating):
                        self?.imdbLogo.isHidden = false
                        self?.imdbRatingLabel.isHidden = false
                        self?.imdbRatingLabel.text = "\(imdbRating) / 10.0"
                    case .failure(let error):
                        self?.imdbLogo.isHidden = true
                        self?.imdbRatingLabel.isHidden = true
                        print("IMDb rating for the film \(film.titleYear) could not be loaded")
                        print(error.localizedDescription)
                    }
                }
            }
        }
        
        // Cast
        castImages = film.credits.cast.compactMap { ($0.profilePath != nil) ? TMDBApi.getImageURL(size: .w342, imagePath: $0.profilePath!) : nil }
        castCollectionView.delegate = self
        castCollectionView.dataSource = self
        castCollectionView.isHidden = castMembersWithImage.isEmpty
 
        // If there are no cast members with images. Show the cast members as a list in a UILabel
        if castImages.isEmpty {
            castLabel.font = UIFont.init(name: "HelveticaNeue", size: 14.0)
            castLabel.numberOfLines = 5
            castLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(castLabel)
            castLabel.topAnchor.constraint(equalTo: castHeaderLabel.bottomAnchor, constant: 8).isActive = true
            castLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8).isActive = true
            castLabel.bottomAnchor.constraint(equalTo: crewHeaderLabel.topAnchor, constant: -8).isActive = true
            castLabel.textColor = .white

            var text = ""
            for castMember in film.credits.cast{
                if let character = castMember.character, let name = castMember.name{
                    text += "\(character): \(name)"
                }
            }
            castLabel.text = text
            castCollectionView.removeFromSuperview()
        }
        
        // Crew
        crewImages = film.credits.crew.compactMap { ($0.profilePath != nil) ? TMDBApi.getImageURL(size: .w342, imagePath: $0.profilePath!) : nil }
        crewCollectionView.delegate = self
        crewCollectionView.dataSource = self
        crewCollectionView.isHidden = crewMembersWithImage.isEmpty
        
        // If there are no crew members with images. Show the crew members as a list in a UILabel
        if crewImages.isEmpty {
            crewLabel.font = UIFont.init(name: "HelveticaNeue", size: 14.0)
            crewLabel.numberOfLines = 5
            crewLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(crewLabel)
            crewLabel.topAnchor.constraint(equalTo: crewHeaderLabel.bottomAnchor, constant: 8).isActive = true
            crewLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
            crewLabel.bottomAnchor.constraint(equalTo: reviewHeaderLabel.topAnchor, constant: -8).isActive = true
            crewLabel.textColor = .white
            var text = ""
            for crewMember in film.credits.crew{
                if let job = crewMember.job, let name = crewMember.name{
                    text += "\(job): \(name)\n"
                }
            }
            crewLabel.text = text
            crewCollectionView.removeFromSuperview()
        }
        
        // Review
        setReviewText(reviewText: film.review ?? "")
        
        scrollView.scrollToTop()
    }
    
    func setReviewText(reviewText: String){
        reviewTextView.text = reviewText
        reviewTextView.isHidden = reviewText.isEmpty
        reviewHeaderLabel.isHidden = reviewText.isEmpty
        setContentHeight()
    }
    
    func setFeaturedVideo(){
        
        for video in videos{
            if video.site == "YouTube"{
                switch video.type{
                case .Trailer:
                    featuredVideo = video
                    break
                default:
                    if featuredVideo == nil{
                        featuredVideo = video
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer){

        guard filmImages != nil else {
            loadFilmImages { filmImages in
                DispatchQueue.main.async {
                    self.filmImages = filmImages
                    self.showFilmImages()
                }
            }
            return
        }
        
        // Images have already been loaded
        self.showFilmImages()
    }
    
    func loadFilmImages(size: TMDBApi.PosterSize = .original, completion: @escaping (FilmImages?) -> Void) {
        guard let filmId = film?.id else {
            completion(nil)
            return
        }
        api.loadFilmImages(filmId, size: size) { result in
            DispatchQueue.main.async {
                var images = FilmImages()
                switch result {
                case .success(let imagesResponse):
                    let posterImageURLs = imagesResponse.posters.map { TMDBApi.getImageURL(size: size, imagePath: $0.filePath) }
                    let backdropImageURLs = imagesResponse.backdrops.map { TMDBApi.getImageURL(size: size, imagePath: $0.filePath) }
                    images.posters = posterImageURLs
                    images.backdrops = backdropImageURLs
                case .failure(let error):
                    print(error.localizedDescription)
                }
                completion(images)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let identifier = segue.identifier{
            
            switch identifier{
            case Segue.showVideoPlayerSegue.rawValue:
                guard let featuredVideo = featuredVideo else{
                    return
                }
                
                guard let url = Youtube.createVideoEmbedURL(withID: featuredVideo.key) else{
                    return
                }
                
                let vc = segue.destination as! VideoPlayerViewController
                vc.navigationItem.title = film?.title
                vc.url = url
        
            case Segue.showReviewSegue.rawValue:
                let vc = segue.destination as! ReviewViewController
                vc.film = film
                
            case Segue.showFilmographySegue.rawValue:
                if let data = sender as? (name: String, profilePath: String, credits: Credits) {
                    let vc = segue.destination as! FilmographyCollectionViewController
                    vc.personName = data.name
                    vc.profilePath = data.profilePath
                    vc.personCredits = data.credits
                }
            
            case Segue.showBiographySegue.rawValue:
                if let data = sender as? (personInfo: PersonDetailInformation, imageURL: URL){
                    let vc = segue.destination as! BiographyViewController
                    vc.personDetailInformation = data.personInfo
                    vc.personImageURL = data.imageURL
                }
                
            case Segue.calendarEventCreationSegue.rawValue:
                if let vc = segue.destination as? CalendarEventCreationViewController {
                    vc.film = self.film
                }
                
            case Segue.showImageCollectionSegue.rawValue:
                if let vc = segue.destination as? ImageCollectionViewController, let imageUrls = sender as? [String:[URL]] {
                    vc.imageUrls = imageUrls
                }
                
            default:
                break
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case Segue.showVideoPlayerSegue.rawValue:
            guard let featuredVideo = featuredVideo else{
                return false
            }
            
            guard let _ = Youtube.createVideoEmbedURL(withID: featuredVideo.key) else{
                return false
            }
            return true
            
        case Segue.showReviewSegue.rawValue:
            return true
            
        case Segue.showBiographySegue.rawValue:
            return true
    
        case Segue.showFilmographySegue.rawValue:
            return true
            
        case Segue.calendarEventCreationSegue.rawValue:
            return true
            
        case Segue.showImageCollectionSegue.rawValue:
            if let imageUrls = sender as? [String:URL], !imageUrls.isEmpty {
                return true
            }
            return false

        default:
            return false
        }
    }
    
    func showFilmImages(){
        guard let filmImages = self.filmImages else{
            return
        }
        
        self.performSegue(withIdentifier: Segue.showImageCollectionSegue.rawValue, sender: filmImages.toDictionary)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension FilmDetailViewController: UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let film = film else { return nil }
        
        // Movie poster
        let posterPoint = self.imageView.convert(location, from: view)
        if imageView.bounds.contains(posterPoint){
            if let posterPath = film.posterPath, let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePreviewController") as? ImagePreviewController{
                let imageUrl = TMDBApi.getImageURL(size: .w780, imagePath: posterPath)
                previewingContext.sourceRect = self.view.convert(imageView.frame, from: contentView)
                vc.identifier = "Poster"
                print(imageUrl.absoluteString)
                vc.imageUrl = imageUrl
                vc.preferredContentSize = CGSize(width: 780, height: 1170)
                return vc
            }
        }
        
        // Cast member
        let castCollectionViewPoint = castCollectionView.convert(location, from: view)
        if let castIndexPath = castCollectionView.indexPathForItem(at: castCollectionViewPoint){
            if let cell = castCollectionView.cellForItem(at: castIndexPath) as? CastCollectionViewCell{
                if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePreviewController") as? ImagePreviewController{
                    
                    if let imageUrl = cell.imageUrl {
                        let castMember = film.credits.cast.filter{$0.profilePath != nil}[castIndexPath.row]
                        self.selectedCastMember = castMember
                        
                        vc.imageUrl = imageUrl
                        vc.identifier = "CastMember"
                        vc.preferredContentSize = CGSize(width: 780, height: 1170)
                        let resizedImageRect = cell.imageView.contentClippingRect
                        let x = cell.frame.minX + ((cell.frame.size.width - resizedImageRect.size.width) / 2)
                        let y = cell.frame.minY
                        let viewPoint = view.convert(CGPoint(x: x, y: y), from: castCollectionView)
                        previewingContext.sourceRect = CGRect(origin: viewPoint, size: resizedImageRect.size)
                        
                        return vc
                    }
                }
            }
        }
        
        // Crew member
        let crewCollectionViewPoint = crewCollectionView.convert(location, from: view)
        if let crewIndexPath = crewCollectionView.indexPathForItem(at: crewCollectionViewPoint){
            if let cell = crewCollectionView.cellForItem(at: crewIndexPath) as? CrewCollectionViewCell{
                if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePreviewController") as? ImagePreviewController{
                    
                    if let imageUrl = cell.imageUrl {
                        vc.imageUrl = imageUrl
                        vc.identifier = "CrewMember"
                        vc.preferredContentSize = CGSize(width: 780, height: 1170)
                        let crewMember = crewMembersWithImage[crewIndexPath.row]
                        self.selectedCrewMember = crewMember

                        let resizedImageRect = cell.imageView.contentClippingRect
                        let x = cell.frame.minX + ((cell.frame.size.width - resizedImageRect.size.width) / 2)
                        let y = cell.frame.minY
                        let viewPoint = view.convert(CGPoint(x: x, y: y), from: crewCollectionView)
                        previewingContext.sourceRect = CGRect(origin: viewPoint, size: resizedImageRect.size)
                        
                        return vc
                    }
                }
            }
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        guard let imagePreviewVC = viewControllerToCommit as? ImagePreviewController else{
            return
        }
        
        switch imagePreviewVC.identifier {
        case "Poster":
            
            guard film != nil else { return }
            
            if let filmImages = self.filmImages {
                performSegue(withIdentifier: Segue.showImageCollectionSegue.rawValue, sender: filmImages.toDictionary)
            }
            else{
                self.loadFilmImages { images in
                    DispatchQueue.main.async { [weak self] in
                        self?.filmImages = images
                        if let images = images {
                            self?.performSegue(withIdentifier: Segue.showImageCollectionSegue.rawValue, sender: images.toDictionary)
                        }
                    }
                }
            }
        
        case "CastMember":
            guard let castMember = selectedCastMember, let personId = castMember.id, let name = castMember.name else{
                return
            }
            
            showPersonImages(personId: personId, personName: name)

        case "CrewMember":
            guard
                let crewMember = selectedCrewMember,
                let personId = crewMember.id,
                let name = crewMember.name else{
                return
            }
            
            showPersonImages(personId: personId, personName: name)
        
        default:
            break
        }
    }
}

extension FilmDetailViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
            
        case castCollectionView:
            return castMembersWithImage.count
            
        case crewCollectionView:
            return crewMembersWithImage.count
            
        default:
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch collectionView {
        case castCollectionView, crewCollectionView:
            return 1
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case castCollectionView:
            guard !castMembersWithImage.isEmpty else {
                self.castCollectionView.isHidden = true
                return UICollectionViewCell()
            }
            
            if indexPath.row < castMembersWithImage.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "castCollectionViewCell", for: indexPath) as! CastCollectionViewCell
                let castMember = castMembersWithImage[indexPath.row]
                cell.configure(with: castMember, imageUrl: castImages[indexPath.row])
                return cell
            }
        
        case crewCollectionView:
            guard !crewMembersWithImage.isEmpty else {
                self.crewCollectionView.isHidden = true
                return UICollectionViewCell()
            }
            
            if indexPath.row < crewMembersWithImage.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "crewCollectionViewCell", for: indexPath) as! CrewCollectionViewCell
                let crewMember = crewMembersWithImage[indexPath.row]
                cell.configure(with: crewMember, imageUrl: crewImages[indexPath.row])
                return cell
            }
            
        default:
            return UICollectionViewCell()
        }
        return UICollectionViewCell()
    }
    
    private func showPersonImages(personId: Int, personName: String) {
        self.api.loadPersonImages(personId: personId, completion: { (result) in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let personImagesResponse):
                    let personImageURLs = personImagesResponse.profiles.map { TMDBApi.getImageURL(size: .original, imagePath: $0.file_path) }
                    self?.performSegue(withIdentifier: Segue.showImageCollectionSegue.rawValue, sender: [personName:personImageURLs])
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        })
    }
}

extension FilmDetailViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var id: Int?
        var name: String?
        var profilePath: String?
        
        // Cast Collection View
        if collectionView == castCollectionView{
            let castMember = castMembersWithImage[indexPath.row]
            id = castMember.id
            name = castMember.name
            profilePath = castMember.profilePath
        }
        // Crew Collection View
        else if collectionView == crewCollectionView{
            let crewMember = crewMembersWithImage[indexPath.row]
            id = crewMember.id
            name = crewMember.name
            profilePath = crewMember.profilePath
        }
        
        guard let personID = id, let personName = name, let personProfilePath = profilePath else {
            return
        }
        
        let actionSheet = UIAlertController.init(title: name, message: nil, preferredStyle: .actionSheet)
        
        // Actions
        let showBiographyAction = UIAlertAction.init(title: "Biography", style: .default, handler: { (action) in
        
            self.api.loadPersonDetails(personID, completion: { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let personDetailInformation):
                        let imageURL = TMDBApi.getImageURL(size: .w342, imagePath: personProfilePath)
                        self.performSegue(withIdentifier: Segue.showBiographySegue.rawValue, sender: (personInfo: personDetailInformation, imageURL: imageURL))
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            })
        })
        
        let showFilmographyAction = UIAlertAction.init(title: "Filmography", style: .default, handler: { (action) in
            
            self.api.loadCredits(forPersonWithID: personID) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let personCredits):
                        self.performSegue(withIdentifier: Segue.showFilmographySegue.rawValue, sender: (personName, personProfilePath, personCredits))
                    case .failure(let error):
                        switch error {
                        case TMDBApiError.requestLimitExceeded(let seconds):
                            print("Request limit exceeded. Try again after \(seconds) seconds")
                        default:
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        })
        
        let showImagesAction = UIAlertAction.init(title: "Show images", style: .default) { [weak self] _ in
            self?.showPersonImages(personId: personID, personName: personName)
        }
        
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(showBiographyAction)
        actionSheet.addAction(showFilmographyAction)
        actionSheet.addAction(showImagesAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true)
    }
}

enum FilmDetailViewControllerError: Error{
    case movieIsNil
}

extension UIScrollView{
    func scrollToTop(){
        let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(desiredOffset, animated: true)
    }
}

