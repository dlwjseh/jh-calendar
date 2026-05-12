import SwiftUI

struct Sidebar: View {
    @State private var folders: [Folder] = Folder.sample
    @State private var isAddMenuPresented: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                HoverButton {
                    isAddMenuPresented.toggle()
                    print("+ 클릭, isAddMenuPresented = \(isAddMenuPresented)")
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 20, height: 20)
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
