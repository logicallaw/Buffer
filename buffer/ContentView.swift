import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedCategory: BufferCategory = .all
    @State private var selectedItem: BufferItem?

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
        } content: {
            NoteListView(selectedItem: $selectedItem, category: selectedCategory)
        } detail: {
            if let selectedItem {
                EditorView(item: selectedItem)
            } else {
                Text("Select or create a note")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BufferItem.self, inMemory: true)
}
