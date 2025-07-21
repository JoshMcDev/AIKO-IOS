import Foundation

/// Represents confidence scoring for extracted data
public struct ConfidenceScore: Equatable, Sendable {
    public let value: Double // 0.0 to 1.0
    public let factors: [String: Double]

    public init(value: Double, factors: [String: Double] = [:]) {
        self.value = max(0.0, min(1.0, value)) // Clamp to 0.0-1.0
        self.factors = factors
    }

    public var isHighConfidence: Bool {
        return value >= 0.85
    }

    public var isMediumConfidence: Bool {
        return value >= 0.65 && value < 0.85
    }

    public var isLowConfidence: Bool {
        return value < 0.65
    }

    public var threshold: ConfidenceThreshold {
        if isHighConfidence { return .high }
        if isMediumConfidence { return .medium }
        return .low
    }
}

/// Confidence thresholds for decision making
public enum ConfidenceThreshold: String, CaseIterable, Equatable, Sendable {
    case high = "high"      // ≥0.85 - Auto-fill
    case medium = "medium"  // 0.65-0.85 - Suggest
    case low = "low"        // <0.65 - Manual review

    public var autoFillThreshold: Double {
        switch self {
        case .high: return 0.85
        case .medium: return 0.65
        case .low: return 0.0
        }
    }
}
