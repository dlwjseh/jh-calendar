import SwiftUI

struct CategoryRow: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var categoryDialog: CategoryDialogMode?
    var category: Category
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.snappy) {
                    category.isChecked.toggle()
                }
            } label: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(category.color)
                    .frame(width: 16, height: 16)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(category.isChecked ? 1 : 0.2)
                    }
            }
            .buttonStyle(.plain)
            Text(category.name)
        }
        .contextMenu {
            Text("카테고리").font(.caption)
            Button("수정") {
                withAnimation(.smooth(duration: 0.3)) {
                    categoryDialog = .edit(category)
                }
            }
            Button("삭제", role: .destructive) {
                modelContext.delete(category)
            }
        }
    }
}

#Preview {
    CategoryRow(categoryDialog: .constant(nil), category: Category(name: "Sample", color: .orange, isChecked: true))
}
