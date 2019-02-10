//
//  CalendarManager.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 10/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import Foundation
import EventKit
import UIKit

class CalendarManager {
    
    let calendarIdentifier: String = "FilmCollectionCalendar"
    let calendarTitle: String = "FilmCollection"
    let eventStore: EKEventStore = EKEventStore()
    
    let userViewController: UIViewController

    lazy var calendar: EKCalendar = {
        let calendars = eventStore.calendars(for: .event)
        var filmCollectionCalendar = eventStore.calendar(withIdentifier: calendarIdentifier)
            ?? calendars.filter { $0.title == calendarTitle }.first
            ?? EKCalendar.init(for: .event, eventStore: eventStore)
        
        filmCollectionCalendar.title = calendarTitle
        
        let sourcesInEventStore = eventStore.sources
        var source = sourcesInEventStore.filter { (source: EKSource) -> Bool in
            source.sourceType == EKSourceType.local
            }.first ?? sourcesInEventStore.filter { $0.sourceType == EKSourceType.calDAV }.first
        
        filmCollectionCalendar.source = source
        
        do {
            try eventStore.saveCalendar(filmCollectionCalendar, commit: true)
            UserDefaults.standard.set(filmCollectionCalendar.calendarIdentifier, forKey: calendarIdentifier)
        }
        catch let error {
            print(error.localizedDescription)
            print("Calendar could not be saved")
        }
        return filmCollectionCalendar
    }()
    
    init(userViewController: UIViewController){
        self.userViewController = userViewController
    }
    
    func insertCalendarEvent(forFilm film: Film, start: Date, setAlert: Bool = false){
        guard let runtime = film.runtime else { return }
        
        eventStore.requestAccess(to: .event) { [weak self] (granted, error) in
            
            guard let strongSelf = self else { return }
            
            if let error = error {
                print(error.localizedDescription)
            }
            
            if granted {
                let end = start.addingTimeInterval(TimeInterval(runtime * 60))
                let newEvent = EKEvent(eventStore: strongSelf.eventStore)
                newEvent.calendar = self?.calendar
                newEvent.title = "Watch film: \(film.titleYear)"
                newEvent.notes = film.overview ?? ""
                newEvent.startDate = start
                newEvent.endDate = end
                
                if setAlert {
                    let alarm = EKAlarm(absoluteDate: start)
                    newEvent.addAlarm(alarm)
                }
                
                let predicate = strongSelf.eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
                var filmEvents: [EKEvent]? = nil
                filmEvents = strongSelf.eventStore.events(matching: predicate)
                
                let dateFormatter: DateFormatter = {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
                    return dateFormatter
                }()
                
                let showSuccessAlert = {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy"
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    let startDateString = dateFormatter.string(from: start)
                    let startTimeString = timeFormatter.string(from: start)
                    DispatchQueue.main.async {
                        strongSelf.userViewController.showAlert(title: "Calendar event added", message: "\"\(film.titleYear)\" is scheduled to be watched on \(startDateString) at \(startTimeString)")
                    }
                }
                
                guard let overlappingEvents = filmEvents, !overlappingEvents.isEmpty else {
                    // No overlapping events. Just add the new event
                    do {
                        try strongSelf.eventStore.save(newEvent, span: .thisEvent)
                        showSuccessAlert()
                    }
                    catch let error {
                        print("Saving the calendar event failed")
                        print(error.localizedDescription)
                    }
                    return
                }
                
                if let overlappingFilmEvent = overlappingEvents.first {
                    let startDateString = dateFormatter.string(from: overlappingFilmEvent.startDate)
                    let endDateString = dateFormatter.string(from: overlappingFilmEvent.endDate)
                    let existingEventTitle = overlappingFilmEvent.title ?? "Unknown"
                    let alertTitle = "Events overlap"
                    let message = "The film \(existingEventTitle) is scheduled from \(startDateString) to \(endDateString)"
                    let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
                    let replaceAction = UIAlertAction(title: "Replace", style: .destructive, handler: { (action) in
                        do {
                            try strongSelf.eventStore.remove(overlappingFilmEvent, span: .thisEvent)
                            try strongSelf.eventStore.save(newEvent, span: .thisEvent)
                            showSuccessAlert()
                        }
                        catch let error {
                            print(error.localizedDescription)
                        }
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alert.addAction(replaceAction)
                    alert.addAction(cancelAction)
                    
                    DispatchQueue.main.async {
                        strongSelf.userViewController.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
