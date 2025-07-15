import Foundation
import CoreML
import CreateML

// MARK: - User Pattern Learning Engine

/// Advanced pattern learning engine that uses ML to predict user preferences
/// and reduce the number of questions needed during data collection
public class UserPatternLearningEngine {
    
    // MARK: - Properties
    
    private var patternHistory: [RequirementField: [PatternData]] = [:]
    private var userDefaults: [RequirementField: FieldDefault] = [:]
    private var contextualPatterns: [ContextualPattern] = []
    private var fieldRelationships: [FieldRelationship] = []
    private var temporalPatterns: [TemporalPattern] = []
    private var confidenceThresholds: [RequirementField: Float] = [:]
    
    private let persistenceKey = "UserPatternLearningEngine.patterns"
    private let contextPersistenceKey = "UserPatternLearningEngine.contextual"
    private let relationshipPersistenceKey = "UserPatternLearningEngine.relationships"
    
    // ML Model properties
    private var predictionModel: MLModel?
    private let modelUpdateQueue = DispatchQueue(label: "com.aiko.pattern.learning", qos: .background)
    
    // Learning configuration
    private let minPatternsForLearning = 5
    private let patternHistoryLimit = 500
    private let confidenceDecayFactor: Float = 0.95
    private let recencyWeight: Float = 0.7
    
    public init() {
        loadPatterns()
        loadContextualPatterns()
        loadFieldRelationships()
        initializeConfidenceThresholds()
    }
    
    // MARK: - Public Methods
    
    public func learn(from interaction: APEUserInteraction) async {
        // Store pattern data with enhanced context
        var patterns = patternHistory[interaction.field] ?? []
        let patternData = PatternData(
            value: String(describing: interaction.finalValue),
            timestamp: Date(),
            acceptedSuggestion: interaction.acceptedSuggestion,
            timeToRespond: interaction.timeToRespond,
            hadDocumentContext: interaction.documentContext,
            sessionContext: captureSessionContext(for: interaction),
            confidence: calculatePatternConfidence(interaction)
        )
        patterns.append(patternData)
        
        // Keep only recent patterns with intelligent pruning
        patterns = intelligentlyPrunePatterns(patterns)
        patternHistory[interaction.field] = patterns
        
        // Learn multiple aspects from the interaction
        await performComprehensiveLearning(from: interaction, with: patternData)
        
        // Update ML model if sufficient data
        if shouldUpdateModel(for: interaction.field) {
            let field = interaction.field
            modelUpdateQueue.async { [weak self] in
                self?.updatePredictionModel(for: field)
            }
        }
        
        // Persist all learned data
        saveAllPatterns()
    }
    
    /// Get intelligent default with confidence scoring and alternatives
    public func getDefault(for field: RequirementField) async -> FieldDefault? {
        // Try multiple prediction strategies
        let predictions = await gatherPredictions(for: field)
        
        // Combine predictions using ensemble approach
        let ensembleResult = combinePredicitions(predictions)
        
        // Apply confidence threshold
        guard ensembleResult.confidence >= getConfidenceThreshold(for: field) else {
            return nil
        }
        
        return ensembleResult
    }
    
    /// Get related fields that should be asked together
    public func getRelatedFields(for field: RequirementField) -> [RequirementField] {
        fieldRelationships
            .filter { $0.primaryField == field || $0.relatedField == field }
            .flatMap { [$0.primaryField, $0.relatedField] }
            .filter { $0 != field }
            .removingDuplicates()
    }
    
    /// Predict next best question based on current context
    public func predictNextQuestion(
        answered: Set<RequirementField>,
        remaining: Set<RequirementField>,
        context: ConversationContext
    ) -> RequirementField? {
        // Score each remaining field
        let scores = remaining.compactMap { field -> (field: RequirementField, score: Float)? in
            let score = calculateFieldPriority(
                field: field,
                answered: answered,
                context: context
            )
            return (field, score)
        }
        
        // Return highest scoring field
        return scores.max(by: { $0.score < $1.score })?.field
    }
    
