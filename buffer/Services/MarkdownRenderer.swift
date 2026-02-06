import AppKit

struct MarkdownRenderer {

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

        // 2. Line-level patterns
        applyHeaders(to: textStorage, in: string, fullRange: fullRange)
        applyBlockquotes(to: textStorage, in: string, fullRange: fullRange)
        applyListItems(to: textStorage, in: string, fullRange: fullRange)
        applyHorizontalRules(to: textStorage, in: string, fullRange: fullRange)

        // 3. Inline patterns (order matters for overlap handling)
        applyInlineCode(to: textStorage, in: string, fullRange: fullRange)
        applyBoldItalic(to: textStorage, in: string, fullRange: fullRange)
        applyBold(to: textStorage, in: string, fullRange: fullRange)
        applyItalic(to: textStorage, in: string, fullRange: fullRange)
        applyStrikethrough(to: textStorage, in: string, fullRange: fullRange)
        applyLinks(to: textStorage, in: string, fullRange: fullRange)

        textStorage.endEditing()
    }

    // MARK: - Line-Level

    private static func applyHeaders(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        headerPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            let hashRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let level = hashRange.length

            let font: NSFont = switch level {
            case 1: h1Font
            case 2: h2Font
            default: h3Font
            }

            // Dim the # markers, apply header font to full line
            ts.addAttributes([.foregroundColor: syntaxColor, .font: font], range: hashRange)
            ts.addAttribute(.font, value: font, range: contentRange)
        }
    }

    private static func applyBlockquotes(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        blockquotePattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            let markerRange = match.range(at: 1)
            let contentRange = match.range(at: 2)

            ts.addAttribute(.foregroundColor, value: syntaxColor, range: markerRange)
            ts.addAttribute(.foregroundColor, value: quoteColor, range: contentRange)

            let style = NSMutableParagraphStyle()
            style.headIndent = 20
            style.firstLineHeadIndent = 0
            style.lineSpacing = 3
            ts.addAttribute(.paragraphStyle, value: style, range: match.range)
        }
    }

    private static func applyListItems(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        unorderedListPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            ts.addAttribute(.foregroundColor, value: listMarkerColor, range: match.range(at: 1))
        }
        orderedListPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            ts.addAttribute(.foregroundColor, value: listMarkerColor, range: match.range(at: 1))
        }
    }

    private static func applyHorizontalRules(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        horizontalRulePattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            ts.addAttributes([
                .foregroundColor: syntaxColor,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            ], range: match.range)
        }
    }

    // MARK: - Inline

    private static func applyInlineCode(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        codePattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            let openRange = match.range(at: 1)
            let codeRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            // Backticks: dimmed + code font
            for r in [openRange, closeRange] {
                ts.addAttributes([.foregroundColor: syntaxColor, .font: codeFont, .backgroundColor: codeBgColor], range: r)
            }
            // Code content
            ts.addAttributes([.font: codeFont, .foregroundColor: codeColor, .backgroundColor: codeBgColor], range: codeRange)
        }
    }

    private static func applyBoldItalic(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        boldItalicPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            let openRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            for r in [openRange, closeRange] {
                ts.addAttributes([.foregroundColor: syntaxColor, .font: bodyBoldItalicFont], range: r)
            }
            ts.addAttribute(.font, value: bodyBoldItalicFont, range: contentRange)
        }
    }

    private static func applyBold(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        boldPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            let openRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            for r in [openRange, closeRange] {
                ts.addAttributes([.foregroundColor: syntaxColor, .font: bodyBoldFont], range: r)
            }
            ts.addAttribute(.font, value: bodyBoldFont, range: contentRange)
        }
    }

    private static func applyItalic(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        italicPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            let fullMatchRange = match.range(at: 0)
            let contentRange = match.range(at: 1)

            // Opening *
            let openRange = NSRange(location: fullMatchRange.location, length: 1)
            // Closing *
            let closeLocation = fullMatchRange.location + fullMatchRange.length - 1
            let closeRange = NSRange(location: closeLocation, length: 1)

            for r in [openRange, closeRange] {
                ts.addAttributes([.foregroundColor: syntaxColor, .font: bodyItalicFont], range: r)
            }
            ts.addAttribute(.font, value: bodyItalicFont, range: contentRange)
        }
    }

    private static func applyStrikethrough(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        strikethroughPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
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

    private static func applyLinks(to ts: NSTextStorage, in string: String, fullRange: NSRange) {
        linkPattern.enumerateMatches(in: string, range: fullRange) { match, _, _ in
            guard let match else { return }
            let openBracket = match.range(at: 1)
            let linkText = match.range(at: 2)
            let middle = match.range(at: 3)
            let urlRange = match.range(at: 4)
            let closeParen = match.range(at: 5)

            // Dim syntax characters
            for r in [openBracket, middle, closeParen] {
                ts.addAttribute(.foregroundColor, value: syntaxColor, range: r)
            }
            // Link text: blue + underline
            ts.addAttributes([
                .foregroundColor: linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ], range: linkText)
            // URL: dimmed + smaller
            ts.addAttributes([
                .foregroundColor: syntaxColor,
                .font: NSFont.systemFont(ofSize: 12),
            ], range: urlRange)
        }
    }
}
