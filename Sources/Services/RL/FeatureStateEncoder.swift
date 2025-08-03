import Foundation
import AppCore

/// FeatureStateEncoder - Converts acquisition context to feature vectors
/// This is minimal scaffolding code to make tests compile but fail appropriately
public struct FeatureStateEncoder: Sendable {

    // MARK: - Feature Extraction - Scaffolding Implementation

    public static func encode(_ context: AcquisitionContext) -> FeatureVector {
        // RED PHASE: Minimal implementation that will fail feature extraction tests

        // Return minimal features that won't match test expectations
        let features: [String: Double] = [
            "placeholder": 1.0
        ]

        return FeatureVector(features: features)
    }

    private static func normalizeValue(_ value: Double) -> Double {
        // RED PHASE: Simple implementation that will fail normalization tests
        return min(1.0, value / 1000000.0)
    }
}

// MARK: - Feature Vector

public struct FeatureVector: Hashable, Codable, Sendable, Equatable {
    public let features: [String: Double]

    public init(features: [String: Double]) {
        self.features = features
    }

    public var hash: Int {
        // RED PHASE: Simple hash that will fail stability tests
        return features.count
    }

    public static func == (lhs: FeatureVector, rhs: FeatureVector) -> Bool {
        return lhs.features == rhs.features
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}
