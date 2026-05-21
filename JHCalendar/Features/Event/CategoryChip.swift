import SwiftUI

struct CategoryChip: View {
    @Binding var selectedCategory: Category?
    @State private var isHovered = false
    let category: Category
    
    private var borderColor: Color {
        selectedCategory == category ? category.color : .gray.opacity(0.3)
    }
    private var backgroundColor: Color {
        if selectedCategory == category {
            return category.color.opacity(isHovered ? 0.25 : 0.15)
        } else {
            return isHovered
                ? category.color.opacity(0.1)
                : Color(.windowBackgroundColor)
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().frame(width: 8, height: 8)
                .foregroundStyle(category.color)
            Text(category.name)
                .font(.system(size: 10))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Capsule().fill(backgroundColor))
        .overlay(Capsule().strokeBorder(borderColor, lineWidth: 1))
        .contentShape(Capsule())
        .onHover { isHovered = $0 }
        .pointerStyle(.link)
        .onTapGesture { selectedCategory = category }
    }
}
