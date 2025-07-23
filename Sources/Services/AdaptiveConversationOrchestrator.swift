import AppCore
import Foundation
import SwiftUI

// MARK: - Adaptive Conversation Orchestrator

// This orchestrator implements the conversational flow architecture to minimize user questions

public final class AdaptiveConversationOrchestrator: ObservableObject, @unchecked Sendable {
    // MARK: - Published Properties

    @Published public private(set) var currentFlow: ConversationFlow?
    @Published public private(set) var currentPrompt: AdaptivePrompt?
    @Published public private(set) var sessionState: SessionState = .idle
    @Published public private(set) var progress: ConversationProgress = .init()

    // MARK: - Dependencies

    private let promptingEngine: AdaptivePromptingEngineProtocol
    private let flowManager: ConversationalFlowManager
    private let intelligenceService: AdaptiveIntelligenceService
    private var currentSession: ConversationSession?

    // MARK: - Configuration

    public struct Configuration {
        public var enableAutoSuggestions: Bool = true
        public var showConfidenceIndicators: Bool = true
        public var useNaturalLanguageProcessing: Bool = true
        public var maxRetries: Int = 2
        public var suggestionAcceptanceThreshold: Float = 0.75

        public init() {}
    }

    public var configuration = Configuration()

    // MARK: - Initialization

    public init(
        promptingEngine: AdaptivePromptingEngineProtocol,
        intelligenceService: AdaptiveIntelligenceService
    ) {
        self.promptingEngine = promptingEngine
        flowManager = ConversationalFlowManager(promptingEngine: promptingEngine)
        self.intelligenceService = intelligenceService

        setupFlowDelegate()
    }

    private func setupFlowDelegate() {
        flowManager.delegate = self
    }

    // MARK: - Public Interface

    public func startAcquisitionConversation(
        type: AcquisitionType,
        documents: [ParsedDocument] = [],
        userProfile: ConversationUserProfile? = nil
    ) async {
        sessionState = .initializing

        // Build conversation context
        let context = await ConversationContext(
            acquisitionType: convertToAPEAcquisitionType(type),
            uploadedDocuments: documents,
            userProfile: userProfile,
            historicalData: loadHistoricalData(for: userProfile)
        )

        // Initialize conversation flow
        currentFlow = await flowManager.initiateConversation(with: context)

        // Start prompting session
        currentSession = await promptingEngine.startConversation(with: context)

        // Present first prompt
        await presentNextPrompt()

        sessionState = .active
    }

    public func submitResponse(_ response: String) async {
        guard let session = currentSession,
              let currentQuestion = currentPrompt?.question else { return }

        sessionState = .processing

        // Create user response
        let userResponse = UserResponse(
            questionId: currentQuestion.id.uuidString,
            responseType: determineResponseType(from: response, question: currentQuestion),
            value: parseResponse(response, for: currentQuestion),
            confidence: analyzeResponseConfidence(response)
        )

        // Process response
        if let nextPrompt = try? await promptingEngine.processUserResponse(userResponse, in: session) {
            // Update current prompt
            currentPrompt = AdaptivePrompt(from: nextPrompt)

            // Update progress
            updateProgress()

            sessionState = .active
        } else {
            // Conversation complete
            await completeConversation()
        }
    }

    public func skipCurrentQuestion() async {
        guard let session = currentSession,
              let currentQuestion = currentPrompt?.question else { return }

        let skipResponse = UserResponse(
            questionId: currentQuestion.id.uuidString,
            responseType: .skip,
            value: NSNull(),
            confidence: 0
        )

        if let nextPrompt = try? await promptingEngine.processUserResponse(skipResponse, in: session) {
            currentPrompt = AdaptivePrompt(from: nextPrompt)
            updateProgress()
        } else {
            await completeConversation()
        }
    }

    public func acceptSuggestion() async {
        guard let suggestion = currentPrompt?.suggestedValue else { return }

        // Convert suggestion to response
        let response = String(describing: suggestion)
        await submitResponse(response)
    }

    // MARK: - Private Methods

