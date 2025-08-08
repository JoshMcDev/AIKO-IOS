import Testing
import Foundation
@testable import AIKO

/// Comprehensive unit tests for RegulationHTMLParser using SwiftSoup
/// Tests HTML parsing, metadata extraction, hierarchy preservation, and error handling
@Suite("RegulationHTMLParser Tests")
struct RegulationHTMLParserTests {

    // MARK: - Core Parsing Tests

    @Test("SwiftSoup HTML structure parsing")
    func testSwiftSoupHTMLStructureParsing() async throws {
        // GIVEN: HTML parser and sample government regulation HTML
        let parser = RegulationHTMLParser()
        let regulationHTML = """
        <!DOCTYPE html>
        <html>
        <head><title>FAR Part 15 - Contracting by Negotiation</title></head>
        <body>
        <h1>Federal Acquisition Regulation</h1>
        <h2>Part 15 - Contracting by Negotiation</h2>
        <h3>Subpart 15.2 - Solicitation and Receipt of Proposals</h3>
        <h4>15.201 Exchanges with industry before receipt of proposals</h4>
        <p>Exchanges of information among all interested parties, from the earliest identification of a requirement through contract award, are encouraged.</p>
        <ul>
        <li>Market research activities</li>
        <li>One-on-one meetings with potential offerors</li>
        </ul>
        <table>
        <tr><th>Section</th><th>Description</th></tr>
        <tr><td>15.201</td><td>Pre-proposal exchanges</td></tr>
        </table>
        </body>
        </html>
        """

        // WHEN: Parsing HTML structure
        let result = try await parser.parseRegulationHTML(regulationHTML)

        // THEN: Should extract structured content
        #expect(result.title.contains("FAR Part 15"), "Should extract title")
        #expect(result.content.contains("Contracting by Negotiation"), "Should extract main content")
        #expect(result.headings.count >= 4, "Should extract all heading levels")
        #expect(result.listItems.count == 2, "Should extract list items")
        #expect(result.tableData.count == 1, "Should extract table data")
        #expect(result.metadata["document_type"] as? String == "regulation", "Should identify as regulation")
    }

    @Test("Government document format handling")
    func testGovernmentDocumentFormatHandling() async throws {
        // GIVEN: Parser with government-specific HTML patterns
        let parser = RegulationHTMLParser()
        let govHTML = """
        <div class="regulation-part">
        <span class="part-number">PART 12</span>
        <span class="part-title">ACQUISITION OF COMMERCIAL PRODUCTS AND COMMERCIAL SERVICES</span>
        </div>
        <div class="subpart">
        <span class="subpart-number">Subpart 12.1</span>
        <span class="subpart-title">Acquisition of Commercial Products and Commercial Services—General</span>
        </div>
        <div class="section">
        <span class="section-number">12.101</span>
        <span class="section-title">Policy</span>
        <p class="section-content">The Government's policy is to acquire commercial products and commercial services...</p>
        </div>
        """

        // WHEN: Parsing government document format
        let result = try await parser.parseRegulationHTML(govHTML)

        // THEN: Should handle government-specific structures
        #expect(result.regulationNumber == "PART 12", "Should extract regulation number")
        #expect(result.hierarchy.part == "PART 12", "Should identify part")
        #expect(result.hierarchy.subpart == "Subpart 12.1", "Should identify subpart")
        #expect(result.hierarchy.section == "12.101", "Should identify section")
        #expect(result.crossReferences.isEmpty == false, "Should detect cross-references")
    }

    @Test("Malformed HTML graceful degradation")
    func testMalformedHTMLGracefulDegradation() async throws {
        // GIVEN: Parser and malformed HTML scenarios
        let parser = RegulationHTMLParser()
        let malformedCases = [
            "<h1>Unclosed heading with content",
            "<p>Paragraph <b>with unclosed <em>nested tags",
            "<div><span>Mixed nesting</div></span>",
            "<regulation>Custom tags</invalid>",
            "<h2>Header</h2><![CDATA[Some CDATA]]><p>Content</p>",
            "&lt;escaped&gt; &amp; special &quot;characters&quot;"
        ]

        for (index, htmlCase) in malformedCases.enumerated() {
            // WHEN: Parsing malformed HTML
            let result = try await parser.parseRegulationHTML(htmlCase)

            // THEN: Should handle gracefully without crashing
            #expect(result.content.isEmpty == false, "Should extract some content from case \(index)")
            #expect(result.errors.isEmpty == false, "Should record parsing errors for case \(index)")
            #expect(result.confidence < 1.0, "Should have reduced confidence for malformed HTML")
        }
    }

