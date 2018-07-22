//
//  NotificationRepetitionTableViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 22/07/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class NotificationRepetitionTableViewController: UITableViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var settings: Settings = {
        return appDelegate.settings
    }()
    
    var selectedRepetitionOption: Settings.RepetitionOption = .Never
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        checkCell(inRow: Int(selectedRepetitionOption.rawValue), section: 0)

    }
    
    func checkCell(inRow row: Int, section: Int, unCheckOthers: Bool = true){
        let rows = tableView.numberOfRows(inSection: section)
        for r in 0..<rows{
            let indexPath = IndexPath(row: r, section: section)
            let cell = tableView.cellForRow(at: indexPath)
            if r == row{
                cell?.accessoryType = .checkmark
            }
            else{
                cell?.accessoryType = .none
            }
        }
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
        return Settings.RepetitionOption.all.count
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        checkCell(inRow: indexPath.row, section: indexPath.section)
        if let repetitionOption = Settings.RepetitionOption(rawValue: Int16(indexPath.row)){
            selectedRepetitionOption = repetitionOption
            settings.notificationRepetitionOption = selectedRepetitionOption
            appDelegate.saveContext()
        }
    }


}
