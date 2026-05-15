import Foundation

public protocol EditorPersistence {
    func loadText() throws -> String
    func saveText(_ text: String) throws
}

public enum PromptPadDocumentStore {
    public static let appDirectoryName = PromptPadStyle.appName
    public static let fileName = FileEditorPersistence.defaultFileName

    public static func documentURL(inApplicationSupportDirectory supportDirectory: URL) -> URL {
        supportDirectory
            .appendingPathComponent(appDirectoryName, isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
    }
}

public struct FileEditorPersistence: EditorPersistence {
    public static let defaultFileName = "prompt.txt"

    private let fileURL: URL
    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func loadText() throws -> String {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return ""
        }

        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    public func saveText(_ text: String) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
