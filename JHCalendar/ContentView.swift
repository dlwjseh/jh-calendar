import SwiftUI

struct ContentView: View {
    @State private var isSidebarVisible = false
    @State private var isAddFolderPresented = false
    @State private var isAddCategoryPresented = false
    
    var body: some View {
        HStack(spacing: 0) {
            Sidebar(
                isAddFolderPresented: $isAddFolderPresented,
                isAddCategoryPresented: $isAddCategoryPresented
            )
                .frame(width: isSidebarVisible ? 240 : 0, alignment: .leading)
                .clipped()
            ZStack(alignment: .topLeading) {
                Color.clear
                MonthlyCalendarView()
                FloatingToolbar(isSidebarVisible: $isSidebarVisible)
            }
        }
        .onChange(of: isAddFolderPresented) { _, new in
            print("isAddFolderPresented = \(new)")
        }
        .onChange(of: isAddCategoryPresented) { _, new in
            print("isAddCategoryPresented = \(new)")
        }
        .frame(minWidth: 900, minHeight: 600)
        .overlay(alignment: .topLeading) { TrafficLightHoverArea() }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
