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
        
        print("Orientation changed")
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        print("FilmCollectionTableViewController viewDidLoad")
        super.viewDidLoad()
        
        createObservers()
        
        // Check if 3D Touch is available
        if traitCollection.forceTouchCapability == .available{
            print("3D touch is available")
            registerForPreviewing(with: self, sourceView: view)
        }
        else{
            print("3D Touch not available")
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
        
        //print("FILMS: \(filmCollection.size)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("FilmCollectionTableViewController viewDidAppear")
    }
    
    func createObservers(){
        let collectionLoaded = Notification.Name(rawValue: FilmCollection.NotificationKey.filmCollectionValueChanged.rawValue)
        let filmAddedToCollection = Notification.Name(rawValue: FilmCollection.NotificationKey.filmAddedToCollection.rawValue)
        let filmChanged = Notification.Name(rawValue: FilmCollection.NotificationKey.filmChanged.rawValue)
        let filmRemoved = Notification.Name(rawValue: FilmCollection.NotificationKey.filmRemoved.rawValue)
        let progressChanged = Notification.Name(rawValue: FilmCollection.NotificationKey.loadingProgressChanged.rawValue)
        let filmDictionaryChanged = Notification.Name(rawValue: FilmCollection.NotificationKey.filmDictionaryChanged.rawValue)
        let newSectionAdded = Notification.Name(rawValue: FilmCollection.NotificationKey.newSectionAddedToDictionary.rawValue)
        let sectionRemoved = Notification.Name(rawValue: FilmCollection.NotificationKey.sectionRemovedFromDictionary.rawValue)
        let beginUpdates = Notification.Name(rawValue: FilmCollection.NotificationKey.beginUpdates.rawValue)
        let endUpdates = Notification.Name(rawValue: FilmCollection.NotificationKey.endUpdates.rawValue)
        let collectionFiltered = Notification.Name(rawValue: FilmCollection.NotificationKey.collectionFiltered.rawValue)
        
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
        if let sectionIndex = notification.object as? Int{
            print("new section: \(sectionIndex)")
            self.tableView.insertSections([sectionIndex], with: .automatic)
        }
    }
    
    @objc func handleSectionRemoval(notification: NSNotification){
        if let sectionIndex = notification.object as? Int{
            print("remove section at index: \(sectionIndex)")
            self.tableView.deleteSections([sectionIndex], with: .automatic)
        }
    }
    
    @objc func handleFilmDictionaryChange(notification: NSNotification){
        let sectionIndices: IndexSet = IndexSet(0..<tableView.numberOfSections)
        tableView.deleteSections(sectionIndices, with: .automatic)
        tableView.reloadData()
    }
    
    @objc func handleFilmRemoval(notification: NSNotification){
        guard let (film, indexPath) = notification.object as? (Movie, IndexPath) else {
            return
        }
        print("Remove: \(film.title) at indexPath: \(indexPath)")
    
        // Remove the corresponding tableview cell
        self.tableView.deleteRows(at: [indexPath], with: .automatic)
        self.setNavigationBarTitle("\(self.filmCollection.size) films")

    }
    
    @objc func handleCollectionLoaded(notification: NSNotification){
        print(filmCollection.size)
    }
    
    @objc func handleCollectionAddition(notification: NSNotification){
        if let film = notification.object as? Movie{

            if let indexPath = filmCollection.getIndexPath(for: film){
                self.tableView.insertRows(at: [indexPath], with: .automatic)
                self.setNavigationBarTitle("\(self.filmCollection.size) films")
            }
        }
    }
    
    @objc func handleChangeInFilmData(notification: NSNotification){
        if let film = notification.object as? Movie, let indexPath = filmCollection.getIndexPath(for: film){
            // Reload the tableView cell that displays the changed film
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    @objc func handleLoadingProgressChange(notification: NSNotification){
        //print("handleLoadingProgressChange: \(Int(notification.object as! Float * 100)) %")
        guard let homeTabBarController = self.tabBarController as? HomeTabBarController else{
            return
        }
        if let progress = notification.object as? Float{
            let percentage: Int = Int(progress * 100)
            homeTabBarController.showLoadingIndicator(withTitle: "Loading films", message: "\(percentage) %", progress: progress, complete: nil)
        }
    }
    
    @IBAction func unwindToFilmCollectionTableVC(segue: UIStoryboardSegue){
        print("unwindToFilmCollectionTableVC")
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
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.subtype == UIEventSubtype.motionShake{
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
        print("Selected scope: \(scope)")
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
        
        guard let indexPath = tableView.indexPathForRow(at: point) else{
            print("No indexpath for point: \(point)")
            return nil
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else{
            print("no cell")
            return nil
        }
        
        guard let film = filmCollection.getMovie(at: indexPath) else{
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
