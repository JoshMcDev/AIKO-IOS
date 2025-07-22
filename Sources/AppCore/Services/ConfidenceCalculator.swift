import Foundation

/// Calculates confidence scores for extracted form data
public struct ConfidenceCalculator: Sendable {
    // Confidence weighting factors
    private enum WeightingFactors {
        static let ocr: Double = 0.3
        static let imageQuality: Double = 0.2
        static let patternMatch: Double = 0.3
        static let validation: Double = 0.2
    }

    public init() {}

    /// Calculate confidence score for a form field
    public func calculateFieldConfidence(
        _ field: FormField,
        ocrConfidence: Double,
        imageQuality: Double
    ) -> ConfidenceScore {
        let patternMatchScore = calculatePatternMatchScore(for: field.fieldType)
        let validationScore = field.isValidFormField ? 0.9 : 0.5

        let weightedScore =
            (ocrConfidence * WeightingFactors.ocr) +
            (imageQuality * WeightingFactors.imageQuality) +
            (patternMatchScore * WeightingFactors.patternMatch) +
            (validationScore * WeightingFactors.validation)

        return ConfidenceScore(
            value: clampConfidence(weightedScore),
            factors: createConfidenceFactors(
                ocr: ocrConfidence,
                imageQuality: imageQuality,
                patternMatch: patternMatchScore,
                validation: validationScore
            )
        )
    }

    /// Calculate pattern match score based on field type complexity
    private func calculatePatternMatchScore(for fieldType: FieldType) -> Double {
        switch fieldType {
        case .text:
            0.8 // Lower confidence for free-form text
        case .cageCode, .uei, .currency, .date:
            0.9 // Higher confidence for structured/validated fields
        default:
            0.85 // Medium confidence for other field types
        }
    }

    /// Clamp confidence value to valid range [0.0, 1.0]
    private func clampConfidence(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    /// Create confidence factors dictionary for debugging and analysis
    private func createConfidenceFactors(
        ocr: Double,
        imageQuality: Double,
        patternMatch: Double,
        validation: Double
    ) -> [String: Double] {
        [
            "ocr": ocr,
            "image_quality": imageQuality,
            "pattern_match": patternMatch,
            "validation": validation
        ]
    }

    /// Calculate overall confidence for extracted data
    public func calculateOverallConfidence(
        for fields: [FormField]
    ) -> ConfidenceScore {
        // GREEN phase - calculate average confidence across fields
        guard !fields.isEmpty else {
            return ConfidenceScore(value: 0.0, factors: ["field_count": 0])
        }

        let averageConfidence = fields.reduce(0.0) { $0 + $1.confidence.value } / Double(fields.count)
        let criticalFieldCount = fields.count(where: { $0.isCritical })
        let highConfidenceCount = fields.count(where: { $0.confidence.value >= 0.8 })

        // Boost confidence if we have high-confidence critical fields
        let confidenceBoost = criticalFieldCount > 0 && highConfidenceCount > 0 ? 0.1 : 0.0
        let finalConfidence = min(1.0, averageConfidence + confidenceBoost)

        return ConfidenceScore(
            value: finalConfidence,
            factors: [
                "field_count": Double(fields.count),
                "average_confidence": averageConfidence,
                "critical_fields": Double(criticalFieldCount),
                "high_confidence_fields": Double(highConfidenceCount)
            ]
        )
    }

    /// Determine if field should be auto-filled based on confidence
    public func shouldAutoFill(
        field: FormField,
        threshold: ConfidenceThreshold = .high
    ) -> Bool {
        // Never auto-fill critical fields for safety
        guard !field.isCritical else { return false }

        let minimumThreshold = getConfidenceThreshold(for: threshold)
        return field.confidence.value >= minimumThreshold
    }

    /// Get numeric confidence threshold for given threshold level
    private func getConfidenceThreshold(for threshold: ConfidenceThreshold) -> Double {
        switch threshold {
        case .high:
            0.85
        case .medium:
            0.65
        case .low:
            0.5
        }
    }

    /// Determine if field requires manual review
    public func requiresManualReview(field: FormField) -> Bool {
        field.isCritical ||
            field.confidence.value < getConfidenceThreshold(for: .medium) ||
            !field.isValidFormField
    }
}
