import AppCore
import ComposableArchitecture
import Foundation

// MARK: - Follow-On Action Service

/// Coordinates follow-on action generation and execution between LLM providers and acquisition features
@MainActor
public final class FollowOnActionService {
    // MARK: - Properties

    let llmManager: LLMManager
    let acquisitionService: AcquisitionService
    let taskQueueManager: TaskQueueManager
    let clock: any Clock<Duration>
    let uuid: () -> UUID

    /// Active follow-on action sets indexed by acquisition ID
    private var activeActionSets: [UUID: FollowOnActionSet] = [:]

    /// Completed actions indexed by acquisition ID
    private var completedActions: [UUID: Set<UUID>] = [:]

    /// Action execution status
    private var executionStatus: [UUID: ActionExecutionStatus] = [:]

    // MARK: - Initialization

    public init(
        llmManager: LLMManager,
        acquisitionService: AcquisitionService,
        taskQueueManager: TaskQueueManager,
        clock: any Clock<Duration>,
        uuid: @escaping () -> UUID
    ) {
        self.llmManager = llmManager
        self.acquisitionService = acquisitionService
        self.taskQueueManager = taskQueueManager
        self.clock = clock
        self.uuid = uuid
    }

    // MARK: - Public Methods

    /// Generate follow-on actions for the current acquisition context
    public func generateFollowOnActions(
        for acquisitionId: UUID,
        context: FollowOnActionContext
    ) async throws -> FollowOnActionSet {
        // Get the active LLM provider
        guard let provider = llmManager.activeProvider else {
            throw FollowOnActionError.noActiveProvider
        }

        // Generate actions using the LLM provider extension
        let actionSet = try await provider.generateFollowOnActions(context: context)

        // Store the action set
        activeActionSets[acquisitionId] = actionSet

        // Initialize tracking for this acquisition if needed
        if completedActions[acquisitionId] == nil {
            completedActions[acquisitionId] = []
        }

        // Analyze dependencies and create execution plan
        let executionPlan = createExecutionPlan(for: actionSet)

        // Store execution plan
        await storeExecutionPlan(acquisitionId: acquisitionId, plan: executionPlan)

        return actionSet
    }

    /// Execute a specific follow-on action
    public func executeAction(
        _ action: FollowOnAction,
        for acquisitionId: UUID
    ) async throws -> ActionExecutionResult {
        // Check dependencies
        guard areDependenciesSatisfied(for: action, acquisitionId: acquisitionId) else {
            throw FollowOnActionError.dependenciesNotSatisfied(action.dependencies)
        }

        // Update status
        executionStatus[action.id] = .executing

        do {
            // Execute based on automation level
            let result: ActionExecutionResult = switch action.automationLevel {
            case .manual:
                try await executeManualAction(action, acquisitionId: acquisitionId)
            case .semiAutomated:
                try await executeSemiAutomatedAction(action, acquisitionId: acquisitionId)
            case .fullyAutomated:
                try await executeFullyAutomatedAction(action, acquisitionId: acquisitionId)
            }

            // Mark as completed
            completedActions[acquisitionId]?.insert(action.id)
            executionStatus[action.id] = .completed(result)

            // Trigger dependent actions if any
            await triggerDependentActions(for: action, acquisitionId: acquisitionId)

            return result
        } catch {
            executionStatus[action.id] = .failed(error)
            throw error
        }
    }

    /// Get suggested actions for the current context
    public func getSuggestedActions(
        for acquisitionId: UUID,
        limit: Int = 5
    ) -> [FollowOnAction] {
        guard let actionSet = activeActionSets[acquisitionId] else {
            return []
        }

        let completed = completedActions[acquisitionId] ?? []

        // Filter available actions
        let availableActions = actionSet.actions.filter { action in
            !completed.contains(action.id) &&
                areDependenciesSatisfied(for: action, acquisitionId: acquisitionId)
        }

        // Sort by priority and recommended path
        let sortedActions = availableActions.sorted { a, b in
            // First check if in recommended path
            let aInPath = actionSet.recommendedPath?.contains(a.id) ?? false
            let bInPath = actionSet.recommendedPath?.contains(b.id) ?? false

            if aInPath != bInPath {
                return aInPath
            }

            // Then sort by priority
            return a.priority.rawValue > b.priority.rawValue
        }

        return Array(sortedActions.prefix(limit))
    }

    /// Create agent tasks from follow-on actions
    public func createAgentTasks(
        from actions: [FollowOnAction],
        for _: UUID
    ) -> [AgentTask] {
        actions.map { action in
            let agentAction = AgentAction(
                id: action.id,
                type: mapToAgentActionType(action.category),
                description: action.description,
                requiresApproval: action.requiresUserInput
            )

            return AgentTask(action: agentAction)
        }
    }

