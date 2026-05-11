import SwiftUI

struct ContentView: View {
    @State private var isSidebarVisible = false
    
    var body: some View {
        HStack(spacing: 0) {
            Sidebar()
                .frame(width: isSidebarVisible ? 240 : 0, alignment: .leading)
                .clipped()
            ZStack(alignment: .topLeading) {
                Color.clear
                MonthlyCalendarView()
                FloatingToolbar(isSidebarVisible: $isSidebarVisible)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .overlay(alignment: .topLeading) { TrafficLightHoverArea() }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
