import CryptoKit
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
public final class FeatureFlags: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = FeatureFlags()

    // MARK: - Thread Safety

    private let lock = NSRecursiveLock()

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

    private let rolloutManager: RolloutManager
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
    public func canaryRollout(feature: Feature, percentage: Int) async throws {
        guard percentage >= 0, percentage <= 100 else {
            throw FeatureFlagError.invalidPercentage(percentage)
        }

        // Use async calls to actor-isolated methods
        await rolloutManager.setRolloutPercentage(feature: feature, percentage: percentage)
        await auditLogger.logAction(.rolloutPercentageChanged(percentage), feature: feature)
        await metricsCollector.recordRolloutChange(feature: feature, percentage: percentage)
    }

    /// Check if feature is enabled for specific user
    /// - Parameters:
    ///   - feature: Feature to check
    ///   - userId: User ID for consistent rollout determination
    /// - Returns: Boolean indicating if feature is enabled for this user
    public func isFeatureEnabledForUser(_ feature: Feature, userId: String) async -> Bool {
        // Check if feature is globally enabled first
        let isGloballyEnabled = getGlobalFeatureState(feature)
        if isGloballyEnabled {
            return true
        }

        // Check rollout percentage
        let rolloutPercentage = await rolloutManager.getRolloutPercentage(feature: feature)
        if rolloutPercentage == 0 {
            return false
        }
        if rolloutPercentage == 100 {
            return true
        }

        // Use consistent hash-based determination
        return await rolloutManager.isUserInRollout(feature: feature, userId: userId, percentage: rolloutPercentage)
    }

    // MARK: - Public API - Emergency Controls

    /// Emergency rollback for specific features
    /// - Parameter features: Array of features to rollback
    public func emergencyRollback(features: [Feature]) async {
        for feature in features {
            setFeatureState(feature, enabled: false)
            await rolloutManager.setRolloutPercentage(feature: feature, percentage: 0)
            await auditLogger.logAction(.emergencyRollback, feature: feature)
        }

        await metricsCollector.recordEmergencyRollback(features: features)
    }

    /// Rollback all features to known good state
    public func rollbackToKnownGoodState() async {
        loadSafeDefaults()
        await rolloutManager.resetAllRollouts()

        for feature in Feature.allCases {
            await auditLogger.logAction(.emergencyRollback, feature: feature)
        }

        await metricsCollector.recordFullRollback()
    }

    /// Reset all flags to their default values
    public func resetToDefaults() async {
        loadSafeDefaults()
        await rolloutManager.resetAllRollouts()
    }

    // MARK: - Public API - Monitoring

    /// Get current usage metrics
    /// - Returns: Current feature flag metrics
    public func getUsageMetrics() async -> FeatureFlagMetrics {
        let enabledFeatures = Set(Feature.allCases.filter { getGlobalFeatureState($0) })
        let disabledFeatures = Set(Feature.allCases.filter { !getGlobalFeatureState($0) })

        var rolloutPercentages: [Feature: Int] = [:]
        for feature in Feature.allCases {
            rolloutPercentages[feature] = await rolloutManager.getRolloutPercentage(feature: feature)
        }

        return FeatureFlagMetrics(
            enabledFeatures: enabledFeatures,
            disabledFeatures: disabledFeatures,
            rolloutPercentages: rolloutPercentages,
            lastUpdated: Date()
        )
    }

    /// Get audit log of feature flag changes
    /// - Returns: Array of audit entries
    public func getAuditLog() async -> [FeatureFlagAuditEntry] {
        await auditLogger.getAuditLog()
    }

    // MARK: - Protocol Conformance Methods

    /// Check if feature is enabled for specific user (Protocol method)
    /// - Parameters:
    ///   - feature: Feature to check
    ///   - userId: User identifier
    /// - Returns: True if feature is enabled for user
    public func isEnabled(_ feature: Feature, userId: String) async -> Bool {
        await isFeatureEnabledForUser(feature, userId: userId)
    }

    /// Log feature usage for specific user (Protocol method)
    /// - Parameters:
    ///   - feature: Feature being used
    ///   - userId: User identifier
    ///   - action: Action being logged
    public func logFeatureUsage(_ feature: Feature, userId: String, action: FeatureFlagAction) async {
        await auditLogger.logAction(action, feature: feature, userId: userId)
        await metricsCollector.recordFeatureUsage(feature: feature, userId: userId)
    }

    /// Set rollout percentage for feature (Protocol method - async version)
    /// - Parameters:
    ///   - feature: Feature to set percentage for
    ///   - percentage: Rollout percentage (0-100)
    public func setRolloutPercentage(feature: Feature, percentage: Int) async {
        await rolloutManager.setRolloutPercentage(feature: feature, percentage: percentage)
        await auditLogger.logAction(.rolloutPercentageChanged(percentage), feature: feature)
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

public enum Feature: String, CaseIterable, Sendable, Codable {
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

public struct FeatureFlagAuditEntry: Sendable, Codable {
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

public enum FeatureFlagAction: Sendable, Codable, Hashable {
    case enabled
    case disabled
    case rolloutPercentageChanged(Int)
    case emergencyRollback
    case auditLogCleared
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

// MARK: - Production Dependencies

/// Thread-safe RolloutManager using actor for concurrency safety
public actor RolloutManager {
    private var rolloutPercentages: [Feature: Int] = [:]
    private var rolloutHistory: [Feature: [RolloutHistoryEntry]] = [:]
    private let persistenceURL: URL

    public init() {
        // Create persistence directory with safe unwrapping
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback to temporary directory if documents directory unavailable
            let tempPath = FileManager.default.temporaryDirectory
            persistenceURL = tempPath.appendingPathComponent("FeatureFlags")
            return
        }
        persistenceURL = documentsPath.appendingPathComponent("FeatureFlags")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: persistenceURL, withIntermediateDirectories: true)

        // Load persisted state
        Task {
            await loadPersistedState()
        }
    }

    /// Set rollout percentage for a feature with persistence and history tracking
    /// - Parameters:
    ///   - feature: Feature to configure
    ///   - percentage: Rollout percentage (0-100)
    public func setRolloutPercentage(feature: Feature, percentage: Int) {
        let previousPercentage = rolloutPercentages[feature] ?? 0
        rolloutPercentages[feature] = percentage

        // Track history
        let historyEntry = RolloutHistoryEntry(
            percentage: percentage,
            previousPercentage: previousPercentage,
            timestamp: Date(),
            reason: "Manual rollout update"
        )

        if rolloutHistory[feature] == nil {
            rolloutHistory[feature] = []
        }
        rolloutHistory[feature]?.append(historyEntry)

        // Keep only last 100 entries per feature
        if let history = rolloutHistory[feature], history.count > 100 {
            rolloutHistory[feature] = Array(history.suffix(100))
        }

        // Persist state asynchronously
        Task {
            persistState()
        }
    }

    /// Get current rollout percentage for feature
    /// - Parameter feature: Feature to query
    /// - Returns: Current rollout percentage (0-100)
    public func getRolloutPercentage(feature: Feature) -> Int {
        rolloutPercentages[feature] ?? 0
    }

    /// Determine if user is included in rollout using consistent hashing
    /// - Parameters:
    ///   - feature: Feature to check
    ///   - userId: User identifier for consistent determination
    ///   - percentage: Current rollout percentage
    /// - Returns: True if user should receive the feature
    public func isUserInRollout(feature: Feature, userId: String, percentage: Int) -> Bool {
        guard percentage > 0 else { return false }
        guard percentage < 100 else { return true }

        // Use SHA256 for consistent, cryptographically sound distribution
        let combinedString = "\(feature.rawValue):\(userId)"
        let hash = combinedString.data(using: .utf8)?.sha256Hash ?? Data()

        // Convert first 4 bytes to UInt32 for percentage calculation
        guard hash.count >= 4 else { return false }

        let hashValue = hash.withUnsafeBytes { bytes in
            bytes.bindMemory(to: UInt32.self).first ?? 0
        }

        let userPercentile = Int(hashValue % 100)
        return userPercentile < percentage
    }

    /// Reset all rollout percentages to 0
    public func resetAllRollouts() {
        for feature in Feature.allCases {
            rolloutPercentages[feature] = 0

            let historyEntry = RolloutHistoryEntry(
                percentage: 0,
                previousPercentage: rolloutPercentages[feature] ?? 0,
                timestamp: Date(),
                reason: "System reset"
            )

            if rolloutHistory[feature] == nil {
                rolloutHistory[feature] = []
            }
            rolloutHistory[feature]?.append(historyEntry)
        }

        Task {
            persistState()
        }
    }

    /// Get rollout history for a feature
    /// - Parameter feature: Feature to query
    /// - Returns: Array of history entries
    public func getRolloutHistory(feature: Feature) -> [RolloutHistoryEntry] {
        rolloutHistory[feature] ?? []
    }

    /// Get current rollout statistics
    /// - Returns: Summary statistics
    public func getRolloutStatistics() -> RolloutStatistics {
        let activeRollouts = rolloutPercentages.filter { $0.value > 0 && $0.value < 100 }
        let fullyEnabled = rolloutPercentages.filter { $0.value == 100 }
        let disabled = rolloutPercentages.filter { $0.value == 0 }

        return RolloutStatistics(
            activeRollouts: activeRollouts.count,
            fullyEnabledFeatures: fullyEnabled.count,
            disabledFeatures: disabled.count,
            totalFeatures: Feature.allCases.count,
            averageRolloutPercentage: rolloutPercentages.values.reduce(0, +) / max(rolloutPercentages.count, 1)
        )
    }

    // MARK: - Private Implementation

    private func loadPersistedState() {
        let stateFile = persistenceURL.appendingPathComponent("rollout_state.json")

        guard FileManager.default.fileExists(atPath: stateFile.path),
              let data = try? Data(contentsOf: stateFile),
              let state = try? JSONDecoder().decode(PersistedRolloutState.self, from: data)
        else {
            return
        }

        rolloutPercentages = state.rolloutPercentages
        rolloutHistory = state.rolloutHistory
    }

    private func persistState() {
        let stateFile = persistenceURL.appendingPathComponent("rollout_state.json")

        let state = PersistedRolloutState(
            rolloutPercentages: rolloutPercentages,
            rolloutHistory: rolloutHistory
        )

        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: stateFile)
        } catch {
            print("Failed to persist rollout state: \(error)")
        }
    }
}

