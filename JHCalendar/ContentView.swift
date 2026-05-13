import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var folders: [Folder]
    @State private var isSidebarVisible = false
    @State private var folderDialog: FolderDialogMode? = nil
    @State private var categoryDialog: CategoryDialogMode? = nil
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Sidebar(
                    folderDialog: $folderDialog,
                    categoryDialog: $categoryDialog,
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
            
            if let mode = folderDialog {
                DialogBackdrop { folderDialog = nil }
                    .transition(.opacity)
                AddFolderDialog(
                    mode: mode,
                    onDismiss: { folderDialog = nil }
                ).transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
            if let mode = categoryDialog {
                DialogBackdrop { categoryDialog = nil }
                    .transition(.opacity)
                AddCategoryDialog(
                    mode: mode,
                    folders: folders,
                    onDismiss: { categoryDialog = nil }
                ).transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
