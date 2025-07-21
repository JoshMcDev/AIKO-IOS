import AppCore
import Foundation

// MARK: - Conversational Flow Architecture

// This architecture defines how the adaptive prompting engine minimizes user questions
// while gathering complete acquisition requirements

public protocol ConversationalFlowDelegate: AnyObject {
    func conversationDidUpdateProgress(_ progress: Float)
    func conversationDidChangeState(_ newState: ConversationState)
    func conversationDidSuggestValue(for field: RequirementField, suggestion: Any, confidence: Float)
}

// MARK: - Core Flow Manager

public final class ConversationalFlowManager: @unchecked Sendable {
    // MARK: - Properties

    private let promptingEngine: AdaptivePromptingEngineProtocol
    private let contextAnalyzer: ContextualAnalyzer
    private let flowOptimizer: FlowOptimizer
    private let responsePredictor: ResponsePredictor

    weak var delegate: ConversationalFlowDelegate?

    // MARK: - Flow Configuration

    public struct FlowConfiguration {
        let maxQuestionsPerSession: Int = 10
        let minimumConfidenceToSkip: Float = 0.85
        let useProgressiveDisclosure: Bool = true
        let enableSmartGrouping: Bool = true
        let adaptiveQuestionTiming: Bool = true
    }

    private let configuration = FlowConfiguration()

    // MARK: - Initialization

    public init(promptingEngine: AdaptivePromptingEngineProtocol) {
        self.promptingEngine = promptingEngine
        contextAnalyzer = ContextualAnalyzer()
        flowOptimizer = FlowOptimizer()
        responsePredictor = ResponsePredictor()
    }

    // MARK: - Flow Orchestration

    public func initiateConversation(with context: ConversationContext) async -> ConversationFlow {
        // 1. Analyze uploaded documents for pre-filled data
        let documentInsights = await analyzeDocuments(context.uploadedDocuments)

        // 2. Predict user responses based on historical patterns
        let predictions = await predictResponses(context: context)

        // 3. Optimize question flow
        let optimizedFlow = await flowOptimizer.optimize(
            baseQuestions: generateBaseQuestions(context),
            documentInsights: documentInsights,
            predictions: predictions,
            userProfile: context.userProfile
        )

        // 4. Create conversation flow
        return ConversationFlow(
            stages: optimizedFlow.stages,
            currentStage: 0,
            totalQuestions: optimizedFlow.estimatedQuestions,
            prefilledData: documentInsights.extractedData,
            confidenceMap: documentInsights.confidence
        )
    }

    // MARK: - Document Analysis

    private func analyzeDocuments(_ documents: [ParsedDocument]) async -> DocumentInsights {
        // Extract all possible data from documents to minimize questions
        let extractedContext = try? await promptingEngine.extractContextFromDocuments(documents)

        var insights = DocumentInsights()

        if let context = extractedContext {
            // Vendor information
            if let vendor = context.vendorInfo {
                insights.extractedData[.vendorName] = vendor.name
                insights.extractedData[.vendorUEI] = vendor.uei
                insights.extractedData[.vendorCAGE] = vendor.cage
                insights.confidence[.vendorName] = context.confidence[.vendorName] ?? 0
            }

            // Pricing information
            if let pricing = context.pricing {
                insights.extractedData[.estimatedValue] = pricing.totalPrice
                insights.confidence[.estimatedValue] = context.confidence[.estimatedValue] ?? 0
            }

            // Dates
            if let dates = context.dates {
                insights.extractedData[.requiredDate] = dates.deliveryDate
                insights.confidence[.requiredDate] = context.confidence[.requiredDate] ?? 0
            }

            // Technical details
            if !context.technicalDetails.isEmpty {
                insights.extractedData[.technicalSpecs] = context.technicalDetails.joined(separator: "\n")
                insights.confidence[.technicalSpecs] = context.confidence[.technicalSpecs] ?? 0
            }
        }

        return insights
    }

    // MARK: - Response Prediction

    private func predictResponses(context: ConversationContext) async -> ResponsePredictions {
        var predictions = ResponsePredictions()

        // Analyze historical patterns
        for acquisition in context.historicalData {
            // Vendor patterns
            if let vendor = acquisition.vendor?.name {
                predictions.recordPattern(field: .vendorName, value: vendor)
            }

            // Contract type patterns
            if let contractType = acquisition.data.acquisitionType {
                predictions.recordPattern(field: .contractType, value: contractType)
            }

            // Location patterns
            if let location = acquisition.data.placeOfPerformance {
                predictions.recordPattern(field: .performanceLocation, value: location)
            }
        }

        return predictions
    }

    // MARK: - Base Question Generation

