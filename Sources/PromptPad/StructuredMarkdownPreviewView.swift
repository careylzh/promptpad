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
                    case .heading(let level, let text):
                        Text(renderedMarkdown(from: text))
                            .font(.system(size: headingFontSize(for: level), weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .codeBlock(let language, let code):
                        VStack(alignment: .leading, spacing: 8) {
                            if let language {
                                Text(language)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.tertiary)
                            }
                            ScrollView(.horizontal) {
                                Text(code)
                                    .font(.system(size: PromptPadStyle.editorFontSize, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    case .blockquote(let source):
                        HStack(alignment: .top, spacing: 12) {
                            Rectangle()
                                .fill(.secondary.opacity(0.45))
                                .frame(width: 3)
                            Text(renderedMarkdown(from: source))
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    case .list(let items):
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(listMarker(for: item))
                                        .font(.system(size: PromptPadStyle.editorFontSize, design: .monospaced))
                                        .frame(minWidth: 20, alignment: .trailing)
                                    Text(renderedMarkdown(from: item.text))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.leading, CGFloat(item.level) * 24)
                            }
                        }
                    case .image(let altText, let source):
                        AsyncImage(url: URL(string: source)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure:
                                Label(altText.isEmpty ? "Image unavailable" : altText, systemImage: "photo")
                                    .foregroundStyle(.tertiary)
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 360, alignment: .leading)
                        .accessibilityLabel(altText)
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
        MarkdownPreviewRenderer.attributedString(from: source)
    }

    private func headingFontSize(for level: Int) -> CGFloat {
        switch level {
        case 1: 34
        case 2: 30
        case 3: 27
        case 4: 24
        case 5: 22
        default: 20
        }
    }

    private func listMarker(for item: MarkdownPreviewListItem) -> String {
        if let taskState = item.taskState {
            return taskState == .checked ? "☑" : "☐"
        }
        switch item.kind {
        case .unordered: return "•"
        case .ordered: return "\(item.ordinal ?? 1)."
        }
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
