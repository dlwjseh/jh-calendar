import SwiftUI

struct CalendarTheme {
    let sunday: Color
    let saturday: Color
    let weekdayText: Color
    let subtleText: Color
    let todayFill: Color
    let todayText: Color
    let holiday: Color
    let gridLine: Color
    let accent: Color
    let colorScheme: ColorScheme?   // .light/.dark 명시 (런타임 토글 시 nil↔비nil은 macOS desync 버그 → 명시값만 사용)
}

extension CalendarTheme {
    static let classic = CalendarTheme(
        sunday: .red,
        saturday: .blue,
        weekdayText: .primary,
        subtleText: .secondary,
        todayFill: .red,
        todayText: .white,
        holiday: Color(red: 255/255, green: 99/255, blue: 71/255),
        gridLine: .gray.opacity(0.2),
        accent: Color(red: 65/255, green: 105/255, blue: 225/255),
        colorScheme: .light
    )

    static let dark = CalendarTheme(
        sunday: Color(red: 1.0, green: 0.5, blue: 0.5),
        saturday: Color(red: 0.5, green: 0.72, blue: 1.0),
        weekdayText: .primary,
        subtleText: .secondary,
        todayFill: Color(red: 0.9, green: 0.35, blue: 0.35),
        todayText: .white,
        holiday: Color(red: 1.0, green: 0.55, blue: 0.45),
        gridLine: .white.opacity(0.14),
        accent: Color(red: 0.5, green: 0.65, blue: 1.0),
        colorScheme: .dark
    )
}

func resolveTheme(_ id: String) -> CalendarTheme {
    switch id {
    case "dark": return .dark
    default:     return .classic
    }
}
