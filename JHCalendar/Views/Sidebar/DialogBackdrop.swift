import SwiftUI

struct DialogBackdrop: View {
    var onDismiss: () -> Void
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                onDismiss()
            }
    }
}
