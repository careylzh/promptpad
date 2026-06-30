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
                    case .spacer:
                        Color.clear
                            .frame(height: PromptPadStyle.editorFontSize)
                    case .divider:
                        Divider()
                            .padding(.vertical, PromptPadStyle.editorLineSpacing)
                    case .table(let table):
                        tableView(table)
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

    private func tableView(_ table: MarkdownPreviewTable) -> some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                GridRow {
                    ForEach(Array(table.headers.enumerated()), id: \.offset) { _, header in
                        Text(renderedMarkdown(from: header))
                            .fontWeight(.semibold)
                    }
                }
                Divider().gridCellColumns(table.headers.count)
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(renderedMarkdown(from: cell))
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