    @Test("Metadata extraction accuracy")
    func testMetadataExtractionAccuracy() async throws {
        // GIVEN: HTML with rich metadata
        let parser = RegulationHTMLParser()
        let metadataHTML = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta name="regulation-number" content="FAR 15.201">
        <meta name="effective-date" content="2024-01-01">
        <meta name="authority" content="GSA">
        <meta name="classification" content="CUI">
        <title>15.201 - Exchanges with industry before receipt of proposals</title>
        </head>
        <body data-regulation-type="solicitation">
        <div class="regulation-header">
        <span class="reg-number">15.201</span>
        <span class="effective-date">Effective: January 1, 2024</span>
        </div>
        <p class="regulation-content">Content goes here...</p>
        </body>
        </html>
        """

        // WHEN: Extracting metadata
        let result = try await parser.parseRegulationHTML(metadataHTML)

        // THEN: Should extract complete metadata
        #expect(result.metadata["regulation_number"] as? String == "FAR 15.201", "Should extract regulation number")
        #expect(result.metadata["effective_date"] as? String == "2024-01-01", "Should extract effective date")
        #expect(result.metadata["authority"] as? String == "GSA", "Should extract authority")
        #expect(result.metadata["classification"] as? String == "CUI", "Should extract classification")
        #expect(result.metadata["language"] as? String == "en", "Should extract language")
        #expect(result.effectiveDate != nil, "Should parse effective date")
    }

    @Test("Hierarchical structure preservation")
    func testHierarchicalStructurePreservation() async throws {
        // GIVEN: Complex nested regulation structure
        let parser = RegulationHTMLParser()
        let hierarchicalHTML = """
        <div class="regulation">
        <h1>PART 15—CONTRACTING BY NEGOTIATION</h1>
        <div class="subpart">
        <h2>Subpart 15.2—Solicitation and Receipt of Proposals and Information</h2>
        <div class="section">
        <h3>15.201 Exchanges with industry before receipt of proposals</h3>
        <div class="subsection">
        <h4>(a) General</h4>
        <p>Exchanges of information among all interested parties...</p>
        <div class="paragraph">
        <h5>(1) Market research activities</h5>
        <p>These activities may include...</p>
        <div class="subparagraph">
        <h6>(i) One-on-one meetings</h6>
        <p>Meetings with potential offerors...</p>
        </div>
        </div>
        </div>
        </div>
        </div>
        </div>
        """

        // WHEN: Parsing hierarchical structure
        let result = try await parser.parseRegulationHTML(hierarchicalHTML)

        // THEN: Should preserve complete hierarchy
        let expectedHierarchy = RegulationHierarchy(
            part: "PART 15",
            subpart: "Subpart 15.2",
            section: "15.201",
            subsection: "(a)",
            paragraph: "(1)",
            subparagraph: "(i)"
        )
        #expect(result.hierarchy == expectedHierarchy, "Should preserve complete hierarchy")
        #expect(result.headings.count == 6, "Should capture all heading levels")
        #expect(result.nestedStructure.maxDepth == 6, "Should track maximum nesting depth")
    }

    @Test("Cross-reference extraction and linking")
    func testCrossReferenceExtractionAndLinking() async throws {
        // GIVEN: HTML with various cross-reference patterns
        let parser = RegulationHTMLParser()
        let crossRefHTML = """
        <div class="regulation">
        <p>See <a href="#15.203">section 15.203</a> for additional requirements.</p>
        <p>As prescribed in <a href="#13.501">13.501(a)</a>, use the procedures in this section.</p>
        <p>Reference to FAR 52.215-1 and DFARS 252.215-7000 applies.</p>
        <p>See also 48 CFR 15.201 and 10 U.S.C. 2304.</p>
        <p>Cross-reference to Part 12, Subpart 12.3, section 12.301.</p>
        </div>
        """

        // WHEN: Extracting cross-references
        let result = try await parser.parseRegulationHTML(crossRefHTML)

        // THEN: Should identify and link all cross-references
        #expect(result.crossReferences.count >= 8, "Should find all cross-references")
        
        let sectionRefs = result.crossReferences.filter { $0.type == .section }
        let farRefs = result.crossReferences.filter { $0.type == .farReference }
        let dfarRefs = result.crossReferences.filter { $0.type == .dfarReference }
        let cfrRefs = result.crossReferences.filter { $0.type == .cfrReference }
        let uscRefs = result.crossReferences.filter { $0.type == .uscReference }
        
        #expect(sectionRefs.count >= 3, "Should find section references")
        #expect(farRefs.count >= 1, "Should find FAR references")
        #expect(dfarRefs.count >= 1, "Should find DFARS references")
        #expect(cfrRefs.count >= 1, "Should find CFR references")
        #expect(uscRefs.count >= 1, "Should find USC references")
    }

    @Test("Table and list structure preservation")
    func testTableAndListStructurePreservation() async throws {
        // GIVEN: HTML with complex tables and lists
        let parser = RegulationHTMLParser()
        let structureHTML = """
        <div>
        <table class="regulation-table">
        <caption>Contract Types and Thresholds</caption>
        <thead>
        <tr><th>Contract Type</th><th>Threshold</th><th>Authority</th></tr>
        </thead>
        <tbody>
        <tr><td>Simplified Acquisition</td><td>$250,000</td><td>FAR 13</td></tr>
        <tr><td>Commercial</td><td>$7.5M</td><td>FAR 12</td></tr>
        </tbody>
        </table>
        
        <ol class="requirements-list">
        <li>Primary requirement
            <ul>
            <li>Sub-requirement A</li>
            <li>Sub-requirement B
                <ol>
                <li>Detailed item 1</li>
                <li>Detailed item 2</li>
                </ol>
            </li>
            </ul>
        </li>
        <li>Secondary requirement</li>
        </ol>
        </div>
        """

        // WHEN: Parsing structured content
        let result = try await parser.parseRegulationHTML(structureHTML)

        // THEN: Should preserve table and list structures
        #expect(result.tables.count == 1, "Should extract table")
        #expect(result.tables.first?.caption == "Contract Types and Thresholds", "Should extract table caption")
        #expect(result.tables.first?.headers.count == 3, "Should extract table headers")
        #expect(result.tables.first?.rows.count == 2, "Should extract table rows")
        
        #expect(result.lists.count >= 2, "Should extract nested lists")
        #expect(result.lists.first?.type == .ordered, "Should identify ordered list")
        #expect(result.lists.first?.items.count == 2, "Should extract list items")
        #expect(result.nestedLists.count >= 2, "Should track nested list structures")
    }

    // MARK: - Performance Tests

    @Test("Parse 5MB regulation in 500ms")
    func testParse5MBRegulationIn500ms() async throws {
        // GIVEN: Large regulation document (~5MB)
        let parser = RegulationHTMLParser()
        let largeHTML = generateLargeRegulationHTML(targetSizeMB: 5)
        
        // WHEN: Parsing with time measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await parser.parseRegulationHTML(largeHTML)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let parseTime = endTime - startTime
        
        // THEN: Should complete within performance target
        #expect(parseTime < 0.5, "Should parse 5MB regulation in under 500ms")
        #expect(result.content.isEmpty == false, "Should successfully extract content")
        #expect(result.processingTime < 0.5, "Should record processing time under 500ms")
    }

    @Test("Memory usage during parsing")
    func testMemoryUsageDuringParsing() async throws {
        // GIVEN: Parser with memory monitoring
        let parser = RegulationHTMLParser()
        let testHTML = generateLargeRegulationHTML(targetSizeMB: 2)
        let memoryMonitor = MemoryMonitor()
        
        // WHEN: Parsing with memory monitoring
        let initialMemory = await memoryMonitor.getCurrentUsage()
        let result = try await parser.parseRegulationHTML(testHTML)
        let peakMemory = await memoryMonitor.getPeakUsage()
        
        let memoryUsedMB = Double(peakMemory - initialMemory) / (1024 * 1024)
        
        // THEN: Should use reasonable memory (<10MB)
        #expect(memoryUsedMB < 10.0, "Should use less than 10MB for parsing")
        #expect(result.memoryUsage.peakMB < 10.0, "Should track memory usage")
    }

    @Test("Concurrent parsing of 10 regulations")
    func testConcurrentParsingOf10Regulations() async throws {
        // GIVEN: Multiple regulation documents
        let parser = RegulationHTMLParser()
        let regulations = (1...10).map { generateRegulationHTML(regulationNumber: $0) }
        
        // WHEN: Parsing concurrently
        try await withThrowingTaskGroup(of: RegulationParseResult.self) { group in
            for regulation in regulations {
                group.addTask {
                    try await parser.parseRegulationHTML(regulation)
                }
            }
            
            var results: [RegulationParseResult] = []
            for try await result in group {
                results.append(result)
            }
            
            // THEN: Should parse all regulations successfully
            #expect(results.count == 10, "Should parse all regulations")
            #expect(results.allSatisfy { !$0.content.isEmpty }, "All should have content")
            #expect(results.allSatisfy { $0.errors.isEmpty }, "Should have no parsing errors")
        }
    }

    // MARK: - Error Handling Tests

    @Test("Character encoding edge cases")
    func testCharacterEncodingEdgeCases() async throws {
        // GIVEN: HTML with various character encodings
        let parser = RegulationHTMLParser()
        let encodingCases = [
            ("UTF-8", "<p>Résumé façade naïve café 🚀</p>"),
            ("Latin-1", "<p>Réglements européens</p>"),
            ("Special", "<p>&lt;tag&gt; &amp; &quot;quotes&quot; &#x27;apostrophes&#x27;</p>"),
            ("Unicode", "<p>中文 العربية русский język</p>"),
            ("Emoji", "<p>📄 📋 ✅ ❌ 🔍 💼</p>")
        ]
        
        for (encoding, html) in encodingCases {
            // WHEN: Parsing encoded content
            let result = try await parser.parseRegulationHTML(html)
            
            // THEN: Should handle encoding correctly
            #expect(result.content.isEmpty == false, "Should parse \(encoding) content")
            #expect(result.encoding == "UTF-8", "Should normalize to UTF-8")
            #expect(result.errors.isEmpty, "Should have no encoding errors for \(encoding)")
        }
    }

    @Test("Invalid HTML structure recovery")
    func testInvalidHTMLStructureRecovery() async throws {
        // GIVEN: Various invalid HTML structures
        let parser = RegulationHTMLParser()
        let invalidStructures = [
            "<html><head><body>Mixed structure</body></head></html>",
            "<div><p>Unclosed paragraph<div>Nested improperly</div>",
            "<table><tr><td>Missing tbody<td>Extra cell</tr></table>",
            "<ul><p>Wrong nesting</p><li>List item</li></ul>",
            "<!-- Comment only document -->"
        ]
        
        for (index, invalidHTML) in invalidStructures.enumerated() {
            // WHEN: Parsing invalid structure
            let result = try await parser.parseRegulationHTML(invalidHTML)
            
            // THEN: Should recover gracefully
            #expect(result.warnings.isEmpty == false, "Should record warnings for case \(index)")
            #expect(result.recoveryActions.isEmpty == false, "Should record recovery actions")
            #expect(result.confidence < 0.9, "Should have reduced confidence")
        }
    }

    // MARK: - Integration Tests

    @Test("NSAttributedString fallback for complex formatting")
    func testNSAttributedStringFallbackForComplexFormatting() async throws {
        // GIVEN: HTML with complex formatting that SwiftSoup might struggle with
        let parser = RegulationHTMLParser()
        let complexHTML = """
        <div>
        <p style="font-weight: bold; color: red;">Important notice with <span style="text-decoration: underline;">underlined text</span></p>
        <table style="border: 1px solid black;">
        <tr style="background-color: yellow;">
        <td style="padding: 10px;">Formatted cell</td>
        </tr>
        </table>
        <p>Text with <sup>superscript</sup> and <sub>subscript</sub> elements.</p>
        </div>
        """
        
        // WHEN: Parsing with fallback enabled
        let result = try await parser.parseRegulationHTML(complexHTML, enableFallback: true)
        
        // THEN: Should use NSAttributedString fallback when needed
        #expect(result.formattedContent != nil, "Should have formatted content")
        #expect(result.fallbackUsed, "Should indicate fallback was used")
        #expect(!result.preservedFormatting.isEmpty, "Should preserve some formatting")
        #expect(result.content.contains("Important notice"), "Should preserve text content")
    }

    // MARK: - Helper Methods

    private func generateLargeRegulationHTML(targetSizeMB: Int) -> String {
        // Generate large HTML content for stress testing
        let baseHTML = """
        <!DOCTYPE html>
        <html>
        <head><title>Large Regulation Test Document</title></head>
        <body>
        <h1>Large Scale Regulation Document</h1>
        """
        
        let targetBytes = targetSizeMB * 1024 * 1024
        let paragraphSize = 1000 // Approximate paragraph size
        let paragraphCount = targetBytes / paragraphSize
        
        var content = baseHTML
        for i in 0..<paragraphCount {
            content += "<h2>Section \(i)</h2>\n"
            content += "<p>This is paragraph \(i) in the large regulation document. " +
                      String(repeating: "Content for stress testing. ", count: 20) +
                      "End of paragraph \(i).</p>\n"
        }
        content += "</body></html>"
        
        return content
    }
    
    private func generateRegulationHTML(regulationNumber: Int) -> String {
        // Generate regulation HTML for testing
        return """
        <!DOCTYPE html>
        <html>
        <head><title>Test Regulation \(regulationNumber)</title></head>
        <body>
        <h1>Federal Acquisition Regulation</h1>
        <h2>Part \(regulationNumber) - Test Section</h2>
        <h3>Subpart \(regulationNumber).1 - General</h3>
        <p>This is the content for regulation \(regulationNumber). It contains test data for parsing validation.</p>
        <ul>
        <li>First requirement</li>
        <li>Second requirement</li>
        </ul>
        <table>
        <tr><th>Section</th><th>Description</th></tr>
        <tr><td>\(regulationNumber).1</td><td>General provisions</td></tr>
        </table>
        </body>
        </html>
        """
    }
}

// MARK: - Supporting Types (Will fail until implemented)

struct RegulationParseResult {
    let title: String
    let content: String
    let headings: [RegulationHeading]
    let listItems: [String]
    let tableData: [RegulationTable]
    let metadata: [String: Any]
    let regulationNumber: String
    let hierarchy: RegulationHierarchy
    let crossReferences: [CrossReference]
    let effectiveDate: Date?
    let confidence: Double
    let errors: [ParseError]
    let warnings: [ParseWarning]
    let recoveryActions: [RecoveryAction]
    let processingTime: TimeInterval
    let memoryUsage: MemoryUsageInfo
    let encoding: String
    let formattedContent: NSAttributedString?
    let fallbackUsed: Bool
    let preservedFormatting: [FormattingInfo]
    let tables: [RegulationTable]
    let lists: [RegulationList]
    let nestedLists: [NestedListStructure]
    let nestedStructure: NestedStructureInfo
}

struct RegulationHierarchy: Equatable {
    let part: String?
    let subpart: String?
    let section: String?
    let subsection: String?
    let paragraph: String?
    let subparagraph: String?
}

struct RegulationHeading {
    let level: Int
    let text: String
    let id: String?
}

struct RegulationTable {
    let caption: String?
    let headers: [String]
    let rows: [[String]]
    let formatting: [String: Any]
}

struct RegulationList {
    let type: ListType
    let items: [String]
    let nestedLists: [RegulationList]
}

enum ListType {
    case ordered, unordered
}

struct CrossReference {
    let text: String
    let target: String
    let type: CrossReferenceType
    let isInternal: Bool
}

enum CrossReferenceType {
    case section, farReference, dfarReference, cfrReference, uscReference
}

struct ParseError {
    let type: ErrorType
    let message: String
    let location: String
}

struct ParseWarning {
    let type: WarningType
    let message: String
    let suggestion: String
}

struct RecoveryAction {
    let type: RecoveryType
    let description: String
    let applied: Bool
}

struct MemoryUsageInfo {
    let peakMB: Double
    let averageMB: Double
}

struct FormattingInfo {
    let type: String
    let preserved: Bool
    let fallbackUsed: Bool
}

struct NestedListStructure {
    let depth: Int
    let type: ListType
    let parentIndex: Int?
}

struct NestedStructureInfo {
    let maxDepth: Int
    let totalElements: Int
}

enum ErrorType {
    case parsing, encoding, structure
}

enum WarningType {
    case malformedStructure, missingMetadata, encodingIssue
}

enum RecoveryType {
    case structureRepair, encodingCorrection, contentExtraction
}

// RegulationHTMLParser and MemoryMonitor implementations are in the main AIKO module
