//
//  Collection.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 05/07/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import Firebase

class FilmCollection: NSObject{
    
    enum NotificationKey: String{
        case filmCollectionValueChanged = "heikkihamalisto.FilmCollection.collectionChanged"
        case filmAddedToCollection = "heikkihamalisto.FilmCollection.filmAdded"
        case filmChanged = "heikkihamalisto.FilmCollection.filmChanged"
        case filmRemoved = "heikkihamalisto.FilmCollection.filmRemoved"
        case loadingProgressChanged = "heikki.FilmCollection.loadingProgressChanged"
        case filmDictionaryChanged = "heikki.FilmCollection.filmDictionaryChanged"
        case newSectionAddedToDictionary = "heikki.FilmCollection.newSectionAddedToDictionary"
        case sectionRemovedFromDictionary = "heikki.FilmCollection.sectionRemovedFromDictionary"
        case beginUpdates = "heikki.FilmCollection.beginUpdates"
        case endUpdates = "heikki.FilmCollection.endUpdates"
        case collectionFiltered = "heikki.FilmCollection.collectionFiltered"
    }
    
    static let shared = FilmCollection()
    
    static func sort(movies: inout [Movie], sortingRule: SortingRule, order: SortOrder = .ascending){
        movies.sort { (movie_A, movie_B) -> Bool in
            switch sortingRule{
            case .title:
                return (order == .ascending) ? movie_A.sortingTitle < movie_B.sortingTitle : movie_A.sortingTitle > movie_B.sortingTitle
            case .year:
                if let movie_A_year = movie_A.year{
                    if let movie_B_year = movie_B.year{
                        return (order == .ascending) ? movie_A_year < movie_B_year : movie_A_year > movie_B_year
                    }
                    return true
                }
                return false
            case .rating:
                return movie_A.rating.rawValue < movie_B.rating.rawValue
            }
        }
    }
    
    private var films: [Movie] = []
    private var sections: [String] = []
    private var filteredSections: [String] = []
    private var filmDict: [String:[Movie]] = [:]
    private var filteredFilmDict: [String: [Movie]] = [:]
    private var filteringScope: String = ""
    private var filteringText: String = ""
    private var filterOn: Bool = false{
        didSet{
            print("filterOn: \(filterOn)")
            if filterOn == false{
                filteringScope = ""
                filteringText = ""
            }
        }
    }
    
    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    lazy var settings = {
        return appDelegate?.settings
    }()
    
    var size: Int{
        return films.count
    }
    
    var order: SortOrder = .ascending{
        didSet{
            createMovieDictionary()
        }
    }
    
    var sortingRule: SortingRule = .title{
        didSet{
            createMovieDictionary()
        }
    }
    
    // Firebase
    lazy var databaseRef: DatabaseReference = {
        return Database.database().reference()
    }()
    
    // TMDB API
    let api: TMDBApi = TMDBApi.shared
    var user: User?
    
