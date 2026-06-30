import PromptPadCore
import SwiftUI
import UniformTypeIdentifiers

@main
struct PromptPadApp: App {
    var body: some Scene {
        #if os(macOS)
        Window(PromptPadStyle.appName, id: "primary-editor") {
            EditorWindow()
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultSize(width: 920, height: 680)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        #else
        WindowGroup {
            EditorWindow()
        }
        #endif
    }
}

private struct EditorWindow: View {
    @StateObject private var editor: PromptEditorModel
    @State private var exportError: ExportError?
    @State private var importError: ImportError?
    @State private var pendingImportDocument: PromptDocument?
    @State private var isConfirmingImport = false
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument = PromptDocument(text: "")
    @State private var exportFormat: PromptExportFormat = .markdown

    init() {
        _editor = StateObject(wrappedValue: Self.makeEditorModel())
    }

    var body: some View {
        ZStack {
            editorBackgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button {
                        isImporting = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderless)
                    .help("Import")
                    .padding(.top, 18)
                    .padding(.trailing, 10)

                    Menu {
                        Button("Markdown...") {
                            exportCurrentPrompt(as: .markdown)
                        }
                        Button("Plain Text...") {
                            exportCurrentPrompt(as: .plainText)
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .menuStyle(.borderlessButton)
                    .help("Export")
                    .padding(.top, 18)
                    .padding(.trailing, 10)

                    Picker("Editor mode", selection: $editor.displayMode) {
                        ForEach(EditorDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 164)
                    .padding(.top, 18)
                    .padding(.trailing, 22)
                }

                Group {
                    switch editor.displayMode {
                    case .edit:
                        PromptEditorView(text: $editor.text, selection: $editor.selection)
                    case .preview:
                        StructuredMarkdownPreviewView(markdown: editor.text)
                    }
                }
            }
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .onChange(of: editor.text) {
            try? editor.save()
        }
        .alert(item: $exportError) { error in
            Alert(
                title: Text("Export Failed"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: PromptImportFormat.allCases.map(\.contentType),
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportFormat.contentType,
            defaultFilename: exportFormat.defaultFileName
        ) { result in
            if case .failure(let error) = result {
                exportError = ExportError(message: error.localizedDescription)
            }
        }
        .alert("Replace Current Prompt?", isPresented: $isConfirmingImport, presenting: pendingImportDocument) { document in
            Button("Cancel", role: .cancel) {
                pendingImportDocument = nil
            }
            Button("Replace", role: .destructive) {
                importPrompt(document)
                pendingImportDocument = nil
            }
        } message: { _ in
            Text("Importing this file will replace the current prompt.")
        }
        .alert(item: $importError) { error in
            Alert(
                title: Text("Import Failed"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private static func makeEditorModel() -> PromptEditorModel {
        if ProcessInfo.processInfo.arguments.contains("--markdown-preview-smoke") {
            return PromptEditorModel(
                text: markdownPreviewSmokeFixture,
                displayMode: .preview,
                persistence: TransientEditorPersistence()
            )
        }

        let fileManager = FileManager.default

        do {
            let supportDirectory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let documentURL = PromptPadDocumentStore.documentURL(
                inApplicationSupportDirectory: supportDirectory
            )
            let persistence = FileEditorPersistence(fileURL: documentURL, fileManager: fileManager)
            return (try? PromptEditorModel(loadingFrom: persistence))
                ?? PromptEditorModel(persistence: persistence)
        } catch {
            preconditionFailure("Unable to resolve Application Support storage: \(error)")
        }
    }

    private func exportCurrentPrompt(as format: PromptExportFormat) {
        exportFormat = format
        exportDocument = PromptDocument(text: editor.text, contentType: format.contentType)
        isExporting = true
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        do {
            guard let fileURL = try result.get().first else {
                return
            }

            let canAccessSecurityScopedResource = fileURL.startAccessingSecurityScopedResource()
            defer {
                if canAccessSecurityScopedResource {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            let document = PromptDocument(text: try PromptTextImport.read(from: fileURL))
            if editor.text.isEmpty {
                importPrompt(document)
            } else {
                pendingImportDocument = document
                isConfirmingImport = true
            }
        } catch {
            importError = ImportError(message: error.localizedDescription)
        }
    }

    private func importPrompt(_ document: PromptDocument) {
        do {
            editor.text = document.text
            try editor.save()
            editor.selection = .zero
            editor.displayMode = .edit
        } catch {
            importError = ImportError(message: error.localizedDescription)
        }
    }
}

private struct TransientEditorPersistence: EditorPersistence {
    func loadText() throws -> String { "" }
    func saveText(_ text: String) throws {}
}

private let markdownPreviewSmokeFixture = """
# PromptPad Markdown Preview

**Bold**, *italic*, ***combined***, ~~strikethrough~~, and `inline code`.

> A blockquote with a [link](https://example.com).

- Unordered item
  - Nested item
1. Ordered item
- [ ] Pending task
- [x] Completed task

```swift
let greeting = "Hello"

print(greeting)
```

| Syntax | Status |
| --- | --- |
| Preview | Working |

---

Hard break here\\
Next line with escaped \\*markers\\* and <https://example.com>.
"""

private var editorBackgroundColor: Color {
    #if os(macOS)
    Color(nsColor: .textBackgroundColor)
    #else
    Color(uiColor: .systemBackground)
    #endif
}

private struct ExportError: Identifiable {
    let id = UUID()
    let message: String
}

private struct ImportError: Identifiable {
    let id = UUID()
    let message: String
}

private extension PromptExportFormat {
    var contentType: UTType {
        UTType(filenameExtension: fileExtension) ?? .plainText
    }
}

private extension PromptImportFormat {
    var contentType: UTType {
        UTType(filenameExtension: fileExtension) ?? .plainText
    }
}

private struct PromptDocument: FileDocument, Identifiable {
    static var readableContentTypes: [UTType] {
        PromptImportFormat.allCases.map(\.contentType)
    }

    let id = UUID()
    var text: String
    var contentType: UTType = .plainText

    init(text: String, contentType: UTType = .plainText) {
        self.text = text
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.text = text
        self.contentType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

private struct MarkdownPreviewView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            Text(Self.renderedMarkdown(from: markdown))
                .font(.custom(PromptPadStyle.editorFontName, size: PromptPadStyle.editorFontSize))
                .foregroundStyle(.secondary)
                .lineSpacing(PromptPadStyle.editorLineSpacing)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PromptPadStyle.editorPadding)
        }
        .accessibilityLabel("Markdown preview")
    }

    private static func renderedMarkdown(from markdown: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .full
                )
            )
        } catch {
            return AttributedString(markdown)
        }
    }
}
