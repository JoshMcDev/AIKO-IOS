import Foundation
import SwiftSoup

/// SwiftSoup-based HTML parser for government regulation documents
/// Handles HTML parsing, metadata extraction, hierarchy preservation, and error handling
public class RegulationHTMLParser {
    
    // MARK: - Nested Types
    
    private struct ParsingContext {
        var errors: [ParseError] = []
        var warnings: [ParseWarning] = []
        var recoveryActions: [RecoveryAction] = []
        var confidence: Double = 1.0
        var formattedContent: NSAttributedString?
        var fallbackUsed: Bool = false
    }
    
    public init() {}

    /// Parse HTML regulation content and extract structured information
    /// - Parameter html: Raw HTML content of the regulation document
    /// - Parameter enableFallback: Whether to enable NSAttributedString fallback for complex formatting
    /// - Returns: RegulationParseResult with extracted content and metadata
    public func parseRegulationHTML(_ html: String, enableFallback: Bool = false) async throws -> RegulationParseResult {
        let context = ParsingContext()
        return try await performParsing(html: html, enableFallback: enableFallback, context: context)
    }
    
    private func performParsing(html: String, enableFallback: Bool, context: ParsingContext) async throws -> RegulationParseResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let memoryMonitor = MemoryMonitor.shared
        let initialMemory = await memoryMonitor.getCurrentUsage()

        var errors: [ParseError] = []
        let warnings: [ParseWarning] = []
        var recoveryActions: [RecoveryAction] = []
        var confidence = 1.0
        var formattedContent: NSAttributedString?
        var fallbackUsed = false

        do {
            // Parse HTML with SwiftSoup
            let doc = try SwiftSoup.parse(html)

            // Extract basic content
            let title = try extractTitle(from: doc)
            let content = try extractContent(from: doc)

            // Extract structured elements
            let headings = try extractHeadings(from: doc)
            let listItems = try extractListItems(from: doc)
            let tableData = try extractTables(from: doc)
            let metadata = try extractMetadata(from: doc, html: html)

            // Extract regulation-specific information
            let regulationNumber = extractRegulationNumber(from: doc, metadata: metadata)
            let hierarchy = extractHierarchy(from: doc)
            let crossReferences = try extractCrossReferences(from: doc)
            let effectiveDate = parseEffectiveDate(from: metadata)

            // Handle complex formatting with fallback if needed
            if enableFallback {
                formattedContent = createAttributedString(from: html)
                fallbackUsed = true
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let processingTime = endTime - startTime
            let peakMemory = await memoryMonitor.getPeakUsage()
            let memoryUsed = Double(peakMemory - initialMemory) / (1024 * 1024)

            return RegulationParseResult(
                title: title,
                content: content,
                headings: headings,
                listItems: listItems,
                tableData: tableData,
                metadata: metadata,
                regulationNumber: regulationNumber,
                hierarchy: hierarchy,
                crossReferences: crossReferences,
                effectiveDate: effectiveDate,
                confidence: confidence,
                errors: errors,
                warnings: warnings,
                recoveryActions: recoveryActions,
                processingTime: processingTime,
                memoryUsage: MemoryUsageInfo(peakMB: memoryUsed, averageMB: memoryUsed * 0.7),
                encoding: "UTF-8",
                formattedContent: formattedContent,
                fallbackUsed: fallbackUsed,
                preservedFormatting: extractFormattingInfo(from: doc, fallbackUsed: fallbackUsed),
                tables: tableData,
                lists: extractLists(from: doc),
                nestedLists: extractNestedLists(from: doc),
                nestedStructure: calculateNestedStructure(from: doc)
            )

        } catch {
            // Handle parsing errors gracefully
            errors.append(ParseError(type: .parsing, message: error.localizedDescription, location: "HTML parsing"))
            confidence = 0.3

            // Attempt basic text extraction as recovery
            let basicContent = extractBasicText(from: html)
            recoveryActions.append(RecoveryAction(type: .contentExtraction, description: "Extracted basic text content", applied: true))

            let endTime = CFAbsoluteTimeGetCurrent()
            let processingTime = endTime - startTime
            let peakMemory = await memoryMonitor.getPeakUsage()
            let memoryUsed = Double(peakMemory - initialMemory) / (1024 * 1024)

            return RegulationParseResult(
                title: "",
                content: basicContent,
                headings: [],
                listItems: [],
                tableData: [],
                metadata: ["document_type": "regulation"],
                regulationNumber: "",
                hierarchy: RegulationHierarchy(part: nil, subpart: nil, section: nil, subsection: nil, paragraph: nil, subparagraph: nil),
                crossReferences: [],
                effectiveDate: nil,
                confidence: confidence,
                errors: errors,
                warnings: warnings,
                recoveryActions: recoveryActions,
                processingTime: processingTime,
                memoryUsage: MemoryUsageInfo(peakMB: memoryUsed, averageMB: memoryUsed * 0.7),
                encoding: "UTF-8",
                formattedContent: nil,
                fallbackUsed: false,
                preservedFormatting: [],
                tables: [],
                lists: [],
                nestedLists: [],
                nestedStructure: NestedStructureInfo(maxDepth: 0, totalElements: 0)
            )
        }
    }

