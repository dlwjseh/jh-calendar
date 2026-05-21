import SwiftUI
import SwiftData

struct MonthlyCalendarView: View {
    @Binding var dayPopup: Date?
    @StateObject private var store = CalendarStore()
    @Query(sort: \Event.startDate) private var allEvents: [Event]
    let calendar: Calendar = Calendar.current
    
    private var events: [Event] {
        let events = allEvents.filter { store.gridInterval.contains($0.startDate) }
        return events.sorted { a,b in
            (a.isAllDay ? 0 : 1, a.startDate) < (b.isAllDay ? 0 : 1, b.startDate)
        }
    }
    private var eventsByDayIndex: [Date: [Event]] {
        eventsByDay(events, calendar: calendar)
    }
    private var multidaysByWeek: [Date: [Event]] {
        var result: [Date: [Event]] = [:]
        for row in store.rows {
            guard let firstCell = row.first,
                  let week = calendar.dateInterval(of: .weekOfYear, for: firstCell.date) else { continue }
            result[week.start] = multidayEvents(in: week, from: events, calendar: calendar)
        }
        return result
    }

    private static let yearMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f
    }()
    
    private func headerColor(at i: Int) -> Color {
        switch i {
            case 0:  return .red
            case 6:  return .blue
            default: return .secondary
        }
    }
    
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 년월 헤더
            Text(Self.yearMonthFormatter.string(from: store.referenceDate))
                .font(.title)
                .padding(.leading, 50)
            
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(weekdayLabels.indices, id: \.self) { i in
                    Text(weekdayLabels[i])
                        .foregroundStyle(headerColor(at: i))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                Divider()
            }
            
            // 일 그리드
            VStack(spacing: 0) {
                ForEach(store.rows, id: \.first?.id) { row in
                    WeekRowView(row: row,
                                eventsByDayIndex: eventsByDayIndex,
                                weekMultidays: multidaysByWeek[calendar.startOfDay(for: row.first!.date)] ?? []) { date in
                        withAnimation(.smooth(duration: 0.3)) {
                            dayPopup = date
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .padding(.top, 70)
    }
}

#Preview {
    MonthlyCalendarView(dayPopup: .constant(Date()))
}
