import AppKit

struct MarkdownRenderer {

    // MARK: - Custom Attribute Keys

    static let isCodeBlockKey = NSAttributedString.Key("isCodeBlock")
    static let isCheckboxKey = NSAttributedString.Key("isCheckbox")
    static let isToggleKey = NSAttributedString.Key("isToggle")

    // MARK: - Fonts

    static let bodyFont = NSFont.systemFont(ofSize: 14)
    static let bodyBoldFont = NSFont.boldSystemFont(ofSize: 14)
    static let bodyItalicFont: NSFont = {
        let descriptor = bodyFont.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: 14) ?? bodyFont
    }()
    static let bodyBoldItalicFont: NSFont = {
        let descriptor = bodyFont.fontDescriptor.withSymbolicTraits([.bold, .italic])
        return NSFont(descriptor: descriptor, size: 14) ?? bodyBoldFont
    }()
    static let h1Font = NSFont.systemFont(ofSize: 26, weight: .bold)
    static let h2Font = NSFont.systemFont(ofSize: 22, weight: .bold)
    static let h3Font = NSFont.systemFont(ofSize: 18, weight: .semibold)
    static let codeFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    // MARK: - Colors

    static let textColor = NSColor.textColor
    static let syntaxColor = NSColor.tertiaryLabelColor
    static let codeColor = NSColor.systemPurple
    static let codeBgColor = NSColor.systemGray.withAlphaComponent(0.12)
    static let quoteColor = NSColor.secondaryLabelColor
    static let linkColor = NSColor.systemBlue
    static let listMarkerColor = NSColor.systemOrange
    static let checkboxColor = NSColor.systemGreen
    static let toggleColor = NSColor.systemBlue
    static let calloutBgColor = NSColor.systemYellow.withAlphaComponent(0.1)
    static let pageLinkColor = NSColor.systemIndigo
    static let tableColor = NSColor.systemGray

    // MARK: - Regex Patterns

    static let headerPattern = try! NSRegularExpression(
        pattern: "^(#{1,3})\\s+(.+)$", options: .anchorsMatchLines)
    static let boldItalicPattern = try! NSRegularExpression(
        pattern: "(\\*\\*\\*)(.+?)(\\*\\*\\*)", options: [])
    static let boldPattern = try! NSRegularExpression(
        pattern: "(\\*\\*|__)(.+?)(\\*\\*|__)", options: [])
    static let italicPattern = try! NSRegularExpression(
        pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", options: [])
    static let codePattern = try! NSRegularExpression(
        pattern: "(`)((?:[^`])+)(`)", options: [])
    static let strikethroughPattern = try! NSRegularExpression(
        pattern: "(~~)(.+?)(~~)", options: [])
    static let blockquotePattern = try! NSRegularExpression(
        pattern: "^(>)\\s+(.+)$", options: .anchorsMatchLines)
    static let unorderedListPattern = try! NSRegularExpression(
        pattern: "^(\\s*[-*+])\\s", options: .anchorsMatchLines)
    static let orderedListPattern = try! NSRegularExpression(
        pattern: "^(\\s*\\d+\\.)\\s", options: .anchorsMatchLines)
    static let linkPattern = try! NSRegularExpression(
        pattern: "(\\[)([^\\]]+)(\\]\\()([^\\)]+)(\\))", options: [])
    static let horizontalRulePattern = try! NSRegularExpression(
        pattern: "^(---+|\\*\\*\\*+|___+)\\s*$", options: .anchorsMatchLines)

    // New patterns
    static let checkboxUncheckedPattern = try! NSRegularExpression(
        pattern: "^(- \\[ \\])\\s(.*)$", options: .anchorsMatchLines)
    static let checkboxCheckedPattern = try! NSRegularExpression(
        pattern: "^(- \\[x\\])\\s(.*)$", options: .anchorsMatchLines)
    static let codeBlockPattern = try! NSRegularExpression(
        pattern: "(^```[^\\n]*\\n)([\\s\\S]*?)(^```\\s*$)", options: .anchorsMatchLines)
    static let calloutPattern = try! NSRegularExpression(
        pattern: "^(>)\\s+(\\p{Emoji_Presentation}|\\p{Emoji}\\uFE0F?)\\s+(.+)$", options: .anchorsMatchLines)
    static let togglePattern = try! NSRegularExpression(
        pattern: "^([▶▼])\\s+(.+)$", options: .anchorsMatchLines)
    static let tableRowPattern = try! NSRegularExpression(
        pattern: "^(\\|.+\\|)\\s*$", options: .anchorsMatchLines)
    static let pageLinkPattern = try! NSRegularExpression(
        pattern: "(\\[\\[)([^\\]]+)(\\]\\])", options: [])

    // MARK: - Main Entry

    static func applyStyles(to textStorage: NSTextStorage) {
        let string = textStorage.string
        guard !string.isEmpty else { return }
        let fullRange = NSRange(location: 0, length: (string as NSString).length)

        textStorage.beginEditing()

        // 1. Reset to base style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.paragraphSpacing = 2

        textStorage.setAttributes([
            .font: bodyFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ], range: fullRange)

        // 2. Code blocks first (mark them so other patterns skip)
        let codeBlockRanges = applyCodeBlocks(to: textStorage, in: string, fullRange: fullRange)

        // 3. Line-level patterns (skip code block ranges)
        applyHeaders(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyCallouts(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyBlockquotes(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyCheckboxes(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyListItems(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyToggles(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyTableRows(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyHorizontalRules(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)

        // 4. Inline patterns (skip code block ranges)
        applyInlineCode(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyBoldItalic(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyBold(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyItalic(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyStrikethrough(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyLinks(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)
        applyPageLinks(to: textStorage, in: string, fullRange: fullRange, excluding: codeBlockRanges)

        textStorage.endEditing()
    }

    // MARK: - Helper

    private static func isInExcludedRange(_ range: NSRange, excluding: [NSRange]) -> Bool {
        for excluded in excluding {
            if NSIntersectionRange(range, excluded).length > 0 {
                return true
            }
        }
        return false
    }

    // MARK: - Code Blocks

    private static func applyCodeBlocks(to ts: NSTextStorage, in string: String, fullRange: NSRange) -> [NSRange] {
        var ranges: [NSRange] = []
        codeBlockPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            let wholeRange = match.range
            let openRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            ranges.append(wholeRange)

            let blockStyle = NSMutableParagraphStyle()
            blockStyle.lineSpacing = 2
            blockStyle.paragraphSpacingBefore = 6
            blockStyle.paragraphSpacing = 6

            // Fence markers
            for r in [openRange, closeRange] {
                ts.addAttributes([
                    .foregroundColor: syntaxColor,
                    .font: codeFont,
                    isCodeBlockKey: true,
                ], range: r)
            }

            // Code content
            ts.addAttributes([
                .font: codeFont,
                .foregroundColor: codeColor,
                .backgroundColor: codeBgColor,
                isCodeBlockKey: true,
            ], range: contentRange)
        }
        return ranges
    }

    // MARK: - Line-Level

    private static func applyHeaders(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        headerPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let hashRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let level = hashRange.length

            let font: NSFont = switch level {
            case 1: h1Font
            case 2: h2Font
            default: h3Font
            }

            ts.addAttributes([.foregroundColor: syntaxColor, .font: font], range: hashRange)
            ts.addAttribute(.font, value: font, range: contentRange)
        }
    }

    private static func applyCallouts(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        calloutPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let markerRange = match.range(at: 1)

            ts.addAttribute(.foregroundColor, value: syntaxColor, range: markerRange)
            ts.addAttribute(.backgroundColor, value: calloutBgColor, range: match.range)

            let style = NSMutableParagraphStyle()
            style.headIndent = 20
            style.firstLineHeadIndent = 0
            style.lineSpacing = 3
            style.paragraphSpacingBefore = 4
            style.paragraphSpacing = 4
            ts.addAttribute(.paragraphStyle, value: style, range: match.range)
        }
    }

    private static func applyBlockquotes(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        blockquotePattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            // Skip if already handled as callout (check for emoji after >)
            let markerRange = match.range(at: 1)
            let contentRange = match.range(at: 2)

            // Check if this is a callout (emoji follows >)
            let contentStr = (string as NSString).substring(with: contentRange)
            if contentStr.first?.isEmoji == true { return }

            ts.addAttribute(.foregroundColor, value: syntaxColor, range: markerRange)
            ts.addAttribute(.foregroundColor, value: quoteColor, range: contentRange)

            let style = NSMutableParagraphStyle()
            style.headIndent = 20
            style.firstLineHeadIndent = 0
            style.lineSpacing = 3
            ts.addAttribute(.paragraphStyle, value: style, range: match.range)
        }
    }

    private static func applyCheckboxes(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        // Unchecked
        checkboxUncheckedPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let markerRange = match.range(at: 1)
            ts.addAttributes([
                .foregroundColor: checkboxColor,
                isCheckboxKey: true,
            ], range: markerRange)
        }
        // Checked
        checkboxCheckedPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let markerRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            ts.addAttributes([
                .foregroundColor: checkboxColor,
                isCheckboxKey: true,
            ], range: markerRange)
            ts.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: NSColor.secondaryLabelColor,
            ], range: contentRange)
        }
    }

    private static func applyListItems(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        unorderedListPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            // Skip checkboxes (already handled)
            let lineRange = (string as NSString).lineRange(for: match.range)
            let line = (string as NSString).substring(with: lineRange)
            if line.contains("- [ ]") || line.contains("- [x]") { return }
            ts.addAttribute(.foregroundColor, value: listMarkerColor, range: match.range(at: 1))
        }
        orderedListPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            ts.addAttribute(.foregroundColor, value: listMarkerColor, range: match.range(at: 1))
        }
    }

    private static func applyToggles(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        togglePattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let markerRange = match.range(at: 1)
            ts.addAttributes([
                .foregroundColor: toggleColor,
                isToggleKey: true,
            ], range: markerRange)
        }
    }

    private static func applyTableRows(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        tableRowPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let rowRange = match.range(at: 1)

            // Apply monospaced font to the whole row
            ts.addAttribute(.font, value: codeFont, range: rowRange)

            // Color the pipe characters
            let rowString = (string as NSString).substring(with: rowRange)
            var searchStart = 0
            while let pipeRange = rowString.range(of: "|", range: String.Index(utf16Offset: searchStart, in: rowString)..<rowString.endIndex) {
                let nsRange = NSRange(pipeRange, in: rowString)
                let absoluteRange = NSRange(location: rowRange.location + nsRange.location, length: 1)
                ts.addAttribute(.foregroundColor, value: tableColor, range: absoluteRange)
                searchStart = nsRange.location + nsRange.length
            }
        }
    }

    private static func applyHorizontalRules(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        horizontalRulePattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            ts.addAttributes([
                .foregroundColor: syntaxColor,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            ], range: match.range)
        }
    }

    // MARK: - Inline

    private static func applyInlineCode(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        codePattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let openRange = match.range(at: 1)
            let codeRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            for r in [openRange, closeRange] {
                ts.addAttributes([.foregroundColor: syntaxColor, .font: codeFont, .backgroundColor: codeBgColor], range: r)
            }
            ts.addAttributes([.font: codeFont, .foregroundColor: codeColor, .backgroundColor: codeBgColor], range: codeRange)
        }
    }

    private static func applyBoldItalic(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        boldItalicPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let openRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            for r in [openRange, closeRange] {
                ts.addAttributes([.foregroundColor: syntaxColor, .font: bodyBoldItalicFont], range: r)
            }
            ts.addAttribute(.font, value: bodyBoldItalicFont, range: contentRange)
        }
    }

    private static func applyBold(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        boldPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let openRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            for r in [openRange, closeRange] {
                ts.addAttributes([.foregroundColor: syntaxColor, .font: bodyBoldFont], range: r)
            }
            ts.addAttribute(.font, value: bodyBoldFont, range: contentRange)
        }
    }

    private static func applyItalic(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        italicPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let fullMatchRange = match.range(at: 0)
            let contentRange = match.range(at: 1)

            let openRange = NSRange(location: fullMatchRange.location, length: 1)
            let closeLocation = fullMatchRange.location + fullMatchRange.length - 1
            let closeRange = NSRange(location: closeLocation, length: 1)

            for r in [openRange, closeRange] {
                ts.addAttributes([.foregroundColor: syntaxColor, .font: bodyItalicFont], range: r)
            }
            ts.addAttribute(.font, value: bodyItalicFont, range: contentRange)
        }
    }

    private static func applyStrikethrough(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        strikethroughPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let openRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            for r in [openRange, closeRange] {
                ts.addAttribute(.foregroundColor, value: syntaxColor, range: r)
            }
            ts.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: NSColor.secondaryLabelColor,
            ], range: contentRange)
        }
    }

    private static func applyLinks(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        linkPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let openBracket = match.range(at: 1)
            let linkText = match.range(at: 2)
            let middle = match.range(at: 3)
            let urlRange = match.range(at: 4)
            let closeParen = match.range(at: 5)

            for r in [openBracket, middle, closeParen] {
                ts.addAttribute(.foregroundColor, value: syntaxColor, range: r)
            }
            ts.addAttributes([
                .foregroundColor: linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ], range: linkText)
            ts.addAttributes([
                .foregroundColor: syntaxColor,
                .font: NSFont.systemFont(ofSize: 12),
            ], range: urlRange)
        }
    }

    private static func applyPageLinks(to ts: NSTextStorage, in string: String, fullRange: NSRange, excluding: [NSRange]) {
        pageLinkPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            if isInExcludedRange(match.range, excluding: excluding) { return }
            let openRange = match.range(at: 1)
            let nameRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            for r in [openRange, closeRange] {
                ts.addAttribute(.foregroundColor, value: syntaxColor, range: r)
            }
            ts.addAttributes([
                .foregroundColor: pageLinkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ], range: nameRange)
        }
    }
}

// MARK: - Character Extension for Emoji Detection

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}
