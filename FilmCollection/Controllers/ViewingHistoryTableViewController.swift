//
//  ViewingHistoryTableViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 01/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import PromiseKit
import Firebase



class ViewingHistoryTableViewController: UITableViewController {

    let reuseIdentifier = "viewingCell"
    let api = TMDBApi.shared
    var viewings: [Viewing] = []
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm"
        return formatter
    }()
    
    // Firebase
    lazy var databaseRef: DatabaseReference = {
        return Database.database().reference()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = Auth.auth().currentUser else{
            print("User")
            return
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        
        databaseRef.child("user-viewing-history").child(user.uid).child("watched").observe(.childAdded) { (snapshot) in
            if let dict = snapshot.value as? [String: AnyObject]{
                if let dateString = dict["date"] as? String,
                    let movieTitle = dict["movieTitle"] as? String,
                    let movieId = dict["movieId"] as? Int,
                    let date = self.dateFormatter.date(from: dateString){
                    self.viewings.append(Viewing(date: date, title: movieTitle, id: movieId))
                }
                self.viewings.sort { $0.date > $1.date }
            }
        }
        
        databaseRef.child("user-viewing-history").child(user.uid).child("watched").observe(.value) { (snapshot) in
            self.tableView.reloadData()
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        return viewings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = viewings[indexPath.row].title
        cell.detailTextLabel?.text = dateFormatter.string(from: viewings[indexPath.row].date)

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            print("Delete viewing")
            tableView.beginUpdates()
            viewings.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }

}
