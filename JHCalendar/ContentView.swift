import SwiftUI

struct ContentView: View {
    @State private var isSidebarVisible = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(minWidth: 900, minHeight: 600)

            TrafficLightHoverArea()

            FloatingToolbar(isSidebarVisible: $isSidebarVisible)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
