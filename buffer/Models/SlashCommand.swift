import Foundation

enum SlashCommandCategory: String, CaseIterable {
    case basic = "기본 블록"
    case list = "리스트"
    case advanced = "고급 블록"
    case page = "페이지"
}

struct SlashCommand: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: SlashCommandCategory
    let template: String

    static func == (lhs: SlashCommand, rhs: SlashCommand) -> Bool {
        lhs.id == rhs.id
    }
}

struct SlashCommandRegistry {
    static let commands: [SlashCommand] = [
        // 기본 블록
        SlashCommand(name: "텍스트", description: "일반 텍스트 블록", icon: "text.alignleft", category: .basic, template: ""),
        SlashCommand(name: "제목 1", description: "큰 제목", icon: "textformat.size.larger", category: .basic, template: "# "),
        SlashCommand(name: "제목 2", description: "중간 제목", icon: "textformat.size", category: .basic, template: "## "),
        SlashCommand(name: "제목 3", description: "작은 제목", icon: "textformat.size.smaller", category: .basic, template: "### "),

        // 리스트
        SlashCommand(name: "할일 목록", description: "체크박스가 있는 목록", icon: "checkmark.square", category: .list, template: "- [ ] "),
        SlashCommand(name: "글머리 기호", description: "글머리 기호 목록", icon: "list.bullet", category: .list, template: "- "),
        SlashCommand(name: "번호 목록", description: "번호가 매겨진 목록", icon: "list.number", category: .list, template: "1. "),
        SlashCommand(name: "토글", description: "접고 펼 수 있는 블록", icon: "chevron.right", category: .list, template: "▶ "),

        // 고급 블록
        SlashCommand(name: "인용", description: "인용문 블록", icon: "text.quote", category: .advanced, template: "> "),
        SlashCommand(name: "구분선", description: "가로 구분선", icon: "minus", category: .advanced, template: "---\n"),
        SlashCommand(name: "콜아웃", description: "강조 박스", icon: "exclamationmark.triangle", category: .advanced, template: "> 💡 "),
        SlashCommand(name: "표", description: "표 블록", icon: "tablecells", category: .advanced, template: "| 열 1 | 열 2 | 열 3 |\n| --- | --- | --- |\n| | | |"),
        SlashCommand(name: "코드 블록", description: "코드 블록", icon: "chevron.left.forwardslash.chevron.right", category: .advanced, template: "```\n\n```"),

        // 페이지
        SlashCommand(name: "페이지", description: "하위 페이지 생성", icon: "doc.badge.plus", category: .page, template: "__PAGE__"),
        SlashCommand(name: "페이지 링크", description: "기존 페이지 링크", icon: "link.badge.plus", category: .page, template: "__PAGE_LINK__"),
    ]

    static func filter(by query: String) -> [SlashCommand] {
        if query.isEmpty {
            return commands
        }
        return commands.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
