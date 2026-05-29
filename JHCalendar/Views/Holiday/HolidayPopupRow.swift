import SwiftUI

struct HolidayPopupRow: View {
    @Environment(\.calendarTheme) private var theme
    let holiday: Holiday
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(theme.holiday)
                .frame(width: 9, height: 9)
            Text(holiday.name)
                .foregroundStyle(theme.holiday)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
    }
}
