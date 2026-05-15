import Foundation

public protocol EditorPersistence {
    func loadText() throws -> String
    func saveText(_ text: String) throws
}

public struct FileEditorPersistence: EditorPersistence {
    public static let defaultFileName = "prompt.txt"

    private let fileURL: URL
    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public static func applicationSupportStore(
        appDirectoryName: String = PromptPadStyle.appName,
        fileManager: FileManager = .default
    ) throws -> FileEditorPersistence {
        let supportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = supportDirectory.appendingPathComponent(appDirectoryName, isDirectory: true)
        let fileURL = appDirectory.appendingPathComponent(defaultFileName, isDirectory: false)
        return FileEditorPersistence(fileURL: fileURL, fileManager: fileManager)
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
