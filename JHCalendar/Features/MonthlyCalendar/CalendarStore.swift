import Foundation

@MainActor
final class CalendarStore: ObservableObject {
    @Published private(set) var rows: [[DayCell]] = []
    let referenceDate: Date
    let gridInterval: DateInterval
    
    init(referenceDate: Date = Date()) {
        self.referenceDate = referenceDate
        let grid = makeDayCells(for: referenceDate)
        self.gridInterval = grid.interval
        self.rows = stride(from: 0, to: grid.cells.count, by: 7).map { start in
            Array(grid.cells[start..<start + 7])
        }
    }
}
