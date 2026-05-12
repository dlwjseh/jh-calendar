import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var folders: [Folder]
    @State private var isSidebarVisible = false
    @State private var isAddFolderPresented = false
    @State private var isAddCategoryPresented = false
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Sidebar(
                    isAddFolderPresented: $isAddFolderPresented,
                    isAddCategoryPresented: $isAddCategoryPresented,
                    folders: folders
                )
                    .frame(width: isSidebarVisible ? 240 : 0, alignment: .leading)
                    .clipped()
                ZStack(alignment: .topLeading) {
                    Color.clear
                    MonthlyCalendarView()
                    FloatingToolbar(isSidebarVisible: $isSidebarVisible)
                }
            }
            .overlay(alignment: .topLeading) { TrafficLightHoverArea() }
            
            if isAddFolderPresented {
                DialogBackdrop(isPresented: $isAddFolderPresented)
                    .transition(.opacity)
                AddFolderDialog(isPresented: $isAddFolderPresented)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
            if isAddCategoryPresented {
                DialogBackdrop(isPresented: $isAddCategoryPresented)
                    .transition(.opacity)
                AddCategoryDialog(isPresented: $isAddCategoryPresented, folders: folders)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
