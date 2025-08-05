import AppCore
import CoreML
import Foundation

// MARK: - Core Compliance Models

/// Compliance Test Dataset - Provides test data for validation
public struct ComplianceTestDataset: Sendable {
    public static func loadKnownViolations() async throws -> ComplianceTestDataset {
        // RED phase: Return minimal dataset to cause accuracy test failures
        ComplianceTestDataset()
    }

    public func getKnownViolations() -> [TestCase] {
        // RED phase: Return empty test cases to cause accuracy failures
        []
    }

    public func getCompliantDocuments() -> [TestDocument] {
        // RED phase: Return empty documents to cause false positive test failures
        []
    }

    public func getFARSection15203Violation() -> TestDocument {
        // RED phase: Return basic document without proper violation markers
        TestDocument(
            id: UUID(),
            content: "Basic document content",
            complexity: .low,
            testId: 1
        )
    }
}

public struct TestCase: Sendable {
    public let document: TestDocument
    public let expectedViolation: ViolationType

    public init(document: TestDocument, expectedViolation: ViolationType) {
        self.document = document
        self.expectedViolation = expectedViolation
    }
}

/// Compliance Performance Metrics - Tracks system performance for compliance
public struct CompliancePerformanceMetrics: Sendable {
    public init() {}

    public func getCurrentMemoryUsage() -> Int64 {
        // RED phase: Return 0 to cause memory tracking test failures
        0
    }
}

/// Compliance Warning Manager - Manages progressive warning hierarchy
public struct ComplianceWarningManager: Sendable {
    public init() {}

    public func createWarning(for _: GuardianComplianceResult) async throws -> ComplianceUIWarningView {
        // RED phase: Return basic warning that will fail UI tests
        ComplianceUIWarningView()
    }
}

public struct ComplianceUIWarningView: Sendable {
    public let level: WarningLevel
    public let borderColor: WarningColor
    public let hasMarginIcon: Bool
    public let interruptsWorkflow: Bool
    public let hapticFeedback: HapticFeedbackType
    public let detailedExplanation: String?
    public let fixSuggestions: [String]?
    public let supportsSwipeToDismiss: Bool
    public let requiresExplicitAcknowledgment: Bool
    public let generatesAuditTrail: Bool
    public let isDismissibleWithoutAction: Bool
    public let isDismissible: Bool
    public let requiresExplicitAction: Bool
    public let complianceDetails: String?
    public let resolutionSuggestions: [String]?

    public init() {
        // RED phase: Initialize with values that will fail UI tests
        level = .passive
        borderColor = .red // Wrong color for passive level
        hasMarginIcon = false // Should be true for passive
        interruptsWorkflow = true // Should be false for passive
        hapticFeedback = .heavy // Wrong feedback for passive
        detailedExplanation = nil
        fixSuggestions = nil
        supportsSwipeToDismiss = false
        requiresExplicitAcknowledgment = false
        generatesAuditTrail = false
        isDismissibleWithoutAction = true
        isDismissible = false
        requiresExplicitAction = true
        complianceDetails = nil
        resolutionSuggestions = nil
    }

    public func showTooltip() async throws -> ComplianceTooltip {
        // RED phase: Return empty tooltip to fail tests
        ComplianceTooltip()
    }
}

public struct ComplianceTooltip: Sendable {
    public let complianceDetails: String?
    public let resolutionSuggestions: [String]?
    public let isDismissible: Bool
    public let requiresExplicitAction: Bool

    public init() {
        // RED phase: Initialize with nil values to fail tests
        complianceDetails = nil
        resolutionSuggestions = nil
        isDismissible = false
        requiresExplicitAction = true
    }
}

public enum WarningLevel: Sendable {
    case passive
    case contextual
    case bottomSheet
    case modal
}

public enum WarningColor: Sendable {
    case yellow
    case orange
    case red
}

public enum HapticFeedbackType: Sendable {
    case none
    case light
    case medium
    case heavy
}

/// Compliance Integration Coordinator - Integrates with DocumentChainManager
public final class ComplianceIntegrationCoordinator: @unchecked Sendable {
    public var onComplianceResult: (@Sendable (GuardianComplianceResult) -> Void)?

    public init(
        documentManager _: ComplianceDocumentChainManager,
        guardian _: ComplianceGuardian
    ) async throws {
        // RED phase: Basic initialization without proper integration
    }
}

