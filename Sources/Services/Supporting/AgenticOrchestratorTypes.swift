import AppCore
import Foundation

// MARK: - Core Types for AgenticOrchestrator Implementation

// These are minimal scaffolding types to make tests compile but fail appropriately

public struct WorkflowAction: Sendable, Identifiable, Codable, Hashable {
    public let id: UUID
    public let actionType: WorkflowActionType
    public let documentTemplates: [AgenticDocumentTemplate]
    public let automationLevel: AgenticAutomationLevel
    public let complianceChecks: [ComplianceCheck]
    public let estimatedDuration: TimeInterval

    public init(
        id: UUID = UUID(),
        actionType: WorkflowActionType,
        documentTemplates: [AgenticDocumentTemplate],
        automationLevel: AgenticAutomationLevel,
        complianceChecks: [ComplianceCheck],
        estimatedDuration: TimeInterval
    ) {
        self.id = id
        self.actionType = actionType
        self.documentTemplates = documentTemplates
        self.automationLevel = automationLevel
        self.complianceChecks = complianceChecks
        self.estimatedDuration = estimatedDuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(actionType)
    }

    public static func == (lhs: WorkflowAction, rhs: WorkflowAction) -> Bool {
        return lhs.id == rhs.id && lhs.actionType == rhs.actionType
    }

    enum CodingKeys: String, CodingKey {
        case id
        case actionType
        case documentTemplates
        case automationLevel
        case complianceChecks
        case estimatedDuration
    }
}

public enum WorkflowActionType: String, Codable, Sendable {
    case generateDocument
    case reviewCompliance
    case automateProcess
    case requestApproval
    case analyzeRequirements
    case createTemplate
}

// AutomationLevel already exists in FollowOnAction.swift, using AgenticAutomationLevel
public enum AgenticAutomationLevel: String, Codable, Sendable {
    case manual
    case assisted
    case automated
}

public struct AgenticDocumentTemplate: Sendable, Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let templateType: AgenticDocumentType
    public let requiredFields: [String]
    public let complianceRequirements: [ComplianceCheck]

    public init(id: UUID = UUID(), name: String, templateType: AgenticDocumentType, requiredFields: [String], complianceRequirements: [ComplianceCheck]) {
        self.id = id
        self.name = name
        self.templateType = templateType
        self.requiredFields = requiredFields
        self.complianceRequirements = complianceRequirements
    }
}

public enum AgenticDocumentType: String, Codable, Sendable {
    case solicitationNotice
    case requestForProposal
    case statementOfWork
    case contractAward
    case performanceWorkStatement
    case independentGovernmentEstimate
}

public struct ComplianceCheck: Sendable, Identifiable, Codable {
    public let id: UUID
    public let farClause: AgenticFARClause
    public let requirement: String
    public let severity: ComplianceSeverity
    public let automated: Bool

    public init(id: UUID = UUID(), farClause: AgenticFARClause, requirement: String, severity: ComplianceSeverity, automated: Bool) {
        self.id = id
        self.farClause = farClause
        self.requirement = requirement
        self.severity = severity
        self.automated = automated
    }
}

public struct AgenticFARClause: Sendable, Codable {
    public let section: String
    public let title: String
    public let description: String

    public init(id _: UUID = UUID(), section: String, title: String, description: String) {
        self.section = section
        self.title = title
        self.description = description
    }
}

public enum ComplianceSeverity: String, Codable, Sendable {
    case critical
    case major
    case minor
    case informational
}

// AcquisitionContext moved to test types section below

public enum AgenticComplexityLevel: String, Codable, Sendable {
    case simple
    case moderate
    case complex
    case highlyComplex

    public var numericValue: Double {
        switch self {
        case .simple: return 1.0
        case .moderate: return 2.0
        case .complex: return 3.0
        case .highlyComplex: return 4.0
        }
    }

    public var score: Double {
        return numericValue
    }
}

// TimeConstraints moved to test types section below

public struct Milestone: Sendable, Codable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let dueDate: Date
    public let dependencies: [String]

    public init(id: UUID = UUID(), name: String, dueDate: Date, dependencies: [String]) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
        self.dependencies = dependencies
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(dueDate)
        hasher.combine(dependencies)
    }

    public static func == (lhs: Milestone, rhs: Milestone) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.dueDate == rhs.dueDate &&
            lhs.dependencies == rhs.dependencies
    }
}

public enum UrgencyLevel: String, Codable, Sendable {
    case low
    case normal
    case high
    case critical

    public var multiplier: Double {
        switch self {
        case .low: return 0.5
        case .normal: return 1.0
        case .high: return 1.5
        case .critical: return 2.0
        }
    }
}

