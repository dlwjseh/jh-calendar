import SwiftUI

struct ContentView: View {
    @State private var isSidebarVisible = false
    
    var body: some View {
        HStack(spacing: 0) {
            if isSidebarVisible {
                Sidebar()
                    .transition(.move(edge: .leading))
            }
            ZStack(alignment: .topLeading) {
                Color.clear
                MonthlyCalendarView()
                FloatingToolbar(isSidebarVisible: $isSidebarVisible)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .overlay(alignment: .topLeading) { TrafficLightHoverArea() }
        .ignoresSafeArea()
        
        let _: [DayCell] = makeDayCells(for: Date())
    }
}

#Preview {
    ContentView()
}
