import Foundation

enum RecurrenceExpander {
    /// event 가 interval 안에서 발생하는 날짜들 (시작일 0시 기준)
    static func occurrences(of event: Event, in interval: DateInterval) -> [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: event.startDate)
        var result: [Date] = []
        
        // 원래 시작일 이전엔 발생 없음
        switch event.recurrence {
        case .none:
            return interval.contains(start) ? [start] : []
        case .daily:
            var day = max(start, cal.startOfDay(for: interval.start))
            while day <= interval.end {
                result.append(day)
                guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            return result
        case .weekly:
            var day: Date
            if start > cal.startOfDay(for: interval.start) {
                day = start
            } else {
                let week = cal.component(.weekday, from: event.startDate)
                day = cal.startOfDay(for: interval.start)
                while day <= interval.end {
                    if cal.component(.weekday, from: day) == week { break }
                    guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                    day = next
                }
            }
            
            while day <= interval.end {
                result.append(day)
                guard let next = cal.date(byAdding: .day, value: 7, to: day) else { break }
                day = next
            }
            return result
        case .monthly:
            let dom = cal.component(.day, from: event.startDate)
            var comps = DateComponents()
            comps.day = dom
            
            let floor = max(start, cal.startOfDay(for: interval.start))
            let from = cal.date(byAdding: .day, value: -1, to: floor)!
            cal.enumerateDates(startingAfter: from, matching: comps, matchingPolicy: .strict) { date, _, stop in
                guard let date, date <= interval.end else { stop = true; return }
                result.append(cal.startOfDay(for: date))
            }
            return result
        case .yearly:
            let month = cal.component(.month, from: event.startDate)
            let dom   = cal.component(.day,   from: event.startDate)
            var comps = DateComponents()
            comps.month = month
            comps.day   = dom
            
            let floor = max(start, cal.startOfDay(for: interval.start))
            let from = cal.date(byAdding: .day, value: -1, to: floor)!
            cal.enumerateDates(startingAfter: from, matching: comps, matchingPolicy: .strict) { date, _, stop in
                guard let date, date <= interval.end else { stop = true; return }
                result.append(cal.startOfDay(for: date))
            }
            return result
        case .yearlyLunar:
            // TODO 음력반복 구현
            return result
        }
    }

    /// 단일 날짜 판정 (팝업용)
    static func occurs(_ event: Event, on day: Date) -> Bool {
        let d = Calendar.current.startOfDay(for: day)
        return occurrences(of: event, in: DateInterval(start: d, duration: 1)).contains(d)
    }
}
