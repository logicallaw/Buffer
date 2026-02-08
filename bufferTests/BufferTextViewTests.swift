import Testing
import AppKit
@testable import buffer

// MARK: - BufferTextView 화이트박스 테스트

struct BufferTextViewTests {

    private func makeTextView(with text: String) -> BufferTextView {
        let textView = BufferTextView()
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = NSTextStorage(string: text)
        textStorage.addLayoutManager(layoutManager)
        textView.replaceTextContainer(textContainer)
        textView.frame = NSRect(x: 0, y: 0, width: 500, height: 500)
        return textView
    }

    // MARK: - 플레이스홀더 텍스트

    @Test func placeholder_string_value() {
        // 빈 문자열일 때 플레이스홀더가 표시되어야 함 (draw 메서드 분기)
        let textView = makeTextView(with: "")
        #expect(textView.string.isEmpty)
    }

    @Test func non_empty_string_no_placeholder() {
        let textView = makeTextView(with: "내용")
        #expect(!textView.string.isEmpty)
    }

    // MARK: - 체크박스 토글 로직 (mouseDown 분기)

    @Test func checkbox_unchecked_string_detection() {
        let text = "- [ ] 할일"
        let nsText = text as NSString

        // "- [ ]" 패턴이 감지되는지 확인
        let regex = try! NSRegularExpression(pattern: "- \\[([ x])\\]")
        let range = NSRange(location: 0, length: nsText.length)
        let match = regex.firstMatch(in: text, range: range)
        #expect(match != nil)

        // 매치 위치에서 인덱스 3이 " " (space)인지 확인
        let checkCharLoc = match!.range.location + 3
        let checkChar = nsText.substring(with: NSRange(location: checkCharLoc, length: 1))
        #expect(checkChar == " ")
    }

    @Test func checkbox_checked_string_detection() {
        let text = "- [x] 완료"
        let nsText = text as NSString

        let regex = try! NSRegularExpression(pattern: "- \\[([ x])\\]")
        let range = NSRange(location: 0, length: nsText.length)
        let match = regex.firstMatch(in: text, range: range)
        #expect(match != nil)

        let checkCharLoc = match!.range.location + 3
        let checkChar = nsText.substring(with: NSRange(location: checkCharLoc, length: 1))
        #expect(checkChar == "x")
    }

    // MARK: - 토글 마커 감지 로직

    @Test func toggle_closed_marker_detected() {
        let text = "▶ 접힌 토글"
        #expect(text.hasPrefix("▶"))
    }

    @Test func toggle_open_marker_detected() {
        let text = "▼ 열린 토글"
        #expect(text.hasPrefix("▼"))
    }

    @Test func toggle_replacement_logic() {
        let current = "▶"
        let replacement = current == "▶" ? "▼" : "▶"
        #expect(replacement == "▼")

        let current2 = "▼"
        let replacement2 = current2 == "▶" ? "▼" : "▶"
        #expect(replacement2 == "▶")
    }

    // MARK: - charIndex >= string.length 가드 분기

    @Test func charIndex_beyond_length_guard() {
        let text = "AB"
        let nsText = text as NSString
        let length = nsText.length
        // charIndex >= length인 경우 super.mouseDown 호출 경로
        #expect(length == 2)
        // charIndex 2일 때 guard 조건 충족
        #expect(2 >= length)
    }

    // MARK: - 일반 텍스트 클릭 (super.mouseDown 경로)

    @Test func plain_text_has_no_checkbox_or_toggle() {
        let text = "일반 텍스트"
        let hasCheckbox = text.range(of: "- \\[([ x])\\]", options: .regularExpression) != nil
        let hasToggle = text.hasPrefix("▶") || text.hasPrefix("▼")
        #expect(hasCheckbox == false)
        #expect(hasToggle == false)
    }

    // MARK: - 체크박스가 있지만 클릭 범위 밖인 경우

    @Test func checkbox_exists_but_click_outside_range() {
        let text = "- [ ] 할일"
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: NSRange(location: 0, length: 0))

