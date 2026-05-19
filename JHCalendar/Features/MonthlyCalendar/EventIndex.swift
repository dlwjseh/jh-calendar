import Foundation

func eventsByDay(_ events: [Event], calendar: Calendar = .current) -> [Date: [Event]] {
    Dictionary(grouping: events) { calendar.startOfDay(for: $0.startDate) }
}
