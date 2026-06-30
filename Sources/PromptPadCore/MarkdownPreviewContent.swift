import Foundation

public enum MarkdownPreviewRenderer {
    public static func attributedString(from source: String) -> AttributedString {
        let sourceWithVisibleLineBreaks = preservingSoftLineBreaks(in: source)
        return (try? AttributedString(
            markdown: sourceWithVisibleLineBreaks,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        )) ?? AttributedString(source)
    }

    private static func preservingSoftLineBreaks(in source: String) -> String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count > 1 else { return source }

        return lines.enumerated().map { index, line in
            let value = String(line)
            guard index < lines.count - 1,
                  !value.hasSuffix("  "),
                  !value.hasSuffix("\\") else {
                return value
            }
            return value + "  "
        }.joined(separator: "\n")
    }
}

public enum MarkdownPreviewBlock: Equatable, Sendable {
    case markdown(String)
    case heading(level: Int, text: String)
    case codeBlock(language: String?, code: String)
    case blockquote(String)
    case list([MarkdownPreviewListItem])
    case image(altText: String, source: String)
    case spacer
    case divider
    case table(MarkdownPreviewTable)
}

public enum MarkdownPreviewListKind: Equatable, Sendable {
    case unordered
    case ordered
}

public enum MarkdownPreviewTaskState: Equatable, Sendable {
    case unchecked
    case checked
}

public struct MarkdownPreviewListItem: Equatable, Sendable {
    public let kind: MarkdownPreviewListKind
    public let level: Int
    public let ordinal: Int?
    public let taskState: MarkdownPreviewTaskState?
    public let text: String

    public init(kind: MarkdownPreviewListKind, level: Int, ordinal: Int? = nil, taskState: MarkdownPreviewTaskState? = nil, text: String) {
        self.kind = kind
        self.level = level
        self.ordinal = ordinal
        self.taskState = taskState
        self.text = text
    }
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
        var codeFenceLanguage: String?
        var codeLines: [String] = []

        func appendParagraph() {
            guard !paragraphLines.isEmpty else { return }
            rawBlocks.append(.markdown(paragraphLines.map(String.init).joined(separator: "\n")))
            paragraphLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if codeFenceLanguage != nil {
                if line.hasPrefix("```") {
                    rawBlocks.append(.codeBlock(language: codeFenceLanguage == "" ? nil : codeFenceLanguage, code: codeLines.joined(separator: "\n")))
                    codeFenceLanguage = nil
                    codeLines.removeAll(keepingCapacity: true)
                } else {
                    codeLines.append(String(line))
                }
                continue
            }

            if line.hasPrefix("```") {
                appendParagraph()
                let language = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                codeFenceLanguage = language
                emptyLineCount = 0
                continue
            }

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

        if codeFenceLanguage != nil {
            rawBlocks.append(.codeBlock(language: codeFenceLanguage == "" ? nil : codeFenceLanguage, code: codeLines.joined(separator: "\n")))
        }
        appendParagraph()
        self.blocks = rawBlocks.flatMap { block in
            guard case .markdown(let source) = block else { return [block] }
            return Self.extractHeadings(from: source)
        }.flatMap { block in
            guard case .markdown(let source) = block else { return [block] }
            return Self.extractBlockquotes(from: source)
        }.flatMap { block in
            guard case .markdown(let source) = block else { return [block] }
            return Self.extractImages(from: source)
        }.flatMap { block in
            guard case .markdown(let source) = block else { return [block] }
            return Self.extractHorizontalRules(from: source)
        }.flatMap { block in
            guard case .markdown(let source) = block else { return [block] }
            return Self.extractLists(from: source)
        }.flatMap { block in
            guard case .markdown(let source) = block else { return [block] }
            return Self.extractTables(from: source)
        }
    }

