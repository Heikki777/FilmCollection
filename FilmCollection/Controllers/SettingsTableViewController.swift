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
    var startDateCellExpanded: Bool = false

    @IBOutlet weak var startDetailLabel: UILabel!
    @IBOutlet weak var repeatDetailLabel: UILabel!
    @IBOutlet weak var notificationsSwitch: UISwitch!
    @IBOutlet weak var notificationStartDatePicker: UIDatePicker!
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        switch sender {
        case notificationStartDatePicker:
            notificationStartDate = sender.date
        default:
            break
        }
    }
    
    @IBAction func switchNotificationsOnOff(_ sender: UISwitch) {
        tableView.beginUpdates()
        tableView.endUpdates()
        settings.notificationsOn = sender.isOn
        if !sender.isOn{
            startDateCellExpanded = false
        }
        appDelegate.saveContext()
    
        NotificationCenter.default.post(name: Notifications.SettingsNotification.notificationsOnChanged.name, object: nil)
    }
    
    lazy var settings = {
        return appDelegate.settings
    }()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.MM.y, hh:mm"
        return formatter
    }()
    
    var notificationStartDate: Date?{
        didSet{
            settings.notificationStartDate = notificationStartDate
            startDetailLabel.text = ""
            if let notificationStartDate = notificationStartDate {
                startDetailLabel.text = dateFormatter.string(from: notificationStartDate)
            }
            appDelegate.saveContext()
            
            NotificationCenter.default.post(name: Notifications.SettingsNotification.notificationStartDateChanged.name, object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.notificationStartDate = settings.notificationStartDate
        notificationsSwitch.isOn = settings.notificationsOn
        
        let filmCollectionLayout = Settings.FilmCollectionLayoutOption(rawValue: settings.filmCollectionLayout) ?? .title
        let filmCollectionLayoutIndex = Settings.FilmCollectionLayoutOption.all.index(of: filmCollectionLayout) ?? 0
        checkCell(inRow: filmCollectionLayoutIndex, section: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        repeatDetailLabel.text = settings.notificationRepetitionOption.description
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appDelegate.saveContext()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.showNotificationRepetitionOptions.rawValue{
            if let vc = segue.destination as? NotificationRepetitionTableViewController{
                if let repetitionOption = Settings.RepetitionOption(rawValue: settings.notificationRepetitionOption.rawValue){
                    vc.selectedRepetitionOption = repetitionOption
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionTitle = Settings.SectionTitle(rawValue: settings.sections[section]) else {
            print("Section title with raw value: \(settings.sections[section]) is not included in Settings.SectionTitle enum")
            return 0
        }

        switch sectionTitle{
        case Settings.SectionTitle.FilmCollectionLayout:
            return FilmCollectionLayoutOption.all.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settings.sections[section]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
            
        case Settings.SectionTitle.FilmCollectionLayout.index:
            checkCell(inRow: indexPath.row, section: indexPath.section)
            let selectedLayoutOption = Settings.FilmCollectionLayoutOption.all[indexPath.row]
            settings.filmCollectionLayout = selectedLayoutOption.rawValue
            appDelegate.saveContext()
            
            // Notify observers about the layout change
            NotificationCenter.default.post(name: Notifications.SettingsNotification.filmCollectionLayoutChanged.name, object: selectedLayoutOption)
        
        default:
            break
        }
    }
    
    func pickNotificationStartTime(){
        print("pickNotificationStartTime")
        startDateCellExpanded = !startDateCellExpanded
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1{
            if !notificationsSwitch.isOn && indexPath.row > 0{
                return 0
            }
            if indexPath.row == 1{
                return startDateCellExpanded ? 250 : 50
            }
        }
        return 50
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
    
}
