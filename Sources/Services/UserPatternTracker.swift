import ComposableArchitecture
import Foundation

// MARK: - User Pattern Tracker

/// Lightweight service that tracks user patterns for adaptive intelligence
public struct UserPatternTracker {
    public var trackAction: (TrackedAction) async -> Void
    public var getPatterns: () async -> UserPatterns
    public var getSuggestions: (WorkflowContext) async -> [IntelligentSuggestion]
    public var learnFromOutcome: (ActionOutcome) async -> Void

    public init(
        trackAction: @escaping (TrackedAction) async -> Void,
        getPatterns: @escaping () async -> UserPatterns,
        getSuggestions: @escaping (WorkflowContext) async -> [IntelligentSuggestion],
        learnFromOutcome: @escaping (ActionOutcome) async -> Void
    ) {
        self.trackAction = trackAction
        self.getPatterns = getPatterns
        self.getSuggestions = getSuggestions
        self.learnFromOutcome = learnFromOutcome
    }
}

// MARK: - Models

public struct TrackedAction: Equatable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let actionType: ActionType
    public let context: ActionContext

    public enum ActionType: String, Codable {
        case documentSelected
        case documentDeselected
        case requirementEntered
        case promptAccepted
        case promptRejected
        case documentGenerated
        case documentEdited
        case workflowCompleted
        case automationEnabled
        case automationDisabled
    }

    public struct ActionContext: Equatable, Codable {
        public let documentType: String?
        public let workflowState: String?
        public let timeOfDay: Int // Hour of day
        public let dayOfWeek: Int // 1-7
        public let previousAction: String?
        public let timeSpent: TimeInterval?
    }

    public init(actionType: ActionType, context: ActionContext) {
        id = UUID()
        timestamp = Date()
        self.actionType = actionType
        self.context = context
    }
}

public struct UserPatterns: Equatable, Codable {
    public var documentSequences: [DocumentSequence] = []
    public var timePatterns: [TimePattern] = []
    public var preferredValues: [String: [String]] = [:] // Field -> Common values
    public var automationPreference: Double = 0.5 // 0-1 scale
    public var averageTimePerDocument: [String: TimeInterval] = [:]
    public var successRate: Double = 0.0

    public struct DocumentSequence: Equatable, Codable {
        public let documents: [String]
        public let frequency: Int
        public let successRate: Double
    }

    public struct TimePattern: Equatable, Codable {
        public let actionType: String
        public let preferredHour: Int?
        public let preferredDay: Int?
        public let frequency: Int
    }
}

public struct IntelligentSuggestion: Equatable {
    public let id = UUID()
    public let type: SuggestionType
    public let title: String
    public let description: String
    public let confidence: Double
    public let reason: String
    public let action: SuggestedAction

    public enum SuggestionType: String {
        case nextDocument
        case automation
        case timeOptimization
        case valuePreFill
        case workflowShortcut
    }

    public enum SuggestedAction: Equatable {
        case selectDocuments([DocumentType])
        case enableAutomation(WorkflowState)
        case preFillValue(field: String, value: String)
        case skipToState(WorkflowState)
    }
}

public struct ActionOutcome: Equatable {
    public let actionId: UUID
    public let success: Bool
    public let timeToComplete: TimeInterval?
    public let userSatisfaction: Int? // 1-5 scale

    public init(
        actionId: UUID,
        success: Bool,
        timeToComplete: TimeInterval? = nil,
        userSatisfaction: Int? = nil
    ) {
        self.actionId = actionId
        self.success = success
        self.timeToComplete = timeToComplete
        self.userSatisfaction = userSatisfaction
    }
}

// MARK: - Implementation

