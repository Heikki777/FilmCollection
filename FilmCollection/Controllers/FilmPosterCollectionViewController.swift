//
//  FilmPosterCollectionViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 07/07/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

private let reuseIdentifier = "FilmPosterCollectionViewCell"

class FilmPosterCollectionViewController: UICollectionViewController {
    
    @IBOutlet weak var orderBarButton: UIBarButtonItem!
    
    @IBAction func changeSortOrder(_ sender: Any) {
        filmCollection.order.toggle()
        orderBarButton.title = String(filmCollection.order.symbol)
    }
    
    @IBAction func unwindFromDetailToFilmPosterCollectionVC(_ segue: UIStoryboardSegue){
        
    }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let filmCollection = FilmCollection.shared
    let scopeButtonTitles: [String] = ["All"] + Genre.all.map {$0.rawValue}
    let searchController = UISearchController(searchResultsController: nil)
    
    var selectedFilteringScope: String{
        let index = searchController.searchBar.selectedScopeButtonIndex
        return scopeButtonTitles[index]
    }

    var sectionCount = 0
    var filmCount = 0
    
    override func viewDidLoad() {
        print("FilmPosterCollectionViewController")
        super.viewDidLoad()
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        
        // Setup the search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter movie collection"
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = scopeButtonTitles
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        
        // Check if 3D Touch is available
        if traitCollection.forceTouchCapability == .available{
            print("3D touch is available")
            registerForPreviewing(with: self, sourceView: view)
        }
        else{
            print("3D Touch not available")
        }
        
        print("FILMS: \(filmCollection.size)")
        
        createObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNavigationBarTitle("\(filmCollection.size) films")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func createObservers(){
        let collectionLoaded = Notifications.FilmCollectionNotification.filmCollectionValueChanged.name
        let filmAddedToCollection = Notifications.FilmCollectionNotification.filmAddedToCollection.name
        let filmChanged = Notifications.FilmCollectionNotification.filmChanged.name
        let filmRemoved = Notifications.FilmCollectionNotification.filmRemoved.name
        let progressChanged = Notifications.FilmCollectionNotification.loadingProgressChanged.name
        let filmDictionaryChanged = Notifications.FilmCollectionNotification.filmDictionaryChanged.name
        let collectionFiltered = Notifications.FilmCollectionNotification.collectionFiltered.name
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionLoaded(notification:)), name: collectionLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionAddition(notification:)), name: filmAddedToCollection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeInFilmData(notification:)), name: filmChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmRemoval(notification:)), name: filmRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLoadingProgressChange(notification:)), name: progressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmDictionaryChange(notification:)), name: filmDictionaryChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionFiltered(notification:)), name: collectionFiltered, object: nil)
    }
    
    func setNavigationBarTitle(_ title: String){
        self.navigationItem.title = title
    }
    
    @objc func handleFilmRemoval(notification: NSNotification){
        print("handleFilmRemoval")
        guard let (film, indexPath) = notification.object as? (Film, IndexPath) else {
            return
        }
        let cell = collectionView?.cellForItem(at: indexPath) as! FilmPosterCollectionViewCell
        if cell.filmId == film.id{
            self.removeMovie(at: indexPath)
        }
        else{
            print("Error! handleFilmRemoval. film.id does not match with cell's filmId")
        }
    }
    
    @objc func handleCollectionFiltered(notification: NSNotification){
        collectionView?.reloadData()
    }
    
    @objc func handleCollectionAddition(notification: NSNotification){
        print("handleCollectionAddition")
        
        if let film = notification.object as? Film{
            print("Film added: \(film.title)")
            setNavigationBarTitle("\(filmCollection.size) films")
            collectionView!.reloadData()
        }
    }
    
    @objc func handleFilmDictionaryChange(notification: NSNotification){
        print("FilmPosterCollectionViewController: handleFilmDictionaryChange")
        collectionView!.reloadData()
    }
    
    @objc func handleChangeInFilmData(notification: NSNotification){
        if let film = notification.object as? Film, let indexPath = filmCollection.getIndexPath(for: film){
            // Reload the tableView cell that displays the changed film
            collectionView?.reloadItems(at: [indexPath])
        }
    }
    
    @objc func handleLoadingProgressChange(notification: NSNotification){
        print("handleLoadingProgressChange: \(Int(notification.object as! Float * 100)) %")
        guard let homeTabBarController = self.tabBarController as? HomeTabBarController else{
            return
        }
        if let progress = notification.object as? Float{
            let percentage: Int = Int(progress * 100)
            homeTabBarController.showLoadingIndicator(withTitle: "Loading films", message: "\(percentage) %", progress: progress, complete: nil)
        }
    }
    
    @objc func handleCollectionLoaded(notification: NSNotification){
        guard let collectionView = collectionView else{
            return
        }
        guard let filmIdWithinNotification = appDelegate.filmIdWithinNotification else {
            return
        }
        guard let notifiedFilm = filmCollection.getMovie(withId: filmIdWithinNotification) else {
            return
        }
        
        if let indexPath = filmCollection.getIndexPath(for: notifiedFilm){
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
            performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
        }
    }
    
    func removeMovie(at indexPath: IndexPath){
        // Remove the corresponding UICollectionView cell
        let sectionTitle = filmCollection.getSectionTitle(atIndex: indexPath.section)
        
        DispatchQueue.main.async {
            self.collectionView!.performBatchUpdates({
                self.collectionView!.deleteItems(at: [indexPath])
                
                // If the section is empty now, remove that too
                if self.filmCollection.filmsInSection(sectionTitle).isEmpty {
                    self.collectionView!.deleteSections([indexPath.section])
                }
            })
        }
    }
    
    func searchBarIsEmpty() -> Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool{
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchBarScopeIsFiltering || (searchController.isActive && !searchBarIsEmpty())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else{
            print("No segue identifier")
            return
        }
        
        // Prepare for showing the movie detail view
        if identifier == Segue.showFilmDetailSegue.rawValue{
            guard let indexPath = collectionView!.indexPathsForSelectedItems?.first else{
                print("No indexpath")
                return
            }
            
            if let film = filmCollection.getMovie(at: indexPath){
                
                if let identifier = segue.identifier{
                    if identifier == Segue.showFilmDetailSegue.rawValue{
                        if let destinationVC = segue.destination as? FilmDetailViewController{
                            destinationVC.film = film
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
                if let sortingRuleIndex = SortingRule.all.index(of: filmCollection.sortingRule){
                    popoverTableViewController.selectionIndexPath = IndexPath(row: sortingRuleIndex, section: 0)
                }
            }
        }
    }
    
    // MARK: UICollectionViewDelegate


    // MARK: UICollectionViewDataSource

    override func indexTitles(for collectionView: UICollectionView) -> [String]? {
        let titles = filmCollection.sectionIndexTitles()
        print("titles: \(titles)")
        return titles
    }
    
    override func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
        if let sections = indexTitles(for: collectionView), let index = sections.index(of: title){
            return IndexPath(row: index, section: 0)
        }
        return IndexPath(row: 0, section: 0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filmCollection.filmsInSection(section).count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FilmPosterCollectionViewCell
        
        // Reset
        cell.filmId = nil
        cell.posterImageView.image = nil
        
        // Configure the cell
        if let film = filmCollection.getMovie(at: indexPath){
            cell.posterImageView.image = film.smallPosterImage
            cell.filmId = film.id
        }
    
        return cell
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return filmCollection.sectionIndexTitles().count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                withReuseIdentifier: "ImageCollectionReusableView",
                for: indexPath) as! ImageCollectionReusableView
            
            headerView.tintColor = UIColor.gray
            
            let header = filmCollection.getSectionTitle(atIndex: indexPath.section)
            headerView.label.text = header
            return headerView
            
        default:
            break
        }
        return UICollectionReusableView()
    }
}

