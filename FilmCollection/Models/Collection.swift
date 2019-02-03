//
//  Collection.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 05/07/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import UIKit

class FilmCollection: NSObject {
    
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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var settings = {
        return appDelegate.settings
    }()
    
    lazy var jsonEncoder: JSONEncoder = {
        return JSONEncoder()
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
    
    // TMDB API
    let api: TMDBApi = TMDBApi.shared
    
    private func createMovieDictionary(notifyObservers: Bool = true){
        var tempFilms = films
        let secondarySortingRule: SortingRule = (sortingRule == .title) ? .year : .title
        FilmCollection.sort(movies: &tempFilms, sortingRule: secondarySortingRule, order: order)
        
        NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.beginUpdates.name, object: nil)
        sections = []
        filteredSections = []
        filmDict = [:]
        filteredFilmDict = [:]
        NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.filmDictionaryChanged.name, object: nil)
        NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.endUpdates.name, object: nil)

        for movie in tempFilms{
            self.addMovieToDictionary(movie)
        }
    }
    
    private func addMovieToDictionary(_ film: Movie){
        let sectionTitle = getSectionTitle(for: film)
        // Create a new section in the film dictionary
        if filmDict[sectionTitle] == nil{
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.beginUpdates.name, object: nil)
            
            sections.append(sectionTitle)
            filmDict[sectionTitle] = []
            sections.sort(by: { (a, b) -> Bool in
                return (order == .ascending) ? a < b : a > b
            })
            
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.newSectionAddedToDictionary.name, object: sections.index(of: sectionTitle)!)
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.endUpdates.name, object: nil)
        }
        
        if var sectionMovies = filmDict[sectionTitle], !sectionMovies.contains(film){
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.beginUpdates.name, object: nil)
            
            // Add movie to temp array
            sectionMovies.append(film)
            // Sort
            FilmCollection.sort(movies: &sectionMovies, sortingRule: sortingRule)
            // Find the index of the added movie
            let index = sectionMovies.index(of: film)!
            // Add movie to the dictionary
            filmDict[sectionTitle]?.insert(film, at: index)
            
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.filmAddedToCollection.name, object: film)
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.endUpdates.name, object: nil)

        }
    }
    
    private override init(){
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmReviewed(notification:)), name: Notifications.FilmCollectionNotification.filmReviewed.name, object: nil)
        
        var loaded: Int = 0
        var failed: Int = 0
        var numberOfFilmsHandled: Int {
            return loaded + failed
        }
        
        func updateLoadingProgress(){
            let progress: Float = Float(numberOfFilmsHandled) / Float(appDelegate.filmEntities.count)
            print("Loaded: \(numberOfFilmsHandled) / \(appDelegate.filmEntities.count) (\(Int(progress*100)) %)")
            let progressNotificationName = Notifications.FilmCollectionNotification.loadingProgressChanged.name
            NotificationCenter.default.post(name: progressNotificationName, object: progress)
        }
        
        let filmLoadedSuccessfullyHandler: (Movie) -> Void = { film in
            // Load the small poster image for the film
            // And then add the film to the collection.
            
            attempt {
                film.loadSmallPosterImage()
            }
            .done { (small) in
                film.smallPosterImage = small
            }
            .catch { error in
                print("Could not load poster images for the movie \(film.title)")
                print(error.localizedDescription)
            }
            .finally {
                self.films.append(film)
                self.addMovieToDictionary(film)
                loaded += 1
                updateLoadingProgress()
            }
        }
        
        let filmLoadingFailed: (Error) -> Void = { error in
            print(error.localizedDescription)
            failed += 1
            updateLoadingProgress()
        }
        
        appDelegate.filmEntities.compactMap { $0 }.forEach { filmEntity in
            loadFilmFromTMDB(filmEntity, success: filmLoadedSuccessfullyHandler, failure: filmLoadingFailed)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadFilmFromTMDB(_ filmEntity: FilmEntity, success: @escaping (_ film: Movie) -> Void, failure: @escaping (_ error: Error) -> Void) {
        print("loadFilmFromTMDB: \(filmEntity.id)")
        attempt {
            self.api.loadMovie(Int(filmEntity.id), append: ["credits"])
        }
        .done { film in
            film.review = filmEntity.review
            let ratingNumber = Int(filmEntity.rating)
            film.rating = Rating.all[ratingNumber]
            success(film)
        }
        .catch { error in
            failure(error)
        }
    }
    
    func contains(_ film: Movie) -> Bool{
        return films.contains(film)
    }
    
    func removeFilm(_ film: Movie){
        
        if let filmEntity = film.entity {
            appDelegate.filmCollectionEntity.removeFromFilms(filmEntity)
            appDelegate.saveContext()
        }

        let sectionTitle = getSectionTitle(for: film)
        if let index = films.index(of: film){
            films.remove(at: index)
        }
        if let index = filmDict[sectionTitle]?.index(of: film){
            filmDict[sectionTitle]?.remove(at: index)
            print("remove row \(index) in section \(sectionTitle)")
            if filmDict[sectionTitle]?.count == 0 {
                print("Remove section: \(sectionTitle)")
                filmDict.removeValue(forKey: sectionTitle)
                if let sectionIndex = sections.firstIndex(of: sectionTitle){
                    sections.remove(at: sectionIndex)
                }
            }
            if filterOn {
                filterCollection(scope: filteringScope, searchText: filteringText)
            }
        }
    }
    
    func addNewFilm(withId id: Int){
        let filmEntity = FilmEntity(context: appDelegate.persistentContainer.viewContext)
        filmEntity.id = Int32(id)
        appDelegate.filmCollectionEntity.addToFilms(filmEntity)
        appDelegate.saveContext()
        TMDBApi.shared.loadMovie(id, append: ["credits"])
        .done { [weak self] (film) in
            self?.addFilm(film)
        }
        .catch { (error) in
            print(error.localizedDescription)
        }
    }
    
    func addFilm(_ film: Movie){
        guard !films.contains(film) else { return }
        guard film.smallPosterImage == nil else {
            films.append(film)
            createMovieDictionary(notifyObservers: true)
            return
        }

        attempt {
            film.loadSmallPosterImage()
        }
        .done { (smallPosterImage) in
            film.smallPosterImage = smallPosterImage
        }
        .catch { (error) in
            print(error.localizedDescription)
        }
        .finally { [weak self] in
            self?.films.append(film)
            self?.createMovieDictionary(notifyObservers: true)
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
    
    func getAllFilms() -> [Movie]{
        return films
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
    
    
    @objc func handleFilmReviewed(notification: Notification) {
        createMovieDictionary()
    }
    
    func filterCollection(scope: String = "All", searchText: String){
        filteringScope = scope
        filteringText = searchText
        filteredFilmDict = [:]
        filteredSections = []
        
        filterOn = !searchText.isEmpty || scope != "All"
        
        guard filterOn else{
            NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.collectionFiltered.name, object: nil)
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
        NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.collectionFiltered.name, object: nil)
    }
    
    func sectionIndexTitles() -> [String]{
        let result = filterOn ? filteredSections : sections
        return result
    }
    
    func getSectionTitle(atIndex index: Int) -> String{
        return filterOn ? filteredSections[index] : sections[index]
    }
}

extension FilmCollection: UITableViewDataSource {
    
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
            
            switch settings.filmCollectionLayout {
                
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
            if let film = self.getMovie(at: indexPath), let filmEntity = film.entity {

                let sectionTitle = getSectionTitle(for: film)

                NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.beginUpdates.name, object: nil)
                removeFilm(film)

                if filmDict[sectionTitle] == nil || filmDict[sectionTitle]?.count == 0 {
                    NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.sectionRemovedFromDictionary.name, object: indexPath.section)
                }
                else {
                    NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.filmRemoved.name, object: (film, indexPath))
                }
                
                NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.endUpdates.name, object: nil)
                appDelegate.filmCollectionEntity.removeFromFilms(filmEntity)
                appDelegate.saveContext()
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

