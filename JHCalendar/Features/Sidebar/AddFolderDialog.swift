import SwiftUI

struct AddFolderDialog: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var name = ""
    @FocusState private var isNameFocused: Bool
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
    private var isNameEmpty: Bool {
        trimmedName.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 25) {
            HStack(spacing: 5) {
                Image(systemName: "folder")
                Text("폴더 추가")
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("폴더 이름", text: $name)
                .focused($isNameFocused)
                .textFieldStyle(.plain)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(.background, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray.opacity(0.3), lineWidth: 1))
            
            HStack(spacing: 13) {
                HoverButton {
                    withAnimation(.smooth(duration: 0.3)) {
                        isPresented = false
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
                    let folder = Folder(name: trimmedName)
                    modelContext.insert(folder)
                    
                    withAnimation(.smooth(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Text("저장")
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 7)
                }
                .disabled(isNameEmpty)
                .background(Color.accentColor.opacity(isNameEmpty ? 0.4 : 1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 25)
        .frame(width: 290)
        .background(.background)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y:8)
        .onAppear {
            DispatchQueue.main.async {
                isNameFocused = true
            }
        }
    }
}
