import Foundation

public enum MarkdownPreviewBlock: Equatable, Sendable {
    case markdown(String)
    case divider
}

public struct MarkdownPreviewContent: Equatable, Sendable {
    public let blocks: [MarkdownPreviewBlock]

    public init(markdown: String) {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)

        var blocks: [MarkdownPreviewBlock] = []
        var paragraphLines: [Substring] = []
        var emptyLineCount = 0

        func appendParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.markdown(paragraphLines.map(String.init).joined(separator: "\n")))
            paragraphLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if line.isEmpty {
                emptyLineCount += 1
                continue
            }

            if emptyLineCount >= 2 {
                appendParagraph()
                blocks.append(.divider)
            } else if emptyLineCount == 1, !paragraphLines.isEmpty {
                paragraphLines.append("")
            }

            emptyLineCount = 0
            paragraphLines.append(line)
        }

        appendParagraph()
        self.blocks = blocks
    }
}