extension UserPatternTracker: DependencyKey {
    public static var liveValue: UserPatternTracker {
        let storage = PatternStorage()

        return UserPatternTracker(
            trackAction: { action in
                await storage.store(action)

                // Update patterns in background
                Task {
                    await storage.updatePatterns()
                }
            },

            getPatterns: {
                await storage.getPatterns()
            },

            getSuggestions: { context in
                let patterns = await storage.getPatterns()
                var suggestions: [IntelligentSuggestion] = []

                // Suggest next document based on sequences
                let currentDoc = context.currentState.displayName
                let relevantSequences = patterns.documentSequences
                    .filter { $0.documents.contains(currentDoc) }
                    .sorted { $0.frequency > $1.frequency }

                if let topSequence = relevantSequences.first,
                   let currentIndex = topSequence.documents.firstIndex(of: currentDoc),
                   currentIndex < topSequence.documents.count - 1
                {
                    let nextDoc = topSequence.documents[currentIndex + 1]
                    suggestions.append(IntelligentSuggestion(
                        type: .nextDocument,
                        title: "Continue with \(nextDoc)?",
                        description: "You usually create \(nextDoc) after \(currentDoc)",
                        confidence: Double(topSequence.frequency) / 10.0,
                        reason: "Based on \(topSequence.frequency) previous workflows",
                        action: .selectDocuments([]) // Would need actual DocumentType
                    ))
                }

                // Suggest automation based on preference
                if patterns.automationPreference > 0.7, !context.automationSettings.enabled {
                    suggestions.append(IntelligentSuggestion(
                        type: .automation,
                        title: "Enable automation?",
                        description: "You typically use automation for this workflow",
                        confidence: patterns.automationPreference,
                        reason: "Based on your usage patterns",
                        action: .enableAutomation(context.currentState)
                    ))
                }

                // Time-based suggestions
                let currentHour = Calendar.current.component(.hour, from: Date())
                let timePatterns = patterns.timePatterns
                    .filter { $0.preferredHour == currentHour }
                    .sorted { $0.frequency > $1.frequency }

                if let topTimePattern = timePatterns.first {
                    suggestions.append(IntelligentSuggestion(
                        type: .timeOptimization,
                        title: "Good time for \(topTimePattern.actionType)",
                        description: "You often do this at this time",
                        confidence: Double(topTimePattern.frequency) / 20.0,
                        reason: "Based on time patterns",
                        action: .skipToState(context.currentState)
                    ))
                }

                return suggestions.sorted { $0.confidence > $1.confidence }
            },

            learnFromOutcome: { outcome in
                await storage.recordOutcome(outcome)
            }
        )
    }
}

// MARK: - Pattern Storage

private actor PatternStorage {
    private var actions: [TrackedAction] = []
    private var patterns = UserPatterns()
    private var outcomes: [UUID: ActionOutcome] = [:]

    func store(_ action: TrackedAction) {
        actions.append(action)

        // Keep only last 1000 actions
        if actions.count > 1000 {
            actions.removeFirst(actions.count - 1000)
        }
    }

    func recordOutcome(_ outcome: ActionOutcome) {
        outcomes[outcome.actionId] = outcome
    }

    func getPatterns() -> UserPatterns {
        patterns
    }

    func updatePatterns() {
        // Update document sequences
        updateDocumentSequences()

        // Update time patterns
        updateTimePatterns()

        // Update automation preference
        updateAutomationPreference()

        // Update success rate
        updateSuccessRate()
    }

    private func updateDocumentSequences() {
        var sequenceCount: [String: Int] = [:]
        var sequenceSuccess: [String: Int] = [:]

        // Find sequences of document selections
        let documentActions = actions.filter { $0.actionType == .documentSelected }

        for i in 0 ..< documentActions.count - 1 {
            if let doc1 = documentActions[i].context.documentType,
               let doc2 = documentActions[i + 1].context.documentType
            {
                let sequence = "\(doc1)->\(doc2)"
                sequenceCount[sequence, default: 0] += 1

                // Check if this sequence led to success
                if let outcome = outcomes[documentActions[i + 1].id], outcome.success {
                    sequenceSuccess[sequence, default: 0] += 1
                }
            }
        }

        // Convert to DocumentSequence objects
        patterns.documentSequences = sequenceCount.map { key, count in
            let docs = key.split(separator: "->").map(String.init)
            let successCount = sequenceSuccess[key] ?? 0
            let successRate = count > 0 ? Double(successCount) / Double(count) : 0

            return UserPatterns.DocumentSequence(
                documents: docs,
                frequency: count,
                successRate: successRate
            )
        }.sorted { $0.frequency > $1.frequency }
    }

    private func updateTimePatterns() {
        var timeFrequency: [String: Int] = [:]

        for action in actions {
            let key = "\(action.actionType.rawValue)-\(action.context.timeOfDay)"
            timeFrequency[key, default: 0] += 1
        }

        patterns.timePatterns = timeFrequency.compactMap { key, frequency in
            let parts = key.split(separator: "-")
            guard parts.count >= 2,
                  let hour = Int(parts.last!) else { return nil }

            return UserPatterns.TimePattern(
                actionType: String(parts.dropLast().joined(separator: "-")),
                preferredHour: hour,
                preferredDay: nil,
                frequency: frequency
            )
        }
    }

    private func updateAutomationPreference() {
        let automationActions = actions.filter {
            $0.actionType == .automationEnabled || $0.actionType == .automationDisabled
        }

        let enabledCount = automationActions.filter { $0.actionType == .automationEnabled }.count
        let totalCount = automationActions.count

        patterns.automationPreference = totalCount > 0 ? Double(enabledCount) / Double(totalCount) : 0.5
    }

    private func updateSuccessRate() {
        let successCount = outcomes.values.filter(\.success).count
        let totalCount = outcomes.count

        patterns.successRate = totalCount > 0 ? Double(successCount) / Double(totalCount) : 0.0
    }
}

public extension DependencyValues {
    var userPatternTracker: UserPatternTracker {
        get { self[UserPatternTracker.self] }
        set { self[UserPatternTracker.self] = newValue }
    }
}
