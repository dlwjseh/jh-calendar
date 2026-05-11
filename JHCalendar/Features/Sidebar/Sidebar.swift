import SwiftUI

struct Sidebar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            ForEach(Folder.sample) { folder in
                VStack(alignment: .leading, spacing: 12) {
                    Text(folder.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(folder.categories) { category in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(category.color)
                                .frame(width: 16, height: 16)
                                .overlay {
                                    if category.isChecked {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            Text(category.name)
                        }
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
