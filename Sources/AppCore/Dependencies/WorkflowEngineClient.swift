import ComposableArchitecture
import Foundation

@DependencyClient
public struct WorkflowEngineClient {
    public var startWorkflow: @Sendable (UUID) async throws -> WorkflowContext
    public var loadWorkflow: @Sendable (UUID) async throws -> WorkflowContext
    public var updateWorkflowState: @Sendable (UUID, WorkflowState) async throws -> WorkflowContext
    public var collectData: @Sendable (UUID, CollectedData) async throws -> Void
    public var processLLMResponse: @Sendable (UUID, String, CollectedData) async throws -> WorkflowContext
    public var processApproval: @Sendable (UUID, UUID, ApprovalStatus) async throws -> WorkflowContext
    public var generatePrompts: @Sendable (WorkflowContext) async throws -> [SuggestedPrompt]
}

extension WorkflowEngineClient: TestDependencyKey {
    public static let testValue = Self()
}

public extension DependencyValues {
    var workflowEngine: WorkflowEngineClient {
        get { self[WorkflowEngineClient.self] }
        set { self[WorkflowEngineClient.self] = newValue }
    }
}
