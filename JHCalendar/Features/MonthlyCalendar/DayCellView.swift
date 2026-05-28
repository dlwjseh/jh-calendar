import SwiftUI

struct DayCellView: View {
    @State private var isHovered = false
    
    let cell: DayCell
    let events: [Event]
    let multidayLaneCount: Int
    let holiday: Holiday?
    var onSelectDay: (Date) -> Void
    
    private let multidayBarHeight: CGFloat = 16
    private let multidayBarGap: CGFloat = 2
    private let maxVisible = 3
    
    private var isHoliday: Bool { holiday != nil }
    private var holidayLaneCount: Int { isHoliday ? 1 : 0 }
    
    private var singleDayBudget: Int {
        max(0, maxVisible - multidayLaneCount - holidayLaneCount)
    }
    private var visibleSingleDays: [Event] {
        Array(events.prefix(singleDayBudget))
    }
    private var hiddenSingleDayCount: Int {
        max(0, events.count - singleDayBudget)
    }
    
    private var textColor: Color {
        if isToday { return .white }
        if !cell.isInCurrentMonth { return .secondary }
        if isHoliday { return .red }
        switch cell.weekday {
            case 1:  return .red
            case 7:  return .blue
            default: return .primary
        }
    }
    
    private var reservedTop: CGFloat {
        CGFloat(multidayLaneCount) * (multidayBarHeight + multidayBarGap)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(cell.date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("\(cell.day)")
                .font(.system(size: 11))
                .foregroundStyle(textColor)
                .frame(width: 21, height: 21)
                .background {
                    if isToday {
                        Circle().fill(.red)
                    }
                }
                .padding(.bottom, 4)
            
            if let holiday {
                Text(holiday.name)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(red: 255/255, green: 99/255, blue: 71/255))
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer().frame(height: reservedTop)
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(visibleSingleDays) { e in
                    if e.isAllDay {
                        Text(e.name)
                            .font(.system(size: 11))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .foregroundStyle(.white)
                            .background(e.color)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .padding(.horizontal, 7).padding(.vertical, 1)
                            .transition(.opacity)
                    } else {
                        HStack(spacing: 5) {
                            Text(e.startDate, format: .dateTime.hour().minute())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(e.color)
                                .padding(.leading, 3)
                            Text(e.name)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 7).padding(.vertical, 1)
                        .transition(.opacity)
                    }
                }
                
                if hiddenSingleDayCount > 0 {
                    HStack(spacing: 1) {
                        Text("+")
                        Text("\(hiddenSingleDayCount)")
                    }
                    .foregroundStyle(.secondary)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.leading, 11)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 6)
        .background(.primary.opacity(isHovered ? 0.03 : 0))
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
        .onHover { isHovered = $0 }
        .contentShape(Rectangle())
        .pointerStyle(.link)
        .onTapGesture { onSelectDay(cell.date) }
    }
}
