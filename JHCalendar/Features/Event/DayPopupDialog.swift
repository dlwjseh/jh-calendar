import SwiftUI
import SwiftData

struct DayPopupDialog: View {
    @Query private var dayEvents: [Event]
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
                event.startDate < dayEnd && event.endDate >= dayStart
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(dayString)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shadow(color: .black.opacity(0.7), radius: 6, x: 2, y: 5)
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
                if dayEvents.isEmpty {
                    Text("이날의 일정이 없습니다.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                        .padding(.horizontal, 25)
                } else {
                    ForEach(dayEvents) { event in
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
            .animation(.smooth(duration: 0.25), value: dayEvents)
        }
        .frame(width: 340)
    }
}
