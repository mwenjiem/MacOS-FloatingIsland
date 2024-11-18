//
//  CalendarEvents.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 11/18/24.
//
import EventKit

class CalendarViewModel: ObservableObject {
    private let eventStore = EKEventStore()

    @Published var events: [EKEvent] = []
    @Published var hasCalendarAccess = false
    
    init() {
        checkCalendarAuthorizationStatus()
    }
    
    public func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            hasCalendarAccess = true
            loadEvents()
        case .notDetermined:
            requestCalendarAccess()
        default:
            hasCalendarAccess = false
        }
    }
    
    public func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                self.hasCalendarAccess = granted
                if granted {
                    self.loadEvents()
                }
            }
        }
    }
    
    public func loadEvents() {
        let calendars = eventStore.calendars(for: .event)
        
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: calendars
        )
        
        let fetchedEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
        
        DispatchQueue.main.async {
            self.events = fetchedEvents
        }
    }
}