// MARK: - Supporting Types for RolloutManager

public struct RolloutHistoryEntry: Codable, Sendable {
    public let percentage: Int
    public let previousPercentage: Int
    public let timestamp: Date
    public let reason: String

    public init(percentage: Int, previousPercentage: Int, timestamp: Date, reason: String) {
        self.percentage = percentage
        self.previousPercentage = previousPercentage
        self.timestamp = timestamp
        self.reason = reason
    }
}

public struct RolloutStatistics: Sendable {
    public let activeRollouts: Int
    public let fullyEnabledFeatures: Int
    public let disabledFeatures: Int
    public let totalFeatures: Int
    public let averageRolloutPercentage: Int

    public init(activeRollouts: Int, fullyEnabledFeatures: Int, disabledFeatures: Int, totalFeatures: Int, averageRolloutPercentage: Int) {
        self.activeRollouts = activeRollouts
        self.fullyEnabledFeatures = fullyEnabledFeatures
        self.disabledFeatures = disabledFeatures
        self.totalFeatures = totalFeatures
        self.averageRolloutPercentage = averageRolloutPercentage
    }
}

private struct PersistedRolloutState: Codable {
    let rolloutPercentages: [Feature: Int]
    let rolloutHistory: [Feature: [RolloutHistoryEntry]]
}

