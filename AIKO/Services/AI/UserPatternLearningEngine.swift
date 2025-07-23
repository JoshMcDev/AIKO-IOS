//
//  UserPatternLearningEngine.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Combine
import CoreData
import Foundation
import os.log

/// Engine for learning and adapting to user patterns in government contracting workflows
@MainActor
final class UserPatternLearningEngine: ObservableObject {
    // MARK: - Properties

    static let shared = UserPatternLearningEngine()

    /// Core Data context for pattern storage
    private let persistenceController = PersistenceController.shared
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    /// Pattern recognition algorithms
    private let patternRecognizer = PatternRecognitionAlgorithm()

    /// User preference storage
    private let preferenceStore = UserPreferenceStore()

    /// Learning feedback system
    private let feedbackLoop = LearningFeedbackLoop()

    /// Analytics collector
    private let analyticsCollector = UserBehaviorAnalytics()

    /// Logger
    private let logger = Logger(subsystem: "com.aiko", category: "PatternLearning")

    /// Active learning session
    @Published private(set) var activeSession: LearningSession?

    /// User patterns discovered
    @Published private(set) var discoveredPatterns: [UserPattern] = []

    /// Confidence threshold for pattern recognition
    private let confidenceThreshold: Double = 0.75

    /// Minimum occurrences before pattern is recognized
    private let minimumOccurrences: Int = 3

    /// Pattern types we track
    enum PatternType: String, CaseIterable {
        case formFilling = "form_filling"
        case documentType = "document_type"
        case workflowSequence = "workflow_sequence"
        case timeOfDay = "time_of_day"
        case fieldValues = "field_values"
        case navigationPath = "navigation_path"
        case errorCorrection = "error_correction"
        case searchQueries = "search_queries"
    }

    // MARK: - Initialization

    private init() {
        loadStoredPatterns()
        startAnalyticsCollection()
    }

    // MARK: - Public Methods

    /// Start a new learning session
    func startLearningSession(userId: String, contextType: String) {
        activeSession = LearningSession(
            id: UUID(),
            userId: userId,
            startTime: Date(),
            contextType: contextType,
            interactions: []
        )

        logger.info("Started learning session for user \(userId) in context \(contextType)")
    }

    /// Record a user interaction
    func recordInteraction(_ interaction: UserInteraction) {
        guard var session = activeSession else {
            logger.warning("No active session for recording interaction")
            return
        }

        // Add to current session
        session.interactions.append(interaction)
        activeSession = session

        // Analyze for patterns
        Task {
            await analyzeInteraction(interaction)
        }

        // Store interaction
        storeInteraction(interaction)

        logger.debug("Recorded interaction: \(interaction.type)")
    }

    /// Get learned preferences for a specific context
    func getLearnedPreferences(for context: PatternContext) -> LearnedPreferences {
        let relevantPatterns = discoveredPatterns.filter { pattern in
            pattern.context.matches(context) && pattern.confidence >= confidenceThreshold
        }

        return LearnedPreferences(
            patterns: relevantPatterns,
            suggestions: generateSuggestions(from: relevantPatterns, context: context),
            confidence: calculateOverallConfidence(relevantPatterns)
        )
    }

    /// Predict next user action
    func predictNextAction(currentState: PatternWorkflowState) -> PredictedAction? {
        let sequencePatterns = discoveredPatterns.filter { $0.type == .workflowSequence }

        for pattern in sequencePatterns {
            if let prediction = pattern.predictNext(from: currentState) {
                return prediction
            }
        }

        return nil
    }

    /// Get smart defaults for form fields
    func getSmartDefaults(formType: String, fieldName: String) -> SmartDefault? {
        let fieldPatterns = discoveredPatterns.filter {
            $0.type == .fieldValues &&
                $0.metadata["formType"] as? String == formType &&
                $0.metadata["fieldName"] as? String == fieldName
        }

        guard let bestPattern = fieldPatterns.max(by: { $0.confidence < $1.confidence }) else {
            return nil
        }

        return SmartDefault(
            value: bestPattern.value,
            confidence: bestPattern.confidence,
            source: .learned,
            lastUsed: bestPattern.lastOccurrence
        )
    }

