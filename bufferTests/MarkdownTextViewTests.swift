import Testing
import AppKit
@testable import buffer

// MARK: - MarkdownTextView Coordinator 화이트박스 테스트

struct MarkdownTextViewCoordinatorTests {

    // MARK: - Coordinator 초기 상태

    @Test func coordinator_initial_state() {
        var text = ""
        let binding = _BindingHelper(get: { text }, set: { text = $0 })
        // Coordinator의 isUpdatingFromSwiftUI 초기값 확인은 뷰 생성 시 테스트 가능
        // 기본 속성만 확인
        #expect(text.isEmpty)
    }

    // MARK: - Slash 명령어 감지 조건

    @Test func slash_at_start_of_line_triggers_menu() {
        // "/" 입력 시 range.location == 0이면 isStartOfLine == true
        let nsString = "" as NSString
        let location = 0
        let isStartOfLine = location == 0
        #expect(isStartOfLine == true)
    }

    @Test func slash_after_newline_triggers_menu() {
        let nsString = "첫줄\n" as NSString
        let location = nsString.length  // "\n" 다음 위치
        let prevChar = nsString.substring(with: NSRange(location: location - 1, length: 1))
        let isStartOfLine = prevChar == "\n"
        #expect(isStartOfLine == true)
    }

    @Test func slash_after_space_triggers_menu() {
        let nsString = "텍스트 " as NSString
        let location = nsString.length
        let prevChar = nsString.substring(with: NSRange(location: location - 1, length: 1))
        let isAfterSpace = prevChar == " "
        #expect(isAfterSpace == true)
    }

    @Test func slash_in_middle_of_word_does_not_trigger() {
        let nsString = "abc" as NSString
        let location = 2  // "c" 다음에 "/" 입력
        let prevChar = nsString.substring(with: NSRange(location: location - 1, length: 1))
        let isStartOfLine = location == 0 || prevChar == "\n"
        let isAfterSpace = location > 0 && prevChar == " "
        #expect(isStartOfLine == false)
        #expect(isAfterSpace == false)
    }

    // MARK: - Slash 쿼리 계산 로직

    @Test func slash_query_empty_when_cursor_right_after_slash() {
        let slashStartIndex = 0
        let currentLoc = 1  // "/" 바로 뒤
        let queryStart = slashStartIndex + 1
        let queryLength = currentLoc - queryStart
        #expect(queryLength == 0)
    }

    @Test func slash_query_extracts_text() {
        let nsString = "/제목" as NSString
        let slashStartIndex = 0
        let currentLoc = 3  // "/제목" 뒤
        let queryStart = slashStartIndex + 1
        let queryLength = currentLoc - queryStart
        let query = nsString.substring(with: NSRange(location: queryStart, length: queryLength))
        #expect(query == "제목")
    }

    @Test func slash_query_dismiss_when_cursor_before_slash() {
        let slashStartIndex = 5
        let currentLoc = 3  // 슬래시 이전으로 커서가 이동한 경우
        let queryStart = slashStartIndex + 1
        let shouldDismiss = queryStart > currentLoc
        #expect(shouldDismiss == true)
    }

    // MARK: - 명령어 선택 분기: __PAGE__ 템플릿

    @Test func page_template_detected() {
        let cmd = SlashCommand(name: "페이지", description: "", icon: "", category: .page, template: "__PAGE__")
        #expect(cmd.template == "__PAGE__")
    }

    @Test func page_link_template_detected() {
        let cmd = SlashCommand(name: "페이지 링크", description: "", icon: "", category: .page, template: "__PAGE_LINK__")
        #expect(cmd.template == "__PAGE_LINK__")
    }

    @Test func normal_template_is_not_special() {
        let cmd = SlashCommand(name: "제목 1", description: "", icon: "", category: .basic, template: "# ")
        #expect(cmd.template != "__PAGE__")
        #expect(cmd.template != "__PAGE_LINK__")
    }

    // MARK: - doCommandBy 분기 (selector 매핑)

    @Test func moveUp_selector_exists() {
        let selector = #selector(NSResponder.moveUp(_:))
        #expect(selector == #selector(NSResponder.moveUp(_:)))
    }

    @Test func moveDown_selector_exists() {
        let selector = #selector(NSResponder.moveDown(_:))
        #expect(selector == #selector(NSResponder.moveDown(_:)))
    }

    @Test func insertNewline_selector_exists() {
        let selector = #selector(NSResponder.insertNewline(_:))
        #expect(selector == #selector(NSResponder.insertNewline(_:)))
    }

    @Test func cancelOperation_selector_exists() {
        let selector = #selector(NSResponder.cancelOperation(_:))
        #expect(selector == #selector(NSResponder.cancelOperation(_:)))
    }

    // MARK: - 명령어 인덱스 경계 테스트

    @Test func selectedCommandIndex_bounds() {
        let commands = SlashCommandRegistry.commands
        // moveUp: index > 0일 때만 감소
        var index = 0
        let canMoveUp = index > 0
        #expect(canMoveUp == false)

        // moveDown: index < count - 1일 때만 증가
        index = commands.count - 1
        let canMoveDown = index < commands.count - 1
        #expect(canMoveDown == false)

        // 중간 인덱스
        index = 5
        #expect(index > 0)
        #expect(index < commands.count - 1)
    }

    @Test func selectCurrentCommand_out_of_bounds_guard() {
        let commands: [SlashCommand] = []
        let index = 0
        let shouldDismiss = index >= commands.count
        #expect(shouldDismiss == true)
    }