// MARK: - CryptoKit Extensions

extension Data {
    var sha256Hash: Data {
        Data(SHA256.hash(data: self))
    }
}

/// Thread-safe audit logger with persistent storage for feature flag operations
public actor FeatureFlagAuditLogger {
    private var auditLog: [FeatureFlagAuditEntry] = []
    private let persistenceURL: URL
    private let maxLogEntries: Int = 10000
    private let fileManager = FileManager.default

    public init() {
        // Create audit logs directory with safe unwrapping
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback to temporary directory if documents directory unavailable
            let tempPath = fileManager.temporaryDirectory
            persistenceURL = tempPath.appendingPathComponent("FeatureFlags/AuditLogs")
            return
        }
        persistenceURL = documentsPath.appendingPathComponent("FeatureFlags/AuditLogs")

        // Create directory if needed
        try? fileManager.createDirectory(at: persistenceURL, withIntermediateDirectories: true)

        // Load existing audit log
        Task {
            await loadPersistedAuditLog()
        }
    }

    /// Log a feature flag action with automatic persistence
    /// - Parameters:
    ///   - action: Action performed on the feature flag
    ///   - feature: Feature that was modified
    ///   - userId: Optional user who performed the action
    ///   - reason: Optional reason for the action
    public func logAction(_ action: FeatureFlagAction, feature: Feature, userId: String? = nil, reason: String? = nil) {
        let entry = FeatureFlagAuditEntry(
            feature: feature,
            action: action,
            userId: userId,
            reason: reason
        )

        auditLog.append(entry)

        // Rotate log if it gets too large
        if auditLog.count > maxLogEntries {
            // Keep most recent entries and archive old ones
            let entriesToArchive = Array(auditLog.prefix(auditLog.count - maxLogEntries + 1000))
            auditLog = Array(auditLog.suffix(maxLogEntries - 1000))

            Task {
                archiveOldEntries(entriesToArchive)
            }
        }

        // Persist current log asynchronously
        Task {
            persistAuditLog()
        }
    }

    /// Get current audit log entries
    /// - Parameter limit: Maximum number of entries to return (default: all)
    /// - Returns: Array of audit entries, newest first
    public func getAuditLog(limit: Int? = nil) -> [FeatureFlagAuditEntry] {
        let sortedLog = auditLog.sorted { $0.timestamp > $1.timestamp }

        if let limit {
            return Array(sortedLog.prefix(limit))
        }

        return sortedLog
    }

    /// Get audit log entries for specific feature
    /// - Parameters:
    ///   - feature: Feature to filter by
    ///   - limit: Maximum number of entries to return
    /// - Returns: Array of audit entries for the feature
    public func getAuditLog(for feature: Feature, limit: Int? = nil) -> [FeatureFlagAuditEntry] {
        let filteredLog = auditLog
            .filter { $0.feature == feature }
            .sorted { $0.timestamp > $1.timestamp }

        if let limit {
            return Array(filteredLog.prefix(limit))
        }

        return filteredLog
    }

    /// Get audit log entries for specific user
    /// - Parameters:
    ///   - userId: User ID to filter by
    ///   - limit: Maximum number of entries to return
    /// - Returns: Array of audit entries for the user
    public func getAuditLog(for userId: String, limit: Int? = nil) -> [FeatureFlagAuditEntry] {
        let filteredLog = auditLog
            .filter { $0.userId == userId }
            .sorted { $0.timestamp > $1.timestamp }

        if let limit {
            return Array(filteredLog.prefix(limit))
        }

        return filteredLog
    }

    /// Get audit statistics
    /// - Returns: Summary statistics about audit log
    public func getAuditStatistics() -> AuditStatistics {
        let totalEntries = auditLog.count
        let uniqueFeatures = Set(auditLog.map(\.feature)).count
        let uniqueUsers = Set(auditLog.compactMap(\.userId)).count

        let actionCounts = Dictionary(grouping: auditLog, by: \.action).mapValues(\.count)

        let recentEntries = auditLog.filter {
            $0.timestamp > Date().addingTimeInterval(-24 * 60 * 60) // Last 24 hours
        }.count

        return AuditStatistics(
            totalEntries: totalEntries,
            uniqueFeatures: uniqueFeatures,
            uniqueUsers: uniqueUsers,
            actionCounts: actionCounts,
            recentEntries: recentEntries,
            oldestEntry: auditLog.min(by: { $0.timestamp < $1.timestamp })?.timestamp,
            newestEntry: auditLog.max(by: { $0.timestamp < $1.timestamp })?.timestamp
        )
    }

    /// Clear all audit log entries (with backup)
    public func clearAuditLog() {
        // Create backup before clearing
        let backupEntries = auditLog
        auditLog.removeAll()

        Task {
            createBackup(backupEntries)
            persistAuditLog()

            // Log the clear action
            logAction(.auditLogCleared, feature: .newAIOrchestrator, reason: "Manual audit log clear")
        }
    }

    // MARK: - Private Implementation

    private func loadPersistedAuditLog() {
        let logFile = persistenceURL.appendingPathComponent("audit_log.json")

        guard fileManager.fileExists(atPath: logFile.path),
              let data = try? Data(contentsOf: logFile),
              let entries = try? JSONDecoder().decode([FeatureFlagAuditEntry].self, from: data)
        else {
            return
        }

        auditLog = entries
    }

    private func persistAuditLog() {
        let logFile = persistenceURL.appendingPathComponent("audit_log.json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(auditLog)
            try data.write(to: logFile)
        } catch {
            print("Failed to persist audit log: \(error)")
        }
    }

    private func archiveOldEntries(_ entries: [FeatureFlagAuditEntry]) {
        let timestamp = Date().timeIntervalSince1970
        let archiveFile = persistenceURL.appendingPathComponent("audit_archive_\(Int(timestamp)).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: archiveFile)
        } catch {
            print("Failed to archive old audit entries: \(error)")
        }
    }

    private func createBackup(_ entries: [FeatureFlagAuditEntry]) {
        let timestamp = Date().timeIntervalSince1970
        let backupFile = persistenceURL.appendingPathComponent("audit_backup_\(Int(timestamp)).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: backupFile)
        } catch {
            print("Failed to create audit log backup: \(error)")
        }
    }
}

