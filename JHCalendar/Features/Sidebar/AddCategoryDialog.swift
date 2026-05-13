import SwiftUI

enum CategoryDialogMode {
    case add
    case edit(Category)
}

struct AddCategoryDialog: View {
    @State private var selectedFolder: Folder? = nil
    @State private var name = ""
    @State private var selectedColor: Color = CategoryColorPalette.all.first ?? .blue
    let mode: CategoryDialogMode
    let folders: [Folder]
    var onDismiss: () -> Void
    
    let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
    private var isSaveEnabled: Bool {
        selectedFolder != nil && !trimmedName.isEmpty
    }
    
    init(mode: CategoryDialogMode, folders: [Folder], onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.folders = folders
        self.onDismiss = onDismiss
        if case .edit(let category) = mode {
            _selectedFolder = State(initialValue: category.folder)
            _name = State(initialValue: category.name)
            _selectedColor = State(initialValue: category.color)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack(spacing: 5) {
                Image(systemName: "tag")
                Text("카테고리 추가")
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 19) {
                HStack(spacing: 0) {
                    Text("폴더")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    Menu {
                        ForEach(folders) { folder in
                            Button(folder.name) { selectedFolder = folder }
                        }
                    } label: {
                        HStack {
                            Text(selectedFolder?.name ?? "폴더 선택")
                                .foregroundStyle(selectedFolder == nil ? .secondary : .primary)
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray.opacity(0.3), lineWidth: 1))
                }
                
                HStack(spacing: 0) {
                    Text("이름")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    TextField("카테고리 이름", text: $name)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray.opacity(0.3), lineWidth: 1))
                }
                
                HStack(alignment: .top, spacing: 0) {
                    Text("색상")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(CategoryColorPalette.all, id:\.self) { color in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.primary, lineWidth: selectedColor == color ? 2 : 0)
                                        .padding(-3)                  // 외곽으로 살짝 띄우기
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                }
            }
            
            HStack(spacing: 13) {
                HoverButton {
                    withAnimation(.smooth(duration: 0.3)) {
                        onDismiss()
                    }
                } label: {
                    Text("취소")
                        .foregroundStyle(.primary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 7)
                }
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .keyboardShortcut(.cancelAction)
                HoverButton {
                    switch mode {
                    case .add:
                        let category = Category(name: trimmedName, color: selectedColor, isChecked: true)
                        selectedFolder?.categories.append(category)
                    case .edit(let category):
                        category.name = trimmedName
                        category.folder = selectedFolder
                        category.color = selectedColor
                    }
                    withAnimation(.smooth(duration: 0.3)) {
                        onDismiss()
                    }
                } label: {
                    Text("저장")
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 7)
                }
                .disabled(!isSaveEnabled)
                .background(Color.accentColor.opacity(isSaveEnabled ? 1 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 25)
        .frame(width: 320)
        .background(.background)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y:8)
    }
}
