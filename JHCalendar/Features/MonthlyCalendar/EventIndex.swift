import Foundation

func eventsByDay(_ events: [Event], calendar: Calendar = .current) -> [Date: [Event]] {
    var result: [Date: [Event]] = [:]
    for event in events {
        let startKey = calendar.startOfDay(for: event.startDate)
        let endKey = calendar.startOfDay(for: event.endDate)
        var day = startKey
        while day <= endKey {
            result[day, default: []].append(event)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = next
        }
    }
    return result
}

func isMultiday(_ event: Event, calendar cal: Calendar = .current) -> Bool {
    cal.startOfDay(for: event.startDate) != cal.startOfDay(for: event.endDate)
}

func multidayEvents(in weekInterval: DateInterval,
                    from events: [Event],
                    calendar cal: Calendar = .current) -> [Event] {
    events.filter { isMultiday($0, calendar: cal) }
        .filter { event in
            let eventInterval = DateInterval(start: event.startDate, end: event.endDate)
            return weekInterval.intersects(eventInterval)
        }
}
