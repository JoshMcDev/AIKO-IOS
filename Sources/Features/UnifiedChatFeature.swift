import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - Unified Chat Feature

@Reducer
public struct UnifiedChatFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        // Mode Management
        var currentMode: ChatMode = .guided
        var modeTransitionState: ModeTransitionState = .stable
        var pendingModeTransition: ChatMode?

        // Child Feature States
        var acquisitionState: AcquisitionChatFeature.State?
        var agenticState: AgenticChatFeature.State?

        // Unified View
        var unifiedMessages: IdentifiedArrayOf<UnifiedMessage> = []
        var sharedContext: SharedChatContext
        var activeWorkflow: UnifiedWorkflowState?

        // UI State
        var showModeTransitionConfirmation: Bool = false
        var modeTransitionReason: String = ""
        var isTransitioning: Bool = false

        public init(
            initialMode: ChatMode = .guided,
            sharedContext: SharedChatContext = SharedChatContext()
        ) {
            currentMode = initialMode
            self.sharedContext = sharedContext

            // Initialize appropriate child state
            switch initialMode {
            case .guided:
                acquisitionState = AcquisitionChatFeature.State()
            case .agentic:
                agenticState = AgenticChatFeature.State()
            case .hybrid:
                acquisitionState = AcquisitionChatFeature.State()
                agenticState = AgenticChatFeature.State()
            }
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)

        // Mode Management
        case setMode(ChatMode)
        case requestModeTransition(to: ChatMode, reason: String)
        case confirmModeTransition
        case cancelModeTransition
        case modeTransitionCompleted

        // Child Feature Actions
        case acquisition(AcquisitionChatFeature.Action)
        case agentic(AgenticChatFeature.Action)

        // Unified Actions
        case sendMessage(String)
        case messageReceived(UnifiedMessage)
        case contextUpdated(SharedChatContext.Update)
        case workflowStateChanged(UnifiedWorkflowState?)

        // Context Synchronization
        case syncContextToChildren
        case childContextChanged(ChildContext)

        // Follow-on Actions
        case followOnActionsReceived(FollowOnActionSet)
        case executeFollowOnAction(FollowOnAction)
        case followOnActionCompleted(UUID, ActionExecutionResult)
        case dismissFollowOnAction(UUID)
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    @Dependency(\.mainQueue) var mainQueue

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            // MARK: - Mode Management

            case let .setMode(mode):
                guard validateModeTransition(from: state.currentMode, to: mode, state: state) else {
                    return .none
                }

                return performModeTransition(to: mode, state: &state)

            case let .requestModeTransition(to: mode, reason: reason):
                guard validateModeTransition(from: state.currentMode, to: mode, state: state) else {
                    return .none
                }

                state.pendingModeTransition = mode
                state.modeTransitionReason = reason
                state.showModeTransitionConfirmation = true
                return .none

            case .confirmModeTransition:
                guard let pendingMode = state.pendingModeTransition else { return .none }

                state.showModeTransitionConfirmation = false
                state.pendingModeTransition = nil

                return performModeTransition(to: pendingMode, state: &state)

            case .cancelModeTransition:
                state.showModeTransitionConfirmation = false
                state.pendingModeTransition = nil
                state.modeTransitionReason = ""
                return .none

            case .modeTransitionCompleted:
                state.isTransitioning = false
                state.modeTransitionState = .stable
                return .none

            // MARK: - Child Feature Actions

            case let .acquisition(childAction):
                return handleAcquisitionAction(childAction, state: &state)

            case let .agentic(childAction):
                return handleAgenticAction(childAction, state: &state)

            // MARK: - Unified Actions

            case let .sendMessage(text):
                return handleUnifiedSendMessage(text, state: &state)

            case let .messageReceived(message):
                state.unifiedMessages.append(message)
                return .none

            case let .contextUpdated(update):
                state.sharedContext.apply(update)
                return .send(.syncContextToChildren)

            case let .workflowStateChanged(workflow):
                state.activeWorkflow = workflow
                return .none

            // MARK: - Context Synchronization

            case .syncContextToChildren:
                return syncContextToChildren(state: state)

            case let .childContextChanged(childContext):
                return handleChildContextChange(childContext, state: &state)

            // MARK: - Follow-on Actions

            case let .followOnActionsReceived(actionSet):
                // Update shared context with new follow-on actions
                state.sharedContext.followOnActions = actionSet.actions
                return .none

            case let .executeFollowOnAction(action):
                // Route to appropriate child feature based on action type
                switch state.currentMode {
                case .guided:
                    return .send(.acquisition(.executeFollowOnAction(action)))
                case .agentic:
                    return .send(.agentic(.executeAction(convertToAgentAction(action))))
                case .hybrid:
                    // Determine based on action category
                    if isAgenticActionCategory(action.category) {
                        return .send(.agentic(.executeAction(convertToAgentAction(action))))
                    } else {
                        return .send(.acquisition(.executeFollowOnAction(action)))
                    }
                }

            case let .followOnActionCompleted(actionId, _):
                // Update action status in shared context
                if let index = state.sharedContext.followOnActions.firstIndex(where: { $0.id == actionId }) {
                    var updatedActions = state.sharedContext.followOnActions
                    // Mark action as completed
                    updatedActions.remove(at: index)
                    state.sharedContext.followOnActions = updatedActions
                }
                return .none

            case let .dismissFollowOnAction(actionId):
                // Remove action from shared context
                state.sharedContext.followOnActions.removeAll { $0.id == actionId }
                return .none
            }
        }
        .ifLet(\.acquisitionState, action: \.acquisition) {
            AcquisitionChatFeature()
        }
        .ifLet(\.agenticState, action: \.agentic) {
            AgenticChatFeature()
        }
    }

    // MARK: - Private Methods

    private func validateModeTransition(
        from current: ChatMode,
        to target: ChatMode,
        state: State
    ) -> Bool {
        // Don't allow transition if already transitioning
        guard state.modeTransitionState == .stable else { return false }

        // Don't transition to same mode
        guard current != target else { return false }

        // Validate specific transitions
        switch (current, target) {
        case (.guided, .agentic):
            // Can only transition to agentic if requirements are gathered
            return state.acquisitionState?.currentPhase == .readyToGenerate

        case (.guided, .hybrid):
            // Can transition to hybrid if we have some requirements
            return state.acquisitionState?.currentPhase == .analyzingRequirements ||
                state.acquisitionState?.currentPhase == .confirmingPredictions ||
                state.acquisitionState?.currentPhase == .readyToGenerate

        case (.agentic, .guided):
            // Can always go back to guided mode
            return true

        case (.agentic, .hybrid):
            // Can transition to hybrid if not actively executing
            return state.agenticState?.agentState != .executing

        case (.hybrid, .guided), (.hybrid, .agentic):
            // Can transition from hybrid to any mode
            return true

        case (.guided, .guided), (.agentic, .agentic), (.hybrid, .hybrid):
            // Already in target mode
            return true
        }
    }

    private func performModeTransition(
        to targetMode: ChatMode,
        state: inout State
    ) -> Effect<Action> {
        state.isTransitioning = true
        state.modeTransitionState = .transitioning(from: state.currentMode, to: targetMode)

        // Prepare context handoff
        let contextHandoff = prepareContextHandoff(from: state.currentMode, to: targetMode, state: state)

        // Initialize target mode state if needed
        switch targetMode {
        case .guided:
            if state.acquisitionState == nil {
                state.acquisitionState = AcquisitionChatFeature.State()
            }

        case .agentic:
            if state.agenticState == nil {
                state.agenticState = AgenticChatFeature.State()
            }

        case .hybrid:
            if state.acquisitionState == nil {
                state.acquisitionState = AcquisitionChatFeature.State()
            }
            if state.agenticState == nil {
                state.agenticState = AgenticChatFeature.State()
            }
        }

        // Update current mode
        state.currentMode = targetMode

        // Apply context handoff
        applyContextHandoff(contextHandoff, to: targetMode, state: &state)

        // Complete transition after animation
        return .run { send in
            try await clock.sleep(for: .milliseconds(300))
            await send(.modeTransitionCompleted)
        }
    }

    private func prepareContextHandoff(
        from currentMode: ChatMode,
        to _: ChatMode,
        state: State
    ) -> ContextHandoff {
        var handoff = ContextHandoff()

        // Extract context from current mode
        switch currentMode {
        case .guided:
            if let acquisition = state.acquisitionState {
                handoff.requirements = acquisition.gatheredRequirements
                handoff.acquisitionPhase = acquisition.currentPhase
                handoff.messages = acquisition.messages.map { msg in
                    let role: MessageRole = msg.role == AcquisitionChatFeature.MessageRole.user ? .user : .assistant
                    return UnifiedMessage(
                        id: msg.id,
                        role: role,
                        content: msg.content,
                        timestamp: msg.timestamp,
                        sourceMode: .guided,
                        metadata: ["phase": String(describing: acquisition.currentPhase)]
                    )
                }
            }

        case .agentic:
            if let agentic = state.agenticState {
                handoff.activeIntent = agentic.currentIntent
                handoff.agentState = agentic.agentState
                handoff.messages = agentic.messages.map { msg in
                    UnifiedMessage(
                        id: msg.id,
                        role: msg.role,
                        content: msg.content,
                        timestamp: msg.timestamp,
                        sourceMode: .agentic,
                        metadata: ["isStatus": msg.isStatus]
                    )
                }
            }

        case .hybrid:
            // Combine context from both modes
            handoff = combineHybridContext(state: state)
        }

        // Add shared context
        handoff.sharedContext = state.sharedContext
        handoff.activeWorkflow = state.activeWorkflow

        return handoff
    }

    private func applyContextHandoff(
        _ handoff: ContextHandoff,
        to targetMode: ChatMode,
        state: inout State
    ) {
        switch targetMode {
        case .guided:
            if var acquisition = state.acquisitionState {
                // Apply relevant context to guided mode
                if let requirements = handoff.requirements {
                    acquisition.gatheredRequirements = requirements
                }

                // Convert relevant messages
                let guidedMessages = handoff.messages
                    .filter { $0.sourceMode == .guided || $0.role == .user }
                    .map { unifiedMsg in
                        let role: AcquisitionChatFeature.MessageRole = unifiedMsg.role == .user ? .user : .assistant
                        return AcquisitionChatFeature.ChatMessage(
                            role: role,
                            content: unifiedMsg.content,
                            timestamp: unifiedMsg.timestamp
                        )
                    }

                acquisition.messages = guidedMessages
                state.acquisitionState = acquisition
            }

        case .agentic:
            if var agentic = state.agenticState {
                // Apply relevant context to agentic mode
                if let intent = handoff.activeIntent {
                    agentic.currentIntent = intent
                }

                // Convert relevant messages
                let agenticMessages = handoff.messages
                    .filter { $0.sourceMode == .agentic || $0.role == .user }
                    .map { unifiedMsg in
                        ChatMessage(
                            id: unifiedMsg.id,
                            role: unifiedMsg.role,
                            content: unifiedMsg.content,
                            timestamp: unifiedMsg.timestamp
                        )
                    }

                agentic.messages = IdentifiedArray(uniqueElements: agenticMessages)
                state.agenticState = agentic
            }

        case .hybrid:
            // Apply context to both child modes
            applyHybridContext(handoff, state: &state)
        }
    }

    private func handleAcquisitionAction(
        _ action: AcquisitionChatFeature.Action,
        state: inout State
    ) -> Effect<Action> {
        // Monitor for state changes that might trigger mode transitions
        switch action {
        case .phaseChanged(.readyToGenerate):
            // Acquisition is ready, suggest transition to agentic mode
            return .send(.requestModeTransition(
                to: .agentic,
                reason: "Requirements gathering complete. Ready to execute tasks?"
            ))

        case .addAssistantMessage:
            // Sync message to unified view
            if let acquisition = state.acquisitionState,
               let lastMessage = acquisition.messages.last
            {
                let role: MessageRole = lastMessage.role == AcquisitionChatFeature.MessageRole.user ? .user : .assistant
                let unifiedMsg = UnifiedMessage(
                    id: lastMessage.id,
                    role: role,
                    content: lastMessage.content,
                    timestamp: lastMessage.timestamp,
                    sourceMode: .guided
                )
                return .send(.messageReceived(unifiedMsg))
            }

        default:
            break
        }

        return .none
    }

    private func handleAgenticAction(
        _ action: AgenticChatFeature.Action,
        state: inout State
    ) -> Effect<Action> {
        // Monitor for state changes that might require mode transitions
        switch action {
        case .agentRequestsApproval:
            // In hybrid mode, this is normal. In pure agentic, might suggest hybrid
            if state.currentMode == .agentic {
                return .send(.requestModeTransition(
                    to: .hybrid,
                    reason: "Agent needs additional input. Switch to hybrid mode?"
                ))
            }

        case .messageReceived:
            // Sync message to unified view
            if let agentic = state.agenticState,
               let lastMessage = agentic.messages.last
            {
                let unifiedMsg = UnifiedMessage(
                    id: lastMessage.id,
                    role: lastMessage.role,
                    content: lastMessage.content,
                    timestamp: lastMessage.timestamp,
                    sourceMode: .agentic
                )
                return .send(.messageReceived(unifiedMsg))
            }

        default:
            break
        }

        return .none
    }

    private func handleUnifiedSendMessage(
        _ text: String,
        state: inout State
    ) -> Effect<Action> {
        // Route message to appropriate child feature based on current mode
        switch state.currentMode {
        case .guided:
            .send(.acquisition(.sendMessage))

        case .agentic:
            .send(.agentic(.sendMessage))

        case .hybrid:
            // Determine which feature should handle based on content
            if isAgenticCommand(text) {
                .send(.agentic(.sendMessage))
            } else {
                .send(.acquisition(.sendMessage))
            }
        }
    }

    private func syncContextToChildren(state _: State) -> Effect<Action> {
        let effects: [Effect<Action>] = []

        // Context sync handled through state updates
        // Child features will react to state changes automatically

        return .merge(effects)
    }

    private func handleChildContextChange(
        _ childContext: ChildContext,
        state: inout State
    ) -> Effect<Action> {
        // Update shared context based on child changes
        switch childContext.source {
        case .acquisition:
            if let requirements = childContext.data["requirements"] as? AcquisitionChatFeature.RequirementsData {
                state.sharedContext.requirements = requirements
            }

        case .agentic:
            if let taskStatus = childContext.data["taskStatus"] as? String {
                state.sharedContext.currentTaskStatus = taskStatus
            }
        }

        return .send(.contextUpdated(.fromChild(childContext)))
    }

    // MARK: - Helper Methods

    private func isAgenticCommand(_ text: String) -> Bool {
        let agenticKeywords = ["execute", "run", "perform", "start task", "begin"]
        return agenticKeywords.contains { text.lowercased().contains($0) }
    }

    private func convertToAgentAction(_ followOnAction: FollowOnAction) -> AgentAction {
        AgentAction(
            id: followOnAction.id,
            type: mapFollowOnCategoryToAgentType(followOnAction.category),
            description: followOnAction.description,
            requiresApproval: followOnAction.requiresUserInput
        )
    }

    private func mapFollowOnCategoryToAgentType(_ category: ActionCategory) -> AgentAction.ActionType {
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

    private func isAgenticActionCategory(_ category: ActionCategory) -> Bool {
        switch category {
        case .documentGeneration, .vendorManagement, .complianceCheck, .marketResearch,
             .dataAnalysis, .communication, .systemConfiguration:
            true
        case .requirementGathering, .reviewApproval, .riskAssessment:
            false
        }
    }

    private func combineHybridContext(state: State) -> ContextHandoff {
        var handoff = ContextHandoff()

        if let acquisition = state.acquisitionState {
            handoff.requirements = acquisition.gatheredRequirements
            handoff.acquisitionPhase = acquisition.currentPhase
        }

        if let agentic = state.agenticState {
            handoff.activeIntent = agentic.currentIntent
            handoff.agentState = agentic.agentState
        }

        // Merge messages from both modes
        var allMessages: [UnifiedMessage] = []

        if let acquisitionMessages = state.acquisitionState?.messages {
            allMessages.append(contentsOf: acquisitionMessages.map { msg in
                let role: MessageRole = msg.role == AcquisitionChatFeature.MessageRole.user ? .user : .assistant
                return UnifiedMessage(
                    id: msg.id,
                    role: role,
                    content: msg.content,
                    timestamp: msg.timestamp,
                    sourceMode: .guided
                )
            })
        }

        if let agenticMessages = state.agenticState?.messages {
            allMessages.append(contentsOf: agenticMessages.map { msg in
                UnifiedMessage(
                    id: msg.id,
                    role: msg.role,
                    content: msg.content,
                    timestamp: msg.timestamp,
                    sourceMode: .agentic
                )
            })
        }

        handoff.messages = allMessages.sorted { $0.timestamp < $1.timestamp }
        handoff.sharedContext = state.sharedContext
        handoff.activeWorkflow = state.activeWorkflow

        return handoff
    }

    private func applyHybridContext(_ handoff: ContextHandoff, state: inout State) {
        // Apply to acquisition state
        if var acquisition = state.acquisitionState {
            if let requirements = handoff.requirements {
                acquisition.gatheredRequirements = requirements
            }
            state.acquisitionState = acquisition
        }

        // Apply to agentic state
        if var agentic = state.agenticState {
            if let intent = handoff.activeIntent {
                agentic.currentIntent = intent
            }
            state.agenticState = agentic
        }
    }
}

