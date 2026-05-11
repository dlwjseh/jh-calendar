import SwiftUI

struct DayCellView: View {
    let cell: DayCell
    
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
