import Foundation

// Workflow-related types that are platform-agnostic
public struct WorkflowContext: Equatable {
    public var currentState: WorkflowState
    public var collectedData: CollectedData
    public var suggestedPrompts: [SuggestedPrompt]
    public var pendingApprovals: [WorkflowStep]
    public var automationSettings: AutomationSettings
    
    public init(
        currentState: WorkflowState = .notStarted,
        collectedData: CollectedData = CollectedData(),
        suggestedPrompts: [SuggestedPrompt] = [],
        pendingApprovals: [WorkflowStep] = [],
        automationSettings: AutomationSettings = AutomationSettings()
    ) {
        self.currentState = currentState
        self.collectedData = collectedData
        self.suggestedPrompts = suggestedPrompts
        self.pendingApprovals = pendingApprovals
        self.automationSettings = automationSettings
    }
}

public enum WorkflowState: String, Equatable, Codable {
    case notStarted
    case gatheringRequirements
    case analyzingRequirements
    case selectingDocuments
    case collectingData
    case generatingDocuments
    case reviewingDocuments
    case completed
}

public struct CollectedData: Equatable, Codable {
    public var data: [String: String]
    
    public init(data: [String: String] = [:]) {
        self.data = data
    }
}

public struct SuggestedPrompt: Identifiable, Equatable {
    public let id = UUID()
    public let prompt: String
    public let category: PromptCategory
    public let nextState: WorkflowState?
    
    public init(prompt: String, category: PromptCategory, nextState: WorkflowState? = nil) {
        self.prompt = prompt
        self.category = category
        self.nextState = nextState
    }
}

public enum PromptCategory: String, Equatable {
    case nextStep
    case documentSelection
    case dataCollection
    case approval
    case clarification
}

public struct WorkflowStep: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let requiredApproval: Bool
    
    public init(title: String, description: String, requiredApproval: Bool = false) {
        self.title = title
        self.description = description
        self.requiredApproval = requiredApproval
    }
}

public struct AutomationSettings: Equatable, Codable {
    public var autoProgressEnabled: Bool
    public var skipApprovals: Bool
    public var useDefaults: Bool
    
    public init(
        autoProgressEnabled: Bool = false,
        skipApprovals: Bool = false,
        useDefaults: Bool = true
    ) {
        self.autoProgressEnabled = autoProgressEnabled
        self.skipApprovals = skipApprovals
        self.useDefaults = useDefaults
    }
}

public enum ApprovalStatus: String, Equatable {
    case approved
    case rejected
    case pending
}

public protocol WorkflowEngineProtocol {
    func startWorkflow(_ acquisitionId: UUID) async throws -> WorkflowContext
    func loadWorkflow(_ acquisitionId: UUID) async throws -> WorkflowContext
    func updateWorkflowState(_ acquisitionId: UUID, _ newState: WorkflowState) async throws -> WorkflowContext
    func collectData(_ acquisitionId: UUID, _ data: CollectedData) async throws
    func processLLMResponse(_ acquisitionId: UUID, _ response: String, _ extractedData: CollectedData) async throws -> WorkflowContext
    func processApproval(_ acquisitionId: UUID, _ stepId: UUID, _ status: ApprovalStatus) async throws -> WorkflowContext
    func generatePrompts(_ context: WorkflowContext) async throws -> [SuggestedPrompt]
}
