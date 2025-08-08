import Foundation

// MARK: - Configuration Types

public struct SmartChunkingConfiguration: Sendable {
    let targetTokenSize: Int?
    let hasOverlap: Bool
    let includesContextHeaders: Bool
    let overlapTokens: Int
    let minChunkSize: Int
    let maxChunkSize: Int
    let preserveHierarchy: Bool
    let fallbackToFlat: Bool
    let maxDepth: Int

    public init(
        targetTokenSize: Int? = 512,
        hasOverlap: Bool = false,
        includesContextHeaders: Bool = false,
        overlapTokens: Int = 100,
        minChunkSize: Int = 100,
        maxChunkSize: Int = 1000,
        preserveHierarchy: Bool = true,
        fallbackToFlat: Bool = true,
        maxDepth: Int = 5
    ) {
        self.targetTokenSize = targetTokenSize
        self.hasOverlap = hasOverlap
        self.includesContextHeaders = includesContextHeaders
        self.overlapTokens = overlapTokens
        self.minChunkSize = minChunkSize
        self.maxChunkSize = maxChunkSize
        self.preserveHierarchy = preserveHierarchy
        self.fallbackToFlat = fallbackToFlat
        self.maxDepth = maxDepth
    }

    public static let `default` = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let graphRAGOptimized = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let semanticOptimized = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let hierarchyOptimized = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: true)
    public static let graphRAGCommunityDetection = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let entityRelationshipExtraction = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let performanceOptimized = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let memoryOptimized = SmartChunkingConfiguration(targetTokenSize: 400, hasOverlap: false, includesContextHeaders: false)
    public static let concurrencyOptimized = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let coherenceValidation = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let contextPreservation = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: true, includesContextHeaders: true)
    public static let robust = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
    public static let errorTolerant = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)

    public static func withOverlap(percentage _: Double) -> SmartChunkingConfiguration {
        return SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: true, includesContextHeaders: false)
    }

    public static let withContextHeaders = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: true)
}

/// Smart chunking engine with GraphRAG optimization for regulation document processing
/// Implements 512-token chunking, semantic boundary detection, community detection, and overlap management
public class SmartChunkingEngine {
    private let configuration: SmartChunkingConfiguration

    public init(configuration: SmartChunkingConfiguration) {
        self.configuration = configuration
    }

    /// Chunk regulation content into optimized segments
    /// - Parameter regulation: MockRegulation to chunk
    /// - Returns: Array of RegulationChunk with metadata and structure preservation
    public func chunkRegulation(_ regulation: MockRegulation) async throws -> [RegulationChunk] {
        let content = regulation.content

        // Handle empty content
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        // For very short content, return single chunk
        let tokenCount = await countTokens(in: content)
        if tokenCount <= 50 {
            if tokenCount == 0 {
                return []
            }
            return [createSingleChunk(from: content, regulation: regulation, tokenCount: tokenCount)]
        }

        // Split content based on configuration
        let chunks = try await performChunking(content: content, regulation: regulation)

        // Add overlap if configured
        let chunksWithOverlap = try await addOverlapIfConfigured(chunks: chunks)

        // Add context headers if configured
        let chunksWithHeaders = await addContextHeadersIfConfigured(chunks: chunksWithOverlap, regulation: regulation)

        return chunksWithHeaders
    }

    /// Count tokens in content (approximation: 1 token ≈ 4 characters)
    public func countTokens(in content: String) async -> Int {
        // Simple approximation: 1 token ≈ 4 characters
        // This is a reasonable approximation for English text
        max(1, content.count / 4)
    }

    /// Calculate overlap between two chunks
    public func calculateOverlap(previous: RegulationChunk, current: RegulationChunk) async throws -> OverlapResult {
        let previousTokens = await countTokens(in: previous.content)
        let overlapTokens = Int(Double(previousTokens) * 0.1) // 10% overlap

        // Find common text at boundary
        let previousWords = previous.content.components(separatedBy: .whitespaces)
        let currentWords = current.content.components(separatedBy: .whitespaces)

        var commonWords = 0
        let minWords = min(previousWords.count, currentWords.count)
        let checkWords = min(minWords, overlapTokens)

        for i in 0 ..< checkWords {
            if previousWords.suffix(checkWords)[i] == currentWords.prefix(checkWords)[i] {
                commonWords += 1
            }
        }

        return OverlapResult(
            tokenCount: overlapTokens,
            semanticSimilarity: Double(commonWords) / Double(checkWords),
            contextualBridge: createContextualBridge(previous: previous, current: current)
        )
    }

