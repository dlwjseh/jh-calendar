import SwiftUI


struct DayCell: Identifiable {
    let id = UUID()
    let date: Date
    let day: Int
    let weekday: Int
    let isInCurrentMonth: Bool
}

func makeDayCells(for referenceDate: Date) -> [DayCell] {
    let cal = Calendar.current
    
    let firstOfMonth: Date = cal.dateInterval(of: .month, for: referenceDate)!.start
    print("이번달 첫날: ", firstOfMonth.formatted(date: .complete, time: .shortened))
    
    let leadingDays: Int = cal.component(.weekday, from: firstOfMonth) - 1
    print("앞쪽에 채울 이전 달 일 수: ", leadingDays)
    
    let daysInMonth: Int = cal.range(of: .day, in: .month, for: firstOfMonth)!.count
    print("이번달 일 수: ", daysInMonth)
    
    let lastOfMonth: Date = cal.date(byAdding: .day, value: daysInMonth-1, to: firstOfMonth)!
    print("이번달 마지막날: ", lastOfMonth.formatted(date: .complete, time: .shortened))
    
    let trailingDays: Int = 7 - cal.component(.weekday, from: lastOfMonth)
    print("뒤쪽에 채울 다음 달 일 수: ", trailingDays)
    
    let gridStart: Date = cal.date(byAdding: .day, value: -leadingDays, to: firstOfMonth)!
    print("시작 날짜: ", gridStart.formatted(date: .complete, time: .shortened))
    
    let total = leadingDays + daysInMonth + trailingDays
    var cells: [DayCell] = []
    for offset in 0..<total {
        let date = cal.date(byAdding: .day, value: offset, to: gridStart)!
        let day = cal.component(.day, from: date)
        let weekday = cal.component(.weekday, from: date)
        let inThisMonth = cal.isDate(date, equalTo: firstOfMonth, toGranularity: .month)
        cells.append(DayCell(date: date, day: day, weekday: weekday, isInCurrentMonth: inThisMonth))
    }
    return cells
}
