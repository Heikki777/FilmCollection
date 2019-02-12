//
//  CalendarEventCreationViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 10/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import UIKit
import EventKit

class CalendarEventCreationViewController: UITableViewController {

    @IBOutlet weak var selectedDateCell: UITableViewCell!
    @IBOutlet weak var alertCell: UITableViewCell!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var selectedAlertTimingOption: CalendarEventAlertOption = .none
    
    lazy var calendarManager: CalendarManager = {
        let cm = CalendarManager(userViewController: self)
        cm.delegate = self
        return cm
    }()
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        return dateFormatter
    }()
    
    var film: Film?
    
    @IBAction func save() {
        guard let film = film else { return }
        calendarManager.insertCalendarEvent(forFilm: film, start: datePicker.date, alertOption: selectedAlertTimingOption)
    }
    
    @IBAction func close() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedDateCell.textLabel?.text = ""
        selectedDateCell.isUserInteractionEnabled = false
        alertCell.textLabel?.text = "Alert"
        alertCell.detailTextLabel?.text = CalendarEventAlertOption.none.rawValue
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(picker:)), for: .valueChanged)
        datePickerValueChanged(picker: datePicker)
    }
    
    @objc func datePickerValueChanged(picker: UIDatePicker){
        selectedDateCell.detailTextLabel?.text = dateFormatter.string(from: picker.date)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.selectAlertOptionSegue.rawValue {
            if let vc = segue.destination as? AlertTimingSelectionTableViewController {
                vc.selectionDelegate = self
                vc.selectedOption = selectedAlertTimingOption
            }
        }
    }
}

extension CalendarEventCreationViewController: AlertTimingSelectionDelegate {
    func didSelect(calendarEventAlertOption: CalendarEventAlertOption) {
        alertCell.detailTextLabel?.text = calendarEventAlertOption.rawValue
        self.selectedAlertTimingOption = calendarEventAlertOption
    }
}

extension CalendarEventCreationViewController: CalendarManagerDelegate {
    func calendarEventAdded() {
        DispatchQueue.main.async {
            print("calendarEventAdded")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let start = self.datePicker.date
            let startDateString = dateFormatter.string(from: start)
            let startTimeString = timeFormatter.string(from: start)
            guard let film = self.film else { return }
            
            let alert = UIAlertController.init(title: "Calendar event added", message: "\"\(film.titleYear)\" is scheduled to be watched on \(startDateString) at \(startTimeString)", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (action) in
                print("OK Pressed")
                self.close()
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        }
    }
}
