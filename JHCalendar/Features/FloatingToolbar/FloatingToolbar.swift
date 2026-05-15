import SwiftUI

struct FloatingToolbar: View {
    @Binding var isSidebarVisible: Bool
    @Binding var eventDialog: EventDialogMode?
    
    var body: some View {
        HStack(spacing: 0) {
            HoverButton {
                withAnimation(.smooth) {
                    isSidebarVisible.toggle()
                }
            } label: {
                Image(systemName: "rectangle.leadinghalf.inset.filled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 15, height: 20)
            }
            HoverButton {
                withAnimation(.smooth(duration: 0.3)) {
                    eventDialog = .add
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(.capsule)
        .shadow(color: .black.opacity(0.1), radius: 7, x: 0, y: 2)
        .padding(.top, 10)
        .padding(.leading, isSidebarVisible ? 12 : 80)
    }
}
