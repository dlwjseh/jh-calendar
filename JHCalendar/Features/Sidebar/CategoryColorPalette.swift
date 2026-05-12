import SwiftUI

enum CategoryColorPalette {
    static let all: [Color] = [
        Color(hex: 0xFFC369),   // 행1: peach yellow
        Color(hex: 0xFF8B5C),   //      orange
        Color(hex: 0xFF6B6B),   //      red-orange
        Color(hex: 0xFF5C7C),   //      coral

        Color(hex: 0xFF8AA6),   // 행2: pink
        Color(hex: 0xFF4D8D),   //      hot pink
        Color(hex: 0xFFA5D8),   //      light pink
        Color(hex: 0x8B9EE0),   //      periwinkle

        Color(hex: 0x6FB6E0),   // 행3: light blue
        Color(hex: 0x5DD4D4),   //      teal
        Color(hex: 0x3AB89E),   //      green-teal
        Color(hex: 0xA4D858),   //      lime
    ]
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
