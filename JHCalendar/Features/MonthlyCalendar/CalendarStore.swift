import Foundation

@MainActor
final class CalendarStore: ObservableObject {
    @Published private(set) var rows: [[DayCell]] = []
    let referenceDate: Date
    
    init(referenceDate: Date = Date()) {
        self.referenceDate = referenceDate
        let cells = makeDayCells(for: referenceDate)
        self.rows = stride(from: 0, to: cells.count, by: 7).map { start in
            Array(cells[start..<start + 7])
        }
    }
}