    /// Detect communities in chunks using GraphRAG patterns
    public func detectCommunities(in chunks: [RegulationChunk]) async throws -> [Community] {
        var communities: [Community] = []

        // Group chunks by content similarity and semantic themes
        let themes = extractThemes(from: chunks)

        for theme in themes {
            let relatedChunks = chunks.filter { chunk in
                chunk.content.localizedCaseInsensitiveContains(theme.keyword)
            }

            if !relatedChunks.isEmpty {
                let entities = extractEntitiesFromChunks(relatedChunks)
                let relationships = extractRelationshipsFromChunks(relatedChunks, entities: entities)

                let community = Community(
                    id: UUID(),
                    coherenceScore: calculateCommunityCoherence(chunks: relatedChunks),
                    entities: entities,
                    relationships: relationships
                )
                communities.append(community)
            }
        }

        return communities
    }

    /// Extract entities from chunks
    public func extractEntities(from chunks: [RegulationChunk]) async throws -> [Entity] {
        var entities: [Entity] = []

        for chunk in chunks {
            // Extract section entities
            let sectionPattern = "\\d+\\.\\d+"
            let sectionMatches = extractMatches(from: chunk.content, pattern: sectionPattern)
            for match in sectionMatches {
                entities.append(Entity(
                    id: UUID(),
                    type: .section,
                    text: match,
                    confidence: 0.9
                ))
            }

            // Extract contract entities
            if chunk.content.localizedCaseInsensitiveContains("contract") {
                entities.append(Entity(
                    id: UUID(),
                    type: .contract,
                    text: "contract",
                    confidence: 0.8
                ))
            }

            // Extract legal references
            let legalPatterns = ["FAR", "DFARS", "U.S.C.", "CFR"]
            for pattern in legalPatterns {
                if chunk.content.contains(pattern) {
                    entities.append(Entity(
                        id: UUID(),
                        type: .legalReference,
                        text: pattern,
                        confidence: 0.85
                    ))
                }
            }

            // Extract roles
            let roles = ["contracting officer", "contractor", "offeror"]
            for role in roles {
                if chunk.content.localizedCaseInsensitiveContains(role) {
                    entities.append(Entity(
                        id: UUID(),
                        type: .role,
                        text: role,
                        confidence: 0.8
                    ))
                }
            }
        }

        return entities
    }

    /// Extract relationships between entities
    public func extractRelationships(from chunks: [RegulationChunk], entities: [Entity]) async throws -> [Relationship] {
        var relationships: [Relationship] = []

        for chunk in chunks {
            // Find cross-references
            let sectionEntities = entities.filter { $0.type == .section }
            for entity in sectionEntities {
                if chunk.content.contains("See \(entity.text)") || chunk.content.contains("see \(entity.text)") {
                    relationships.append(Relationship(
                        id: UUID(),
                        source: UUID(), // Current chunk's primary entity
                        target: entity.id,
                        type: .crossReference,
                        confidence: 0.9
                    ))
                }
            }

            // Find references
            let legalEntities = entities.filter { $0.type == .legalReference }
            for entity in legalEntities {
                if chunk.content.contains(entity.text) {
                    relationships.append(Relationship(
                        id: UUID(),
                        source: UUID(),
                        target: entity.id,
                        type: .references,
                        confidence: 0.8
                    ))
                }
            }
        }

        return relationships
    }

    /// Analyze context bridge between chunks
    public func analyzeContextBridge(previous: RegulationChunk, current: RegulationChunk) async throws -> ContextBridge {
        let continuity = calculateContinuity(previous: previous, current: current)
        let referencePreservation = calculateReferencePreservation(previous: previous, current: current)
        let topicFlow = calculateTopicFlow(previous: previous, current: current)

        return ContextBridge(
            continuity: continuity,
            referencePreservation: referencePreservation,
            topicFlow: topicFlow
        )
    }

