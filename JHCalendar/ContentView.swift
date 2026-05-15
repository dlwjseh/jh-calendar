import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var folders: [Folder]
    @State private var isSidebarVisible = false
    @State private var folderDialog: FolderDialogMode? = nil
    @State private var categoryDialog: CategoryDialogMode? = nil
    @State private var eventDialog: EventDialogMode? = nil
    
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
                    FloatingToolbar(
                        isSidebarVisible: $isSidebarVisible,
                        eventDialog: $eventDialog
                    )
                }
            }
            .overlay(alignment: .topLeading) { TrafficLightHoverArea() }
            
            if let mode = folderDialog {
                DialogBackdrop {
                    withAnimation(.smooth(duration: 0.3)) {
                        folderDialog = nil
                    }
                }.transition(.opacity)
                AddFolderDialog(
                    mode: mode,
                    onDismiss: {
                        withAnimation(.smooth(duration: 0.3)) {
                            folderDialog = nil
                        }
                    }
                ).transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
            if let mode = categoryDialog {
                DialogBackdrop {
                    withAnimation(.smooth(duration: 0.3)) {
                        categoryDialog = nil
                    }
                }.transition(.opacity)
                AddCategoryDialog(
                    mode: mode,
                    folders: folders,
                    onDismiss: {
                        withAnimation(.smooth(duration: 0.3)) {
                            categoryDialog = nil
                        }
                    }
                ).transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
            if let mode = eventDialog {
                DialogBackdrop {
                    withAnimation(.smooth(duration: 0.3)) {
                        eventDialog = nil
                    }
                }.transition(.opacity)
                AddEventDialog(
                    mode: mode,
                    categories: folders.flatMap(\.categories),
                    onDismiss: {
                        withAnimation(.smooth(duration: 0.3)) {
                            eventDialog = nil
                        }
                    }
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
