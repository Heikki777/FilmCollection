//
//  FilmCollectionTableViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import PromiseKit
import Firebase

class FilmCollectionTableViewController: UIViewController {

    private enum ReuseIdentifier: String{
        case filmCellSimple
        case filmCellExpanded
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var orderBarButton: UIBarButtonItem!
    
    @IBAction func changeSortOrder(_ sender: Any) {
        order.toggle()
        orderBarButton.title = String(order.symbol)
        createMovieDictionary()
    }
    
    // Firebase
    lazy var databaseRef: DatabaseReference = {
        return Database.database().reference()
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let scopeButtonTitles: [String] = ["All"] + Genre.all.map {$0.rawValue}
    let searchController = UISearchController(searchResultsController: nil)
    
    var sortingRule: SortingRule = .title
    var sections: [String] = []
    var filteredSections: [String] = []
    var movieDict: [String:[Movie]] = [:]
    var filteredMovieDict: [String:[Movie]] = [:]
    var order: SortOrder = .ascending
    
    var movies: [Movie] = []
    var user: User?
    var selectedLayoutOption: FilmCollectionLayoutOption = .posterTitleOverview
    
    var selectedFilteringScope: String{
        let index = searchController.searchBar.selectedScopeButtonIndex
        return scopeButtonTitles[index]
    }
    
    lazy var api: TMDBApi = {
        return TMDBApi.shared
    }()
    
    lazy var jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()
    
    lazy var context = {
        return appDelegate.persistentContainer.viewContext
    }()
    
    lazy var settings = {
        return appDelegate.settings
    }()
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        print("Orientation changed")
        
    }
    
