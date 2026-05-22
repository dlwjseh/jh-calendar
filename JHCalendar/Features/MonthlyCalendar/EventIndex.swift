import Foundation

struct LanedSlice {
    let event: Event
    let interval: DateInterval
    let lane: Int
}

func assignLanes(_ slices: [(event: Event, interval: DateInterval)]) -> [LanedSlice] {
    let sorted = slices.sorted { $0.interval.start < $1.interval.start }
    var laneEnds: [Date] = []           // index = lane, value = 그 lane 의 가장 마지막 end
    var result: [LanedSlice] = []

    for slice in sorted {
        // 1) 빈 lane 찾기: laneEnds[i] <= slice.interval.start 인 가장 작은 i
        let lane: Int
        if let i = laneEnds.firstIndex(where: { $0 <= slice.interval.start }) {
            lane = i
            laneEnds[i] = slice.interval.end           // 이 lane 의 end 갱신
        } else {
            // 빈 lane 없음 → 새 lane 추가
            lane = laneEnds.count
            laneEnds.append(slice.interval.end)
        }
        result.append(LanedSlice(event: slice.event, interval: slice.interval, lane: lane))
    }
    return result
}

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
