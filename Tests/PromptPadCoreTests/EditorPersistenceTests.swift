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

    func testEditorModelExposesSelectionState() {
        let persistence = InMemoryEditorPersistence()
        let model = PromptEditorModel(
            text: "Select **markdown**",
            selection: EditorSelection(location: 7, length: 10),
            persistence: persistence
        )

        XCTAssertEqual(model.selection, EditorSelection(location: 7, length: 10))

        model.selection = EditorSelection(location: 0, length: 6)

        XCTAssertEqual(model.selection, EditorSelection(location: 0, length: 6))
    }

    func testEditorSelectionClampsNegativeValues() {
        let selection = EditorSelection(location: -3, length: -8)

        XCTAssertEqual(selection, .zero)
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
