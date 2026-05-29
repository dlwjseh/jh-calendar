import AppKit

enum TrafficLightController {
    static func setAlpha(_ value: CGFloat, animated: Bool) {
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
