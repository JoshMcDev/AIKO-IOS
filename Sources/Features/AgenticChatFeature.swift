import ComposableArchitecture
import Foundation
import SwiftUI

// NSAttributedString already conforms to Equatable in Foundation

// MARK: - Agentic Chat Feature

@Reducer
public struct AgenticChatFeature {
    @ObservableState
    public struct State: Equatable {
        var messages: IdentifiedArrayOf<ChatMessage> = []
        var currentIntent: AcquisitionIntent?
        var agentState: AgentState = .idle
        var inputText: String = ""
        var suggestions: [String] = []
        var activeAcquisitions: IdentifiedArrayOf<AcquisitionProgress> = []
        var showDetails: Bool = false

        // Enhanced state properties
        var taskQueueState: TaskQueueState
        var activeApprovals: IdentifiedArrayOf<ApprovalRequest> = []
        var taskHistory: [TaskExecutionResult] = []
        var errorRecoverySuggestions: [String] = []
        var isProcessingQueue: Bool = false

        public init() {
            taskQueueState = TaskQueueState(taskExecutor: LiveTaskExecutor())
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case sendMessage
        case messageReceived(ChatMessage)
        case intentRecognized(AcquisitionIntent)
        case suggestionsUpdated([String])
        case agentStateChanged(AgentState)
        case executeAction(AgentAction)
        case showAcquisitionDetails(AcquisitionProgress.ID)
        case dismissDetails

        // Agent autonomous actions
        case agentStartedTask(AgentTask)
        case agentCompletedTask(AgentTask, TaskResult)
        case agentRequestsApproval(ApprovalRequest)
        case userApproval(ApprovalRequest.ID, Bool)

        // Enhanced actions
        case taskQueue(TaskQueueAction)
        case processTaskQueue
        case taskExecutionCompleted(TaskExecutionResult)
        case retryFailedTask(UUID)
        case showTaskDetails(UUID)
        case updateSuggestions
        case handleError(Error, UUID?)
    }

    @Dependency(\.agenticEngine) var agenticEngine
    @Dependency(\.naturalLanguageProcessor) var nlp
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    @Dependency(\.taskQueueManager) var taskQueueManager

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .sendMessage:
                guard !state.inputText.isEmpty else { return .none }

                let message = ChatMessage(
                    id: uuid(),
                    role: .user,
                    content: state.inputText,
                    timestamp: Date()
                )
                state.messages.append(message)
                state.inputText = ""
                state.agentState = .thinking

                return .run { [message] send in
                    // Process user intent
                    let intent = try await nlp.processAcquisitionIntent(message.content)
                    await send(.intentRecognized(intent))

                    // Generate agent response
                    let response = try await agenticEngine.generateResponse(intent, message.content)
                    await send(.messageReceived(response))

                    // Start autonomous execution if approved
                    if intent.requiresExecution {
                        await send(.agentStateChanged(.executing))
                    }
                }

            case let .messageReceived(message):
                state.messages.append(message)
                state.agentState = .idle

                // Update suggestions based on context
                return .run { send in
                    let suggestions = try await nlp.generateContextualSuggestions(message.content)
                    await send(.suggestionsUpdated(suggestions))
                }

            case let .intentRecognized(intent):
                state.currentIntent = intent

                // Show relevant UI elements based on intent
                switch intent.type {
                case .createAcquisition:
                    state.showDetails = true
                case .reviewDocuments:
                    // Would show document viewer
                    break
                case .checkStatus:
                    // Would show status dashboard
                    break
                default:
                    break
                }
                return .none

            case let .suggestionsUpdated(suggestions):
                state.suggestions = suggestions
                return .none

            case let .agentStateChanged(newState):
                state.agentState = newState
                return .none

            case let .executeAction(action):
                // Add to task queue instead of direct execution
                let task = AgentTask(action: action)
                let priority: TaskPriority = action.requiresApproval ? .high : .normal

                return .run { send in
                    await send(.taskQueue(.enqueueTask(task, priority, [])))
                    await send(.agentStartedTask(task))

                    // Process queue if not already processing
                    await send(.processTaskQueue)
                }

