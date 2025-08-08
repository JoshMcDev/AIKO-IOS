import Testing
import Foundation
@testable import AIKO

/// Comprehensive unit tests for SmartChunkingEngine with GraphRAG optimization
/// Tests 512-token chunking, semantic boundaries, community detection, and overlap management
@Suite("SmartChunkingEngine Tests")
struct SmartChunkingEngineTests {

    // MARK: - Core Chunking Tests

    @Test("512-token chunk size validation")
    func test512TokenChunkSizeValidation() async throws {
        // GIVEN: Smart chunking engine with GraphRAG optimization
        let engine = SmartChunkingEngine(configuration: .graphRAGOptimized)
        let testContent = generatePreciseTokenContent(tokenCount: 2048) // Should create ~4 chunks
        let regulation = createMockRegulation(content: testContent)
        
        // WHEN: Chunking with 512-token target
        let chunks = try await engine.chunkRegulation(regulation)
        
        // THEN: Should create chunks near 512 tokens each
        #expect(chunks.count >= 3, "Should create multiple chunks for 2048 tokens")
        #expect(chunks.count <= 5, "Should not over-fragment content")
        
        for (index, chunk) in chunks.enumerated() {
            let tokenCount = await engine.countTokens(in: chunk.content)
            
            if index < chunks.count - 1 { // All but last chunk
                #expect(tokenCount >= 410 && tokenCount <= 614, "Chunk \(index) should be within ±20% of 512 tokens (was \(tokenCount))")
            } else { // Last chunk can be smaller
                #expect(tokenCount >= 50 && tokenCount <= 614, "Last chunk should be reasonable size")
            }
        }
    }

    @Test("Semantic boundary detection")
    func testSemanticBoundaryDetection() async throws {
        // GIVEN: Engine with content having clear semantic boundaries
        let engine = SmartChunkingEngine(configuration: .semanticOptimized)
        let semanticContent = """
        PART 15—CONTRACTING BY NEGOTIATION
        
        Subpart 15.1—Source Selection Processes and Techniques
        
        15.101 Best value continuum.
        (a) An agency can obtain best value in negotiated acquisitions by using any one or a combination of source selection approaches. In different types of acquisitions, the relative importance of cost or price may vary. For example, in acquisitions where the requirement is clearly definable and the risk of unsuccessful contract performance is minimal, cost or price may play a dominant role in source selection.
        
        (b) The source selection approach that represents the best value shall be used.
        
        15.102 Oral presentations.
        (a) Oral presentations by offerors as part of the evaluation process may be used when they are advantageous to the Government.
        
        (b) Oral presentations provide an opportunity for dialogue among the parties.
        """
        let regulation = createMockRegulation(content: semanticContent)
        
        // WHEN: Chunking with semantic boundary detection
        let chunks = try await engine.chunkRegulation(regulation)
        
        // THEN: Should respect semantic boundaries
        let boundaryRespected = chunks.allSatisfy { chunk in
            // Check if chunk ends at natural boundaries
            let content = chunk.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return content.hasSuffix(".") || 
                   content.contains("15.101") || 
                   content.contains("15.102") ||
                   content.contains("Subpart")
        }
        
        #expect(boundaryRespected, "Should respect semantic boundaries")
        #expect(chunks.count >= 2, "Should create multiple semantic chunks")
        
        // Verify each chunk has semantic coherence
        for chunk in chunks {
            #expect(chunk.semanticCoherence >= 0.8, "Each chunk should have high semantic coherence")
            #expect(chunk.boundaryType != .arbitrary, "Should avoid arbitrary boundaries")
        }
    }

