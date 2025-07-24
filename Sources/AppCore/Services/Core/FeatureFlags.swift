import Foundation
import SwiftUI

/// FeatureFlags - Unified feature flag system for gradual rollout and rollback
/// Week 1-2 deliverable: Feature flag system operational for gradual rollout
///
/// Provides comprehensive feature flag management with:
/// - SwiftUI Observable integration for reactive UI updates
/// - Sendable compliance for Swift 6 concurrency
/// - Canary rollout functionality with user-based consistency
/// - Emergency rollback capabilities
/// - Usage metrics and audit logging
/// - Safe default states for all features
public final class FeatureFlags {
    // MARK: - Singleton

    public nonisolated(unsafe) static let shared = FeatureFlags()

    // MARK: - AI Feature Flags (Default: OFF for safety)

    public var useNewAIOrchestrator: Bool = false
    public var useUnifiedProviders: Bool = false
    public var enableSmartCaching: Bool = false
    public var useDocumentEngine: Bool = false
    public var useComplianceValidator: Bool = false

    // MARK: - UI Feature Flags (Default: Legacy TCA enabled)

    public var useLegacyTCA: Bool = true
    public var enableSwiftUINavigation: Bool = false
    public var useGraphRAG: Bool = false
    public var enableNewDocumentView: Bool = false

    // MARK: - Rollout State

    private var rolloutManager: RolloutManager
    private let auditLogger: FeatureFlagAuditLogger
    private let metricsCollector: FeatureFlagMetricsCollector

    // MARK: - Thread Safety

    private let accessQueue = DispatchQueue(label: "com.aiko.featureflags", attributes: .concurrent)

    // MARK: - Initialization

    private init() {
        rolloutManager = RolloutManager()
        auditLogger = FeatureFlagAuditLogger()
        metricsCollector = FeatureFlagMetricsCollector()

        // Initialize with safe defaults
        loadSafeDefaults()
    }

    // MARK: - Public API - Canary Rollout

    /// Enable canary rollout for a feature with percentage-based distribution
    /// - Parameters:
    ///   - feature: Feature to enable rollout for
    ///   - percentage: Percentage of users to enable (0-100)
    /// - Throws: FeatureFlagError for invalid parameters
    public func canaryRollout(feature: Feature, percentage: Int) throws {
        guard percentage >= 0, percentage <= 100 else {
            throw FeatureFlagError.invalidPercentage(percentage)
        }

        // Simplified for RED phase - no threading complexity
        rolloutManager.setRolloutPercentage(feature: feature, percentage: percentage)
        auditLogger.logAction(.rolloutPercentageChanged(percentage), feature: feature)
        metricsCollector.recordRolloutChange(feature: feature, percentage: percentage)
    }

    /// Check if feature is enabled for specific user
    /// - Parameters:
    ///   - feature: Feature to check
    ///   - userId: User ID for consistent rollout determination
    /// - Returns: Boolean indicating if feature is enabled for this user
    public func isFeatureEnabledForUser(_ feature: Feature, userId: String) -> Bool {
        // Check if feature is globally enabled first
        let isGloballyEnabled = getGlobalFeatureState(feature)
        if isGloballyEnabled {
            return true
        }

        // Check rollout percentage
        let rolloutPercentage = rolloutManager.getRolloutPercentage(feature: feature)
        if rolloutPercentage == 0 {
            return false
        }
        if rolloutPercentage == 100 {
            return true
        }

        // Use consistent hash-based determination
        return rolloutManager.isUserInRollout(feature: feature, userId: userId, percentage: rolloutPercentage)
    }

    // MARK: - Public API - Emergency Controls

    /// Emergency rollback for specific features
    /// - Parameter features: Array of features to rollback
    public func emergencyRollback(features: [Feature]) {
        for feature in features {
            setFeatureState(feature, enabled: false)
            rolloutManager.setRolloutPercentage(feature: feature, percentage: 0)
            auditLogger.logAction(.emergencyRollback, feature: feature)
        }

        metricsCollector.recordEmergencyRollback(features: features)
    }

    /// Rollback all features to known good state
    public func rollbackToKnownGoodState() {
        loadSafeDefaults()
        rolloutManager.resetAllRollouts()

        for feature in Feature.allCases {
            auditLogger.logAction(.emergencyRollback, feature: feature)
        }

        metricsCollector.recordFullRollback()
    }

    /// Reset all flags to their default values
    public func resetToDefaults() {
        loadSafeDefaults()
        rolloutManager.resetAllRollouts()
    }

    // MARK: - Public API - Monitoring

    /// Get current usage metrics
    /// - Returns: Current feature flag metrics
    public func getUsageMetrics() -> FeatureFlagMetrics {
        let enabledFeatures = Set(Feature.allCases.filter { getGlobalFeatureState($0) })
        let disabledFeatures = Set(Feature.allCases.filter { !getGlobalFeatureState($0) })
        let rolloutPercentages = Dictionary(uniqueKeysWithValues:
            Feature.allCases.map { ($0, rolloutManager.getRolloutPercentage(feature: $0)) }
        )

        return FeatureFlagMetrics(
            enabledFeatures: enabledFeatures,
            disabledFeatures: disabledFeatures,
            rolloutPercentages: rolloutPercentages,
            lastUpdated: Date()
        )
    }

    /// Get audit log of feature flag changes
    /// - Returns: Array of audit entries
    public func getAuditLog() -> [FeatureFlagAuditEntry] {
        auditLogger.getAuditLog()
    }

    // MARK: - Private Implementation