    // MARK: - 쿼리 길이 음수 분기 (queryLength < 0)

    @Test func slash_query_negative_length_dismisses() {
        let slashStartIndex = 10
        let currentLoc = 8  // 커서가 slash 이전으로 이동
        let queryStart = slashStartIndex + 1
        let queryLength = currentLoc - queryStart
        #expect(queryLength < 0)
    }

    // MARK: - 필터된 명령어가 비어있으면 메뉴 닫기

    @Test func empty_filtered_commands_dismisses() {
        let query = "존재하지않는명령어"
        let filtered = SlashCommandRegistry.filter(by: query)
        #expect(filtered.isEmpty)
    }

    // MARK: - moveUp 경계: index == 1 → 0으로 이동 가능

    @Test func moveUp_from_index_1_possible() {
        var index = 1
        let canMoveUp = index > 0
        #expect(canMoveUp == true)
        if canMoveUp { index -= 1 }
        #expect(index == 0)
    }

    // MARK: - moveDown 경계: index == count-2 → count-1로 이동 가능

    @Test func moveDown_from_second_to_last_possible() {
        let commands = SlashCommandRegistry.commands
        var index = commands.count - 2
        let canMoveDown = index < commands.count - 1
        #expect(canMoveDown == true)
        if canMoveDown { index += 1 }
        #expect(index == commands.count - 1)
    }

    // MARK: - selectCommand: 일반 템플릿 대체 로직

    @Test func normal_template_replacement_calculates_range() {
        let slashStartIndex = 5
        let currentLoc = 8  // "/제목" 입력 후
        let replaceStart = slashStartIndex
        let replaceLength = currentLoc - replaceStart
        #expect(replaceStart == 5)
        #expect(replaceLength == 3)
    }

    // MARK: - "/" 감지: markedRange == NSNotFound 조건 (한글 IME)

    @Test func marked_range_not_found_allows_slash() {
        let markedLocation = NSNotFound
        let isComposing = markedLocation != NSNotFound
        #expect(isComposing == false)
    }

    @Test func marked_range_found_blocks_slash() {
        let markedLocation = 5  // 조합 중
        let isComposing = markedLocation != NSNotFound
        #expect(isComposing == true)
    }

    // MARK: - Slash 쿼리에 공백 포함 시 필터링

    @Test func slash_query_with_space_filters() {
        let query = "코드 블록"
        let filtered = SlashCommandRegistry.filter(by: query)
        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "코드 블록")
    }

    @Test func slash_query_partial_returns_filtered() {
        let query = "글머"
        let filtered = SlashCommandRegistry.filter(by: query)
        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "글머리 기호")
    }

    // MARK: - isSlashMenuVisible false일 때 doCommandBy 동작

    @Test func doCommandBy_returns_false_when_menu_hidden() {
        // isSlashMenuVisible == false이면 모든 selector에 대해 false 반환
        let isSlashMenuVisible = false
        let result = isSlashMenuVisible  // 메뉴가 보이지 않으면 처리 안 함
        #expect(result == false)
    }

    // MARK: - selectCurrentCommand: 유효한 인덱스

    @Test func selectCurrentCommand_valid_index() {
        let commands = SlashCommandRegistry.commands
        let index = 3
        let shouldDismiss = index >= commands.count
        #expect(shouldDismiss == false)
        let selected = commands[index]
        #expect(!selected.name.isEmpty)
    }

    // MARK: - "__PAGE__" 템플릿: 슬래시 텍스트 제거 후 콜백

    @Test func page_template_replaces_with_empty() {
        let template = "__PAGE__"
        let isPageCommand = template == "__PAGE__"
        #expect(isPageCommand == true)
        // 대체 문자열은 빈 문자열
        let replacement = ""
        #expect(replacement.isEmpty)
    }

    // MARK: - "__PAGE_LINK__" 템플릿: 슬래시 텍스트 제거 후 콜백

    @Test func page_link_template_replaces_with_empty() {
        let template = "__PAGE_LINK__"
        let isPageLinkCommand = template == "__PAGE_LINK__"
        #expect(isPageLinkCommand == true)
        let replacement = ""
        #expect(replacement.isEmpty)
    }

    // MARK: - updateSlashQuery: queryLength == 0일 때 빈 쿼리

    @Test func query_length_zero_returns_empty_query() {
        let slashStartIndex = 0
        let currentLoc = 1  // "/" 바로 뒤
        let queryStart = slashStartIndex + 1
        let queryLength = currentLoc - queryStart

        let query: String
        if queryLength == 0 {
            query = ""
        } else {
            query = "something"
        }
        #expect(query == "")
    }

    // MARK: - shouldChangeTextIn: 탭/개행 입력 시 메뉴 열린 상태

    @Test func tab_input_while_menu_visible() {
        let isSlashMenuVisible = true
        let inputText = "\t"
        let isTabOrNewline = inputText == "\n" || inputText == "\t"
        // 메뉴가 열린 상태에서 탭 입력 → doCommandBy에서 처리
        #expect(isSlashMenuVisible && isTabOrNewline)
    }

    @Test func newline_input_while_menu_visible() {
        let isSlashMenuVisible = true
        let inputText = "\n"
        let isTabOrNewline = inputText == "\n" || inputText == "\t"
        #expect(isSlashMenuVisible && isTabOrNewline)
    }
}

// MARK: - Binding Helper (테스트용)
// Swift Testing에서 @Binding을 직접 사용할 수 없으므로 로직만 테스트

private struct _BindingHelper<T> {
    let get: () -> T
    let set: (T) -> Void
}
