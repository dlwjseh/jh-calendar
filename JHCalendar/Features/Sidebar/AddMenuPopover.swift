import SwiftUI

struct AddMenuPopover: View {
    @Binding var isAddMenuPresented: Bool
    @Binding var isAddFolderPresented: Bool
    @Binding var isAddCategoryPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            menuItem(title: "폴더", systemImage: "folder") {
                isAddMenuPresented = false
                withAnimation(.smooth(duration: 0.3)) {
                    isAddFolderPresented = true
                }
            }
            menuItem(title: "카테고리", systemImage: "tag") {
                isAddMenuPresented = false
                withAnimation(.smooth(duration: 0.3)) {
                    isAddCategoryPresented = true
                }
            }
        }
        .padding(8)
    }
    
    private func menuItem(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        HoverButton {
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12))
                .frame(minWidth: 80, alignment: .leading)
        }
    }
}