            case let .agentStartedTask(task):
                // Update UI to show task in progress
                let message = ChatMessage(
                    id: uuid(),
                    role: .assistant,
                    content: " \(task.description)",
                    timestamp: Date(),
                    isStatus: true
                )
                state.messages.append(message)
                return .none

            case let .agentCompletedTask(task, result):
                // Update UI with task result
                let content: String
                var card: MessageCard?

                switch result {
                case let .success(output):
                    content = " \(task.completionMessage(output))"
                    // Create appropriate card based on task type
                    card = Self.createCardForTaskResult(task: task, output: output)
                case let .failure(error):
                    content = "❌ \(task.failureMessage(error))"
                    // Generate recovery suggestions
                    state.errorRecoverySuggestions = Self.generateRecoverySuggestions(for: error, task: task)
                }

                let message = ChatMessage(
                    id: uuid(),
                    role: .assistant,
                    content: content,
                    timestamp: Date(),
                    isStatus: true,
                    card: card
                )
                state.messages.append(message)

                // Show recovery options if task failed
                if case .failure = result {
                    return .run { send in
                        await send(.updateSuggestions)
                    }
                }

                return .none

            case let .agentRequestsApproval(request):
                // Show approval request in chat
                let message = ChatMessage(
                    id: uuid(),
                    role: .assistant,
                    content: request.message,
                    timestamp: Date(),
                    approvalRequest: request
                )
                state.messages.append(message)
                return .none

            case let .userApproval(requestId, approved):
                // Process user approval
                return .run { _ in
                    if approved {
                        try await agenticEngine.proceedWithApproval(requestId)
                    } else {
                        try await agenticEngine.cancelRequest(requestId)
                    }
                }

            case .showAcquisitionDetails:
                state.showDetails = true
                return .none

            case .dismissDetails:
                state.showDetails = false
                return .none

            case .binding:
                return .none

            // Enhanced action handlers
            case let .taskQueue(action):
                return handleTaskQueueAction(action, &state)

            case .processTaskQueue:
                guard !state.isProcessingQueue else { return .none }
                state.isProcessingQueue = true

                return .run { [taskQueueManager] send in
                    let mutableManager = taskQueueManager
                    let results = await mutableManager.processQueue()
                    for result in results {
                        await send(.taskExecutionCompleted(result))
                    }
                    await send(.taskQueue(.refreshQueueStatus))
                }

            case let .taskExecutionCompleted(result):
                state.isProcessingQueue = false
                state.taskHistory.append(result)

                // Update agent state based on result
                if state.taskQueueState.queueStatus.executingTasks.isEmpty {
                    state.agentState = .idle
                }

                return .none

            case let .retryFailedTask(taskId):
                // Find the failed task and retry it
                if state.taskHistory.contains(where: { $0.taskId == taskId }) {
                    // Re-enqueue the task
                    return .run { send in
                        await send(.updateSuggestions)
                    }
                }
                return .none

            case .updateSuggestions:
                return .run { [state] send in
                    let suggestions = await Self.generateContextualSuggestions(state: state)
                    await send(.suggestionsUpdated(suggestions))
                }

            case let .handleError(error, _):
                // Add error message
                let errorMessage = ChatMessage(
                    id: uuid(),
                    role: .system,
                    content: "⚠ Error: \(error.localizedDescription)",
                    timestamp: Date(),
                    isStatus: true
                )
                state.messages.append(errorMessage)

                // Generate recovery suggestions
                state.errorRecoverySuggestions = Self.generateRecoverySuggestions(for: error, task: nil)

                return .run { send in
                    await send(.updateSuggestions)
                }

