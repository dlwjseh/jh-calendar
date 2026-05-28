import SwiftUI

struct HolidayPopupRow: View {
    let holiday: Holiday
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.holiday)
                .frame(width: 9, height: 9)
            Text(holiday.name)
                .foregroundStyle(Color.holiday)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
    }
}