    @Test("10% overlap preservation")
    func test10PercentOverlapPreservation() async throws {
        // GIVEN: Engine configured for overlap
        let engine = SmartChunkingEngine(configuration: .withOverlap(percentage: 0.1))
        let longContent = generatePreciseTokenContent(tokenCount: 1536) // Creates ~3 chunks
        let regulation = createMockRegulation(content: longContent)
        
        // WHEN: Chunking with overlap
        let chunks = try await engine.chunkRegulation(regulation)
        
        // THEN: Should have 10% overlap between adjacent chunks
        #expect(chunks.count >= 2, "Should create multiple chunks to test overlap")
        
        for i in 1..<chunks.count {
            let previousChunk = chunks[i - 1]
            let currentChunk = chunks[i]
            
            let overlap = try await engine.calculateOverlap(previous: previousChunk, current: currentChunk)
            let previousTokens = await engine.countTokens(in: previousChunk.content)
            let expectedOverlapTokens = Int(Double(previousTokens) * 0.1)
            
            let overlapTolerance = max(10, expectedOverlapTokens / 10) // ±10% or minimum 10 tokens
            let lowerBound = expectedOverlapTokens - overlapTolerance
            let upperBound = expectedOverlapTokens + overlapTolerance
            
            #expect(overlap.tokenCount >= lowerBound && overlap.tokenCount <= upperBound, 
                   "Overlap should be ~10% (expected: \(expectedOverlapTokens)±\(overlapTolerance), actual: \(overlap.tokenCount))")
        }
    }

    @Test("Context header injection")
    func testContextHeaderInjection() async throws {
        // GIVEN: Engine with hierarchical regulation content
        let engine = SmartChunkingEngine(configuration: .withContextHeaders)
        let hierarchicalContent = """
        PART 15—CONTRACTING BY NEGOTIATION
        
        Subpart 15.2—Solicitation and Receipt of Proposals and Information
        
        15.201 Exchanges with industry before receipt of proposals.
        (a) Exchanges of information among all interested parties, from the earliest identification of a requirement through contract award, are encouraged.
        
        (1) Market research activities may include one-on-one meetings with potential offerors prior to the issuance of the solicitation.
        """
        let regulation = createMockRegulation(
            content: hierarchicalContent,
            hierarchy: RegulationHierarchy(
                part: "PART 15",
                subpart: "Subpart 15.2",
                section: "15.201",
                subsection: nil,
                paragraph: nil,
                subparagraph: nil
            )
        )
        
        // WHEN: Chunking with context headers
        let chunks = try await engine.chunkRegulation(regulation)
        
        // THEN: Should inject hierarchical context headers
        for chunk in chunks {
            #expect(chunk.contextHeader.contains("PART 15"), "Should include part in context header")
            #expect(chunk.contextHeader.contains("Subpart 15.2"), "Should include subpart in context header")
            #expect(chunk.contextHeader.contains("15.201"), "Should include section in context header")
            #expect(chunk.hierarchyPath.count >= 3, "Should maintain hierarchy path")
            #expect(chunk.content.hasPrefix(chunk.contextHeader) || chunk.content.contains(chunk.contextHeader), "Context header should be integrated with content")
        }
    }

    @Test("Regulation hierarchy preservation")
    func testRegulationHierarchyPreservation() async throws {
        // GIVEN: Complex regulation with deep hierarchy
        let engine = SmartChunkingEngine(configuration: .hierarchyOptimized)
        let deepHierarchyContent = """
        PART 15—CONTRACTING BY NEGOTIATION
        
        Subpart 15.2—Solicitation and Receipt of Proposals and Information
        
        15.201 Exchanges with industry before receipt of proposals.
        (a) Exchanges of information among all interested parties, from the earliest identification of a requirement through contract award, are encouraged.
        
        (1) Market research activities may include one-on-one meetings with potential offerors prior to the issuance of the solicitation.
        
        (i) One-on-one meetings with potential offerors prior to the issuance of the solicitation may be conducted for the purpose of enhancing Government understanding of technologies or market capabilities.
        
        (A) Such meetings should be structured to ensure that all offerors are treated fairly and have equal access to information.
        """
        let regulation = createMockRegulation(
            content: deepHierarchyContent,
            hierarchy: RegulationHierarchy(
                part: "PART 15",
                subpart: "Subpart 15.2",
                section: "15.201",
                subsection: "(a)",
                paragraph: "(1)",
                subparagraph: "(i)"
            )
        )
        
        // WHEN: Chunking with hierarchy preservation
        let chunks = try await engine.chunkRegulation(regulation)
        
        // THEN: Should preserve hierarchy throughout chunks
        for chunk in chunks {
            #expect(chunk.hierarchyPath.isEmpty == false, "Should have hierarchy path")
            #expect(chunk.hierarchyPath.contains("PART 15"), "Should preserve part level")
            #expect(chunk.parentSection != nil, "Should identify parent section")
            #expect(chunk.depth >= 1, "Should track nesting depth")
            
            // Verify hierarchy consistency
            let hierarchyString = chunk.hierarchyPath.joined(separator: " > ")
            #expect(hierarchyString.contains("PART 15"), "Hierarchy string should be well-formed")
        }
    }

    // MARK: - GraphRAG Community Detection Tests

    @Test("Community detection accuracy")
    func testCommunityDetectionAccuracy() async throws {
        // GIVEN: Engine with community detection enabled
        let engine = SmartChunkingEngine(configuration: .graphRAGCommunityDetection)
        let communityContent = """
        15.201 Exchanges with industry before receipt of proposals.
        This section establishes policies for pre-solicitation exchanges.
        
        15.202 Advisory multi-step process.
        This section describes the advisory process for complex acquisitions.
        
        15.203 Requests for information.
        Agencies may issue RFIs to gather market information.
        
        15.204 Disclosure, protection, and marking of contractor bid or proposal information.
        This section addresses information security requirements.
        """
        let regulation = createMockRegulation(content: communityContent)
        
        // WHEN: Performing community detection
        let chunks = try await engine.chunkRegulation(regulation)
        let communities = try await engine.detectCommunities(in: chunks)
        
        // THEN: Should identify logical communities
        #expect(communities.count >= 2, "Should detect multiple communities")
        #expect(communities.count <= 4, "Should not over-fragment into too many communities")
        
        // Verify community coherence
        for community in communities {
            #expect(community.coherenceScore >= 0.7, "Community should have high coherence")
            #expect(community.entities.isEmpty == false, "Community should have entities")
            #expect(community.relationships.isEmpty == false, "Community should have relationships")
            
            // Check for thematic consistency
            let hasThematicConsistency = community.entities.contains { entity in
                entity.type == .section || entity.type == .policy || entity.type == .procedure
            }
            #expect(hasThematicConsistency, "Community should have thematic consistency")
        }
    }

    @Test("Entity and relationship extraction")
    func testEntityAndRelationshipExtraction() async throws {
        // GIVEN: Regulation content with clear entities and relationships
        let engine = SmartChunkingEngine(configuration: .entityRelationshipExtraction)
        let entityContent = """
        15.201 Exchanges with industry before receipt of proposals.
        (a) Exchanges of information among all interested parties, from the earliest identification of a requirement through contract award, are encouraged.
        See also 15.202 for advisory processes and 13.501 for simplified procedures.
        Reference to FAR 52.215-1 applies to this section.
        The contracting officer shall ensure compliance with 10 U.S.C. 2304.
        """
        let regulation = createMockRegulation(content: entityContent)
        
        // WHEN: Extracting entities and relationships
        let chunks = try await engine.chunkRegulation(regulation)
        let entities = try await engine.extractEntities(from: chunks)
        let relationships = try await engine.extractRelationships(from: chunks, entities: entities)
        
        // THEN: Should identify key entities and their relationships
        let sectionEntities = entities.filter { $0.type == .section }
        let contractEntities = entities.filter { $0.type == .contract }
        let legalEntities = entities.filter { $0.type == .legalReference }
        let roleEntities = entities.filter { $0.type == .role }
        
        #expect(sectionEntities.count >= 3, "Should identify section entities (15.201, 15.202, 13.501)")
        #expect(contractEntities.count >= 1, "Should identify contract-related entities")
        #expect(legalEntities.count >= 2, "Should identify legal references (FAR 52.215-1, 10 U.S.C. 2304)")
        #expect(roleEntities.count >= 1, "Should identify contracting officer role")
        
        // Verify relationships
        let crossReferences = relationships.filter { $0.type == .crossReference }
        let parentChild = relationships.filter { $0.type == .parentChild }
        let references = relationships.filter { $0.type == .references }
        
        #expect(crossReferences.count >= 2, "Should identify cross-references")
        #expect(parentChild.count >= 1, "Should identify parent-child relationships")
        #expect(references.count >= 2, "Should identify reference relationships")
    }

    // MARK: - Performance Tests

    @Test("Process regulation in 2 seconds")
    func testProcessRegulationIn2Seconds() async throws {
        // GIVEN: Large regulation for performance testing
        let engine = SmartChunkingEngine(configuration: .performanceOptimized)
        let largeRegulation = generateLargeRegulation(targetTokens: 5000)
        
        // WHEN: Processing with time measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        let chunks = try await engine.chunkRegulation(largeRegulation)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let processingTime = endTime - startTime
        
        // THEN: Should complete within 2 seconds
        #expect(processingTime < 2.0, "Should process regulation in under 2 seconds (took \(processingTime)s)")
        #expect(chunks.isEmpty == false, "Should produce chunks")
        #expect(chunks.count >= 5, "Should create reasonable number of chunks for large content")
    }

    @Test("Memory usage during chunking")
    func testMemoryUsageDuringChunking() async throws {
        // GIVEN: Engine with memory monitoring
        let engine = SmartChunkingEngine(configuration: .memoryOptimized)
        let regulation = generateLargeRegulation(targetTokens: 10000)
        let memoryMonitor = MemoryMonitor()
        
        // WHEN: Chunking with memory monitoring
        let initialMemory = await memoryMonitor.getCurrentUsage()
        let chunks = try await engine.chunkRegulation(regulation)
        let peakMemory = await memoryMonitor.getPeakUsage()
        
        let memoryUsedMB = Double(peakMemory - initialMemory) / (1024 * 1024)
        
        // THEN: Should use reasonable memory (<100MB)
        #expect(memoryUsedMB < 100.0, "Should use less than 100MB for chunking (used \(memoryUsedMB)MB)")
        #expect(chunks.isEmpty == false, "Should successfully create chunks")
    }

    @Test("Concurrent chunking with TaskGroup")
    func testConcurrentChunkingWithTaskGroup() async throws {
        // GIVEN: Multiple regulations for concurrent processing
        let engine = SmartChunkingEngine(configuration: .concurrencyOptimized)
        let regulations = (1...10).map { generateRegulation(number: $0, tokens: 1000) }
        
        // WHEN: Processing concurrently with TaskGroup
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await withThrowingTaskGroup(of: [RegulationChunk].self) { group in
            for regulation in regulations {
                group.addTask {
                    try await engine.chunkRegulation(regulation)
                }
            }
            
            var allChunks: [RegulationChunk] = []
            for try await chunks in group {
                allChunks.append(contentsOf: chunks)
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let totalTime = endTime - startTime
            
            // THEN: Should process all regulations efficiently
            #expect(allChunks.isEmpty == false, "Should produce chunks from all regulations")
            #expect(totalTime < 5.0, "Should process all regulations concurrently in under 5 seconds")
            
            let expectedChunks = regulations.count * 2 // Approximate
            #expect(allChunks.count >= expectedChunks, "Should produce reasonable number of chunks")
        }
    }

    // MARK: - Quality Validation Tests

    @Test("Chunk semantic coherence")
    func testChunkSemanticCoherence() async throws {
        // GIVEN: Engine with coherence validation
        let engine = SmartChunkingEngine(configuration: .coherenceValidation)
        let coherentContent = """
        15.201 Exchanges with industry before receipt of proposals.
        This section establishes the policy for pre-solicitation exchanges between Government and industry.
        Such exchanges facilitate the Government's acquisition planning and market research.
        They also help potential offerors understand the Government's requirements.
        The ultimate goal is to improve the quality of solicitations and proposals.
        """
        let regulation = createMockRegulation(content: coherentContent)
        
        // WHEN: Chunking with coherence validation
        let chunks = try await engine.chunkRegulation(regulation)
        
        // THEN: Each chunk should be semantically coherent
        for chunk in chunks {
            #expect(chunk.semanticCoherence >= 0.8, "Chunk should have high semantic coherence (was \(chunk.semanticCoherence))")
            #expect(chunk.topicConsistency >= 0.7, "Chunk should have topic consistency")
            #expect(chunk.contextualRelevance >= 0.8, "Chunk should have contextual relevance")
        }
    }

    @Test("Context preservation across boundaries")
    func testContextPreservationAcrossBoundaries() async throws {
        // GIVEN: Content that requires context preservation
        let engine = SmartChunkingEngine(configuration: .contextPreservation)
        let contextualContent = """
        15.201 Exchanges with industry.
        The contracting officer may conduct exchanges with industry representatives.
        These exchanges serve multiple purposes as described below.
        
        First, they help the Government understand available technologies.
        Second, they assist in developing realistic requirements.
        Third, they promote competition by ensuring broad industry participation.
        
        However, such exchanges must be conducted fairly and transparently.
        All potential offerors must have equal access to information.
        The contracting officer shall document all significant exchanges.
        """
        let regulation = createMockRegulation(content: contextualContent)
        
        // WHEN: Chunking with context preservation
        let chunks = try await engine.chunkRegulation(regulation)
        
        // THEN: Should preserve context across chunk boundaries
        for i in 1..<chunks.count {
            let previousChunk = chunks[i - 1]
            let currentChunk = chunks[i]
            
            let contextBridge = try await engine.analyzeContextBridge(previous: previousChunk, current: currentChunk)
            
            #expect(contextBridge.continuity >= 0.7, "Should maintain context continuity across boundaries")
            #expect(contextBridge.referencePreservation >= 0.8, "Should preserve pronoun and reference clarity")
            #expect(contextBridge.topicFlow >= 0.7, "Should maintain topic flow")
        }
    }

    // MARK: - Error Handling Tests

    @Test("Empty content handling")
    func testEmptyContentHandling() async throws {
        // GIVEN: Engine and empty/minimal content scenarios
        let engine = SmartChunkingEngine(configuration: .robust)
        let emptyCases = [
            "",
            "   ",
            "\n\n\n",
            "<!-- Comment only -->",
            "A", // Single character
            "Short." // Very short content
        ]
        
        for (index, emptyContent) in emptyCases.enumerated() {
            let regulation = createMockRegulation(content: emptyContent)
            
            // WHEN: Processing empty/minimal content
            let chunks = try await engine.chunkRegulation(regulation)
            
            // THEN: Should handle gracefully
            if emptyContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                #expect(chunks.isEmpty, "Empty content should produce no chunks")
            } else {
                #expect(chunks.count <= 1, "Minimal content should produce at most one chunk")
                if !chunks.isEmpty {
                    #expect(chunks.first!.content.isEmpty == false, "Non-empty chunk should have content")
                }
            }
        }
    }

    @Test("Malformed regulation structure handling")
    func testMalformedRegulationStructureHandling() async throws {
        // GIVEN: Malformed regulation structures
        let engine = SmartChunkingEngine(configuration: .errorTolerant)
        let malformedCases = [
            "15.201 (a) Missing section title and improper structure",
            "(1) (2) (3) Sequential paragraphs without parent structure",
            "PART 15 Subpart 15.1 15.101 Mixed hierarchy levels",
            "See 15.999 (nonexistent reference) and 999.999 (invalid format)"
        ]
        
        for (index, malformedContent) in malformedCases.enumerated() {
            let regulation = createMockRegulation(content: malformedContent)
            
            // WHEN: Processing malformed structure
            let chunks = try await engine.chunkRegulation(regulation)
            
            // THEN: Should handle gracefully with warnings
            #expect(chunks.isEmpty == false, "Should produce chunks despite malformed structure")
            
            for chunk in chunks {
                #expect(chunk.warnings.isEmpty == false, "Should record warnings for malformed structure")
                #expect(chunk.confidence < 1.0, "Should have reduced confidence")
                #expect(chunk.content.isEmpty == false, "Should preserve content despite structure issues")
            }
        }
    }

    // MARK: - Helper Methods

    private func generatePreciseTokenContent(tokenCount: Int) -> String {
        return (0..<tokenCount).map { "token\($0)" }.joined(separator: " ")
    }
    
    private func createMockRegulation(content: String, hierarchy: RegulationHierarchy? = nil) -> MockRegulation {
        fatalError("createMockRegulation not implemented - test will fail")
    }
    
    private func generateLargeRegulation(targetTokens: Int) -> MockRegulation {
        fatalError("generateLargeRegulation not implemented - test will fail")
    }
    
    private func generateRegulation(number: Int, tokens: Int) -> MockRegulation {
        fatalError("generateRegulation not implemented - test will fail")
    }
}

