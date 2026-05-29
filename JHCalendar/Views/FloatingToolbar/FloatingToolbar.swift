import SwiftUI

struct FloatingToolbar: View {
    @EnvironmentObject private var store: CalendarStore
    @Binding var isSidebarVisible: Bool
    @Binding var eventDialog: EventDialogMode?
    
    var body: some View {
        HStack(spacing: 0) {
            HoverButton {
                withAnimation(.smooth) {
                    isSidebarVisible.toggle()
                }
            } label: {
                Image(systemName: "rectangle.leadinghalf.inset.filled")
                    .help("사이드바 open/close")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 15, height: 20)
            }
            HoverButton {
                store.today()
            } label: {
                Image(systemName: "scope")
                    .help("오늘")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(height: 20)
            }
            HoverButton {
                withAnimation(.smooth(duration: 0.3)) {
                    eventDialog = .add(Date())
                }
            } label: {
                Image(systemName: "plus")
                    .help("이벤트 등록")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(.capsule)
        .shadow(color: .black.opacity(0.1), radius: 7, x: 0, y: 2)
        .padding(.top, 10)
        .padding(.leading, isSidebarVisible ? 12 : 80)
    }
}
