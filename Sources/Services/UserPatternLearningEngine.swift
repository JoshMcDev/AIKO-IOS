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
            modelUpdateQueue.async { [weak self] in
                self?.updatePredictionModel(for: interaction.field)
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
        let trainingData = prepareTrainingData(from: patterns)
        
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
    let id = UUID()
    let field: String // RequirementField raw value
    let context: PatternContext
    let predictedValue: String
    let occurrences: Int
    let accuracy: Float
    let lastSeen: Date
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