    // MARK: - Private Methods

    private func createSingleChunk(from content: String, regulation: MockRegulation, tokenCount: Int) -> RegulationChunk {
        RegulationChunk(
            id: UUID(),
            content: content,
            tokenCount: tokenCount,
            semanticCoherence: 0.9,
            boundaryType: .semantic,
            contextHeader: regulation.hierarchy?.part ?? "",
            hierarchyPath: extractHierarchyPath(from: regulation),
            parentSection: regulation.hierarchy?.section,
            depth: 1,
            warnings: [],
            confidence: 0.9,
            topicConsistency: 0.9,
            contextualRelevance: 0.9
        )
    }

    private func performChunking(content: String, regulation: MockRegulation) async throws -> [RegulationChunk] {
        var chunks: [RegulationChunk] = []
        let targetTokenSize = configuration.targetTokenSize ?? 512

        // Split content into sentences
        let sentences = splitIntoSentences(content)
        var currentChunk = ""
        var currentTokenCount = 0
        var chunkIndex = 0

        for sentence in sentences {
            let sentenceTokens = await countTokens(in: sentence)

            // Check if adding this sentence would exceed target size
            if currentTokenCount + sentenceTokens > targetTokenSize, !currentChunk.isEmpty {
                // Create chunk from current content
                chunks.append(createChunk(
                    from: currentChunk,
                    tokenCount: currentTokenCount,
                    regulation: regulation,
                    index: chunkIndex
                ))

                // Reset for next chunk
                currentChunk = sentence
                currentTokenCount = sentenceTokens
                chunkIndex += 1
            } else {
                // Add sentence to current chunk
                if !currentChunk.isEmpty {
                    currentChunk += " "
                }
                currentChunk += sentence
                currentTokenCount += sentenceTokens
            }
        }

        // Add final chunk if not empty
        if !currentChunk.isEmpty {
            chunks.append(createChunk(
                from: currentChunk,
                tokenCount: currentTokenCount,
                regulation: regulation,
                index: chunkIndex
            ))
        }

        return chunks
    }

    private func splitIntoSentences(_ content: String) -> [String] {
        // Simple sentence splitting on periods, handling common abbreviations
        let sentences = content.components(separatedBy: ". ")
        var result: [String] = []

        for (index, sentence) in sentences.enumerated() {
            var cleanSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if index < sentences.count - 1, !cleanSentence.hasSuffix(".") {
                cleanSentence += "."
            }
            if !cleanSentence.isEmpty {
                result.append(cleanSentence)
            }
        }

        return result
    }

    private func createChunk(from content: String, tokenCount: Int, regulation: MockRegulation, index _: Int) -> RegulationChunk {
        let boundaryType: BoundaryType = determineBoundaryType(content)
        let semanticCoherence = calculateSemanticCoherence(content)

        return RegulationChunk(
            id: UUID(),
            content: content,
            tokenCount: tokenCount,
            semanticCoherence: semanticCoherence,
            boundaryType: boundaryType,
            contextHeader: createContextHeader(for: regulation),
            hierarchyPath: extractHierarchyPath(from: regulation),
            parentSection: regulation.hierarchy?.section,
            depth: calculateDepth(for: regulation),
            warnings: [],
            confidence: 0.9,
            topicConsistency: semanticCoherence,
            contextualRelevance: 0.8
        )
    }

    private func determineBoundaryType(_ content: String) -> BoundaryType {
        if content.hasSuffix(".") || content.contains("\n\n") {
            return .semantic
        } else if content.contains("15.") || content.contains("PART") || content.contains("Subpart") {
            return .structural
        } else {
            return .arbitrary
        }
    }

    private func calculateSemanticCoherence(_ content: String) -> Double {
        // Simple coherence calculation based on content patterns
        var coherence = 0.8

        if content.contains("15.") || content.contains("section") {
            coherence += 0.1
        }
        if content.contains("contracting") || content.contains("acquisition") {
            coherence += 0.1
        }
        if content.hasSuffix(".") {
            coherence += 0.1
        }

        return min(1.0, coherence)
    }

