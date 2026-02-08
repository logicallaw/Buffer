import SwiftUI
import AppKit

// MARK: - BufferTextView (NSTextView subclass)

class BufferTextView: NSTextView {
    var onCheckboxToggle: ((NSRange) -> Void)?
    var onToggleMarkerClick: ((NSRange) -> Void)?
    private let placeholderString = "/ 입력하여 블록 추가..."

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if string.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.placeholderTextColor,
                .font: NSFont.systemFont(ofSize: 14),
            ]
            let placeholder = NSAttributedString(string: placeholderString, attributes: attrs)
            let inset = textContainerInset
            let origin = textContainerOrigin
            placeholder.draw(at: NSPoint(x: inset.width + origin.x + 5, y: inset.height + origin.y))
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let charIndex = characterIndexForInsertion(at: point)
        let string = self.string as NSString

        guard charIndex < string.length else {
            super.mouseDown(with: event)
            return
        }

        // Check for checkbox click: `- [ ] ` or `- [x] `
        let lineRange = string.lineRange(for: NSRange(location: charIndex, length: 0))
        let line = string.substring(with: lineRange)

        if let checkboxRange = line.range(of: "- \\[([ x])\\]", options: .regularExpression) {
            let localRange = NSRange(checkboxRange, in: line)
            let checkCharLoc = lineRange.location + localRange.location + 3 // position of space/x inside [ ]
            let clickableStart = lineRange.location + localRange.location
            let clickableEnd = lineRange.location + localRange.location + localRange.length

            if charIndex >= clickableStart && charIndex < clickableEnd {
                let checkChar = string.substring(with: NSRange(location: checkCharLoc, length: 1))
                let replacement = checkChar == "x" ? " " : "x"
                let replaceRange = NSRange(location: checkCharLoc, length: 1)
                if shouldChangeText(in: replaceRange, replacementString: replacement) {
                    textStorage?.replaceCharacters(in: replaceRange, with: replacement)
                    didChangeText()
                }
                return
            }
        }

        // Check for toggle marker click: ▶ or ▼
        if line.hasPrefix("▶") || line.hasPrefix("▼") {
            let markerEnd = lineRange.location + 1
            if charIndex >= lineRange.location && charIndex < markerEnd {
                let currentChar = string.substring(with: NSRange(location: lineRange.location, length: 1))
                let replacement = currentChar == "▶" ? "▼" : "▶"
                let replaceRange = NSRange(location: lineRange.location, length: 1)
                if shouldChangeText(in: replaceRange, replacementString: replacement) {
                    textStorage?.replaceCharacters(in: replaceRange, with: replacement)
                    didChangeText()
                }
                return
            }
        }

        super.mouseDown(with: event)
    }
}

