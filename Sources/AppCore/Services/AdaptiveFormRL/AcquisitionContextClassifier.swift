import Foundation

/// Context classifier for acquisition types to enable domain-specific learning
/// Prevents cross-context contamination in Q-learning
public actor AcquisitionContextClassifier {
    // MARK: - Classification Rules

    private let itKeywords = ["software", "hardware", "technology", "computer", "network", "server", "database", "cloud", "cybersecurity", "it services"]
    private let constructionKeywords = ["construction", "building", "materials", "concrete", "steel", "contractor", "architect", "engineering", "infrastructure", "renovation"]
    private let professionalKeywords = ["consulting", "analysis", "research", "training", "advisory", "professional services", "management", "strategy"]

    // MARK: - Confidence Thresholds

    private let highConfidenceThreshold: Double = 0.8
    private let mediumConfidenceThreshold: Double = 0.6

    // MARK: - Public Interface

    /// Classify acquisition context based on content analysis
    public func classifyContext(acquisition: AcquisitionAggregate) -> AcquisitionContext {
        let analysisData = extractAnalysisData(from: acquisition)

        // Calculate confidence scores for each context type
        let itScore = calculateITScore(data: analysisData)
        let constructionScore = calculateConstructionScore(data: analysisData)
        let professionalScore = calculateProfessionalScore(data: analysisData)

        // Determine primary context
        let scores = [
            (ContextCategory.informationTechnology, itScore),
            (ContextCategory.construction, constructionScore),
            (ContextCategory.professional, professionalScore),
        ]

        let primaryContext = scores.max { $0.1 < $1.1 }

        guard let primary = primaryContext else {
            return createDefaultContext()
        }

        let confidence = determineConfidence(score: primary.1)

        return AcquisitionContext(
            type: primary.0,
            confidence: confidence,
            subContexts: detectSubContexts(data: analysisData, primaryType: primary.0),
            metadata: createMetadata(from: analysisData, type: primary.0)
        )
    }

    /// Fast classification for real-time scenarios
    public func quickClassify(title: String, description: String) -> AcquisitionContext {
        let combinedText = "\(title) \(description)".lowercased()

        let itMatches = countKeywordMatches(text: combinedText, keywords: itKeywords)
        let constructionMatches = countKeywordMatches(text: combinedText, keywords: constructionKeywords)
        let professionalMatches = countKeywordMatches(text: combinedText, keywords: professionalKeywords)

        let maxMatches = max(itMatches, constructionMatches, professionalMatches)

        if maxMatches == 0 {
            return createDefaultContext()
        }

        let type: ContextCategory
        let confidence: ContextConfidence

        if itMatches == maxMatches {
            type = .informationTechnology
            confidence = determineConfidenceFromMatches(itMatches, total: combinedText.split(separator: " ").count)
        } else if constructionMatches == maxMatches {
            type = .construction
            confidence = determineConfidenceFromMatches(constructionMatches, total: combinedText.split(separator: " ").count)
        } else {
            type = .professional
            confidence = determineConfidenceFromMatches(professionalMatches, total: combinedText.split(separator: " ").count)
        }

        return AcquisitionContext(
            type: type,
            confidence: confidence,
            subContexts: [],
            metadata: ContextMetadata(
                keywordMatches: maxMatches,
                totalWords: combinedText.split(separator: " ").count,
                classificationMethod: .keywordBased
            )
        )
    }

    // MARK: - Private Methods

    private func extractAnalysisData(from acquisition: AcquisitionAggregate) -> AnalysisData {
        // Extract relevant text data from acquisition
        let title = acquisition.title ?? ""
        let description = acquisition.description ?? ""
        let requirements = acquisition.requirements?.joined(separator: " ") ?? ""

        return AnalysisData(
            title: title,
            description: description,
            requirements: requirements,
            combinedText: "\(title) \(description) \(requirements)".lowercased()
        )
    }

    private func calculateITScore(data: AnalysisData) -> Double {
        let matches = countKeywordMatches(text: data.combinedText, keywords: itKeywords)
        let density = Double(matches) / Double(max(1, data.combinedText.split(separator: " ").count))

        // Boost score for specific IT patterns
        var score = density
        if data.combinedText.contains("software license") { score += 0.2 }
        if data.combinedText.contains("hardware") { score += 0.15 }
        if data.combinedText.contains("cloud service") { score += 0.15 }

        return min(1.0, score)
    }

    private func calculateConstructionScore(data: AnalysisData) -> Double {
        let matches = countKeywordMatches(text: data.combinedText, keywords: constructionKeywords)
        let density = Double(matches) / Double(max(1, data.combinedText.split(separator: " ").count))

        // Boost score for specific construction patterns
        var score = density
        if data.combinedText.contains("building materials") { score += 0.2 }
        if data.combinedText.contains("construction services") { score += 0.15 }
        if data.combinedText.contains("contractor") { score += 0.1 }

        return min(1.0, score)
    }

    private func calculateProfessionalScore(data: AnalysisData) -> Double {
        let matches = countKeywordMatches(text: data.combinedText, keywords: professionalKeywords)
        let density = Double(matches) / Double(max(1, data.combinedText.split(separator: " ").count))

        // Boost score for specific professional patterns
        var score = density
        if data.combinedText.contains("professional services") { score += 0.2 }
        if data.combinedText.contains("consulting") { score += 0.15 }
        if data.combinedText.contains("training") { score += 0.1 }

        return min(1.0, score)
    }

    private func countKeywordMatches(text: String, keywords: [String]) -> Int {
        keywords.reduce(0) { count, keyword in
            count + (text.contains(keyword) ? 1 : 0)
        }
    }

    private func determineConfidence(score: Double) -> ContextConfidence {
        if score >= highConfidenceThreshold {
            .high
        } else if score >= mediumConfidenceThreshold {
            .medium
        } else {
            .low
        }
    }

    private func determineConfidenceFromMatches(_ matches: Int, total: Int) -> ContextConfidence {
        let ratio = Double(matches) / Double(max(1, total))

        if ratio >= 0.1 {
            return .high
        } else if ratio >= 0.05 {
            return .medium
        } else {
            return .low
        }
    }

    private func detectSubContexts(data: AnalysisData, primaryType: ContextCategory) -> [String] {
        var subContexts: [String] = []

        switch primaryType {
        case .informationTechnology:
            if data.combinedText.contains("cloud") { subContexts.append("cloud") }
            if data.combinedText.contains("security") { subContexts.append("cybersecurity") }
            if data.combinedText.contains("database") { subContexts.append("database") }

        case .construction:
            if data.combinedText.contains("materials") { subContexts.append("materials") }
            if data.combinedText.contains("labor") { subContexts.append("labor") }
            if data.combinedText.contains("equipment") { subContexts.append("equipment") }

        case .professional:
            if data.combinedText.contains("consulting") { subContexts.append("consulting") }
            if data.combinedText.contains("training") { subContexts.append("training") }
            if data.combinedText.contains("research") { subContexts.append("research") }
        }

        return subContexts
    }

    private func createMetadata(from data: AnalysisData, type: ContextCategory) -> ContextMetadata {
        let wordCount = data.combinedText.split(separator: " ").count
        let keywordMatches: Int = switch type {
        case .informationTechnology:
            countKeywordMatches(text: data.combinedText, keywords: itKeywords)
        case .construction:
            countKeywordMatches(text: data.combinedText, keywords: constructionKeywords)
        case .professional:
            countKeywordMatches(text: data.combinedText, keywords: professionalKeywords)
        }

        return ContextMetadata(
            keywordMatches: keywordMatches,
            totalWords: wordCount,
            classificationMethod: .comprehensive
        )
    }

    private func createDefaultContext() -> AcquisitionContext {
        AcquisitionContext(
            type: .professional,
            confidence: .low,
            subContexts: [],
            metadata: ContextMetadata(
                keywordMatches: 0,
                totalWords: 0,
                classificationMethod: .default
            )
        )
    }
}