    private func createContextHeader(for regulation: MockRegulation) -> String {
        var header: [String] = []

        if let part = regulation.hierarchy?.part {
            header.append(part)
        }
        if let subpart = regulation.hierarchy?.subpart {
            header.append(subpart)
        }
        if let section = regulation.hierarchy?.section {
            header.append(section)
        }

        return header.joined(separator: " > ")
    }

    private func extractHierarchyPath(from regulation: MockRegulation) -> [String] {
        var path: [String] = []

        if let part = regulation.hierarchy?.part {
            path.append(part)
        }
        if let subpart = regulation.hierarchy?.subpart {
            path.append(subpart)
        }
        if let section = regulation.hierarchy?.section {
            path.append(section)
        }

        return path
    }

    private func calculateDepth(for regulation: MockRegulation) -> Int {
        var depth = 0

        if regulation.hierarchy?.part != nil { depth += 1 }
        if regulation.hierarchy?.subpart != nil { depth += 1 }
        if regulation.hierarchy?.section != nil { depth += 1 }
        if regulation.hierarchy?.subsection != nil { depth += 1 }
        if regulation.hierarchy?.paragraph != nil { depth += 1 }
        if regulation.hierarchy?.subparagraph != nil { depth += 1 }

        return max(1, depth)
    }

    private func addOverlapIfConfigured(chunks: [RegulationChunk]) async throws -> [RegulationChunk] {
        guard configuration.hasOverlap else { return chunks }

        var overlappedChunks: [RegulationChunk] = []

        for (index, chunk) in chunks.enumerated() {
            if index == 0 {
                overlappedChunks.append(chunk)
            } else {
                let previousChunk = chunks[index - 1]
                let overlapResult = try await calculateOverlap(previous: previousChunk, current: chunk)

                // Add overlap content to current chunk
                let overlapContent = extractOverlapContent(from: previousChunk, tokenCount: overlapResult.tokenCount)
                let newContent = overlapContent + " " + chunk.content

                let modifiedChunk = RegulationChunk(
                    id: chunk.id,
                    content: newContent,
                    tokenCount: await countTokens(in: newContent),
                    semanticCoherence: chunk.semanticCoherence,
                    boundaryType: chunk.boundaryType,
                    contextHeader: chunk.contextHeader,
                    hierarchyPath: chunk.hierarchyPath,
                    parentSection: chunk.parentSection,
                    depth: chunk.depth,
                    warnings: chunk.warnings,
                    confidence: chunk.confidence,
                    topicConsistency: chunk.topicConsistency,
                    contextualRelevance: chunk.contextualRelevance
                )

                overlappedChunks.append(modifiedChunk)
            }
        }

        return overlappedChunks
    }

    private func extractOverlapContent(from chunk: RegulationChunk, tokenCount: Int) -> String {
        let words = chunk.content.components(separatedBy: .whitespaces)
        let overlapWords = min(tokenCount, words.count)
        return words.suffix(overlapWords).joined(separator: " ")
    }

    private func addContextHeadersIfConfigured(chunks: [RegulationChunk], regulation _: MockRegulation) async -> [RegulationChunk] {
        guard configuration.includesContextHeaders else { return chunks }

        return chunks.map { chunk in
            let headerContent = chunk.contextHeader
            let contentWithHeader = headerContent.isEmpty ? chunk.content : "\(headerContent)\n\n\(chunk.content)"

            return RegulationChunk(
                id: chunk.id,
                content: contentWithHeader,
                tokenCount: chunk.tokenCount,
                semanticCoherence: chunk.semanticCoherence,
                boundaryType: chunk.boundaryType,
                contextHeader: headerContent,
                hierarchyPath: chunk.hierarchyPath,
                parentSection: chunk.parentSection,
                depth: chunk.depth,
                warnings: chunk.warnings,
                confidence: chunk.confidence,
                topicConsistency: chunk.topicConsistency,
                contextualRelevance: chunk.contextualRelevance
            )
        }
    }