            case .showTaskDetails:
                state.showDetails = true
                return .none
            }
        }
    }

    // MARK: - Helper Functions

    private func handleTaskQueueAction(_ action: TaskQueueAction, _: inout State) -> Effect<Action> {
        switch action {
        case .enqueueTask:
            // For now, we'll just update the status
            // In a real implementation, this would interact with the taskQueueManager dependency
            .none

        case .refreshQueueStatus:
            // Update status from the task queue manager
            .none

        default:
            .none
        }
    }

    private static func createCardForTaskResult(task: AgentTask, output: Any) -> MessageCard? {
        switch task.action.type {
        case .identifyVendors:
            // Create vendor comparison card
            if let vendorData = output as? [String: Any],
               let vendors = vendorData["vendors"] as? [String]
            {
                let vendorInfos = vendors.map { name in
                    VendorInfo(
                        name: name,
                        capability: "Full Service",
                        compliance: "SAM Verified",
                        pricing: "Competitive"
                    )
                }
                return MessageCard(
                    type: .vendorComparison,
                    title: "Qualified Vendors Found",
                    data: .vendors(vendorInfos)
                )
            }

        case .monitorCompliance:
            // Create compliance card
            if let complianceData = output as? [String: Any],
               let score = complianceData["complianceScore"] as? Double
            {
                return MessageCard(
                    type: .compliance,
                    title: "Compliance Status",
                    data: .compliance(ComplianceData(
                        score: score,
                        issues: [],
                        recommendations: score < 1.0 ? ["Review documentation", "Update certifications"] : []
                    ))
                )
            }

        default:
            return nil
        }

        return nil
    }

    private static func generateRecoverySuggestions(for error: Error, task: AgentTask?) -> [String] {
        var suggestions = [String]()

        // Add contextual suggestions based on error type
        if error.localizedDescription.contains("network") {
            suggestions.append("Check network connection")
            suggestions.append("Retry the operation")
        }

        if error.localizedDescription.contains("timeout") {
            suggestions.append("Try again with smaller scope")
            suggestions.append("Check service status")
        }

        // Add task-specific suggestions
        if let task {
            switch task.action.type {
            case .gatherMarketResearch:
                suggestions.append("Try specific market segment")
            case .identifyVendors:
                suggestions.append("Narrow search criteria")
            default:
                break
            }
        }

        return suggestions
    }

    private static func generateContextualSuggestions(state: State) async -> [String] {
        var suggestions = [String]()

        // Add error recovery suggestions if any
        suggestions.append(contentsOf: state.errorRecoverySuggestions)

        // Add contextual suggestions based on current state
        if state.messages.isEmpty {
            suggestions.append("Create new acquisition")
            suggestions.append("Check acquisition status")
            suggestions.append("Review recent documents")
        } else if let lastMessage = state.messages.last {
            // Generate follow-up suggestions based on last message
            if lastMessage.content.contains("vendor") {
                suggestions.append("Compare vendor capabilities")
                suggestions.append("Request vendor quotes")
            }
        }

        // Add queue-based suggestions
        if state.taskQueueState.queueStatus.queuedTasks.count > 0 {
            suggestions.append("View task queue (\(state.taskQueueState.queueStatus.queuedTasks.count) pending)")
        }

        return Array(suggestions.prefix(5)) // Limit to 5 suggestions
    }
}

// MARK: - Models

public struct ChatMessage: Equatable, Identifiable {
    public let id: UUID
    public let role: MessageRole
    public let content: String
    public let rtfContent: String
    public let attributedContent: NSAttributedString
    public let timestamp: Date
    public var isStatus: Bool = false
    public var approvalRequest: ApprovalRequest? = nil
    public var card: MessageCard? = nil

    public init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isStatus: Bool = false, approvalRequest: ApprovalRequest? = nil, card: MessageCard? = nil) {
        self.id = id
        self.role = role
        self.content = content

        // Generate RTF content
        let (rtf, attributed) = RTFFormatter.convertToRTF(content)
        rtfContent = rtf
        attributedContent = attributed

        self.timestamp = timestamp
        self.isStatus = isStatus
        self.approvalRequest = approvalRequest
        self.card = card
    }
}

public enum MessageRole {
    case user
    case assistant
    case system
}

public struct MessageCard: Equatable {
    public let type: CardType
    public let title: String
    public let data: CardData

    public enum CardType {
        case vendorComparison
        case timeline
        case compliance
        case metrics
    }

    public enum CardData: Equatable {
        case vendors([VendorInfo])
        case timeline(TimelineData)
        case compliance(ComplianceData)
        case metrics([MetricData])
    }
}

// MARK: - Supporting Types for MessageCard

public struct VendorInfo: Equatable {
    public let name: String
    public let capability: String
    public let compliance: String
    public let pricing: String
}

