import SwiftUI
import SwiftData

struct EditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: BufferItem
    @State private var showPagePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            TextField("제목", text: $item.title)
                .textFieldStyle(.plain)
                .font(.title.bold())
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .onChange(of: item.title) {
                    item.updatedAt = Date()
                }

            Divider()
                .padding(.horizontal, 20)

            // Markdown editor
            MarkdownTextView(
                text: $item.content,
                onTextChange: {
                    item.updatedAt = Date()
                },
                onCreateSubPage: {
                    createSubPage()
                },
                onLinkToPage: {
                    showPagePicker = true
                }
            )

            // Bottom bar
            HStack {
                Label(item.category.displayName, systemImage: item.category.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(item.updatedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showPagePicker) {
            PagePickerView { selectedPage in
                let title = selectedPage.title.isEmpty ? "제목 없음" : selectedPage.title
                item.content += "[[" + title + "]]"
                item.updatedAt = Date()
            }
        }
    }

    private func createSubPage() {
        let subPage = BufferItem(
            title: "",
            content: "",
            category: .notes,
            parentItem: item
        )
        modelContext.insert(subPage)
        let linkText = "[[새 페이지]]"
        item.content += linkText
        item.updatedAt = Date()
    }
}
