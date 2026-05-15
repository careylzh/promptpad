import Combine
import Foundation

public final class PromptEditorModel: ObservableObject {
    @Published public var text: String
    @Published public var selection: EditorSelection

    private let persistence: EditorPersistence

    public init(
        text: String = "",
        selection: EditorSelection = .zero,
        persistence: EditorPersistence
    ) {
        self.text = text
        self.selection = selection
        self.persistence = persistence
    }

    public convenience init(loadingFrom persistence: EditorPersistence) throws {
        self.init(text: try persistence.loadText(), persistence: persistence)
    }

    public func load() throws {
        text = try persistence.loadText()
    }

    public func save() throws {
        try persistence.saveText(text)
    }

    public func applyMarkdownBold() {
        let edit = MarkdownBoldEdit.apply(to: text, selection: selection)
        text = edit.text
        selection = edit.selection
    }
}

public struct MarkdownBoldEdit: Equatable, Sendable {
    public let text: String
    public let selection: EditorSelection

    public static func apply(to text: String, selection: EditorSelection) -> MarkdownBoldEdit {
        let range = clampedRange(for: selection, in: text)
        let prefix = text[..<range.lowerBound]
        let selectedText = text[range]
        let suffix = text[range.upperBound...]
        let updatedText = "\(prefix)**\(selectedText)**\(suffix)"

        let cursorLocation: Int
        let cursorLength: Int
        let selectedLength = selectedText.utf16.count
        if selectedText.isEmpty {
            cursorLocation = selectionOffset(of: range.lowerBound, in: text) + 2
            cursorLength = 0
        } else {
            cursorLocation = selectionOffset(of: range.lowerBound, in: text)
            cursorLength = selectedLength + 4
        }

        return MarkdownBoldEdit(
            text: updatedText,
            selection: EditorSelection(location: cursorLocation, length: cursorLength)
        )
    }

    private static func clampedRange(
        for selection: EditorSelection,
        in text: String
    ) -> Range<String.Index> {
        let textLength = text.utf16.count
        let location = min(selection.location, textLength)
        let length = min(selection.length, textLength - location)
        let lowerBound = String.Index(utf16Offset: location, in: text)
        let upperBound = String.Index(utf16Offset: location + length, in: text)
        return lowerBound..<upperBound
    }

    private static func selectionOffset(of index: String.Index, in text: String) -> Int {
        index.utf16Offset(in: text)
    }
}