// MARK: - Supporting Types

public struct UnifiedUserPreferences: Equatable {
    public var preferredMode: ChatMode?
    public var autoTransition: Bool = true
    public var notificationSettings: NotificationSettings = .init()

    public struct NotificationSettings: Equatable {
        public var enabled: Bool = true
        public var actionSuggestions: Bool = true
        public var statusUpdates: Bool = true
    }
}

public enum ChatMode: String, CaseIterable, Equatable {
    case guided = "Guided"
    case agentic = "Agentic"
    case hybrid = "Hybrid"

    var icon: String {
        switch self {
        case .guided: "questionmark.circle"
        case .agentic: "bolt.circle"
        case .hybrid: "arrow.triangle.2.circlepath.circle"
        }
    }

    var description: String {
        switch self {
        case .guided:
            "Step-by-step requirement gathering"
        case .agentic:
            "Autonomous task execution"
        case .hybrid:
            "Combined guided and autonomous operation"
        }
    }
}

public enum ModeTransitionState: Equatable {
    case stable
    case transitioning(from: ChatMode, to: ChatMode)
    case error(String)
}

public struct SharedChatContext: Equatable {
    public var acquisitionId: UUID?
    public var requirements: AcquisitionChatFeature.RequirementsData?
    public var activePhase: AcquisitionChatFeature.ChatPhase?
    public var currentTaskStatus: String?
    public var userPreferences: UnifiedUserPreferences?
    public var followOnActions: [FollowOnAction] = []

