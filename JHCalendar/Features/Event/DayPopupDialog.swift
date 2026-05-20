import SwiftUI
import SwiftData

struct DayPopupDialog: View {
    let date: Date
    @Query private var dayEvents: [Event]
    
    init(date: Date) {
        self.date = date
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
        VStack(alignment: .leading, spacing: 20) {
            Text(dayString)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 6, x: 2, y: 4)
            
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
            .frame(width: 340, alignment: .topLeading)
            .padding(.vertical, 20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 2, y: 8)
        }
    }
}