    /// Apply user feedback to improve learning
    func applyFeedback(_ feedback: UserFeedback) {
        feedbackLoop.processFeedback(feedback)

        // Update pattern confidence based on feedback
        if let patternId = feedback.patternId,
           let index = discoveredPatterns.firstIndex(where: { $0.id == patternId }) {
            var pattern = discoveredPatterns[index]
            pattern.updateConfidence(basedOn: feedback)
            discoveredPatterns[index] = pattern

            // Persist updated pattern
            updateStoredPattern(pattern)
        }

        logger.info("Applied user feedback: \(feedback.type)")
    }

    /// End the current learning session
    func endLearningSession() {
        guard let session = activeSession else { return }

        // Final analysis of session
        Task {
            await performSessionAnalysis(session)
        }

        // Store session data
        storeSession(session)

        activeSession = nil
        logger.info("Ended learning session with \(session.interactions.count) interactions")
    }

    // MARK: - Private Methods

    private func loadStoredPatterns() {
        let request: NSFetchRequest<PatternEntity> = PatternEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntity.confidence, ascending: false)]

        do {
            let entities = try context.fetch(request)
            discoveredPatterns = entities.compactMap { UserPattern(from: $0) }
            logger.info("Loaded \(discoveredPatterns.count) stored patterns")
        } catch {
            logger.error("Failed to load patterns: \(error.localizedDescription)")
        }
    }

    private func startAnalyticsCollection() {
        analyticsCollector.startCollection { [weak self] event in
            self?.processAnalyticsEvent(event)
        }
    }

    private func analyzeInteraction(_ interaction: UserInteraction) async {
        // Run pattern recognition
        let detectedPatterns = await patternRecognizer.analyze(
            interaction: interaction,
            historicalData: getHistoricalInteractions()
        )

        // Process detected patterns
        for detected in detectedPatterns {
            if let existingIndex = discoveredPatterns.firstIndex(where: { $0.id == detected.id }) {
                // Update existing pattern
                var pattern = discoveredPatterns[existingIndex]
                pattern.occurrences += 1
                pattern.lastOccurrence = Date()
                pattern.updateConfidence()
                discoveredPatterns[existingIndex] = pattern

                updateStoredPattern(pattern)
            } else if detected.occurrences >= minimumOccurrences {
                // Add new pattern
                discoveredPatterns.append(detected)
                storeNewPattern(detected)
            }
        }
    }

    private func performSessionAnalysis(_ session: LearningSession) async {
        // Analyze entire session for macro patterns
        let sessionPatterns = await patternRecognizer.analyzeSession(session)

        // Store valuable session patterns
        for pattern in sessionPatterns where pattern.confidence >= confidenceThreshold {
            if !discoveredPatterns.contains(where: { $0.id == pattern.id }) {
                discoveredPatterns.append(pattern)
                storeNewPattern(pattern)
            }
        }
    }

    private func generateSuggestions(from patterns: [UserPattern], context: PatternContext) -> [Suggestion] {
        var suggestions: [Suggestion] = []

        for pattern in patterns {
            if let suggestion = pattern.generateSuggestion(for: context) {
                suggestions.append(suggestion)
            }
        }

        // Sort by relevance and confidence
        return suggestions.sorted { $0.relevance * $0.confidence > $1.relevance * $1.confidence }
    }

    private func calculateOverallConfidence(_ patterns: [UserPattern]) -> Double {
        guard !patterns.isEmpty else { return 0 }

        let totalConfidence = patterns.reduce(0) { $0 + $1.confidence }
        return totalConfidence / Double(patterns.count)
    }

    // MARK: - Core Data Operations

    private func storeInteraction(_ interaction: UserInteraction) {
        let entity = InteractionEntity(context: context)
        entity.id = interaction.id
        entity.type = interaction.type
        entity.timestamp = interaction.timestamp
        entity.metadata = try? JSONEncoder().encode(interaction.metadata)
        entity.userId = activeSession?.userId

        do {
            try context.save()
        } catch {
            logger.error("Failed to store interaction: \(error.localizedDescription)")
        }
    }

    private func storeNewPattern(_ pattern: UserPattern) {
        let entity = PatternEntity(context: context)
        pattern.populate(entity)

        do {
            try context.save()
            logger.debug("Stored new pattern: \(pattern.type)")
        } catch {
            logger.error("Failed to store pattern: \(error.localizedDescription)")
        }
    }

    private func updateStoredPattern(_ pattern: UserPattern) {
        let request: NSFetchRequest<PatternEntity> = PatternEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", pattern.id as CVarArg)

        do {
            if let entity = try context.fetch(request).first {
                pattern.populate(entity)
                try context.save()
            }
        } catch {
            logger.error("Failed to update pattern: \(error.localizedDescription)")
        }
    }

    private func storeSession(_ session: LearningSession) {
        let entity = SessionEntity(context: context)
        entity.id = session.id
        entity.userId = session.userId
        entity.startTime = session.startTime
        entity.endTime = Date()
        entity.contextType = session.contextType
        entity.interactionCount = Int32(session.interactions.count)

        do {
            try context.save()
        } catch {
            logger.error("Failed to store session: \(error.localizedDescription)")
        }
    }

    private func getHistoricalInteractions() -> [UserInteraction] {
        let request: NSFetchRequest<InteractionEntity> = InteractionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InteractionEntity.timestamp, ascending: false)]
        request.fetchLimit = 1000 // Limit to recent interactions

        do {
            let entities = try context.fetch(request)
            return entities.compactMap { UserInteraction(from: $0) }
        } catch {
            logger.error("Failed to fetch historical interactions: \(error.localizedDescription)")
            return []
        }
    }

    private func processAnalyticsEvent(_ event: AnalyticsEvent) {
        // Convert analytics events to interactions
        let interaction = UserInteraction(
            id: UUID(),
            type: event.type,
            timestamp: event.timestamp,
            metadata: event.properties
        )

        recordInteraction(interaction)
    }
}

