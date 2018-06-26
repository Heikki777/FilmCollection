//
//  SettingsTableViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 24/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import CoreData

class SettingsTableViewController: UITableViewController {

    private let reuseIdentifier = "settingsTableViewCell"
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var context = {
        return appDelegate.persistentContainer.viewContext
    }()
    
    lazy var settings: Settings = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
        
        do{
            if let settingsArray = try context.fetch(request) as? [Settings], let settings = settingsArray.first{
                print("settings array")
                print(settingsArray)
                return settings
            }
        }
        catch let error {
            print(error.localizedDescription)
        }
        
        let settings = Settings(context: context)
        appDelegate.saveContext()
        return settings
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appDelegate.saveContext()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.dictionary.keys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dict = settings.dictionary
        let raw = dict.keys[dict.index(dict.startIndex, offsetBy: section)]
        guard let sectionTitle = Settings.SectionTitle(rawValue: raw) else {
            print("Section title with raw value: \(raw) is not included in Settings.SectionTitle enum")
            return 0
        }

        switch sectionTitle{
        case Settings.SectionTitle.FilmCollectionLayout:
            return FilmCollectionLayoutOption.all.count
        }
            
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dict = settings.dictionary
        let cell = UITableViewCell()
        
        let sectionTitle = dict.keys[dict.index(dict.startIndex, offsetBy: indexPath.section)]
        
        switch(indexPath.section){
        case 0:
            cell.accessoryType = .none
            if let labelText = dict[sectionTitle]?[indexPath.row]{
                cell.textLabel?.text = labelText
                if settings.filmCollectionLayout == labelText{
                    cell.accessoryType = .checkmark
                }
            }
        default:
            break
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let dict = settings.dictionary
        return dict.keys[dict.index(dict.startIndex, offsetBy: section)]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.section){
        case 0:
            settings.filmCollectionLayout = FilmCollectionLayoutOption.all[indexPath.row].rawValue
            appDelegate.saveContext()
            tableView.reloadSections([indexPath.section], with: .automatic)
        default:
            break
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
