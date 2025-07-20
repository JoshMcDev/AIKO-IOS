import XCTest
import ComposableArchitecture
@testable import AppCore

final class AcquisitionChatFeatureTests: XCTestCase {
    
    func testInitialState() {
        let state = AcquisitionChatFeature.State()
        
        XCTAssertTrue(state.messages.count > 0)
        XCTAssertEqual(state.currentInput, "")
        XCTAssertFalse(state.isProcessing)
        XCTAssertEqual(state.currentPhase, .initial)
        XCTAssertTrue(state.gatheredRequirements.projectTitle?.isEmpty != false)
    }
    
    func testUpdateInputAction() async {
        let store = TestStore(initialState: AcquisitionChatFeature.State()) {
            AcquisitionChatFeature()
        }
        
        await store.send(.updateInput("Test input")) {
            $0.currentInput = "Test input"
        }
    }
    
    func testSendMessageAction() async {
        let store = TestStore(initialState: AcquisitionChatFeature.State()) {
            AcquisitionChatFeature()
        } withDependencies: {
            $0.testAIProvider = MockAIProvider(responses: ["Test AI response"])
        }
        
        // Set input first
        await store.send(.updateInput("Hello, I need office supplies")) {
            $0.currentInput = "Hello, I need office supplies"
        }
        
        // Send message
        await store.send(.sendMessage) {
            $0.currentInput = ""
            $0.isProcessing = true
            $0.messages.append(ChatMessage(role: .user, content: "Hello, I need office supplies"))
        }
        
        // Wait for processing to complete
        await store.receive(.messageProcessed) {
            $0.isProcessing = false
            $0.currentPhase = .gatheringBasics
            $0.messages.append(ChatMessage(role: .assistant, content: "Test AI response"))
        }
    }
    
    func testPhaseTransitions() async {
        let store = TestStore(initialState: AcquisitionChatFeature.State()) {
            AcquisitionChatFeature()
        } withDependencies: {
            $0.testAIProvider = MockAIProvider(responses: [
                "Great! I'll help you with office supplies.",
                "What's your estimated budget?",
                "Perfect! Let me analyze your requirements."
            ])
        }
        
        var state = AcquisitionChatFeature.State()
        
        // Initial -> GatheringBasics
        state.currentInput = "I need office supplies"
        await store.send(.updateInput("I need office supplies")) {
            $0.currentInput = "I need office supplies"
        }
        
        await store.send(.sendMessage) {
            $0.currentInput = ""
            $0.isProcessing = true
            $0.messages.append(ChatMessage(role: .user, content: "I need office supplies"))
        }
        
        await store.receive(.messageProcessed) {
            $0.isProcessing = false
            $0.currentPhase = .gatheringBasics
            $0.gatheredRequirements.description = "I need office supplies"
        }
    }
    
    func testRequirementsGathering() async {
        var state = AcquisitionChatFeature.State()
        state.currentPhase = .gatheringBasics
        
        let store = TestStore(initialState: state) {
            AcquisitionChatFeature()
        } withDependencies: {
            $0.testAIProvider = MockAIProvider(responses: ["Understood. What's the estimated value?"])
        }
        
        // Test gathering estimated value
        await store.send(.updateInput("$25,000")) {
            $0.currentInput = "$25,000"
        }
        
        await store.send(.sendMessage) {
            $0.currentInput = ""
            $0.isProcessing = true
            $0.messages.append(ChatMessage(role: .user, content: "$25,000"))
        }
        
        await store.receive(.messageProcessed) {
            $0.isProcessing = false
            $0.gatheredRequirements.estimatedValue = 25000.0
        }
    }
    
    func testDocumentRecommendation() async {
        var state = AcquisitionChatFeature.State()
        state.currentPhase = .readyToGenerate
        state.gatheredRequirements = TestDataGenerator.sampleRequirementsData()
        
        let store = TestStore(initialState: state) {
            AcquisitionChatFeature()
        }
        
        // Simulate document recommendation
        await store.send(.recommendDocuments([.contractingOfficerOrder, .independentGovernmentCostEstimate])) {
            $0.recommendedDocuments = [.contractingOfficerOrder, .independentGovernmentCostEstimate]
            $0.documentReadiness[.contractingOfficerOrder] = true
            $0.documentReadiness[.independentGovernmentCostEstimate] = true
        }
    }
    
    func testGenerateDocumentsAction() async {
        var state = AcquisitionChatFeature.State()
        state.currentPhase = .readyToGenerate
        state.gatheredRequirements = TestDataGenerator.sampleRequirementsData()
        state.recommendedDocuments = [.contractingOfficerOrder]
        state.documentReadiness[.contractingOfficerOrder] = true
        
        let store = TestStore(initialState: state) {
            AcquisitionChatFeature()
        } withDependencies: {
            $0.documentGenerator = TestUtilities.createMockDocumentGenerator()
            $0.acquisitionService = MockAcquisitionService()
        }
        
        await store.send(.generateDocuments) {
            $0.isProcessing = true
        }
        
        await store.receive(.documentsGenerated([TestDataGenerator.sampleGeneratedDocument()])) {
            $0.isProcessing = false
        }
    }
    
    func testInputPlaceholderText() {
        let state = AcquisitionChatFeature.State()
        
        // Test initial placeholder
        XCTAssertEqual(state.inputPlaceholder, "Describe the product or service you need...")
        
        // Test gathering basics placeholder
        var gatheringState = state
        gatheringState.currentPhase = .gatheringBasics
        XCTAssertEqual(gatheringState.inputPlaceholder, "Enter the estimated dollar value (e.g., $50,000)...")
        
        // Test ready to generate placeholder
        var readyState = state
        readyState.currentPhase = .readyToGenerate
        XCTAssertEqual(readyState.inputPlaceholder, "Type 'generate all' or select specific documents...")
    }
    
    func testErrorHandling() async {
        let store = TestStore(initialState: AcquisitionChatFeature.State()) {
            AcquisitionChatFeature()
        } withDependencies: {
            $0.testAIProvider = FailingMockAIProvider()
        }
        
        await store.send(.updateInput("Test input")) {
            $0.currentInput = "Test input"
        }
        
        await store.send(.sendMessage) {
            $0.currentInput = ""
            $0.isProcessing = true
            $0.messages.append(ChatMessage(role: .user, content: "Test input"))
        }
        
        await store.receive(.error("AI provider error")) {
            $0.isProcessing = false
            $0.messages.append(ChatMessage(
                role: .assistant,
                content: "I'm sorry, I encountered an error processing your message. Please try again."
            ))
        }
    }
}

// MARK: - Test Helpers

private extension TestUtilities {
    static func createMockDocumentGenerator() -> DocumentGenerator {
        DocumentGenerator(
            generateDocument: { _, _ in
                TestDataGenerator.sampleGeneratedDocument()
            }
        )
    }
}

private class FailingMockAIProvider: AIProvider, @unchecked Sendable {
    func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse {
        throw TestError.aiProviderFailure
    }
}

private enum TestError: Error {
    case aiProviderFailure
}