// MARK: - Supporting Types (Will fail until implemented)

struct ChunkingConfiguration {
    static let graphRAGOptimized = ChunkingConfiguration()
    static let semanticOptimized = ChunkingConfiguration()
    static let hierarchyOptimized = ChunkingConfiguration()
    static let graphRAGCommunityDetection = ChunkingConfiguration()
    static let entityRelationshipExtraction = ChunkingConfiguration()
    static let performanceOptimized = ChunkingConfiguration()
    static let memoryOptimized = ChunkingConfiguration()
    static let concurrencyOptimized = ChunkingConfiguration()
    static let coherenceValidation = ChunkingConfiguration()
    static let contextPreservation = ChunkingConfiguration()
    static let robust = ChunkingConfiguration()
    static let errorTolerant = ChunkingConfiguration()
    
    static func withOverlap(percentage: Double) -> ChunkingConfiguration {
        return ChunkingConfiguration()
    }
    
    static let withContextHeaders = ChunkingConfiguration()
}

struct RegulationChunk {
    let id: UUID
    let content: String
    let tokenCount: Int
    let semanticCoherence: Double
    let boundaryType: BoundaryType
    let contextHeader: String
    let hierarchyPath: [String]
    let parentSection: String?
    let depth: Int
    let warnings: [ChunkWarning]
    let confidence: Double
    let topicConsistency: Double
    let contextualRelevance: Double
}