    private func generateBaseQuestions(_ context: ConversationContext) async -> [DynamicQuestion] {
        let session = await promptingEngine.startConversation(with: context)
        return session.remainingQuestions
    }
}

// MARK: - Flow Optimizer

public final class FlowOptimizer: @unchecked Sendable {
    public func optimize(
        baseQuestions: [DynamicQuestion],
        documentInsights: DocumentInsights,
        predictions: ResponsePredictions,
        userProfile: ConversationUserProfile?
    ) async -> OptimizedFlow {
        var stages: [ConversationStage] = []
        var questionsToAsk: [DynamicQuestion] = []

        // Filter out questions we already have high-confidence answers for
        for question in baseQuestions {
            let confidence = documentInsights.confidence[question.field] ?? 0
            let hasPrediction = predictions.hasHighConfidencePrediction(for: question.field)

            if confidence < 0.85, !hasPrediction {
                questionsToAsk.append(question)
            }
        }

        // Group related questions into stages
        stages = groupQuestionsIntoStages(questionsToAsk)

        // Apply progressive disclosure
        stages = applyProgressiveDisclosure(stages, userProfile: userProfile)

        return OptimizedFlow(
            stages: stages,
            estimatedQuestions: questionsToAsk.count,
            skippedQuestions: baseQuestions.count - questionsToAsk.count
        )
    }

    private func groupQuestionsIntoStages(_ questions: [DynamicQuestion]) -> [ConversationStage] {
        var stages: [ConversationStage] = []

        // Stage 1: Essential Information
        let essentialQuestions = questions.filter { $0.priority == .critical }
        if !essentialQuestions.isEmpty {
            stages.append(ConversationStage(
                name: "Essential Information",
                questions: essentialQuestions,
                canSkip: false
            ))
        }

        // Stage 2: Key Details
        let keyQuestions = questions.filter { $0.priority == .high }
        if !keyQuestions.isEmpty {
            stages.append(ConversationStage(
                name: "Key Details",
                questions: keyQuestions,
                canSkip: false
            ))
        }

        // Stage 3: Additional Information
        let additionalQuestions = questions.filter { $0.priority == .medium || $0.priority == .low }
        if !additionalQuestions.isEmpty {
            stages.append(ConversationStage(
                name: "Additional Information",
                questions: additionalQuestions,
                canSkip: true
            ))
        }

        return stages
    }

    private func applyProgressiveDisclosure(_ stages: [ConversationStage], userProfile: ConversationUserProfile?) -> [ConversationStage] {
        guard let profile = userProfile else { return stages }

        // For experienced users, combine stages
        if profile.experienceLevel == .expert, stages.count > 2 {
            let combinedQuestions = stages.flatMap(\.questions)
            return [ConversationStage(
                name: "Acquisition Details",
                questions: combinedQuestions,
                canSkip: false
            )]
        }

        return stages
    }
}

// MARK: - Contextual Analyzer

public final class ContextualAnalyzer: @unchecked Sendable {
    public func analyzeUserContext(_ response: UserResponse, session: ConversationSession) -> ContextualInsight {
        var insight = ContextualInsight()

        // Analyze response time
        insight.responseSpeed = categorizeResponseSpeed(response.timestamp.timeIntervalSinceNow)

        // Check for uncertainty indicators
        var textResponse: String?
        switch response.value {
        case .text(let text):
            textResponse = text
        case .selection(let selection):
            textResponse = selection
        default:
            textResponse = nil
        }

        if let text = textResponse {
            insight.certaintyLevel = analyzeCertainty(in: text)
            insight.requiresClarification = detectClarificationNeeds(in: text)
        }

        // Analyze session progress
        insight.sessionProgress = Float(session.questionHistory.count) / Float(session.questionHistory.count + session.remainingQuestions.count)

        return insight
    }

    private func categorizeResponseSpeed(_ interval: TimeInterval) -> ResponseSpeed {
        let seconds = abs(interval)
        if seconds < 5 { return .immediate }
        if seconds < 30 { return .quick }
        if seconds < 120 { return .normal }
        return .slow
    }

    private func analyzeCertainty(in text: String) -> CertaintyLevel {
        let uncertainPhrases = ["maybe", "i think", "not sure", "possibly", "might be", "approximately"]
        let certainPhrases = ["definitely", "yes", "exactly", "certain", "sure"]

        let lowercased = text.lowercased()

        if uncertainPhrases.contains(where: { lowercased.contains($0) }) {
            return .low
        }
        if certainPhrases.contains(where: { lowercased.contains($0) }) {
            return .high
        }

        return .medium
    }

    private func detectClarificationNeeds(in text: String) -> Bool {
        let clarificationIndicators = ["?", "what do you mean", "can you explain", "not clear"]
        let lowercased = text.lowercased()

        return clarificationIndicators.contains(where: { lowercased.contains($0) })
    }
}

