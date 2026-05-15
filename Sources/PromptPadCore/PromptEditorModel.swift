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
}
