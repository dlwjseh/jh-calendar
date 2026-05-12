import SwiftUI

struct AddFolderDialog: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("폴더 추가").font(.headline)
            Text("(단계 04 에서 입력 폼 추가 예정)")
                .foregroundStyle(.secondary)
            
            HStack(spacing: 10) {
                Button("취소") {
                    withAnimation(.smooth(duration: 0.3)) {
                        isPresented = false
                    }
                }
                .keyboardShortcut(.cancelAction)
                Button("저장") {
                    withAnimation(.smooth(duration: 0.3)) {
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(.background)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y:8)
    }
}
