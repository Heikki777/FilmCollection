//
//  FilmCollectionTableViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class FilmCollectionTableViewController: UIViewController {

    private enum ReuseIdentifier: String{
        case filmCellSimple
        case filmCellExpanded
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var orderBarButton: UIBarButtonItem!
    
    @IBAction func changeSortOrder(_ sender: Any) {
        filmCollection.order.toggle()
        orderBarButton.title = String(filmCollection.order.symbol)
    }

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let filmCollection = FilmCollection.shared
    let scopeButtonTitles: [String] = ["All"] + Genre.all.map {$0.rawValue}
    let searchController = UISearchController(searchResultsController: nil)
    
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
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createObservers()
        
        // Check if 3D Touch is available
        if traitCollection.forceTouchCapability == .available{
            registerForPreviewing(with: self, sourceView: view)
        }
        
        orderBarButton.title = String(filmCollection.order.symbol)

        tableView.delegate = self
        tableView.dataSource = filmCollection
        
        // Setup the search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter movie collection"
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = scopeButtonTitles

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true

        if let layoutOption = FilmCollectionLayoutOption(rawValue: appDelegate.settings.filmCollectionLayout){
            self.selectedLayoutOption = layoutOption
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)        
    }
    
    func createObservers(){
        let collectionLoaded = Notifications.FilmCollectionNotification.filmCollectionValueChanged.name
        let filmAddedToCollection = Notifications.FilmCollectionNotification.filmAddedToCollection.name
        let filmChanged = Notifications.FilmCollectionNotification.filmChanged.name
        let filmRemoved = Notifications.FilmCollectionNotification.filmRemoved.name
        let progressChanged = Notifications.FilmCollectionNotification.loadingProgressChanged.name
        let filmDictionaryChanged = Notifications.FilmCollectionNotification.filmDictionaryChanged.name
        let newSectionAdded = Notifications.FilmCollectionNotification.newSectionAddedToDictionary.name
        let sectionRemoved = Notifications.FilmCollectionNotification.sectionRemovedFromDictionary.name
        let beginUpdates = Notifications.FilmCollectionNotification.beginUpdates.name
        let endUpdates = Notifications.FilmCollectionNotification.endUpdates.name
        let collectionFiltered = Notifications.FilmCollectionNotification.collectionFiltered.name
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionLoaded(notification:)), name: collectionLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionAddition(notification:)), name: filmAddedToCollection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeInFilmData(notification:)), name: filmChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmRemoval(notification:)), name: filmRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLoadingProgressChange(notification:)), name: progressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFilmDictionaryChange(notification:)), name: filmDictionaryChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSectionAddition(notification:)), name: newSectionAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSectionRemoval(notification:)), name: sectionRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(beginUpdates(notification:)), name: beginUpdates, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endUpdates(notification:)), name: endUpdates, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCollectionFiltered(notification:)), name: collectionFiltered, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleShowDetailOfNotifiedFilm(notification:)), name: NSNotification.Name.init("showDetailOfNotifiedFilm"), object: nil)

    }
    
    @objc func handleCollectionFiltered(notification: NSNotification){
        self.tableView.reloadData()
    }
    
    @objc func beginUpdates(notification: NSNotification){
        self.tableView.beginUpdates()
    }
    
    @objc func endUpdates(notification: NSNotification){
        self.tableView.endUpdates()
    }
    
    @objc func handleSectionAddition(notification: NSNotification){
        if let sectionIndex = notification.object as? Int {
            self.tableView.insertSections([sectionIndex], with: .automatic)
        }
    }
    
    @objc func handleSectionRemoval(notification: NSNotification){
        if let sectionIndex = notification.object as? Int{
            self.tableView.deleteSections([sectionIndex], with: .automatic)
            self.setNavigationBarTitle("\(self.filmCollection.size) films")
        }
    }
    
    @objc func handleFilmDictionaryChange(notification: NSNotification){
        let sectionIndices: IndexSet = IndexSet(0..<tableView.numberOfSections)
        tableView.deleteSections(sectionIndices, with: .automatic)
        tableView.reloadData()
    }
    
    @objc func handleFilmRemoval(notification: NSNotification){
        guard let (_, indexPath) = notification.object as? (Film, IndexPath) else {
            return
        }
    
        // Remove the corresponding tableview cell
        if (self.tableView.numberOfRows(inSection: indexPath.section) == 1) {
            self.tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
        else {
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        self.setNavigationBarTitle("\(self.filmCollection.size) films")
    }
    
    @objc func handleShowDetailOfNotifiedFilm(notification: NSNotification){
        guard let filmIdWithinNotification = appDelegate.filmIdWithinNotification else {
            return
        }
        guard let notifiedFilm = filmCollection.getMovie(withId: filmIdWithinNotification) else {
            return
        }
        if let indexPath = filmCollection.getIndexPath(for: notifiedFilm){
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
        }
    }
    
    @objc func handleCollectionLoaded(notification: NSNotification){
        
        guard let filmIdWithinNotification = appDelegate.filmIdWithinNotification else {
            return
        }
        guard let notifiedFilm = filmCollection.getMovie(withId: filmIdWithinNotification) else {
            return
        }
        if let indexPath = filmCollection.getIndexPath(for: notifiedFilm){
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
        }
    }
    
    @objc func handleCollectionAddition(notification: NSNotification){
        if let film = notification.object as? Film{

            if let indexPath = filmCollection.getIndexPath(for: film){
                self.tableView.insertRows(at: [indexPath], with: .automatic)
                self.setNavigationBarTitle("\(self.filmCollection.size) films")
            }
        }
    }
    
    @objc func handleChangeInFilmData(notification: NSNotification){
        if let film = notification.object as? Film, let indexPath = filmCollection.getIndexPath(for: film){
            // Reload the tableView cell that displays the changed film
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    @objc func handleLoadingProgressChange(notification: NSNotification){
        guard let homeTabBarController = self.tabBarController as? HomeTabBarController else{
            return
        }
        if let progress = notification.object as? Float{
            let percentage: Int = Int(progress * 100)
            homeTabBarController.showLoadingIndicator(withTitle: "Loading films", message: "\(percentage) %", progress: progress, complete: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else { return }
        
        // Prepare for showing the movie detail view
        if identifier == Segue.showFilmDetailSegue.rawValue{
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            
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
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if event?.subtype == UIEvent.EventSubtype.motionShake{
            handleShakeGesture()
        }
    }
    
    func handleShakeGesture(){
        // Show a random movie
        guard let movie = filmCollection.randomFilm() else{
            return
        }
        if let indexPath = filmCollection.getIndexPath(for: movie){
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            performSegue(withIdentifier: Segue.showFilmDetailSegue.rawValue, sender: nil)
        }
    }
    
    func setNavigationBarTitle(_ title: String){
        self.navigationItem.title = title
    }
    
    func searchBarIsEmpty() -> Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
}

extension FilmCollectionTableViewController: UITableViewDelegate{
    // MARK: - UITableViewDelegate
    
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
   
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
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
        filmCollection.filterCollection(scope: selectedFilteringScope, searchText: searchController.searchBar.text ?? "")
        tableView.reloadData()
        if tableView.numberOfSections > 0{
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
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
        filmCollection.filterCollection(scope: selectedFilteringScope, searchText: searchBar.text ?? "")
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
        filmCollection.sortingRule = SortingRule.all[indexPath.row]
    }
}

extension FilmCollectionTableViewController: UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let point = tableView.convert(location, from: self.view)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        guard let film = filmCollection.getMovie(at: indexPath) else { return nil }
        guard let filmPreviewVC = storyboard?.instantiateViewController(withIdentifier: "FilmPreviewViewController") as? FilmPreviewViewController else { return nil }
        
        previewingContext.sourceRect = self.view.convert(cell.frame, from: self.tableView)
        filmPreviewVC.film = film
        
        return filmPreviewVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        guard let filmPreviewVC = viewControllerToCommit as? FilmPreviewViewController else { return }
        guard let film = filmPreviewVC.film else { return }
        
        if let vc = self.storyboard!.instantiateViewController(withIdentifier: "FilmDetailViewController") as? FilmDetailViewController{
            vc.film = film
            show(vc, sender: self)
        }
    }
}
