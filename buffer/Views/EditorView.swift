import SwiftUI

struct EditorView: View {
    @Bindable var item: BufferItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            TextField("Title", text: $item.title)
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
            MarkdownTextView(text: $item.content) {
                item.updatedAt = Date()
            }

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
    }
}