    public init(
        acquisitionId: UUID? = nil,
        requirements: AcquisitionChatFeature.RequirementsData? = nil,
        activePhase: AcquisitionChatFeature.ChatPhase? = nil,
        currentTaskStatus: String? = nil,
        userPreferences: UnifiedUserPreferences? = nil,
        followOnActions: [FollowOnAction] = []
    ) {
        self.acquisitionId = acquisitionId
        self.requirements = requirements
        self.activePhase = activePhase
        self.currentTaskStatus = currentTaskStatus
        self.userPreferences = userPreferences
        self.followOnActions = followOnActions
    }

    public enum Update {
        case requirements(AcquisitionChatFeature.RequirementsData)
        case phase(AcquisitionChatFeature.ChatPhase)
        case taskStatus(String)
        case preferences(UnifiedUserPreferences)
        case followOnActions([FollowOnAction])
        case fromChild(ChildContext)
    }

    mutating func apply(_ update: Update) {
        switch update {
        case let .requirements(data):
            requirements = data
        case let .phase(phase):
            activePhase = phase
        case let .taskStatus(status):
            currentTaskStatus = status
        case let .preferences(prefs):
            userPreferences = prefs
        case let .followOnActions(actions):
            followOnActions = actions
        case let .fromChild(context):
            // Apply child context updates
            if let requirements = context.data["requirements"] as? AcquisitionChatFeature.RequirementsData {
                self.requirements = requirements
            }
            if let phase = context.data["phase"] as? AcquisitionChatFeature.ChatPhase {
                activePhase = phase
            }
        }
    }
}

