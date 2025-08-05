import Foundation

/// Feature state encoder for converting contexts to feature vectors
/// Provides normalized feature extraction for Q-learning state representation
public actor FeatureStateEncoder {
    // MARK: - Static Interface

    /// Main encoding method to convert AcquisitionContext to FeatureVector
    /// This method works with the production AcquisitionContext
    public static func encode(_ context: AcquisitionContext) -> FeatureVector {
        var features: [String: Double] = [:]

        // Encode production context features
        features["context_type"] = encodeContextType(context.type)
        features["context_confidence"] = encodeContextConfidence(context.confidence)
        features["sub_context_count"] = Double(context.subContexts.count)
        features["keyword_matches"] = Double(context.metadata.keywordMatches)
        features["total_words"] = Double(context.metadata.totalWords)

        // Default values for missing test-specific features
        features["workflow_progress"] = 0.5
        features["documents_completed"] = 0.0
        features["past_success_rate"] = 0.7
        features["user_experience_level"] = 0.5

        return FeatureVector(features: features)
    }

    /// Test encoding method to convert TestAcquisitionContext to FeatureVector
    /// This method is used by the test suite
    public static func encode(_ context: TestAcquisitionContext) -> FeatureVector {
        var features: [String: Double] = [:]

        // 1. Document type one-hot encoding
        encodeDocumentType(context.documentType, into: &features)

        // 2. Acquisition value normalization
        encodeAcquisitionValue(context.acquisitionValue, into: &features)

        // 3. Complexity features
        encodeComplexity(context.complexity, into: &features)

        // 4. Time constraint features
        encodeTimeConstraints(context.timeConstraints, into: &features)

        // 5. Historical features
        features["past_success_rate"] = context.historicalSuccess
        features["user_experience_level"] = context.userProfile.experienceLevel

        // 6. Regulatory requirement features (limit to first 10 most common)
        encodeRegulatoryRequirements(context.regulatoryRequirements, into: &features)

        // 7. Workflow state features
        features["workflow_progress"] = context.workflowProgress
        features["documents_completed"] = Double(context.completedDocuments.count)

        return FeatureVector(features: features)
    }

    // MARK: - Production Context Encoding Methods

    private static func encodeContextType(_ type: ContextCategory) -> Double {
        switch type {
        case .informationTechnology:
            1.0
        case .construction:
            2.0
        case .professional:
            3.0
        }
    }

    private static func encodeContextConfidence(_ confidence: ContextConfidence) -> Double {
        switch confidence {
        case .high:
            1.0
        case .medium:
            0.6
        case .low:
            0.3
        }
    }

    // MARK: - Test Context Encoding Methods

    private static func encodeDocumentType(_ documentType: TestDocumentType, into features: inout [String: Double]) {
        // One-hot encode document types
        switch documentType {
        case .purchaseRequest:
            features["docType_purchaseRequest"] = 1.0
        case .sourceSelection:
            features["docType_sourceSelection"] = 1.0
        case .emergencyProcurement:
            features["docType_emergencyProcurement"] = 1.0
        case .simplePurchase:
            features["docType_simplePurchase"] = 1.0
        case .majorConstruction:
            features["docType_majorConstruction"] = 1.0
        case .other:
            features["docType_other"] = 1.0
        }
    }

    private static func encodeAcquisitionValue(_ value: Double, into features: inout [String: Double]) {
        // Normalize using log scaling for large ranges
        let logValue = log10(max(1.0, value))
        let maxLogValue = log10(100_000_000.0) // $100M max

        features["value_normalized"] = min(1.0, logValue / maxLogValue)
        features["value_log"] = logValue
    }

    private static func encodeComplexity(_ complexity: TestComplexityLevel, into features: inout [String: Double]) {
        features["complexity_score"] = complexity.score
        features["num_requirements"] = Double(complexity.factors.count)
    }

    private static func encodeTimeConstraints(_ timeConstraints: TestTimeConstraints, into features: inout [String: Double]) {
        features["days_remaining"] = Double(timeConstraints.daysRemaining)
        features["is_urgent"] = timeConstraints.isUrgent ? 1.0 : 0.0
    }

    private static func encodeRegulatoryRequirements(_ requirements: Set<TestFARClause>, into features: inout [String: Double]) {
        features["num_requirements"] = Double(requirements.count)

        // Encode up to 10 most common regulatory requirements as binary indicators
        let sortedRequirements = Array(requirements).sorted { $0.clauseNumber < $1.clauseNumber }
        let limitedRequirements = Array(sortedRequirements.prefix(10))

        for requirement in limitedRequirements {
            features["has_\(requirement.clauseNumber)"] = 1.0
        }
    }
}

/// Feature vector representation for Q-learning states
public struct FeatureVector: Hashable, Equatable, Sendable {
    public let features: [String: Double]
    public let hash: Int

    public init(features: [String: Double]) {
        self.features = features
        hash = Self.computeHash(features: features)
    }

    /// Compute stable hash for feature vector
    private static func computeHash(features: [String: Double]) -> Int {
        var hasher = Hasher()

        // Sort keys for consistent hashing
        let sortedKeys = features.keys.sorted()
        for key in sortedKeys {
            hasher.combine(key)
            // Round double values to avoid floating point precision issues
            if let value = features[key] {
                hasher.combine(Int(value * 1_000_000))
            }
        }

        return hasher.finalize()
    }

    // MARK: - Hashable & Equatable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }

    public static func == (lhs: FeatureVector, rhs: FeatureVector) -> Bool {
        guard lhs.features.count == rhs.features.count else { return false }

        for (key, value) in lhs.features {
            guard let rhsValue = rhs.features[key],
                  abs(value - rhsValue) < 1e-6
            else {
                return false
            }
        }

        return true
    }
}
