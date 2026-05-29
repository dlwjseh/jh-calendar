import SwiftUI
import SwiftData

struct DayPopupDialog: View {
    @Query private var dayEvents: [Event]
    @EnvironmentObject private var holidayStore: HolidayStore
    @State private var isAddEventButtonHovered = false
    let date: Date
    var onAddEvent: (Date) -> Void
    var onSelectEvent: (Event) -> Void
    
    init(date: Date, onAddEvent: @escaping (Date) -> Void, onSelectEvent: @escaping (Event) -> Void) {
        self.date = date
        self.onAddEvent = onAddEvent
        self.onSelectEvent = onSelectEvent
        
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        _dayEvents = Query(
            filter: #Predicate<Event> { event in
                event.startDate <= dayEnd
            },
            sort: \Event.startDate
        )
    }
    
    private var dayString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: date)
    }
    private var lunarString: String {
        LunarDate.shortLabel(from: date)
    }
    private var holiday: Holiday? {
        holidayStore.byDay[Calendar.current.startOfDay(for: date)]
    }
    private var visibleEvents: [Event] {
        let cal = Calendar.current
        return dayEvents.filter { event in
            let checkedCategory = event.category?.isChecked ?? true
            if event.recurrence == .none {
                let dayStart = cal.startOfDay(for: date)
                let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
                return event.startDate < dayEnd && event.endDate >= dayStart && checkedCategory
            } else {
                return RecurrenceExpander.occurs(event, on: date) && checkedCategory
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(dayString)
                        .font(.system(size: 17, weight: .bold))
                    Text(lunarString)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.bottom, 2)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 6, x: 2, y: 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    onAddEvent(date)
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(red: 37/255, green: 99/255, blue: 235/255)))
                        .overlay(Circle().fill(.white.opacity(isAddEventButtonHovered ? 0.08 : 0)))
                }
                .buttonStyle(.plain)
                .pointerStyle(.link)
                .onHover { isAddEventButtonHovered = $0 }
            }
            .padding(.horizontal, 10)
            
            VStack(spacing: 0) {
                if visibleEvents.isEmpty && holiday == nil {
                    Text("이날의 일정이 없습니다.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                        .padding(.horizontal, 25)
                } else {
                    if let holiday {
                        HolidayPopupRow(holiday: holiday)
                    }
                    ForEach(visibleEvents) { event in
                        DayPopupEventRow(event: event, date: date, onClick: onSelectEvent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.vertical, 15)
            .padding(.horizontal, 10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 2, y: 8)
            .animation(.smooth(duration: 0.25), value: visibleEvents)
        }
        .frame(width: 340)
    }
}
