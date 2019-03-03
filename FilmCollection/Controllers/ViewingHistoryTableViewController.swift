//
//  ViewingHistoryTableViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 01/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import CoreData

class ViewingHistoryTableViewController: UITableViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let reuseIdentifier = "viewingCell"
    let api = TMDBApi.shared
    var viewings: [Viewing] = []
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.viewings = appDelegate.viewingEntities
        self.viewings.sort { $0.date! > $1.date! }
        self.tableView.reloadData()
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
        cell.isUserInteractionEnabled = false
        if let title = viewings[indexPath.row].title {
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = dateFormatter.string(from: viewings[indexPath.row].date!)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let selectedViewingToBeRemoved = viewings[indexPath.row]
            
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Viewing")
            
            do {
                if let viewingEntities = try context.fetch(request) as? [Viewing] {
                    for object in viewingEntities {
                        if object.objectID == selectedViewingToBeRemoved.objectID {
                            context.delete(object)
                            appDelegate.saveContext()
                            break
                        }
                    }
                }
            }
            catch let error {
                print(error.localizedDescription)
            }
            
            appDelegate.saveContext()

            tableView.beginUpdates()
            viewings.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }

}
