import AppCore
import Foundation
import SwiftData

// MARK: - User Pattern Learning Module

/// Tracks and learns from user behavior to improve future interactions
public class UserPatternLearner {
    // MARK: - Types

    public struct UserPattern: Codable, Identifiable {
        public var id = UUID()
        public let patternType: PatternType
        public let field: String
        public let value: String
        public let context: PatternContext
        public let occurrences: Int
        public let confidence: Double
        public let lastSeen: Date
        public let metadata: [String: String]

        public enum PatternType: String, Codable {
            case defaultValue = "default_value"
            case frequentChoice = "frequent_choice"
            case workflow
            case documentType = "document_type"
            case vendorPreference = "vendor_preference"
            case approvalChain = "approval_chain"
        }
    }

    public struct PatternContext: Codable {
        public let userId: String
        public let organizationUnit: String?
        public let acquisitionType: AcquisitionType?
        public let valueRange: String?
        public let timeOfDay: String?
        public let dayOfWeek: String?
    }

    public struct LearningInsight {
        public let field: String
        public let suggestedValue: String
        public let confidence: Double
        public let reasoning: String
        public let alternativeValues: [(value: String, confidence: Double)]
    }

    // MARK: - Properties

    private var patterns: [UserPattern] = []
    private let minOccurrencesForPattern = 3
    private let confidenceThreshold = 0.65
    private let patternDecayDays = 90

    // MARK: - Public Methods

    /// Learn from a user interaction
    public func learn(from interaction: PatternUserInteraction) async {
        // Extract patterns from the interaction
        let extractedPatterns = extractPatterns(from: interaction)

        // Update existing patterns or create new ones
        for pattern in extractedPatterns {
            await updatePattern(pattern)
        }

        // Decay old patterns
        await decayOldPatterns()

        // Persist patterns
        await persistPatterns()
    }

    /// Get insights for a specific field based on learned patterns
    public func getInsights(for field: String, context: PatternContext) async -> LearningInsight? {
        // Find relevant patterns
        let relevantPatterns = patterns.filter { pattern in
            pattern.field == field &&
                isContextSimilar(pattern.context, context) &&
                pattern.confidence >= confidenceThreshold
        }

        guard !relevantPatterns.isEmpty else { return nil }

        // Sort by relevance (confidence * recency factor)
        let sortedPatterns = relevantPatterns.sorted { pattern1, pattern2 in
            let recency1 = recencyFactor(for: pattern1.lastSeen)
            let recency2 = recencyFactor(for: pattern2.lastSeen)
            return (pattern1.confidence * recency1) > (pattern2.confidence * recency2)
        }

        // Build insight
        let topPattern = sortedPatterns[0]
        let alternatives = Array(sortedPatterns.dropFirst().prefix(3)).map {
            ($0.value, $0.confidence * recencyFactor(for: $0.lastSeen))
        }

        return LearningInsight(
            field: field,
            suggestedValue: topPattern.value,
            confidence: topPattern.confidence * recencyFactor(for: topPattern.lastSeen),
            reasoning: generateReasoning(for: topPattern),
            alternativeValues: alternatives
        )
    }

    /// Get workflow patterns for a user
    public func getWorkflowPatterns(for userId: String) async -> [WorkflowPattern] {
        let userPatterns = patterns.filter {
            $0.context.userId == userId &&
                $0.patternType == .workflow
        }

        return analyzeWorkflowPatterns(userPatterns)
    }

    /// Get smart defaults for a form
    public func getSmartDefaults(for formType: DocumentType, context: PatternContext) async -> [String: String] {
        var defaults: [String: String] = [:]

        // Get all fields typically used for this form type
        let formFields = getFieldsForFormType(formType)

        // Get insights for each field
        for field in formFields {
            if let insight = await getInsights(for: field, context: context),
               insight.confidence >= 0.7
            {
                defaults[field] = insight.suggestedValue
            }
        }

        return defaults
    }