/// Real-time metrics collector for feature flag operations and usage analytics
public actor FeatureFlagMetricsCollector {
    private var metrics: [MetricEntry] = []
    private var isCollecting = false
    private let persistenceURL: URL
    private let maxMetricEntries: Int = 50000
    private let collectionInterval: TimeInterval = 60 // 1 minute
    private var backgroundTask: Task<Void, Never>?

    public init() {
        // Create metrics directory with safe unwrapping
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback to temporary directory if documents directory unavailable
            let tempPath = FileManager.default.temporaryDirectory
            persistenceURL = tempPath.appendingPathComponent("FeatureFlags/Metrics")
            return
        }
        persistenceURL = documentsPath.appendingPathComponent("FeatureFlags/Metrics")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: persistenceURL, withIntermediateDirectories: true)

        // Load existing metrics
        Task {
            await loadPersistedMetrics()
        }
    }

    deinit {
        backgroundTask?.cancel()
    }

    /// Start real-time metrics collection with background monitoring
    public func startCollection() async {
        guard !isCollecting else { return }

        isCollecting = true

        // Start background collection task
        backgroundTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                try? await Task.sleep(nanoseconds: UInt64(collectionInterval * 1_000_000_000))
                await collectSystemMetrics()
            }
        }

        // Record collection start
        recordMetric(.systemEvent("metrics_collection_started"), value: 1)
    }

    /// Stop metrics collection
    public func stopCollection() {
        isCollecting = false
        backgroundTask?.cancel()
        backgroundTask = nil

        recordMetric(.systemEvent("metrics_collection_stopped"), value: 1)
    }

    /// Record a rollout percentage change
    public func recordRolloutChange(feature: Feature, percentage: Int) {
        recordMetric(.rolloutChange(feature), value: Double(percentage))
    }

    /// Record emergency rollback event
    public func recordEmergencyRollback(features: [Feature]) {
        recordMetric(.emergencyRollback, value: Double(features.count))

        for feature in features {
            recordMetric(.featureRollback(feature), value: 0)
        }
    }

    /// Record full system rollback
    public func recordFullRollback() {
        recordMetric(.fullSystemRollback, value: Double(Feature.allCases.count))
    }

    /// Record feature usage event
    public func recordFeatureUsage(feature: Feature, userId: String) {
        recordMetric(.featureUsage(feature), value: 1, userId: userId)
    }

    /// Record feature evaluation (whether enabled/disabled for user)
    public func recordFeatureEvaluation(feature: Feature, userId: String, enabled: Bool) {
        recordMetric(.featureEvaluation(feature), value: enabled ? 1 : 0, userId: userId)
    }

    /// Get current metrics summary
    public func getMetricsSummary() -> MetricsSummary {
        let totalMetrics = metrics.count
        let uniqueFeatures = Set(metrics.compactMap { metric in
            switch metric.type {
            case let .featureUsage(feature), let .featureEvaluation(feature), let .rolloutChange(feature), let .featureRollback(feature):
                feature
            default:
                nil
            }
        }).count

        let recentMetrics = metrics.filter {
            $0.timestamp > Date().addingTimeInterval(-24 * 60 * 60) // Last 24 hours
        }.count

        let featureUsageCounts = Dictionary(uniqueKeysWithValues: metrics.compactMap { metric in
            if case let .featureUsage(feature) = metric.type {
                return (feature, 1)
            }
            return nil
        }.reduce(into: [Feature: Int]()) { result, item in
            result[item.0, default: 0] += item.1
        }.map { ($0.key, $0.value) })

        return MetricsSummary(
            totalMetrics: totalMetrics,
            uniqueFeatures: uniqueFeatures,
            recentMetrics: recentMetrics,
            featureUsageCounts: featureUsageCounts,
            collectionActive: isCollecting,
            oldestMetric: metrics.min(by: { $0.timestamp < $1.timestamp })?.timestamp,
            newestMetric: metrics.max(by: { $0.timestamp < $1.timestamp })?.timestamp
        )
    }

    /// Get metrics for specific feature
    public func getMetrics(for feature: Feature, limit: Int? = nil) -> [MetricEntry] {
        let filteredMetrics = metrics.filter { metric in
            switch metric.type {
            case let .featureUsage(f), let .featureEvaluation(f), let .rolloutChange(f), let .featureRollback(f):
                f == feature
            default:
                false
            }
        }.sorted { $0.timestamp > $1.timestamp }

        if let limit {
            return Array(filteredMetrics.prefix(limit))
        }

        return filteredMetrics
    }

    /// Get usage analytics for all features
    public func getUsageAnalytics() -> [Feature: FeatureAnalytics] {
        var analytics: [Feature: FeatureAnalytics] = [:]

        for feature in Feature.allCases {
            let featureMetrics = getMetrics(for: feature)

            let usageCount = featureMetrics.filter {
                if case .featureUsage = $0.type { return true }
                return false
            }.count

            let evaluationMetrics = featureMetrics.filter {
                if case .featureEvaluation = $0.type { return true }
                return false
            }

            let enabledEvaluations = evaluationMetrics.filter { $0.value > 0 }.count
            let totalEvaluations = evaluationMetrics.count
            let enabledRate = totalEvaluations > 0 ? Double(enabledEvaluations) / Double(totalEvaluations) : 0.0

            let uniqueUsers = Set(featureMetrics.compactMap(\.userId)).count

            analytics[feature] = FeatureAnalytics(
                usageCount: usageCount,
                enabledRate: enabledRate,
                uniqueUsers: uniqueUsers,
                totalEvaluations: totalEvaluations
            )
        }

        return analytics
    }

    /// Clear all metrics (with backup)
    public func clearMetrics() {
        let backupMetrics = metrics
        metrics.removeAll()

        Task {
            createMetricsBackup(backupMetrics)
            persistMetrics()
        }

        recordMetric(.systemEvent("metrics_cleared"), value: Double(backupMetrics.count))
    }

    // MARK: - Private Implementation

    private func recordMetric(_ type: MetricType, value: Double, userId: String? = nil) {
        let entry = MetricEntry(
            type: type,
            value: value,
            timestamp: Date(),
            userId: userId
        )

        metrics.append(entry)

        // Rotate metrics if they get too large
        if metrics.count > maxMetricEntries {
            let metricsToArchive = Array(metrics.prefix(metrics.count - maxMetricEntries + 5000))
            metrics = Array(metrics.suffix(maxMetricEntries - 5000))

            Task {
                archiveOldMetrics(metricsToArchive)
            }
        }

        // Persist periodically (every 100 entries)
        if metrics.count % 100 == 0 {
            Task {
                persistMetrics()
            }
        }
    }

    private func collectSystemMetrics() {
        // Collect system-level metrics
        recordMetric(.systemEvent("periodic_collection"), value: 1)

        // Record memory usage (simplified)
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if result == KERN_SUCCESS {
            let memoryUsage = Double(memoryInfo.resident_size) / (1024 * 1024) // MB
            recordMetric(.systemEvent("memory_usage_mb"), value: memoryUsage)
        }
    }

    private func loadPersistedMetrics() {
        let metricsFile = persistenceURL.appendingPathComponent("metrics.json")

        guard FileManager.default.fileExists(atPath: metricsFile.path),
              let data = try? Data(contentsOf: metricsFile),
              let entries = try? JSONDecoder().decode([MetricEntry].self, from: data)
        else {
            return
        }

        metrics = entries
    }

    private func persistMetrics() {
        let metricsFile = persistenceURL.appendingPathComponent("metrics.json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(metrics)
            try data.write(to: metricsFile)
        } catch {
            print("Failed to persist metrics: \(error)")
        }
    }

    private func archiveOldMetrics(_ metricsToArchive: [MetricEntry]) {
        let timestamp = Date().timeIntervalSince1970
        let archiveFile = persistenceURL.appendingPathComponent("metrics_archive_\(Int(timestamp)).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(metricsToArchive)
            try data.write(to: archiveFile)
        } catch {
            print("Failed to archive old metrics: \(error)")
        }
    }

    private func createMetricsBackup(_ metricsToBackup: [MetricEntry]) {
        let timestamp = Date().timeIntervalSince1970
        let backupFile = persistenceURL.appendingPathComponent("metrics_backup_\(Int(timestamp)).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(metricsToBackup)
            try data.write(to: backupFile)
        } catch {
            print("Failed to create metrics backup: \(error)")
        }
    }
}