    // MARK: - Private Methods

    private func extractTitle(from doc: Document) throws -> String {
        if let title = try doc.select("title").first()?.text(), !title.isEmpty {
            return title
        }
        if let h1 = try doc.select("h1").first()?.text(), !h1.isEmpty {
            return h1
        }
        return ""
    }

    private func extractContent(from doc: Document) throws -> String {
        let bodyText = try doc.body()?.text() ?? ""
        return bodyText.isEmpty ? try doc.text() : bodyText
    }

    private func extractHeadings(from doc: Document) throws -> [RegulationHeading] {
        var headings: [RegulationHeading] = []

        for level in 1 ... 6 {
            let selector = "h\(level)"
            for element in try doc.select(selector) {
                guard let text = try? element.text(), !text.isEmpty else { continue }
                let id = try element.attr("id").isEmpty ? nil : element.attr("id")
                headings.append(RegulationHeading(level: level, text: text, id: id))
            }
        }

        return headings.sorted { $0.level < $1.level }
    }

    private func extractListItems(from doc: Document) throws -> [String] {
        let listItems = try doc.select("li")
        return listItems.compactMap { element in
            try? element.text()
        }
    }

    private func extractTables(from doc: Document) throws -> [RegulationTable] {
        var tables: [RegulationTable] = []

        for table in try doc.select("table") {
            let caption = try table.select("caption").first()?.text()

            let headerElements = try table.select("th")
            let headers = headerElements.compactMap { element in
                try? element.text()
            }

            var rows: [[String]] = []
            for row in try table.select("tbody tr") {
                let cells = try row.select("td").compactMap { element in
                    try? element.text()
                }
                if !cells.isEmpty {
                    rows.append(cells)
                }
            }

            tables.append(RegulationTable(
                caption: caption,
                headers: headers,
                rows: rows,
                formatting: [:]
            ))
        }

        return tables
    }

    private func extractMetadata(from doc: Document, html _: String) throws -> [String: Any] {
        var metadata: [String: Any] = ["document_type": "regulation"]

        // Extract meta tags
        for meta in try doc.select("meta") {
            let name = try meta.attr("name")
            let content = try meta.attr("content")
            if !name.isEmpty, !content.isEmpty {
                metadata[name.replacingOccurrences(of: "-", with: "_")] = content
            }
        }

        // Extract language
        if let htmlElement = try doc.select("html").first() {
            let lang = try htmlElement.attr("lang")
            if !lang.isEmpty {
                metadata["language"] = lang
            }
        }

        return metadata
    }

    private func extractRegulationNumber(from doc: Document, metadata: [String: Any]) -> String {
        // Check metadata first
        if let regNumber = metadata["regulation_number"] as? String {
            return regNumber
        }

        // Look for regulation number in spans
        if let span = try? doc.select(".part-number, .regulation-number, .reg-number").first() {
            if let text = try? span.text(), !text.isEmpty {
                return text
            }
        }

        // Extract from headings
        if let heading = try? doc.select("h1, h2").first() {
            if let text = try? heading.text() {
                if text.contains("PART") {
                    let parts = text.components(separatedBy: "—")
                    return parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                }
            }
        }

        return ""
    }

