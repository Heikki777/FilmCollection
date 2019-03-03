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
    
    static func sort(movies: inout [Film], sortingRule: SortingRule, order: SortOrder = .ascending){
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
    
    private var films: [Film] = []
    private var sections: [String] = []
    private var filteredSections: [String] = []
    private var filmDict: [String:[Film]] = [:]
    private var filteredFilmDict: [String: [Film]] = [:]
    private var filteringScope: String = ""
    private var filteringText: String = ""
    private var filterOn: Bool = false {
        didSet{
            if filterOn == false{
                filteringScope = ""
                filteringText = ""
            }
        }
    }
    
    weak var loadingIndicatorDataSource: LoadingProgressDataSource?
    
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
    let imdbApi: IMDbAPI = IMDbAPI.shared
    
    private override init(){
        super.init()
        
        // Update IMDb ratings every 2 hours
        imdbApi.setScheduledRatingsUpdate(withInterval: DispatchTimeInterval.seconds(60*60*2))
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmReviewed(notification:)), name: Notifications.FilmCollectionNotification.filmReviewed.name, object: nil)

        let queue = DispatchQueue(label: "loadCollection", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
        let group = DispatchGroup()
        
        let collectionLoadingFinished = DispatchWorkItem {
            DispatchQueue.main.async {
                print("collectionLoadingFinished")
                self.loadingIndicatorDataSource?.loadingFinished()
                self.createMovieDictionary()
            }
        }
        
        let totalCount = appDelegate.filmEntities.count
        
        guard totalCount > 0 else {
            group.notify(queue: queue, work: collectionLoadingFinished)
            return
        }
        
        var countDown = totalCount
        appDelegate.filmEntities.forEach { filmEntity in
            group.enter()
            loadFilmFromTMDB(filmEntity) { [weak self] filmResult in
                DispatchQueue.main.async {

                    switch filmResult {
                    case .success(let film):
                        print("\(film.titleYear) loaded")
                        self?.addFilm(film, resetDictionary: false)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                    group.leave()
                    countDown -= 1
                    
                    let progress: Float = Float(totalCount - countDown) / Float(totalCount)
                    self?.loadingIndicatorDataSource?.loadingProgressChanged(progress: progress)
                    
                    if countDown == 0 {
                        group.notify(queue: queue, work: collectionLoadingFinished)
                    }
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func createMovieDictionary(){
        let secondarySortingRule: SortingRule = (sortingRule == .title) ? .year : .title
        FilmCollection.sort(movies: &films, sortingRule: secondarySortingRule, order: order)
        
        sections = []
        filteredSections = []
        filmDict = [:]
        filteredFilmDict = [:]
        
        NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.filmDictionaryChanged.name, object: nil)

        for film in films {
            self.addMovieToDictionary(film)
        }
        
    }
    
    private func addMovieToDictionary(_ film: Film){
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
    
    private func loadFilmFromTMDB(_ filmEntity: FilmEntity, completion: @escaping (GenericResult<Film>) -> Void) {

        self.api.loadFilm(Int(filmEntity.id), append: ["credits"]) { filmResult in
            switch filmResult {
            case .success(let film):
                film.rating = Rating(rawValue: Int(filmEntity.rating)) ?? Rating.NotRated
                completion(.success(film))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func contains(_ film: Film) -> Bool{
        return films.contains(film)
    }
    
    func removeFilm(_ film: Film){
        
        if let filmEntity = film.entity {
            appDelegate.filmCollectionEntity.removeFromFilms(filmEntity)
            appDelegate.saveContext()
        }

        guard let indexPath = getIndexPath(for: film) else { return }
        
        let sectionTitle = getSectionTitle(for: film)
        if let index = films.index(of: film){
            films.remove(at: index)
        }
        if let row = filmDict[sectionTitle]?.index(of: film),
            let section = sections.firstIndex(of: sectionTitle){
            
            // Remove film
            // Remove section
            if filmDict[sectionTitle]?.count == 1 {
                NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.beginUpdates.name, object: nil)
                filmDict.removeValue(forKey: sectionTitle)
                sections.remove(at: section)
                NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.sectionRemovedFromDictionary.name, object: indexPath.section)
                NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.endUpdates.name, object: nil)
            }
            else {
                NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.beginUpdates.name, object: nil)
                filmDict[sectionTitle]?.remove(at: row)
                NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.filmRemoved.name, object: (film, indexPath))
                NotificationCenter.default.post(name: Notifications.FilmCollectionNotification.endUpdates.name, object: nil)
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
        TMDBApi.shared.loadFilm(id, append: ["credits"]) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let film):
                    self?.addFilm(film, resetDictionary: true)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func addFilm(_ film: Film, resetDictionary: Bool){
        guard !films.contains(film) else { return }
        
        self.films.append(film)
        if resetDictionary {
            self.createMovieDictionary()
        }
    }
    
    func randomFilm() -> Film?{

        guard size > 0 else{
            return nil
        }
        
        let random = Int(arc4random_uniform(UInt32(size)))
        return films[random]
    }
    
    func randomFilms(_ count: Int) -> Set<Film> {
        var result = Set<Film>()
        guard count <= self.size else { return result }
        
        while let randFilm = self.randomFilm(), result.count < count {
            result.insert(randFilm)
        }
        return result
    }
    
    func getFilm(withId id: Int) -> Film?{
        return films.filter { $0.id == id }.first
    }
    
    func getFilm(at indexPath: IndexPath) -> Film?{
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
    
    func getAllFilms() -> [Film]{
        return films
    }
    
    func getSectionTitle(section: Int) -> String?{
        return (filterOn) ? filteredSections[section] : sections[section]
    }
    
    func getIndexPath(for movie: Film) -> IndexPath?{
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
    
    func filmsInSection(_ sectionTitle: String) -> [Film]{
        let sectionFilms = filterOn ? filteredFilmDict[sectionTitle] : filmDict[sectionTitle]
        return sectionFilms ?? []
    }
    
    func filmsInSection(_ section: Int) -> [Film]{
        let sectionTitle = getSectionTitle(atIndex: section)
        let sectionFilms = filterOn ? filteredFilmDict[sectionTitle] : filmDict[sectionTitle]
        let result = sectionFilms ?? []
        return result
    }
    
    func getSectionTitle(for movie: Film) -> String{
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
        
        if let film = self.getFilm(at: indexPath){

            guard let layoutOption = FilmCollectionLayoutOption(rawValue: settings.filmCollectionLayout) else {
                print("Error! Invalid layout option")
                return UITableViewCell()
            }

            switch layoutOption {
                
            case .posterAndBriefInfo:
                let cell = tableView.dequeueReusableCell(withIdentifier: "filmCellExpanded") as! FilmTableViewCellExpanded
                cell.configure(withFilm: film)
                cell.selectionStyle = .none
                return cell
                
            case .title:
                let cell = tableView.dequeueReusableCell(withIdentifier: "filmCellSimple") as! FilmTableViewCellSimple
                cell.configure(withMovie: film)
                cell.selectionStyle = .none
                return cell
                
            case .poster:
                // Handled elsewhere
                break
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete{
            if let film = self.getFilm(at: indexPath){
                removeFilm(film)
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