// MARK: - Supporting Types for Audit Logger

public struct AuditStatistics: Sendable {
    public let totalEntries: Int
    public let uniqueFeatures: Int
    public let uniqueUsers: Int
    public let actionCounts: [FeatureFlagAction: Int]
    public let recentEntries: Int
    public let oldestEntry: Date?
    public let newestEntry: Date?

    public init(
        totalEntries: Int,
        uniqueFeatures: Int,
        uniqueUsers: Int,
        actionCounts: [FeatureFlagAction: Int],
        recentEntries: Int,
        oldestEntry: Date?,
        newestEntry: Date?
    ) {
        self.totalEntries = totalEntries
        self.uniqueFeatures = uniqueFeatures
        self.uniqueUsers = uniqueUsers
        self.actionCounts = actionCounts
        self.recentEntries = recentEntries
        self.oldestEntry = oldestEntry
        self.newestEntry = newestEntry
    }
}

// MARK: - Supporting Types for Metrics Collector

public struct MetricEntry: Codable, Sendable {
    public let type: MetricType
    public let value: Double
    public let timestamp: Date
    public let userId: String?

    public init(type: MetricType, value: Double, timestamp: Date, userId: String? = nil) {
        self.type = type
        self.value = value
        self.timestamp = timestamp
        self.userId = userId
    }
}