    /// Analyze acquisition patterns for optimization
    public func analyzeAcquisitionPatterns() async -> AcquisitionAnalysis {
        let vendorPatterns = patterns.filter { $0.patternType == .vendorPreference }
        let workflowPatterns = patterns.filter { $0.patternType == .workflow }
        let valuePatterns = patterns.filter { $0.patternType == .defaultValue }

        return AcquisitionAnalysis(
            preferredVendors: extractPreferredVendors(from: vendorPatterns),
            commonWorkflows: extractCommonWorkflows(from: workflowPatterns),
            typicalValues: extractTypicalValues(from: valuePatterns),
            efficiencyMetrics: calculateEfficiencyMetrics()
        )
    }

    // MARK: - Private Methods

    private func extractPatterns(from interaction: PatternUserInteraction) -> [UserPattern] {
        var extractedPatterns: [UserPattern] = []

        // Extract value patterns
        for (field, value) in interaction.fieldValues {
            let pattern = UserPattern(
                patternType: determinePatternType(field: field, value: value),
                field: field,
                value: value,
                context: interaction.context,
                occurrences: 1,
                confidence: calculateInitialConfidence(interaction),
                lastSeen: Date(),
                metadata: extractMetadata(from: interaction, field: field)
            )
            extractedPatterns.append(pattern)
        }

        // Extract workflow patterns
        if let workflow = extractWorkflowPattern(from: interaction) {
            extractedPatterns.append(workflow)
        }

        return extractedPatterns
    }

    private func updatePattern(_ newPattern: UserPattern) async {
        if let existingIndex = patterns.firstIndex(where: {
            $0.field == newPattern.field &&
                $0.value == newPattern.value &&
                $0.context.userId == newPattern.context.userId
        }) {
            // Update existing pattern
            let updated = patterns[existingIndex]
            patterns[existingIndex] = UserPattern(
                patternType: updated.patternType,
                field: updated.field,
                value: updated.value,
                context: updated.context,
                occurrences: updated.occurrences + 1,
                confidence: recalculateConfidence(
                    currentConfidence: updated.confidence,
                    occurrences: updated.occurrences + 1
                ),
                lastSeen: Date(),
                metadata: mergeMetadata(updated.metadata, newPattern.metadata)
            )
        } else {
            // Add new pattern
            patterns.append(newPattern)
        }
    }

    private func decayOldPatterns() async {
        guard let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -patternDecayDays,
            to: Date()
        ) else { return }