    /// Get confidence level for a specific field prediction
    public func getConfidenceLevel(for field: RequirementField) -> Float {
        guard let patterns = patternHistory[field],
              patterns.count >= minPatternsForLearning else {
            return 0.0
        }
        
        // Calculate based on pattern consistency and recency
        let recentPatterns = Array(patterns.suffix(20))
        let consistency = calculatePatternConsistency(recentPatterns)
        let recency = calculateRecencyScore(recentPatterns)
        
        return consistency * 0.6 + recency * 0.4
    }
    
    /// Learn from batch interactions for improved pattern recognition
    public func learnFromBatch(_ interactions: [APEUserInteraction]) async {
        for interaction in interactions {
            await learn(from: interaction)
        }
        
        // Perform batch analysis
        analyzeCrossFieldPatterns(interactions)
        updateTemporalPatterns(interactions)
    }
    
    // MARK: - Private Learning Methods
    
    private func performComprehensiveLearning(
        from interaction: APEUserInteraction,
        with patternData: PatternData
    ) async {
        // Update basic defaults
        updateDefaults(for: interaction.field)
        
        // Learn contextual patterns
        learnContextualPattern(from: interaction, with: patternData)
        
        // Update field relationships
        updateFieldRelationships(from: interaction)
        
        // Learn temporal patterns
        learnTemporalPatterns(from: interaction)
        
        // Adjust confidence thresholds based on accuracy
        adjustConfidenceThreshold(for: interaction.field, wasAccepted: interaction.acceptedSuggestion)
    }
    
    private func updateDefaults(for field: RequirementField) {
        guard let patterns = patternHistory[field],
              patterns.count >= minPatternsForLearning else { return }
        
        // Use advanced analysis for default calculation
        let analysis = analyzePatterns(patterns)
        
        if let bestDefault = analysis.bestDefault {
            userDefaults[field] = bestDefault
        }
    }
    
    private func analyzePatterns(_ patterns: [PatternData]) -> PatternAnalysis {
        let recentPatterns = Array(patterns.suffix(30))
        
        // Group by value and calculate weighted counts
        let weightedCounts = calculateWeightedValueCounts(recentPatterns)
        
        // Find clusters of similar values
        let clusters = findValueClusters(recentPatterns)
        
        // Calculate confidence based on multiple factors
        let (bestValue, confidence) = determineBestValue(
            weightedCounts: weightedCounts,
            clusters: clusters,
            patterns: recentPatterns
        )
        
        let bestDefault = bestValue.map { value in
            FieldDefault(
                value: value,
                confidence: confidence,
                source: determineSource(patterns: recentPatterns)
            )
        }
        
        return PatternAnalysis(
            bestDefault: bestDefault,
            alternativeValues: clusters.map { $0.representative },
            confidence: confidence,
            patternType: identifyPatternType(patterns)
        )
    }
    
    private func calculateWeightedValueCounts(_ patterns: [PatternData]) -> [String: Float] {
        var weightedCounts: [String: Float] = [:]
        let now = Date()
        
        for pattern in patterns {
            // Calculate time-based weight
            let age = now.timeIntervalSince(pattern.timestamp)
            let ageInDays = age / 86400
            let timeWeight = exp(-ageInDays / 30) // Exponential decay over 30 days
            
            // Calculate confidence-based weight
            let confidenceWeight = pattern.confidence
            
            // Calculate acceptance weight
            let acceptanceWeight: Float = pattern.acceptedSuggestion ? 1.2 : 1.0
            
            // Combined weight
            let weight = Float(timeWeight) * confidenceWeight * acceptanceWeight
            
            weightedCounts[pattern.value, default: 0] += weight
        }
        
        return weightedCounts
    }
    
    // MARK: - ML Model Methods
    
