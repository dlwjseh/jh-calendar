import SwiftUI

struct DayCellView: View {
    let cell: DayCell
    
    var body: some View {
        VStack(spacing: 0) {
            Text("\(cell.day)")
                .font(.caption)
                .foregroundStyle(cell.isInCurrentMonth ? .primary : .tertiary)
            
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
