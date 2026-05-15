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
    @State private var text = ""

    var body: some View {
        ZStack {
            Color(nsColor: .textBackgroundColor)
                .ignoresSafeArea()

            TextEditor(text: $text)
                .font(.custom(PromptPadStyle.editorFontName, size: PromptPadStyle.editorFontSize))
                .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                .lineSpacing(PromptPadStyle.editorLineSpacing)
                .padding(PromptPadStyle.editorPadding)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .accessibilityLabel("Prompt editor")
        }
    }
}
