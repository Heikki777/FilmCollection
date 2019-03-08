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
    
    @IBAction func handleRandomBarButtonPressed(_ sender: UIBarButtonItem) {
        showRandomFilm()
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
            registerForPreviewing(with: self, sourceView: view)
        }
        
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
        print("deinit FilmPosterCollectionViewController")
        NotificationCenter.default.removeObserver(self)
    }
    
    func createObservers(){
        let collectionLoaded = Notifications.FilmCollectionNotification.filmCollectionValueChanged.name
        let filmAddedToCollection = Notifications.FilmCollectionNotification.filmAddedToCollection.name
        let filmChanged = Notifications.FilmCollectionNotification.filmChanged.name
        let filmRemoved = Notifications.FilmCollectionNotification.filmRemoved.name
        let filmDictionaryChanged = Notifications.FilmCollectionNotification.filmDictionaryChanged.name
        let collectionFiltered = Notifications.FilmCollectionNotification.collectionFiltered.name
        let sectionRemoved = Notifications.FilmCollectionNotification.sectionRemovedFromDictionary.name

        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionLoaded(notification:)), name: collectionLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionAddition(notification:)), name: filmAddedToCollection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeInFilmData(notification:)), name: filmChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmRemoval(notification:)), name: filmRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmDictionaryChange(notification:)), name: filmDictionaryChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionFiltered(notification:)), name: collectionFiltered, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSectionRemoval(notification:)), name: sectionRemoved, object: nil)
    }
    
    func setNavigationBarTitle(_ title: String){
        self.navigationItem.title = title
    }
    
    @objc func handleSectionRemoval(notification: NSNotification){
        if let sectionIndex = notification.object as? Int{
            self.collectionView.deleteSections([sectionIndex])
        }
    }
    
    @objc func handleFilmRemoval(notification: NSNotification){
        guard let (film, indexPath) = notification.object as? (Film, IndexPath) else {
            return
        }
        self.removeMovie(at: indexPath)
    }
    
    @objc func handleCollectionFiltered(notification: NSNotification){
        collectionView?.reloadData()
    }
    
    @objc func handleCollectionAddition(notification: NSNotification){
        if let film = notification.object as? Film{
            setNavigationBarTitle("\(filmCollection.size) films")
            collectionView!.reloadData()
        }
    }
    
    @objc func handleFilmDictionaryChange(notification: NSNotification){
        collectionView!.reloadData()
    }
    
    @objc func handleChangeInFilmData(notification: NSNotification){
        if let film = notification.object as? Film, let indexPath = filmCollection.getIndexPath(for: film){
            // Reload the tableView cell that displays the changed film
            collectionView?.reloadItems(at: [indexPath])
        }
    }
    
    @objc func handleCollectionLoaded(notification: NSNotification){
        guard let collectionView = collectionView else{
            return
        }
        guard let filmIdWithinNotification = appDelegate.filmIdWithinNotification else {
            return
        }
        guard let notifiedFilm = filmCollection.getFilm(withId: filmIdWithinNotification) else {
            return
        }
        
        if let indexPath = filmCollection.getIndexPath(for: notifiedFilm){
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
            performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
        }
    }
    
    func removeMovie(at indexPath: IndexPath){
        // Remove the corresponding UICollectionView cell
        DispatchQueue.main.async {
            self.collectionView!.deleteItems(at: [indexPath])
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
            return
        }
        
        // Prepare for showing the film detail view
        if identifier == Segue.showFilmDetailSegue.rawValue{
            guard let indexPath = collectionView!.indexPathsForSelectedItems?.first else{
                return
            }
            
            if let film = filmCollection.getFilm(at: indexPath){
                
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

    // MARK: UICollectionViewDataSource

    override func indexTitles(for collectionView: UICollectionView) -> [String]? {
        let titles = filmCollection.sectionIndexTitles()
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
        
        // Configure the cell
        if let film = filmCollection.getFilm(at: indexPath){
            cell.configure(withFilm: film)
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
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if event?.subtype == UIEvent.EventSubtype.motionShake{
            handleShakeGesture()
        }
    }
    
    func showRandomFilm(){
        // Show a random movie
        guard let movie = filmCollection.randomFilm() else{
            return
        }
        if let indexPath = filmCollection.getIndexPath(for: movie){
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
            performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
        }
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
        filmCollection.filterCollection(scope: selectedFilteringScope, searchText: searchBar.text ?? "")
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension FilmPosterCollectionViewController: UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let locationInCollectionView: CGPoint = collectionView?.convert(location, from: self.view) else {
            return nil
        }
        
        guard let indexPath = collectionView?.indexPathForItem(at: locationInCollectionView) else {
            return nil
        }
        
        guard let cell = collectionView?.cellForItem(at: indexPath) as? FilmPosterCollectionViewCell else {
            return nil
        }
        
        guard let film = filmCollection.getFilm(at: indexPath) else {
            return nil
        }
        
        guard let filmPreviewVC = storyboard?.instantiateViewController(withIdentifier: "FilmPreviewViewController") as? FilmPreviewViewController else{
            return nil
        }
        
        previewingContext.sourceRect = self.view.convert(cell.frame, from: self.collectionView)
        filmPreviewVC.film = film
        
        return filmPreviewVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        guard let filmPreviewVC = viewControllerToCommit as? FilmPreviewViewController else{
            return
        }
        
        guard let film = filmPreviewVC.film else {
            return
        }
            
        if let vc = self.storyboard!.instantiateViewController(withIdentifier: "FilmDetailViewController") as? FilmDetailViewController{
            vc.film = film
            vc.preferredContentSize = CGSize(width: 0, height: 0)
            show(vc, sender: self)
        }
    }
}

// MARK: - Shakeable
extension FilmPosterCollectionViewController: Shakeable {
    func handleShakeGesture(){
        showRandomFilm()
    }
}