// MARK: - Response Predictor

public final class ResponsePredictor: @unchecked Sendable {
    private var patternDatabase: [RequirementField: [String: Int]] = [:]

    public func predictResponse(for field: RequirementField, context _: PredictionContext) -> PredictedResponse? {
        // Check if we have enough pattern data
        guard let patterns = patternDatabase[field],
              let mostCommon = patterns.max(by: { $0.value < $1.value })
        else {
            return nil
        }

        let totalOccurrences = patterns.values.reduce(0, +)
        let confidence = Float(mostCommon.value) / Float(totalOccurrences)

        if confidence >= 0.7 {
            return PredictedResponse(
                value: mostCommon.key,
                confidence: confidence,
                source: .historicalPattern
            )
        }

        return nil
    }

    public func updatePatterns(field: RequirementField, value: String) {
        if patternDatabase[field] == nil {
            patternDatabase[field] = [:]
        }
        patternDatabase[field]?[value, default: 0] += 1
    }
}

// MARK: - Supporting Types

public struct ConversationFlow {
    public let stages: [ConversationStage]
    public var currentStage: Int
    public let totalQuestions: Int
    public let prefilledData: [RequirementField: Any]
    public let confidenceMap: [RequirementField: Float]

    public var progress: Float {
        guard !stages.isEmpty else { return 0 }
        return Float(currentStage) / Float(stages.count)
    }

    public var currentQuestions: [DynamicQuestion] {
        guard currentStage < stages.count else { return [] }
        return stages[currentStage].questions
    }

    public mutating func moveToNextStage() {
        if currentStage < stages.count - 1 {
            currentStage += 1
        }
    }
}

public struct ConversationStage {
    public let name: String
    public let questions: [DynamicQuestion]
    public let canSkip: Bool
}

public struct DocumentInsights {
    public var extractedData: [RequirementField: Any] = [:]
    public var confidence: [RequirementField: Float] = [:]
}

public struct ResponsePredictions {
    private var patterns: [RequirementField: [String: Int]] = [:]

    public mutating func recordPattern(field: RequirementField, value: String) {
        if patterns[field] == nil {
            patterns[field] = [:]
        }
        patterns[field]?[value, default: 0] += 1
    }

    public func hasHighConfidencePrediction(for field: RequirementField) -> Bool {
        guard let fieldPatterns = patterns[field],
              let maxCount = fieldPatterns.values.max()
        else {
            return false
        }

        let total = fieldPatterns.values.reduce(0, +)
        return Float(maxCount) / Float(total) >= 0.8
    }
}

public struct OptimizedFlow {
    public let stages: [ConversationStage]
    public let estimatedQuestions: Int
    public let skippedQuestions: Int
}

public struct ContextualInsight {
    public var responseSpeed: ResponseSpeed = .normal
    public var certaintyLevel: CertaintyLevel = .medium
    public var requiresClarification: Bool = false
    public var sessionProgress: Float = 0
}

public enum ResponseSpeed {
    case immediate // < 5 seconds
    case quick // 5-30 seconds
    case normal // 30-120 seconds
    case slow // > 120 seconds
}

public enum CertaintyLevel {
    case low
    case medium
    case high
}

public struct PredictionContext {
    public let acquisitionType: AcquisitionType
    public let previousResponses: [RequirementField: Any]
    public let userProfile: ConversationUserProfile?
}

public struct PredictedResponse {
    public let value: Any
    public let confidence: Float
    public let source: PredictionSource
}

public enum PredictionSource {
    case historicalPattern
    case documentContext
    case userProfile
    case systemDefault
}

// MARK: - User Profile Extension

public struct ConversationUserProfile: Sendable {
    public let id: UUID
    public let experienceLevel: ExperienceLevel
    public let preferredVendors: [String]
    public let commonAcquisitionTypes: [AcquisitionType]
    public let averageResponseTime: TimeInterval
    public let skipOptionalQuestions: Bool

    public enum ExperienceLevel: Sendable {
        case novice
        case intermediate
        case expert
    }

    public init(
        id: UUID = UUID(),
        experienceLevel: ExperienceLevel = .intermediate,
        preferredVendors: [String] = [],
        commonAcquisitionTypes: [AcquisitionType] = [],
        averageResponseTime: TimeInterval = 30,
        skipOptionalQuestions: Bool = false
    ) {
        self.id = id
        self.experienceLevel = experienceLevel
        self.preferredVendors = preferredVendors
        self.commonAcquisitionTypes = commonAcquisitionTypes
        self.averageResponseTime = averageResponseTime
        self.skipOptionalQuestions = skipOptionalQuestions
    }
}
