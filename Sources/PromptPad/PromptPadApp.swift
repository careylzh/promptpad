import PromptPadCore
import SwiftUI

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

    init() {
        _editor = StateObject(wrappedValue: Self.makeEditorModel())
    }

    var body: some View {
        ZStack {
            Color(nsColor: .textBackgroundColor)
                .ignoresSafeArea()

            PromptEditorView(text: $editor.text)
        }
        .onChange(of: editor.text) {
            try? editor.save()
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
}
