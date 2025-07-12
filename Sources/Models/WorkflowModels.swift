import Foundation

// MARK: - Workflow State

public enum WorkflowState: String, CaseIterable {
    case initial
    case gatheringRequirements = "gathering_requirements"
    case analyzingRequirements = "analyzing_requirements"
    case suggestingDocuments = "suggesting_documents"
    case collectingData = "collecting_data"
    case generatingDocuments = "generating_documents"
    case reviewingDocuments = "reviewing_documents"
    case finalizingDocuments = "finalizing_documents"
    case completed

    public var displayName: String {
        switch self {
        case .initial: "Initial"
        case .gatheringRequirements: "Gathering Requirements"
        case .analyzingRequirements: "Analyzing Requirements"
        case .suggestingDocuments: "Suggesting Documents"
        case .collectingData: "Collecting Data"
        case .generatingDocuments: "Generating Documents"
        case .reviewingDocuments: "Reviewing Documents"
        case .finalizingDocuments: "Finalizing Documents"
        case .completed: "Completed"
        }
    }

    public var nextStates: [WorkflowState] {
        switch self {
        case .initial:
            [.gatheringRequirements]
        case .gatheringRequirements:
            [.analyzingRequirements]
        case .analyzingRequirements:
            [.suggestingDocuments, .collectingData]
        case .suggestingDocuments:
            [.collectingData, .generatingDocuments]
        case .collectingData:
            [.generatingDocuments]
        case .generatingDocuments:
            [.reviewingDocuments, .collectingData]
        case .reviewingDocuments:
            [.finalizingDocuments, .generatingDocuments]
        case .finalizingDocuments:
            [.completed, .reviewingDocuments]
        case .completed:
            []
        }
    }
}

// MARK: - Collected Data

public struct CollectedData: Equatable, Codable {
    public var data: [String: String] = [:]

    public init(data: [String: String] = [:]) {
        self.data = data
    }

    public subscript(key: String) -> String? {
        get { data[key] }
        set { data[key] = newValue }
    }
}

// MARK: - Workflow Step

public struct WorkflowStep: Identifiable, Equatable {
    public let id = UUID()
    public let timestamp: Date
    public let state: WorkflowState
    public let action: String
    public let llmPrompt: String?
    public let userResponse: String?
    public let dataCollected: CollectedData?
    public let requiresApproval: Bool
    public let approvalStatus: ApprovalStatus?

    public init(
        timestamp: Date = Date(),
        state: WorkflowState,
        action: String,
        llmPrompt: String? = nil,
        userResponse: String? = nil,
        dataCollected: CollectedData? = nil,
        requiresApproval: Bool = false,
        approvalStatus: ApprovalStatus? = nil
    ) {
        self.timestamp = timestamp
        self.state = state
        self.action = action
        self.llmPrompt = llmPrompt
        self.userResponse = userResponse
        self.dataCollected = dataCollected
        self.requiresApproval = requiresApproval
        self.approvalStatus = approvalStatus
    }
}

// MARK: - Approval Status

public enum ApprovalStatus: String {
    case pending
    case approved
    case rejected
    case skipped
}

// MARK: - Automation Settings

public struct AutomationSettings: Equatable, Codable {
    public var enabled: Bool
    public var requireApprovalForDocumentGeneration: Bool
    public var requireApprovalForDataCollection: Bool
    public var requireApprovalForWorkflowTransitions: Bool
    public var autoSuggestNextSteps: Bool
    public var autoFillFromProfile: Bool
    public var autoFillFromPreviousDocuments: Bool

    public init(
        enabled: Bool = false,
        requireApprovalForDocumentGeneration: Bool = true,
        requireApprovalForDataCollection: Bool = false,
        requireApprovalForWorkflowTransitions: Bool = false,
        autoSuggestNextSteps: Bool = true,
        autoFillFromProfile: Bool = true,
        autoFillFromPreviousDocuments: Bool = true
    ) {
        self.enabled = enabled
        self.requireApprovalForDocumentGeneration = requireApprovalForDocumentGeneration
        self.requireApprovalForDataCollection = requireApprovalForDataCollection
        self.requireApprovalForWorkflowTransitions = requireApprovalForWorkflowTransitions
        self.autoSuggestNextSteps = autoSuggestNextSteps
        self.autoFillFromProfile = autoFillFromProfile
        self.autoFillFromPreviousDocuments = autoFillFromPreviousDocuments
    }
}

// MARK: - Document Dependency

public struct DocumentDependency: Identifiable, Equatable {
    public let id = UUID()
    public let sourceDocumentType: DocumentType
    public let targetDocumentType: DocumentType
    public let dataFields: [String] // Fields that flow from source to target
    public let isRequired: Bool

    public init(
        sourceDocumentType: DocumentType,
        targetDocumentType: DocumentType,
        dataFields: [String],
        isRequired: Bool = true
    ) {
        self.sourceDocumentType = sourceDocumentType
        self.targetDocumentType = targetDocumentType
        self.dataFields = dataFields
        self.isRequired = isRequired
    }
}

// MARK: - Workflow Context

public struct WorkflowContext: Equatable {
    public var acquisitionId: UUID
    public var currentState: WorkflowState
    public var workflowSteps: [WorkflowStep]
    public var automationSettings: AutomationSettings
    public var collectedData: CollectedData
    public var suggestedPrompts: [SuggestedPrompt]
    public var pendingApprovals: [WorkflowStep]

    public init(
        acquisitionId: UUID,
        currentState: WorkflowState = .initial,
        workflowSteps: [WorkflowStep] = [],
        automationSettings: AutomationSettings = AutomationSettings(),
        collectedData: CollectedData = CollectedData(),
        suggestedPrompts: [SuggestedPrompt] = [],
        pendingApprovals: [WorkflowStep] = []
    ) {
        self.acquisitionId = acquisitionId
        self.currentState = currentState
        self.workflowSteps = workflowSteps
        self.automationSettings = automationSettings
        self.collectedData = collectedData
        self.suggestedPrompts = suggestedPrompts
        self.pendingApprovals = pendingApprovals
    }
}

// MARK: - Suggested Prompt

public struct SuggestedPrompt: Identifiable, Equatable {
    public let id = UUID()
    public let prompt: String
    public let category: PromptCategory
    public let priority: PromptPriority
    public let dataToCollect: [String]
    public let nextState: WorkflowState?

    public enum PromptCategory: String {
        case dataCollection = "data_collection"
        case clarification
        case documentSelection = "document_selection"
        case approval
        case nextStep = "next_step"
    }

    public enum PromptPriority: Int {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3
    }

    public init(
        prompt: String,
        category: PromptCategory,
        priority: PromptPriority = .medium,
        dataToCollect: [String] = [],
        nextState: WorkflowState? = nil
    ) {
        self.prompt = prompt
        self.category = category
        self.priority = priority
        self.dataToCollect = dataToCollect
        self.nextState = nextState
    }
}

// MARK: - Document Generation Context

public struct DocumentGenerationContext: Equatable {
    public let documentType: DocumentType
    public let acquisitionData: CollectedData
    public let userProfileData: CollectedData
    public let previousDocumentsData: CollectedData
    public let templateVariables: [String: String]

    public init(
        documentType: DocumentType,
        acquisitionData: CollectedData,
        userProfileData: CollectedData,
        previousDocumentsData: CollectedData,
        templateVariables: [String: String]
    ) {
        self.documentType = documentType
        self.acquisitionData = acquisitionData
        self.userProfileData = userProfileData
        self.previousDocumentsData = previousDocumentsData
        self.templateVariables = templateVariables
    }
}