public struct AgenticUserProfile: Sendable, Codable, Hashable {
    public let userId: UUID
    public let experienceLevel: ExperienceLevel
    public let department: String
    public let role: UserRole
    public let preferences: UserPreferences
    public let historicalPerformance: PerformanceMetrics

    public init(id _: UUID = UUID(),
                userId: UUID = UUID(),
                experienceLevel: ExperienceLevel,
                department: String,
                role: UserRole,
                preferences: UserPreferences,
                historicalPerformance: PerformanceMetrics) {
        self.userId = userId
        self.experienceLevel = experienceLevel
        self.department = department
        self.role = role
        self.preferences = preferences
        self.historicalPerformance = historicalPerformance
    }
}

public enum ExperienceLevel: String, Codable, Sendable, Hashable {
    case novice
    case intermediate
    case advanced
    case expert

    public var confidenceMultiplier: Double {
        switch self {
        case .novice: return 0.7
        case .intermediate: return 0.85
        case .advanced: return 0.95
        case .expert: return 1.0
        }
    }
}

public enum UserRole: String, Codable, Sendable, Hashable {
    case contractingOfficer
    case contractSpecialist
    case programManager
    case technicalEvaluator
    case legalCounsel
    case financeOfficer
}

public struct UserPreferences: Sendable, Codable, Hashable {
    public let automationPreference: AutomationPreference
    public let notificationSettings: NotificationSettings
    public let workflowCustomizations: [String: String]

    public init(
        automationPreference: AutomationPreference = .balanced,
        notificationSettings: NotificationSettings = NotificationSettings(),
        workflowCustomizations: [String: String] = [:]
    ) {
        self.automationPreference = automationPreference
        self.notificationSettings = notificationSettings
        self.workflowCustomizations = workflowCustomizations
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(automationPreference)
        hasher.combine(notificationSettings)
        hasher.combine(workflowCustomizations)
    }

    public static func == (lhs: UserPreferences, rhs: UserPreferences) -> Bool {
        return lhs.automationPreference == rhs.automationPreference &&
            lhs.notificationSettings == rhs.notificationSettings &&
            lhs.workflowCustomizations == rhs.workflowCustomizations
    }
}

public enum AutomationPreference: String, Codable, Sendable {
    case minimal
    case balanced
    case aggressive
}

public struct NotificationSettings: Sendable, Codable, Hashable, Equatable {
    public let enablePushNotifications: Bool
    public let emailDigest: Bool
    public let criticalOnly: Bool

    public init(id _: UUID = UUID(),
                enablePushNotifications: Bool = true,
                emailDigest: Bool = false,
                criticalOnly: Bool = false) {
        self.enablePushNotifications = enablePushNotifications
        self.emailDigest = emailDigest
        self.criticalOnly = criticalOnly
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enablePushNotifications)
        hasher.combine(emailDigest)
        hasher.combine(criticalOnly)
    }

    public static func == (lhs: NotificationSettings, rhs: NotificationSettings) -> Bool {
        return lhs.enablePushNotifications == rhs.enablePushNotifications &&
            lhs.emailDigest == rhs.emailDigest &&
            lhs.criticalOnly == rhs.criticalOnly
    }
}

public struct PerformanceMetrics: Sendable, Codable, Hashable {
    public let accuracy: Double
    public let speed: Double
    public let compliance: Double
    public let userSatisfaction: Double

    public init(id _: UUID = UUID(), accuracy: Double, speed: Double, compliance: Double, userSatisfaction: Double) {
        self.accuracy = accuracy
        self.speed = speed
        self.compliance = compliance
        self.userSatisfaction = userSatisfaction
    }

    public var overall: Double {
        return (accuracy + speed + compliance + userSatisfaction) / 4.0
    }
}

// OrganizationalContext is imported from existing AppCore models

public struct BudgetInfo: Sendable, Codable {
    public let totalBudget: Double
    public let availableFunds: Double
    public let fiscalYear: String
    public let appropriation: String

    public init(id _: UUID = UUID(), totalBudget: Double, availableFunds: Double, fiscalYear: String, appropriation: String) {
        self.totalBudget = totalBudget
        self.availableFunds = availableFunds
        self.fiscalYear = fiscalYear
        self.appropriation = appropriation
    }
}

public struct PolicyRequirement: Sendable, Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let mandatory: Bool
    public let effectiveDate: Date

    public init(id: UUID = UUID(), title: String, description: String, mandatory: Bool, effectiveDate: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.mandatory = mandatory
        self.effectiveDate = effectiveDate
    }
}

