import SwiftUI

enum SlideDirection { case forward, backward }

@MainActor
final class CalendarStore: ObservableObject {
    @Published private(set) var rows: [[DayCell]] = []
    @Published private(set) var referenceDate: Date = Date()
    @Published private(set) var gridInterval: DateInterval = .init(start: .distantPast, duration: 0)
    @Published private(set) var direction: SlideDirection = .forward
    
    init(referenceDate: Date = Date()) {
        rebuild(for: referenceDate)
    }
    
    func prevMonth() {
        direction = .backward
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(.smooth(duration: 0.3)) {
                let prev = Calendar.current.date(byAdding: .month, value: -1, to: self.referenceDate) ?? self.referenceDate
                self.rebuild(for: prev)
            }
        }
    }
    func nextMonth() {
        direction = .forward
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(.smooth(duration: 0.3)) {
                let next = Calendar.current.date(byAdding: .month, value: 1, to: self.referenceDate) ?? self.referenceDate
                self.rebuild(for: next)
            }
        }
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
