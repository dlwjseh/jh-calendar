import SwiftUI

struct ContentView: View {
    @State private var isSidebarVisible = false
    
    var body: some View {
        HStack(spacing: 0) {
            if isSidebarVisible {
                Sidebar()
            }
            Color.clear
        }
        .frame(minWidth: 900, minHeight: 600)
        .overlay(alignment: .topLeading) { TrafficLightHoverArea() }
        .overlay(alignment: .topLeading) { FloatingToolbar(isSidebarVisible: $isSidebarVisible) }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
