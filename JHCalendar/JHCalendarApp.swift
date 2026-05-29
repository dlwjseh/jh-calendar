import SwiftUI
import SwiftData

@main
struct JHCalendarApp: App {
    @AppStorage("selectedThemeId") private var themeId = "classic"
    @StateObject private var holidayStore = HolidayStore()
    
    var body: some Scene {
        WindowGroup {
            let theme = resolveTheme(themeId)
            ContentView()
                .environmentObject(holidayStore)
                .environment(\.calendarTheme, theme)
                .preferredColorScheme(theme.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(for: [Folder.self, Category.self, Event.self])
    }
}
