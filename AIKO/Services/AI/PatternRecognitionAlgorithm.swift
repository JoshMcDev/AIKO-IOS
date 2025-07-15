//
//  PatternRecognitionAlgorithm.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation
import Accelerate
import os.log

/// Advanced pattern recognition algorithm for user behavior analysis
actor PatternRecognitionAlgorithm {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.aiko", category: "PatternRecognition")
    
    /// Sequence detection window size
    private let sequenceWindowSize = 10
    
    /// Similarity threshold for pattern matching
    private let similarityThreshold: Double = 0.8
    
    /// Time-based pattern window (in seconds)
    private let timeWindowSize: TimeInterval = 3600 // 1 hour
    
    /// Pattern mining algorithms
    private let frequentPatternMiner = FrequentPatternMiner()
    private let sequenceAnalyzer = SequenceAnalyzer()
    private let temporalAnalyzer = TemporalPatternAnalyzer()
    private let valueClusterer = ValuePatternClusterer()
    
    // MARK: - Public Methods
    
    /// Analyze a single interaction for patterns
    func analyze(
        interaction: UserInteraction,
        historicalData: [UserInteraction]
    ) async -> [UserPattern] {
        
        var detectedPatterns: [UserPattern] = []
        
        // Analyze different pattern types in parallel
        async let formPatterns = analyzeFormFillingPatterns(interaction, historicalData)
        async let sequencePatterns = analyzeWorkflowSequences(interaction, historicalData)
        async let temporalPatterns = analyzeTemporalPatterns(interaction, historicalData)
        async let valuePatterns = analyzeFieldValuePatterns(interaction, historicalData)
        
        // Combine results
        detectedPatterns.append(contentsOf: await formPatterns)
        detectedPatterns.append(contentsOf: await sequencePatterns)
        detectedPatterns.append(contentsOf: await temporalPatterns)
        detectedPatterns.append(contentsOf: await valuePatterns)
        
        // Remove duplicates and low-confidence patterns
        return filterAndRankPatterns(detectedPatterns)
    }
    
    /// Analyze an entire session for macro patterns
    func analyzeSession(_ session: LearningSession) async -> [UserPattern] {
        var patterns: [UserPattern] = []
        
        // Extract navigation patterns
        if let navigationPattern = extractNavigationPattern(from: session) {
            patterns.append(navigationPattern)
        }
        
        // Extract workflow completion patterns
        if let workflowPattern = extractWorkflowPattern(from: session) {
            patterns.append(workflowPattern)
        }
        
        // Extract error correction patterns
        patterns.append(contentsOf: extractErrorCorrectionPatterns(from: session))
        
        return patterns
    }
    
    // MARK: - Form Filling Pattern Analysis
    
    private func analyzeFormFillingPatterns(
        _ interaction: UserInteraction,
        _ history: [UserInteraction]
    ) -> [UserPattern] {
        
        guard interaction.type == "form_interaction" else { return [] }
        
        var patterns: [UserPattern] = []
        
        // Look for repeated form completion sequences
        let formType = interaction.metadata["formType"] as? String ?? ""
        let similarInteractions = history.filter {
            $0.type == "form_interaction" &&
            $0.metadata["formType"] as? String == formType
        }
        
        // Mine frequent field sequences
        let fieldSequences = extractFieldSequences(from: similarInteractions)
        let frequentSequences = frequentPatternMiner.mine(sequences: fieldSequences, minSupport: 3)
        
        for sequence in frequentSequences {
            let pattern = UserPattern(
                id: UUID(),
                type: .formFilling,
                value: sequence.items,
                context: PatternContext(
                    formType: formType,
                    documentType: nil,
                    workflowPhase: nil,
                    timeOfDay: nil
                ),
                occurrences: sequence.support,
                confidence: calculateConfidence(support: sequence.support, total: similarInteractions.count),
                lastOccurrence: Date(),
                metadata: ["formType": formType]
            )
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    // MARK: - Workflow Sequence Analysis
    
    private func analyzeWorkflowSequences(
        _ interaction: UserInteraction,
        _ history: [UserInteraction]
    ) -> [UserPattern] {
        
        guard interaction.type == "workflow_step" else { return [] }
        
        var patterns: [UserPattern] = []
        
        // Get recent workflow steps
        let recentSteps = history
            .filter { $0.type == "workflow_step" }
            .prefix(sequenceWindowSize)
            .map { $0.metadata["stepName"] as? String ?? "" }
        
        // Analyze step sequences
        let sequences = sequenceAnalyzer.findRepeatingSequences(
            in: Array(recentSteps),
            minLength: 3,
            minOccurrences: 2
        )
        
        for seq in sequences {
            let pattern = UserPattern(
                id: UUID(),
                type: .workflowSequence,
                value: seq.sequence,
                context: PatternContext(
                    formType: nil,
                    documentType: interaction.metadata["documentType"] as? String,
                    workflowPhase: interaction.metadata["phase"] as? String,
                    timeOfDay: nil
                ),
                occurrences: seq.occurrences,
                confidence: Double(seq.occurrences) / Double(recentSteps.count),
                lastOccurrence: Date(),
                metadata: ["sequenceLength": seq.sequence.count]
            )
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    // MARK: - Temporal Pattern Analysis
    
    private func analyzeTemporalPatterns(
        _ interaction: UserInteraction,
        _ history: [UserInteraction]
    ) -> [UserPattern] {
        
        var patterns: [UserPattern] = []
        
        // Analyze time-of-day patterns
        let timeOfDay = TimeOfDay(from: interaction.timestamp)
        let similarTimeInteractions = history.filter {
            TimeOfDay(from: $0.timestamp) == timeOfDay
        }
        
        // Group by interaction type
        let groupedByType = Dictionary(grouping: similarTimeInteractions) { $0.type }
        
        for (interactionType, interactions) in groupedByType {
            if interactions.count >= 5 { // Minimum threshold
                let pattern = UserPattern(
                    id: UUID(),
                    type: .timeOfDay,
                    value: interactionType,
                    context: PatternContext(
                        formType: nil,
                        documentType: nil,
                        workflowPhase: nil,
                        timeOfDay: timeOfDay
                    ),
                    occurrences: interactions.count,
                    confidence: temporalAnalyzer.calculateTemporalConfidence(
                        occurrences: interactions.count,
                        timeWindow: timeWindowSize,
                        totalHistory: history.count
                    ),
                    lastOccurrence: Date(),
                    metadata: ["timeOfDay": timeOfDay.rawValue]
                )
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    // MARK: - Field Value Pattern Analysis
    
    private func analyzeFieldValuePatterns(
        _ interaction: UserInteraction,
        _ history: [UserInteraction]
    ) -> [UserPattern] {
        
        guard interaction.type == "field_input",
              let fieldName = interaction.metadata["fieldName"] as? String,
              let fieldValue = interaction.metadata["value"] as? String else {
            return []
        }
        
        var patterns: [UserPattern] = []
        
        // Find similar field inputs
        let similarFields = history.filter {
            $0.type == "field_input" &&
            $0.metadata["fieldName"] as? String == fieldName
        }
        
        // Cluster field values
        let values = similarFields.compactMap { $0.metadata["value"] as? String }
        let clusters = valueClusterer.cluster(values: values, similarity: similarityThreshold)
        
        for cluster in clusters where cluster.members.count >= 3 {
            let pattern = UserPattern(
                id: UUID(),
                type: .fieldValues,
                value: cluster.centroid,
                context: PatternContext(
                    formType: interaction.metadata["formType"] as? String,
                    documentType: nil,
                    workflowPhase: nil,
                    timeOfDay: nil
                ),
                occurrences: cluster.members.count,
                confidence: cluster.cohesion,
                lastOccurrence: Date(),
                metadata: [
                    "fieldName": fieldName,
                    "formType": interaction.metadata["formType"] as? String ?? ""
                ]
            )
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    // MARK: - Session Analysis
    
    private func extractNavigationPattern(from session: LearningSession) -> UserPattern? {
        let navigationSteps = session.interactions
            .filter { $0.type == "navigation" }
            .compactMap { $0.metadata["destination"] as? String }
        
        guard navigationSteps.count >= 3 else { return nil }
        
        // Check if this is a repeated navigation path
        let pathHash = navigationSteps.joined(separator: "->")
        
        return UserPattern(
            id: UUID(),
            type: .navigationPath,
            value: navigationSteps,
            context: PatternContext(
                formType: nil,
                documentType: nil,
                workflowPhase: session.contextType,
                timeOfDay: TimeOfDay(from: session.startTime)
            ),
            occurrences: 1,
            confidence: 0.5, // Initial confidence
            lastOccurrence: Date(),
            metadata: ["pathLength": navigationSteps.count]
        )
    }
    
    private func extractWorkflowPattern(from session: LearningSession) -> UserPattern? {
        let workflowSteps = session.interactions
            .filter { $0.type == "workflow_step" }
            .compactMap { interaction -> (String, TimeInterval)? in
                guard let stepName = interaction.metadata["stepName"] as? String else { return nil }
                return (stepName, interaction.timestamp.timeIntervalSince(session.startTime))
            }
        
        guard workflowSteps.count >= 2 else { return nil }
        
        return UserPattern(
            id: UUID(),
            type: .workflowSequence,
            value: workflowSteps.map { $0.0 },
            context: PatternContext(
                formType: nil,
                documentType: session.contextType,
                workflowPhase: nil,
                timeOfDay: nil
            ),
            occurrences: 1,
            confidence: 0.6,
            lastOccurrence: Date(),
            metadata: [
                "totalDuration": session.interactions.last?.timestamp.timeIntervalSince(session.startTime) ?? 0
            ]
        )
    }
    
    private func extractErrorCorrectionPatterns(from session: LearningSession) -> [UserPattern] {
        var patterns: [UserPattern] = []
        
        // Find error-correction pairs
        for i in 0..<session.interactions.count - 1 {
            let current = session.interactions[i]
            let next = session.interactions[i + 1]
            
            if current.type == "error" && next.type == "correction" {
                let errorType = current.metadata["errorType"] as? String ?? "unknown"
                let correctionType = next.metadata["correctionType"] as? String ?? "unknown"
                
                let pattern = UserPattern(
                    id: UUID(),
                    type: .errorCorrection,
                    value: ["error": errorType, "correction": correctionType],
                    context: PatternContext(
                        formType: current.metadata["formType"] as? String,
                        documentType: nil,
                        workflowPhase: nil,
                        timeOfDay: nil
                    ),
                    occurrences: 1,
                    confidence: 0.7,
                    lastOccurrence: Date(),
                    metadata: [
                        "errorType": errorType,
                        "correctionType": correctionType
                    ]
                )
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    // MARK: - Helper Methods
    
    private func extractFieldSequences(from interactions: [UserInteraction]) -> [[String]] {
        var sequences: [[String]] = []
        var currentSequence: [String] = []
        var lastTimestamp: Date?
        
        for interaction in interactions.sorted(by: { $0.timestamp < $1.timestamp }) {
            if let fieldName = interaction.metadata["fieldName"] as? String {
                if let last = lastTimestamp,
                   interaction.timestamp.timeIntervalSince(last) > 30 {
                    // New sequence if more than 30 seconds gap
                    if !currentSequence.isEmpty {
                        sequences.append(currentSequence)
                    }
                    currentSequence = [fieldName]
                } else {
                    currentSequence.append(fieldName)
                }
                lastTimestamp = interaction.timestamp
            }
        }
        
        if !currentSequence.isEmpty {
            sequences.append(currentSequence)
        }
        
        return sequences
    }
    
    private func calculateConfidence(support: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        
        let frequency = Double(support) / Double(total)
        let recency = 1.0 // TODO: Implement recency calculation
        let consistency = 1.0 // TODO: Implement consistency calculation
        
        // Weighted confidence score
        return (frequency * 0.5) + (recency * 0.3) + (consistency * 0.2)
    }
    
    private func filterAndRankPatterns(_ patterns: [UserPattern]) -> [UserPattern] {
        // Remove duplicates
        var uniquePatterns: [UserPattern] = []
        var seenIds = Set<UUID>()
        
        for pattern in patterns {
            if !seenIds.contains(pattern.id) {
                seenIds.insert(pattern.id)
                uniquePatterns.append(pattern)
            }
        }
        
        // Filter by minimum confidence
        let filtered = uniquePatterns.filter { $0.confidence >= 0.5 }
        
        // Sort by confidence and occurrences
        return filtered.sorted {
            if $0.confidence == $1.confidence {
                return $0.occurrences > $1.occurrences
            }
            return $0.confidence > $1.confidence
        }
    }
}

// MARK: - Supporting Algorithms

struct FrequentPatternMiner {
    func mine(sequences: [[String]], minSupport: Int) -> [FrequentSequence] {
        var frequentSequences: [FrequentSequence] = []
        var candidateSequences: [[String]: Int] = [:]
        
        // Count occurrences of subsequences
        for sequence in sequences {
            for length in 2...min(sequence.count, 5) {
                for i in 0...(sequence.count - length) {
                    let subsequence = Array(sequence[i..<i+length])
                    let key = subsequence.joined(separator: ",")
                    candidateSequences[key, default: 0] += 1
                }
            }
        }
        
        // Filter by minimum support
        for (key, support) in candidateSequences where support >= minSupport {
            let items = key.split(separator: ",").map(String.init)
            frequentSequences.append(FrequentSequence(items: items, support: support))
        }
        
        return frequentSequences
    }
}

struct SequenceAnalyzer {
    func findRepeatingSequences(
        in data: [String],
        minLength: Int,
        minOccurrences: Int
    ) -> [RepeatingSequence] {
        
        var sequences: [RepeatingSequence] = []
        var seen: Set<String> = []
        
        for length in minLength...min(data.count / 2, 10) {
            for i in 0...(data.count - length) {
                let sequence = Array(data[i..<i+length])
                let key = sequence.joined(separator: ",")
                
                if seen.contains(key) { continue }
                
                // Count occurrences
                var occurrences = 0
                for j in 0...(data.count - length) {
                    let candidate = Array(data[j..<j+length])
                    if candidate == sequence {
                        occurrences += 1
                    }
                }
                
                if occurrences >= minOccurrences {
                    sequences.append(RepeatingSequence(
                        sequence: sequence,
                        occurrences: occurrences
                    ))
                    seen.insert(key)
                }
            }
        }
        
        return sequences
    }
}

struct TemporalPatternAnalyzer {
    func calculateTemporalConfidence(
        occurrences: Int,
        timeWindow: TimeInterval,
        totalHistory: Int
    ) -> Double {
        
        // Base confidence from occurrence frequency
        let frequencyScore = min(Double(occurrences) / 10.0, 1.0)
        
        // Temporal consistency score
        let consistencyScore = 0.8 // TODO: Calculate actual consistency
        
        // Combined score
        return (frequencyScore * 0.6) + (consistencyScore * 0.4)
    }
}

struct ValuePatternClusterer {
    func cluster(values: [String], similarity: Double) -> [ValueCluster] {
        var clusters: [ValueCluster] = []
        
        for value in values {
            var assigned = false
            
            for i in 0..<clusters.count {
                if calculateSimilarity(value, clusters[i].centroid) >= similarity {
                    clusters[i].members.append(value)
                    clusters[i].updateCentroid()
                    assigned = true
                    break
                }
            }
            
            if !assigned {
                clusters.append(ValueCluster(centroid: value, members: [value]))
            }
        }
        
        // Calculate cohesion for each cluster
        for i in 0..<clusters.count {
            clusters[i].calculateCohesion()
        }
        
        return clusters
    }
    
    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        // Simple Jaccard similarity for now
        let set1 = Set(s1.lowercased().split(separator: " "))
        let set2 = Set(s2.lowercased().split(separator: " "))
        
        guard !set1.isEmpty || !set2.isEmpty else { return 1.0 }
        
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        
        return Double(intersection) / Double(union)
    }
}

// MARK: - Data Structures

struct FrequentSequence {
    let items: [String]
    let support: Int
}

struct RepeatingSequence {
    let sequence: [String]
    let occurrences: Int
}

struct ValueCluster {
    var centroid: String
    var members: [String]
    var cohesion: Double = 0.0
    
    mutating func updateCentroid() {
        // For strings, use the most common value as centroid
        let counts = members.reduce(into: [:]) { counts, member in
            counts[member, default: 0] += 1
        }
        
        if let mostCommon = counts.max(by: { $0.value < $1.value }) {
            centroid = mostCommon.key
        }
    }
    
    mutating func calculateCohesion() {
        guard members.count > 1 else {
            cohesion = 1.0
            return
        }
        
        var totalSimilarity = 0.0
        var comparisons = 0
        
        for i in 0..<members.count {
            for j in (i+1)..<members.count {
                totalSimilarity += calculateSimilarity(members[i], members[j])
                comparisons += 1
            }
        }
        
        cohesion = comparisons > 0 ? totalSimilarity / Double(comparisons) : 0.0
    }
    
    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        let set1 = Set(s1.lowercased().split(separator: " "))
        let set2 = Set(s2.lowercased().split(separator: " "))
        
        guard !set1.isEmpty || !set2.isEmpty else { return 1.0 }
        
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        
        return Double(intersection) / Double(union)
    }
}