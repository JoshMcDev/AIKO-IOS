import Foundation

/// HTML regulation processor with smart chunking and government regulation specialization
actor RegulationProcessor {
    private let maxChunkSize = 512 // tokens (roughly 2048 characters)
    private let overlapSize = 128 // tokens overlap between chunks

    init() {
        // Initialized for GREEN phase implementation
    }

    func processHTMLRegulation(
        html: String,
        source: RegulationSource
    ) async throws -> ProcessedRegulation {
        // Clean HTML and extract meaningful content
        let cleanedText = cleanHTML(html)

        // Extract metadata from the HTML/content
        let metadata = extractMetadata(from: html, source: source)

        // Perform smart chunking based on regulation structure
        let chunks = performSmartChunking(
            text: cleanedText,
            source: source,
            metadata: metadata
        )

        return ProcessedRegulation(
            chunks: chunks,
            metadata: metadata,
            source: source
        )
    }

    func processRegulation(input: TestRegulationInput) async throws -> ProcessedRegulation {
        try await processHTMLRegulation(html: input.html, source: input.source)
    }

    // MARK: - HTML Processing

    private func cleanHTML(_ html: String) -> String {
        // Remove HTML tags and normalize whitespace
        var cleaned = html

        // Remove script and style tags with their content
        cleaned = removeTagsWithContent(cleaned, tags: ["script", "style"])

        // Remove all HTML tags but preserve content
        cleaned = cleaned.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )

        // Decode common HTML entities
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
        cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "<")
        cleaned = cleaned.replacingOccurrences(of: "&gt;", with: ">")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")
        cleaned = cleaned.replacingOccurrences(of: "&apos;", with: "'")
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")

        // Normalize whitespace
        cleaned = cleaned.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }

    private func removeTagsWithContent(_ html: String, tags: [String]) -> String {
        var result = html
        for tag in tags {
            let pattern = "<\(tag)[^>]*>.*?</\(tag)>"
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        return result
    }

    // MARK: - Metadata Extraction

    private func extractMetadata(from html: String, source: RegulationSource) -> RegulationMetadata {
        let regulationNumber = extractRegulationNumber(from: html, source: source)
        let title = extractTitle(from: html)
        let subpart = extractSubpart(from: html)
        let supplement = extractSupplement(from: html)

        return RegulationMetadata(
            regulationNumber: regulationNumber,
            title: title,
            subpart: subpart,
            supplement: supplement
        )
    }

    private func extractRegulationNumber(from html: String, source: RegulationSource) -> String {
        let patterns: [String] = switch source {
        case .far:
            [
                "FAR\\s+\\d+\\.\\d+-\\d+",
                "\\d+\\.\\d+-\\d+",
            ]
        case .dfars:
            [
                "DFARS\\s+\\d+\\.\\d+-\\d+",
                "\\d+\\.\\d+-\\d+",
            ]
        case .agency:
            [
                "[A-Z]+\\s+\\d+\\.\\d+-\\d+",
                "\\d+\\.\\d+-\\d+",
            ]
        }

        for pattern in patterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                return String(html[match])
            }
        }

        return "Unknown"
    }

    private func extractTitle(from html: String) -> String {
        // Look for title in common HTML patterns
        let patterns = [
            "<title[^>]*>([^<]+)</title>",
            "<h1[^>]*>([^<]+)</h1>",
            "<h2[^>]*>([^<]+)</h2>",
        ]

        for pattern in patterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let titleMatch = html[match]
                let cleanTitle = cleanHTML(String(titleMatch))
                if !cleanTitle.isEmpty, cleanTitle.count > 5 {
                    return cleanTitle
                }
            }
        }

        return "Untitled Regulation"
    }

    private func extractSubpart(from html: String) -> String? {
        let pattern = "Subpart\\s+[A-Z]+"
        if let match = html.range(of: pattern, options: .regularExpression) {
            return String(html[match])
        }
        return nil
    }

    private func extractSupplement(from html: String) -> String? {
        let pattern = "Supplement\\s+\\d+"
        if let match = html.range(of: pattern, options: .regularExpression) {
            return String(html[match])
        }
        return nil
    }

    // MARK: - Smart Chunking

    private func performSmartChunking(
        text: String,
        source: RegulationSource,
        metadata _: RegulationMetadata
    ) -> [GraphRAGRegulationChunk] {
        // Split by logical sections first
        let sections = splitIntoSections(text, source: source)
        var chunks: [GraphRAGRegulationChunk] = []
        var chunkIndex = 0

        for section in sections {
            let sectionChunks = chunkSection(
                section,
                startingIndex: chunkIndex,
                source: source
            )
            chunks.append(contentsOf: sectionChunks)
            chunkIndex += sectionChunks.count
        }

        return chunks
    }

    private func splitIntoSections(_ text: String, source: RegulationSource) -> [RegulationSection] {
        let patterns: [String] = switch source {
        case .far:
            [
                "\\([a-z]\\)\\s+", // (a), (b), etc.
                "\\(\\d+\\)\\s+", // (1), (2), etc.
                "\\([ivx]+\\)\\s+", // (i), (ii), etc.
            ]
        case .dfars:
            [
                "\\([A-Z]\\)\\s+", // (A), (B), etc.
                "\\(\\d+\\)\\s+", // (1), (2), etc.
                "\\([ivx]+\\)\\s+", // (i), (ii), etc.
            ]
        case .agency:
            [
                "\\d+\\.\\d+\\s+", // 1.1, 1.2, etc.
                "\\([a-z]\\)\\s+", // (a), (b), etc.
                "\\(\\d+\\)\\s+", // (1), (2), etc.
            ]
        }

        var sections: [RegulationSection] = []
        let currentContent = text

        for pattern in patterns {
            let matches = findMatches(in: currentContent, pattern: pattern)
            if !matches.isEmpty {
                let splitSections = splitByPattern(currentContent, pattern: pattern)
                for (index, content) in splitSections.enumerated() {
                    let title = index < matches.count ? matches[index] : nil
                    sections.append(RegulationSection(
                        content: content,
                        title: title
                    ))
                }
                break
            }
        }

        // If no pattern matches, treat entire text as one section
        if sections.isEmpty {
            sections.append(RegulationSection(
                content: text,
                title: nil
            ))
        }

        return sections
    }

    private func findMatches(in text: String, pattern: String) -> [String] {
        var matches: [String] = []

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            // Return empty array if regex creation fails
            return []
        }

        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for result in results {
            if let range = Range(result.range, in: text) {
                matches.append(String(text[range]))
            }
        }

        return matches
    }

    private func splitByPattern(_ text: String, pattern _: String) -> [String] {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .chunked(into: maxChunkSize / 4) // Rough word-to-token estimate
            .map { $0.joined(separator: " ") }
    }

    private func chunkSection(
        _ section: RegulationSection,
        startingIndex: Int,
        source _: RegulationSource
    ) -> [GraphRAGRegulationChunk] {
        let words = section.content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        let wordsPerChunk = maxChunkSize / 4 // Rough estimate: 4 chars per token
        let overlapWords = overlapSize / 4

        var chunks: [GraphRAGRegulationChunk] = []
        var startIndex = 0
        var chunkIndex = startingIndex

        while startIndex < words.count {
            let endIndex = min(startIndex + wordsPerChunk, words.count)
            let chunkWords = Array(words[startIndex ..< endIndex])
            let content = chunkWords.joined(separator: " ")

            chunks.append(GraphRAGRegulationChunk(
                content: content,
                chunkIndex: chunkIndex,
                sectionTitle: section.title
            ))

            chunkIndex += 1
            startIndex += wordsPerChunk - overlapWords

            // Break if we wouldn't have enough content for another chunk
            if startIndex >= words.count - overlapWords {
                break
            }
        }

        return chunks
    }
}

// MARK: - Supporting Types

private struct RegulationSection {
    let content: String
    let title: String?
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
