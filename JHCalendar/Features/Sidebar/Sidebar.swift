import SwiftUI

struct Sidebar: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isAddMenuPresented: Bool = false
    @Binding var folderDialog: FolderDialogMode?
    @Binding var categoryDialog: CategoryDialogMode?
    var folders: [Folder]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                HoverButton {
                    isAddMenuPresented.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 20, height: 20)
                }
                .popover(
                    isPresented: $isAddMenuPresented,
                    attachmentAnchor: .rect(.bounds),
                    arrowEdge: .trailing
                ) {
                    AddMenuPopover(
                        isAddMenuPresented: $isAddMenuPresented,
                        folderDialog: $folderDialog,
                        categoryDialog: $categoryDialog
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 30) {
                ForEach(folders) { folder in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(folder.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contextMenu {
                                Button("이름 변경") {
                                    folderDialog = .edit(folder)
                                }
                                Button("삭제", role: .destructive) {
                                    modelContext.delete(folder)
                                }
                            }
                        ForEach(folder.categories) { category in
                            CategoryRow(categoryDialog: $categoryDialog, category: category)
                        }
                    }
                    .padding(.leading, 20)
                }
            }
            .padding(.top, 10)
        }
        .frame(width: 240, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(.gray.opacity(0.08))
    }
}
