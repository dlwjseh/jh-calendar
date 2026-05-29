import SwiftUI

struct HoverButton<Label: View>: View {
    var hoverfill: Color = .primary.opacity(0.08)
    var cornerRadius: CGFloat = 6
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    
    @State private var isHovered = false
    
    var body: some View {
        Button (action: action) {
            label()
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(isHovered ? hoverfill : .clear)
                .clipShape(.rect(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .onHover { isHovered = $0 }
    }
}