// MARK: - Supporting Types

struct UserPattern: Identifiable {
    let id: UUID
    let type: UserPatternLearningEngine.PatternType
    let value: Any
    let context: PatternContext
    var occurrences: Int
    var confidence: Double
    var lastOccurrence: Date
    let metadata: [String: Any]

    mutating func updateConfidence(basedOn feedback: UserFeedback? = nil) {
        if let feedback {
            switch feedback.type {
            case .positive:
                confidence = min(1.0, confidence * 1.1)
            case .negative:
                confidence = max(0.0, confidence * 0.9)
            case .neutral:
                break
            }
        } else {
            // Natural confidence growth with occurrences
            confidence = min(1.0, Double(occurrences) / 10.0)
        }
    }

    func generateSuggestion(for context: PatternContext) -> Suggestion? {
        guard self.context.matches(context) else { return nil }

        return Suggestion(
            id: UUID(),
            type: mapPatternTypeToSuggestionType(type),
            value: value,
            reason: "Based on your past behavior",
            confidence: confidence,
            relevance: calculateRelevance(to: context)
        )
    }

    func predictNext(from state: PatternWorkflowState) -> PredictedAction? {
        guard type == .workflowSequence,
              let sequence = value as? [String],
              let currentIndex = sequence.firstIndex(of: state.currentStep),
              currentIndex < sequence.count - 1
        else {
            return nil
        }

        return PredictedAction(
            action: sequence[currentIndex + 1],
            confidence: confidence,
            alternativeActions: []
        )
    }

    private func mapPatternTypeToSuggestionType(_ type: UserPatternLearningEngine.PatternType) -> SuggestionType {
        switch type {
        case .formFilling: .formCompletion
        case .documentType: .documentSelection
        case .workflowSequence: .nextStep
        case .fieldValues: .fieldValue
        case .navigationPath: .navigation
        default: .general
        }
    }

    private func calculateRelevance(to context: PatternContext) -> Double {
        // Simple relevance calculation based on context similarity
        var relevance = 0.0

        if self.context.formType == context.formType { relevance += 0.3 }
        if self.context.documentType == context.documentType { relevance += 0.3 }
        if self.context.workflowPhase == context.workflowPhase { relevance += 0.2 }
        if self.context.timeOfDay == context.timeOfDay { relevance += 0.2 }

        return relevance
    }
}

