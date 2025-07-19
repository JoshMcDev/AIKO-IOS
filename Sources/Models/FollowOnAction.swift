import Foundation
import AppCore

// MARK: - Follow-On Action Model

/// Represents a suggested next action that the LLM recommends to the user
public struct FollowOnAction: Equatable, Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let category: ActionCategory
    public let priority: ActionPriority
    public let estimatedDuration: TimeInterval
    public let requiresUserInput: Bool
    public let automationLevel: AutomationLevel
    public let dependencies: [UUID] // IDs of other actions that must complete first
    public let metadata: ActionMetadata?
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: ActionCategory,
        priority: ActionPriority = .medium,
        estimatedDuration: TimeInterval = 300, // 5 minutes default
        requiresUserInput: Bool = true,
        automationLevel: AutomationLevel = .semiAutomated,
        dependencies: [UUID] = [],
        metadata: ActionMetadata? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.requiresUserInput = requiresUserInput
        self.automationLevel = automationLevel
        self.dependencies = dependencies
        self.metadata = metadata
    }
}

// MARK: - Supporting Types

/// Categories for follow-on actions
public enum ActionCategory: String, Codable, CaseIterable {
    case documentGeneration = "Document Generation"
    case requirementGathering = "Requirement Gathering"
    case vendorManagement = "Vendor Management"
    case complianceCheck = "Compliance Check"
    case marketResearch = "Market Research"
    case reviewApproval = "Review & Approval"
    case dataAnalysis = "Data Analysis"
    case communication = "Communication"
    case systemConfiguration = "System Configuration"
    case riskAssessment = "Risk Assessment"
}

/// Priority levels for actions
public enum ActionPriority: String, Codable, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    public var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

/// Level of automation for the action
public enum AutomationLevel: String, Codable {
    case manual = "Manual"
    case semiAutomated = "Semi-Automated"
    case fullyAutomated = "Fully Automated"
    
    public var description: String {
        switch self {
        case .manual:
            return "Requires full user involvement"
        case .semiAutomated:
            return "LLM assists but needs user decisions"
        case .fullyAutomated:
            return "LLM can complete autonomously"
        }
    }
}

/// Metadata for specific action types
public struct ActionMetadata: Equatable, Codable {
    public let documentTypes: [DocumentType]? // For document generation actions
    public let vendorIds: [UUID]? // For vendor-related actions
    public let complianceStandards: [String]? // For compliance actions
    public let dataSourceIds: [UUID]? // For data analysis actions
    public let recipientEmails: [String]? // For communication actions
    public let customData: [String: String]? // Flexible storage
    
    public init(
        documentTypes: [DocumentType]? = nil,
        vendorIds: [UUID]? = nil,
        complianceStandards: [String]? = nil,
        dataSourceIds: [UUID]? = nil,
        recipientEmails: [String]? = nil,
        customData: [String: String]? = nil
    ) {
        self.documentTypes = documentTypes
        self.vendorIds = vendorIds
        self.complianceStandards = complianceStandards
        self.dataSourceIds = dataSourceIds
        self.recipientEmails = recipientEmails
        self.customData = customData
    }
}

// MARK: - Follow-On Action Set

/// A collection of related follow-on actions for a specific context
public struct FollowOnActionSet: Equatable, Identifiable {
    public let id: UUID
    public let context: String // Description of when these actions apply
    public let actions: [FollowOnAction]
    public let recommendedPath: [UUID]? // Suggested order of action IDs
    public let expiresAt: Date? // When these recommendations are no longer valid
    
    public init(
        id: UUID = UUID(),
        context: String,
        actions: [FollowOnAction],
        recommendedPath: [UUID]? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.context = context
        self.actions = actions
        self.recommendedPath = recommendedPath
        self.expiresAt = expiresAt
    }
    
    /// Get actions sorted by priority and dependencies
    public var sortedActions: [FollowOnAction] {
        actions.sorted { lhs, rhs in
            // First sort by priority
            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }
            // Then by whether they have dependencies
            if lhs.dependencies.isEmpty != rhs.dependencies.isEmpty {
                return lhs.dependencies.isEmpty
            }
            // Finally by estimated duration (shorter first)
            return lhs.estimatedDuration < rhs.estimatedDuration
        }
    }
    
    /// Get actions that can be started immediately (no pending dependencies)
    public func availableActions(completedActionIds: Set<UUID>) -> [FollowOnAction] {
        actions.filter { action in
            action.dependencies.allSatisfy { completedActionIds.contains($0) }
        }
    }
}

// MARK: - Action Execution Result

/// Result of executing a follow-on action
public struct ActionExecutionResult: Equatable {
    public let actionId: UUID
    public let status: ExecutionStatus
    public let completedAt: Date
    public let output: String?
    public let generatedDocumentIds: [UUID]?
    public let nextActions: [FollowOnAction]? // New actions discovered during execution
    
    public enum ExecutionStatus: String, Codable {
        case completed = "Completed"
        case partiallyCompleted = "Partially Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
        case pendingUser = "Pending User"
        case pendingApproval = "Pending Approval"
    }
    
    public init(
        actionId: UUID,
        status: ExecutionStatus,
        completedAt: Date = Date(),
        output: String? = nil,
        generatedDocumentIds: [UUID]? = nil,
        nextActions: [FollowOnAction]? = nil
    ) {
        self.actionId = actionId
        self.status = status
        self.completedAt = completedAt
        self.output = output
        self.generatedDocumentIds = generatedDocumentIds
        self.nextActions = nextActions
    }
}