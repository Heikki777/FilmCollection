//
//  AlertTimingSelectionTableViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 11/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import UIKit

protocol AlertTimingSelectionDelegate {
    func didSelect(calendarEventAlertOption: CalendarEventAlertOption)
}

class AlertTimingSelectionTableViewController: UITableViewController {

    var selectionDelegate: AlertTimingSelectionDelegate?
    var selectedOption: CalendarEventAlertOption = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let selectionIndexPath = selectedOption.indexPath {
            tableView.selectRow(at: selectionIndexPath, animated: true, scrollPosition: .top)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.visibleCells.filter { $0.accessoryType != .none }.forEach { $0.accessoryType = .none }

        if let option = CalendarEventAlertOption(withIndexPath: indexPath){
            selectionDelegate?.didSelect(calendarEventAlertOption: option)
        }
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        
    }
}

enum CalendarEventAlertOption: String {
    case none = "None"
    case timeOfEvent = "At time of event"
    case minutes5 = "5 minutes"
    case minutes15 = "15 minutes"
    case minutes30 = "30 minutes"
    case hours1 = "1 hour"
    case hours2 = "2 hours"
    
    static let all: [Int: [CalendarEventAlertOption]] = [
        0: [.none],
        1: [.timeOfEvent, .minutes5, .minutes15, .minutes30, .hours1, .hours2]
    ]
    
    init?(withIndexPath indexPath: IndexPath) {
        if let option = CalendarEventAlertOption.all[indexPath.section]?[indexPath.row] {
            self = option
        }
        else {
            return nil
        }
    }
    
    var indexPath: IndexPath? {
        for (section, options) in CalendarEventAlertOption.all {
            if let row = options.firstIndex(of: self){
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }
    
    var interval: TimeInterval {
        switch self {
        case .none:
            return 0
        case .timeOfEvent:
            return 0
        case .minutes5:
            return 60 * 5
        case .minutes15:
            return 60 * 15
        case .minutes30:
            return 60 * 30
        case .hours1:
            return 60 * 60
        case .hours2:
            return 60 * 120
        }
    }
    
}
