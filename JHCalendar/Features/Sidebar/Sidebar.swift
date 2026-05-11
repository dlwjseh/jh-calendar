import SwiftUI

struct Sidebar: View {
    @State private var folders: [Folder] = Folder.sample
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            ForEach($folders) { $folder in
                VStack(alignment: .leading, spacing: 12) {
                    Text(folder.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach($folder.categories) { $category in
                        CategoryRow(category: $category)
                    }
                }
            }
        }
        .frame(width: 240, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.leading, 15)
        .padding(.top, 30)
        .background(.gray.opacity(0.08))
    }
}