// MARK: - Supporting Types

public struct AcquisitionContext: Sendable {
    public let type: ContextCategory
    public let confidence: ContextConfidence
    public let subContexts: [String]
    public let metadata: ContextMetadata

    // Compatibility properties for existing code
    public var programName: String {
        "Default Program"
    }

    public var agency: String? {
        nil
    }

    public var contractValue: Decimal? {
        nil
    }

    public var regulatoryRequirements: [String] {
        // Generate regulatory requirements based on context type
        switch type {
        case .informationTechnology:
            ["FISMA", "NIST", "FedRAMP"]
        case .construction:
            ["FAR", "OSHA", "Environmental"]
        case .professional:
            ["SOW", "Quality Standards", "Professional Licensing"]
        }
    }

    public init(type: ContextCategory, confidence: ContextConfidence, subContexts: [String], metadata: ContextMetadata) {
        self.type = type
        self.confidence = confidence
        self.subContexts = subContexts
        self.metadata = metadata
    }
}

public enum ContextConfidence: String, CaseIterable, Sendable {
    case high
    case medium
    case low
}

public struct ContextMetadata: Sendable {
    public let keywordMatches: Int
    public let totalWords: Int
    public let classificationMethod: ClassificationMethod

    public init(keywordMatches: Int, totalWords: Int, classificationMethod: ClassificationMethod) {
        self.keywordMatches = keywordMatches
        self.totalWords = totalWords
        self.classificationMethod = classificationMethod
    }
}

public enum ClassificationMethod: String, Sendable {
    case comprehensive
    case keywordBased = "keyword_based"
    case `default`
}

/// Acquisition aggregate for context classification
public struct AcquisitionAggregate: Sendable {
    public let title: String?
    public let description: String?
    public let requirements: [String]?

    public init(title: String?, description: String?, requirements: [String]?) {
        self.title = title
        self.description = description
        self.requirements = requirements
    }
}

private struct AnalysisData {
    let title: String
    let description: String
    let requirements: String
    let combinedText: String
}