    private func updatePredictionModel(for field: RequirementField) {
        guard let patterns = patternHistory[field],
              patterns.count >= 20 else { return }
        
        // Prepare training data
        let _ = prepareTrainingData(from: patterns)
        
        // Train or update model
        // In a real implementation, this would use CreateML or CoreML
        // For now, we'll use statistical methods
        
        print("[PatternLearning] Model updated for field: \(field.rawValue)")
    }
    
    private func gatherPredictions(for field: RequirementField) async -> [FieldDefault] {
        var predictions: [FieldDefault] = []
        
        // Historical pattern prediction
        if let historicalDefault = userDefaults[field] {
            predictions.append(historicalDefault)
        }
        
        // Contextual prediction
        if let contextualDefault = predictFromContext(field: field) {
            predictions.append(contextualDefault)
        }
        
        // Temporal prediction
        if let temporalDefault = predictFromTemporalPatterns(field: field) {
            predictions.append(temporalDefault)
        }
        
        // ML model prediction
        if let mlDefault = await predictFromMLModel(field: field) {
            predictions.append(mlDefault)
        }
        
        return predictions
    }
    
    private func combinePredicitions(_ predictions: [FieldDefault]) -> FieldDefault {
        guard !predictions.isEmpty else {
            return FieldDefault(value: "", confidence: 0, source: .systemDefault)
        }
        
        // If all predictions agree, high confidence
        let uniqueValues = Set(predictions.map { String(describing: $0.value) })
        if uniqueValues.count == 1 {
            let avgConfidence = predictions.map { $0.confidence }.reduce(0, +) / Float(predictions.count)
            return FieldDefault(
                value: predictions[0].value,
                confidence: min(avgConfidence * 1.2, 1.0), // Boost for agreement
                source: .userPattern
            )
        }
        
        // Otherwise, use weighted voting
        let weightedVotes = predictions.map { prediction in
            (value: prediction.value, weight: prediction.confidence)
        }
        
        // Find value with highest weighted support
        let valueScores = Dictionary(grouping: weightedVotes, by: { String(describing: $0.value) })
            .mapValues { group in
                group.map { $0.weight }.reduce(0, +)
            }
        
        if let best = valueScores.max(by: { $0.value < $1.value }) {
            let totalWeight = valueScores.values.reduce(0, +)
            let confidence = best.value / totalWeight
            
            return FieldDefault(
                value: best.key,
                confidence: confidence,
                source: .userPattern
            )
        }
        
        return predictions[0]
    }
    
    // MARK: - Persistence Methods
    
    private func loadPatterns() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let decoded = try? JSONDecoder().decode([String: [PatternData]].self, from: data) {
            // Convert string keys back to RequirementField
            for (key, value) in decoded {
                if let field = RequirementField(rawValue: key) {
                    patternHistory[field] = value
                }
            }
        }
    }
    
    private func loadContextualPatterns() {
        if let data = UserDefaults.standard.data(forKey: contextPersistenceKey),
           let decoded = try? JSONDecoder().decode([ContextualPattern].self, from: data) {
            contextualPatterns = decoded
        }
    }
    
    private func loadFieldRelationships() {
        if let data = UserDefaults.standard.data(forKey: relationshipPersistenceKey),
           let decoded = try? JSONDecoder().decode([FieldRelationship].self, from: data) {
            fieldRelationships = decoded
        }
    }
    
    private func saveAllPatterns() {
        savePatterns()
        saveContextualPatterns()
        saveFieldRelationships()
    }
    
    private func savePatterns() {
        // Convert RequirementField keys to strings for encoding
        let encodableHistory = Dictionary(uniqueKeysWithValues: 
            patternHistory.map { ($0.key.rawValue, $0.value) }
        )
        
        if let encoded = try? JSONEncoder().encode(encodableHistory) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
        }
    }
    
    private func saveContextualPatterns() {
        if let encoded = try? JSONEncoder().encode(contextualPatterns) {
            UserDefaults.standard.set(encoded, forKey: contextPersistenceKey)
        }
    }
    
    private func saveFieldRelationships() {
        if let encoded = try? JSONEncoder().encode(fieldRelationships) {
            UserDefaults.standard.set(encoded, forKey: relationshipPersistenceKey)
        }
    }
}

