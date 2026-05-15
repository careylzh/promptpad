import Foundation
import XCTest
@testable import PromptPadCore

final class EditorPersistenceTests: XCTestCase {
    func testDocumentStoreBuildsApplicationSupportDocumentURL() {
        let supportDirectory = URL(fileURLWithPath: "/Users/example/Library/Application Support")

        let documentURL = PromptPadDocumentStore.documentURL(
            inApplicationSupportDirectory: supportDirectory
        )

        XCTAssertEqual(
            documentURL.path,
            "/Users/example/Library/Application Support/PromptPad/prompt.txt"
        )
    }

    func testFilePersistenceReturnsEmptyTextWhenFileDoesNotExist() throws {
        let persistence = FileEditorPersistence(fileURL: temporaryFileURL())

        XCTAssertEqual(try persistence.loadText(), "")
    }

    func testFilePersistenceSavesAndLoadsText() throws {
        let fileURL = temporaryFileURL()
        let persistence = FileEditorPersistence(fileURL: fileURL)

        try persistence.saveText("A reusable prompt draft")

        XCTAssertEqual(try persistence.loadText(), "A reusable prompt draft")
    }

    func testFilePersistenceCreatesMissingDirectoriesWhenSaving() throws {
        let fileURL = temporaryFileURL()
        let persistence = FileEditorPersistence(fileURL: fileURL)

        try persistence.saveText("Saved through missing directories")

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.deletingLastPathComponent().path))
        XCTAssertEqual(try persistence.loadText(), "Saved through missing directories")
    }

    func testEditorModelLoadsAndSavesThroughPersistence() throws {
        let persistence = InMemoryEditorPersistence(text: "Existing draft")
        let model = try PromptEditorModel(loadingFrom: persistence)

        XCTAssertEqual(model.text, "Existing draft")

        model.text = "Updated draft"
        try model.save()

        XCTAssertEqual(persistence.savedText, "Updated draft")
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("prompt.txt", isDirectory: false)
    }
}

private final class InMemoryEditorPersistence: EditorPersistence {
    var text: String
    var savedText: String?

    init(text: String = "") {
        self.text = text
    }

    func loadText() throws -> String {
        text
    }

    func saveText(_ text: String) throws {
        savedText = text
        self.text = text
    }
}