public struct UnifiedMessage: Equatable, Identifiable {
    public let id: UUID
    public let role: MessageRole
    public let content: String
    public let timestamp: Date
    public let sourceMode: ChatMode
    public var metadata: [String: Any]

    public init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        sourceMode: ChatMode,
        metadata: [String: Any] = [:]
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.sourceMode = sourceMode
        self.metadata = metadata
    }

    public static func == (lhs: UnifiedMessage, rhs: UnifiedMessage) -> Bool {
        lhs.id == rhs.id &&
            lhs.role == rhs.role &&
            lhs.content == rhs.content &&
            lhs.timestamp == rhs.timestamp &&
            lhs.sourceMode == rhs.sourceMode
    }
}

public struct UnifiedWorkflowState: Equatable {
    public let id: UUID
    public let type: WorkflowType
    public let status: WorkflowStatus
    public let progress: Double
    public var activeSteps: [WorkflowStep]

    public enum WorkflowType {
        case acquisition
        case documentGeneration
        case vendorEvaluation
        case compliance
    }

    public enum WorkflowStatus {
        case notStarted
        case inProgress
        case paused
        case completed
        case failed
    }

    public struct WorkflowStep: Equatable {
        public let id: UUID
        public let title: String
        public let status: WorkflowStatus
    }
}