/// Mock Network Provider for testing offline scenarios
public final class MockNetworkProvider: NetworkProvider, @unchecked Sendable {
    private var shouldFailNetwork = false

    public init() {}

    public func simulateNetworkFailure() {
        // RED phase: Enable network failure simulation
        shouldFailNetwork = true
    }

    public func updateRules() async throws -> RuleUpdateResult {
        if shouldFailNetwork {
            return RuleUpdateResult(success: false, usingCachedRules: true)
        }
        return RuleUpdateResult(success: true, usingCachedRules: false)
    }
}

/// User Action for feedback tracking
public enum UserAction: Sendable {
    case dismissWarning(reason: DismissalReason)
    case acceptSuggestion
    case rejectSuggestion

    public enum DismissalReason: Sendable {
        case falsePositive
        case notRelevant
        case willFixLater
    }
}

/// Compliance Error types
public enum ComplianceError: Error, Sendable {
    case invalidDocumentFormat
    case networkFailure
    case modelLoadFailure
    case analysisTimeout

    public var type: ComplianceErrorType {
        switch self {
        case .invalidDocumentFormat:
            .invalidDocumentFormat
        case .networkFailure:
            .networkFailure
        case .modelLoadFailure:
            .modelLoadFailure
        case .analysisTimeout:
            .analysisTimeout
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .invalidDocumentFormat:
            "Check document format and try again"
        case .networkFailure:
            "Check network connection and retry"
        case .modelLoadFailure:
            "Restart application to reload models"
        case .analysisTimeout:
            "Try with a smaller document"
        }
    }
}

public enum ComplianceErrorType: Sendable {
    case invalidDocumentFormat
    case networkFailure
    case modelLoadFailure
    case analysisTimeout
}

// MARK: - Mock Protocols and Implementations

public protocol LearningFeedbackLoop: Sendable {
    func recordFeedback(_ feedback: ComplianceFeedback) async throws
    func getLastEvent() async throws -> LearningEvent
    func recordEvent(_ event: LearningEvent) async throws
}

public protocol CompliancePolicyEngine: Sendable {
    func evaluatePolicy(_ document: TestDocument) async throws -> PolicyEvaluation
}

public protocol NetworkProvider: Sendable {
    func updateRules() async throws -> RuleUpdateResult
}

public struct MockLearningFeedbackLoop: LearningFeedbackLoop {
    public init() {}

    public func recordFeedback(_: ComplianceFeedback) async throws {
        // RED phase: Do nothing to cause integration test failures
    }

    public func getLastEvent() async throws -> LearningEvent {
        // RED phase: Return basic event with wrong type
        LearningEvent(
            eventType: .requirementEntered, // Wrong type for compliance
            context: LearningEvent.EventContext(
                workflowState: "",
                acquisitionId: nil,
                documentType: nil,
                userData: [:],
                systemData: [:]
            )
        )
    }

    public func recordEvent(_: LearningEvent) async throws {
        // GREEN phase: Accept event recording to make tests pass
    }
}

public struct MockCompliancePolicyEngine: CompliancePolicyEngine {
    public init() {}

    public func evaluatePolicy(_: TestDocument) async throws -> PolicyEvaluation {
        // RED phase: Return empty evaluation
        PolicyEvaluation()
    }
}

public struct ComplianceFeedback: Sendable {
    public let result: GuardianComplianceResult
    public let userAction: UserAction
    public let timestamp: Date

    public init(result: GuardianComplianceResult, userAction: UserAction) {
        self.result = result
        self.userAction = userAction
        timestamp = Date()
    }
}

public struct PolicyEvaluation: Sendable {
    public let compliant: Bool
    public let violations: [String]

    public init(compliant: Bool = false, violations: [String] = []) {
        self.compliant = compliant
        self.violations = violations
    }
}

// MARK: - Missing Mock Types for Tests

// ComplianceDocumentChainManager is defined in DocumentChainManager+Compliance.swift

// LearningLoop is defined in LearningLoop.swift with shared instance

// MARK: - Mock ML Feature Provider

public class MockMLFeatureProvider: MLFeatureProvider {
    public init() {}

    public var featureNames: Set<String> {
        ["feature1", "feature2", "feature3"]
    }

    public func featureValue(for _: String) -> MLFeatureValue? {
        MLFeatureValue(double: 0.5)
    }
}

// RED PHASE MARKER: All implementations are designed to fail tests appropriately
