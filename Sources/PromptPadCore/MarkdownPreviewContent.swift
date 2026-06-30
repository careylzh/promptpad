import Foundation

public enum MarkdownPreviewRenderer {
    public static func attributedString(from source: String) -> AttributedString {
        (try? AttributedString(
            markdown: source,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        )) ?? AttributedString(source)
    }
}

public enum MarkdownPreviewBlock: Equatable, Sendable {
    case markdown(String)
    case heading(level: Int, text: String)
    case spacer
    case divider
    case table(MarkdownPreviewTable)
}

public struct MarkdownPreviewTable: Equatable, Sendable {
    public let headers: [String]
    public let rows: [[String]]

    public init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
    }
}

public struct MarkdownPreviewContent: Equatable, Sendable {
    public let blocks: [MarkdownPreviewBlock]

    public init(markdown: String) {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)

        var rawBlocks: [MarkdownPreviewBlock] = []
        var paragraphLines: [Substring] = []
        var emptyLineCount = 0

        func appendParagraph() {
            guard !paragraphLines.isEmpty else { return }
            rawBlocks.append(.markdown(paragraphLines.map(String.init).joined(separator: "\n")))
            paragraphLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if line.isEmpty {
                emptyLineCount += 1
                continue
            }

            if emptyLineCount >= 2 {
                appendParagraph()
                rawBlocks.append(.divider)
            } else if emptyLineCount == 1 {
                appendParagraph()
                rawBlocks.append(.spacer)
            }

            emptyLineCount = 0
            paragraphLines.append(line)
        }

        appendParagraph()
        self.blocks = rawBlocks.flatMap { block in
            guard case .markdown(let source) = block else { return [block] }
            return Self.extractHeadings(from: source)
        }.flatMap { block in
            guard case .markdown(let source) = block else { return [block] }
            return Self.extractTables(from: source)
        }
    }

    private static func extractHeadings(from source: String) -> [MarkdownPreviewBlock] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownPreviewBlock] = []
        var markdownLines: [String] = []

        func appendMarkdown() {
            guard !markdownLines.isEmpty else { return }
            blocks.append(.markdown(markdownLines.joined(separator: "\n")))
            markdownLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            let level = line.prefix { $0 == "#" }.count
            guard (1...6).contains(level), line.dropFirst(level).first == " " else {
                markdownLines.append(line)
                continue
            }
            appendMarkdown()
            blocks.append(.heading(level: level, text: String(line.dropFirst(level + 1))))
        }
        appendMarkdown()
        return blocks
    }

    private static func extractTables(from source: String) -> [MarkdownPreviewBlock] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownPreviewBlock] = []
        var markdownLines: [String] = []
        var index = 0

        func appendMarkdown() {
            guard !markdownLines.isEmpty else { return }
            blocks.append(.markdown(markdownLines.joined(separator: "\n")))
            markdownLines.removeAll(keepingCapacity: true)
        }

        while index < lines.count {
            guard index + 1 < lines.count,
                  let headers = cells(in: lines[index]),
                  let separators = cells(in: lines[index + 1]),
                  headers.count == separators.count,
                  separators.allSatisfy(isTableSeparator) else {
                markdownLines.append(lines[index])
                index += 1
                continue
            }

            appendMarkdown()
            index += 2
            var rows: [[String]] = []
            while index < lines.count, let row = cells(in: lines[index]) {
                rows.append(normalized(row: row, columnCount: headers.count))
                index += 1
            }
            blocks.append(.table(MarkdownPreviewTable(headers: headers, rows: rows)))
        }

        appendMarkdown()
        return blocks
    }

    private static func cells(in line: String) -> [String]? {
        guard line.contains("|") else { return nil }
        var content = line.trimmingCharacters(in: .whitespaces)
        if content.hasPrefix("|") { content.removeFirst() }
        if content.hasSuffix("|") { content.removeLast() }
        let cells = content.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        return cells.count >= 2 ? cells : nil
    }

    private static func isTableSeparator(_ cell: String) -> Bool {
        let marker = cell.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
        return marker.count >= 3 && marker.allSatisfy { $0 == "-" }
    }

    private static func normalized(row: [String], columnCount: Int) -> [String] {
        if row.count >= columnCount {
            return Array(row.prefix(columnCount))
        }
        return row + Array(repeating: "", count: columnCount - row.count)
    }
}
