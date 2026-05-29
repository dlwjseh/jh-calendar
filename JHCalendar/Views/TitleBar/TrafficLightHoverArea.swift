import SwiftUI

struct TrafficLightHoverArea: View {
    @State private var isHovered = false

    var body: some View {
        Color.clear
            .frame(width: 100, height: 40)
            .onHover { isHovered = $0 }
            .onAppear {
                TrafficLightController.setAlpha(0, animated: false)
            }
            .onChange(of: isHovered) { _, hovering in
                TrafficLightController.setAlpha(hovering ? 1 : 0, animated: true)
            }
    }
}
