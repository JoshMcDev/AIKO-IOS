import Foundation

/// User action tracking for personalization
public struct UserAction: Sendable {
    public enum ActionType: String, Codable, Sendable {
        case documentGenerated = "document_generated"
        case templateSelected = "template_selected"
        case formCompleted = "form_completed"
        case feedbackProvided = "feedback_provided"
    }

    public let type: ActionType
    public let documentType: AIDocumentType?
    public let templateId: String?
    public let timestamp: Date

    public init(type: ActionType, documentType: AIDocumentType? = nil, templateId: String? = nil, timestamp: Date = Date()) {
        self.type = type
        self.documentType = documentType
        self.templateId = templateId
        self.timestamp = timestamp
    }
}

/// Personalization recommendations
public struct PersonalizationRecommendations: Sendable {
    public let suggestedTemplates: [String]
    public let preferredDocumentTypes: [AIDocumentType]
    public let workflowOptimizations: [String]
    public let confidenceScore: Double

    public init(suggestedTemplates: [String], preferredDocumentTypes: [AIDocumentType], workflowOptimizations: [String], confidenceScore: Double) {
        self.suggestedTemplates = suggestedTemplates
        self.preferredDocumentTypes = preferredDocumentTypes
        self.workflowOptimizations = workflowOptimizations
        self.confidenceScore = confidenceScore
    }
}

/// Personalized recommendations for Core Engines
public struct PersonalizedRecommendations: Sendable {
    public let suggestedTemplates: [String]
    public let optimizations: [String]
    public let learningInsights: [String]
    public let confidenceScore: Double

    public init(
        suggestedTemplates: [String] = [],
        optimizations: [String] = [],
        learningInsights: [String] = [],
        confidenceScore: Double = 0.5
    ) {
        self.suggestedTemplates = suggestedTemplates
        self.optimizations = optimizations
        self.learningInsights = learningInsights
        self.confidenceScore = confidenceScore
    }
}

/// Compliance requirements
public struct AIComplianceRequirements: Sendable {
    public let farCompliance: Bool
    public let securityRequirements: [String]
    public let accessibility: Bool
    public let dataRetention: TimeInterval?

    public init(farCompliance: Bool, securityRequirements: [String], accessibility: Bool, dataRetention: TimeInterval? = nil) {
        self.farCompliance = farCompliance
        self.securityRequirements = securityRequirements
        self.accessibility = accessibility
        self.dataRetention = dataRetention
    }

    public static let standard = AIComplianceRequirements(
        farCompliance: true,
        securityRequirements: ["52.204-21", "52.212-4"],
        accessibility: true,
        dataRetention: 7 * 24 * 3600 // 7 days
    )
}

/// Compliance validation result
public struct AIValidationResult: Sendable {
    public let isCompliant: Bool
    public let score: Double
    public let issues: [AIComplianceIssue]
    public let recommendations: [String]

    public init(isCompliant: Bool, score: Double, issues: [AIComplianceIssue], recommendations: [String]) {
        self.isCompliant = isCompliant
        self.score = score
        self.issues = issues
        self.recommendations = recommendations
    }

    // Convenience initializer for just score, issues, and recommendations
    public init(score: Double, issues: [AIComplianceIssue], recommendations: [String]) {
        isCompliant = issues.allSatisfy { $0.severity != .critical && $0.severity != .high }
        self.score = score
        self.issues = issues
        self.recommendations = recommendations
    }
}

/// AI-specific compliance issue for Core Engines
public struct AIComplianceIssue: Sendable {
    public enum Severity: String, CaseIterable, Codable, Sendable {
        case low
        case medium
        case high
        case critical
    }

    public let severity: Severity
    public let description: String
    public let farReference: String?
    public let suggestion: String?

    public init(severity: Severity, description: String, farReference: String? = nil, suggestion: String? = nil) {
        self.severity = severity
        self.description = description
        self.farReference = farReference
        self.suggestion = suggestion
    }
}

/// Prompt optimization patterns for Core Engines
public enum PromptPattern: String, CaseIterable, Codable, Sendable {
    case concise
    case detailed
    case governmentCompliance = "government_compliance"
    case technical
    case structured
    case conversational

    public var description: String {
        switch self {
        case .concise:
            "Generate concise, focused output"
        case .detailed:
            "Provide comprehensive details"
        case .governmentCompliance:
            "Follow government contracting standards"
        case .technical:
            "Include technical specifications"
        case .structured:
            "Organize response in structured format"
        case .conversational:
            "Use professional conversational tone"
        }
    }
}

/// Acquisition context (already exists in tests but might need this version)
public struct AcquisitionContext: Sendable {
    public let programName: String
    public let agency: String?
    public let contractValue: Decimal?
    public let timeline: DateInterval?
    public let specialRequirements: [String]

    public init(programName: String, agency: String? = nil, contractValue: Decimal? = nil, timeline: DateInterval? = nil, specialRequirements: [String] = []) {
        self.programName = programName
        self.agency = agency
        self.contractValue = contractValue
        self.timeline = timeline
        self.specialRequirements = specialRequirements
    }
}
