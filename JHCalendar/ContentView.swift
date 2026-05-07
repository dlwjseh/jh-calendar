import SwiftUI
import AppKit

struct ContentView: View {
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(minWidth: 900, minHeight: 600)
            
            Color.clear
                .frame(width: 100, height: 40)
                .onHover { isHovered = $0 }
        }
        .ignoresSafeArea()
        .onAppear {
            setTrafficLightAlpha(0, animated: false)
        }
        .onChange(of: isHovered) { _, hovering in
            setTrafficLightAlpha(hovering ? 1 : 0, animated: true)
        }
    }
    
    private func setTrafficLightAlpha(_ value: CGFloat, animated: Bool) {
        guard let window = NSApplication.shared.windows.first else { return }
        let buttons: [NSButton] = [.closeButton, .miniaturizeButton, .zoomButton]
            .compactMap { window.standardWindowButton($0) }
        
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                buttons.forEach { $0.animator().alphaValue = value }
            }
        } else {
            buttons.forEach { $0.alphaValue = value }
        }
    }
}

#Preview {
    ContentView()
}