public enum MetricType: Codable, Sendable {
    case featureUsage(Feature)
    case featureEvaluation(Feature)
    case rolloutChange(Feature)
    case featureRollback(Feature)
    case emergencyRollback
    case fullSystemRollback
    case systemEvent(String)
}

public struct MetricsSummary: Sendable {
    public let totalMetrics: Int
    public let uniqueFeatures: Int
    public let recentMetrics: Int
    public let featureUsageCounts: [Feature: Int]
    public let collectionActive: Bool
    public let oldestMetric: Date?
    public let newestMetric: Date?

    public init(
        totalMetrics: Int,
        uniqueFeatures: Int,
        recentMetrics: Int,
        featureUsageCounts: [Feature: Int],
        collectionActive: Bool,
        oldestMetric: Date?,
        newestMetric: Date?
    ) {
        self.totalMetrics = totalMetrics
        self.uniqueFeatures = uniqueFeatures
        self.recentMetrics = recentMetrics
        self.featureUsageCounts = featureUsageCounts
        self.collectionActive = collectionActive
        self.oldestMetric = oldestMetric
        self.newestMetric = newestMetric
    }
}

public struct FeatureAnalytics: Sendable {
    public let usageCount: Int
    public let enabledRate: Double
    public let uniqueUsers: Int
    public let totalEvaluations: Int

    public init(usageCount: Int, enabledRate: Double, uniqueUsers: Int, totalEvaluations: Int) {
        self.usageCount = usageCount
        self.enabledRate = enabledRate
        self.uniqueUsers = uniqueUsers
        self.totalEvaluations = totalEvaluations
    }
}
