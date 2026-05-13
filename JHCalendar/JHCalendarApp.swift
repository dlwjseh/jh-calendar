import SwiftUI
import SwiftData

@main
struct JHCalendarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(for: [Folder.self, Category.self, Event.self])
    }
}
