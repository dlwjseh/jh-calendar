import SwiftUI

struct FloatingToolbar: View {
    var body: some View {
        HStack(spacing: 4) {
            Color.gray.opacity(0.3).frame(width: 25, height: 25)
            Color.gray.opacity(0.3).frame(width: 25, height: 25)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(.white)
        .clipShape(.capsule)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        .padding(.top, 10)
        .padding(.leading, 80)
    }
}