// MARK: - Private Types

private struct ContextHandoff {
    var requirements: AcquisitionChatFeature.RequirementsData?
    var acquisitionPhase: AcquisitionChatFeature.ChatPhase?
    var activeIntent: AcquisitionIntent?
    var agentState: AgentState?
    var messages: [UnifiedMessage] = []
    var sharedContext: SharedChatContext?
    var activeWorkflow: UnifiedWorkflowState?
}

public struct ChildContext: Equatable {
    let source: Source
    let data: [String: Any]

    public enum Source: Equatable {
        case acquisition
        case agentic
    }

    public static func == (lhs: ChildContext, rhs: ChildContext) -> Bool {
        lhs.source == rhs.source
        // Note: data comparison omitted due to [String: Any]
    }
}

// MARK: - View

public struct UnifiedChatView: View {
    @Perception.Bindable var store: StoreOf<UnifiedChatFeature>

    public init(store: StoreOf<UnifiedChatFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Mode Selection Header
            ModeSelectionHeader(store: store)
                .transition(.move(edge: .top).combined(with: .opacity))

            // Main Chat Area
            ChatContentArea(store: store)
                .transition(.opacity)

            // Follow-on Actions View
            if !store.sharedContext.followOnActions.isEmpty {
                FollowOnActionsView(store: store)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Input Bar
            UnifiedInputBar(store: store)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.currentMode)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.sharedContext.followOnActions.isEmpty)
        .sheet(isPresented: $store.showModeTransitionConfirmation) {
            ModeTransitionConfirmationView(store: store)
        }
    }
}

