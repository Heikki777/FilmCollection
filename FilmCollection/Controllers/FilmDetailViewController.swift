//
//  FilmDetailViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 31/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Alamofire
import PromiseKit

class FilmDetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var directorLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
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
    
    @IBAction func removeMovie(_ sender: Any) {
        guard let film = film else{
            print("Error! There is no film to remove!")
            return
        }
        
        guard let filmEntities: Set<FilmEntity> = appDelegate.filmCollectionEntity.films as? Set<FilmEntity> else { return }
        if let filmEntity = filmEntities.filter({ Int($0.id) == film.id }).first {
            let alert = UIAlertController.init(title: "Remove film", message: "Are you sure that you want to remove the movie \"\(film.title)\" from the collection?", preferredStyle: .alert)
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
                FilmCollection.shared.addFilm(film)
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
        print("Watched film \(film.title)")
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
    
    var smallPosterImage: UIImage?{
        didSet{
            DispatchQueue.main.async {
                self.imageView.image = self.smallPosterImage
            }
        }
    }
    var bigPosterImage: UIImage?{
        didSet{
            DispatchQueue.main.async {
                self.backgroundImageView.image = self.bigPosterImage
            }
        }
    }
    var featuredVideo: Video?{
        didSet{
            if let featuredVideo = featuredVideo{
                playVideoButton.isHidden = false
                playVideoButton.setTitle("Play \(featuredVideo.type) ▶︎", for: .normal)
            }
        }
    }
    
    var movieImages: FilmImages?
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
    
    var castImages: [UIImage] = []
    var crewImages: [UIImage] = []
    
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
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        print("Orientation changed")
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
        
        guard let film = film else{
            print("No film")
            return
        }
        
        // Bar buttons
        let filmIsInCollection = FilmCollection.shared.contains(film)
        additionBarButton.isEnabled = !filmIsInCollection
        removeBarButton.isEnabled = filmIsInCollection
        
        // Load background poster and the small poster images
        film.loadPosterImages().done({ (smallPosterImage, bigPosterImage) in
            self.bigPosterImage = bigPosterImage
            self.smallPosterImage = smallPosterImage
        }).catch { (error) in
            print(error.localizedDescription)
        }
        
        // Videos
        attempt{
            self.api.loadVideos(film.id)
        }
        .done { (videos) in
            self.videos = videos
        }
        .catch { (error) in
            print(error.localizedDescription)
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
            print("3D touch is available")
            registerForPreviewing(with: self, sourceView: view)
        }
        else{
            print("3D Touch not available")
        }
        
        // MARK: - Set the movie title
        titleLabel.text = film.titleYear
        
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
        
        // Cast
        castImages = []
        castCollectionView.delegate = self
        castCollectionView.dataSource = self
        castCollectionView.isHidden = castMembersWithImage.isEmpty
 
        // If there are no cast members with images. Show the cast members as a list in a UILabel
        if castMembersWithImage.isEmpty {
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
        crewImages = []
        crewCollectionView.delegate = self
        crewCollectionView.dataSource = self
        crewCollectionView.isHidden = crewMembersWithImage.isEmpty
        
        // If there are no crew members with images. Show the crew members as a list in a UILabel
        if crewMembersWithImage.isEmpty {
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
        
        let castMemberImagePromises = castMembersWithImage.map { (castMember) -> Promise<UIImage> in
            let url = TMDBApi.getPosterURL(size: .w342, imagePath: castMember.profilePath!)
            return Downloader.shared.loadImage(url: url)
        }
        
        // Load cast images
        when(fulfilled: castMemberImagePromises)
        .done { (images) in
            self.castImages = images
            self.castCollectionView.reloadData()
            if self.castCollectionView.numberOfSections > 0 && self.castCollectionView.numberOfItems(inSection: 0) > 0{
                self.castCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
            }
        }
        .catch({ (error) in
            print(error.localizedDescription)
            self.castImages = []
            self.castCollectionView.reloadData()
            if self.castCollectionView.numberOfSections > 0 && self.castCollectionView.numberOfItems(inSection: 0) > 0{
                self.castCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
            }
        })
        
        let crewMemberImagePromises = crewMembersWithImage.map { (crewMember) -> Promise<UIImage> in
            let url = TMDBApi.getPosterURL(size: .w342, imagePath: crewMember.profilePath!)
            return Downloader.shared.loadImage(url: url)
        }
        
        // Load crew images
        when(fulfilled: crewMemberImagePromises)
        .done { (images) in
            self.crewImages = images
            self.crewCollectionView.reloadData()
            if self.crewCollectionView.numberOfSections > 0 && self.crewCollectionView.numberOfItems(inSection: 0) > 0{
                self.crewCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
            }
        }
        .catch({ (error) in
            print(error.localizedDescription)
            self.crewImages = []
            self.crewCollectionView.reloadData()
            if self.crewCollectionView.numberOfSections > 0 && self.crewCollectionView.numberOfItems(inSection: 0) > 0{
                self.crewCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
            }
        })
        
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
    
    func showAlert(title: String, message: String){
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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

        guard let movieImages = movieImages, !movieImages.isEmpty else{
            loadMovieImages()
            .done { (movieImages) in
                self.movieImages = movieImages
                self.showMovieImages()
            }
            .catch { (error) in
                print(error.localizedDescription)
            }
            return
        }
        
        // Images have already been loaded
        self.showMovieImages()
    }
    
    func loadMovieImages() -> Promise<FilmImages>{
        return Promise { result in
            guard let movieId = self.film?.id else{
                print("No movie")
                result.reject(FilmDetailViewControllerError.movieIsNil)
                return
            }
            
            let loadingIndicator = LoadingIndicatorViewController(title: "Loading images", message: "", complete: nil)
            
            // Images have not been loaded yet
            self.tabBarController?.present(loadingIndicator, animated: true)
            attempt{
                self.api.loadImages(movieId, size: .w500) {
                    loadingIndicator.setProgress($0)
                    loadingIndicator.message = "\(Int($0 * 100)) %"
                }
            }
            .done { images in
                self.movieImages = images
                result.fulfill(images)
            }
            .catch { error in
                print(error.localizedDescription)
                result.reject(error)
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
                vc.backgroundImage = bigPosterImage
                
            case Segue.showFilmographySegue.rawValue:
                if let personCredits = sender as? PersonCredits {
                    let vc = segue.destination as! FilmographyCollectionViewController
                    vc.personCredits = personCredits
                }
            
            case Segue.showBiographySegue.rawValue:
                if let data = sender as? (personInfo: PersonDetailInformation, image: UIImage?){
                    let vc = segue.destination as! BiographyViewController
                    vc.personDetailInformation = data.personInfo
                    vc.personImage = data.image
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

        default:
            print("Unknown segue")
            return false
        }
    }
    
    func showMovieImages(){
        guard let movieImages = self.movieImages else{
            print("No images")
            return
        }
        
        if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImageCollectionViewController") as? ImageCollectionViewController{
            guard movieImages.count > 0 else{
                print("MovieImages is empty")
                return
            }
            vc.images = movieImages.toDictionary
            vc.movieId = film?.id
            vc.navigationItem.title = film?.title
        
            self.show(vc, sender: self)
        }
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension FilmDetailViewController: UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Movie poster
        let posterPoint = self.imageView.convert(location, from: view)
        if imageView.bounds.contains(posterPoint){
            if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePreviewController") as? ImagePreviewController{
                if let image = self.bigPosterImage {
                    previewingContext.sourceRect = self.view.convert(imageView.frame, from: contentView)
                
                    vc.identifier = "Poster"
                    vc.image = image
                    vc.preferredContentSize = image.size
                    return vc
                }
            }
        }
        
        // Cast member
        let castCollectionViewPoint = castCollectionView.convert(location, from: view)
        if let castIndexPath = castCollectionView.indexPathForItem(at: castCollectionViewPoint){
            if let cell = castCollectionView.cellForItem(at: castIndexPath) as? CastCollectionViewCell{
                if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePreviewController") as? ImagePreviewController{
        
                    if let image = cell.imageView.image {
                        let castMember = castMembersWithImage[castIndexPath.row]
                        self.selectedCastMember = castMember
                        
                        vc.image = image
                        vc.identifier = "CastMember"
                        vc.preferredContentSize = image.size
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
                    
                    if let image = cell.imageView.image {
                        vc.image = image
                        vc.identifier = "CrewMember"
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
        
        let showImageCollectionVC: (_ images: [String: [UIImage]]) -> () = { images in
            if let imageCollectionVC = self.storyboard!.instantiateViewController(withIdentifier: "ImageCollectionViewController") as? ImageCollectionViewController{
                imageCollectionVC.images = images
                self.show(imageCollectionVC, sender: self)
            }
        }
        
        switch imagePreviewVC.identifier {
        case "Poster":
            
            guard film != nil else{
                print("film is nil")
                return
            }
            
            if let movieImages = self.movieImages{
                showImageCollectionVC(movieImages.toDictionary)
            }
            else{
                attempt{
                    self.loadMovieImages()
                }
                .done { (images) in
                    self.movieImages = images
                    if images.isEmpty{
                        return
                    }
                    else{
                        showImageCollectionVC(images.toDictionary)
                    }
                }
                .catch({ (error) in
                    print(error.localizedDescription)
                    return
                })
            }
        
        case "CastMember":
            guard let castMember = selectedCastMember, let personId = castMember.id, let name = castMember.name else{
                return
            }
            
            let loadingIndicator = LoadingIndicatorViewController(title: "Loading \(name) images", message: "", complete: nil)
            self.tabBarController?.present(loadingIndicator, animated: true, completion: nil)
            
            attempt{
                self.api.loadImages(personId: personId, progressHandler: { (progress) in
                    loadingIndicator.setProgress(progress)
                    loadingIndicator.message = "\(Int(100 * progress)) %"
                })
            }
            .done { (images) in
                showImageCollectionVC([name: images])
            }
            .catch { (error) in
                print(error.localizedDescription)
            }
            .finally {
                loadingIndicator.finish()
                self.selectedCastMember = nil
            }
            
        case "CrewMember":
            guard
                let crewMember = selectedCrewMember,
                let personId = crewMember.id,
                let name = crewMember.name else{
                return
            }
            
            let loadingIndicator = LoadingIndicatorViewController(title: "Loading \(name) images", message: "", complete: nil)
            loadingIndicator.progressView.isHidden = true
            self.tabBarController?.present(loadingIndicator, animated: true, completion: nil)
            
            attempt{
                self.api.loadImages(personId: personId)
            }
            .done { (images) in
                showImageCollectionVC([name: images])
            }
            .catch { (error) in
                print(error.localizedDescription)
            }
            .finally {
                loadingIndicator.finish()
                self.selectedCrewMember = nil
            }
        
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
                print("There are no cast members with image -> hide collection view")
                self.castCollectionView.isHidden = true
                return UICollectionViewCell()
            }
            
            if indexPath.row < castMembersWithImage.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "castCollectionViewCell", for: indexPath) as! CastCollectionViewCell
                let castMember = castMembersWithImage[indexPath.row]
                var image: UIImage?
                if indexPath.row < castImages.count{
                    image = castImages[indexPath.row]
                }
                cell.configure(with: castMember, image: image)
                return cell
            }
        
        case crewCollectionView:
            guard !crewMembersWithImage.isEmpty else {
                print("There are no crew members with image -> hide collection view")
                self.crewCollectionView.isHidden = true
                return UICollectionViewCell()
            }
            
            if indexPath.row < crewMembersWithImage.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "crewCollectionViewCell", for: indexPath) as! CrewCollectionViewCell
                let crewMember = crewMembersWithImage[indexPath.row]
                var image: UIImage?
                if indexPath.row < crewImages.count{
                    image = crewImages[indexPath.row]
                }
                cell.configure(with: crewMember, image: image)
                return cell
            }
            
        default:
            return UICollectionViewCell()
        }
        return UICollectionViewCell()
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
            print("Error! Missing data")
            return
        }
        
        let actionSheet = UIAlertController.init(title: name, message: nil, preferredStyle: .actionSheet)
        
        // Actions
        let showBiographyAction = UIAlertAction.init(title: "Biography", style: .default, handler: { (action) in
            print("Show Biography: \(personName)")
            
            let loadingIndicator = LoadingIndicatorViewController(title: "Loading biography", message: personName, complete: nil)
            var loaded = 0
            let toLoad = 2
            let itemLoaded: (() -> Void) = {
                loaded += 1
                let progress = Float(loaded) / Float(toLoad)
                loadingIndicator.setProgress(progress)
                if loaded == toLoad {
                    loadingIndicator.finish()
                }
            }
            self.presentingViewController?.present(loadingIndicator, animated: true, completion: nil)
            
            firstly{
                when(fulfilled:
                    attempt{
                        self.api.loadPersonDetails(personID)
                    }.ensure { itemLoaded() },
                    attempt{
                        self.api.loadImage(withPath: personProfilePath, size: .w342)
                    }.ensure { itemLoaded() }
                )
            }
            .done{ personDetailInformation, image in
                print(personDetailInformation)
                self.performSegue(withIdentifier: Segue.showBiographySegue.rawValue, sender: (personInfo: personDetailInformation, image: image))
            }
            .catch{ error in
                print(error.localizedDescription)
            }
            .finally {
                loadingIndicator.finish()
            }
        })
        
        let showFilmographyAction = UIAlertAction.init(title: "Filmography", style: .default, handler: { (action) in
            print("Show Movies: \(personName)")
            
            attempt{
                self.api.loadCredits(forPersonWithID: personID)
            }
            .done({ (crew, cast) in
                let credits = PersonCredits(name: personName, profilePath: personProfilePath, crewRoles: crew, castRoles: cast)
                self.performSegue(withIdentifier: Segue.showFilmographySegue.rawValue, sender: credits)
            })
            .catch({ (error) in
                print(error.localizedDescription)
            })
            
        })
        
        let showImagesAction = UIAlertAction.init(title: "Show images", style: .default) { (action) in
            
            let loadingIndicator = LoadingIndicatorViewController.init(title: "Loading images", message: personName, complete: nil)
            self.tabBarController?.present(loadingIndicator, animated: true, completion: nil)
            
            attempt {
                self.api.loadImages(personId: personID, progressHandler: { (progress) in
                    loadingIndicator.setProgress(progress)
                })
            }
            .done({(images) in
                guard images.count > 0 else { return }
                let imageCollectionViewController = self.storyboard!.instantiateViewController(withIdentifier: "ImageCollectionViewController") as! ImageCollectionViewController
                imageCollectionViewController.images = [personName : images]
                self.show(imageCollectionViewController, sender: nil)
            })
            .catch({ (error) in
                print(error.localizedDescription)
            })
        }
        
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(showBiographyAction)
        actionSheet.addAction(showFilmographyAction)
        actionSheet.addAction(showImagesAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true) {
            print("actionSheet completed")
        }

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

