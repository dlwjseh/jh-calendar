import SwiftUI

struct WeekRowView: View {
    let row: [DayCell]
    let eventsByDayIndex: [Date: [Event]]
    let weekMultidays: [Event]
    let onSelectDay: (Date) -> Void
    
    private let cal = Calendar.current
    
    private func barFrame(for event: Event, weekStart: Date, rowWidth: CGFloat) -> (x: CGFloat, width: CGFloat) {
        let cellWidth = rowWidth / 7
        let startKey = cal.startOfDay(for: event.startDate)
        let endKey = cal.startOfDay(for: event.endDate)
        let startCol = max(0, cal.dateComponents([.day], from: weekStart, to: startKey).day ?? 0)
        let dayCount = (cal.dateComponents([.day], from: startKey, to: endKey).day ?? 0) + 1
        let endCol = min(7, startCol + dayCount)
        return (x: CGFloat(startCol) * cellWidth, width: CGFloat(endCol - startCol) * cellWidth)
    }
    
    var body: some View {
        GeometryReader { geo in
            let rowWidth = geo.size.width
            let weekStart = cal.startOfDay(for: row.first?.date ?? Date())
            
            HStack(spacing: 0) {
                ForEach(row) { cell in
                    DayCellView(cell: cell,
                                events: eventsByDayIndex[cal.startOfDay(for: cell.date)] ?? [],
                                onSelectDay: onSelectDay)
                }
            }
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    ForEach(weekMultidays) { event in
                        let f = barFrame(for: event, weekStart: weekStart, rowWidth: rowWidth)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(event.color)
                            .frame(width: f.width, height: 16)
                            .offset(x: f.x, y: 24)
                    }
                }
            }
        }
    }
}