    private func extractHierarchy(from doc: Document) -> RegulationHierarchy {
        var part: String?
        var subpart: String?
        var section: String?
        var subsection: String?
        var paragraph: String?
        var subparagraph: String?

        // Extract part
        if let partElement = try? doc.select(".part-number, h1").first() {
            if let text = try? partElement.text(), text.contains("PART") {
                part = text.components(separatedBy: "—").first?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Extract subpart
        if let subpartElement = try? doc.select(".subpart-number, h2").first() {
            if let text = try? subpartElement.text(), text.contains("Subpart") {
                subpart = text.components(separatedBy: "—").first?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Extract section
        if let sectionElement = try? doc.select(".section-number, h3").first() {
            if let text = try? sectionElement.text() {
                let pattern = "\\d+\\.\\d+"
                if let range = text.range(of: pattern, options: .regularExpression) {
                    section = String(text[range])
                }
            }
        }

        // Extract subsection, paragraph, subparagraph from content
        let content = (try? doc.text()) ?? ""

        // Look for subsection patterns like "(a)"
        let subsectionPattern = "\\([a-z]\\)"
        if let range = content.range(of: subsectionPattern, options: .regularExpression) {
            subsection = String(content[range])
        }

        // Look for paragraph patterns like "(1)"
        let paragraphPattern = "\\(\\d+\\)"
        if let range = content.range(of: paragraphPattern, options: .regularExpression) {
            paragraph = String(content[range])
        }

        // Look for subparagraph patterns like "(i)"
        let subparagraphPattern = "\\([ivx]+\\)"
        if let range = content.range(of: subparagraphPattern, options: .regularExpression) {
            subparagraph = String(content[range])
        }

        return RegulationHierarchy(
            part: part,
            subpart: subpart,
            section: section,
            subsection: subsection,
            paragraph: paragraph,
            subparagraph: subparagraph
        )
    }

    private func extractCrossReferences(from doc: Document) throws -> [CrossReference] {
        var crossReferences: [CrossReference] = []
        let content = try doc.text()

        // Define patterns for different reference types
        let patterns: [(String, CrossReferenceType)] = [
            ("\\d+\\.\\d+", .section),
            ("FAR \\d+\\.\\d+-\\d+", .farReference),
            ("DFARS \\d+\\.\\d+-\\d+", .dfarReference),
            ("\\d+ CFR \\d+\\.\\d+", .cfrReference),
            ("\\d+ U\\.S\\.C\\. \\d+", .uscReference),
        ]

        for (pattern, type) in patterns {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))

            for match in matches {
                if let range = Range(match.range, in: content) {
                    let text = String(content[range])
                    let crossRef = CrossReference(
                        text: text,
                        target: text,
                        type: type,
                        isInternal: type == .section
                    )
                    crossReferences.append(crossRef)
                }
            }
        }

        return crossReferences
    }

    private func parseEffectiveDate(from metadata: [String: Any]) -> Date? {
        if let dateString = metadata["effective_date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateString)
        }
        return nil
    }

    private func createAttributedString(from html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }

        do {
            return try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )
        } catch {
            return nil
        }
    }

    private func extractFormattingInfo(from doc: Document, fallbackUsed: Bool) -> [FormattingInfo] {
        var formatting: [FormattingInfo] = []

        let formattingTags = ["b", "i", "u", "strong", "em", "sup", "sub"]

        for tag in formattingTags {
            if let elements = try? doc.select(tag), !elements.isEmpty() {
                formatting.append(FormattingInfo(
                    type: tag,
                    preserved: true,
                    fallbackUsed: fallbackUsed
                ))
            }
        }

        return formatting
    }

    private func extractLists(from doc: Document) -> [RegulationList] {
        var lists: [RegulationList] = []

        // Extract ordered lists
        if let olElements = try? doc.select("ol") {
            for ol in olElements {
                let items = (try? ol.select("li").map { try $0.text() }) ?? []
                let nestedLists = extractNestedListsFromElement(ol)
                lists.append(RegulationList(
                    type: .ordered,
                    items: items,
                    nestedLists: nestedLists
                ))
            }
        }

        // Extract unordered lists
        if let ulElements = try? doc.select("ul") {
            for ul in ulElements {
                let items = (try? ul.select("li").map { try $0.text() }) ?? []
                let nestedLists = extractNestedListsFromElement(ul)
                lists.append(RegulationList(
                    type: .unordered,
                    items: items,
                    nestedLists: nestedLists
                ))
            }
        }

        return lists
    }