    /// Update action context based on new information
    public func updateContext(
        for acquisitionId: UUID,
        with updates: ContextUpdate
    ) async throws {
        guard let currentActionSet = activeActionSets[acquisitionId] else {
            return
        }

        // Create updated context
        let updatedContext = updates.apply(to: currentActionSet.context)

        // Regenerate actions if significant changes
        if updates.requiresRegeneration {
            let newActionSet = try await generateFollowOnActions(
                for: acquisitionId,
                context: updatedContext
            )

            // Merge with existing completed actions
            activeActionSets[acquisitionId] = mergeActionSets(
                current: currentActionSet,
                new: newActionSet,
                completed: completedActions[acquisitionId] ?? []
            )
        }
    }

    // MARK: - Private Methods

    private func areDependenciesSatisfied(
        for action: FollowOnAction,
        acquisitionId: UUID
    ) -> Bool {
        let completed = completedActions[acquisitionId] ?? []
        return action.dependencies.allSatisfy { completed.contains($0) }
    }

    private func createExecutionPlan(for actionSet: FollowOnActionSet) -> ActionExecutionPlan {
        var plan = ActionExecutionPlan()

        // Group actions by dependency level
        var levels: [[FollowOnAction]] = []
        var remaining = actionSet.actions
        var processed = Set<UUID>()

        while !remaining.isEmpty {
            let currentLevel = remaining.filter { action in
                action.dependencies.allSatisfy { processed.contains($0) }
            }

            if currentLevel.isEmpty {
                // Circular dependency or invalid state
                break
            }

            levels.append(currentLevel)
            currentLevel.forEach { processed.insert($0.id) }
            remaining.removeAll { currentLevel.contains($0) }
        }

        plan.executionLevels = levels
        plan.estimatedTotalDuration = actionSet.actions.reduce(0) { $0 + $1.estimatedDuration }
        plan.parallelizationOpportunities = identifyParallelizationOpportunities(levels: levels)

        return plan
    }

    private func identifyParallelizationOpportunities(levels: [[FollowOnAction]]) -> [ParallelizationOpportunity] {
        levels.enumerated().compactMap { index, level in
            guard level.count > 1 else { return nil }

            let parallelizable = level.filter { action in
                // Can parallelize if no shared resources and automation level allows
                action.automationLevel != .manual
            }

            guard parallelizable.count > 1 else { return nil }

            return ParallelizationOpportunity(
                level: index,
                actions: parallelizable.map(\.id),
                estimatedTimeSaving: calculateTimeSaving(actions: parallelizable)
            )
        }
    }

    private func calculateTimeSaving(actions: [FollowOnAction]) -> TimeInterval {
        let sequential = actions.reduce(0) { $0 + $1.estimatedDuration }
        let parallel = actions.map(\.estimatedDuration).max() ?? 0
        return sequential - parallel
    }

    private func executeManualAction(
        _ action: FollowOnAction,
        acquisitionId _: UUID
    ) async throws -> ActionExecutionResult {
        // Create a task for user to complete
        let userTask = UserTask(
            id: action.id,
            title: action.title,
            description: action.description,
            dueDate: Date().addingTimeInterval(action.estimatedDuration)
        )

        // Notify user
        await notifyUserOfManualTask(userTask)

        return ActionExecutionResult(
            actionId: action.id,
            status: .pendingUser,
            completedAt: Date(),
            output: "{\"taskId\":\"\(userTask.id.uuidString)\"}"
        )
    }

    private func executeSemiAutomatedAction(
        _ action: FollowOnAction,
        acquisitionId: UUID
    ) async throws -> ActionExecutionResult {
        // Prepare the action
        let preparation = try await prepareAction(action, acquisitionId: acquisitionId)

        if action.requiresUserInput {
            // Request approval
            let approvalRequest = ApprovalRequest(
                id: uuid(),
                message: "Ready to \(action.title). Review and approve to proceed.",
                action: AgentAction(
                    id: action.id,
                    type: mapToAgentActionType(action.category),
                    description: action.description,
                    requiresApproval: true
                ),
                impact: determineImpactLevel(action)
            )

            // Wait for approval (in real implementation)
            return ActionExecutionResult(
                actionId: action.id,
                status: .pendingApproval,
                completedAt: Date(),
                output: "{\"approvalRequestId\":\"\(approvalRequest.id.uuidString)\"}"
            )
        } else {
            // Execute directly
            return try await performAction(action, preparation: preparation)
        }
    }

    private func executeFullyAutomatedAction(
        _ action: FollowOnAction,
        acquisitionId: UUID
    ) async throws -> ActionExecutionResult {
        // Execute without user intervention
        let preparation = try await prepareAction(action, acquisitionId: acquisitionId)
        return try await performAction(action, preparation: preparation)
    }

