import SwiftUI
import SwiftData

struct PagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BufferItem.updatedAt, order: .reverse) private var allItems: [BufferItem]
    @State private var searchText = ""
    let onSelect: (BufferItem) -> Void

    private var filteredItems: [BufferItem] {
        if searchText.isEmpty {
            return allItems
        }
        return allItems.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("페이지 링크")
                    .font(.headline)
                Spacer()
                Button("취소") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .padding()

            // Search
            TextField("페이지 검색...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.bottom, 8)

            Divider()

            // List
            List(filteredItems) { item in
                Button(action: {
                    onSelect(item)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title.isEmpty ? "제목 없음" : item.title)
                                .font(.body)
                            if !item.content.isEmpty {
                                Text(item.content)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .frame(width: 360, height: 400)
    }
}