public struct Stakeholder: Sendable, Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let role: String
    public let influence: InfluenceLevel
    public let contactInfo: String

    public init(id: UUID = UUID(), name: String, role: String, influence: InfluenceLevel, contactInfo: String) {
        self.id = id
        self.name = name
        self.role = role
        self.influence = influence
        self.contactInfo = contactInfo
    }
}

public enum InfluenceLevel: String, Codable, Sendable {
    case low
    case medium
    case high
    case critical
}

// AcquisitionPhase is imported from existing DocumentChain models

// CoreDataStack and service classes are defined in their respective files
// These types are just placeholders for testing

// MARK: - Feedback Types for AgenticOrchestrator

public struct AgenticUserFeedback: Sendable, Codable {
    public let id: UUID
    public let outcome: AgenticFeedbackOutcome
    public let satisfactionScore: Double
    public let workflowCompleted: Bool
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        outcome: AgenticFeedbackOutcome,
        satisfactionScore: Double,
        workflowCompleted: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.outcome = outcome
        self.satisfactionScore = satisfactionScore
        self.workflowCompleted = workflowCompleted
        self.timestamp = timestamp
    }
}

public enum AgenticFeedbackOutcome: String, Codable, Sendable {
    case success
    case failure
    case partial
    case abandoned
}

// Note: MockCoreDataStack, InteractionHistory, and InteractionOutcome are imported from existing files

// MARK: - Test Document Template

public struct TestDocumentTemplate: Sendable {
    public let id: UUID
    public let name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    public static let purchaseRequest = TestDocumentTemplate(name: "Purchase Request")
}

// Note: AutomationLevel is imported from FollowOnAction.swift

// MARK: - Test-specific Types

public enum TestDocumentType: String, Codable, Sendable, CaseIterable {
    case requestForProposal
    case sourceSelection
    case emergencyProcurement
    case purchaseRequest
    case contract
    case amendment
}

public struct TestComplexityLevel: Sendable, Codable {
    public let score: Double
    public let factors: [String]

    public init(score: Double, factors: [String]) {
        self.score = score
        self.factors = factors
    }
}

public struct TestFARClause: Sendable, Hashable, Codable {
    public let clauseNumber: String
    public let isCritical: Bool

    public init(clauseNumber: String, isCritical: Bool) {
        self.clauseNumber = clauseNumber
        self.isCritical = isCritical
    }
}

// MARK: - Test UserProfile

public struct TestUserProfile: Sendable, Codable {
    public let experienceLevel: Double

    public init(experienceLevel: Double) {
        self.experienceLevel = experienceLevel
    }
}

// MARK: - Test OrganizationalContext

public struct TestOrganizationalContext: Sendable {
    public let organization: String
    public let budget: BudgetInfo
    public let policies: [PolicyRequirement]
    public let stakeholders: [Stakeholder]

    public init(organization: String, budget: BudgetInfo, policies: [PolicyRequirement], stakeholders: [Stakeholder]) {
        self.organization = organization
        self.budget = budget
        self.policies = policies
        self.stakeholders = stakeholders
    }
}

// MARK: - Test TimeConstraints

public struct TestTimeConstraints: Sendable, Codable {
    public let daysRemaining: Int
    public let isUrgent: Bool
    public let expectedDuration: TimeInterval

    public init(daysRemaining: Int, isUrgent: Bool, expectedDuration: TimeInterval) {
        self.daysRemaining = daysRemaining
        self.isUrgent = isUrgent
        self.expectedDuration = expectedDuration
    }
}

// MARK: - Test Quality Metrics

public struct TestQualityMetrics: Sendable {
    public let accuracy: Double
    public let completeness: Double
    public let compliance: Double

    public init(accuracy: Double, completeness: Double, compliance: Double) {
        self.accuracy = accuracy
        self.completeness = completeness
        self.compliance = compliance
    }
}

// MARK: - Test Context Creation

public struct AcquisitionContext: Sendable, Codable {
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

    // Computed property for compatibility
    public var hash: Int {
        var hasher = Hasher()
        hasher.combine(acquisitionId)
        hasher.combine(documentType.rawValue)
        return hasher.finalize()
    }

    public init(acquisitionId: UUID, documentType: TestDocumentType, acquisitionValue: Double, complexity: TestComplexityLevel, timeConstraints: TestTimeConstraints, regulatoryRequirements: Set<TestFARClause>, historicalSuccess: Double, userProfile: TestUserProfile, workflowProgress: Double, completedDocuments: [String]) {
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

// Feature Vector and WorkflowContext/WorkflowState already exist in other files