struct Community {
    let id: UUID
    let coherenceScore: Double
    let entities: [Entity]
    let relationships: [Relationship]
}

struct Entity {
    let id: UUID
    let type: EntityType
    let text: String
    let confidence: Double
}

struct Relationship {
    let id: UUID
    let source: UUID
    let target: UUID
    let type: RelationshipType
    let confidence: Double
}

struct OverlapResult {
    let tokenCount: Int
    let semanticSimilarity: Double
    let contextualBridge: String
}

struct ContextBridge {
    let continuity: Double
    let referencePreservation: Double
    let topicFlow: Double
}

struct ChunkWarning {
    let type: WarningType
    let message: String
    let severity: WarningSeverity
}

struct MockRegulation {
    let id: UUID
    let content: String
    let hierarchy: RegulationHierarchy?
    let metadata: [String: Any]
}

enum BoundaryType {
    case semantic, arbitrary, structural
}

enum EntityType {
    case section, policy, procedure, contract, legalReference, role
}

enum RelationshipType {
    case crossReference, parentChild, references, implements
}

enum WarningType {
    case structuralIssue, semanticGap, referenceError
}

enum WarningSeverity {
    case low, medium, high
}

// Classes that will fail until implemented
class SmartChunkingEngine {
    init(configuration: ChunkingConfiguration) {
        fatalError("SmartChunkingEngine init not yet implemented")
    }
    