struct ModeSelectionHeader: View {
    let store: StoreOf<UnifiedChatFeature>

    var body: some View {
        HStack(spacing: 16) {
            ForEach(ChatMode.allCases, id: \.self) { mode in
                ModeButton(
                    mode: mode,
                    isSelected: store.currentMode == mode,
                    isTransitioning: store.isTransitioning
                ) {
                    store.send(.setMode(mode))
                }
            }
        }
        .padding()
        .background(Color(red: 0.97, green: 0.97, blue: 0.99))
    }
}

struct ModeButton: View {
    let mode: ChatMode
    let isSelected: Bool
    let isTransitioning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(mode.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.blue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .disabled(isTransitioning)
        .opacity(isTransitioning ? 0.6 : 1.0)
    }
}

struct ChatContentArea: View {
    let store: StoreOf<UnifiedChatFeature>

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.unifiedMessages) { message in
                        UnifiedMessageView(message: message, mode: store.currentMode)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: store.unifiedMessages.count) { _ in
                withAnimation {
                    proxy.scrollTo(store.unifiedMessages.last?.id)
                }
            }
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
    }
}

struct UnifiedMessageView: View {
    let message: UnifiedMessage
    let mode: ChatMode

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Mode indicator for messages from other modes
                if message.sourceMode != mode, message.role != .user {
                    Text("From \(message.sourceMode.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }

                // Message content
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? Color.blue
                            : Color(red: 0.92, green: 0.92, blue: 0.94)
                    )
                    .foregroundColor(
                        message.role == .user
                            ? .white
                            : .primary
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

struct UnifiedInputBar: View {
    @Perception.Bindable var store: StoreOf<UnifiedChatFeature>
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Mode-specific hints
            if store.currentMode == .hybrid {
                HybridModeHint()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            // Input field
            HStack(spacing: 12) {
                TextField(
                    "",
                    text: $inputText,
                    prompt: Text(placeholderText).foregroundColor(.gray),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.92, green: 0.92, blue: 0.94))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isFocused)
                .onSubmit {
                    if !inputText.isEmpty {
                        store.send(.sendMessage(inputText))
                        inputText = ""
                    }
                }

                Button(action: {
                    if !inputText.isEmpty {
                        store.send(.sendMessage(inputText))
                        inputText = ""
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty ? .gray : .blue)
                }
                .disabled(inputText.isEmpty)
            }
            .padding()
            .background(Color(red: 0.97, green: 0.97, blue: 0.99))
        }
    }

    var placeholderText: String {
        switch store.currentMode {
        case .guided:
            "Describe your requirements..."
        case .agentic:
            "What task should I execute?"
        case .hybrid:
            "Ask questions or give commands..."
        }
    }
}

struct HybridModeHint: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)

            Text("Use keywords like 'execute' or 'run' for agent commands")
                .font(.caption)

            Spacer()
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

