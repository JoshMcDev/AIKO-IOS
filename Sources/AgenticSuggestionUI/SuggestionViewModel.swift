import AppCore
import Combine
import CryptoKit
import os.log
import SwiftUI

/// @Observable view model for managing agentic suggestions state and orchestrator integration
/// Handles real-time updates, feedback submission, and Swift 6 strict concurrency compliance
@Observable
@MainActor
public final class SuggestionViewModel {
    // MARK: - Published Properties

    public private(set) var currentSuggestions: [DecisionResponse] = []
    public private(set) var isProcessing: Bool = false
    public private(set) var errorState: ErrorState?
    public private(set) var learningMetrics: LearningMetrics?

    // Configuration
    public var confidenceThreshold: Double

    // Performance optimization: Cache expensive calculations
    private var cachedMemoryUsage: Int = 0
    private var lastSuggestionCount: Int = 0
    private var cachedFilteredSuggestions: [DecisionResponse] = []
    private var lastFilterThreshold: Double = 0.0
    private var lastSuggestionIds: Set<UUID> = []

    // MARK: - Private Properties

    private let orchestrator: any AgenticOrchestratorProtocol
    private let complianceGuardian: any ComplianceGuardianProtocol
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.aiko.agentic-ui", category: "SuggestionViewModel")
    private let secureLogger: SecureLoggerProtocol

    // MARK: - Initialization

    public init(
        orchestrator: any AgenticOrchestratorProtocol,
        complianceGuardian: any ComplianceGuardianProtocol,
        secureLogger: SecureLoggerProtocol = DefaultSecureLogger(),
        confidenceThreshold: Double = 0.65
    ) {
        self.orchestrator = orchestrator
        self.complianceGuardian = complianceGuardian
        self.secureLogger = secureLogger
        self.confidenceThreshold = confidenceThreshold

        Task {
            await setupRealTimeUpdates()
        }
    }

    // MARK: - Public Methods

