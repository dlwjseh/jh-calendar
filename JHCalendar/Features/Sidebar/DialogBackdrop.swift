import SwiftUI

struct DialogBackdrop: View {
    @Binding var isPresented: Bool
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                isPresented = false
            }
    }
}