    private func presentNextPrompt() async {
        guard let flow = currentFlow,
              !flow.currentQuestions.isEmpty
        else {
            await completeConversation()
            return
        }

        // Get next question from current stage
        let nextQuestion = flow.currentQuestions.first!

        // Get smart defaults
        let smartDefault = await promptingEngine.getSmartDefaults(for: nextQuestion.field)

        // Check if we can auto-fill with high confidence
        if let prefilled = flow.prefilledData[nextQuestion.field],
           let confidence = flow.confidenceMap[nextQuestion.field],
           confidence >= configuration.suggestionAcceptanceThreshold {
            // Auto-accept high confidence prefilled data
            let autoResponse = UserResponse(
                questionId: nextQuestion.id.uuidString,
                responseType: .text,
                value: prefilled,
                confidence: confidence
            )

            if let _ = try? await promptingEngine.processUserResponse(autoResponse, in: currentSession!) {
                // Continue to next question
                await presentNextPrompt()
            } else {
                await completeConversation()
            }

        } else {
            // Present question to user
            currentPrompt = AdaptivePrompt(
                question: nextQuestion,
                suggestedValue: smartDefault?.value ?? flow.prefilledData[nextQuestion.field],
                suggestionConfidence: smartDefault?.confidence ?? flow.confidenceMap[nextQuestion.field] ?? 0,
                helpContext: generateHelpContext(for: nextQuestion)
            )
        }
    }

    private func generateHelpContext(for question: DynamicQuestion) -> HelpContext {
        var examples: [String] = []
        var tips: [String] = []

        switch question.field {
        case .projectTitle:
            examples = ["Q1 2025 Office Supplies", "Annual IT Equipment Refresh", "Emergency Generator Maintenance"]
            tips = ["Use a descriptive title that helps identify the acquisition later"]

        case .estimatedValue:
            examples = ["50000", "125000.50", "2500000"]
            tips = ["Include all costs (products, services, shipping, etc.)", "Use numbers only, no currency symbols"]

        case .requiredDate:
            examples = ["March 15, 2025", "End of Q2 2025", "Within 30 days"]
            tips = ["Consider lead times and approval processes", "Allow buffer for unexpected delays"]

        case .vendorName:
            examples = ["Acme Corporation", "TechSupply Inc.", "Global Services LLC"]
            tips = ["Use the full legal business name if known", "You can leave blank if no preference"]

        default:
            break
        }

        return HelpContext(
            examples: examples,
            tips: tips,
            relatedFields: getRelatedFields(for: question.field)
        )
    }

    private func getRelatedFields(for field: RequirementField) -> [RequirementField] {
        switch field {
        case .vendorName:
            [.vendorUEI, .vendorCAGE]
        case .estimatedValue:
            [.contractType, .setAsideType]
        case .requiredDate:
            [.performanceLocation]
        default:
            []
        }
    }

    private func updateProgress() {
        guard let session = currentSession,
              let flow = currentFlow else { return }

        let totalQuestions = session.questionHistory.count + session.remainingQuestions.count
        let answeredQuestions = session.questionHistory.count

        progress = ConversationProgress(
            totalQuestions: totalQuestions,
            answeredQuestions: answeredQuestions,
            skippedQuestions: session.questionHistory.filter(\.skipped).count,
            currentStage: flow.currentStage + 1,
            totalStages: flow.stages.count,
            estimatedTimeRemaining: estimateTimeRemaining(questionsLeft: session.remainingQuestions.count)
        )
    }

    private func estimateTimeRemaining(questionsLeft: Int) -> TimeInterval {
        // Estimate 30 seconds per question on average
        TimeInterval(questionsLeft * 30)
    }

    private func completeConversation() async {
        sessionState = .completing

        guard let session = currentSession else { return }

        // Generate acquisition package
        let package = AcquisitionPackage(
            id: UUID(),
            title: session.collectedData.projectTitle ?? "Untitled Acquisition",
            type: session.collectedData.acquisitionType ?? "Unknown",
            data: session.collectedData,
            confidence: session.confidence,
            generatedDate: Date(),
            questionCount: session.questionHistory.count
        )

        // Save to history
        await saveToHistory(package)

        // Update state
        sessionState = .completed(package)

        // Reset for next conversation
        currentSession = nil
        currentFlow = nil
        currentPrompt = nil
    }

    private func convertToAPEAcquisitionType(_ type: AcquisitionType) -> APEAcquisitionType {
        switch type {
        case .simplifiedAcquisition, .commercialItem:
            .supplies
        case .nonCommercialService:
            .services
        case .constructionProject:
            .construction
        case .researchDevelopment, .otherTransaction:
            .researchAndDevelopment
        case .majorSystem:
            .services // Major systems are typically services
        }
    }

