import AppKit
import PromptPadCore
import SwiftUI
import UniformTypeIdentifiers

@main
struct PromptPadApp: App {
    var body: some Scene {
        Window(PromptPadStyle.appName, id: "primary-editor") {
            EditorWindow()
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultSize(width: 920, height: 680)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

private struct EditorWindow: View {
    @StateObject private var editor: PromptEditorModel
    @State private var exportError: ExportError?

    init() {
        _editor = StateObject(wrappedValue: Self.makeEditorModel())
    }

    var body: some View {
        ZStack {
            Color(nsColor: .textBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

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
                        MarkdownPreviewView(markdown: editor.text)
                    }
                }
            }
        }
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
    }

    private static func makeEditorModel() -> PromptEditorModel {
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
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = format.defaultFileName
        panel.allowedContentTypes = [format.contentType]

        guard panel.runModal() == .OK, let fileURL = panel.url else {
            return
        }

        do {
            try editor.exportText(to: fileURL)
        } catch {
            exportError = ExportError(message: error.localizedDescription)
        }
    }
}

private struct ExportError: Identifiable {
    let id = UUID()
    let message: String
}

private extension PromptExportFormat {
    var contentType: UTType {
        UTType(filenameExtension: fileExtension) ?? .plainText
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
