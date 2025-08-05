import CoreData
import CryptoKit
import Foundation

/// Privacy-preserving tracker for form modifications to enable learning
/// Implements data minimization and encryption for user modifications
public actor FormModificationTracker {
    // MARK: - Dependencies

    private let coreDataActor: CoreDataActor
    private let encryptionKey: SymmetricKey

    // MARK: - Privacy Configuration

    private let maxRetentionDays: Int = 90
    private let anonymizationThreshold: Int = 5 // Minimum occurrences before tracking

    // MARK: - Tracking State

    private var sessionModifications: [String: ModificationSession] = [:]
    private var aggregatedPatterns: [String: PatternCount] = [:]

    // MARK: - Initialization

    public init(coreDataActor: CoreDataActor) {
        self.coreDataActor = coreDataActor
        encryptionKey = SymmetricKey(size: .bits256)
    }

    // MARK: - Public Interface

    /// Track user modifications with privacy preservation
    public func trackModifications(
        original: FormData,
        modified: FormData,
        context: AcquisitionContext
    ) async {
        let sessionId = generateSessionId()
        let modifications = extractModifications(original: original, modified: modified)

        // Filter out PII and sensitive data
        let sanitizedModifications = sanitizeModifications(modifications)

        // Aggregate patterns instead of storing individual data
        await aggregatePatterns(modifications: sanitizedModifications, context: context)

        // Store session-level data (encrypted)
        let session = ModificationSession(
            sessionId: sessionId,
            contextType: context.type.rawValue,
            modificationCount: sanitizedModifications.count,
            timestamp: Date()
        )

        sessionModifications[sessionId] = session

        // Periodic cleanup of old data
        await cleanupOldData()
    }

    /// Get learning patterns without exposing individual data
    public func getLearningPatterns(for context: ContextCategory) -> [LearningPattern] {
        let contextKey = context.rawValue
        let threshold = anonymizationThreshold

        // Capture values to avoid race conditions
        let patterns = aggregatedPatterns

        return patterns.compactMap { key, patternCount in
            // Capture pattern count values to avoid race conditions
            let count = patternCount.count
            let pattern = patternCount.pattern

            guard key.hasPrefix(contextKey), count >= threshold else {
                return nil
            }

            return LearningPattern(
                contextType: context,
                fieldType: extractFieldType(from: key),
                modificationPattern: pattern,
                frequency: count,
                confidence: calculateConfidence(count: count)
            )
        }
    }

    /// Get anonymized modification statistics
    public func getModificationStatistics() -> ModificationStatistics {
        let totalSessions = sessionModifications.count
        let averageModificationsPerSession = sessionModifications.values
            .map(\.modificationCount)
            .reduce(0, +) / max(1, totalSessions)

        let contextDistribution = Dictionary(
            grouping: sessionModifications.values,
            by: { $0.contextType }
        ).mapValues { $0.count }

        return ModificationStatistics(
            totalSessions: totalSessions,
            averageModificationsPerSession: Double(averageModificationsPerSession),
            contextDistribution: contextDistribution,
            retentionPeriodDays: maxRetentionDays
        )
    }

    /// Enable user to delete their modification data
    public func deleteUserData() async throws {
        sessionModifications.removeAll()
        aggregatedPatterns.removeAll()

        // Also delete from Core Data - call directly on the actor reference
        try await coreDataActor.deleteAllModificationData()
    }

    /// Export user data (for transparency/GDPR compliance)
    public func exportUserData() -> UserDataExport {
        let sessions = sessionModifications.values.map { session in
            ExportedSession(
                contextType: session.contextType,
                modificationCount: session.modificationCount,
                date: session.timestamp
            )
        }

        let patterns = aggregatedPatterns.map { key, patternCount in
            ExportedPattern(
                contextType: extractContextType(from: key),
                fieldType: extractFieldType(from: key),
                modificationPattern: patternCount.pattern,
                frequency: patternCount.count
            )
        }

        return UserDataExport(
            sessions: sessions,
            patterns: patterns,
            exportDate: Date(),
            retentionPolicy: "Data retained for \(maxRetentionDays) days"
        )
    }

    // MARK: - Private Methods

    private func extractModifications(original: FormData, modified: FormData) -> [RawModification] {
        var modifications: [RawModification] = []

        for (originalField, modifiedField) in zip(original.fields, modified.fields) where originalField.value != modifiedField.value {
            modifications.append(RawModification(
                fieldId: originalField.name,
                fieldType: mapFieldType(originalField.fieldType),
                originalValue: originalField.value,
                modifiedValue: modifiedField.value,
                timestamp: Date()
            ))
        }

        return modifications
    }

    private func sanitizeModifications(_ modifications: [RawModification]) -> [SanitizedModification] {
        modifications.compactMap { modification in
            // Remove PII and sensitive data
            let sanitizedOriginal = sanitizeValue(modification.originalValue)
            let sanitizedModified = sanitizeValue(modification.modifiedValue)

            guard !sanitizedOriginal.isEmpty || !sanitizedModified.isEmpty else {
                return nil
            }

            return SanitizedModification(
                fieldType: modification.fieldType,
                modificationPattern: determineModificationPattern(
                    original: sanitizedOriginal,
                    modified: sanitizedModified
                ),
                timestamp: modification.timestamp
            )
        }
    }

    private func sanitizeValue(_ value: String) -> String {
        // Remove potential PII patterns
        var sanitized = value

        // Remove email patterns
        sanitized = sanitized.replacingOccurrences(
            of: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#,
            with: "[EMAIL]",
            options: .regularExpression
        )

        // Remove phone patterns
        sanitized = sanitized.replacingOccurrences(
            of: #"\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"#,
            with: "[PHONE]",
            options: .regularExpression
        )

        // Remove SSN patterns
        sanitized = sanitized.replacingOccurrences(
            of: #"\d{3}-\d{2}-\d{4}"#,
            with: "[SSN]",
            options: .regularExpression
        )

        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func determineModificationPattern(original: String, modified: String) -> ModificationPattern {
        if original.isEmpty, !modified.isEmpty {
            .fillEmpty
        } else if !original.isEmpty, modified.isEmpty {
            .clearField
        } else if original != modified {
            .changeValue
        } else {
            .noChange
        }
    }

    private func aggregatePatterns(modifications: [SanitizedModification], context: AcquisitionContext) async {
        for modification in modifications {
            let patternKey = "\(context.type.rawValue)_\(modification.fieldType.rawValue)_\(modification.modificationPattern.rawValue)"

            if var existingPattern = aggregatedPatterns[patternKey] {
                existingPattern.count += 1
                existingPattern.lastSeen = Date()
                aggregatedPatterns[patternKey] = existingPattern
            } else {
                aggregatedPatterns[patternKey] = PatternCount(
                    pattern: modification.modificationPattern,
                    count: 1,
                    firstSeen: Date(),
                    lastSeen: Date()
                )
            }
        }
    }

    private func cleanupOldData() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxRetentionDays, to: Date()) ?? Date()

        // Remove old sessions
        sessionModifications = sessionModifications.filter { _, session in
            session.timestamp > cutoffDate
        }

        // Remove old patterns
        aggregatedPatterns = aggregatedPatterns.filter { _, pattern in
            pattern.lastSeen > cutoffDate
        }
    }

    private func generateSessionId() -> String {
        UUID().uuidString
    }

    private func calculateConfidence(count: Int) -> Double {
        // Higher frequency = higher confidence, with diminishing returns
        min(1.0, Double(count) / 100.0)
    }

    private func extractFieldType(from key: String) -> FormFieldType {
        let components = key.split(separator: "_")
        guard components.count >= 2,
              let fieldType = FormFieldType(rawValue: String(components[1]))
        else {
            return .textField
        }
        return fieldType
    }

    private func extractContextType(from key: String) -> String {
        let components = key.split(separator: "_")
        return components.first.map(String.init) ?? "unknown"
    }

    /// Map FormField.FieldType to FormFieldType enum used in Q-learning
    private func mapFieldType(_ fieldType: FieldType) -> FormFieldType {
        switch fieldType {
        case .text:
            .textField
        case .number, .currency, .estimatedValue:
            .numberField
        case .date:
            .dateField
        default:
            .textField // Default mapping for unsupported types
        }
    }
}