    private static func extractHorizontalRules(from source: String) -> [MarkdownPreviewBlock] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownPreviewBlock] = []
        var markdownLines: [String] = []

        func appendMarkdown() {
            guard !markdownLines.isEmpty else { return }
            blocks.append(.markdown(markdownLines.joined(separator: "\n")))
            markdownLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            let marker = line.filter { !$0.isWhitespace }
            let isRule = marker.count >= 3 && ["-", "*", "_"].contains(String(marker.first ?? " ")) && marker.allSatisfy { $0 == marker.first }
            if isRule {
                appendMarkdown()
                blocks.append(.divider)
            } else {
                markdownLines.append(line)
            }
        }
        appendMarkdown()
        return blocks
    }

    private static func extractImages(from source: String) -> [MarkdownPreviewBlock] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownPreviewBlock] = []
        var markdownLines: [String] = []

        func appendMarkdown() {
            guard !markdownLines.isEmpty else { return }
            blocks.append(.markdown(markdownLines.joined(separator: "\n")))
            markdownLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            guard line.hasPrefix("!["), let separator = line.range(of: "]("), line.hasSuffix(")") else {
                markdownLines.append(line)
                continue
            }
            let altStart = line.index(line.startIndex, offsetBy: 2)
            let altText = String(line[altStart..<separator.lowerBound])
            let sourceStart = separator.upperBound
            let sourceEnd = line.index(before: line.endIndex)
            let imageSource = String(line[sourceStart..<sourceEnd])
            guard !imageSource.isEmpty else {
                markdownLines.append(line)
                continue
            }
            appendMarkdown()
            blocks.append(.image(altText: altText, source: imageSource))
        }
        appendMarkdown()
        return blocks
    }

    private static func extractLists(from source: String) -> [MarkdownPreviewBlock] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownPreviewBlock] = []
        var markdownLines: [String] = []
        var listItems: [MarkdownPreviewListItem] = []

        func appendMarkdown() {
            guard !markdownLines.isEmpty else { return }
            blocks.append(.markdown(markdownLines.joined(separator: "\n")))
            markdownLines.removeAll(keepingCapacity: true)
        }
        func appendList() {
            guard !listItems.isEmpty else { return }
            blocks.append(.list(listItems))
            listItems.removeAll(keepingCapacity: true)
        }

        for line in lines {
            guard let item = listItem(from: line) else {
                appendList()
                markdownLines.append(line)
                continue
            }
            appendMarkdown()
            listItems.append(item)
        }
        appendList()
        appendMarkdown()
        return blocks
    }

    private static func listItem(from line: String) -> MarkdownPreviewListItem? {
        let indentation = line.prefix { $0 == " " || $0 == "\t" }
        let level = indentation.reduce(0) { count, character in count + (character == "\t" ? 1 : 0) } + indentation.filter { $0 == " " }.count / 2
        let trimmed = line.dropFirst(indentation.count)

        let kind: MarkdownPreviewListKind
        let ordinal: Int?
        let rawText: Substring
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
            kind = .unordered
            ordinal = nil
            rawText = trimmed.dropFirst(2)
        } else {
            let digits = trimmed.prefix { $0.isNumber }
            guard !digits.isEmpty, trimmed.dropFirst(digits.count).hasPrefix(". ") else { return nil }
            kind = .ordered
            ordinal = Int(String(digits))
            rawText = trimmed.dropFirst(digits.count + 2)
        }

        let taskState: MarkdownPreviewTaskState?
        let text: String
        if rawText.hasPrefix("[ ] ") {
            taskState = .unchecked
            text = String(rawText.dropFirst(4))
        } else if rawText.lowercased().hasPrefix("[x] ") {
            taskState = .checked
            text = String(rawText.dropFirst(4))
        } else {
            taskState = nil
            text = String(rawText)
        }
        return MarkdownPreviewListItem(kind: kind, level: level, ordinal: ordinal, taskState: taskState, text: text)
    }

    private static func extractBlockquotes(from source: String) -> [MarkdownPreviewBlock] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownPreviewBlock] = []
        var markdownLines: [String] = []
        var quoteLines: [String] = []

        func appendMarkdown() {
            guard !markdownLines.isEmpty else { return }
            blocks.append(.markdown(markdownLines.joined(separator: "\n")))
            markdownLines.removeAll(keepingCapacity: true)
        }
        func appendQuote() {
            guard !quoteLines.isEmpty else { return }
            blocks.append(.blockquote(quoteLines.joined(separator: "\n")))
            quoteLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if line == ">" || line.hasPrefix("> ") {
                appendMarkdown()
                quoteLines.append(line == ">" ? "" : String(line.dropFirst(2)))
            } else {
                appendQuote()
                markdownLines.append(line)
            }
        }
        appendQuote()
        appendMarkdown()
        return blocks
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
