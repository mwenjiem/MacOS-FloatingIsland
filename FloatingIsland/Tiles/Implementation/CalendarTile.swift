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
        200
    }
    
    static func getMinHeight() -> CGFloat {
        160
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
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(events.prefix(5), id: \.eventIdentifier) { event in
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
        .padding(.vertical)
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
                Text(event.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(formatEventTime(event))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let location = event.location, !location.isEmpty {
                        Text("• \(location)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle()) // Makes entire row clickable
        .hover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    private func openEventInCalendar(_ event: EKEvent) {
        // Open the Calendar app
        if let url = URL(string: "x-apple-calendar://") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func formatEventTime(_ event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: event.startDate)
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
