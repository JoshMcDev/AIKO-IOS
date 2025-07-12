import XCTest
@testable import AIKO

final class AdaptivePromptingEngineTests: XCTestCase {
    var engine: AdaptivePromptingEngine!
    
    override func setUp() {
        super.setUp()
        engine = AdaptivePromptingEngine()
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    // MARK: - Conversation Start Tests
    
    func testStartConversationWithoutDocuments() async {
        // Given
        let context = ConversationContext(
            acquisitionType: .supplies,
            uploadedDocuments: [],
            userProfile: nil,
            historicalData: []
        )
        
        // When
        let session = await engine.startConversation(with: context)
        
        // Then
        XCTAssertEqual(session.state, .gatheringBasicInfo)
        XCTAssertTrue(session.remainingQuestions.count > 0)
        XCTAssertTrue(session.questionHistory.isEmpty)
        XCTAssertEqual(session.confidence, .low)
    }
    
    func testStartConversationWithDocuments() async throws {
        // Given
        let mockDocument = createMockParsedDocument()
        let context = ConversationContext(
            acquisitionType: .supplies,
            uploadedDocuments: [mockDocument],
            userProfile: nil,
            historicalData: []
        )
        
        // When
        let session = await engine.startConversation(with: context)
        
        // Then
        XCTAssertEqual(session.state, .gatheringBasicInfo)
        // Should have fewer questions since we extracted data from document
        XCTAssertTrue(session.remainingQuestions.count > 0)
    }
    
    // MARK: - User Response Processing Tests
    
    func testProcessUserResponseTextInput() async throws {
        // Given
        let context = ConversationContext(acquisitionType: .supplies)
        let session = await engine.startConversation(with: context)
        
        guard let firstQuestion = session.remainingQuestions.first else {
            XCTFail("No questions generated")
            return
        }
        
        let response = UserResponse(
            questionId: firstQuestion.id.uuidString,
            responseType: .text,
            value: "Office Supplies for Q1 2025"
        )
        
        // When
        let nextPrompt = try await engine.processUserResponse(response, in: session)
        
        // Then
        XCTAssertNotNil(nextPrompt)
        XCTAssertNotEqual(nextPrompt?.question.id, firstQuestion.id)
    }
    
    func testProcessUserResponseSkip() async throws {
        // Given
        let context = ConversationContext(acquisitionType: .services)
        let session = await engine.startConversation(with: context)
        
        guard let firstQuestion = session.remainingQuestions.first else {
            XCTFail("No questions generated")
            return
        }
        
        let response = UserResponse(
            questionId: firstQuestion.id.uuidString,
            responseType: .skip,
            value: ""
        )
        
        // When
        let nextPrompt = try await engine.processUserResponse(response, in: session)
        
        // Then
        XCTAssertNotNil(nextPrompt)
        // Should move to next question
        XCTAssertNotEqual(nextPrompt?.question.id, firstQuestion.id)
    }
    
    // MARK: - Context Extraction Tests
    
    func testExtractContextFromDocuments() async throws {
        // Given
        let documents = [createMockParsedDocument()]
        
        // When
        let context = try await engine.extractContextFromDocuments(documents)
        
        // Then
        XCTAssertNotNil(context.vendorInfo)
        XCTAssertNotNil(context.pricing)
        XCTAssertTrue(context.technicalDetails.count > 0)
        XCTAssertTrue(context.confidence.count > 0)
    }
    
    // MARK: - Smart Defaults Tests
    
    func testLearnFromInteraction() async {
        // Given
        let interaction = APEUserInteraction(
            sessionId: UUID(),
            field: .vendorName,
            suggestedValue: "ACME Corp",
            acceptedSuggestion: true,
            finalValue: "ACME Corp",
            timeToRespond: 2.5,
            documentContext: false
        )
        
        // When
        await engine.learnFromInteraction(interaction)
        
        // Then
        // Interaction should be recorded for future defaults
        let defaults = await engine.getSmartDefaults(for: .vendorName)
        // May be nil if not enough patterns yet
        XCTAssertTrue(defaults == nil || defaults?.source == .userPattern)
    }
    
    func testSmartDefaultsAfterMultipleInteractions() async {
        // Given - simulate multiple interactions with same vendor
        let sessionId = UUID()
        for i in 0..<5 {
            let interaction = APEUserInteraction(
                sessionId: sessionId,
                field: .vendorName,
                suggestedValue: nil,
                acceptedSuggestion: false,
                finalValue: "ACME Corp",
                timeToRespond: TimeInterval(i),
                documentContext: false
            )
            await engine.learnFromInteraction(interaction)
        }
        
        // When
        let defaults = await engine.getSmartDefaults(for: .vendorName)
        
        // Then
        XCTAssertNotNil(defaults)
        XCTAssertEqual(defaults?.value as? String, "ACME Corp")
        XCTAssertEqual(defaults?.source, .userPattern)
        XCTAssertGreaterThan(defaults?.confidence ?? 0, 0.6)
    }
    
    // MARK: - Question Priority Tests
    
    func testQuestionPriorityOrdering() async {
        // Given
        let context = ConversationContext(acquisitionType: .construction)
        
        // When
        let session = await engine.startConversation(with: context)
        
        // Then
        let priorities = session.remainingQuestions.map { $0.priority }
        // Critical questions should come first
        for i in 1..<priorities.count {
            XCTAssertTrue(priorities[i-1] <= priorities[i])
        }
    }
    
    // MARK: - Historical Data Adaptation Tests
    
    func testAdaptationWithHistoricalData() async {
        // Given
        let historicalAcquisition = HistoricalAcquisition(
            date: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            type: .supplies,
            data: RequirementsData(
                projectTitle: "Office Supplies Q4 2024",
                vendorInfo: APEVendorInfo(name: "ACME Corp")
            ),
            vendor: APEVendorInfo(name: "ACME Corp")
        )
        
        let context = ConversationContext(
            acquisitionType: .supplies,
            uploadedDocuments: [],
            userProfile: nil,
            historicalData: [historicalAcquisition]
        )
        
        // When
        let session = await engine.startConversation(with: context)
        
        // Then
        // Should adapt questions based on historical data
        let vendorQuestion = session.remainingQuestions.first { $0.field == .vendorName }
        XCTAssertNotNil(vendorQuestion)
        // May suggest ACME Corp based on history
    }
    
    // MARK: - Helper Methods
    
    private func createMockParsedDocument() -> ParsedDocument {
        let extractedData = ExtractedData(
            entities: [
                ExtractedEntity(
                    type: .vendor,
                    value: "Test Vendor Inc",
                    confidence: 0.9,
                    location: ExtractedLocation(page: 1, boundingBox: nil)
                ),
                ExtractedEntity(
                    type: .price,
                    value: "25000.00",
                    confidence: 0.85,
                    location: ExtractedLocation(page: 1, boundingBox: nil)
                )
            ],
            relationships: [],
            tables: [],
            summary: "Quote for office supplies from Test Vendor Inc"
        )
        
        let metadata = ParsedDocumentMetadata(
            fileName: "test_quote.pdf",
            fileSize: 1024,
            pageCount: 2
        )
        
        return ParsedDocument(
            sourceType: .pdf,
            extractedText: """
            QUOTE
            Vendor: Test Vendor Inc
            UEI: TESTVENDOR12
            
            Items:
            - Office Chairs - Qty: 10 - $200 each
            - Desks - Qty: 5 - $500 each
            
            Total: $25,000.00
            
            Delivery Date: 30 days from order
            Terms: Net 30
            """,
            metadata: metadata,
            extractedData: extractedData,
            confidence: 0.85
        )
    }
}

// MARK: - Integration Tests

final class AdaptivePromptingIntegrationTests: XCTestCase {
    var engine: AdaptivePromptingEngine!
    var documentParser: DocumentParserEnhanced!
    
    override func setUp() {
        super.setUp()
        engine = AdaptivePromptingEngine()
        documentParser = DocumentParserEnhanced()
    }
    
    func testEndToEndDocumentProcessing() async throws {
        // Given - simulate a PDF quote
        let pdfData = createMockPDFData()
        
        // When - parse document
        let parsedDoc = try await documentParser.parse(pdfData, type: .pdf)
        
        // Extract context
        let extractedContext = try await engine.extractContextFromDocuments([parsedDoc])
        
        // Start conversation with context
        let conversationContext = ConversationContext(
            acquisitionType: .supplies,
            uploadedDocuments: [parsedDoc]
        )
        let session = await engine.startConversation(with: conversationContext)
        
        // Then
        XCTAssertNotNil(extractedContext.vendorInfo)
        XCTAssertNotNil(session.collectedData.vendorInfo)
        // Should have pre-filled some data
        XCTAssertNotEqual(session.confidence, .low)
    }
    
    private func createMockPDFData() -> Data {
        // Create simple PDF-like data for testing
        // In real tests, would load actual test PDF
        return Data("Mock PDF content".utf8)
    }
}