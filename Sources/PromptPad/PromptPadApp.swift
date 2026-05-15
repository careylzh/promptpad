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
        let fallbackURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PromptPad", isDirectory: true)
            .appendingPathComponent(FileEditorPersistence.defaultFileName, isDirectory: false)
        let persistence = (try? FileEditorPersistence.applicationSupportStore())
            ?? FileEditorPersistence(fileURL: fallbackURL)
        let model = (try? PromptEditorModel(loadingFrom: persistence)) ?? PromptEditorModel(persistence: persistence)
        _editor = StateObject(wrappedValue: model)
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
}
