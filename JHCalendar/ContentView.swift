import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(minWidth: 900, minHeight: 600)

            TrafficLightHoverArea()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
