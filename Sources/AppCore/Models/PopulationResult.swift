import Foundation

/// Result of form auto-population process
public struct PopulationResult: Equatable, Sendable {
    public let populatedFields: [FormPopulatedField]
    public let overallConfidence: Double
    public let processingTime: TimeInterval
    public let requiresManualReview: Bool
    public let summary: PopulationSummary

    public init(
        populatedFields: [FormPopulatedField],
        overallConfidence: Double,
        processingTime: TimeInterval,
        requiresManualReview: Bool,
        summary: PopulationSummary? = nil
    ) {
        self.populatedFields = populatedFields
        self.overallConfidence = overallConfidence
        self.processingTime = processingTime
        self.requiresManualReview = requiresManualReview
        self.summary = summary ?? PopulationSummary(from: populatedFields)
    }
}

/// Individual populated field information
public struct FormPopulatedField: Equatable, Sendable {
    public let formField: FormField
    public let wasAutoFilled: Bool
    public let userAccepted: Bool
    public let isCritical: Bool
    public let requiresManualReview: Bool
    public let originalValue: String?
    public let populatedValue: String

    public init(
        formField: FormField,
        wasAutoFilled: Bool,
        userAccepted: Bool = false,
        isCritical: Bool = false,
        requiresManualReview: Bool = false,
        originalValue: String? = nil,
        populatedValue: String
    ) {
        self.formField = formField
        self.wasAutoFilled = wasAutoFilled
        self.userAccepted = userAccepted
        self.isCritical = isCritical
        self.requiresManualReview = requiresManualReview
        self.originalValue = originalValue
        self.populatedValue = populatedValue
    }
}

/// Summary statistics for population result
public struct PopulationSummary: Equatable, Sendable {
    public let totalFields: Int
    public let autoFilledCount: Int
    public let manualReviewCount: Int
    public let criticalFieldCount: Int
    public let autoFillRate: Double

    public init(from populatedFields: [FormPopulatedField]) {
        totalFields = populatedFields.count
        autoFilledCount = populatedFields.count(where: { $0.wasAutoFilled })
        manualReviewCount = populatedFields.count(where: { $0.requiresManualReview })
        criticalFieldCount = populatedFields.count(where: { $0.isCritical })
        autoFillRate = totalFields > 0 ? Double(autoFilledCount) / Double(totalFields) : 0.0
    }
}
