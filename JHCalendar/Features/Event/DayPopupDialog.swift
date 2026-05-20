import SwiftUI
import SwiftData

struct DayPopupDialog: View {
    @Query private var dayEvents: [Event]
    @State private var isAddEventButtonHoverd = false
    let date: Date
    var onAddEvent: (Date) -> Void
    
    init(date: Date, onAddEvent: @escaping (Date) -> Void) {
        self.date = date
        self.onAddEvent = onAddEvent
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        _dayEvents = Query(
            filter: #Predicate<Event> { event in
                event.startDate >= dayStart && event.startDate < dayEnd
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
                        .overlay(Circle().fill(.white.opacity(isAddEventButtonHoverd ? 0.08 : 0)))
                }
                .buttonStyle(.plain)
                .pointerStyle(.link)
                .onHover { isAddEventButtonHoverd = $0 }
            }
            .padding(.horizontal, 10)
            
            VStack(spacing: 7) {
                if dayEvents.isEmpty {
                    Text("이날의 일정이 없습니다.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                        .padding(.horizontal, 25)
                } else {
                    ForEach(dayEvents) { event in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(event.color)
                                .frame(width: 9, height: 9)
                            Text(event.name)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !event.isAllDay {
                                Text(event.startDate, format: .dateTime.hour().minute())
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 10))
                            }
                        }
                        .padding(.horizontal, 25)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.vertical, 20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 2, y: 8)
        }
        .frame(width: 340)
    }
}
