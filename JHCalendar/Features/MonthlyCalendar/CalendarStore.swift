import Foundation

@MainActor
final class CalendarStore: ObservableObject {
    @Published private(set) var rows: [[DayCell]] = []
    @Published private(set) var referenceDate: Date = Date()
    @Published private(set) var gridInterval: DateInterval = .init(start: .distantPast, duration: 0)
    
    init(referenceDate: Date = Date()) {
        rebuild(for: referenceDate)
    }
    
    func prevMonth() {
        let prev = Calendar.current.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        rebuild(for: prev)
    }
    func nextMonth() {
        let next = Calendar.current.date(byAdding: .month, value: 1, to: referenceDate) ?? referenceDate
        rebuild(for: next)
    }
    
    private func rebuild(for date: Date) {
        let grid = makeDayCells(for: date)
        self.referenceDate = date
        self.gridInterval = grid.interval
        self.rows = stride(from: 0, to: grid.cells.count, by: 7).map { start in
            Array(grid.cells[start..<start + 7])
        }
    }
}
