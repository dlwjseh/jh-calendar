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
