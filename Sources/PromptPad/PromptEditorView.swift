import PromptPadCore
import AppKit
import SwiftUI

struct PromptEditorView: View {
    @Binding var text: String
    @Binding var selection: EditorSelection

    var body: some View {
        PlainTextEditor(text: $text, selection: $selection)
            .accessibilityLabel("Prompt editor")
    }
}

private struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selection: EditorSelection

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, selection: $selection)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = MarkdownTextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.onApplyMarkdownBold = {
            context.coordinator.applyMarkdownBold()
        }
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textColor = .secondaryLabelColor
        textView.insertionPointColor = .labelColor
        textView.font = Self.editorFont()
        textView.defaultParagraphStyle = Self.paragraphStyle()
        textView.typingAttributes = Self.typingAttributes()
        textView.textContainerInset = NSSize(
            width: PromptPadStyle.editorPadding,
            height: PromptPadStyle.editorPadding
        )
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )
        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.enabledTextCheckingTypes = 0

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.requestFocusIfNeeded()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        context.coordinator.text = $text
        context.coordinator.selection = $selection

        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(Self.clampedRange(selectedRange, textLength: textView.string.utf16.count))
        }

        let expectedRange = NSRange(location: selection.location, length: selection.length)
        let clampedRange = Self.clampedRange(expectedRange, textLength: textView.string.utf16.count)
        if textView.selectedRange() != clampedRange {
            textView.setSelectedRange(clampedRange)
        }

        context.coordinator.requestFocusIfNeeded()
    }

    private static func editorFont() -> NSFont {
        NSFont(name: PromptPadStyle.editorFontName, size: PromptPadStyle.editorFontSize)
            ?? PromptPadStyle.editorFontFallbacks.lazy.compactMap {
                NSFont(name: $0, size: PromptPadStyle.editorFontSize)
            }.first
            ?? .systemFont(ofSize: PromptPadStyle.editorFontSize)
    }

    private static func paragraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = PromptPadStyle.editorLineSpacing
        return style
    }

    private static func typingAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: editorFont(),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle()
        ]
    }

    private static func clampedRange(_ range: NSRange, textLength: Int) -> NSRange {
        let location = min(max(0, range.location), textLength)
        let length = min(max(0, range.length), textLength - location)
        return NSRange(location: location, length: length)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var selection: Binding<EditorSelection>
        weak var textView: NSTextView?
        private var didRequestInitialFocus = false

        init(text: Binding<String>, selection: Binding<EditorSelection>) {
            self.text = text
            self.selection = selection
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            text.wrappedValue = textView.string
            updateSelection(from: textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            updateSelection(from: textView)
        }

        func requestFocusIfNeeded() {
            guard !didRequestInitialFocus, let textView else {
                return
            }

            DispatchQueue.main.async { [weak self, weak textView] in
                guard let self, let textView, !self.didRequestInitialFocus else {
                    return
                }

                if textView.window?.makeFirstResponder(textView) == true {
                    self.didRequestInitialFocus = true
                }
            }
        }

        func applyMarkdownBold() {
            guard let textView else {
                return
            }

            updateSelection(from: textView)
            let edit = MarkdownBoldEdit.apply(
                to: textView.string,
                selection: selection.wrappedValue
            )
            textView.string = edit.text
            textView.setSelectedRange(
                NSRange(location: edit.selection.location, length: edit.selection.length)
            )
            text.wrappedValue = edit.text
            selection.wrappedValue = edit.selection
        }

        private func updateSelection(from textView: NSTextView) {
            let range = textView.selectedRange()
            let editorSelection = EditorSelection(location: range.location, length: range.length)
            if selection.wrappedValue != editorSelection {
                selection.wrappedValue = editorSelection
            }
        }
    }
}

private final class MarkdownTextView: NSTextView {
    var onApplyMarkdownBold: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.isCommandB {
            onApplyMarkdownBold?()
            return
        }

        super.keyDown(with: event)
    }
}

private extension NSEvent {
    var isCommandB: Bool {
        let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags.subtracting([.capsLock, .numericPad, .function]) == .command
            && charactersIgnoringModifiers?.lowercased() == "b"
    }
}
