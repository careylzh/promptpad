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

    func testEditorModelDefaultsToEditDisplayMode() {
        let model = PromptEditorModel(persistence: InMemoryEditorPersistence())

        XCTAssertEqual(model.displayMode, .edit)
    }

    func testEditorModelDisplayModeDoesNotModifyText() {
        let model = PromptEditorModel(
            text: "# Heading\n\nRaw **markdown**",
            persistence: InMemoryEditorPersistence()
        )

        model.displayMode = .preview
        model.displayMode = .edit

        XCTAssertEqual(model.text, "# Heading\n\nRaw **markdown**")
    }

    func testExportFormatsUseExpectedFileExtensions() {
        XCTAssertEqual(PromptExportFormat.markdown.defaultFileName, "prompt.md")
        XCTAssertEqual(PromptExportFormat.markdown.fileExtension, "md")
        XCTAssertEqual(PromptExportFormat.plainText.defaultFileName, "prompt.txt")
        XCTAssertEqual(PromptExportFormat.plainText.fileExtension, "txt")
    }

    func testImportFormatsUseExpectedFileExtensions() {
        XCTAssertEqual(PromptImportFormat.markdown.fileExtension, "md")
        XCTAssertEqual(PromptImportFormat.plainText.fileExtension, "txt")
    }

    func testEditorModelExportsCurrentTextExactly() throws {
        let fileURL = temporaryFileURL(fileName: "export.md")
        let model = PromptEditorModel(
            text: "# Prompt\n\nUse **this** exactly.\n",
            persistence: InMemoryEditorPersistence()
        )

        try model.exportText(to: fileURL)

        XCTAssertEqual(
            try String(contentsOf: fileURL, encoding: .utf8),
            "# Prompt\n\nUse **this** exactly.\n"
        )
    }

    func testEditorModelExportDoesNotSavePersistentDocument() throws {
        let persistence = InMemoryEditorPersistence(text: "Persistent draft")
        let fileURL = temporaryFileURL(fileName: "export.txt")
        let model = PromptEditorModel(
            text: "Exported draft",
            persistence: persistence
        )

        try model.exportText(to: fileURL)

        XCTAssertNil(persistence.savedText)
        XCTAssertEqual(persistence.text, "Persistent draft")
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "Exported draft")
    }

    func testEditorModelImportsMarkdownAndPersistsReplacement() throws {
        let fileURL = temporaryFileURL(fileName: "import.md")
        try PromptTextExport.write("# Imported\n\nMarkdown body\n", to: fileURL)
        let persistence = InMemoryEditorPersistence(text: "Existing draft")
        let model = PromptEditorModel(
            text: "Existing draft",
            persistence: persistence
        )

        try model.importText(from: fileURL)

        XCTAssertEqual(model.text, "# Imported\n\nMarkdown body\n")
        XCTAssertEqual(persistence.savedText, "# Imported\n\nMarkdown body\n")
        XCTAssertEqual(persistence.text, "# Imported\n\nMarkdown body\n")
    }

    func testEditorModelImportsPlainTextAndPersistsReplacement() throws {
        let fileURL = temporaryFileURL(fileName: "import.txt")
        try PromptTextExport.write("Imported plain text\nSecond line", to: fileURL)
        let persistence = InMemoryEditorPersistence(text: "# Existing")
        let model = PromptEditorModel(
            text: "# Existing",
            persistence: persistence
        )

        try model.importText(from: fileURL)

        XCTAssertEqual(model.text, "Imported plain text\nSecond line")
        XCTAssertEqual(persistence.savedText, "Imported plain text\nSecond line")
    }

    func testEditorSelectionClampsNegativeValues() {
        let selection = EditorSelection(location: -3, length: -8)

        XCTAssertEqual(selection, .zero)
    }

    func testMarkdownBoldWrapsSelectedTextAndPreservesSurroundingText() {
        let edit = MarkdownBoldEdit.apply(
            to: "Make this bold today",
            selection: EditorSelection(location: 5, length: 9)
        )

        XCTAssertEqual(edit.text, "Make **this bold** today")
        XCTAssertEqual(edit.selection, EditorSelection(location: 5, length: 13))
    }

    func testMarkdownBoldInsertsMarkersAndPlacesCursorBetweenThem() {
        let edit = MarkdownBoldEdit.apply(
            to: "Draft prompt",
            selection: EditorSelection(location: 6, length: 0)
        )

        XCTAssertEqual(edit.text, "Draft ****prompt")
        XCTAssertEqual(edit.selection, EditorSelection(location: 8, length: 0))
    }

    func testEditorModelAppliesMarkdownBoldToAutosavedTextState() {
        let persistence = InMemoryEditorPersistence()
        let model = PromptEditorModel(
            text: "Hello world",
            selection: EditorSelection(location: 6, length: 5),
            persistence: persistence
        )

        model.applyMarkdownBold()

        XCTAssertEqual(model.text, "Hello **world**")
        XCTAssertEqual(model.selection, EditorSelection(location: 6, length: 9))
    }

    private func temporaryFileURL(fileName: String = "prompt.txt") -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
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
