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
                .onHover { hovering in
                    isHovered = hovering
                    print("hover: ", hovering)
                }
        }
        .ignoresSafeArea()
        .onAppear {
            if let window = NSApplication.shared.windows.first {
                window.styleMask.insert(.fullSizeContentView)
                
                let buttonTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
                for buttonType in buttonTypes {
                    window.standardWindowButton(buttonType)?.alphaValue = 0
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