// MARK: - Supporting Types

private struct PatternData: Codable {
    let value: String
    let timestamp: Date
    let acceptedSuggestion: Bool
    let timeToRespond: TimeInterval
    let hadDocumentContext: Bool
    let sessionContext: SessionContext?
    let confidence: Float
}

private struct SessionContext: Codable {
    let acquisitionType: String
    let previousFields: [String]
    let timeOfDay: Int // Hour of day
    let dayOfWeek: Int
    let documentTypes: [String]
}

private struct ContextualPattern: Codable {
    let id: UUID
    let field: String // RequirementField raw value
    let context: PatternContext
    let predictedValue: String
    let occurrences: Int
    let accuracy: Float
    let lastSeen: Date
    
    init(id: UUID = UUID(), field: String, context: PatternContext, predictedValue: String, occurrences: Int, accuracy: Float, lastSeen: Date) {
        self.id = id
        self.field = field
        self.context = context
        self.predictedValue = predictedValue
        self.occurrences = occurrences
        self.accuracy = accuracy
        self.lastSeen = lastSeen
    }
}

private struct PatternContext: Codable {
    let precedingFields: [String]
    let acquisitionType: String?
    let hasDocuments: Bool
    let timeContext: TimeContext?
}

private struct TimeContext: Codable {
    let hourOfDay: Int?
    let dayOfWeek: Int?
    let isEndOfMonth: Bool
    let isEndOfQuarter: Bool
}

private struct FieldRelationship: Codable {
    let primaryField: RequirementField
    let relatedField: RequirementField
    let relationshipStrength: Float
    let relationshipType: RelationshipType
    
    enum RelationshipType: String, Codable {
        case dependent // One field depends on another
        case correlated // Fields tend to have related values
        case sequential // Fields are usually filled in sequence
        case exclusive // Fields are mutually exclusive
    }
    
    private enum CodingKeys: String, CodingKey {
        case primaryField, relatedField, relationshipStrength, relationshipType
    }
    
    init(primaryField: RequirementField, relatedField: RequirementField, relationshipStrength: Float, relationshipType: RelationshipType) {
        self.primaryField = primaryField
        self.relatedField = relatedField
        self.relationshipStrength = relationshipStrength
        self.relationshipType = relationshipType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let primaryRaw = try container.decode(String.self, forKey: .primaryField)
        let relatedRaw = try container.decode(String.self, forKey: .relatedField)
        
        guard let primary = RequirementField(rawValue: primaryRaw),
              let related = RequirementField(rawValue: relatedRaw) else {
            throw DecodingError.dataCorruptedError(forKey: .primaryField, in: container, debugDescription: "Invalid RequirementField")
        }
        
        self.primaryField = primary
        self.relatedField = related
        self.relationshipStrength = try container.decode(Float.self, forKey: .relationshipStrength)
        self.relationshipType = try container.decode(RelationshipType.self, forKey: .relationshipType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(primaryField.rawValue, forKey: .primaryField)
        try container.encode(relatedField.rawValue, forKey: .relatedField)
        try container.encode(relationshipStrength, forKey: .relationshipStrength)
        try container.encode(relationshipType, forKey: .relationshipType)
    }
}

private struct TemporalPattern: Codable {
    let field: String
    let timePattern: TimePattern
    let typicalValue: String
    let confidence: Float
    
    enum TimePattern: String, Codable {
        case endOfMonth
        case endOfQuarter
        case mondayMorning
        case fridayAfternoon
        case businessHours
        case afterHours
    }
}

private struct PatternAnalysis {
    let bestDefault: FieldDefault?
    let alternativeValues: [String]
    let confidence: Float
    let patternType: PatternType
    
    enum PatternType {
        case consistent // Same value repeatedly
        case periodic // Changes predictably
        case contextual // Depends on other factors
        case random // No clear pattern
    }
}

// MARK: - Helper Methods Implementation

extension UserPatternLearningEngine {
    
