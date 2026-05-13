import SwiftUI

struct CategoryRow: View {
    var category: Category
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.snappy) {
                    category.isChecked.toggle()
                }
            } label: {
                RoundedRectangle(cornerRadius: 4)
//                    .fill(category.color)
                    .frame(width: 16, height: 16)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(category.isChecked ? 1 : 0.2)
                    }
            }
            .buttonStyle(.plain)
            Text(category.name)
        }
    }
}

//#Preview {
//    CategoryRow(category: Category(name: "Sample", color: .orange, isChecked: true))
//}
