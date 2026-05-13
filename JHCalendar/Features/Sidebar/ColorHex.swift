import SwiftUI
import AppKit

extension Color {
    func toHex() -> String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB)
        let r: CGFloat = nsColor?.redComponent ?? 0
        let g: CGFloat = nsColor?.greenComponent ?? 0
        let b: CGFloat = nsColor?.blueComponent ?? 0
        return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
    
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        
        guard cleaned.count == 6,
                let n = UInt32(cleaned, radix: 16) else {
            self = .gray
            return
        }
        
        let r = Double((n >> 16) & 0xFF) / 255.0
        let g = Double((n >>  8) & 0xFF) / 255.0
        let b = Double( n        & 0xFF) / 255.0
        
        self = Color(red: r, green: g, blue: b)
    }
}
