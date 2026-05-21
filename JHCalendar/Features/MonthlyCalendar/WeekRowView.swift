import SwiftUI

struct WeekRowView: View {
    let row: [DayCell]
    let eventsByDayIndex: [Date: [Event]]
    let weekMultidays: [Event]
    let onSelectDay: (Date) -> Void
    
    private let cal = Calendar.current
    
    var body: some View {
        GeometryReader { geo in
            let rowWidth = geo.size.width
            
            HStack(spacing: 0) {
                ForEach(row) { cell in
                    DayCellView(cell: cell,
                                events: eventsByDayIndex[cal.startOfDay(for: cell.date)] ?? [],
                                onSelectDay: onSelectDay)
                }
            }
        }
    }
}