    private func initializeConfidenceThresholds() {
        // Set default confidence thresholds for each field
        for field in RequirementField.allCases {
            switch field {
            case .projectTitle, .description, .vendorName:
                confidenceThresholds[field] = 0.7 // Higher threshold for critical fields
            case .estimatedValue, .requiredDate:
                confidenceThresholds[field] = 0.8 // Very high threshold for financial/date fields
            case .technicalSpecs, .specialConditions:
                confidenceThresholds[field] = 0.6 // Lower threshold for variable fields
            default:
                confidenceThresholds[field] = 0.65 // Default threshold
            }
        }
    }
    
    private func captureSessionContext(for interaction: APEUserInteraction) -> SessionContext {
        let calendar = Calendar.current
        let now = Date()
        
        return SessionContext(
            acquisitionType: "supplies", // Would come from actual session
            previousFields: Array(patternHistory.keys.map { $0.rawValue }.prefix(5)),
            timeOfDay: calendar.component(.hour, from: now),
            dayOfWeek: calendar.component(.weekday, from: now),
            documentTypes: [] // Would come from actual documents
        )
    }
    
    private func calculatePatternConfidence(_ interaction: APEUserInteraction) -> Float {
        var confidence: Float = 0.5 // Base confidence
        
        // Boost for accepted suggestions
        if interaction.acceptedSuggestion {
            confidence += 0.2
        }
        
        // Boost for quick responses
        if interaction.timeToRespond < 2.0 {
            confidence += 0.1
        }
        
        // Boost for document context
        if interaction.documentContext {
            confidence += 0.2
        }
        
        return min(confidence, 1.0)
    }
    
    private func intelligentlyPrunePatterns(_ patterns: [PatternData]) -> [PatternData] {
        guard patterns.count > patternHistoryLimit else { return patterns }
        
        // Keep most recent patterns
        let recentCount = patternHistoryLimit / 2
        let recent = Array(patterns.suffix(recentCount))
        
        // Keep high-confidence patterns from older data
        let older = patterns.dropLast(recentCount)
        let highConfidenceOlder = older.filter { $0.confidence > 0.8 }
            .suffix(patternHistoryLimit / 4)
        
        // Keep accepted suggestions
        let acceptedOlder = older.filter { $0.acceptedSuggestion }
            .suffix(patternHistoryLimit / 4)
        
        return Array(highConfidenceOlder) + Array(acceptedOlder) + recent
    }
    
    private func shouldUpdateModel(for field: RequirementField) -> Bool {
        guard let patterns = patternHistory[field] else { return false }
        
        // Update model if we have enough new patterns
        let recentPatterns = patterns.filter { pattern in
            Date().timeIntervalSince(pattern.timestamp) < 86400 * 7 // Last 7 days
        }
        
        return recentPatterns.count >= 10
    }
    
    private func getConfidenceThreshold(for field: RequirementField) -> Float {
        confidenceThresholds[field] ?? 0.65
    }
    
    private func findValueClusters(_ patterns: [PatternData]) -> [ValueCluster] {
        // Group similar values together
        var clusters: [ValueCluster] = []
        
        let groupedValues = Dictionary(grouping: patterns, by: { $0.value })
        
        for (value, patterns) in groupedValues {
            let avgConfidence = patterns.map { $0.confidence }.reduce(0, +) / Float(patterns.count)
            let cluster = ValueCluster(
                representative: value,
                members: patterns,
                confidence: avgConfidence
            )
            clusters.append(cluster)
        }
        
        return clusters.sorted { $0.confidence > $1.confidence }
    }
    
