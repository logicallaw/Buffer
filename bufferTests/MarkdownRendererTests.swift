import Testing
import AppKit
@testable import buffer

// MARK: - MarkdownRenderer 화이트박스 테스트

struct MarkdownRendererTests {

    // MARK: - Helper

    private func makeTextStorage(_ text: String) -> NSTextStorage {
        NSTextStorage(string: text)
    }

    private func applyAndGetAttributes(_ text: String, at location: Int) -> [NSAttributedString.Key: Any] {
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        return ts.attributes(at: location, effectiveRange: nil)
    }

    // MARK: - 빈 문자열 (guard early return)

    @Test func empty_string_does_nothing() {
        let ts = makeTextStorage("")
        MarkdownRenderer.applyStyles(to: ts)
        #expect(ts.string == "")
    }

    // MARK: - 기본 스타일 리셋

    @Test func base_style_applied() {
        let attrs = applyAndGetAttributes("Hello", at: 0)
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.bodyFont)
    }

    // MARK: - 헤더 (3 레벨 분기)

    @Test func h1_renders_with_h1Font() {
        let text = "# 큰 제목"
        let attrs = applyAndGetAttributes(text, at: 2)  // "큰" 위치
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.h1Font)
    }

    @Test func h2_renders_with_h2Font() {
        let text = "## 중간 제목"
        let attrs = applyAndGetAttributes(text, at: 3)
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.h2Font)
    }

    @Test func h3_renders_with_h3Font() {
        let text = "### 작은 제목"
        let attrs = applyAndGetAttributes(text, at: 4)
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.h3Font)
    }

    @Test func header_hash_dimmed() {
        let text = "# 제목"
        let attrs = applyAndGetAttributes(text, at: 0)  // "#" 위치
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.syntaxColor)
    }

    // MARK: - 볼드

    @Test func bold_renders() {
        let text = "**볼드**"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // "볼드" 시작 위치 = 2
        let attrs = ts.attributes(at: 2, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.bodyBoldFont)
    }

    @Test func bold_markers_dimmed() {
        let text = "**볼드**"
        let attrs = applyAndGetAttributes(text, at: 0)  // "**" 위치
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.syntaxColor)
    }

    // MARK: - 이탤릭

    @Test func italic_renders() {
        let text = "*이탤릭*"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 1, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.bodyItalicFont)
    }

    @Test func italic_markers_dimmed() {
        let text = "*이탤릭*"
        let attrs = applyAndGetAttributes(text, at: 0)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.syntaxColor)
    }

    // MARK: - 볼드이탤릭

    @Test func boldItalic_renders() {
        let text = "***볼드이탤릭***"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 3, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.bodyBoldItalicFont)
    }

    // MARK: - 취소선

    @Test func strikethrough_renders() {
        let text = "~~취소~~"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 2, effectiveRange: nil)  // "취소" 시작
        let strikeStyle = attrs[.strikethroughStyle] as? Int
        #expect(strikeStyle == NSUnderlineStyle.single.rawValue)
    }

    @Test func strikethrough_markers_dimmed() {
        let text = "~~취소~~"
        let attrs = applyAndGetAttributes(text, at: 0)  // "~~" 위치
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.syntaxColor)
    }

    // MARK: - 인라인 코드

    @Test func inline_code_renders() {
        let text = "`code`"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 1, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        let color = attrs[.foregroundColor] as? NSColor
        let bg = attrs[.backgroundColor] as? NSColor
        #expect(font == MarkdownRenderer.codeFont)
        #expect(color == MarkdownRenderer.codeColor)
        #expect(bg == MarkdownRenderer.codeBgColor)
    }

    // MARK: - 인용

    @Test func blockquote_renders() {
        let text = "> 인용문"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // ">" 마커
        let markerAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((markerAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
        // 내용
        let contentAttrs = ts.attributes(at: 2, effectiveRange: nil)
        #expect((contentAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.quoteColor)
    }

    // MARK: - 콜아웃 (이모지 blockquote 분기)

    @Test func callout_renders_with_background() {
        let text = "> 💡 중요한 내용"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // 콜아웃은 배경색이 적용되어야 함
        let attrs = ts.attributes(at: 4, effectiveRange: nil)
        let bg = attrs[.backgroundColor] as? NSColor
        #expect(bg != nil)
    }

    @Test func blockquote_without_emoji_has_no_background() {
        let text = "> 일반 인용문"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 2, effectiveRange: nil)
        let bg = attrs[.backgroundColor] as? NSColor
        #expect(bg == nil)
    }

    // MARK: - 비순서 리스트

    @Test func unordered_list_marker_colored() {
        let text = "- 항목"
        let attrs = applyAndGetAttributes(text, at: 0)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.listMarkerColor)
    }

    // MARK: - 순서 리스트

    @Test func ordered_list_marker_colored() {
        let text = "1. 항목"
        let attrs = applyAndGetAttributes(text, at: 0)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.listMarkerColor)
    }

    // MARK: - 체크박스 미체크 (isCheckbox 분기)

    @Test func unchecked_checkbox_renders() {
        let text = "- [ ] 할 일"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        let isCheckbox = attrs[MarkdownRenderer.isCheckboxKey] as? Bool
        #expect(color == MarkdownRenderer.checkboxColor)
        #expect(isCheckbox == true)
    }

    // MARK: - 체크박스 체크됨 (취소선 분기)

    @Test func checked_checkbox_renders_with_strikethrough() {
        let text = "- [x] 완료된 일"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // 마커 부분
        let markerAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((markerAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.checkboxColor)
        // "완료된 일" 부분 - 취소선
        let contentAttrs = ts.attributes(at: 6, effectiveRange: nil)
        let strikeStyle = contentAttrs[.strikethroughStyle] as? Int
        #expect(strikeStyle == NSUnderlineStyle.single.rawValue)
    }

    // MARK: - 리스트: 체크박스 라인은 리스트 마커 색상을 적용하지 않음

    @Test func checkbox_line_does_not_get_list_marker_color() {
        let text = "- [ ] 할일\n- 일반 항목"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // 체크박스 라인의 "-"는 checkboxColor여야 함
        let cbAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((cbAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.checkboxColor)
        // 일반 리스트 항목의 "-"는 listMarkerColor
        let listStart = (text as NSString).range(of: "- 일반").location
        let listAttrs = ts.attributes(at: listStart, effectiveRange: nil)
        #expect((listAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.listMarkerColor)
    }

    // MARK: - 토글

    @Test func toggle_closed_renders() {
        let text = "▶ 토글 내용"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((attrs[.foregroundColor] as? NSColor) == MarkdownRenderer.toggleColor)
        #expect((attrs[MarkdownRenderer.isToggleKey] as? Bool) == true)
    }

    @Test func toggle_open_renders() {
        let text = "▼ 열린 토글"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((attrs[.foregroundColor] as? NSColor) == MarkdownRenderer.toggleColor)
    }

    // MARK: - 수평선

    @Test func horizontal_rule_renders() {
        let text = "---"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        let strikeStyle = attrs[.strikethroughStyle] as? Int
        #expect(color == MarkdownRenderer.syntaxColor)
        #expect(strikeStyle == NSUnderlineStyle.single.rawValue)
    }

    @Test func horizontal_rule_asterisks() {
        let text = "***"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        let strikeStyle = attrs[.strikethroughStyle] as? Int
        #expect(strikeStyle == NSUnderlineStyle.single.rawValue)
    }

    // MARK: - 코드 블록

    @Test func code_block_renders() {
        let text = "```\nhello\n```"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // fence marker
        let fenceAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((fenceAttrs[MarkdownRenderer.isCodeBlockKey] as? Bool) == true)
        #expect((fenceAttrs[.font] as? NSFont) == MarkdownRenderer.codeFont)
        // code content "hello"
        let contentStart = (text as NSString).range(of: "hello").location
        let contentAttrs = ts.attributes(at: contentStart, effectiveRange: nil)
        #expect((contentAttrs[.font] as? NSFont) == MarkdownRenderer.codeFont)
        #expect((contentAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.codeColor)
        #expect((contentAttrs[.backgroundColor] as? NSColor) == MarkdownRenderer.codeBgColor)
    }

    // MARK: - 코드블록 내부 마크다운 무시

    @Test func markdown_inside_codeblock_not_styled() {
        let text = "```\n# 이건 헤더가 아님\n**볼드 아님**\n```"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let hashLoc = (text as NSString).range(of: "#").location
        let attrs = ts.attributes(at: hashLoc, effectiveRange: nil)
        // 코드블록 내부이므로 h1Font가 아닌 codeFont
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.codeFont)
    }

    // MARK: - 표

    @Test func table_row_monospaced() {
        let text = "| 열1 | 열2 |"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 2, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.codeFont)
    }

    @Test func table_pipe_colored() {
        let text = "| A | B |"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)  // first "|"
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.tableColor)
    }

    // MARK: - 페이지 링크

    @Test func page_link_renders() {
        let text = "[[페이지명]]"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // "[[" 부분
        let openAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((openAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
        // "페이지명" 부분
        let nameStart = (text as NSString).range(of: "페이지명").location
        let nameAttrs = ts.attributes(at: nameStart, effectiveRange: nil)
        #expect((nameAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.pageLinkColor)
        let underline = nameAttrs[.underlineStyle] as? Int
        #expect(underline == NSUnderlineStyle.single.rawValue)
    }

    @Test func page_link_closing_brackets_dimmed() {
        let text = "[[링크]]"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let closeStart = (text as NSString).range(of: "]]").location
        let attrs = ts.attributes(at: closeStart, effectiveRange: nil)
        #expect((attrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
    }

    // MARK: - 링크

    @Test func link_renders() {
        let text = "[텍스트](https://example.com)"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // 링크 텍스트
        let textStart = (text as NSString).range(of: "텍스트").location
        let linkAttrs = ts.attributes(at: textStart, effectiveRange: nil)
        #expect((linkAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.linkColor)
        #expect((linkAttrs[.underlineStyle] as? Int) == NSUnderlineStyle.single.rawValue)
    }

    // MARK: - 복합 마크다운 테스트

    @Test func multiline_mixed_markdown() {
        let text = """
        # 제목
        일반 텍스트 **볼드** *이탤릭*
        - 항목 1
        - [ ] 할일
        > 인용문
        ---
        """
        let ts = makeTextStorage(text)
        // 에러 없이 실행되어야 함
        MarkdownRenderer.applyStyles(to: ts)
        #expect(ts.string == text)
    }

    // MARK: - 폰트 static 프로퍼티 non-nil

    @Test func static_fonts_are_not_nil() {
        #expect(MarkdownRenderer.bodyFont.pointSize == 14)
        #expect(MarkdownRenderer.bodyBoldFont.pointSize == 14)
        #expect(MarkdownRenderer.bodyItalicFont.pointSize > 0)
        #expect(MarkdownRenderer.bodyBoldItalicFont.pointSize > 0)
        #expect(MarkdownRenderer.h1Font.pointSize == 26)
        #expect(MarkdownRenderer.h2Font.pointSize == 22)
        #expect(MarkdownRenderer.h3Font.pointSize == 18)
        #expect(MarkdownRenderer.codeFont.pointSize == 13)
    }

    // MARK: - 색상 static 프로퍼티 non-nil

    @Test func static_colors_are_not_nil() {
        #expect(MarkdownRenderer.textColor == NSColor.textColor)
        #expect(MarkdownRenderer.syntaxColor == NSColor.tertiaryLabelColor)
        #expect(MarkdownRenderer.codeColor == NSColor.systemPurple)
        #expect(MarkdownRenderer.quoteColor == NSColor.secondaryLabelColor)
        #expect(MarkdownRenderer.linkColor == NSColor.systemBlue)
        #expect(MarkdownRenderer.listMarkerColor == NSColor.systemOrange)
        #expect(MarkdownRenderer.checkboxColor == NSColor.systemGreen)
        #expect(MarkdownRenderer.toggleColor == NSColor.systemBlue)
        #expect(MarkdownRenderer.pageLinkColor == NSColor.systemIndigo)
        #expect(MarkdownRenderer.tableColor == NSColor.systemGray)
    }

    // MARK: - 볼드 __ 마커 (대체 구문)

    @Test func bold_with_underscores_renders() {
        let text = "__볼드__"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 2, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.bodyBoldFont)
    }

    @Test func bold_underscore_markers_dimmed() {
        let text = "__볼드__"
        let attrs = applyAndGetAttributes(text, at: 0)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.syntaxColor)
    }

    // MARK: - 비순서 리스트: * 및 + 접두사 분기

    @Test func unordered_list_asterisk_marker_colored() {
        let text = "* 항목"
        let attrs = applyAndGetAttributes(text, at: 0)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.listMarkerColor)
    }

    @Test func unordered_list_plus_marker_colored() {
        let text = "+ 항목"
        let attrs = applyAndGetAttributes(text, at: 0)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.listMarkerColor)
    }

    // MARK: - 들여쓴 리스트 마커

    @Test func indented_unordered_list_marker_colored() {
        let text = "  - 들여쓴 항목"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 2, effectiveRange: nil) // "-" 위치
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.listMarkerColor)
    }

    @Test func indented_ordered_list_marker_colored() {
        let text = "  1. 들여쓴 항목"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 2, effectiveRange: nil) // "1" 위치
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.listMarkerColor)
    }

    // MARK: - 코드블록: 언어 지정자

    @Test func code_block_with_language_renders() {
        let text = "```swift\nlet x = 1\n```"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // fence marker
        let fenceAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((fenceAttrs[MarkdownRenderer.isCodeBlockKey] as? Bool) == true)
        // content
        let contentStart = (text as NSString).range(of: "let").location
        let contentAttrs = ts.attributes(at: contentStart, effectiveRange: nil)
        #expect((contentAttrs[.font] as? NSFont) == MarkdownRenderer.codeFont)
        #expect((contentAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.codeColor)
    }

    // MARK: - 다중 코드블록

    @Test func multiple_code_blocks() {
        let text = "```\nfirst\n```\n일반 텍스트\n```\nsecond\n```"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // 첫 번째 블록
        let first = (text as NSString).range(of: "first").location
        let firstAttrs = ts.attributes(at: first, effectiveRange: nil)
        #expect((firstAttrs[MarkdownRenderer.isCodeBlockKey] as? Bool) == true)
        // 일반 텍스트 (코드블록 아님)
        let normalStart = (text as NSString).range(of: "일반").location
        let normalAttrs = ts.attributes(at: normalStart, effectiveRange: nil)
        let isCode = normalAttrs[MarkdownRenderer.isCodeBlockKey] as? Bool
        #expect(isCode != true)
        // 두 번째 블록
        let second = (text as NSString).range(of: "second").location
        let secondAttrs = ts.attributes(at: second, effectiveRange: nil)
        #expect((secondAttrs[MarkdownRenderer.isCodeBlockKey] as? Bool) == true)
    }

    // MARK: - 코드블록 내부 인라인 스타일 무시 (excluding 로직)

    @Test func inline_code_inside_codeblock_not_styled() {
        let text = "```\n`inline`\n```"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let loc = (text as NSString).range(of: "inline").location
        let attrs = ts.attributes(at: loc, effectiveRange: nil)
        // 코드블록 내부이므로 codeFont (inline code가 아닌 code block 스타일)
        #expect((attrs[MarkdownRenderer.isCodeBlockKey] as? Bool) == true)
    }

    @Test func link_inside_codeblock_not_styled() {
        let text = "```\n[link](url)\n```"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let loc = (text as NSString).range(of: "link").location
        let attrs = ts.attributes(at: loc, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        // 코드블록 내부이므로 linkColor가 아닌 codeColor
        #expect(color == MarkdownRenderer.codeColor)
    }

    // MARK: - 표 구분행

    @Test func table_separator_row_monospaced() {
        let text = "| --- | --- | --- |"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 2, effectiveRange: nil) // "-" 위치
        let font = attrs[.font] as? NSFont
        #expect(font == MarkdownRenderer.codeFont)
    }

    // MARK: - 다중행 표

    @Test func multiline_table() {
        let text = "| 열 1 | 열 2 |\n| --- | --- |\n| A | B |"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // 마지막 행 "| A |" 부분
        let aLoc = (text as NSString).range(of: "| A").location
        let attrs = ts.attributes(at: aLoc, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.tableColor) // pipe 색상
    }

    // MARK: - 링크 URL 부분 스타일

    @Test func link_url_portion_styled() {
        let text = "[텍스트](https://example.com)"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let urlStart = (text as NSString).range(of: "https").location
        let urlAttrs = ts.attributes(at: urlStart, effectiveRange: nil)
        #expect((urlAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
        let font = urlAttrs[.font] as? NSFont
        #expect(font?.pointSize == 12) // 작은 폰트
    }

    @Test func link_brackets_dimmed() {
        let text = "[텍스트](https://example.com)"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // "[" 위치
        let openAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((openAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
        // ")" 위치
        let closeLoc = (text as NSString).length - 1
        let closeAttrs = ts.attributes(at: closeLoc, effectiveRange: nil)
        #expect((closeAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
    }

    // MARK: - 수평선 ___ (언더스코어)

    @Test func horizontal_rule_underscores() {
        let text = "___"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        let strikeStyle = attrs[.strikethroughStyle] as? Int
        #expect(color == MarkdownRenderer.syntaxColor)
        #expect(strikeStyle == NSUnderlineStyle.single.rawValue)
    }

    // MARK: - 취소선 내용에 secondaryLabelColor 적용

    @Test func strikethrough_content_secondary_color() {
        let text = "~~삭제된 텍스트~~"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let contentStart = 2 // "삭" 위치
        let attrs = ts.attributes(at: contentStart, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == NSColor.secondaryLabelColor)
    }

    // MARK: - 체크된 체크박스 내용에 secondaryLabelColor 적용

    @Test func checked_checkbox_content_secondary_color() {
        let text = "- [x] 완료"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let contentStart = 6  // "완" 위치
        let attrs = ts.attributes(at: contentStart, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == NSColor.secondaryLabelColor)
    }

    // MARK: - 인라인 코드 백틱 마커 스타일

    @Test func inline_code_backtick_markers_styled() {
        let text = "`code`"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // 여는 백틱
        let openAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((openAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
        #expect((openAttrs[.font] as? NSFont) == MarkdownRenderer.codeFont)
        #expect((openAttrs[.backgroundColor] as? NSColor) == MarkdownRenderer.codeBgColor)
        // 닫는 백틱
        let closeAttrs = ts.attributes(at: 5, effectiveRange: nil)
        #expect((closeAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
    }

    // MARK: - 볼드이탤릭 마커 스타일

    @Test func boldItalic_markers_dimmed() {
        let text = "***내용***"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let openAttrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((openAttrs[.foregroundColor] as? NSColor) == MarkdownRenderer.syntaxColor)
        #expect((openAttrs[.font] as? NSFont) == MarkdownRenderer.bodyBoldItalicFont)
    }

    // MARK: - 콜아웃 paragraphStyle headIndent

    @Test func callout_paragraph_style_applied() {
        let text = "> 💡 중요한 내용"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 2, effectiveRange: nil)
        let ps = attrs[.paragraphStyle] as? NSParagraphStyle
        #expect(ps != nil)
        #expect(ps?.headIndent == 20)
        #expect(ps?.firstLineHeadIndent == 0)
    }

    // MARK: - 블록인용 paragraphStyle headIndent

    @Test func blockquote_paragraph_style_applied() {
        let text = "> 인용문 내용"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        let ps = attrs[.paragraphStyle] as? NSParagraphStyle
        #expect(ps != nil)
        #expect(ps?.headIndent == 20)
    }

    // MARK: - 기본 paragraphStyle (lineSpacing, paragraphSpacing)

    @Test func base_paragraph_style_applied() {
        let text = "일반 텍스트"
        let attrs = applyAndGetAttributes(text, at: 0)
        let ps = attrs[.paragraphStyle] as? NSParagraphStyle
        #expect(ps != nil)
        #expect(ps?.lineSpacing == 3)
        #expect(ps?.paragraphSpacing == 2)
    }

    // MARK: - 다중 헤더 (같은 텍스트 내)

    @Test func multiple_headers_in_text() {
        let text = "# H1\n## H2\n### H3"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // H1 내용
        let h1Loc = (text as NSString).range(of: "H1").location
        let h1Attrs = ts.attributes(at: h1Loc, effectiveRange: nil)
        #expect((h1Attrs[.font] as? NSFont) == MarkdownRenderer.h1Font)
        // H2 내용
        let h2Loc = (text as NSString).range(of: "H2").location
        let h2Attrs = ts.attributes(at: h2Loc, effectiveRange: nil)
        #expect((h2Attrs[.font] as? NSFont) == MarkdownRenderer.h2Font)
        // H3 내용
        let h3Loc = (text as NSString).range(of: "H3").location
        let h3Attrs = ts.attributes(at: h3Loc, effectiveRange: nil)
        #expect((h3Attrs[.font] as? NSFont) == MarkdownRenderer.h3Font)
    }

    // MARK: - 토글 isToggle 커스텀 키 (열린 토글)

    @Test func toggle_open_has_isToggle_key() {
        let text = "▼ 열린 토글"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        #expect((attrs[MarkdownRenderer.isToggleKey] as? Bool) == true)
    }

    // MARK: - 닫힌 코드블록이 없는 경우 (fence 미완성)

    @Test func unclosed_code_block_no_crash() {
        let text = "```\n코드 내용\n끝나지 않음"
        let ts = makeTextStorage(text)
        // crash 없이 실행되어야 함
        MarkdownRenderer.applyStyles(to: ts)
        #expect(ts.string == text)
    }

    // MARK: - 빈 체크박스 (내용 없음)

    @Test func checkbox_empty_content() {
        let text = "- [ ] "
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        let isCheckbox = attrs[MarkdownRenderer.isCheckboxKey] as? Bool
        #expect(isCheckbox == true)
    }

    // MARK: - 다중 체크박스

    @Test func multiple_checkboxes() {
        let text = "- [ ] 첫번째\n- [x] 두번째\n- [ ] 세번째"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // 첫번째 미체크
        let first = ts.attributes(at: 0, effectiveRange: nil)
        #expect((first[MarkdownRenderer.isCheckboxKey] as? Bool) == true)
        #expect((first[.foregroundColor] as? NSColor) == MarkdownRenderer.checkboxColor)
        // 두번째 체크됨
        let secondLoc = (text as NSString).range(of: "- [x]").location
        let second = ts.attributes(at: secondLoc, effectiveRange: nil)
        #expect((second[MarkdownRenderer.isCheckboxKey] as? Bool) == true)
    }

    // MARK: - 순서 리스트 다양한 번호

    @Test func ordered_list_double_digit() {
        let text = "10. 열번째"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        let attrs = ts.attributes(at: 0, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == MarkdownRenderer.listMarkerColor)
    }

    // MARK: - 페이지 링크 이름 부분만 밑줄

    @Test func page_link_name_underlined_brackets_not() {
        let text = "[[테스트 페이지]]"
        let ts = makeTextStorage(text)
        MarkdownRenderer.applyStyles(to: ts)
        // "[["에는 밑줄 없음
        let bracketAttrs = ts.attributes(at: 0, effectiveRange: nil)
        let bracketUnderline = bracketAttrs[.underlineStyle] as? Int
        #expect(bracketUnderline == nil)
        // "테스트 페이지"에는 밑줄 있음
        let nameStart = (text as NSString).range(of: "테스트").location
        let nameAttrs = ts.attributes(at: nameStart, effectiveRange: nil)
        let nameUnderline = nameAttrs[.underlineStyle] as? Int
        #expect(nameUnderline == NSUnderlineStyle.single.rawValue)
    }
}

// MARK: - Character.isEmoji 화이트박스 테스트

struct CharacterEmojiTests {

    @Test func standard_emoji_is_emoji() {
        let ch: Character = "😀"
        #expect(ch.isEmoji == true)
    }

    @Test func lightbulb_emoji_is_emoji() {
        let ch: Character = "💡"
        #expect(ch.isEmoji == true)
    }

    @Test func ascii_letter_is_not_emoji() {
        let ch: Character = "A"
        #expect(ch.isEmoji == false)
    }

    @Test func digit_is_not_emoji() {
        // 숫자는 isEmoji가 true일 수 있지만 scalar.value <= 0x238C이므로 false
        let ch: Character = "1"
        #expect(ch.isEmoji == false)
    }

    @Test func korean_char_is_not_emoji() {
        let ch: Character = "가"
        #expect(ch.isEmoji == false)
    }

    @Test func flag_emoji_is_emoji() {
        let ch: Character = "🇰🇷"
        #expect(ch.isEmoji == true)
    }

    @Test func star_symbol_not_emoji() {
        // ★ (U+2605) — scalar.value > 0x238C but isEmoji may be false
        let ch: Character = "★"
        // ★ has isEmoji=false, so it should return false
        #expect(ch.isEmoji == false)
    }
}
