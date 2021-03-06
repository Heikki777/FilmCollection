//
//  AddFilmTableViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 11.2.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

class AddFilmTableViewController: UITableViewController {
    
    let reuseIdentifier = "filmSearchResultCell"
    var searchResults: [FilmSearchResult] = []{
        didSet{
            tableView.reloadData()
        }
    }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let searchController = UISearchController.init(searchResultsController: nil)
    
    lazy var api: TMDBApi = {
        return TMDBApi.shared
    }()
    
    lazy var dateFormatter: DateFormatter = {
        return DateFormatter()
    }()
    
    lazy var jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()
    
    lazy var jsonEncoder: JSONEncoder = {
        return JSONEncoder()
    }()
    
    var lastPage: Int = 1
    var isLoadingPage: Bool = false
    var endOfResults: Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = searchController
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.frame = CGRect(x: 0, y: 0, width: 320, height: 44)
        searchController.searchBar.placeholder = "Search films"
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.searchBar.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func configure(cell: FilmSearchResultTableViewCell, searchResult: FilmSearchResult){
        cell.clear()
        
        // Year
        var year: String?
        if let releaseDate = searchResult.releaseDate{
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: releaseDate){
                dateFormatter.dateFormat = "yyyy"
                year = dateFormatter.string(from: date)
            }
        }
        
        // Title
        if let title = searchResult.title{
            if let year = year{
                cell.titleLabel.text = "\(title) (\(year))"
            }
            else{
                cell.titleLabel.text = "\(title)"
            }
        }
        
        // Original title
        if let originalTitle = searchResult.originalTitle{
            cell.originalTitleLabel.text = originalTitle
        }
        
        // Overview
        if let overview = searchResult.overview{
            cell.overviewLabel.text = overview
        }
        
        // Poster image
        if let posterPath = searchResult.posterPath{
            let imageURL = TMDBApi.getImageURL(size: .w92, imagePath: posterPath)
            cell.setImageURL(url: imageURL)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! FilmSearchResultTableViewCell
        if indexPath.row < searchResults.count{
            let searchResult = searchResults[indexPath.row]
            configure(cell: cell, searchResult: searchResult)
        }
        if indexPath.row == searchResults.count-1 && !isLoadingPage {
            loadNextPage()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectSearchResult(at: indexPath)
        
        let searchResult = searchResults[indexPath.row]
        guard let id = searchResult.id else { return }

        _ = self.api.loadFilm(id, append: ["credits"]) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let film):
                    self?.addFilm(film: film)
                case .failure(_):
                    let message = (searchResult.title != nil) ? "The film: \(searchResult.title!) could not be loaded" : "The film could not be loaded"
                    self?.showAlert(title: "Error", message: message)
                }
            }
        }

    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func addFilm(film: Film){
        let context = appDelegate.persistentContainer.viewContext
        let newFilm = FilmEntity(context: context)
        newFilm.id = Int32(film.id)
        
        if appDelegate.filmEntities.filter({ $0.id == film.id }).isEmpty {
            let title = "Add a new film"
            let message = "Are you sure that you want to add the film: \"\(film.titleYear)\" to your collection?"
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
            let message = "The film: \"\(film.titleYear)\" is already in the collection"
            let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func selectSearchResult(at indexPath: IndexPath){
        guard indexPath.row < searchResults.count else{
            print("Error! Selected search result not found. Index out of bounds")
            return
        }
        
        let searchResult = searchResults[indexPath.row]
        guard let _ = searchResult.id else{
            print("Error! The film does not have an ID")
            return
        }
        
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 138
    }
    
    func loadNextPage(){
        let page = lastPage+1
        isLoadingPage = true
        if let text = searchController.searchBar.text {
            self.api.search(query: text, page: page) { result in
                DispatchQueue.main.async {
                    switch result {
                        
                    case .success(let response):
                        for result in response.results{
                            if !self.searchResults.contains(where: { $0.id == result.id } ){
                                self.searchResults.append(result)
                            }
                        }
                        self.endOfResults = response.results.isEmpty
                        self.lastPage = self.endOfResults ? self.lastPage : page
                        self.isLoadingPage = false
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
 
        }
        else{
            searchResults = []
            lastPage = 1
        }

    }
    
    @objc func reload() {
        lastPage = 1
        isLoadingPage = true
        endOfResults = false
        
        if let text = searchController.searchBar.text {
            self.api.search(query: text, page: 1) { result in
                DispatchQueue.main.async {
                    switch result {
                        
                    case .success(let response):
                        self.searchResults = response.results
                        self.isLoadingPage = false
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
        else{
            searchResults = []
            lastPage = 1
        }
    }
}

extension AddFilmTableViewController: UISearchControllerDelegate{
    
}

extension AddFilmTableViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {

    }
}

extension AddFilmTableViewController: UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // to limit network activity, reload half a second after last key press.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.reload), object: nil)
        self.perform(#selector(self.reload), with: nil, afterDelay: 0.5)
    }

}
