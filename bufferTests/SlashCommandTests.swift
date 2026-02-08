import Testing
import Foundation
@testable import buffer

// MARK: - SlashCommandCategory 화이트박스 테스트

struct SlashCommandCategoryTests {

    @Test func rawValues() {
        #expect(SlashCommandCategory.basic.rawValue == "기본 블록")
        #expect(SlashCommandCategory.list.rawValue == "리스트")
        #expect(SlashCommandCategory.advanced.rawValue == "고급 블록")
        #expect(SlashCommandCategory.page.rawValue == "페이지")
    }

    @Test func allCases_has_4() {
        #expect(SlashCommandCategory.allCases.count == 4)
    }
}

// MARK: - SlashCommand 화이트박스 테스트

struct SlashCommandTests {

    @Test func equatable_same_instance() {
        let cmd = SlashCommand(name: "테스트", description: "설명", icon: "star", category: .basic, template: "")
        #expect(cmd == cmd)
    }

    @Test func equatable_different_instances_not_equal() {
        let a = SlashCommand(name: "테스트", description: "설명", icon: "star", category: .basic, template: "")
        let b = SlashCommand(name: "테스트", description: "설명", icon: "star", category: .basic, template: "")
        // 각 인스턴스는 고유한 UUID를 가지므로 같지 않아야 함
        #expect(a != b)
    }

    @Test func identifiable_id_is_unique() {
        let a = SlashCommand(name: "A", description: "", icon: "", category: .basic, template: "")
        let b = SlashCommand(name: "B", description: "", icon: "", category: .basic, template: "")
        #expect(a.id != b.id)
    }

    @Test func properties_are_set() {
        let cmd = SlashCommand(name: "제목 1", description: "큰 제목", icon: "textformat.size.larger", category: .basic, template: "# ")
        #expect(cmd.name == "제목 1")
        #expect(cmd.description == "큰 제목")
        #expect(cmd.icon == "textformat.size.larger")
        #expect(cmd.category == .basic)
        #expect(cmd.template == "# ")
    }
}

// MARK: - SlashCommandRegistry 화이트박스 테스트

struct SlashCommandRegistryTests {

    // MARK: - 전체 명령어 카운트

    @Test func commands_count() {
        #expect(SlashCommandRegistry.commands.count == 15)
    }

    // MARK: - 카테고리별 명령어 개수

    @Test func commands_per_category() {
        let basic = SlashCommandRegistry.commands.filter { $0.category == .basic }
        let list = SlashCommandRegistry.commands.filter { $0.category == .list }
        let advanced = SlashCommandRegistry.commands.filter { $0.category == .advanced }
        let page = SlashCommandRegistry.commands.filter { $0.category == .page }

        #expect(basic.count == 4)
        #expect(list.count == 4)
        #expect(advanced.count == 5)
        #expect(page.count == 2)
    }

    // MARK: - filter: 빈 쿼리 → 전체 반환 (분기 1)

    @Test func filter_empty_query_returns_all() {
        let result = SlashCommandRegistry.filter(by: "")
        #expect(result.count == SlashCommandRegistry.commands.count)
    }

    // MARK: - filter: 쿼리로 필터링 (분기 2)

    @Test func filter_by_제목_returns_3_heading_commands() {
        let result = SlashCommandRegistry.filter(by: "제목")
        #expect(result.count == 3)
        for cmd in result {
            #expect(cmd.name.contains("제목"))
        }
    }

    @Test func filter_by_partial_match() {
        let result = SlashCommandRegistry.filter(by: "토")
        #expect(result.count == 1)
        #expect(result.first?.name == "토글")
    }

    @Test func filter_by_코드() {
        let result = SlashCommandRegistry.filter(by: "코드")
        #expect(result.count == 1)
        #expect(result.first?.name == "코드 블록")
    }

    @Test func filter_no_match_returns_empty() {
        let result = SlashCommandRegistry.filter(by: "존재하지않는명령어")
        #expect(result.isEmpty)
    }

    @Test func filter_case_insensitive() {
        // 한글은 케이스가 없지만, localizedCaseInsensitiveContains 호출 경로 확인
        let result = SlashCommandRegistry.filter(by: "페이지")
        #expect(result.count == 2)
    }

    // MARK: - 특수 명령어 템플릿 검증

    @Test func page_command_has_sentinel_template() {
        let pageCmd = SlashCommandRegistry.commands.first { $0.name == "페이지" }
        #expect(pageCmd?.template == "__PAGE__")
    }

    @Test func pageLinkCommand_has_sentinel_template() {
        let linkCmd = SlashCommandRegistry.commands.first { $0.name == "페이지 링크" }
        #expect(linkCmd?.template == "__PAGE_LINK__")
    }

    // MARK: - 각 명령어의 필수 필드 존재 확인

    @Test func all_commands_have_nonempty_fields() {
        for cmd in SlashCommandRegistry.commands {
            #expect(!cmd.name.isEmpty, "name should not be empty for \(cmd.name)")
            #expect(!cmd.description.isEmpty, "description should not be empty for \(cmd.name)")
            #expect(!cmd.icon.isEmpty, "icon should not be empty for \(cmd.name)")
        }
    }

    // MARK: - 텍스트 명령어 빈 템플릿

    @Test func text_command_has_empty_template() {
        let textCmd = SlashCommandRegistry.commands.first { $0.name == "텍스트" }
        #expect(textCmd?.template == "")
    }

    // MARK: - 마크다운 템플릿 정확성

    @Test func heading_templates() {
        let h1 = SlashCommandRegistry.commands.first { $0.name == "제목 1" }
        let h2 = SlashCommandRegistry.commands.first { $0.name == "제목 2" }
        let h3 = SlashCommandRegistry.commands.first { $0.name == "제목 3" }
        #expect(h1?.template == "# ")
        #expect(h2?.template == "## ")
        #expect(h3?.template == "### ")
    }

    @Test func list_templates() {
        let todo = SlashCommandRegistry.commands.first { $0.name == "할일 목록" }
        let bullet = SlashCommandRegistry.commands.first { $0.name == "글머리 기호" }
        let numbered = SlashCommandRegistry.commands.first { $0.name == "번호 목록" }
        let toggle = SlashCommandRegistry.commands.first { $0.name == "토글" }
        #expect(todo?.template == "- [ ] ")
        #expect(bullet?.template == "- ")
        #expect(numbered?.template == "1. ")
        #expect(toggle?.template == "▶ ")
    }

    @Test func advanced_templates() {
        let quote = SlashCommandRegistry.commands.first { $0.name == "인용" }
        let divider = SlashCommandRegistry.commands.first { $0.name == "구분선" }
        let callout = SlashCommandRegistry.commands.first { $0.name == "콜아웃" }
        let table = SlashCommandRegistry.commands.first { $0.name == "표" }
        let code = SlashCommandRegistry.commands.first { $0.name == "코드 블록" }
        #expect(quote?.template == "> ")
        #expect(divider?.template == "---\n")
        #expect(callout?.template == "> 💡 ")
        #expect(table?.template.contains("| 열 1 |") == true)
        #expect(code?.template == "```\n\n```")
    }
}