extension FilmPosterCollectionViewController: PopoverTableItemSelectionDelegate{
    // MARK: - PopoverTableItemSelectionDelegate
    func itemSelected(indexPath: IndexPath){
        filmCollection.sortingRule = SortingRule.all[indexPath.row]
    }
}


extension FilmPosterCollectionViewController: UISearchResultsUpdating{
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filmCollection.filterCollection(scope: selectedFilteringScope, searchText: searchController.searchBar.text ?? "")
    }
    
}

extension FilmPosterCollectionViewController: UISearchBarDelegate{
    // MARK: - UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let scope = scopeButtonTitles[selectedScope]
        print("Selected scope: \(scope)")
        filmCollection.filterCollection(scope: selectedFilteringScope, searchText: searchBar.text ?? "")
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension FilmPosterCollectionViewController: UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let locationInCollectionView: CGPoint = collectionView?.convert(location, from: self.view) else {
            print("Location not in CollectionView")
            return nil
        }
        
        guard let indexPath = collectionView?.indexPathForItem(at: locationInCollectionView) else {
            print("No indexPath")
            return nil
        }
        
        guard let cell = collectionView?.cellForItem(at: indexPath) as? FilmPosterCollectionViewCell else {
            print("No cell at indexPath: \(indexPath)")
            return nil
        }
        
        guard let film = filmCollection.getMovie(at: indexPath) else {
            print("No film at indexPath")
            return nil
        }
        
        guard let filmPreviewVC = storyboard?.instantiateViewController(withIdentifier: "FilmPreviewViewController") as? FilmPreviewViewController else{
            print("A FilmPreviewViewController could not be instantiated")
            return nil
        }
        
        previewingContext.sourceRect = self.view.convert(cell.frame, from: self.collectionView)
        filmPreviewVC.film = film
        
        return filmPreviewVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        guard let filmPreviewVC = viewControllerToCommit as? FilmPreviewViewController else{
            print("viewControllerToCommit is not an instance of FilmPreviewViewController")
            return
        }
        
        guard let film = filmPreviewVC.film else {
            print("No film in FilmPreviewViewController")
            return
        }
            
        if let vc = self.storyboard!.instantiateViewController(withIdentifier: "FilmDetailViewController") as? FilmDetailViewController{
            vc.film = film
            vc.preferredContentSize = CGSize(width: 0, height: 0)
            show(vc, sender: self)
        }
    }
}