    func chunkRegulation(_ regulation: MockRegulation) async throws -> [RegulationChunk] {
        fatalError("SmartChunkingEngine.chunkRegulation not yet implemented")
    }
    
    func countTokens(in content: String) async -> Int {
        fatalError("SmartChunkingEngine.countTokens not yet implemented")
    }
    
    func calculateOverlap(previous: RegulationChunk, current: RegulationChunk) async throws -> OverlapResult {
        fatalError("SmartChunkingEngine.calculateOverlap not yet implemented")
    }
    
    func detectCommunities(in chunks: [RegulationChunk]) async throws -> [Community] {
        fatalError("SmartChunkingEngine.detectCommunities not yet implemented")
    }
    
    func extractEntities(from chunks: [RegulationChunk]) async throws -> [Entity] {
        fatalError("SmartChunkingEngine.extractEntities not yet implemented")
    }
    
    func extractRelationships(from chunks: [RegulationChunk], entities: [Entity]) async throws -> [Relationship] {
        fatalError("SmartChunkingEngine.extractRelationships not yet implemented")
    }
    
    func analyzeContextBridge(previous: RegulationChunk, current: RegulationChunk) async throws -> ContextBridge {
        fatalError("SmartChunkingEngine.analyzeContextBridge not yet implemented")
    }
}