    /// Load suggestions for the given acquisition context
    public func loadSuggestions(for context: AcquisitionContext) async throws {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // Create decision request from context
            let request = DecisionRequest(
                context: context,
                possibleActions: [WorkflowAction.placeholder],
                historicalData: [],
                userPreferences: UserPreferences(
                    automationPreference: .balanced,
                    notificationSettings: NotificationSettings(),
                    workflowCustomizations: [:]
                )
            )

            // Get decision from orchestrator
            let decision = try await orchestrator.makeDecision(request)

            // Validate compliance
            _ = try await complianceGuardian.validateCompliance(for: context)

            // Update suggestions - GREEN phase: minimal implementation
            currentSuggestions = [decision]
            errorState = nil

            // Performance optimization: Clear caches when suggestions change
            await clearPerformanceCaches()

        } catch {
            let errorMessage = "Failed to load suggestions: \(error.localizedDescription)"
            logger.error("\(errorMessage, privacy: .public)")
            await secureLogger.logError(error, context: "loadSuggestions", sensitiveData: [:])
            errorState = .orchestratorError(errorMessage)
            currentSuggestions = []
        }
    }

    /// Submit user feedback for a specific suggestion
    public func submitFeedback(_ feedback: AgenticUserFeedback, for suggestion: DecisionResponse) async throws {
        do {
            // Submit feedback to orchestrator
            try await orchestrator.provideFeedback(for: suggestion, feedback: feedback)

            // Log successful feedback submission securely
            await secureLogger.logUserInteraction(
                action: "feedback_submitted",
                suggestionId: suggestion.id,
                outcome: feedback.outcome,
                timestamp: Date()
            )

        } catch {
            let errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
            logger.error("\(errorMessage, privacy: .public)")
            await secureLogger.logError(error, context: "submitFeedback", sensitiveData: ["suggestionId": suggestion.id.uuidString])
            errorState = .orchestratorError(errorMessage)
            throw error
        }
    }

    /// Process real-time updates from the orchestrator
    public func processRealTimeUpdate(_ suggestion: DecisionResponse) async throws {
        // GREEN phase: minimal implementation - just update current suggestions
        var updatedSuggestions = currentSuggestions

        // Find and update existing suggestion, or add new one
        if let index = updatedSuggestions.firstIndex(where: { $0.id == suggestion.id }) {
            updatedSuggestions[index] = suggestion
        } else {
            updatedSuggestions.append(suggestion)
        }

        currentSuggestions = updatedSuggestions

        // Performance optimization: Update caches incrementally for real-time updates
        await updatePerformanceCachesIncremental()

        await secureLogger.logSystemEvent(
            event: "realtime_update_processed",
            suggestionId: suggestion.id,
            confidence: suggestion.confidence,
            timestamp: Date()
        )
    }

    /// Retry the last failed operation
    public func retryLastOperation() async throws {
        guard errorState != nil else {
            logger.info("No error to retry")
            return
        }

        logger.info("Attempting to retry last operation")
        await secureLogger.logSystemEvent(
            event: "retry_operation_attempted",
            suggestionId: nil,
            confidence: nil,
            timestamp: Date()
        )

        errorState = nil

        // For GREEN phase, just clearing error state is sufficient
        // More sophisticated retry logic would be implemented in REFACTOR phase
    }

    // MARK: - Computed Properties

    /// Suggestions filtered by current confidence threshold with caching
    public var filteredSuggestions: [DecisionResponse] {
        let currentIds = Set(currentSuggestions.map(\.id))

        // Performance optimization: Cache filtered results when threshold and suggestions haven't changed
        if confidenceThreshold == lastFilterThreshold, currentIds == lastSuggestionIds {
            return cachedFilteredSuggestions
        }

        // Recalculate filtered suggestions
        let filtered = currentSuggestions.filter { $0.confidence >= confidenceThreshold }

        // Cache the results
        cachedFilteredSuggestions = filtered
        lastFilterThreshold = confidenceThreshold
        lastSuggestionIds = currentIds

        return filtered
    }

    /// Estimated memory usage for current suggestion set with caching optimization
    public var estimatedMemoryUsage: Int {
        // Performance optimization: Cache memory calculation when suggestion count hasn't changed
        if currentSuggestions.count == lastSuggestionCount, cachedMemoryUsage > 0 {
            return cachedMemoryUsage
        }

        // Recalculate memory usage
        let baseSuggestionSize = 512 // Base size per suggestion in bytes
        let reasoningTextFactor = 2 // Factor for reasoning text length

        let newMemoryUsage = currentSuggestions.reduce(0) { total, suggestion in
            let reasoningSize = suggestion.reasoning.count * reasoningTextFactor
            return total + baseSuggestionSize + reasoningSize
        }

        // Cache the result
        cachedMemoryUsage = newMemoryUsage
        lastSuggestionCount = currentSuggestions.count

        return newMemoryUsage
    }

    // MARK: - Private Methods

    private func setupRealTimeUpdates() async {
        logger.info("Initializing real-time updates for SuggestionViewModel")
        await secureLogger.logSystemEvent(
            event: "realtime_updates_initialized",
            suggestionId: nil,
            confidence: nil,
            timestamp: Date()
        )

        // Initialize performance caches
        await initializePerformanceCaches()
    }

    /// Performance optimization: Clear all cached calculations
    private func clearPerformanceCaches() async {
        cachedMemoryUsage = 0
        lastSuggestionCount = 0
        cachedFilteredSuggestions = []
        lastFilterThreshold = 0.0
        lastSuggestionIds = []
    }

    /// Performance optimization: Initialize caches for better startup performance
    private func initializePerformanceCaches() async {
        // Pre-warm common calculations
        _ = estimatedMemoryUsage
        _ = filteredSuggestions
    }

    /// Performance optimization: Update caches incrementally for real-time updates
    private func updatePerformanceCachesIncremental() async {
        // For real-time updates, we invalidate caches to recalculate on next access
        // This is more efficient than recalculating immediately
        cachedMemoryUsage = 0
        lastSuggestionCount = -1 // Force recalculation
        lastSuggestionIds = [] // Force filtered suggestions recalculation
    }
}

// MARK: - Supporting Types

/// Error states for the suggestion view model
public enum ErrorState: Error, Sendable {
    case networkError(String)
    case orchestratorError(String)
    case complianceError(String)
    case unknownError(Error)
}

/// Learning metrics for tracking suggestion effectiveness
public struct LearningMetrics: Sendable {
    let accuracyScore: Double
    let userSatisfaction: Double
    let completionRate: Double
    let lastUpdated: Date
}

/// Errors for RED phase indicating unimplemented functionality
public enum NotImplementedError: Error, LocalizedError {
    case loadSuggestions
    case submitFeedback
    case processRealTimeUpdate
    case retryLastOperation

    public var errorDescription: String? {
        switch self {
        case .loadSuggestions:
            "RED PHASE: loadSuggestions method not implemented"
        case .submitFeedback:
            "RED PHASE: submitFeedback method not implemented"
        case .processRealTimeUpdate:
            "RED PHASE: processRealTimeUpdate method not implemented"
        case .retryLastOperation:
            "RED PHASE: retryLastOperation method not implemented"
        }
    }
}

// MARK: - Protocol Definitions (Placeholder)

/// Protocol for agentic orchestrator integration
public protocol AgenticOrchestratorProtocol: Sendable {
    func makeDecision(_ request: DecisionRequest) async throws -> DecisionResponse
    func provideFeedback(for decision: DecisionResponse, feedback: AgenticUserFeedback) async throws
}

/// Protocol for compliance guardian integration
public protocol ComplianceGuardianProtocol: Sendable {
    func validateCompliance(for context: AcquisitionContext) async throws -> ComplianceValidationResult
}