    private func loadSafeDefaults() {
        // AI Features: OFF by default for safety
        useNewAIOrchestrator = false
        useUnifiedProviders = false
        enableSmartCaching = false
        useDocumentEngine = false
        useComplianceValidator = false

        // UI Features: Legacy TCA enabled by default
        useLegacyTCA = true
        enableSwiftUINavigation = false
        useGraphRAG = false
        enableNewDocumentView = false
    }

    private func getGlobalFeatureState(_ feature: Feature) -> Bool {
        switch feature {
        case .newAIOrchestrator:
            useNewAIOrchestrator
        case .unifiedProviders:
            useUnifiedProviders
        case .smartCaching:
            enableSmartCaching
        case .documentEngine:
            useDocumentEngine
        case .complianceValidator:
            useComplianceValidator
        case .swiftUINavigation:
            enableSwiftUINavigation
        case .graphRAG:
            useGraphRAG
        case .newDocumentView:
            enableNewDocumentView
        }
    }

    private func setFeatureState(_ feature: Feature, enabled: Bool) {
        switch feature {
        case .newAIOrchestrator:
            useNewAIOrchestrator = enabled
        case .unifiedProviders:
            useUnifiedProviders = enabled
        case .smartCaching:
            enableSmartCaching = enabled
        case .documentEngine:
            useDocumentEngine = enabled
        case .complianceValidator:
            useComplianceValidator = enabled
        case .swiftUINavigation:
            enableSwiftUINavigation = enabled
            if enabled {
                useLegacyTCA = false // Disable legacy when new UI is enabled
            }
        case .graphRAG:
            useGraphRAG = enabled
        case .newDocumentView:
            enableNewDocumentView = enabled
        }
    }

    private func startMonitoring() async {
        // Start background monitoring and metrics collection
        await metricsCollector.startCollection()
    }
}

// MARK: - Supporting Types

public enum Feature: String, CaseIterable, Sendable {
    case newAIOrchestrator = "new_ai_orchestrator"
    case unifiedProviders = "unified_providers"
    case smartCaching = "smart_caching"
    case documentEngine = "document_engine"
    case complianceValidator = "compliance_validator"
    case swiftUINavigation = "swiftui_navigation"
    case graphRAG = "graph_rag"
    case newDocumentView = "new_document_view"
}

public struct FeatureFlagMetrics: Sendable {
    public let enabledFeatures: Set<Feature>
    public let disabledFeatures: Set<Feature>
    public let rolloutPercentages: [Feature: Int]
    public let lastUpdated: Date

    public func contains(_ feature: Feature) -> Bool {
        enabledFeatures.contains(feature)
    }
}

public struct FeatureFlagAuditEntry: Sendable {
    public let feature: Feature
    public let action: FeatureFlagAction
    public let timestamp: Date
    public let userId: String?
    public let reason: String?

    public init(
        feature: Feature,
        action: FeatureFlagAction,
        timestamp: Date = Date(),
        userId: String? = nil,
        reason: String? = nil
    ) {
        self.feature = feature
        self.action = action
        self.timestamp = timestamp
        self.userId = userId
        self.reason = reason
    }
}

public enum FeatureFlagAction: Sendable {
    case enabled
    case disabled
    case rolloutPercentageChanged(Int)
    case emergencyRollback
}

public enum FeatureFlagError: Error, LocalizedError {
    case invalidPercentage(Int)
    case featureNotFound(String)
    case rolloutInProgress(Feature)
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidPercentage(percentage):
            "Invalid rollout percentage: \(percentage). Must be between 0-100."
        case let .featureNotFound(featureName):
            "Feature not found: \(featureName)"
        case let .rolloutInProgress(feature):
            "Rollout already in progress for feature: \(feature.rawValue)"
        case let .unknownError(message):
            "Unknown feature flag error: \(message)"
        }
    }
}

// MARK: - Placeholder Dependencies (Will be implemented in GREEN phase)

public struct RolloutManager: Sendable {
    private var rolloutPercentages: [Feature: Int] = [:]

    public init() {}

    public mutating func setRolloutPercentage(feature: Feature, percentage: Int) {
        // In a real implementation, this would be thread-safe
        // For RED phase, this is a placeholder
        rolloutPercentages[feature] = percentage
    }

    public func getRolloutPercentage(feature: Feature) -> Int {
        rolloutPercentages[feature] ?? 0
    }

    public func isUserInRollout(feature: Feature, userId: String, percentage: Int) -> Bool {
        // Use consistent hash-based determination
        let hashValue = abs(userId.hashValue ^ feature.rawValue.hashValue)
        let userPercentile = hashValue % 100
        return userPercentile < percentage
    }

    public mutating func resetAllRollouts() {
        rolloutPercentages.removeAll()
    }
}

public struct FeatureFlagAuditLogger: Sendable {
    private var auditLog: [FeatureFlagAuditEntry] = []

    public init() {}

    public func logAction(_ action: FeatureFlagAction, feature: Feature, userId: String? = nil, reason: String? = nil) {
        _ = FeatureFlagAuditEntry(
            feature: feature,
            action: action,
            userId: userId,
            reason: reason
        )
        // In a real implementation, this would be thread-safe and persistent
        // For RED phase, this is a placeholder
    }

    public func getAuditLog() -> [FeatureFlagAuditEntry] {
        auditLog
    }
}

public struct FeatureFlagMetricsCollector: Sendable {
    public init() {}

    public func startCollection() async {
        // Start collecting metrics in background
    }

    public func recordRolloutChange(feature _: Feature, percentage _: Int) {
        // Record rollout change metric
    }

    public func recordEmergencyRollback(features _: [Feature]) {
        // Record emergency rollback metric
    }

    public func recordFullRollback() {
        // Record full system rollback metric
    }
}