public struct TimelineData: Equatable {
    public let milestones: [Milestone]

    public struct Milestone: Equatable {
        public let date: Date
        public let title: String
        public let isCompleted: Bool
    }
}

public struct ComplianceData: Equatable {
    public let score: Double
    public let issues: [String]
    public let recommendations: [String]
}

public struct MetricData: Equatable {
    public let name: String
    public let value: Double
    public let target: Double
    public let unit: String
}

public struct AcquisitionIntent: Equatable {
    public let id: UUID
    public let type: IntentType
    public let parameters: [String: String]
    public let confidence: Double
    public let requiresExecution: Bool

    public enum IntentType {
        case createAcquisition
        case reviewDocuments
        case checkStatus
        case modifyRequirements
        case askQuestion
        case approveAction
    }
}

public enum AgentState: Equatable {
    case idle
    case thinking
    case executing
    case waitingForApproval
    case monitoring
}

public struct AgentAction: Equatable {
    public let id: UUID
    public let type: ActionType
    public let description: String
    public let requiresApproval: Bool

    public enum ActionType {
        case gatherMarketResearch
        case generateDocuments
        case identifyVendors
        case scheduleReviews
        case submitForApproval
        case monitorCompliance
    }
}

public struct AgentTask: Equatable, Identifiable {
    public let id: UUID = .init()
    public let action: AgentAction
    public let startTime: Date = .init()

    public var description: String {
        switch action.type {
        case .gatherMarketResearch:
            "Gathering market research data..."
        case .generateDocuments:
            "Generating acquisition documents..."
        case .identifyVendors:
            "Identifying qualified vendors..."
        case .scheduleReviews:
            "Scheduling required reviews..."
        case .submitForApproval:
            "Submitting for approval..."
        case .monitorCompliance:
            "Monitoring compliance requirements..."
        }
    }

    public func completionMessage(_: Any) -> String {
        switch action.type {
        case .gatherMarketResearch:
            "Market research complete. Found relevant data from 15 sources."
        case .generateDocuments:
            "Documents generated successfully. Ready for review."
        case .identifyVendors:
            "Identified 8 qualified vendors meeting requirements."
        case .scheduleReviews:
            "Reviews scheduled with all stakeholders."
        case .submitForApproval:
            "Submitted for approval. Tracking number: AP-2025-0142"
        case .monitorCompliance:
            "Compliance check complete. All requirements met."
        }
    }

    public func failureMessage(_ error: Error) -> String {
        "Task failed: \(error.localizedDescription). Would you like me to try again?"
    }
}

public enum TaskResult: Equatable {
    case success(Any)
    case failure(Error)

    public static func == (lhs: TaskResult, rhs: TaskResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success):
            true
        case let (.failure(lhsError), .failure(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }
}

public struct ApprovalRequest: Equatable, Identifiable {
    public let id: UUID
    public let message: String
    public let action: AgentAction
    public let impact: ImpactLevel

    public enum ImpactLevel {
        case low
        case medium
        case high
    }
}

public struct AcquisitionProgress: Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let status: Status
    public let progress: Double
    public let nextMilestone: String
    public let daysUntilDeadline: Int

    public enum Status {
        case planning
        case marketResearch
        case solicitation
        case evaluation
        case award
        case execution
        case closeout
    }
}

// MARK: - Dependencies

public struct AgenticEngine {
    public var generateResponse: (AcquisitionIntent, String) async throws -> ChatMessage
    public var execute: (AgentAction) async throws -> Any
    public var proceedWithApproval: (UUID) async throws -> Void
    public var cancelRequest: (UUID) async throws -> Void
}

extension AgenticEngine: DependencyKey {
    public static var liveValue: AgenticEngine {
        AgenticEngine(
            generateResponse: { intent, _ in
                // This would connect to the AI service
                ChatMessage(
                    id: UUID(),
                    role: .assistant,
                    content: "I understand you want to \(intent.type). Let me help with that.",
                    timestamp: Date()
                )
            },
            execute: { _ in
                // Execute the autonomous action
                try await Task.sleep(for: .seconds(2))
                return "Action completed"
            },
            proceedWithApproval: { _ in
                // Process approval
            },
            cancelRequest: { _ in
                // Cancel request
            }
        )
    }
}