        patterns = patterns.compactMap { pattern in
            if pattern.lastSeen < cutoffDate {
                // Decay confidence for old patterns
                let decayedConfidence = pattern.confidence * 0.9
                if decayedConfidence < 0.3 {
                    return nil // Remove patterns with very low confidence
                }

                return UserPattern(
                    patternType: pattern.patternType,
                    field: pattern.field,
                    value: pattern.value,
                    context: pattern.context,
                    occurrences: pattern.occurrences,
                    confidence: decayedConfidence,
                    lastSeen: pattern.lastSeen,
                    metadata: pattern.metadata
                )
            }
            return pattern
        }
    }

    private func isContextSimilar(_ context1: PatternContext, _ context2: PatternContext) -> Bool {
        // Same user is most important
        guard context1.userId == context2.userId else { return false }

        // Check other context factors
        var similarity = 1.0

        if let org1 = context1.organizationUnit, let org2 = context2.organizationUnit {
            similarity *= (org1 == org2) ? 1.0 : 0.8
        }

        if let type1 = context1.acquisitionType, let type2 = context2.acquisitionType {
            similarity *= (type1 == type2) ? 1.0 : 0.7
        }

        return similarity >= 0.7
    }

    private func recencyFactor(for date: Date) -> Double {
        let daysSince = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(0.5, 1.0 - (Double(daysSince) / Double(patternDecayDays)))
    }

    private func generateReasoning(for pattern: UserPattern) -> String {
        let timeAgo = formatTimeAgo(pattern.lastSeen)

        switch pattern.patternType {
        case .defaultValue:
            return "You've used '\(pattern.value)' \(pattern.occurrences) times \(timeAgo)"
        case .frequentChoice:
            return "This is your most common choice (\(Int(pattern.confidence * 100))% of the time)"
        case .workflow:
            return "Part of your typical workflow"
        case .documentType:
            return "Standard for \(pattern.metadata["documentType"] ?? "this document type")"
        case .vendorPreference:
            return "Preferred vendor based on \(pattern.occurrences) previous selections"
        case .approvalChain:
            return "Standard approval chain for your organization"
        }
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "today" } else if days == 1 { return "yesterday" } else if days < 7 { return "this week" } else if days < 30 { return "in the last month" } else { return "in the last \(days / 30) months" }
    }

    private func determinePatternType(field: String, value _: String) -> UserPattern.PatternType {
        // Logic to determine pattern type based on field
        if field.contains("vendor") { return .vendorPreference }
        if field.contains("approval") { return .approvalChain }
        if field.contains("workflow") { return .workflow }
        return .defaultValue
    }

    private func calculateInitialConfidence(_ interaction: PatternUserInteraction) -> Double {
        // Base confidence on various factors
        var confidence = 0.5

        // Increase if user didn't change the suggested value
        if interaction.acceptedSuggestion { confidence += 0.2 }

        // Increase if interaction was completed quickly
        if interaction.completionTime < 60 { confidence += 0.1 }

        // Increase if no errors occurred
        if interaction.errorCount == 0 { confidence += 0.2 }

        return min(1.0, confidence)
    }

    private func recalculateConfidence(currentConfidence: Double, occurrences: Int) -> Double {
        // Increase confidence with more occurrences, but with diminishing returns
        let occurrenceFactor = Double(occurrences) / (Double(occurrences) + 10.0)
        return currentConfidence * 0.7 + occurrenceFactor * 0.3
    }

    private func extractMetadata(from interaction: PatternUserInteraction, field _: String) -> [String: String] {
        var metadata: [String: String] = [:]

        metadata["source"] = interaction.source.rawValue
        metadata["completionTime"] = "\(interaction.completionTime)"

        if let docType = interaction.documentType {
            metadata["documentType"] = docType.rawValue
        }

        return metadata
    }

    private func mergeMetadata(_ existing: [String: String], _ new: [String: String]) -> [String: String] {
        var merged = existing
        for (key, value) in new {
            merged[key] = value
        }
        return merged
    }

    private func extractWorkflowPattern(from interaction: PatternUserInteraction) -> UserPattern? {
        guard let workflow = interaction.workflowSteps, !workflow.isEmpty else { return nil }

        let workflowString = workflow.joined(separator: " → ")

        return UserPattern(
            patternType: .workflow,
            field: "workflow_sequence",
            value: workflowString,
            context: interaction.context,
            occurrences: 1,
            confidence: 0.6,
            lastSeen: Date(),
            metadata: ["stepCount": "\(workflow.count)"]
        )
    }

    private func getFieldsForFormType(_ formType: DocumentType) -> [String] {
        // Return typical fields for each form type
        switch formType {
        case .requestForQuote:
            ["vendor", "deliveryDate", "location", "justification", "approver"]
        case .requestForProposal:
            ["requirements", "evaluationCriteria", "submissionDeadline", "pointOfContact"]
        case .contractScaffold:
            ["contractType", "performancePeriod", "deliverables", "paymentTerms"]
        default:
            ["description", "requiredDate", "approver"]
        }
    }

    private func analyzeWorkflowPatterns(_ patterns: [UserPattern]) -> [WorkflowPattern] {
        // Group patterns by workflow sequence
        var workflowGroups: [String: [UserPattern]] = [:]

        for pattern in patterns {
            workflowGroups[pattern.value, default: []].append(pattern)
        }

        // Convert to WorkflowPattern objects
        return workflowGroups.compactMap { workflow, patterns in
            guard !patterns.isEmpty else { return nil }

            let totalOccurrences = patterns.reduce(0) { $0 + $1.occurrences }
            let avgConfidence = patterns.reduce(0.0) { $0 + $1.confidence } / Double(patterns.count)

            return WorkflowPattern(
                steps: workflow.split(separator: " → ").map(String.init),
                occurrences: totalOccurrences,
                confidence: avgConfidence,
                averageCompletionTime: extractAverageTime(from: patterns)
            )
        }
    }

    private func extractAverageTime(from patterns: [UserPattern]) -> TimeInterval {
        let times = patterns.compactMap { pattern in
            Double(pattern.metadata["completionTime"] ?? "0")
        }
        guard !times.isEmpty else { return 0 }
        return times.reduce(0, +) / Double(times.count)
    }

    private func extractPreferredVendors(from patterns: [UserPattern]) -> [PreferredVendor] {
        var vendorStats: [String: (count: Int, confidence: Double)] = [:]

        for pattern in patterns {
            let current = vendorStats[pattern.value] ?? (0, 0.0)
            vendorStats[pattern.value] = (
                count: current.count + pattern.occurrences,
                confidence: max(current.confidence, pattern.confidence)
            )
        }

        return vendorStats.map { vendor, stats in
            PreferredVendor(
                name: vendor,
                selectionCount: stats.count,
                confidence: stats.confidence
            )
        }.sorted { $0.selectionCount > $1.selectionCount }
    }

    private func extractCommonWorkflows(from patterns: [UserPattern]) -> [String] {
        patterns
            .sorted { $0.occurrences > $1.occurrences }
            .prefix(5)
            .map(\.value)
    }

    private func extractTypicalValues(from patterns: [UserPattern]) -> [String: String] {
        var typicalValues: [String: String] = [:]

        // Group by field
        let fieldGroups = Dictionary(grouping: patterns) { $0.field }

        for (field, fieldPatterns) in fieldGroups {
            // Find most common value for this field
            if let mostCommon = fieldPatterns.max(by: { $0.occurrences < $1.occurrences }) {
                typicalValues[field] = mostCommon.value
            }
        }

        return typicalValues
    }

    private func calculateEfficiencyMetrics() -> EfficiencyMetrics {
        // Calculate various efficiency metrics
        let recentPatterns = patterns.filter {
            guard let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else { return false }
            return $0.lastSeen > thirtyDaysAgo
        }

        let avgCompletionTime = recentPatterns
            .compactMap { Double($0.metadata["completionTime"] ?? "0") }
            .reduce(0.0, +) / Double(max(1, recentPatterns.count))

        let reuseRate = Double(patterns.count(where: { $0.occurrences > 1 })) / Double(max(1, patterns.count))

        return EfficiencyMetrics(
            averageCompletionTime: avgCompletionTime,
            patternReuseRate: reuseRate,
            confidenceGrowth: calculateConfidenceGrowth()
        )
    }

    private func calculateConfidenceGrowth() -> Double {
        let sortedByDate = patterns.sorted { $0.lastSeen < $1.lastSeen }
        guard sortedByDate.count >= 2 else { return 0.0 }

        let earliestAvg = sortedByDate.prefix(patterns.count / 3)
            .map(\.confidence)
            .reduce(0.0, +) / Double(patterns.count / 3)

        let latestAvg = sortedByDate.suffix(patterns.count / 3)
            .map(\.confidence)
            .reduce(0.0, +) / Double(patterns.count / 3)

        return latestAvg - earliestAvg
    }

    private func persistPatterns() async {
        // Save patterns to persistent storage
        // This would integrate with SwiftData or Core Data
    }
}

// MARK: - Supporting Types

public struct PatternUserInteraction {
    public let userId: String
    public let context: UserPatternLearner.PatternContext
    public let fieldValues: [String: String]
    public let documentType: DocumentType?
    public let source: InteractionSource
    public let acceptedSuggestion: Bool
    public let completionTime: TimeInterval
    public let errorCount: Int
    public let workflowSteps: [String]?

    public enum InteractionSource: String {
        case manualEntry = "manual"
        case documentUpload = "upload"
        case apiIntegration = "api"
        case emailParsing = "email"
    }
}

public struct WorkflowPattern {
    public let steps: [String]
    public let occurrences: Int
    public let confidence: Double
    public let averageCompletionTime: TimeInterval
}

public struct PreferredVendor {
    public let name: String
    public let selectionCount: Int
    public let confidence: Double
}

public struct AcquisitionAnalysis {
    public let preferredVendors: [PreferredVendor]
    public let commonWorkflows: [String]
    public let typicalValues: [String: String]
    public let efficiencyMetrics: EfficiencyMetrics
}

public struct EfficiencyMetrics {
    public let averageCompletionTime: TimeInterval
    public let patternReuseRate: Double
    public let confidenceGrowth: Double
}
