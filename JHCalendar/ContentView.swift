import SwiftUI
import AppKit

struct ContentView: View {
    var body: some View {
        Color.clear
            .frame(minWidth: 900, minHeight: 600)
            .onAppear {
                if let window = NSApplication.shared.windows.first {
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