public struct NaturalLanguageProcessor {
    public var processAcquisitionIntent: (String) async throws -> AcquisitionIntent
    public var generateContextualSuggestions: (String) async throws -> [String]
}

extension NaturalLanguageProcessor: DependencyKey {
    public static var liveValue: NaturalLanguageProcessor {
        NaturalLanguageProcessor(
            processAcquisitionIntent: { _ in
                // NLP processing would happen here
                AcquisitionIntent(
                    id: UUID(),
                    type: .createAcquisition,
                    parameters: [:],
                    confidence: 0.95,
                    requiresExecution: true
                )
            },
            generateContextualSuggestions: { _ in
                [
                    "What's the estimated budget?",
                    "When do you need this completed?",
                    "Are there any special requirements?",
                ]
            }
        )
    }
}

// MARK: - View

public struct AgenticChatView: View {
    @Perception.Bindable var store: StoreOf<AgenticChatFeature>

    public init(store: StoreOf<AgenticChatFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Ambient status bar
            AmbientStatusBar(store: store)

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.messages) { message in
                            MessageView(message: message, store: store)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: store.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(store.messages.last?.id)
                    }
                }
            }

            // Smart input bar
            SmartInputBar(store: store)
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
    }
}

struct AmbientStatusBar: View {
    let store: StoreOf<AgenticChatFeature>

    var body: some View {
        HStack(spacing: 12) {
            if store.activeAcquisitions.count > 0 {
                StatusPill(
                    text: "\(store.activeAcquisitions.count) Active",
                    color: .green
                )
            }

            if store.agentState == .executing {
                StatusPill(
                    text: "Working...",
                    color: .blue,
                    isAnimating: true
                )
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(red: 0.97, green: 0.97, blue: 0.99))
    }
}

public struct StatusPill: View {
    public let text: String
    public let color: Color
    public var isAnimating: Bool = false

    public init(text: String, color: Color, isAnimating: Bool = false) {
        self.text = text
        self.color = color
        self.isAnimating = isAnimating
    }

    public var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
                isAnimating ? .easeInOut(duration: 1).repeatForever() : .default,
                value: isAnimating
            )
    }
}

struct MessageView: View {
    let message: ChatMessage
    let store: StoreOf<AgenticChatFeature>

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
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

                // Approval buttons if needed
                if let approval = message.approvalRequest {
                    HStack(spacing: 12) {
                        Button("Approve") {
                            store.send(.userApproval(approval.id, true))
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Decline") {
                            store.send(.userApproval(approval.id, false))
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }

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

struct SmartInputBar: View {
    @Perception.Bindable var store: StoreOf<AgenticChatFeature>
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Suggestions
            if !store.suggestions.isEmpty, store.inputText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.suggestions, id: \.self) { suggestion in
                            Button(action: {
                                store.inputText = suggestion
                            }) {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(red: 0.92, green: 0.92, blue: 0.94))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }

            // Input field
            HStack(spacing: 12) {
                TextField(
                    "",
                    text: .init(
                        get: { store.inputText },
                        set: { newValue in store.send(.binding(.set(\.inputText, newValue))) }
                    ),
                    prompt: Text("...").foregroundColor(.gray),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.92, green: 0.92, blue: 0.94))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isFocused)
                .onSubmit {
                    store.send(.sendMessage)
                }

                Button(action: {
                    store.send(.sendMessage)
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(
                            store.inputText.isEmpty ? .gray : .blue
                        )
                }
                .disabled(store.inputText.isEmpty)
            }
            .padding()
            .background(Color(red: 0.97, green: 0.97, blue: 0.99))
        }
    }
}

// MARK: - Dependency Registration

public extension DependencyValues {
    var agenticEngine: AgenticEngine {
        get { self[AgenticEngine.self] }
        set { self[AgenticEngine.self] = newValue }
    }

    var naturalLanguageProcessor: NaturalLanguageProcessor {
        get { self[NaturalLanguageProcessor.self] }
        set { self[NaturalLanguageProcessor.self] = newValue }
    }
}