    private func determineBestValue(
        weightedCounts: [String: Float],
        clusters: [ValueCluster],
        patterns: [PatternData]
    ) -> (String?, Float) {
        guard !weightedCounts.isEmpty else { return (nil, 0) }
        
        // Find value with highest weighted count
        let bestWeighted = weightedCounts.max(by: { $0.value < $1.value })
        
        // Find most confident cluster
        let bestCluster = clusters.first
        
        // Combine insights
        if let weighted = bestWeighted,
           let cluster = bestCluster,
           weighted.key == cluster.representative {
            // Strong agreement
            return (weighted.key, min(weighted.value * 1.2, 1.0))
        } else if let weighted = bestWeighted {
            return (weighted.key, weighted.value)
        } else if let cluster = bestCluster {
            return (cluster.representative, cluster.confidence)
        }
        
        return (nil, 0)
    }
    
    private func determineSource(patterns: [PatternData]) -> FieldDefault.DefaultSource {
        let hasDocumentContext = patterns.contains { $0.hadDocumentContext }
        let mostlyAccepted = patterns.filter { $0.acceptedSuggestion }.count > patterns.count / 2
        
        if hasDocumentContext {
            return .documentContext
        } else if mostlyAccepted {
            return .userPattern
        } else {
            return .historical
        }
    }
    
    private func identifyPatternType(_ patterns: [PatternData]) -> PatternAnalysis.PatternType {
        let uniqueValues = Set(patterns.map { $0.value })
        let valueCount = uniqueValues.count
        let patternCount = patterns.count
        
        if valueCount == 1 {
            return .consistent
        } else if Float(valueCount) / Float(patternCount) < 0.2 {
            return .periodic
        } else if Float(valueCount) / Float(patternCount) < 0.5 {
            return .contextual
        } else {
            return .random
        }
    }
    
    private func learnContextualPattern(from interaction: APEUserInteraction, with patternData: PatternData) {
        // Create contextual pattern
        let context = PatternContext(
            precedingFields: Array(patternHistory.keys.map { $0.rawValue }.suffix(3)),
            acquisitionType: "supplies", // Would come from session
            hasDocuments: interaction.documentContext,
            timeContext: captureTimeContext()
        )
        
        let contextualPattern = ContextualPattern(
            id: UUID(),
            field: interaction.field.rawValue,
            context: context,
            predictedValue: String(describing: interaction.finalValue),
            occurrences: 1,
            accuracy: interaction.acceptedSuggestion ? 1.0 : 0.0,
            lastSeen: Date()
        )
        
        contextualPatterns.append(contextualPattern)
        
        // Limit contextual patterns
        if contextualPatterns.count > 1000 {
            contextualPatterns = Array(contextualPatterns.suffix(800))
        }
    }
    
    private func captureTimeContext() -> TimeContext {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.hour, .weekday, .day, .month], from: now)
        
