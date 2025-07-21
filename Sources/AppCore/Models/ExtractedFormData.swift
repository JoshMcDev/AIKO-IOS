import Foundation

/// Container for extracted form data from document processing
public struct ExtractedFormData: Equatable, Sendable {
    public let fields: [FormField]
    public let confidence: ConfidenceScore
    public let metadata: ExtractionMetadata

    public init(
        fields: [FormField],
        confidence: ConfidenceScore,
        metadata: ExtractionMetadata
    ) {
        self.fields = fields
        self.confidence = confidence
        self.metadata = metadata
    }

    public var highConfidenceFields: [FormField] {
        return fields.filter { $0.confidence.isHighConfidence }
    }

    public var criticalFields: [FormField] {
        return fields.filter { $0.isCritical }
    }
}

/// Metadata about the extraction process
public struct ExtractionMetadata: Equatable, Sendable {
    public let processingTime: TimeInterval
    public let formType: FormType
    public let ocrConfidence: Double
    public let imageQuality: Double
    public let timestamp: Date

    public init(
        processingTime: TimeInterval,
        formType: FormType,
        ocrConfidence: Double = 0.0,
        imageQuality: Double = 0.0,
        timestamp: Date = Date()
    ) {
        self.processingTime = processingTime
        self.formType = formType
        self.ocrConfidence = ocrConfidence
        self.imageQuality = imageQuality
        self.timestamp = timestamp
    }
}
