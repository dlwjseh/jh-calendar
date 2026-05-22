import SwiftUI

struct DayPopupEventRow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false
    let event: Event
    let date: Date
    var onClick: (Event) -> Void
    
    private var showsTime: Bool {
        !event.isAllDay && Calendar.current.isDate(event.startDate, inSameDayAs: date)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(event.color)
                .frame(width: 9, height: 9)
            Text(event.name)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if showsTime {
                Text(event.startDate, format: .dateTime.hour().minute())
                    .foregroundStyle(.secondary)
                    .font(.system(size: 10))
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(.primary.opacity(isHovered ? 0.07 : 0))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .pointerStyle(.link)
        .contextMenu {
            Button("삭제", role: .destructive) {
                modelContext.delete(event)
            }
        }
        .onHover{ isHovered = $0 }
        .onTapGesture { onClick(event) }
    }
}