    private func extractNestedListsFromElement(_: Element) -> [RegulationList] {
        // Simplified nested list extraction
        return []
    }

    private func extractNestedLists(from doc: Document) -> [NestedListStructure] {
        var nestedLists: [NestedListStructure] = []

        if let lists = try? doc.select("ol, ul") {
            for (index, list) in lists.enumerated() {
                let depth = calculateDepth(of: list)
                let type: ListType = list.tagName() == "ol" ? .ordered : .unordered

                nestedLists.append(NestedListStructure(
                    depth: depth,
                    type: type,
                    parentIndex: depth > 1 ? index - 1 : nil
                ))
            }
        }

        return nestedLists
    }

    private func calculateDepth(of element: Element) -> Int {
        var depth = 1
        var current = element.parent()

        while let parent = current {
            if parent.tagName() == "li" {
                depth += 1
            }
            current = parent.parent()
        }

        return depth
    }

    private func calculateNestedStructure(from doc: Document) -> NestedStructureInfo {
        var maxDepth = 0
        var totalElements = 0

        func traverseElement(_ element: Element, currentDepth: Int) {
            maxDepth = max(maxDepth, currentDepth)
            totalElements += 1

            let children = element.children()
            for child in children {
                traverseElement(child, currentDepth: currentDepth + 1)
            }
        }

        if let body = doc.body() {
            traverseElement(body, currentDepth: 1)
        }

        return NestedStructureInfo(maxDepth: maxDepth, totalElements: totalElements)
    }