    private func createMovieDictionary(notifyObservers: Bool = true){
        var tempFilms = films
        let secondarySortingRule: SortingRule = (sortingRule == .title) ? .year : .title
        FilmCollection.sort(movies: &tempFilms, sortingRule: secondarySortingRule, order: order)
        
        NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.beginUpdates.rawValue), object: nil)
        sections = []
        filteredSections = []
        filmDict = [:]
        filteredFilmDict = [:]
        NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.filmDictionaryChanged.rawValue), object: nil)
        NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.endUpdates.rawValue), object: nil)

        for movie in tempFilms{
            self.addMovieToDictionary(movie)
        }
    }
    
    private func addMovieToDictionary(_ film: Movie){
        let sectionTitle = getSectionTitle(for: film)
        //print("addMovieToDictionary: \(film.title): section: \(sectionTitle)")
        // Create a new section in the film dictionary
        if filmDict[sectionTitle] == nil{
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.beginUpdates.rawValue), object: nil)
            
            sections.append(sectionTitle)
            filmDict[sectionTitle] = []
            sections.sort(by: { (a, b) -> Bool in
                return (order == .ascending) ? a < b : a > b
            })
            
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.newSectionAddedToDictionary.rawValue), object: sections.index(of: sectionTitle)!)
            
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.endUpdates.rawValue), object: nil)

        }
        
        if var sectionMovies = filmDict[sectionTitle], !sectionMovies.contains(film){
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.beginUpdates.rawValue), object: nil)
            
            // Add movie to temp array
            sectionMovies.append(film)
            // Sort
            FilmCollection.sort(movies: &sectionMovies, sortingRule: sortingRule)
            // Find the index of the added movie
            let index = sectionMovies.index(of: film)!
            // Add movie to the dictionary
            filmDict[sectionTitle]?.insert(film, at: index)
            
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.filmAddedToCollection.rawValue), object: film)
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: NotificationKey.endUpdates.rawValue), object: nil)

        }
    }
    
    private override init(){
        super.init()
        
        guard let user = Auth.auth().currentUser else{
            print("Error! No user")
            return
        }
        
        self.user = user
    
        databaseRef.child("user-movies").child(user.uid).observeSingleEvent(of: .value) { (snapshot) in
            
            if let dbFilms = snapshot.value as? [String:AnyObject]{
                
                guard dbFilms.count > 0 else{
                    NotificationCenter.default.post(name: NSNotification.Name(NotificationKey.filmCollectionValueChanged.rawValue), object: nil)
                    return
                }
                
                print("Movie list value changed: \(dbFilms.count)")
                var loaded: Int = 0
                for (_,dbFilm) in dbFilms{
                    guard let id = dbFilm["id"] as? Int, let rating = dbFilm["rating"] as? Int else {
                        print("No Film ID")
                        continue
                    }
                    
                    attempt{
                        self.api.loadMovie(id, append: ["credits"])
                    }
                    .done{ film in
                        film.review = dbFilm["review"] as? String ?? ""
                        film.rating = Rating.all[rating]
                        
                        attempt{
                            film.loadSmallPosterImage()
                        }
                        .done{ (small) in
                            film.smallPosterImage = small
                        }
                        .catch{ error in
                            print("Could not load poster images for the movie \(film.title)")
                            print(error.localizedDescription)
                        }
                        .finally {
                            self.films.append(film)
                            self.addMovieToDictionary(film)
                            loaded += 1
                            
                            // Progress
                            let progress: Float = Float(loaded) / Float(dbFilms.count)
                            print("Loaded: \(loaded) / \(dbFilms.count) (\(Int(progress*100)) %)")
                            //print("\(self.films.count) / \(dbFilms.count)")
                            let progressNotificationName = NSNotification.Name(NotificationKey.loadingProgressChanged.rawValue)
                            NotificationCenter.default.post(name: progressNotificationName, object: progress)
                            
                            if loaded == dbFilms.count{
                                NotificationCenter.default.post(name: NSNotification.Name(NotificationKey.filmCollectionValueChanged.rawValue), object: nil)
                            }
                        }
                    }
                    .catch{ error in

                        print(error.localizedDescription)
                    }
                }
            }
        }
        
        // Listen for new movies in the Firebase database
        databaseRef.child("user-movies").child(user.uid).observe(.childAdded, with: { (dataSnapshot) in
            
            
            // Use this handler only if the movies have been loaded
            guard !self.films.isEmpty else{
                return
            }
            
            guard let snapshotValue = dataSnapshot.value as? [String:AnyObject],
                let id = snapshotValue["id"] as? Int,
                let rating = snapshotValue["rating"] as? Int else {
                    return
            }
            
            // Make sure that the movie is not already in the movies array before loading it.
            if !self.films.filter({ (film) -> Bool in
                return film.id == id
            }).isEmpty{
                return
            }
            
            attempt{
                self.api.loadMovie(id, append: ["credits"])
            }
            .done{ film in
                film.rating = Rating.all[rating]
                attempt{
                    film.loadSmallPosterImage()
                }
                .done{ (small) in
                    film.smallPosterImage = small
                }
                .catch{ error in
                    print("Could not load poster images for the movie \(film.title)")
                    print(error.localizedDescription)
                }
                .finally {
                    self.films.append(film)
                    self.addMovieToDictionary(film)
                }
            }
            .catch{ error in
                print(error.localizedDescription)
            }
        })
        
        // Listen for changed movies in the Firebase database
        databaseRef.child("user-movies").child(user.uid).observe(.childChanged, with: { (dataSnapshot) in
            
            guard let snapshotValue = dataSnapshot.value as? [String:AnyObject] else {
                return
            }
            
            if let id = snapshotValue["id"] as? Int, let film = (self.films.filter { $0.id == id }).first{
                // Rating changed
                if let rating = snapshotValue["rating"] as? Int{
                    film.rating = Rating.all[rating]
                    self.createMovieDictionary()
                    let name = NSNotification.Name(NotificationKey.filmChanged.rawValue)
                    NotificationCenter.default.post(name: name, object: film)
                }
            }
        })
        
        // Listen for deleted movies in the Firebase database
        databaseRef.child("user-movies").child(user.uid).observe(.childRemoved, with: { (dataSnapshot) in
            if let value = dataSnapshot.value as? [String:Any]{
                if let id = value["id"] as? Int, let film = (self.films.filter { $0.id == id }).first {
                    if let indexPath = self.getIndexPath(for: film){
                        
                        // Remove film
                        NotificationCenter.default.post(name: Notification.Name.init(NotificationKey.beginUpdates.rawValue), object: nil)
                        self.removeFilm(film)
                        NotificationCenter.default.post(name: Notification.Name.init(NotificationKey.filmRemoved.rawValue), object: (film, indexPath))
                        
                        // Check if section needs to be removed as well
                        let sectionTitle = self.getSectionTitle(for: film)
                        if self.filterOn{
                            if self.filteredFilmDict[sectionTitle] == nil || self.filteredFilmDict[sectionTitle]!.isEmpty{
                                self.filteredFilmDict[sectionTitle] = nil
                                NotificationCenter.default.post(name: Notification.Name.init(NotificationKey.sectionRemovedFromDictionary.rawValue), object: indexPath.section)
                            }
                        }
                        else{
                            if self.filmDict[sectionTitle] == nil || self.filmDict[sectionTitle]!.isEmpty{
                                self.filmDict[sectionTitle] = nil
                                NotificationCenter.default.post(name: Notification.Name.init(NotificationKey.sectionRemovedFromDictionary.rawValue), object: indexPath.section)
                            }
                        }

                        NotificationCenter.default.post(name: Notification.Name.init(NotificationKey.endUpdates.rawValue), object: nil)
                    }
                }
            }
        })
    }
    
    func removeFilmFromDatabase(_ film: Movie){
        if let user = Auth.auth().currentUser{
            // Remove the movie from the database
            self.databaseRef.child("user-movies").child("\(user.uid)").child("\(film.id)").removeValue()
        }
    }
    
    private func removeFilm(_ film: Movie){
        let sectionTitle = getSectionTitle(for: film)
        if let index = films.index(of: film){
            films.remove(at: index)
        }
        if let index = filmDict[sectionTitle]?.index(of: film){
            filmDict[sectionTitle]?.remove(at: index)
            if filterOn{
                filterCollection(scope: filteringScope, searchText: filteringText)
            }
        }
    }
    
    func randomFilm() -> Movie?{

        guard size > 0 else{
            return nil
        }
        
        let random = Int(arc4random_uniform(UInt32(size)))
        return films[random]
    }
    
    func getMovie(withId id: Int) -> Movie?{
        return films.filter { $0.id == id }.first
    }
    
    func getMovie(at indexPath: IndexPath) -> Movie?{
        let sectionTitle = getSectionTitle(atIndex: indexPath.section)
        if filterOn{
            if indexPath.row < filteredFilmDict[sectionTitle]?.count ?? 0{
                return filteredFilmDict[sectionTitle]?[indexPath.row]
            }
        }
        else{
            if indexPath.row < filmDict[sectionTitle]?.count ?? 0{
                return filmDict[sectionTitle]?[indexPath.row]
            }
        }
        return nil
    }
    
    func getSectionTitle(section: Int) -> String?{
        return (filterOn) ? filteredSections[section] : sections[section]
    }
    
    func getIndexPath(for movie: Movie) -> IndexPath?{
        let sectionTitle = getSectionTitle(for: movie)
        if filterOn{
            if let row = filteredFilmDict[sectionTitle]?.index(of: movie), let section = filteredSections.index(of: sectionTitle){
                return IndexPath.init(row: row, section: section)
            }
        }
        else if let row = filmDict[sectionTitle]?.index(of: movie), let section = sections.index(of: sectionTitle){
            return IndexPath.init(row: row, section: section)
        }
        return nil
    }
    
    func filmsInSection(_ sectionTitle: String) -> [Movie]{
        let sectionFilms = filterOn ? filteredFilmDict[sectionTitle] : filmDict[sectionTitle]
        return sectionFilms ?? []
    }
    
    func filmsInSection(_ section: Int) -> [Movie]{
        let sectionTitle = getSectionTitle(atIndex: section)
        let sectionFilms = filterOn ? filteredFilmDict[sectionTitle] : filmDict[sectionTitle]
        let result = sectionFilms ?? []
        return result
    }
    
    func getSectionTitle(for movie: Movie) -> String{
        switch sortingRule {
        case .rating:
            return movie.rating.description
        case .title:
            if let first = movie.sortingTitle.first{
                return String.init(first)
            }
            return ""
        case .year:
            if let year = movie.year{
                return "\(year)"
            }
            return "Unknown"
        }
    }
    
    func filterCollection(scope: String = "All", searchText: String){
        filteringScope = scope
        filteringText = searchText
        filteredFilmDict = [:]
        filteredSections = []
        
        filterOn = !searchText.isEmpty || scope != "All"
        
        guard filterOn else{
            NotificationCenter.default.post(name: Notification.Name(NotificationKey.collectionFiltered.rawValue), object: nil)
            return
        }
        
        for section in sections{
            if let sectionMovies = filmDict[section]{
                let filteredSectionMovies = sectionMovies.filter({ (movie) -> Bool in
                    switch scope{
                        
                    case "All":
                        return movie.title.lowercased().contains(searchText.lowercased())
                        
                    default:
                        
                        let movieBelongsToGenre = movie.genres?.contains(where: { (genre) -> Bool in
                            return genre.name == scope
                        }) ?? false
                        
                        if searchText.isEmpty{
                            return movieBelongsToGenre
                        }
                        else{
                            return movieBelongsToGenre && movie.title.lowercased().contains(searchText.lowercased())
                        }
                        
                    }
                })
                
                if filteredSectionMovies.count > 0{
                    filteredSections.append(section)
                    filteredFilmDict[section] = filteredSectionMovies
                }
            }
        }
        NotificationCenter.default.post(name: Notification.Name(NotificationKey.collectionFiltered.rawValue), object: nil)
    }
    
    func sectionIndexTitles() -> [String]{
        let result = filterOn ? filteredSections : sections
        return result
    }
    
    func getSectionTitle(atIndex index: Int) -> String{
        return filterOn ? filteredSections[index] : sections[index]
    }
}

