import Foundation

// MARK: - User Pattern Learning Engine

public class UserPatternLearningEngine {
    private var patternHistory: [RequirementField: [PatternData]] = [:]
    private var userDefaults: [RequirementField: FieldDefault] = [:]
    private let persistenceKey = "UserPatternLearningEngine.patterns"
    
    public init() {
        loadPatterns()
    }
    
    public func learn(from interaction: APEUserInteraction) async {
        // Store pattern data
        var patterns = patternHistory[interaction.field] ?? []
        let patternData = PatternData(
            value: String(describing: interaction.finalValue),
            timestamp: Date(),
            acceptedSuggestion: interaction.acceptedSuggestion,
            timeToRespond: interaction.timeToRespond,
            hadDocumentContext: interaction.documentContext
        )
        patterns.append(patternData)
        
        // Keep only recent patterns (last 100)
        if patterns.count > 100 {
            patterns = Array(patterns.suffix(100))
        }
        
        patternHistory[interaction.field] = patterns
        
        // Update defaults based on patterns
        updateDefaults(for: interaction.field)
        
        // Persist patterns
        savePatterns()
    }
    
    public func getDefault(for field: RequirementField) async -> FieldDefault? {
        userDefaults[field]
    }
    
    // MARK: - Private Methods
    
    private func updateDefaults(for field: RequirementField) {
        guard let patterns = patternHistory[field], patterns.count >= 3 else { return }
        
        // Find most common value in recent patterns
        let recentPatterns = Array(patterns.suffix(20))
        let valueCounts = Dictionary(grouping: recentPatterns, by: { $0.value })
            .mapValues { $0.count }
        
        if let mostCommon = valueCounts.max(by: { $0.value < $1.value }) {
            let confidence = Float(mostCommon.value) / Float(recentPatterns.count)
            
            // Only set as default if confidence is high enough
            if confidence >= 0.6 {
                userDefaults[field] = FieldDefault(
                    value: mostCommon.key,
                    confidence: confidence,
                    source: .userPattern
                )
            }
        }
    }
    
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
    
    private func savePatterns() {
        // Convert RequirementField keys to strings for encoding
        let encodableHistory = Dictionary(uniqueKeysWithValues: 
            patternHistory.map { ($0.key.rawValue, $0.value) }
        )
        
        if let encoded = try? JSONEncoder().encode(encodableHistory) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
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
}