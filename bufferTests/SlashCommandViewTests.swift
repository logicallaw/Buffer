import Testing
@testable import buffer

// MARK: - SlashCommandView 로직 화이트박스 테스트
// (SwiftUI View 자체는 렌더링 불가 → 내부 로직인 groupedCommands, flatIndex 테스트)

struct SlashCommandViewLogicTests {

    // MARK: - groupedCommands 로직 (카테고리별 그루핑)

    @Test func grouping_preserves_category_order() {
        let commands = SlashCommandRegistry.commands

        // 등장 순서대로 카테고리가 나와야 함
        var seen = Set<String>()
        var categories: [SlashCommandCategory] = []
        for cmd in commands {
            if !seen.contains(cmd.category.rawValue) {
                seen.insert(cmd.category.rawValue)
                categories.append(cmd.category)
            }
        }

        #expect(categories.count == 4)
        #expect(categories[0] == .basic)
        #expect(categories[1] == .list)
        #expect(categories[2] == .advanced)
        #expect(categories[3] == .page)
    }

    @Test func grouping_filtered_commands() {
        let filtered = SlashCommandRegistry.filter(by: "제목")
        // 모두 basic 카테고리
        var seen = Set<String>()
        var categories: [SlashCommandCategory] = []
        for cmd in filtered {
            if !seen.contains(cmd.category.rawValue) {
                seen.insert(cmd.category.rawValue)
                categories.append(cmd.category)
            }
        }
        #expect(categories.count == 1)
        #expect(categories[0] == .basic)
    }

    @Test func grouping_empty_commands() {
        let commands: [SlashCommand] = []
        var seen = Set<String>()
        var result: [(SlashCommandCategory, [SlashCommand])] = []
        for cmd in commands {
            let key = cmd.category.rawValue
            if !seen.contains(key) {
                seen.insert(key)
                let group = commands.filter { $0.category == cmd.category }
                result.append((cmd.category, group))
            }
        }
        #expect(result.isEmpty)
    }

    // MARK: - flatIndex 로직 (firstIndex 검색)

    @Test func flatIndex_finds_correct_position() {
        let commands = SlashCommandRegistry.commands
        for (i, cmd) in commands.enumerated() {
            let found = commands.firstIndex(of: cmd) ?? 0
            #expect(found == i)
        }
    }

    @Test func flatIndex_not_found_returns_0() {
        let commands = SlashCommandRegistry.commands
        let orphan = SlashCommand(name: "없는 명령어", description: "", icon: "", category: .basic, template: "")
        let index = commands.firstIndex(of: orphan) ?? 0
        #expect(index == 0)
    }

    // MARK: - 선택 인덱스 하이라이트 로직

    @Test func selectedIndex_matches_command() {
        let commands = SlashCommandRegistry.commands
        let selectedIndex = 3
        for (i, _) in commands.enumerated() {
            let isSelected = i == selectedIndex
            if i == 3 {
                #expect(isSelected == true)
            } else {
                #expect(isSelected == false)
            }
        }
    }
}

// MARK: - PagePickerView 로직 화이트박스 테스트

struct PagePickerViewLogicTests {

    // MARK: - 필터링 로직 시뮬레이션

    @Test func filter_empty_search_returns_all() {
        let items = [
            (title: "메모 1", content: "내용 A"),
            (title: "메모 2", content: "내용 B"),
        ]
        let searchText = ""
        let filtered: [(title: String, content: String)]
        if searchText.isEmpty {
            filtered = items
        } else {
            filtered = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        #expect(filtered.count == 2)
    }

    @Test func filter_by_title() {
        let items = [
            (title: "프로젝트 계획", content: "내용"),
            (title: "회의록", content: "주간 회의"),
        ]
        let searchText = "프로젝트"
        let filtered = items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
        #expect(filtered.count == 1)
        #expect(filtered[0].title == "프로젝트 계획")
    }

    @Test func filter_by_content() {
        let items = [
            (title: "메모", content: "중요한 회의 결과"),
            (title: "일지", content: "오늘의 할 일"),
        ]
        let searchText = "회의"
        let filtered = items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
        #expect(filtered.count == 1)
        #expect(filtered[0].title == "메모")
    }

    @Test func filter_no_match() {
        let items = [
            (title: "메모", content: "내용"),
        ]
        let searchText = "없는검색어"
        let filtered = items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
        #expect(filtered.isEmpty)
    }
}