extension FilmCollection: UITableViewDataSource{
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return filterOn ? filteredSections.count : sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if filterOn{
            guard section < filteredSections.count else{
                return 0
            }
            return filteredFilmDict[filteredSections[section]]?.count ?? 0
        }
        
        guard section < sections.count else{
            return 0
        }
        return filmDict[sections[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let movie = self.getMovie(at: indexPath){
            
            switch settings?.filmCollectionLayout {
                
            case FilmCollectionLayoutOption.posterTitleOverview.rawValue:
                let cell = tableView.dequeueReusableCell(withIdentifier: "filmCellExpanded") as! FilmTableViewCellExpanded
                cell.configure(withMovie: movie)
                cell.selectionStyle = .none
                return cell
                
            case FilmCollectionLayoutOption.title.rawValue:
                let cell = tableView.dequeueReusableCell(withIdentifier: "filmCellSimple") as! FilmTableViewCellSimple
                cell.configure(withMovie: movie)
                cell.selectionStyle = .none
                return cell
                
            default:
                break
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete{
            print("DELETE")
            if let film = self.getMovie(at: indexPath){
                self.removeFilmFromDatabase(film)
            }
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return filterOn ? filteredSections : sections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionTitles = self.sectionIndexTitles()
        if section < sectionTitles.count{
            return sectionTitles[section]
        }
        return nil
    }
}