    func reset(){
        self.movies = []
        self.movieDict = [:]
        self.filteredMovieDict = [:]
        self.sections = []
        self.filteredSections = []
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = Auth.auth().currentUser else{
            print("Error! No user")
            // TODO: Show alert
            return
        }
        
        // Check if 3D Touch is available
        if traitCollection.forceTouchCapability == .available{
            print("3D touch is available")
            registerForPreviewing(with: self, sourceView: view)
        }
        else{
            print("3D Touch not available")
        }
        
        self.user = user
        
        let loadingIndicator = LoadingIndicatorViewController(title: "Loading movies", message: "", complete: nil)
        self.tabBarController?.present(loadingIndicator, animated: true, completion: nil)
        
        databaseRef.child("user-movies").child(user.uid).observeSingleEvent(of: .value) { (snapshot) in
            
            if let dbMovies = snapshot.value as? [String:AnyObject]{
                
                print("Movie list value changed: \(dbMovies.count)")
                self.reset()

                for (_,dbMovie) in dbMovies{
                    if let id = dbMovie["id"] as? Int, let rating = dbMovie["rating"] as? Int{
                        attempt{
                            self.api.loadMovie(id, append: ["credits"])
                        }
                        .done{ movie in
                            movie.review = dbMovie["review"] as? String ?? ""
                            movie.rating = Rating.all[rating]
                            // Load the small poster images for the tableView
                            attempt{
                                movie.loadSmallPosterImage()
                            }
                            .done{ (image) in
                                movie.smallPosterImage = image
                            }
                            .catch{ error in
                                print("Could not load small poster image for the movie \(movie.title)")
                                print(error.localizedDescription)
                            }
                            .finally {
                                self.movies.append(movie)
                                let progress = Float(self.movies.count) / Float(dbMovies.count)
                                loadingIndicator.message = "\(Int(progress*100)) %"
                                loadingIndicator.setProgress(progress)
                                _ = self.addMovieToDictionary(movie)
                                self.setNavigationBarTitle("\(self.movies.count) films")
                            }
                        }
                        .catch{ error in
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        // Listen for new movies in the Firebase database
        databaseRef.child("user-movies").child(user.uid).observe(.childAdded, with: { (dataSnapshot) in
            
            // Use this handler only if the movies have been loaded
            guard !self.movies.isEmpty else{
                return
            }
            
            guard let snapshotValue = dataSnapshot.value as? [String:AnyObject],
                let id = snapshotValue["id"] as? Int,
                let rating = snapshotValue["rating"] as? Int else {
                return
            }
            
            // Make sure that the movie is not already in the movies array before loading it.
            if !self.movies.filter({ (movie) -> Bool in
                return movie.id == id
            }).isEmpty{
                return
            }
            
            attempt{
                self.api.loadMovie(id, append: ["credits"])
            }
            .done{ movie in
                movie.rating = Rating.all[rating]
                // Load the small poster images for the tableView
                attempt{
                    movie.loadSmallPosterImage()
                }
                .done{ (image) in
                    movie.smallPosterImage = image
                }
                .catch{ error in
                    print("Could not load small poster image for the movie \(movie.title)")
                    print(error.localizedDescription)
                }
                .finally {
                    self.movies.append(movie)
                    _ = self.addMovieToDictionary(movie)
                    self.setNavigationBarTitle("\(self.movies.count) movies")
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
            
            if let id = snapshotValue["id"] as? Int, let movie = (self.movies.filter { $0.id == id }).first{
                // Rating changed
                if let rating = snapshotValue["rating"] as? Int{
                    movie.rating = Rating.all[rating]
                    if let indexPath = self.getIndexPath(for: movie){
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        })
        
        // Listen for deleted movies in the Firebase database
        databaseRef.child("user-movies").child(user.uid).observe(.childRemoved, with: { (dataSnapshot) in
            if let value = dataSnapshot.value as? [String:Any]{
                if let id = value["id"] as? Int {
                    if let movie = self.getMovie(withId: id), let indexPath = self.getIndexPath(for: movie){
                        self.removeMovie(at: indexPath)
                    }
                }
            }
            
            self.setNavigationBarTitle("\(self.movies.count) movies")
            
        })
                
        orderBarButton.title = String(order.symbol)

        tableView.delegate = self
        tableView.dataSource = self
        
        // Setup the search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter movie collection"
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = scopeButtonTitles

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        
    }
    
    @IBAction func unwindToFilmCollectionTableVC(segue: UIStoryboardSegue){
        print("unwindToFilmCollectionTableVC")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let settingsLayoutOption = FilmCollectionLayoutOption(rawValue: settings.filmCollectionLayout){
            if selectedLayoutOption != settingsLayoutOption{
                selectedLayoutOption = settingsLayoutOption
                tableView.reloadData()
            }
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else{
            print("No segue identifier")
            return
        }
        
        // Prepare for showing the movie detail view
        if identifier == Segue.showFilmDetailSegue.rawValue{
            guard let indexPath = tableView.indexPathForSelectedRow else{
                print("No indexpath")
                return
            }
            
            if let movie = getMovie(at: indexPath){
                
                if let identifier = segue.identifier{
                    if identifier == Segue.showFilmDetailSegue.rawValue{
                        if let destinationVC = segue.destination as? FilmDetailViewController{
                            destinationVC.movie = movie
                        }
                    }
                }
            }
        }
            
        // Prepare for showing sort options table
        else if identifier == Segue.showSortOptionsSegue.rawValue{
            if let popoverTableViewController = segue.destination as? PopoverTableViewController{
                popoverTableViewController.items = SortingRule.all.map{$0.rawValue}
                popoverTableViewController.navigationItem.title = "Order by"
                popoverTableViewController.delegate = self
                if let sortingRuleIndex = SortingRule.all.index(of: sortingRule){
                    popoverTableViewController.selectionIndexPath = IndexPath(row: sortingRuleIndex, section: 0)
                }
            }
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.subtype == UIEventSubtype.motionShake{
            handleShakeGesture()
        }
    }
    
    func handleShakeGesture(){
        // Show a random movie
        let random = Int(arc4random_uniform(UInt32(movies.count)))
        let movie = movies[random]
        if let indexPath = getIndexPath(for: movie){
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
        }
    }
    
    func setNavigationBarTitle(_ title: String){
        self.navigationItem.title = title
    }
    
    func sort(movies: inout [Movie], sortingRule: SortingRule, order: SortOrder = .ascending){
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
    
    func getIndexPath(for movie: Movie) -> IndexPath?{
        let sectionTitle = getSectionTitle(for: movie)
        if isFiltering(){
            if let row = filteredMovieDict[sectionTitle]?.index(of: movie), let section = filteredSections.index(of: sectionTitle){
                return IndexPath.init(row: row, section: section)
            }
        }
        else if let row = movieDict[sectionTitle]?.index(of: movie), let section = sections.index(of: sectionTitle){
            return IndexPath.init(row: row, section: section)
        }
        return nil
    }
    
    func searchBarIsEmpty() -> Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContent(scope: String = "All", searchText: String){
        filteredMovieDict = [:]
        filteredSections = []
        for section in sections{
            if let sectionMovies = movieDict[section]{
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
                    filteredMovieDict[section] = filteredSectionMovies
                }
            }
        }
        
        tableView.reloadData()
        if tableView.numberOfSections > 0{
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    func isFiltering() -> Bool{
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchBarScopeIsFiltering || (searchController.isActive && !searchBarIsEmpty())
    }
    
    // Re-creates the film dictionary by applying the selected sorting rule
    func createMovieDictionary(){
        var tempMovies = movies
        let secondarySortingRule: SortingRule = (sortingRule == .title) ? .year : .title
        sort(movies: &tempMovies, sortingRule: secondarySortingRule, order: order)
        sections = []
        filteredSections = []
        movieDict = [:]
        filteredMovieDict = [:]
        tableView.reloadData()
        
        for movie in tempMovies{
            _ = self.addMovieToDictionary(movie)
        }
    }
    
    /* Adds the movie to the dictionary and updated the tableview.
     Returns false if the movie was already in the collection, otherwise return true.
     */
    func addMovieToDictionary(_ movie: Movie) -> Bool{
        let sectionTitle = getSectionTitle(for: movie)
        if movieDict[sectionTitle] == nil{
            sections.append(sectionTitle)
            movieDict[sectionTitle] = []

            sections.sort(by: { (a, b) -> Bool in
                if sortingRule == .rating{
                    if let ratingA = Rating.init(string: a), let ratingB = Rating.init(string: b){
                        return (order == .ascending) ? ratingA.rawValue < ratingB.rawValue : ratingA.rawValue > ratingB.rawValue
                    }
                }
                return (order == .ascending) ? a < b : a > b
            })
            if let sectionIndex = sections.index(of: sectionTitle){
                if isFiltering(){
                    filterContent(scope: selectedFilteringScope, searchText: searchController.searchBar.text!)
                }
                else{
                    self.tableView.performBatchUpdates({
                        self.tableView.insertSections([sectionIndex], with: .automatic)
                    }, completion: nil)
                }
            }
        }

        if var sectionMovies = movieDict[sectionTitle], !sectionMovies.contains(movie){
            if let sectionIndex = sections.index(of: sectionTitle){
                if movieDict[sectionTitle] != nil{

                    // Add movie to temp array
                    sectionMovies.append(movie)
                    // Sort
                    sort(movies: &sectionMovies, sortingRule: sortingRule)
                    // Find the index of the added movie
                    let index = sectionMovies.index(of: movie)!
                    // Add movie to the dictionary
                    movieDict[sectionTitle]?.insert(movie, at: index)

                    if let rowIndex = movieDict[sectionTitle]?.index(of: movie){
                        let indexPath = IndexPath.init(row: rowIndex, section: sectionIndex)
                        if isFiltering(){
                            filterContent(scope: selectedFilteringScope, searchText: self.searchController.searchBar.text!)
                        }
                        else{
                            self.tableView.performBatchUpdates({
                                self.tableView.insertRows(at: [indexPath], with: .automatic)
                            }, completion: nil)
                        }

                        setNavigationBarTitle("\(movies.count) movies")
                        return true
                    }
                }
            }
        }
        return false
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
    
    func getSectionTitle(atIndex index: Int) -> String{
        return isFiltering() ? filteredSections[index] : sections[index]
    }
    
    func getMovie(at indexPath: IndexPath) -> Movie?{
        let sectionTitle = getSectionTitle(atIndex: indexPath.section)
        return isFiltering() ? filteredMovieDict[sectionTitle]?[indexPath.row] : movieDict[sectionTitle]?[indexPath.row]
    }
    
    func getMovie(withId id: Int) -> Movie?{
        return movies.filter { $0.id == id }.first
    }
    
    func removeMovie(at indexPath: IndexPath){
        let section = isFiltering() ? filteredSections[indexPath.section] : sections[indexPath.section]
        if let movie = isFiltering() ? filteredMovieDict[section]?[indexPath.row] : movieDict[section]?[indexPath.row]{
            print("Trying to delete the movie: \(movie.title)")
            
            if let user = Auth.auth().currentUser{
                // Remove the movie to database
                self.databaseRef.child("user-movies").child("\(user.uid)").child("\(movie.id)").removeValue()
            }
            
            if let indexInDict = movieDict[section]!.index(of: movie){
                print(indexInDict)
                tableView.beginUpdates()
                
                if isFiltering(){
                    if let indexInFilteredMovieDict = filteredMovieDict[section]!.index(of: movie){
                        filteredMovieDict[section]!.remove(at: indexInFilteredMovieDict)
                        if let sectionMovies = filteredMovieDict[section], sectionMovies.isEmpty{
                            filteredMovieDict[section] = nil
                            if let indexOfFilteredSection = filteredSections.index(of: section){
                                tableView.deleteSections([indexOfFilteredSection], with: .automatic)
                            }
                        }
                    }
                }
                
                movieDict[section]!.remove(at: indexInDict)
                movies.remove(at: movies.index(of:movie)!)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                if movieDict[section]!.isEmpty{
                    movieDict[section] = nil
                    tableView.deleteSections([indexPath.section], with: .automatic)
                }
                tableView.endUpdates()
            }
        }
    }
}

extension FilmCollectionTableViewController: UITableViewDataSource{
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let sectionTitle = getSectionTitle(atIndex: section)
        if let sectionMovies = isFiltering() ? filteredMovieDict[sectionTitle] : movieDict[sectionTitle]{
            return sectionMovies.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let movie = getMovie(at: indexPath){
            
            switch settings.filmCollectionLayout {
                
            case FilmCollectionLayoutOption.posterTitleOverview.rawValue:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.filmCellExpanded.rawValue) as! FilmTableViewCellExpanded
                cell.configure(withMovie: movie)
                cell.selectionStyle = .none
                return cell

            case FilmCollectionLayoutOption.title.rawValue:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.filmCellSimple.rawValue) as! FilmTableViewCellSimple
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
            removeMovie(at: indexPath)
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return isFiltering() ? filteredSections : sections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isFiltering(){
            return filteredSections[section]
        }
        return sections[section]
    }
    
}

extension FilmCollectionTableViewController: UITableViewDelegate{
    // MARK: - UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return isFiltering() ? filteredMovieDict.count : movieDict.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch settings.filmCollectionLayout{
        case FilmCollectionLayoutOption.posterTitleOverview.rawValue:
            return 138
        case FilmCollectionLayoutOption.title.rawValue:
            return 45
        default:
            return 0
        }
    }
   
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.gray
        if let header = view as? UITableViewHeaderFooterView{
            header.textLabel?.textColor = UIColor.white
        }
    }

}

extension FilmCollectionTableViewController: UISearchResultsUpdating{
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text{
            filterContent(scope: selectedFilteringScope, searchText: text)
        }
        else{
            print("No search text")
        }
    }
    
}

extension FilmCollectionTableViewController: UISearchBarDelegate{
    // MARK: - UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let scope = scopeButtonTitles[selectedScope]
        print("Selected scope: \(scope)")
        filterContent(scope: selectedFilteringScope, searchText: searchBar.text ?? "")
    }
    
    
}

extension FilmCollectionTableViewController: UIPopoverPresentationControllerDelegate{
    // MARK: - UIPopoverPresentationControllerDelegate
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController){
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .currentContext
    }
}

extension FilmCollectionTableViewController: PopoverTableItemSelectionDelegate{
    func itemSelected(indexPath: IndexPath){
        sortingRule = SortingRule.all[indexPath.row]
        createMovieDictionary()
        self.tableView.reloadData()
        self.navigationItem.title = "\(movies.count) movies"
    }
}

extension FilmCollectionTableViewController: UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        let point = tableView.convert(location, from: self.view)
        
        guard let indexPath = tableView.indexPathForRow(at: point) else{
            print("No indexpath for point: \(point)")
            return nil
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else{
            print("no cell")
            return nil
        }
        
        let sectionTitle = getSectionTitle(atIndex: indexPath.section)
        guard let film = movieDict[sectionTitle]?[indexPath.row] else{
            print("There is no film at indexPath: \(indexPath)")
            return nil
        }
        
        guard let filmPreviewVC = storyboard?.instantiateViewController(withIdentifier: "FilmPreviewViewController") as? FilmPreviewViewController else{
            print("A FilmPreviewViewController could not be instantiated")
            return nil
        }
        
        previewingContext.sourceRect = self.view.convert(cell.frame, from: self.tableView)
        filmPreviewVC.film = film
        
        return filmPreviewVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        // TODO:
    }
}