/// Compliance validation result
public struct ComplianceValidationResult: Sendable {
    let isCompliant: Bool
    let warnings: [String]
    let recommendations: [String]
}

// MARK: - Secure Logging Protocols

/// Protocol for secure logging with CUI data protection
public protocol SecureLoggerProtocol: Sendable {
    func logUserInteraction(action: String, suggestionId: UUID, outcome: AgenticFeedbackOutcome, timestamp: Date) async
    func logSystemEvent(event: String, suggestionId: UUID?, confidence: Double?, timestamp: Date) async
    func logError(_ error: Error, context: String, sensitiveData: [String: String]) async
}

/// Default implementation of secure logging with government compliance
public final class DefaultSecureLogger: SecureLoggerProtocol {
    private let logger = Logger(subsystem: "com.aiko.secure-logging", category: "AgenticSuggestionUI")
    private let auditTrail: AuditTrailProtocol

    public init(auditTrail: AuditTrailProtocol = DefaultAuditTrail()) {
        self.auditTrail = auditTrail
    }

    public func logUserInteraction(action: String, suggestionId: UUID, outcome: AgenticFeedbackOutcome, timestamp: Date) async {
        // Hash sensitive suggestion ID for logging
        let hashedSuggestionId = hashSensitiveData(suggestionId.uuidString)
        logger.info("User interaction: \(action, privacy: .public) for suggestion: \(hashedSuggestionId, privacy: .public)")

        await auditTrail.recordUserInteraction(
            action: action,
            hashedSuggestionId: hashedSuggestionId,
            outcome: outcome,
            timestamp: timestamp
        )
    }

    public func logSystemEvent(event: String, suggestionId: UUID?, confidence: Double?, timestamp: Date) async {
        let hashedSuggestionId = suggestionId.map { hashSensitiveData($0.uuidString) }
        logger.info("System event: \(event, privacy: .public) for suggestion: \(hashedSuggestionId ?? "nil", privacy: .public)")

        await auditTrail.recordSystemEvent(
            event: event,
            hashedSuggestionId: hashedSuggestionId,
            confidence: confidence,
            timestamp: timestamp
        )
    }

    public func logError(_ error: Error, context: String, sensitiveData: [String: String]) async {
        // Hash all sensitive data before logging
        let hashedSensitiveData = sensitiveData.mapValues { hashSensitiveData($0) }
        logger.error("Error in \(context, privacy: .public): \(error.localizedDescription, privacy: .public)")

        await auditTrail.recordError(
            error: error.localizedDescription,
            context: context,
            hashedSensitiveData: hashedSensitiveData,
            timestamp: Date()
        )
    }

    private func hashSensitiveData(_ data: String) -> String {
        // Use secure hashing for sensitive data (SHA-256)
        let inputData = Data(data.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Audit Trail Protocols

/// Protocol for audit trail management with government compliance
public protocol AuditTrailProtocol: Sendable {
    func recordUserInteraction(action: String, hashedSuggestionId: String, outcome: AgenticFeedbackOutcome, timestamp: Date) async
    func recordSystemEvent(event: String, hashedSuggestionId: String?, confidence: Double?, timestamp: Date) async
    func recordError(error: String, context: String, hashedSensitiveData: [String: String], timestamp: Date) async
}

/// Default audit trail implementation with secure storage
public final class DefaultAuditTrail: AuditTrailProtocol {
    private let logger = Logger(subsystem: "com.aiko.audit-trail", category: "AgenticSuggestionUI")

    public init() {}

    public func recordUserInteraction(action: String, hashedSuggestionId: String, outcome: AgenticFeedbackOutcome, timestamp: Date) async {
        // In production, this would write to secure, tamper-proof storage
        logger.info("AUDIT: User \(action, privacy: .public) - Suggestion: \(hashedSuggestionId, privacy: .public) - Outcome: \(String(describing: outcome), privacy: .public) - Time: \(timestamp.ISO8601Format(), privacy: .public)")
    }

    public func recordSystemEvent(event: String, hashedSuggestionId: String?, confidence: Double?, timestamp: Date) async {
        logger.info("AUDIT: System \(event, privacy: .public) - Suggestion: \(hashedSuggestionId ?? "nil", privacy: .public) - Confidence: \(confidence?.description ?? "nil", privacy: .public) - Time: \(timestamp.ISO8601Format(), privacy: .public)")
    }

    public func recordError(error: String, context: String, hashedSensitiveData: [String: String], timestamp: Date) async {
        logger.error("AUDIT: Error in \(context, privacy: .public) - \(error, privacy: .public) - Data: \(hashedSensitiveData.description, privacy: .public) - Time: \(timestamp.ISO8601Format(), privacy: .public)")
    }
}

// MARK: - Preview Support

#Preview {
    Text("SuggestionViewModel Preview")
        .padding()
}