    private func prepareAction(
        _ action: FollowOnAction,
        acquisitionId: UUID
    ) async throws -> ActionPreparation {
        // Gather necessary data
        guard let acquisition = try await acquisitionService.fetchAcquisition(acquisitionId) else {
            throw FollowOnActionError.invalidContext
        }

        return ActionPreparation(
            action: action,
            acquisitionData: acquisition,
            requiredDocuments: gatherRequiredDocuments(for: action, acquisition: acquisition),
            context: buildActionContext(action: action, acquisition: acquisition)
        )
    }

    private func performAction(
        _ action: FollowOnAction,
        preparation: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Route to appropriate handler based on category
        switch action.category {
        case .documentGeneration:
            try await handleDocumentGeneration(action, preparation: preparation)
        case .requirementGathering:
            try await handleRequirementGathering(action, preparation: preparation)
        case .vendorManagement:
            try await handleVendorManagement(action, preparation: preparation)
        case .reviewApproval:
            try await handleReviewApproval(action, preparation: preparation)
        case .complianceCheck:
            try await handleComplianceCheck(action, preparation: preparation)
        case .marketResearch:
            try await handleMarketResearch(action, preparation: preparation)
        case .riskAssessment:
            try await handleRiskAssessment(action, preparation: preparation)
        case .dataAnalysis:
            try await handleDataAnalysis(action, preparation: preparation)
        case .communication:
            try await handleCommunication(action, preparation: preparation)
        case .systemConfiguration:
            try await handleSystemConfiguration(action, preparation: preparation)
        }
    }

    private func triggerDependentActions(
        for completedAction: FollowOnAction,
        acquisitionId: UUID
    ) async {
        guard let actionSet = activeActionSets[acquisitionId] else { return }

        let dependentActions = actionSet.actions.filter { action in
            action.dependencies.contains(completedAction.id) &&
                areDependenciesSatisfied(for: action, acquisitionId: acquisitionId)
        }

        for action in dependentActions {
            if action.automationLevel == .fullyAutomated {
                // Queue for automatic execution
                Task {
                    try? await executeAction(action, for: acquisitionId)
                }
            } else {
                // Notify that action is now available
                await notifyActionAvailable(action)
            }
        }
    }

    // MARK: - Action Handlers

    private func handleDocumentGeneration(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Extract document types from metadata
        let documentTypes = action.metadata?.documentTypes ?? []

        // Generate documents
        var generatedDocuments: [String] = []
        for docType in documentTypes {
            // Call document generation service
            // This is a placeholder - integrate with actual service
            generatedDocuments.append("\(docType.rawValue) - Generated")
        }

        let documentsJson = try? JSONEncoder().encode(generatedDocuments)
        let documentsString = documentsJson.flatMap { String(data: $0, encoding: .utf8) }

        return ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: documentsString
        )
    }

    private func handleRequirementGathering(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Gather additional requirements
        // This would integrate with the chat interface

        ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: "{\"requirementsGathered\":true}"
        )
    }

    private func handleVendorManagement(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Vendor related actions

        ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: "{\"vendorsIdentified\":5}"
        )
    }

    private func handleReviewApproval(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Review and approval workflow

        ActionExecutionResult(
            actionId: action.id,
            status: .pendingApproval,
            completedAt: Date(),
            output: "{\"reviewRequestSent\":true}"
        )
    }

    private func handleComplianceCheck(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Compliance validation
        let complianceStandards = action.metadata?.complianceStandards ?? []

        let standardsJson = try? JSONEncoder().encode(complianceStandards)
        let standardsString = standardsJson.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        return ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: "{\"complianceChecked\":true,\"standards\":\(standardsString)}"
        )
    }

    private func handleMarketResearch(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Market research activities

        ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: "{\"marketDataCollected\":true}"
        )
    }

    private func handleRiskAssessment(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Risk assessment

        ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: "{\"risksIdentified\":3,\"mitigationPlanned\":true}"
        )
    }

    private func handleDataAnalysis(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Data analysis activities

        ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: "{\"dataAnalyzed\":true,\"insightsGenerated\":5}"
        )
    }

    private func handleCommunication(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // Communication activities

        ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: "{\"messagesSent\":true,\"recipients\":3}"
        )
    }

    private func handleSystemConfiguration(
        _ action: FollowOnAction,
        preparation _: ActionPreparation
    ) async throws -> ActionExecutionResult {
        // System configuration activities

        ActionExecutionResult(
            actionId: action.id,
            status: .completed,
            completedAt: Date(),
            output: "{\"systemConfigured\":true,\"settings\":\"updated\"}"
        )
    }

    // MARK: - Helper Methods

    private func mapToAgentActionType(_ category: ActionCategory) -> AgentAction.ActionType {
        switch category {
        case .documentGeneration:
            .generateDocuments
        case .vendorManagement:
            .identifyVendors
        case .reviewApproval:
            .submitForApproval
        case .complianceCheck:
            .monitorCompliance
        case .marketResearch:
            .gatherMarketResearch
        default:
            .gatherMarketResearch
        }
    }

    private func determineImpactLevel(_ action: FollowOnAction) -> ApprovalRequest.ImpactLevel {
        switch action.priority {
        case .critical:
            .high
        case .high:
            .medium
        default:
            .low
        }
    }

    private func gatherRequiredDocuments(
        for _: FollowOnAction,
        acquisition _: AppCore.Acquisition
    ) -> [GeneratedDocument] {
        // Gather relevant documents for the action
        []
    }

    private func buildActionContext(
        action: FollowOnAction,
        acquisition: AppCore.Acquisition
    ) -> [String: Any] {
        [
            "acquisitionId": acquisition.id.uuidString,
            "actionCategory": action.category.rawValue,
            "priority": action.priority.rawValue
        ]
    }

    private func mergeActionSets(
        current: FollowOnActionSet,
        new: FollowOnActionSet,
        completed: Set<UUID>
    ) -> FollowOnActionSet {
        // Keep completed actions and merge with new suggestions
        let completedActions = current.actions.filter { completed.contains($0.id) }
        let newActions = new.actions.filter { !completed.contains($0.id) }

        return FollowOnActionSet(
            context: new.context,
            actions: completedActions + newActions,
            recommendedPath: new.recommendedPath,
            expiresAt: new.expiresAt
        )
    }

    private func storeExecutionPlan(
        acquisitionId _: UUID,
        plan _: ActionExecutionPlan
    ) async {
        // Store plan for reference
        // Could persist to database or cache
    }

    private func notifyUserOfManualTask(_: UserTask) async {
        // Send notification to user
    }

    private func notifyActionAvailable(_: FollowOnAction) async {
        // Notify that action is ready
    }
}

