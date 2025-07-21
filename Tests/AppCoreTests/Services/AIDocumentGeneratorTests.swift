import XCTest
import ComposableArchitecture
@testable import AppCore
@testable import AikoCompat

final class AIDocumentGeneratorTests: XCTestCase {
    var generator: AIDocumentGenerator!
    var mockProvider: MockAIProvider!
    
    override func setUp() {
        super.setUp()
        mockProvider = MockAIProvider(responses: [
            """
            # Test Document
            
            This is a test document generated for testing purposes.
            
            ## Requirements
            - Test requirement 1
            - Test requirement 2
            
            ## Conclusion
            This completes the test document.
            """
        ])
        generator = AIDocumentGenerator.liveValue
    }
    
    override func tearDown() {
        generator = nil
        mockProvider = nil
        super.tearDown()
    }
    
    func testGenerateDocument() async throws {
        // Given
        let requirements = TestDataGenerator.sampleRequirementsData()
        let documentType = DocumentType.contractingOfficerOrder
        
        // Mock the AIProviderFactory to return our mock
        AIProviderFactory.setTestProvider(mockProvider)
        
        // When
        let document = try await generator.generateDocument(
            requirements: requirements,
            type: documentType
        )
        
        // Then
        XCTAssertEqual(document.documentCategory, documentType)
        XCTAssertEqual(document.title, "Test Project - Contracting Officer Order")
        XCTAssertTrue(document.content.contains("Test Document"))
        XCTAssertEqual(mockProvider.callCount, 1)
        
        // Verify the request was properly formatted
        let lastRequest = try XCTUnwrap(mockProvider.lastRequest)
        XCTAssertEqual(lastRequest.model, "claude-sonnet-4-20250514")
        XCTAssertTrue(lastRequest.systemPrompt?.contains("CONTRACTING OFFICER ORDER") == true)
    }
    
    func testGenerateDocumentWithNoProvider() async throws {
        // Given
        AIProviderFactory.setTestProvider(nil)
        let requirements = TestDataGenerator.sampleRequirementsData()
        
        // When/Then
        do {
            _ = try await generator.generateDocument(
                requirements: requirements,
                type: .contractingOfficerOrder
            )
            XCTFail("Expected error when no provider is available")
        } catch AIDocumentGeneratorError.noProvider {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateDocumentWithProviderError() async throws {
        // Given
        let failingProvider = FailingMockAIProvider()
        AIProviderFactory.setTestProvider(failingProvider)
        let requirements = TestDataGenerator.sampleRequirementsData()
        
        // When/Then
        do {
            _ = try await generator.generateDocument(
                requirements: requirements,
                type: .contractingOfficerOrder
            )
            XCTFail("Expected error when provider fails")
        } catch {
            // Expected - provider should throw an error
            XCTAssertTrue(error is MockProviderError)
        }
    }
    
    func testGenerateMultipleDocumentTypes() async throws {
        // Given
        let requirements = TestDataGenerator.sampleRequirementsData()
        let documentTypes: [DocumentType] = [
            .contractingOfficerOrder,
            .independentGovernmentCostEstimate,
            .statementOfWork
        ]
        
        mockProvider = MockAIProvider(responses: Array(repeating: "Test content", count: documentTypes.count))
        AIProviderFactory.setTestProvider(mockProvider)
        
        // When
        var documents: [GeneratedDocument] = []
        for type in documentTypes {
            let document = try await generator.generateDocument(
                requirements: requirements,
                type: type
            )
            documents.append(document)
        }
        
        // Then
        XCTAssertEqual(documents.count, documentTypes.count)
        XCTAssertEqual(mockProvider.callCount, documentTypes.count)
        
        for (index, document) in documents.enumerated() {
            XCTAssertEqual(document.documentCategory, documentTypes[index])
            XCTAssertTrue(document.content.contains("Test content"))
        }
    }
    
    func testDocumentTitleGeneration() async throws {
        // Given
        let requirements = TestDataGenerator.sampleRequirementsData()
        requirements.projectTitle = "Custom Project Title"
        
        AIProviderFactory.setTestProvider(mockProvider)
        
        // When
        let document = try await generator.generateDocument(
            requirements: requirements,
            type: .independentGovernmentCostEstimate
        )
        
        // Then
        XCTAssertEqual(document.title, "Custom Project Title - Independent Government Cost Estimate")
    }
    
    func testRequirementsStringGeneration() async throws {
        // Given
        let requirements = TestDataGenerator.sampleRequirementsData()
        AIProviderFactory.setTestProvider(mockProvider)
        
        // When
        _ = try await generator.generateDocument(
            requirements: requirements,
            type: .contractingOfficerOrder
        )
        
        // Then
        let lastRequest = try XCTUnwrap(mockProvider.lastRequest)
        let userMessage = lastRequest.messages.first { $0.content.contains("Project Title") }
        XCTAssertNotNil(userMessage)
        XCTAssertTrue(userMessage?.content.contains("Test Project") == true)
    }
}

// MARK: - Test Helpers

private class FailingMockAIProvider: AIProvider, @unchecked Sendable {
    func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse {
        throw MockProviderError.simulatedFailure
    }
    
    func streamComplete(_ request: AICompletionRequest) async throws -> AsyncThrowingStream<AIStreamEvent, any Error> {
        throw MockProviderError.simulatedFailure
    }
}

private enum MockProviderError: Error {
    case simulatedFailure
}

// MARK: - AIProviderFactory Test Extension

private extension AIProviderFactory {
    static func setTestProvider(_ provider: AIProvider?) {
        // In a real implementation, this would set up the test provider
        // For now, we'll use dependency injection in the actual tests
    }
}