//
//  CalendarTile.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 11/1/24.
//

import SwiftUI
import EventKit

struct CalendarTile: View, TileProtocol {
    @State private var events: [EKEvent] = []
    @State private var hasCalendarAccess = false
    private let eventStore = EKEventStore()
    
    static func getWidth() -> CGFloat {
        170
    }
    
    static func getMinHeight() -> CGFloat {
        140
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white)
                Text("Upcoming Events")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            if hasCalendarAccess {
                if events.isEmpty {
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(events.prefix(5).enumerated()), id: \.offset) { index, event in
                                EventRow(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                Button("Grant Calendar Access") {
                    requestCalendarAccess()
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(1.0))
        .onAppear {
            checkCalendarAuthorizationStatus()
        }
    }
    
    private func checkCalendarAuthorizationStatus() {
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
    
    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                hasCalendarAccess = granted
                if granted {
                    loadEvents()
                }
            }
        }
    }
    
    private func loadEvents() {
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

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        Button(action: {
            openEventInCalendar(event)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(event.calendar.cgColor))
                        .frame(width: 8, height: 8)
                    
                    Text(event.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Text(formatEventTime(event))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    
                    if let location = event.location, !location.isEmpty {
                        Text("• \(location)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .hover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    private func openEventInCalendar(_ event: EKEvent) {
        // Open the Calendar app using its bundle identifier
        if let calendarURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.openApplication(at: calendarURL, 
                                            configuration: NSWorkspace.OpenConfiguration(),
                                            completionHandler: nil)
        }
    }
    
    private func formatEventTime(_ event: EKEvent) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if calendar.isDateInToday(event.startDate) {
            return "Today, " + formatter.string(from: event.startDate)
        } else if calendar.isDateInTomorrow(event.startDate) {
            return "Tomorrow, " + formatter.string(from: event.startDate)
        } else {
            let days = calendar.dateComponents([.day], from: Date(), to: event.startDate).day ?? 0
            if days < 7 {
                formatter.dateFormat = "EEEE" // Day name (e.g., "Monday")
                return formatter.string(from: event.startDate) + ", " + formatter.string(from: event.startDate)
            } else {
                formatter.dateStyle = .short
                return formatter.string(from: event.startDate)
            }
        }
    }
}

// Add this view modifier for hover effect
extension View {
    func hover(onHover: @escaping (Bool) -> Void) -> some View {
        self.onHover { isHovered in
            onHover(isHovered)
        }
    }
}

#if DEBUG
struct CalendarTile_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with no calendar access
            CalendarTile()
                .frame(width: CalendarTile.getWidth(), height: CalendarTile.getMinHeight())
                .previewDisplayName("No Access")
            
            // Preview with calendar access but no events
            MockCalendarTile(hasAccess: true, events: [])
                .frame(width: CalendarTile.getWidth(), height: CalendarTile.getMinHeight())
                .previewDisplayName("No Events")
            
            // Preview with calendar access and events
            MockCalendarTile(hasAccess: true, events: mockEvents)
                .frame(width: CalendarTile.getWidth(), height: CalendarTile.getMinHeight())
                .previewDisplayName("With Events")
        }
        .background(Color.black)
    }
    
    // Mock events for preview
    static var mockEvents: [EKEvent] {
        let eventStore = EKEventStore()
        let event1 = EKEvent(eventStore: eventStore)
        event1.title = "Team Meeting"
        event1.startDate = Date()
        event1.location = "Conference Room A"
        
        let event2 = EKEvent(eventStore: eventStore)
        event2.title = "Lunch with John"
        event2.startDate = Date().addingTimeInterval(3600 * 2)
        event2.location = "Cafe Downtown"
        
        let event3 = EKEvent(eventStore: eventStore)
        event3.title = "Project Deadline"
        event3.startDate = Date().addingTimeInterval(3600 * 24)
        
        return [event1, event2, event3]
    }
}

// Mock CalendarTile for preview
private struct MockCalendarTile: View {
    let hasAccess: Bool
    let events: [EKEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white)
                Text("Upcoming Events")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            if hasAccess {
                if events.isEmpty {
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                                EventRow(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                Button("Grant Calendar Access") {
                    // No-op for preview
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(1.0))
    }
}
#endif
