import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedCategory: BufferCategory
    @Query private var items: [BufferItem]

    private func count(for category: BufferCategory) -> Int {
        if category == .all {
            return items.count
        }
        return items.filter { $0.category == category }.count
    }

    var body: some View {
        List(selection: $selectedCategory) {
            Section("Categories") {
                ForEach(BufferCategory.allCases) { category in
                    Label {
                        HStack {
                            Text(category.displayName)
                            Spacer()
                            Text("\(count(for: category))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: category.icon)
                    }
                    .tag(category)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 260)
    }
}
