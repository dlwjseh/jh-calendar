import SwiftUI
import SwiftData

@main
struct JHCalendarApp: App {
    @StateObject private var holidayStore = HolidayStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(holidayStore)
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(for: [Folder.self, Category.self, Event.self])
    }
}
