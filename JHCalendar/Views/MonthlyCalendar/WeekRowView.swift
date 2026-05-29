import SwiftUI

struct WeekRowView: View {
    let row: [DayCell]
    let eventsByDayIndex: [Date: [Event]]
    let weekMultidays: [Event]
    let holidaysByDay: [Date: Holiday]
    let onSelectDay: (Date) -> Void

    private let cal = Calendar.current

    private func barFrame(for slice: (event: Event, interval: DateInterval),
                          weekStart: Date,
                          weekInterval: DateInterval,
                          rowWidth: CGFloat) -> (x: CGFloat, width: CGFloat) {
        let cellWidth = rowWidth / 7
        let startKey = cal.startOfDay(for: slice.interval.start)
        let endKey: Date
        if slice.interval.end == weekInterval.end {
            endKey = cal.startOfDay(for: cal.date(byAdding: .second, value: -1, to: slice.interval.end) ?? slice.interval.end)
        } else {
            endKey = cal.startOfDay(for: slice.interval.end)
        }
        let startCol = cal.dateComponents([.day], from: weekStart, to: startKey).day ?? 0
        let dayCount = (cal.dateComponents([.day], from: startKey, to: endKey).day ?? 0) + 1
        return (x: CGFloat(startCol) * cellWidth,
                width: CGFloat(dayCount) * cellWidth)
    }

    private func slices(for events: [Event], in week: DateInterval) -> [(event: Event, interval: DateInterval)] {
        events.compactMap { e in
            let raw = DateInterval(start: e.startDate, end: e.endDate)
            guard let inter = raw.intersection(with: week) else { return nil }
            return (e, inter)
        }
    }
    
    private func laneCount(for date: Date, laned: [LanedSlice]) -> Int {
        let dayStart = cal.startOfDay(for: date)
        let nextDayStart = cal.date(byAdding: .day, value: 1, to: dayStart)!
        let lanes = laned.compactMap { l in
            (l.interval.start < nextDayStart && l.interval.end > dayStart) ? l.lane : nil
        }
        return (lanes.max() ?? -1) + 1
    }
    
    private func cornerCaps(for slice: LanedSlice) -> (leading: Bool, trailing: Bool) {
        let isFirst = cal.isDate(slice.interval.start, equalTo: slice.event.startDate, toGranularity: .day)
        let isLast = cal.isDate(slice.interval.end, equalTo: slice.event.endDate, toGranularity: .day)
        return (leading: isFirst, trailing: isLast)
    }

    var body: some View {
        GeometryReader { geo in
            let rowWidth = geo.size.width
            let weekStart = cal.startOfDay(for: row.first?.date ?? Date())
            let weekInterval = cal.dateInterval(of: .weekOfYear, for: row.first!.date)!
            let slices = slices(for: weekMultidays, in: weekInterval)
            let laned = assignLanes(slices)

            HStack(spacing: 0) {
                ForEach(row) { cell in
                    DayCellView(cell: cell,
                                events: eventsByDayIndex[cal.startOfDay(for: cell.date)] ?? [],
                                multidayLaneCount: laneCount(for: cell.date, laned: laned),
                                holiday: holidaysByDay[cell.date],
                                onSelectDay: onSelectDay)
                }
            }
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    ForEach(laned, id: \.event.id) { l in
                        let f = barFrame(for: (l.event, l.interval), weekStart: weekStart, weekInterval: weekInterval, rowWidth: rowWidth)
                        let caps = cornerCaps(for: l)
                        
                        HStack(spacing: 3) {
                            if !l.event.isAllDay {
                                Circle()
                                    .fill(.white)
                                    .padding(.top, 4)
                                    .frame(width: 3)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                            Text(l.event.name)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .frame(width: f.width, height: 16, alignment: .leading)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius:     caps.leading  ? 3 : 0,
                                bottomLeadingRadius:  caps.leading  ? 3 : 0,
                                bottomTrailingRadius: caps.trailing ? 3 : 0,
                                topTrailingRadius:    caps.trailing ? 3 : 0
                            )
                            .fill(l.event.color)
                        )
                        .offset(x: f.x, y: 24 + CGFloat(l.lane) * (16 + 2))
                        .transition(.opacity)
                    }
                }
            }
        }
    }
}
