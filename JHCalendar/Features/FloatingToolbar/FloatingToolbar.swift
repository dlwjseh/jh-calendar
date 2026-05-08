import SwiftUI

struct FloatingToolbar: View {
    var body: some View {
        HStack(spacing: 4) {
            Button {
                print("Sidebar 버튼 클릭")
            } label: {
                Image(systemName: "rectangle.leadinghalf.inset.filled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .pointerStyle(.link)
            Button {
                print("Plus 버튼 클릭")
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .pointerStyle(.link)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(.regularMaterial)
        .clipShape(.capsule)
        .shadow(color: .black.opacity(0.1), radius: 7, x: 0, y: 2)
        .padding(.top, 10)
        .padding(.leading, 80)
    }
}
