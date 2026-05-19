import SwiftUI

struct DayCellView: View {
    @State private var isHovered = false
    
    let cell: DayCell
    let events: [Event]
    
    private let maxVisible = 3
    
    private var textColor: Color {
        if !cell.isInCurrentMonth { return .secondary }
        switch cell.weekday {
            case 1:  return .red
            case 7:  return .blue
            default: return .primary
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("\(cell.day)")
                .font(.system(size: 12))
                .foregroundStyle(textColor)
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(events.prefix(maxVisible)) { e in
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
                    }
                }
                
                if events.count > maxVisible {
                    HStack(spacing: 1) {
                        Text("+")
                        Text("\(events.count - maxVisible)")
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
    }
}
