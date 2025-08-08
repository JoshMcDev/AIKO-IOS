import Testing
import Foundation
@testable import AIKO

/// Unit tests for structure-aware hierarchical chunking of HTML regulation documents
/// Tests boundary detection, context preservation, and hierarchy maintenance
@Suite("Structure-Aware Chunking Engine Tests")
struct StructureAwareChunkingTests {

    // MARK: - Boundary Detection Tests

    @Test("Accurate detection of HTML structural elements")
    func testHTMLStructuralElementDetection() async throws {
        // GIVEN: Structure-aware chunker and test HTML with various elements
        let chunker = StructureAwareChunker()
        let testHTML = """
        <html>
        <h1>FAR Part 15 - Contracting by Negotiation</h1>
        <h2>15.2 Solicitation and Receipt of Proposals and Information</h2>
        <h3>15.201 Exchanges with industry before receipt of proposals</h3>
        <p>Exchanges of information among all interested parties, from the earliest identification of a requirement through contract award, are encouraged.</p>
        <ul>
        <li>Market research activities</li>
        <li>One-on-one meetings</li>
        </ul>
        </html>
        """

        // WHEN: Detecting structural elements
        let detectedElements = try await chunker.detectStructuralElements(html: testHTML)

        // THEN: Should accurately identify all elements
        #expect(detectedElements.count >= 6, "Should detect h1, h2, h3, p, ul, li elements")

        let h1Elements = detectedElements.filter { $0.type == .heading1 }
        let h2Elements = detectedElements.filter { $0.type == .heading2 }
        let h3Elements = detectedElements.filter { $0.type == .heading3 }
        let pElements = detectedElements.filter { $0.type == .paragraph }
        let liElements = detectedElements.filter { $0.type == .listItem }

        #expect(h1Elements.count == 1, "Should detect 1 h1 element")
        #expect(h2Elements.count == 1, "Should detect 1 h2 element")
        #expect(h3Elements.count == 1, "Should detect 1 h3 element")
        #expect(pElements.count == 1, "Should detect 1 paragraph element")
        #expect(liElements.count == 2, "Should detect 2 list items")
    }

    @Test("Hierarchy path construction validation")
    func testHierarchyPathConstruction() async throws {
        // GIVEN: Nested HTML structure
        let chunker = StructureAwareChunker()
        let nestedHTML = """
        <h1>FAR Part 15</h1>
        <h2>Subpart 15.2 - Solicitation</h2>
        <h3>15.201 General Requirements</h3>
        <p>(a) Market research activities shall include...</p>
        <h4>15.201-1 Specific procedures</h4>
        <p>(1) Documentation requirements</p>
        """

        // WHEN: Constructing hierarchy paths
        let chunks = try await chunker.chunkDocument(html: nestedHTML, config: SmartChunkingConfiguration.default)

        // THEN: Should build correct hierarchy paths
        let expectedPaths = [
            ["FAR Part 15"],
            ["FAR Part 15", "Subpart 15.2 - Solicitation"],
            ["FAR Part 15", "Subpart 15.2 - Solicitation", "15.201 General Requirements"],
            ["FAR Part 15", "Subpart 15.2 - Solicitation", "15.201 General Requirements", "(a)"],
            ["FAR Part 15", "Subpart 15.2 - Solicitation", "15.201 General Requirements", "15.201-1 Specific procedures"],
            ["FAR Part 15", "Subpart 15.2 - Solicitation", "15.201 General Requirements", "15.201-1 Specific procedures", "(1)"]
        ]

        #expect(chunks.count >= expectedPaths.count, "Should create chunks for all hierarchy levels")

        for (index, chunk) in chunks.enumerated() {
            if index < expectedPaths.count {
                #expect(chunk.hierarchyPath == expectedPaths[index], "Hierarchy path should match expected structure")
            }
        }
    }

    @Test("Depth limiting with graceful degradation")
    func testDepthLimitingWithGracefulDegradation() async throws {
        // GIVEN: Extremely deep nested structure
        let chunker = StructureAwareChunker()
        let deepHTML = """
        <h1>Level 1</h1>
        <h2>Level 2</h2>
        <h3>Level 3</h3>
        <h4>Level 4</h4>
        <h5>Level 5</h5>
        <h6>Level 6</h6>
        <div><div><div><div><div><div>Very deep content</div></div></div></div></div></div>
        """

        let config = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false, maxDepth: 5)

        // WHEN: Processing with depth limit
        let chunks = try await chunker.chunkDocument(html: deepHTML, config: config)