        return TimeContext(
            hourOfDay: components.hour,
            dayOfWeek: components.weekday,
            isEndOfMonth: components.day ?? 0 > 25,
            isEndOfQuarter: [3, 6, 9, 12].contains(components.month ?? 0) && (components.day ?? 0) > 20
        )
    }
    
    private func updateFieldRelationships(from interaction: APEUserInteraction) {
        // Look for fields that were filled before this one
        let recentFields = Array(patternHistory.keys.suffix(5))
        
        for recentField in recentFields {
            guard recentField != interaction.field else { continue }
            
            // Check if relationship exists
            if let existingIndex = fieldRelationships.firstIndex(where: {
                ($0.primaryField == recentField && $0.relatedField == interaction.field) ||
                ($0.primaryField == interaction.field && $0.relatedField == recentField)
            }) {
                // Update strength
                var relationship = fieldRelationships[existingIndex]
                relationship.relationshipStrength = min(relationship.relationshipStrength + 0.1, 1.0)
                fieldRelationships[existingIndex] = relationship
            } else {
                // Create new relationship
                let relationship = FieldRelationship(
                    primaryField: recentField,
                    relatedField: interaction.field,
                    relationshipStrength: 0.3,
                    relationshipType: .sequential
                )
                fieldRelationships.append(relationship)
            }
        }
    }
    
    private func learnTemporalPatterns(from interaction: APEUserInteraction) {
        let timeContext = captureTimeContext()
        let value = String(describing: interaction.finalValue)
        
        // Identify time pattern
        let pattern: TemporalPattern.TimePattern?
        if timeContext.isEndOfMonth {
            pattern = .endOfMonth
        } else if timeContext.isEndOfQuarter {
            pattern = .endOfQuarter
        } else if let hour = timeContext.hourOfDay {
            if hour >= 9 && hour <= 17 {
                pattern = .businessHours
            } else {
                pattern = .afterHours
            }
        } else {
            pattern = nil
        }
        
        if let pattern = pattern {
            let temporal = TemporalPattern(
                field: interaction.field.rawValue,
                timePattern: pattern,
                typicalValue: value,
                confidence: 0.5
            )
            temporalPatterns.append(temporal)
        }
    }
    
    private func adjustConfidenceThreshold(for field: RequirementField, wasAccepted: Bool) {
        let current = confidenceThresholds[field] ?? 0.65
        
        if wasAccepted {
            // Lower threshold slightly if suggestion was accepted
            confidenceThresholds[field] = max(current - 0.02, 0.5)
        } else {
            // Raise threshold if suggestion was rejected
            confidenceThresholds[field] = min(current + 0.05, 0.95)
        }
    }
    
    private func prepareTrainingData(from patterns: [PatternData]) -> [(features: [String: Any], label: String)] {
        // Convert patterns to ML training data
        return patterns.map { pattern in
            let features: [String: Any] = [
                "timeOfDay": pattern.sessionContext?.timeOfDay ?? 0,
                "dayOfWeek": pattern.sessionContext?.dayOfWeek ?? 0,
                "hasDocuments": pattern.hadDocumentContext,
                "responseTime": pattern.timeToRespond,
                "confidence": pattern.confidence
            ]
            return (features, pattern.value)
        }
    }
    
    private func predictFromContext(field: RequirementField) -> FieldDefault? {
        // Find contextual patterns matching current context
        let _ = captureTimeContext()
        
        let matchingPatterns = contextualPatterns.filter { pattern in
            pattern.field == field.rawValue &&
            pattern.context.hasDocuments == false // Simplified matching
        }
        
        guard !matchingPatterns.isEmpty else { return nil }
        
        // Find most accurate pattern
        let best = matchingPatterns.max(by: { $0.accuracy < $1.accuracy })
        
        return best.map { pattern in
            FieldDefault(
                value: pattern.predictedValue,
                confidence: pattern.accuracy,
                source: .documentContext
            )
        }
    }
    
    private func predictFromTemporalPatterns(field: RequirementField) -> FieldDefault? {
        let currentTime = captureTimeContext()
        
        // Find matching temporal patterns
        let matching = temporalPatterns.filter { temporal in
            temporal.field == field.rawValue &&
            matchesCurrentTime(temporal.timePattern, currentTime)
        }
        
        guard !matching.isEmpty else { return nil }
        
        // Average confidence of matching patterns
        let avgConfidence = matching.map { $0.confidence }.reduce(0, +) / Float(matching.count)
        
        return FieldDefault(
            value: matching[0].typicalValue,
            confidence: avgConfidence,
            source: .userPattern
        )
    }
    
    private func matchesCurrentTime(_ pattern: TemporalPattern.TimePattern, _ context: TimeContext) -> Bool {
        switch pattern {
        case .endOfMonth:
            return context.isEndOfMonth
        case .endOfQuarter:
            return context.isEndOfQuarter
        case .businessHours:
            return (context.hourOfDay ?? 0) >= 9 && (context.hourOfDay ?? 0) <= 17
        case .afterHours:
            return (context.hourOfDay ?? 0) < 9 || (context.hourOfDay ?? 0) > 17
        case .mondayMorning:
            return context.dayOfWeek == 2 && (context.hourOfDay ?? 0) < 12
        case .fridayAfternoon:
            return context.dayOfWeek == 6 && (context.hourOfDay ?? 0) >= 12
        }
    }
    
    private func predictFromMLModel(field: RequirementField) async -> FieldDefault? {
        // Placeholder for ML model prediction
        // In real implementation, this would use the trained CoreML model
        return nil
    }
    
    private func calculateFieldPriority(
        field: RequirementField,
        answered: Set<RequirementField>,
        context: ConversationContext
    ) -> Float {
        var score: Float = 0.5 // Base score
        
        // Boost for fields with dependencies already answered
        let dependencies = getRelatedFields(for: field)
        let answeredDependencies = dependencies.filter { answered.contains($0) }
        score += Float(answeredDependencies.count) * 0.1
        
        // Boost for fields with high confidence defaults available
        let confidence = getConfidenceLevel(for: field)
        if confidence > 0.8 {
            score += 0.2
        }
        
        // Boost for critical fields
        switch field {
        case .projectTitle, .estimatedValue, .requiredDate:
            score += 0.3
        case .vendorName, .vendorUEI:
            score += 0.2
        default:
            break
        }
        
        return min(score, 1.0)
    }
    
    private func calculatePatternConsistency(_ patterns: [PatternData]) -> Float {
        guard !patterns.isEmpty else { return 0 }
        
        let values = patterns.map { $0.value }
        let uniqueValues = Set(values)
        
        return 1.0 - (Float(uniqueValues.count - 1) / Float(patterns.count))
    }
    
    private func calculateRecencyScore(_ patterns: [PatternData]) -> Float {
        guard !patterns.isEmpty else { return 0 }
        
        let now = Date()
        let scores = patterns.map { pattern in
            let age = now.timeIntervalSince(pattern.timestamp)
            let ageInDays = age / 86400
            return exp(-ageInDays / 30) // Exponential decay
        }
        
        return Float(scores.reduce(0, +) / Double(scores.count))
    }
    
    private func analyzeCrossFieldPatterns(_ interactions: [APEUserInteraction]) {
        // Analyze patterns across multiple fields
        for i in 0..<interactions.count {
            for j in (i+1)..<interactions.count {
                let field1 = interactions[i].field
                let field2 = interactions[j].field
                
                // Look for correlations
                if shouldCreateRelationship(between: field1, and: field2, from: interactions) {
                    let relationship = FieldRelationship(
                        primaryField: field1,
                        relatedField: field2,
                        relationshipStrength: 0.5,
                        relationshipType: .correlated
                    )
                    fieldRelationships.append(relationship)
                }
            }
        }
    }
    
    private func shouldCreateRelationship(
        between field1: RequirementField,
        and field2: RequirementField,
        from interactions: [APEUserInteraction]
    ) -> Bool {
        // Simple correlation check
        let field1Values = interactions.filter { $0.field == field1 }.map { String(describing: $0.finalValue) }
        let field2Values = interactions.filter { $0.field == field2 }.map { String(describing: $0.finalValue) }
        
        return !field1Values.isEmpty && !field2Values.isEmpty && field1Values.count == field2Values.count
    }
    
    private func updateTemporalPatterns(_ interactions: [APEUserInteraction]) {
        // Update temporal pattern confidence based on batch
        for interaction in interactions {
            let _ = captureTimeContext()
            
            // Find matching temporal patterns
            for i in 0..<temporalPatterns.count {
                if temporalPatterns[i].field == interaction.field.rawValue {
                    // Update confidence based on match
                    let matches = String(describing: interaction.finalValue) == temporalPatterns[i].typicalValue
                    let adjustment: Float = matches ? 0.1 : -0.05
                    temporalPatterns[i] = TemporalPattern(
                        field: temporalPatterns[i].field,
                        timePattern: temporalPatterns[i].timePattern,
                        typicalValue: temporalPatterns[i].typicalValue,
                        confidence: min(max(temporalPatterns[i].confidence + adjustment, 0), 1)
                    )
                }
            }
        }
    }
}

// MARK: - Additional Supporting Types

private struct ValueCluster {
    let representative: String
    let members: [PatternData]
    let confidence: Float
}

// MARK: - Helper Extensions

extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}