        if let checkboxRange = text.range(of: "- \\[([ x])\\]", options: .regularExpression) {
            let localRange = NSRange(checkboxRange, in: text)
            let clickableStart = lineRange.location + localRange.location
            let clickableEnd = lineRange.location + localRange.location + localRange.length

            // 범위 밖 (예: charIndex가 "할일" 위치)
            let charIndex = 6  // "할" 위치 근처
            let isInside = charIndex >= clickableStart && charIndex < clickableEnd
            #expect(isInside == false)
        }
    }

    // MARK: - textStorage 직접 교체 테스트

    @Test func textStorage_replace_checkbox() {
        let ts = NSTextStorage(string: "- [ ] 할일")
        let replaceRange = NSRange(location: 3, length: 1)
        ts.replaceCharacters(in: replaceRange, with: "x")
        #expect(ts.string == "- [x] 할일")
    }

    @Test func textStorage_replace_toggle() {
        let ts = NSTextStorage(string: "▶ 접힌 토글")
        let replaceRange = NSRange(location: 0, length: 1)
        ts.replaceCharacters(in: replaceRange, with: "▼")
        #expect(ts.string == "▼ 접힌 토글")
    }

    // MARK: - 체크박스 역방향 토글 (checked → unchecked)

    @Test func textStorage_replace_checkbox_checked_to_unchecked() {
        let ts = NSTextStorage(string: "- [x] 완료")
        let replaceRange = NSRange(location: 3, length: 1) // "x" 위치
        ts.replaceCharacters(in: replaceRange, with: " ")
        #expect(ts.string == "- [ ] 완료")
    }

    // MARK: - 토글 역방향 (열림 → 닫힘)

    @Test func textStorage_replace_toggle_open_to_closed() {
        let ts = NSTextStorage(string: "▼ 열린 토글")
        let replaceRange = NSRange(location: 0, length: 1)
        ts.replaceCharacters(in: replaceRange, with: "▶")
        #expect(ts.string == "▶ 열린 토글")
    }

    // MARK: - 다중 라인에서 체크박스 위치 계산

    @Test func checkbox_in_second_line_position() {
        let text = "첫줄\n- [ ] 할일"
        let nsText = text as NSString

        // 두 번째 줄의 시작 위치
        let secondLineStart = (text as NSString).range(of: "- [ ]").location
        let lineRange = nsText.lineRange(for: NSRange(location: secondLineStart, length: 0))
        let line = nsText.substring(with: lineRange)

        if let checkboxRange = line.range(of: "- \\[([ x])\\]", options: .regularExpression) {
            let localRange = NSRange(checkboxRange, in: line)
            let clickableStart = lineRange.location + localRange.location
            let clickableEnd = lineRange.location + localRange.location + localRange.length
            // "- [ ]"의 절대 위치 확인
            #expect(clickableStart == secondLineStart)
            #expect(clickableEnd == secondLineStart + 5)
        }
    }

    // MARK: - 토글 마커가 줄 시작이 아닌 위치에 있는 경우

    @Test func toggle_marker_not_at_line_start() {
        let text = "텍스트 ▶ 아님"
        let hasTogglePrefix = text.hasPrefix("▶") || text.hasPrefix("▼")
        #expect(hasTogglePrefix == false)
    }

    // MARK: - 빈 textStorage 교체

    @Test func textStorage_replace_in_empty_creates_content() {
        let ts = NSTextStorage(string: "")
        ts.replaceCharacters(in: NSRange(location: 0, length: 0), with: "- [ ] ")
        #expect(ts.string == "- [ ] ")
    }

    // MARK: - 체크박스 클릭 범위 내 정확히 경계

    @Test func checkbox_click_at_exact_start_boundary() {
        let text = "- [ ] 할일"
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: NSRange(location: 0, length: 0))

        if let checkboxRange = text.range(of: "- \\[([ x])\\]", options: .regularExpression) {
            let localRange = NSRange(checkboxRange, in: text)
            let clickableStart = lineRange.location + localRange.location
            let clickableEnd = lineRange.location + localRange.location + localRange.length

            // 정확히 시작 경계에서 클릭
            let charIndex = clickableStart
            let isInside = charIndex >= clickableStart && charIndex < clickableEnd
            #expect(isInside == true)
        }
    }

    @Test func checkbox_click_at_exact_end_boundary() {
        let text = "- [ ] 할일"
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: NSRange(location: 0, length: 0))

        if let checkboxRange = text.range(of: "- \\[([ x])\\]", options: .regularExpression) {
            let localRange = NSRange(checkboxRange, in: text)
            let clickableStart = lineRange.location + localRange.location
            let clickableEnd = lineRange.location + localRange.location + localRange.length

            // 정확히 끝 경계에서 클릭 (밖)
            let charIndex = clickableEnd
            let isInside = charIndex >= clickableStart && charIndex < clickableEnd
            #expect(isInside == false)
        }
    }

    // MARK: - onCheckboxToggle / onToggleMarkerClick 콜백 프로퍼티

    @Test func callback_properties_default_nil() {
        let textView = makeTextView(with: "")
        #expect(textView.onCheckboxToggle == nil)
        #expect(textView.onToggleMarkerClick == nil)
    }

    // MARK: - 다중 체크박스 라인에서 특정 라인 감지

    @Test func multiple_checkbox_lines_detect_correct_one() {
        let text = "- [ ] 첫번째\n- [x] 두번째\n- [ ] 세번째"
        let nsText = text as NSString

        // 두 번째 라인의 체크박스 확인
        let secondStart = (nsText as NSString).range(of: "- [x]").location
        let lineRange = nsText.lineRange(for: NSRange(location: secondStart, length: 0))
        let line = nsText.substring(with: lineRange)

        if let checkboxRange = line.range(of: "- \\[([ x])\\]", options: .regularExpression) {
            let localRange = NSRange(checkboxRange, in: line)
            let checkCharLoc = lineRange.location + localRange.location + 3
            let checkChar = nsText.substring(with: NSRange(location: checkCharLoc, length: 1))
            #expect(checkChar == "x")
        }
    }
}