    private func extractBasicText(from html: String) -> String {
        // Remove HTML tags for basic text extraction
        let pattern = "<[^>]+>"
        let cleanText = html.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Supporting Types

public struct RegulationParseResult {
    public let title: String
    public let content: String
    public let headings: [RegulationHeading]
    public let listItems: [String]
    public let tableData: [RegulationTable]
    public let metadata: [String: Any]
    public let regulationNumber: String
    public let hierarchy: RegulationHierarchy
    public let crossReferences: [CrossReference]
    public let effectiveDate: Date?
    public let confidence: Double
    public let errors: [ParseError]
    public let warnings: [ParseWarning]
    public let recoveryActions: [RecoveryAction]
    public let processingTime: TimeInterval
    public let memoryUsage: MemoryUsageInfo
    public let encoding: String
    public let formattedContent: NSAttributedString?
    public let fallbackUsed: Bool
    public let preservedFormatting: [FormattingInfo]
    public let tables: [RegulationTable]
    public let lists: [RegulationList]
    public let nestedLists: [NestedListStructure]
    public let nestedStructure: NestedStructureInfo

    public init(title: String, content: String, headings: [RegulationHeading], listItems: [String], tableData: [RegulationTable], metadata: [String: Any], regulationNumber: String, hierarchy: RegulationHierarchy, crossReferences: [CrossReference], effectiveDate: Date?, confidence: Double, errors: [ParseError], warnings: [ParseWarning], recoveryActions: [RecoveryAction], processingTime: TimeInterval, memoryUsage: MemoryUsageInfo, encoding: String, formattedContent: NSAttributedString?, fallbackUsed: Bool, preservedFormatting: [FormattingInfo], tables: [RegulationTable], lists: [RegulationList], nestedLists: [NestedListStructure], nestedStructure: NestedStructureInfo) {
        self.title = title
        self.content = content
        self.headings = headings
        self.listItems = listItems
        self.tableData = tableData
        self.metadata = metadata
        self.regulationNumber = regulationNumber
        self.hierarchy = hierarchy
        self.crossReferences = crossReferences
        self.effectiveDate = effectiveDate
        self.confidence = confidence
        self.errors = errors
        self.warnings = warnings
        self.recoveryActions = recoveryActions
        self.processingTime = processingTime
        self.memoryUsage = memoryUsage
        self.encoding = encoding
        self.formattedContent = formattedContent
        self.fallbackUsed = fallbackUsed
        self.preservedFormatting = preservedFormatting
        self.tables = tables
        self.lists = lists
        self.nestedLists = nestedLists
        self.nestedStructure = nestedStructure
    }
}

public struct RegulationHierarchy: Equatable, Sendable {
    public let part: String?
    public let subpart: String?
    public let section: String?
    public let subsection: String?
    public let paragraph: String?
    public let subparagraph: String?

    public init(part: String?, subpart: String?, section: String?, subsection: String?, paragraph: String?, subparagraph: String?) {
        self.part = part
        self.subpart = subpart
        self.section = section
        self.subsection = subsection
        self.paragraph = paragraph
        self.subparagraph = subparagraph
    }
}

public struct RegulationHeading {
    public let level: Int
    public let text: String
    public let id: String?

    public init(level: Int, text: String, id: String?) {
        self.level = level
        self.text = text
        self.id = id
    }
}

public struct RegulationTable {
    public let caption: String?
    public let headers: [String]
    public let rows: [[String]]
    public let formatting: [String: Any]

    public init(caption: String?, headers: [String], rows: [[String]], formatting: [String: Any]) {
        self.caption = caption
        self.headers = headers
        self.rows = rows
        self.formatting = formatting
    }
}

public struct RegulationList {
    public let type: ListType
    public let items: [String]
    public let nestedLists: [RegulationList]

    public init(type: ListType, items: [String], nestedLists: [RegulationList]) {
        self.type = type
        self.items = items
        self.nestedLists = nestedLists
    }
}

public enum ListType {
    case ordered, unordered
}

public struct CrossReference {
    public let text: String
    public let target: String
    public let type: CrossReferenceType
    public let isInternal: Bool

    public init(text: String, target: String, type: CrossReferenceType, isInternal: Bool) {
        self.text = text
        self.target = target
        self.type = type
        self.isInternal = isInternal
    }
}

public enum CrossReferenceType {
    case section, farReference, dfarReference, cfrReference, uscReference
}

public struct ParseError {
    public let type: ErrorType
    public let message: String
    public let location: String

    public init(type: ErrorType, message: String, location: String) {
        self.type = type
        self.message = message
        self.location = location
    }
}

public struct ParseWarning {
    public let type: WarningType
    public let message: String
    public let suggestion: String

    public init(type: WarningType, message: String, suggestion: String) {
        self.type = type
        self.message = message
        self.suggestion = suggestion
    }
}

public struct RecoveryAction {
    public let type: RecoveryType
    public let description: String
    public let applied: Bool

    public init(type: RecoveryType, description: String, applied: Bool) {
        self.type = type
        self.description = description
        self.applied = applied
    }
}

public struct MemoryUsageInfo {
    public let peakMB: Double
    public let averageMB: Double

    public init(peakMB: Double, averageMB: Double) {
        self.peakMB = peakMB
        self.averageMB = averageMB
    }
}

public struct FormattingInfo {
    public let type: String
    public let preserved: Bool
    public let fallbackUsed: Bool

    public init(type: String, preserved: Bool, fallbackUsed: Bool) {
        self.type = type
        self.preserved = preserved
        self.fallbackUsed = fallbackUsed
    }
}

public struct NestedListStructure {
    public let depth: Int
    public let type: ListType
    public let parentIndex: Int?

    public init(depth: Int, type: ListType, parentIndex: Int?) {
        self.depth = depth
        self.type = type
        self.parentIndex = parentIndex
    }
}

public struct NestedStructureInfo {
    public let maxDepth: Int
    public let totalElements: Int

    public init(maxDepth: Int, totalElements: Int) {
        self.maxDepth = maxDepth
        self.totalElements = totalElements
    }
}

public enum ErrorType {
    case parsing, encoding, structure
}

public enum WarningType: Sendable {
    case malformedStructure, missingMetadata, encodingIssue, memoryUsage, processingTime, qualityIssue
}

public enum RecoveryType {
    case structureRepair, encodingCorrection, contentExtraction
}