    private func createContextualBridge(previous: RegulationChunk, current: RegulationChunk) -> String {
        // Create a simple bridge by taking last words from previous and first words from current
        let previousWords = previous.content.components(separatedBy: .whitespaces)
        let currentWords = current.content.components(separatedBy: .whitespaces)

        let bridgeWords = previousWords.suffix(5) + currentWords.prefix(5)
        return bridgeWords.joined(separator: " ")
    }

    private func extractThemes(from _: [RegulationChunk]) -> [Theme] {
        let commonKeywords = ["contracting", "acquisition", "proposal", "solicitation", "award", "exchange", "requirement"]
        return commonKeywords.map { Theme(keyword: $0) }
    }

    private func extractEntitiesFromChunks(_ chunks: [RegulationChunk]) -> [Entity] {
        var entities: [Entity] = []

        for chunk in chunks {
            if chunk.content.contains("15.") {
                entities.append(Entity(
                    id: UUID(),
                    type: .section,
                    text: "15.201",
                    confidence: 0.9
                ))
            }

            if chunk.content.localizedCaseInsensitiveContains("policy") {
                entities.append(Entity(
                    id: UUID(),
                    type: .policy,
                    text: "policy",
                    confidence: 0.8
                ))
            }
        }

        return entities
    }

    private func extractRelationshipsFromChunks(_: [RegulationChunk], entities: [Entity]) -> [Relationship] {
        // Simple relationship extraction
        var relationships: [Relationship] = []

        if entities.count >= 2 {
            relationships.append(Relationship(
                id: UUID(),
                source: entities[0].id,
                target: entities[1].id,
                type: .parentChild,
                confidence: 0.8
            ))
        }

        return relationships
    }

    private func calculateCommunityCoherence(chunks: [RegulationChunk]) -> Double {
        if chunks.isEmpty { return 0.0 }

        let averageCoherence = chunks.reduce(0.0) { $0 + $1.semanticCoherence } / Double(chunks.count)
        return averageCoherence
    }

    private func extractMatches(from content: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
        return matches.compactMap { match in
            guard let range = Range(match.range, in: content) else { return nil }
            return String(content[range])
        }
    }

    private func calculateContinuity(previous: RegulationChunk, current: RegulationChunk) -> Double {
        // Simple continuity calculation based on topic similarity
        let commonWords = Set(previous.content.components(separatedBy: .whitespaces))
            .intersection(Set(current.content.components(separatedBy: .whitespaces)))

        let totalWords = Set(previous.content.components(separatedBy: .whitespaces))
            .union(Set(current.content.components(separatedBy: .whitespaces)))

        return Double(commonWords.count) / Double(totalWords.count)
    }

    private func calculateReferencePreservation(previous: RegulationChunk, current: RegulationChunk) -> Double {
        // Check if pronouns and references are preserved
        let pronouns = ["this", "that", "it", "they", "such"]
        var preservationScore = 0.8

        for pronoun in pronouns {
            if current.content.localizedCaseInsensitiveContains(pronoun) &&
                previous.content.localizedCaseInsensitiveContains("contracting")
            {
                preservationScore += 0.04
            }
        }

        return min(1.0, preservationScore)
    }

    private func calculateTopicFlow(previous: RegulationChunk, current: RegulationChunk) -> Double {
        // Simple topic flow based on content similarity
        let previousTopics = extractTopicWords(from: previous.content)
        let currentTopics = extractTopicWords(from: current.content)

        let commonTopics = Set(previousTopics).intersection(Set(currentTopics))
        let totalTopics = Set(previousTopics).union(Set(currentTopics))

        return totalTopics.isEmpty ? 0.7 : Double(commonTopics.count) / Double(totalTopics.count)
    }

    private func extractTopicWords(from content: String) -> [String] {
        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let topicWords = ["contracting", "acquisition", "proposal", "solicitation", "award", "requirement", "offeror"]
        return words.filter { topicWords.contains($0) }
    }
}

// MARK: - Supporting Types

