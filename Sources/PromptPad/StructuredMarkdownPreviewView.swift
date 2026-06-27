import PromptPadCore
import SwiftUI

struct StructuredMarkdownPreviewView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: PromptPadStyle.editorLineSpacing) {
                ForEach(Array(content.blocks.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .markdown(let source):
                        Text(renderedMarkdown(from: source))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .divider:
                        Divider()
                    }
                }
            }
            .font(.custom(PromptPadStyle.editorFontName, size: PromptPadStyle.editorFontSize))
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PromptPadStyle.editorPadding)
        }
        .accessibilityLabel("Markdown preview")
    }

    private var content: MarkdownPreviewContent {
        MarkdownPreviewContent(markdown: markdown)
    }

    private func renderedMarkdown(from source: String) -> AttributedString {
        (try? AttributedString(
            markdown: source,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        )) ?? AttributedString(source)
    }
}
