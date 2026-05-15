import Combine
import Foundation

public final class PromptEditorModel: ObservableObject {
    @Published public var text: String

    private let persistence: EditorPersistence

    public init(text: String = "", persistence: EditorPersistence) {
        self.text = text
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
