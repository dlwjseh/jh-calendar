import SwiftUI

struct AddMenuPopover: View {
    @Binding var isAddMenuPresented: Bool
    @Binding var folderDialog: FolderDialogMode?
    @Binding var categoryDialog: CategoryDialogMode?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            menuItem(title: "폴더", systemImage: "folder") {
                isAddMenuPresented = false
                withAnimation(.smooth(duration: 0.3)) {
                    folderDialog = .add
                }
            }
            menuItem(title: "카테고리", systemImage: "tag") {
                isAddMenuPresented = false
                withAnimation(.smooth(duration: 0.3)) {
                    categoryDialog = .add
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