struct ModeTransitionConfirmationView: View {
    let store: StoreOf<UnifiedChatFeature>

    var body: some View {
        VStack(spacing: 20) {
            Text("Switch Mode?")
                .font(.headline)

            Text(store.modeTransitionReason)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button("Cancel") {
                    store.send(.cancelModeTransition)
                }
                .buttonStyle(.bordered)

                Button("Switch") {
                    store.send(.confirmModeTransition)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .presentationDetents([.height(200)])
    }
}

// MARK: - Follow-on Action UI Components

struct FollowOnActionsView: View {
    let store: StoreOf<UnifiedChatFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Next Steps")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.sharedContext.followOnActions, id: \.id) { action in
                        FollowOnActionCard(
                            action: action,
                            onExecute: {
                                store.send(.executeFollowOnAction(action))
                            },
                            onDismiss: {
                                store.send(.dismissFollowOnAction(action.id))
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(red: 0.97, green: 0.97, blue: 0.99))
    }
}

struct FollowOnActionCard: View {
    let action: FollowOnAction
    let onExecute: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(action.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(action.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                // Priority indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(action.priority.color)
                        .frame(width: 8, height: 8)
                    Text(action.priority.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Duration estimate
                Label {
                    Text(formatDuration(action.estimatedDuration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Automation level
                if action.requiresUserInput {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            Button(action: onExecute) {
                HStack {
                    Image(systemName: action.category.icon)
                        .font(.caption)
                    Text(action.requiresUserInput ? "Review & Start" : "Start")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 250)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            return "\(hours) hr"
        }
    }
}

// MARK: - Follow-on Action Extensions

extension ActionCategory {
    var displayName: String {
        switch self {
        case .documentGeneration:
            "Document Generation"
        case .requirementGathering:
            "Requirements"
        case .vendorManagement:
            "Vendor Management"
        case .reviewApproval:
            "Review & Approval"
        case .complianceCheck:
            "Compliance"
        case .marketResearch:
            "Market Research"
        case .dataAnalysis:
            "Data Analysis"
        case .communication:
            "Communication"
        case .systemConfiguration:
            "System Configuration"
        case .riskAssessment:
            "Risk Assessment"
        }
    }

    var icon: String {
        switch self {
        case .documentGeneration:
            "doc.text.fill"
        case .requirementGathering:
            "list.bullet.rectangle"
        case .vendorManagement:
            "person.3.fill"
        case .reviewApproval:
            "checkmark.circle.fill"
        case .complianceCheck:
            "shield.checkered"
        case .marketResearch:
            "chart.line.uptrend.xyaxis"
        case .dataAnalysis:
            "chart.bar.fill"
        case .communication:
            "envelope.fill"
        case .systemConfiguration:
            "gearshape.fill"
        case .riskAssessment:
            "exclamationmark.triangle.fill"
        }
    }
}

extension ActionPriority {
    var displayName: String {
        switch self {
        case .critical:
            "Critical"
        case .high:
            "High"
        case .medium:
            "Medium"
        case .low:
            "Low"
        }
    }

    var color: Color {
        switch self {
        case .critical:
            .red
        case .high:
            .orange
        case .medium:
            .blue
        case .low:
            .gray
        }
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var mainQueue: AnySchedulerOf<DispatchQueue> {
        get { self[MainQueueKey.self] }
        set { self[MainQueueKey.self] = newValue }
    }
}

private enum MainQueueKey: DependencyKey {
    static let liveValue = AnySchedulerOf<DispatchQueue>.main
}
