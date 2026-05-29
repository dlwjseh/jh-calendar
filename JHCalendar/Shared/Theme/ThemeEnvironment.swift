import SwiftUI

private struct CalendarThemeKey: EnvironmentKey {
    static let defaultValue: CalendarTheme = .classic
}

extension EnvironmentValues {
    var calendarTheme: CalendarTheme {
        get { self[CalendarThemeKey.self] }
        set { self[CalendarThemeKey.self] = newValue }
    }
}