    private func loadHistoricalData(for _: ConversationUserProfile?) async -> [HistoricalAcquisition] {
        // Load from persistence
        // For now, return empty array
        []
    }

    private func saveToHistory(_: AcquisitionPackage) async {
        // Save to persistence
        // Implementation depends on storage strategy
    }

    private func determineResponseType(from response: String, question: DynamicQuestion) -> UserResponse.ResponseType {
        if response.isEmpty {
            return .skip
        }

        switch question.responseType {
        case .numeric:
            return Double(response) != nil ? .numeric : .text
        case .date:
            return .date // Would need date parsing logic
        case .selection:
            return .selection
        case .boolean:
            let lowercased = response.lowercased()
            return (lowercased == "yes" || lowercased == "no") ? .boolean : .text
        default:
            return .text
        }
    }

    private func parseResponse(_ response: String, for question: DynamicQuestion) -> Any {
        switch question.responseType {
        case .numeric:
            Double(response) ?? response
        case .boolean:
            response.lowercased() == "yes"
        case .date:
            // Parse date - would need proper implementation
            response
        default:
            response
        }
    }

    private func analyzeResponseConfidence(_ response: String) -> Float {
        let uncertainWords = ["maybe", "possibly", "think", "guess", "approximately", "around"]
        let lowercased = response.lowercased()

        let hasUncertainty = uncertainWords.contains { lowercased.contains($0) }
        return hasUncertainty ? 0.7 : 0.95
    }
}

// MARK: - Flow Manager Delegate

extension AdaptiveConversationOrchestrator: ConversationalFlowDelegate {
    public func conversationDidUpdateProgress(_ progress: Float) {
        // Update UI progress indicator
        self.progress.overallProgress = progress
    }

    public func conversationDidChangeState(_: ConversationState) {
        // Handle state changes
    }

    public func conversationDidSuggestValue(for _: RequirementField, suggestion _: Any, confidence: Float) {
        // Handle suggestions
        if configuration.enableAutoSuggestions, confidence >= configuration.suggestionAcceptanceThreshold {
            // Could auto-accept high confidence suggestions
        }
    }
}

// MARK: - Supporting Types

public struct AdaptivePrompt {
    public let question: DynamicQuestion
    public let suggestedValue: Any?
    public let suggestionConfidence: Float
    public let helpContext: HelpContext
    public let isRequired: Bool

    public init(
        question: DynamicQuestion,
        suggestedValue: Any? = nil,
        suggestionConfidence: Float = 0,
        helpContext: HelpContext = HelpContext()
    ) {
        self.question = question
        self.suggestedValue = suggestedValue
        self.suggestionConfidence = suggestionConfidence
        self.helpContext = helpContext
        isRequired = question.priority == .critical
    }

    public init(from nextPrompt: NextPrompt) {
        question = nextPrompt.question
        suggestedValue = nextPrompt.suggestedAnswer
        suggestionConfidence = nextPrompt.confidenceInSuggestion
        helpContext = HelpContext()
        isRequired = nextPrompt.isRequired
    }
}

public struct HelpContext {
    public let examples: [String]
    public let tips: [String]
    public let relatedFields: [RequirementField]

    public init(
        examples: [String] = [],
        tips: [String] = [],
        relatedFields: [RequirementField] = []
    ) {
        self.examples = examples
        self.tips = tips
        self.relatedFields = relatedFields
    }
}

public enum SessionState {
    case idle
    case initializing
    case active
    case processing
    case completing
    case completed(AcquisitionPackage)
    case error(Error)
}

public struct ConversationProgress {
    public var totalQuestions: Int = 0
    public var answeredQuestions: Int = 0
    public var skippedQuestions: Int = 0
    public var currentStage: Int = 0
    public var totalStages: Int = 0
    public var estimatedTimeRemaining: TimeInterval = 0
    public var overallProgress: Float = 0

    public var percentComplete: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Float(answeredQuestions) / Float(totalQuestions)) * 100)
    }
}

public struct AcquisitionPackage {
    public let id: UUID
    public let title: String
    public let type: String
    public let data: RequirementsData
    public let confidence: ConfidenceLevel
    public let generatedDate: Date
    public let questionCount: Int
}
