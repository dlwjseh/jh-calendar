import SwiftUI

struct Sidebar: View {
    @State private var folders: [Folder] = Folder.sample
    @State private var isAddMenuPresented: Bool = false
    @Binding var isAddFolderPresented: Bool
    @Binding var isAddCategoryPresented: Bool
    
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
                        isAddFolderPresented: $isAddFolderPresented,
                        isAddCategoryPresented: $isAddCategoryPresented
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 30) {
                ForEach($folders) { $folder in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(folder.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach($folder.categories) { $category in
                            CategoryRow(category: $category)
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
