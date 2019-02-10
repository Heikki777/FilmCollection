//
//  CalendarEventCreationViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 10/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import UIKit
import EventKit

class CalendarEventCreationViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var alertSwitch: UISwitch!
    
    lazy var calendarManager: CalendarManager = {
        return CalendarManager(userViewController: self)
    }()
    
    var film: Film?
    
    @IBAction func save() {
        guard let film = film else { return }
        calendarManager.insertCalendarEvent(forFilm: film, start: datePicker.date, setAlert: alertSwitch.isOn)
    }
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let film = film else { return }
        headerLabel?.text = "Schedule watching \"\(film.titleYear)\""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
