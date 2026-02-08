import SwiftUI

struct SlashCommandView: View {
    let commands: [SlashCommand]
    let selectedIndex: Int
    let onSelect: (SlashCommand) -> Void

    private var groupedCommands: [(SlashCommandCategory, [SlashCommand])] {
        var result: [(SlashCommandCategory, [SlashCommand])] = []
        var seen = Set<String>()
        for cmd in commands {
            let key = cmd.category.rawValue
            if !seen.contains(key) {
                seen.insert(key)
                let group = commands.filter { $0.category == cmd.category }
                result.append((cmd.category, group))
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedCommands, id: \.0.rawValue) { category, items in
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)
                                .padding(.bottom, 4)

                            ForEach(Array(items.enumerated()), id: \.element.id) { _, command in
                                let currentIndex = flatIndex(for: command)
                                let isSelected = currentIndex == selectedIndex

                                Button(action: { onSelect(command) }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: command.icon)
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(isSelected ? .white : .secondary)

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(command.name)
                                                .font(.body)
                                                .foregroundStyle(isSelected ? .white : .primary)
                                            Text(command.description)
                                                .font(.caption)
                                                .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color.accentColor : Color.clear)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .id(currentIndex)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: selectedIndex) { _, newValue in
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 260, height: 320)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    private func flatIndex(for command: SlashCommand) -> Int {
        commands.firstIndex(of: command) ?? 0
    }
}