// MARK: - Supporting Types

public enum FollowOnActionError: LocalizedError {
    case noActiveProvider
    case dependenciesNotSatisfied([UUID])
    case executionFailed(String)
    case invalidContext

    public var errorDescription: String? {
        switch self {
        case .noActiveProvider:
            "No active LLM provider configured"
        case let .dependenciesNotSatisfied(deps):
            "Dependencies not satisfied: \(deps.count) actions must complete first"
        case let .executionFailed(reason):
            "Action execution failed: \(reason)"
        case .invalidContext:
            "Invalid action context"
        }
    }
}

public enum ActionExecutionStatus {
    case pending
    case executing
    case completed(ActionExecutionResult)
    case failed(Error)
}

public struct ActionExecutionPlan {
    public var executionLevels: [[FollowOnAction]] = []
    public var estimatedTotalDuration: TimeInterval = 0
    public var parallelizationOpportunities: [ParallelizationOpportunity] = []
}

public struct ParallelizationOpportunity {
    public let level: Int
    public let actions: [UUID]
    public let estimatedTimeSaving: TimeInterval
}

public struct ContextUpdate {
    public let phase: AcquisitionPhase?
    public let completedDocuments: Set<DocumentType>?
    public let newRequirements: RequirementsData?
    public let userPreferences: UserPreferences?
    public let requiresRegeneration: Bool

    func apply(to _: String) -> FollowOnActionContext {
        // This would parse the context string and update it
        // For now, returning a placeholder
        FollowOnActionContext(
            currentPhase: phase ?? .planning,
            requirements: newRequirements ?? RequirementsData(),
            reviewMode: .iterative
        )
    }
}

public struct ActionPreparation {
    public let action: FollowOnAction
    public let acquisitionData: AppCore.Acquisition
    public let requiredDocuments: [GeneratedDocument]
    public let context: [String: Any]
}

public struct UserTask {
    public let id: UUID
    public let title: String
    public let description: String
    public let dueDate: Date
}

// MARK: - Dependency Registration

public extension DependencyValues {
    var followOnActionService: FollowOnActionService {
        get { self[FollowOnActionService.self] }
        set { self[FollowOnActionService.self] = newValue }
    }
}

extension FollowOnActionService: DependencyKey {
    public nonisolated static let liveValue: FollowOnActionService = {
        @MainActor
        func makeLiveValue() -> FollowOnActionService {
            FollowOnActionService(
                llmManager: LLMManager.shared,
                acquisitionService: AcquisitionService.liveValue,
                taskQueueManager: TaskQueueManagerKey.liveValue,
                clock: ContinuousClock(),
                uuid: { UUID() }
            )
        }

        return MainActor.assumeIsolated {
            makeLiveValue()
        }
    }()
}
