import Foundation

public struct WorkflowEngineClient: Sendable {
    public var startWorkflow: @Sendable (UUID) async throws -> WorkflowContext
    public var loadWorkflow: @Sendable (UUID) async throws -> WorkflowContext
    public var updateWorkflowState: @Sendable (UUID, WorkflowState) async throws -> WorkflowContext
    public var collectData: @Sendable (UUID, CollectedData) async throws -> Void
    public var processLLMResponse: @Sendable (UUID, String, CollectedData) async throws -> WorkflowContext
    public var processApproval: @Sendable (UUID, UUID, ApprovalStatus) async throws -> WorkflowContext
    public var generatePrompts: @Sendable (WorkflowContext) async throws -> [SuggestedPrompt]
}

public extension WorkflowEngineClient {
    static let testValue = Self(
        startWorkflow: { _ in WorkflowContext() },
        loadWorkflow: { _ in WorkflowContext() },
        updateWorkflowState: { _, state in WorkflowContext(currentState: state) },
        collectData: { _, _ in },
        processLLMResponse: { _, _, _ in WorkflowContext() },
        processApproval: { _, _, _ in WorkflowContext() },
        generatePrompts: { _ in [] }
    )
}
