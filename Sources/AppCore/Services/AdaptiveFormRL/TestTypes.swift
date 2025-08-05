import Foundation

// MARK: - Test Types for FeatureStateEncoder Testing

/// Test document type enumeration for testing purposes
public enum TestDocumentType: String, CaseIterable, Sendable {
    case purchaseRequest = "purchase_request"
    case sourceSelection = "source_selection"
    case emergencyProcurement = "emergency_procurement"
    case simplePurchase = "simple_purchase"
    case majorConstruction = "major_construction"
    case other
}

/// Test complexity level for testing purposes
public struct TestComplexityLevel: Sendable {
    public let score: Double
    public let factors: [String]

    public init(score: Double, factors: [String]) {
        self.score = score
        self.factors = factors
    }
}

/// Test time constraints for testing purposes
public struct TestTimeConstraints: Sendable {
    public let daysRemaining: Int
    public let isUrgent: Bool
    public let expectedDuration: TimeInterval

    public init(daysRemaining: Int, isUrgent: Bool, expectedDuration: TimeInterval) {
        self.daysRemaining = daysRemaining
        self.isUrgent = isUrgent
        self.expectedDuration = expectedDuration
    }
}

/// Test FAR clause for testing purposes
public struct TestFARClause: Hashable, Sendable {
    public let clauseNumber: String
    public let isCritical: Bool

    public init(clauseNumber: String, isCritical: Bool) {
        self.clauseNumber = clauseNumber
        self.isCritical = isCritical
    }
}

/// Test user profile for testing purposes
public struct TestUserProfile: Sendable {
    public let experienceLevel: Double

    public init(experienceLevel: Double) {
        self.experienceLevel = experienceLevel
    }
}

/// Test-specific AcquisitionContext that works with FeatureStateEncoder
public struct TestAcquisitionContext: Sendable {
    public let acquisitionId: UUID
    public let documentType: TestDocumentType
    public let acquisitionValue: Double
    public let complexity: TestComplexityLevel
    public let timeConstraints: TestTimeConstraints
    public let regulatoryRequirements: Set<TestFARClause>
    public let historicalSuccess: Double
    public let userProfile: TestUserProfile
    public let workflowProgress: Double
    public let completedDocuments: [String]

    public init(
        acquisitionId: UUID,
        documentType: TestDocumentType,
        acquisitionValue: Double,
        complexity: TestComplexityLevel,
        timeConstraints: TestTimeConstraints,
        regulatoryRequirements: Set<TestFARClause>,
        historicalSuccess: Double,
        userProfile: TestUserProfile,
        workflowProgress: Double,
        completedDocuments: [String]
    ) {
        self.acquisitionId = acquisitionId
        self.documentType = documentType
        self.acquisitionValue = acquisitionValue
        self.complexity = complexity
        self.timeConstraints = timeConstraints
        self.regulatoryRequirements = regulatoryRequirements
        self.historicalSuccess = historicalSuccess
        self.userProfile = userProfile
        self.workflowProgress = workflowProgress
        self.completedDocuments = completedDocuments
    }
}
