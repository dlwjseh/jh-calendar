import SwiftUI

struct DayCellView: View {
    let cell: DayCell
    let events: [Event]
    
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
            
            VStack(spacing: 2) {
                ForEach(events) { e in
                    if e.isAllDay {
                        VStack {
                            Text(e.name)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .foregroundStyle(.white)
                                .background(e.color)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .padding(.horizontal, 7).padding(.vertical, 1)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 6)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}