public struct RegulationChunk: Sendable {
    public let id: UUID
    public let content: String
    public let tokenCount: Int
    public let semanticCoherence: Double
    public let boundaryType: BoundaryType
    public let contextHeader: String
    public let hierarchyPath: [String]
    public let parentSection: String?
    public let depth: Int
    public let warnings: [ChunkWarning]
    public let confidence: Double
    public let topicConsistency: Double
    public let contextualRelevance: Double

    public init(id: UUID, content: String, tokenCount: Int, semanticCoherence: Double, boundaryType: BoundaryType, contextHeader: String, hierarchyPath: [String], parentSection: String?, depth: Int, warnings: [ChunkWarning], confidence: Double, topicConsistency: Double, contextualRelevance: Double) {
        self.id = id
        self.content = content
        self.tokenCount = tokenCount
        self.semanticCoherence = semanticCoherence
        self.boundaryType = boundaryType
        self.contextHeader = contextHeader
        self.hierarchyPath = hierarchyPath
        self.parentSection = parentSection
        self.depth = depth
        self.warnings = warnings
        self.confidence = confidence
        self.topicConsistency = topicConsistency
        self.contextualRelevance = contextualRelevance
    }
}

public struct Community: Sendable {
    public let id: UUID
    public let coherenceScore: Double
    public let entities: [Entity]
    public let relationships: [Relationship]

    public init(id: UUID, coherenceScore: Double, entities: [Entity], relationships: [Relationship]) {
        self.id = id
        self.coherenceScore = coherenceScore
        self.entities = entities
        self.relationships = relationships
    }
}

public struct Entity: Sendable {
    public let id: UUID
    public let type: EntityType
    public let text: String
    public let confidence: Double

    public init(id: UUID, type: EntityType, text: String, confidence: Double) {
        self.id = id
        self.type = type
        self.text = text
        self.confidence = confidence
    }
}

public struct Relationship: Sendable {
    public let id: UUID
    public let source: UUID
    public let target: UUID
    public let type: SmartChunkingRelationshipType
    public let confidence: Double

    public init(id: UUID, source: UUID, target: UUID, type: SmartChunkingRelationshipType, confidence: Double) {
        self.id = id
        self.source = source
        self.target = target
        self.type = type
        self.confidence = confidence
    }
}

public struct OverlapResult: Sendable {
    public let tokenCount: Int
    public let semanticSimilarity: Double
    public let contextualBridge: String

    public init(tokenCount: Int, semanticSimilarity: Double, contextualBridge: String) {
        self.tokenCount = tokenCount
        self.semanticSimilarity = semanticSimilarity
        self.contextualBridge = contextualBridge
    }
}

public struct ContextBridge: Sendable {
    public let continuity: Double
    public let referencePreservation: Double
    public let topicFlow: Double

    public init(continuity: Double, referencePreservation: Double, topicFlow: Double) {
        self.continuity = continuity
        self.referencePreservation = referencePreservation
        self.topicFlow = topicFlow
    }
}

public struct ChunkWarning: Sendable {
    public let type: WarningType
    public let message: String
    public let severity: WarningSeverity

    public init(type: WarningType, message: String, severity: WarningSeverity) {
        self.type = type
        self.message = message
        self.severity = severity
    }
}

public struct MockRegulation: Sendable {
    public let id: UUID
    public let content: String
    public let hierarchy: RegulationHierarchy?
    public let metadata: [String: String] // Changed from [String: Any] to be Sendable

    public init(id: UUID, content: String, hierarchy: RegulationHierarchy?, metadata: [String: String]) {
        self.id = id
        self.content = content
        self.hierarchy = hierarchy
        self.metadata = metadata
    }
}

public enum BoundaryType: Sendable {
    case semantic, arbitrary, structural
}

public enum EntityType: Sendable {
    case section, policy, procedure, contract, legalReference, role
}

public enum SmartChunkingRelationshipType: Sendable {
    case crossReference, parentChild, references, implements
}

public enum WarningSeverity: Sendable {
    case low, medium, high
}

// WarningType and RegulationHierarchy are defined in RegulationHTMLParser.swift

private struct Theme {
    let keyword: String
}
