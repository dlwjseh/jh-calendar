import Foundation

struct LanedSlice {
    let event: Event
    let interval: DateInterval
    let lane: Int
}

func assignLanes(_ slices: [(event: Event, interval: DateInterval)],
                 calendar cal: Calendar = .current) -> [LanedSlice] {
    let sorted = slices.sorted { $0.interval.start < $1.interval.start }
    var laneEndDays: [Date] = []        // index = lane, value = 그 lane 의 마지막 이벤트가 차지한 마지막 '날' (startOfDay)
    var result: [LanedSlice] = []

    for slice in sorted {
        let sliceStartDay = cal.startOfDay(for: slice.interval.start)
        let sliceEndDay   = cal.startOfDay(for: slice.interval.end)
        // 1) 빈 lane 찾기: lane 의 마지막 '날' 이 새 슬라이스 시작 '날' 보다 strict 이전
        let lane: Int
        if let i = laneEndDays.firstIndex(where: { $0 < sliceStartDay }) {
            lane = i
            laneEndDays[i] = sliceEndDay
        } else {
            // 빈 lane 없음 → 새 lane 추가
            lane = laneEndDays.count
            laneEndDays.append(sliceEndDay)
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
