import PromptPadCore
import SwiftUI

struct PromptEditorView: View {
    @Binding var text: String

    var body: some View {
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
