import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BufferItem.updatedAt, order: .reverse) private var allItems: [BufferItem]
    @Binding var selectedItem: BufferItem?
    let category: BufferCategory

    private var filteredItems: [BufferItem] {
        if category == .all {
            return allItems
        }
        return allItems.filter { $0.category == category }
    }

    var body: some View {
        List(selection: $selectedItem) {
            ForEach(filteredItems) { item in
                NoteRowView(item: item)
                    .tag(item)
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.inset)
        .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 360)
        .toolbar {
            ToolbarItem {
                Button(action: createNewNote) {
                    Label("New Note", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }

    private func createNewNote() {
        let newItem = BufferItem(title: "", content: "", category: category == .all ? .notes : category)
        modelContext.insert(newItem)
        selectedItem = newItem
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            if selectedItem == item {
                selectedItem = nil
            }
            modelContext.delete(item)
        }
    }
}