struct UserInteraction {
    let id: UUID
    let type: String
    let timestamp: Date
    let metadata: [String: Any]
}

struct LearningSession {
    let id: UUID
    let userId: String
    let startTime: Date
    let contextType: String
    var interactions: [UserInteraction]
}

struct PatternContext {
    let formType: String?
    let documentType: String?
    let workflowPhase: String?
    let timeOfDay: TimeOfDay?

    func matches(_ other: PatternContext) -> Bool {
        if let formType, let otherFormType = other.formType {
            guard formType == otherFormType else { return false }
        }

        if let documentType, let otherDocumentType = other.documentType {
            guard documentType == otherDocumentType else { return false }
        }

        if let workflowPhase, let otherWorkflowPhase = other.workflowPhase {
            guard workflowPhase == otherWorkflowPhase else { return false }
        }

        return true
    }
}

struct LearnedPreferences {
    let patterns: [UserPattern]
    let suggestions: [Suggestion]
    let confidence: Double
}

struct SmartDefault {
    let value: Any
    let confidence: Double
    let source: DefaultSource
    let lastUsed: Date

    enum DefaultSource {
        case learned
        case historical
        case regulation
        case system
    }
}

struct Suggestion {
    let id: UUID
    let type: SuggestionType
    let value: Any
    let reason: String
    let confidence: Double
    let relevance: Double
}

enum SuggestionType {
    case formCompletion
    case documentSelection
    case nextStep
    case fieldValue
    case navigation
    case general
}

struct PredictedAction {
    let action: String
    let confidence: Double
    let alternativeActions: [String]
}

struct PatternWorkflowState {
    let currentStep: String
    let completedSteps: [String]
    let documentType: String
    let metadata: [String: Any]
}

struct UserFeedback {
    let id: UUID
    let patternId: UUID?
    let type: FeedbackType
    let timestamp: Date
    let context: String?

    enum FeedbackType {
        case positive
        case negative
        case neutral
    }
}

enum TimeOfDay: String {
    case morning // 6 AM - 12 PM
    case afternoon // 12 PM - 6 PM
    case evening // 6 PM - 10 PM
    case night // 10 PM - 6 AM

    init(from date: Date) {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 6 ..< 12: self = .morning
        case 12 ..< 18: self = .afternoon
        case 18 ..< 22: self = .evening
        default: self = .night
        }
    }
}

struct AnalyticsEvent {
    let type: String
    let timestamp: Date
    let properties: [String: Any]
}

// MARK: - Core Data Extensions

extension UserPattern {
    init?(from entity: PatternEntity) {
        guard let id = entity.id,
              let typeString = entity.type,
              let type = UserPatternLearningEngine.PatternType(rawValue: typeString),
              let contextData = entity.context,
              let context = try? JSONDecoder().decode(PatternContext.self, from: contextData),
              let lastOccurrence = entity.lastOccurrence
        else {
            return nil
        }

        self.id = id
        self.type = type
        value = entity.value ?? ""
        self.context = context
        occurrences = Int(entity.occurrences)
        confidence = entity.confidence
        self.lastOccurrence = lastOccurrence
        metadata = [:]
    }

    func populate(_ entity: PatternEntity) {
        entity.id = id
        entity.type = type.rawValue
        entity.value = "\(value)"
        entity.context = try? JSONEncoder().encode(context)
        entity.occurrences = Int32(occurrences)
        entity.confidence = confidence
        entity.lastOccurrence = lastOccurrence
    }
}

extension UserInteraction {
    init?(from entity: InteractionEntity) {
        guard let id = entity.id,
              let type = entity.type,
              let timestamp = entity.timestamp
        else {
            return nil
        }

        self.id = id
        self.type = type
        self.timestamp = timestamp
        metadata = [:]

        if let metadataData = entity.metadata,
           let metadata = try? JSONDecoder().decode([String: String].self, from: metadataData) {
            self.metadata = metadata
        }
    }
}
