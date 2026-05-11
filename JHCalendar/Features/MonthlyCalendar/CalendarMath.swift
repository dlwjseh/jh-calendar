import Foundation


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
    
    let leadingDays: Int = cal.component(.weekday, from: firstOfMonth) - 1
    
    let daysInMonth: Int = cal.range(of: .day, in: .month, for: firstOfMonth)!.count
    
    let lastOfMonth: Date = cal.date(byAdding: .day, value: daysInMonth-1, to: firstOfMonth)!
    
    let trailingDays: Int = 7 - cal.component(.weekday, from: lastOfMonth)
    
    let gridStart: Date = cal.date(byAdding: .day, value: -leadingDays, to: firstOfMonth)!
    
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