// MARK: - MarkdownTextView (NSViewRepresentable)

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: (() -> Void)?
    var onCreateSubPage: (() -> Void)?
    var onLinkToPage: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = BufferTextView()

        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        textView.replaceTextContainer(textContainer)

        textView.delegate = context.coordinator
        textView.font = MarkdownRenderer.bodyFont
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.textContainerInset = NSSize(width: 16, height: 12)
        textView.drawsBackground = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        textView.string = text
        textView.undoManager?.disableUndoRegistration()
        MarkdownRenderer.applyStyles(to: textView.textStorage!)
        textView.undoManager?.enableUndoRegistration()

        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? BufferTextView else { return }
        guard !context.coordinator.isUpdatingFromSwiftUI else { return }

        if textView.string != text {
            context.coordinator.isUpdatingFromSwiftUI = true
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.undoManager?.disableUndoRegistration()
            MarkdownRenderer.applyStyles(to: textView.textStorage!)
            textView.undoManager?.enableUndoRegistration()
            textView.selectedRanges = selectedRanges
            context.coordinator.isUpdatingFromSwiftUI = false
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextView
        weak var textView: BufferTextView?
        weak var scrollView: NSScrollView?
        var isUpdatingFromSwiftUI = false

        // Slash command state
        private var slashPanel: NSPanel?
        private var slashHostingView: NSHostingView<SlashCommandView>?
        private var isSlashMenuVisible = false
        private var slashStartIndex: Int = 0
        private var slashQuery: String = ""
        private var filteredCommands: [SlashCommand] = SlashCommandRegistry.commands
        private var selectedCommandIndex: Int = 0

        init(_ parent: MarkdownTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI else { return }
            guard let textView = notification.object as? BufferTextView else { return }

            parent.text = textView.string
            parent.onTextChange?()

            textView.undoManager?.disableUndoRegistration()
            MarkdownRenderer.applyStyles(to: textView.textStorage!)
            textView.undoManager?.enableUndoRegistration()

            // Handle slash menu
            if isSlashMenuVisible {
                updateSlashQuery()
            }
        }

        // MARK: - Key handling for slash menu

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if isSlashMenuVisible {
                if commandSelector == #selector(NSResponder.moveUp(_:)) {
                    if selectedCommandIndex > 0 {
                        selectedCommandIndex -= 1
                        updateSlashPanel()
                    }
                    return true
                }
                if commandSelector == #selector(NSResponder.moveDown(_:)) {
                    if selectedCommandIndex < filteredCommands.count - 1 {
                        selectedCommandIndex += 1
                        updateSlashPanel()
                    }
                    return true
                }
                if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                    selectCurrentCommand()
                    return true
                }
                if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                    dismissSlashMenu()
                    return true
                }
            }
            return false
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString text: String?) -> Bool {
            guard let text = text else { return true }

            // Detect `/` typed at start of line or after whitespace
            if text == "/" && !isSlashMenuVisible {
                let nsString = textView.string as NSString
                // Check we're not in the middle of composing (Korean IME)
                if textView.markedRange().location == NSNotFound {
                    let isStartOfLine = range.location == 0 ||
                        nsString.substring(with: NSRange(location: range.location - 1, length: 1)) == "\n"
                    let isAfterSpace = range.location > 0 &&
                        nsString.substring(with: NSRange(location: range.location - 1, length: 1)) == " "

                    if isStartOfLine || isAfterSpace {
                        // Will show menu after the character is inserted
                        DispatchQueue.main.async { [weak self] in
                            self?.showSlashMenu(at: range.location)
                        }
                    }
                }
            }

            // If slash menu is open and user types space or newline, dismiss
            if isSlashMenuVisible && (text == "\n" || text == "\t") {
                // Let the command selector handle it
            }

            return true
        }

        // MARK: - Slash Menu Management

        private func showSlashMenu(at location: Int) {
            guard let textView = textView, let window = textView.window else { return }

            slashStartIndex = location
            slashQuery = ""
            filteredCommands = SlashCommandRegistry.commands
            selectedCommandIndex = 0
            isSlashMenuVisible = true

            // Calculate position
            let glyphIndex = textView.layoutManager?.glyphIndexForCharacter(at: location) ?? 0
            let charRect = textView.layoutManager?.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textView.textContainer!) ?? .zero

            var point = charRect.origin
            point.x += textView.textContainerInset.width + textView.textContainerOrigin.x
            point.y += charRect.height + textView.textContainerInset.height + textView.textContainerOrigin.y

            // Convert to window then screen coordinates
            let pointInView = textView.convert(point, to: nil)
            let pointOnScreen = window.convertPoint(toScreen: pointInView)

            // Create or update the panel
            if slashPanel == nil {
                let panel = NSPanel(
                    contentRect: NSRect(x: 0, y: 0, width: 260, height: 320),
                    styleMask: [.nonactivatingPanel],
                    backing: .buffered,
                    defer: true
                )
                panel.isFloatingPanel = true
                panel.hidesOnDeactivate = true
                panel.backgroundColor = .clear
                panel.hasShadow = false
                panel.level = .popUpMenu
                slashPanel = panel
            }

            updateSlashPanel()

            slashPanel?.setFrameTopLeftPoint(NSPoint(x: pointOnScreen.x, y: pointOnScreen.y))
            slashPanel?.orderFront(nil)
        }

        private func updateSlashPanel() {
            guard let panel = slashPanel else { return }

            let hostingView = NSHostingView(rootView: SlashCommandView(
                commands: filteredCommands,
                selectedIndex: selectedCommandIndex,
                onSelect: { [weak self] command in
                    self?.selectCommand(command)
                }
            ))

            panel.contentView = hostingView
            hostingView.frame = panel.contentView?.bounds ?? .zero
        }

        private func updateSlashQuery() {
            guard let textView = textView else { return }
            let nsString = textView.string as NSString

            // slashStartIndex is where `/` was inserted
            let currentLoc = textView.selectedRange().location
            let queryStart = slashStartIndex + 1 // after the `/`

            guard queryStart <= currentLoc else {
                dismissSlashMenu()
                return
            }

            let queryLength = currentLoc - queryStart
            if queryLength < 0 {
                dismissSlashMenu()
                return
            }

            if queryLength == 0 {
                slashQuery = ""
            } else {
                slashQuery = nsString.substring(with: NSRange(location: queryStart, length: queryLength))
            }

            // Check for spaces — if query contains a space that doesn't match any command, dismiss
            filteredCommands = SlashCommandRegistry.filter(by: slashQuery)
            selectedCommandIndex = 0

            if filteredCommands.isEmpty {
                dismissSlashMenu()
                return
            }

            updateSlashPanel()
        }

        private func selectCurrentCommand() {
            guard selectedCommandIndex < filteredCommands.count else {
                dismissSlashMenu()
                return
            }
            selectCommand(filteredCommands[selectedCommandIndex])
        }

        private func selectCommand(_ command: SlashCommand) {
            guard let textView = textView else { return }

            dismissSlashMenu()

            // Replace `/query` with the template
            let currentLoc = textView.selectedRange().location
            let replaceStart = slashStartIndex
            let replaceLength = currentLoc - replaceStart

            let replaceRange = NSRange(location: replaceStart, length: replaceLength)

            // Handle special commands
            if command.template == "__PAGE__" {
                // Replace slash text with empty, then trigger callback
                if textView.shouldChangeText(in: replaceRange, replacementString: "") {
                    textView.replaceCharacters(in: replaceRange, with: "")
                    textView.didChangeText()
                }
                parent.onCreateSubPage?()
                return
            }

            if command.template == "__PAGE_LINK__" {
                if textView.shouldChangeText(in: replaceRange, replacementString: "") {
                    textView.replaceCharacters(in: replaceRange, with: "")
                    textView.didChangeText()
                }
                parent.onLinkToPage?()
                return
            }

            // Normal template insertion
            if textView.shouldChangeText(in: replaceRange, replacementString: command.template) {
                textView.replaceCharacters(in: replaceRange, with: command.template)
                textView.didChangeText()
            }
        }

        private func dismissSlashMenu() {
            isSlashMenuVisible = false
            slashPanel?.orderOut(nil)
        }
    }
}