        // THEN: Should limit depth and flatten excessive nesting
        let maxDepth = chunks.map { $0.depth }.max() ?? 0
        #expect(maxDepth <= 5, "Should not exceed maximum depth limit")

        let deepestChunk = chunks.first { $0.depth == maxDepth }
        #expect(deepestChunk != nil, "Should have chunk at maximum depth")
        #expect(deepestChunk!.content.contains("Very deep content"), "Should preserve deep content")
    }

    @Test("Character encoding edge cases handling")
    func testCharacterEncodingEdgeCases() async throws {
        // GIVEN: HTML with various encodings
        let chunker = StructureAwareChunker()
        let encodingTestCases = [
            ("UTF-8", "Résumé façade naïve café"),
            ("Latin-1", "Réglements européens"),
            ("Mixed", "ASCII + émojis 🚀 + 中文")
        ]

        // WHEN: Processing each encoding case
        for (encoding, content) in encodingTestCases {
            let html = "<h1>\(content)</h1><p>Content with \(encoding) encoding.</p>"
            let chunks = try await chunker.chunkDocument(html: html, config: SmartChunkingConfiguration.default)

            // THEN: Should handle all encodings correctly
            #expect(!chunks.isEmpty, "Should process \(encoding) encoded content")
            #expect(chunks.first?.content.contains(content) == true, "Should preserve \(encoding) content")
        }
    }

    @Test("Malformed HTML edge case handling")
    func testMalformedHTMLEdgeCaseHandling() async throws {
        // GIVEN: Various malformed HTML scenarios
        let chunker = StructureAwareChunker()
        let malformedCases = [
            "<h1>Unclosed heading",
            "<p>Paragraph <b>unclosed bold",
            "<div><span>Nested <em>elements</span></em></div>", // Incorrectly nested
            "<h2>Header</h2><p>Valid content</p><invalid-tag>Custom tag</invalid-tag>",
            "" // Empty HTML
        ]

        // WHEN: Processing malformed HTML
        for (index, html) in malformedCases.enumerated() {
            // THEN: Should handle gracefully without crashing
            await #expect(throws: Never.self) {
                let chunks = try await chunker.chunkDocument(html: html, config: SmartChunkingConfiguration.default)

                if html.isEmpty {
                    #expect(chunks.isEmpty, "Empty HTML should produce no chunks")
                } else {
                    #expect(chunks.isEmpty, "Should handle malformed HTML case \(index)")
                }
            }
        }
    }

    // MARK: - Context Preservation Tests

    @Test("100-token overlap between adjacent chunks")
    func test100TokenOverlapBetweenAdjacentChunks() async throws {
        // GIVEN: Large content requiring multiple chunks
        let chunker = StructureAwareChunker()
        let longContent = generateLongContent(tokenCount: 2000) // Requires ~4 chunks at 512 tokens each
        let html = "<h1>Long Document</h1><p>\(longContent)</p>"

        let config = SmartChunkingConfiguration(
            targetTokenSize: 512,
            hasOverlap: true,
            includesContextHeaders: false,
            overlapTokens: 100,
            minChunkSize: 100,
            maxChunkSize: 1000
        )

        // WHEN: Chunking with overlap
        let chunks = try await chunker.chunkDocument(html: html, config: config)

        // THEN: Should have 100-token overlap between adjacent chunks
        #expect(chunks.count >= 2, "Should create multiple chunks for long content")

        for i in 1..<chunks.count {
            let previousChunk = chunks[i - 1]
            let currentChunk = chunks[i]

            let overlap = await chunker.calculateOverlapTokens(previousChunk, currentChunk)
            #expect(overlap >= 90 && overlap <= 110, "Should have ~100 token overlap (±10)")
        }
    }

    @Test("Parent-child relationship retention (95% target)")
    func testParentChildRelationshipRetention() async throws {
        // GIVEN: Hierarchical document with clear parent-child relationships
        let chunker = StructureAwareChunker()
        let html = createHierarchicalTestDocument()

        // WHEN: Processing with relationship tracking
        let chunks = try await chunker.chunkDocument(html: html, config: ChunkingConfiguration.default)
        let relationships = try await chunker.analyzeParentChildRelationships(chunks)

        // THEN: Should retain 95% of parent-child relationships
        let totalRelationships = relationships.count
        let retainedRelationships = relationships.filter { $0.retentionQuality >= 0.8 }.count
        let retentionRate = Double(retainedRelationships) / Double(totalRelationships)

        #expect(retentionRate >= 0.95, "Should retain at least 95% of parent-child relationships")

        // Verify specific relationship types
        let headingToParagraphRelationships = relationships.filter { $0.type == RelationshipType.headingToParagraph }
        let listRelationships = relationships.filter { $0.type == RelationshipType.listToItems }

        #expect(!headingToParagraphRelationships.isEmpty, "Should have heading-to-paragraph relationships")
        #expect(!listRelationships.isEmpty, "Should have list-to-item relationships")
    }

    @Test("Contextual window generation validation")
    func testContextualWindowGeneration() async throws {
        // GIVEN: Nested document structure
        let chunker = StructureAwareChunker()
        let html = """
        <h1>Contract Requirements</h1>
        <h2>Technical Specifications</h2>
        <p>This section defines technical requirements.</p>
        <h3>Performance Standards</h3>
        <p>All systems must meet the following performance criteria:</p>
        <ul>
        <li>Response time under 2 seconds</li>
        <li>99.9% uptime requirement</li>
        </ul>
        <h3>Security Requirements</h3>
        <p>Security measures must include:</p>
        """

        // WHEN: Generating contextual windows
        let chunks = try await chunker.chunkDocument(html: html, config: ChunkingConfiguration.default)

        // THEN: Each chunk should have contextual window (parent + current + preview)
        for chunk in chunks {
            let contextWindow = chunk.contextWindow

            #expect(!contextWindow.currentContent.isEmpty, "Each chunk should have context window")
            #expect(contextWindow.parentContext != nil || chunk.depth == 1, "Should have parent context except for top level")

            if chunk != chunks.last {
                #expect(contextWindow.previewContent != nil, "Should have preview content except for last chunk")
            }
        }
    }

    @Test("Coherence maintenance across chunk boundaries")
    func testCoherenceMaintenanceAcrossChunkBoundaries() async throws {
        // GIVEN: Document with natural semantic boundaries
        let chunker = StructureAwareChunker()
        let html = createCoherenceTestDocument()

        // WHEN: Analyzing coherence across boundaries
        let chunks = try await chunker.chunkDocument(html: html, config: ChunkingConfiguration.default)
        let coherenceScores = try await chunker.analyzeChunkCoherence(chunks)

        // THEN: Should maintain high coherence across boundaries
        let averageCoherence = coherenceScores.reduce(0, +) / Double(coherenceScores.count)
        #expect(averageCoherence >= 0.85, "Should maintain at least 85% coherence across boundaries")

        // Check for semantic continuity at boundaries
        for i in 1..<chunks.count {
            let boundaryCoherence = coherenceScores[i - 1]
            #expect(boundaryCoherence >= 0.7, "Boundary coherence should be at least 70%")
        }
    }

    // MARK: - Token Management Tests

    @Test("Accurate token counting with target 512 tokens per chunk")
    func testAccuateTokenCountingWith512Target() async throws {
        // GIVEN: Chunker with 512-token target
        let chunker = StructureAwareChunker()
        let config = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)
        let testContent = generatePreciseTokenContent(tokenCount: 1536) // Should create ~3 chunks
        let html = "<div>\(testContent)</div>"

        // WHEN: Chunking with token target
        let chunks = try await chunker.chunkDocument(html: html, config: config)

        // THEN: Should create chunks close to 512 tokens each
        #expect(chunks.count >= 2, "Should create multiple chunks")

        for chunk in chunks {
            let tokenCount = await chunker.countTokens(in: chunk.content)
            #expect(tokenCount >= 100, "Should meet minimum token count")
            #expect(tokenCount <= 1000, "Should not exceed maximum token count")

            // Most chunks should be near target (±20% tolerance)
            if chunk != chunks.last { // Last chunk may be smaller
                #expect(tokenCount >= 410 && tokenCount <= 614, "Should be within 20% of 512-token target")
            }
        }
    }

    @Test("Min/max chunk size enforcement")
    func testMinMaxChunkSizeEnforcement() async throws {
        // GIVEN: Configuration with strict size limits
        let chunker = StructureAwareChunker()
        let config = SmartChunkingConfiguration(
            targetTokenSize: 500,
            hasOverlap: false,
            includesContextHeaders: false,
            minChunkSize: 150,
            maxChunkSize: 800
        )

        let testCases = [
            generatePreciseTokenContent(tokenCount: 50),   // Below minimum
            generatePreciseTokenContent(tokenCount: 300),  // Within range
            generatePreciseTokenContent(tokenCount: 1500), // Above maximum, needs splitting
        ]

        // WHEN: Processing various content sizes
        for (index, content) in testCases.enumerated() {
            let html = "<div>\(content)</div>"
            let chunks = try await chunker.chunkDocument(html: html, config: config)

            // THEN: Should enforce size limits
            for chunk in chunks {
                let tokenCount = await chunker.countTokens(in: chunk.content)

                if index == 0 { // Small content might be merged or padded
                    #expect(tokenCount >= 150 || chunks.count == 1, "Should meet minimum or be single chunk")
                } else {
                    #expect(tokenCount >= 150, "Should meet minimum size")
                    #expect(tokenCount <= 800, "Should not exceed maximum size")
                }
            }
        }
    }

    @Test("Overflow handling for oversized content sections")
    func testOverflowHandlingForOversizedContentSections() async throws {
        // GIVEN: Single element with oversized content
        let chunker = StructureAwareChunker()
        let config = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false, maxChunkSize: 500)
        let oversizedContent = generatePreciseTokenContent(tokenCount: 1500)
        let html = "<p>\(oversizedContent)</p>" // Single paragraph, can't split at element boundary

        // WHEN: Processing oversized content
        let chunks = try await chunker.chunkDocument(html: html, config: config)

        // THEN: Should handle overflow gracefully
        #expect(chunks.count > 1, "Should split oversized content into multiple chunks")

        for chunk in chunks {
            let tokenCount = await chunker.countTokens(in: chunk.content)
            #expect(tokenCount <= 600, "Should respect max size with small tolerance")
        }

        // Verify content preservation
        let reconstructedContent = chunks.map { $0.content }.joined(separator: " ")
        #expect(reconstructedContent.contains("token"), "Should preserve content during overflow splitting")
    }

    @Test("Token-aware splitting at natural boundaries")
    func testTokenAwareSplittingAtNaturalBoundaries() async throws {
        // GIVEN: Content with clear natural boundaries
        let chunker = StructureAwareChunker()
        let html = """
        <h1>Document Title</h1>
        <p>First paragraph with \(generatePreciseTokenContent(tokenCount: 300)) content.</p>
        <p>Second paragraph with \(generatePreciseTokenContent(tokenCount: 400)) content.</p>
        <p>Third paragraph with \(generatePreciseTokenContent(tokenCount: 300)) content.</p>
        """

        let config = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false)

        // WHEN: Splitting at natural boundaries
        let chunks = try await chunker.chunkDocument(html: html, config: config)

        // THEN: Should prefer natural boundaries over arbitrary splits
        var naturalBoundaryCount = 0
        var arbitrarySplitCount = 0

        for chunk in chunks {
            let endsWithCompleteSentence = chunk.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).hasSuffix(".")
            let endsWithCompleteElement = chunk.content.contains("</p>") || chunk.content.contains("</h1>")

            if endsWithCompleteSentence || endsWithCompleteElement {
                naturalBoundaryCount += 1
            } else {
                arbitrarySplitCount += 1
            }
        }

        #expect(naturalBoundaryCount >= arbitrarySplitCount, "Should prefer natural boundaries over arbitrary splits")
    }

    // MARK: - Fallback Mechanism Tests

    @Test("SwiftSoup parsing failure to flat chunking mode")
    func testSwiftSoupParsingFailureToFlatChunkingMode() async throws {
        // GIVEN: Chunker with parsing failure simulation
        let chunker = StructureAwareChunker()
        let config = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false, fallbackToFlat: true)

        // WHEN: Simulating SwiftSoup parsing failure
        await chunker.simulateParsingFailure(enabled: true)
        let html = "<h1>Valid HTML</h1><p>This should fallback to flat chunking.</p>"
        let chunks = try await chunker.chunkDocument(html: html, config: config)

        // THEN: Should fallback to flat chunking
        #expect(!chunks.isEmpty, "Should produce chunks even with parsing failure")

        let usedFlatChunking = await chunker.getLastProcessingMode()
        #expect(usedFlatChunking == .flatChunking, "Should have used flat chunking mode")

        // Verify chunks don't have hierarchical structure
        for chunk in chunks {
            #expect(chunk.hierarchyPath.count <= 1, "Flat chunks should have minimal hierarchy")
            #expect(chunk.elementType == .text, "Should use text element type for flat chunks")
        }
    }

    @Test("HTML structure detection failure to regex-based fallback")
    func testHTMLStructureDetectionFailureToRegexFallback() async throws {
        // GIVEN: Chunker with structure detection disabled
        let chunker = StructureAwareChunker()
        let config = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false, fallbackToFlat: true)

        // WHEN: Disabling structure detection
        await chunker.disableStructureDetection(true)
        let html = "<h1>Title</h1><p>Content</p>"
        let chunks = try await chunker.chunkDocument(html: html, config: config)

        // THEN: Should use regex-based fallback
        let processingMode = await chunker.getLastProcessingMode()
        #expect(processingMode == .regexBased, "Should use regex-based fallback")

        #expect(!chunks.isEmpty, "Should produce chunks with regex fallback")
        #expect(chunks.first?.content.contains("Title") == true, "Should preserve content")
    }

    @Test("Depth overflow to flattening to maximum depth")
    func testDepthOverflowToFlatteningToMaximumDepth() async throws {
        // GIVEN: Extremely nested content
        let chunker = StructureAwareChunker()
        let config = SmartChunkingConfiguration(targetTokenSize: 512, hasOverlap: false, includesContextHeaders: false, maxDepth: 3)
        let nestedHTML = createDeeplyNestedHTML(levels: 10)

        // WHEN: Processing with depth overflow
        let chunks = try await chunker.chunkDocument(html: nestedHTML, config: config)

        // THEN: Should flatten to maximum depth
        let maxActualDepth = chunks.map { $0.depth }.max() ?? 0
        #expect(maxActualDepth <= 3, "Should not exceed maximum depth")

        // Verify content preservation despite flattening
        let allContent = chunks.map { $0.content }.joined()
        #expect(allContent.contains("Level 8"), "Should preserve deep content")
        #expect(allContent.contains("Level 10"), "Should preserve deepest content")
    }

    @Test("Mixed content handling (PDF-in-HTML, embedded base64, JS-generated DOM)")
    func testMixedContentHandling() async throws {
        // GIVEN: HTML with mixed content types
        let chunker = StructureAwareChunker()
        let mixedHTML = """
        <h1>Document with Mixed Content</h1>
        <embed src="data:application/pdf;base64,JVBERi0xLjQ..." type="application/pdf" />
        <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEA..." />
        <script>document.write('<p>Dynamically generated content</p>');</script>
        <p>Regular HTML content</p>
        """

        // WHEN: Processing mixed content
        let chunks = try await chunker.chunkDocument(html: mixedHTML, config: ChunkingConfiguration.default)

        // THEN: Should handle mixed content gracefully
        #expect(!chunks.isEmpty, "Should process mixed content")

        let textChunks = chunks.filter { $0.content.contains("Document with Mixed Content") || $0.content.contains("Regular HTML content") }
        #expect(!textChunks.isEmpty, "Should preserve text content")

        // Verify handling of embedded content
        let hasEmbeddedHandling = chunks.contains { chunk in
            chunk.metadata.keys.contains("embedded_content") || chunk.metadata.keys.contains("binary_data")
        }
        #expect(hasEmbeddedHandling == true, "Should mark embedded content in metadata")
    }

    // MARK: - Helper Methods

    private func generateLongContent(tokenCount: Int) -> String {
        let baseText = "This is a sample token "
        return String(repeating: baseText, count: tokenCount / 5) // Approximate token count
    }

    private func generatePreciseTokenContent(tokenCount: Int) -> String {
        return (0..<tokenCount).map { "token\($0)" }.joined(separator: " ")
    }

    private func createHierarchicalTestDocument() -> String {
        return """
        <h1>Main Title</h1>
        <h2>Section A</h2>
        <p>Content for section A with detailed information.</p>
        <h3>Subsection A.1</h3>
        <p>Detailed content for subsection A.1.</p>
        <ul>
        <li>First item in list</li>
        <li>Second item in list</li>
        </ul>
        <h3>Subsection A.2</h3>
        <p>Content for subsection A.2.</p>
        <h2>Section B</h2>
        <p>Content for section B.</p>
        """
    }

    private func createCoherenceTestDocument() -> String {
        return """
        <h1>Coherence Test Document</h1>
        <p>This document tests semantic coherence. The following sections build upon each other logically.</p>
        <h2>Introduction</h2>
        <p>The introduction establishes the foundation for understanding the subsequent material.</p>
        <h2>Core Concepts</h2>
        <p>Building on the introduction, we now explore the core concepts that form the basis of our analysis.</p>
        <h2>Detailed Analysis</h2>
        <p>The detailed analysis section expands on the core concepts with specific examples and case studies.</p>
        <h2>Conclusion</h2>
        <p>In conclusion, the analysis demonstrates the interconnected nature of all preceding sections.</p>
        """
    }

    private func createDeeplyNestedHTML(levels: Int) -> String {
        var html = ""
        for i in 1...levels {
            html += "<div class='level\(i)'><h\(min(i, 6))>Level \(i)</h\(min(i, 6))><p>Content at level \(i)</p>"
        }
        for _ in 1...levels {
            html += "</div>"
        }
        return html
    }
}

// MARK: - Supporting Types imported from AIKO module
// All types now use the actual implementations from StructureAwareChunker.swift