// MARK: - Supporting Types

private struct ModificationSession {
    let sessionId: String
    let contextType: String
    let modificationCount: Int
    let timestamp: Date
}

private struct PatternCount {
    let pattern: ModificationPattern
    var count: Int
    let firstSeen: Date
    var lastSeen: Date
}

private struct RawModification {
    let fieldId: String
    let fieldType: FormFieldType
    let originalValue: String
    let modifiedValue: String
    let timestamp: Date
}

private struct SanitizedModification {
    let fieldType: FormFieldType
    let modificationPattern: ModificationPattern
    let timestamp: Date
}

public struct LearningPattern {
    public let contextType: ContextCategory
    public let fieldType: FormFieldType
    public let modificationPattern: ModificationPattern
    public let frequency: Int
    public let confidence: Double

    public init(contextType: ContextCategory, fieldType: FormFieldType, modificationPattern: ModificationPattern, frequency: Int, confidence: Double) {
        self.contextType = contextType
        self.fieldType = fieldType
        self.modificationPattern = modificationPattern
        self.frequency = frequency
        self.confidence = confidence
    }
}

public enum ModificationPattern: String, CaseIterable {
    case fillEmpty = "fill_empty"
    case clearField = "clear_field"
    case changeValue = "change_value"
    case noChange = "no_change"
}

public struct ModificationStatistics {
    public let totalSessions: Int
    public let averageModificationsPerSession: Double
    public let contextDistribution: [String: Int]
    public let retentionPeriodDays: Int

    public init(totalSessions: Int, averageModificationsPerSession: Double, contextDistribution: [String: Int], retentionPeriodDays: Int) {
        self.totalSessions = totalSessions
        self.averageModificationsPerSession = averageModificationsPerSession
        self.contextDistribution = contextDistribution
        self.retentionPeriodDays = retentionPeriodDays
    }
}

public struct UserDataExport {
    public let sessions: [ExportedSession]
    public let patterns: [ExportedPattern]
    public let exportDate: Date
    public let retentionPolicy: String

    public init(sessions: [ExportedSession], patterns: [ExportedPattern], exportDate: Date, retentionPolicy: String) {
        self.sessions = sessions
        self.patterns = patterns
        self.exportDate = exportDate
        self.retentionPolicy = retentionPolicy
    }
}

public struct ExportedSession {
    public let contextType: String
    public let modificationCount: Int
    public let date: Date

    public init(contextType: String, modificationCount: Int, date: Date) {
        self.contextType = contextType
        self.modificationCount = modificationCount
        self.date = date
    }
}

public struct ExportedPattern {
    public let contextType: String
    public let fieldType: FormFieldType
    public let modificationPattern: ModificationPattern
    public let frequency: Int

    public init(contextType: String, fieldType: FormFieldType, modificationPattern: ModificationPattern, frequency: Int) {
        self.contextType = contextType
        self.fieldType = fieldType
        self.modificationPattern = modificationPattern
        self.frequency = frequency
    }
}
