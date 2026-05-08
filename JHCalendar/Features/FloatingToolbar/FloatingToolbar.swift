import SwiftUI

struct FloatingToolbar: View {
    var body: some View {
        HStack(spacing: 0) {
            HoverButton {
                print("Sidebar 버튼 클릭")
            } label: {
                Image(systemName: "rectangle.leadinghalf.inset.filled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 15, height: 20)
            }
            HoverButton {
                print("Plus 버튼 클릭")
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
        .padding(.leading, 80)
    }
}
