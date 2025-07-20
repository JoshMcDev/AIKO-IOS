import AppCore
import ComposableArchitecture
import Foundation
import AikoCompat

@Reducer
public struct AcquisitionChatFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var messages: [ChatMessage] = []
        public var currentInput: String = ""
        public var isProcessing: Bool = false
        public var currentPhase: ChatPhase = .initial
        public var gatheredRequirements: RequirementsData = .init()
        public var predictedValues: [String: String] = [:]
        public var confirmedPredictions: Set<String> = []
        public var documentReadiness: [DocumentType: Bool] = [:]
        public var recommendedDocuments: Set<DocumentType> = []
        public var showingCloseConfirmation: Bool = false
        public var acquisitionId: UUID?
        public var currentAcquisitionId: UUID? // For updates
        public var awaitingConfirmation: Bool = false
        public var isRecording: Bool = false

        // Enhanced Agentic Chat properties
        public var agentState: AgentState = .idle
        public var currentIntent: AcquisitionIntent?
        public var suggestions: [String] = []
        public var activeTask: AgentTask?
        public var activeTasks: [AgentTask] = []
        public var messageCards: [UUID: MessageCard] = [:]
        public var approvalRequests: [UUID: ApprovalRequest] = [:]

        // Follow-on Action properties
        public var suggestedActions: FollowOnActionSet?
        public var completedActionIds: Set<UUID> = []
        public var executingActionIds: Set<UUID> = []
        public var showingActionSelector: Bool = false

        // Document picker state
        public var showingDocumentPicker: Bool = false
        public var uploadedDocuments: [UploadedDocument] = []

        public init() {
            // If we have recommended documents, we're gathering info for specific docs
            // Otherwise, it's a new acquisition
            if !recommendedDocuments.isEmpty {
                // Initial message will be set by parent when needed
            } else {
                // Add initial greeting message for new acquisition
                messages.append(ChatMessage(
                    role: .assistant,
                    content: """
                    # Welcome to AIKO Acquisition Assistant

                    I'm here to help you create a new acquisition. I'll guide you through gathering the essential information needed to generate your contract documents.

                    **Let's start with the basics:**
                    What type of product or service are you looking to acquire?
                    """
                ))
            }
        }

        public var inputPlaceholder: String {
            switch currentPhase {
            case .initial:
                "Describe the product or service you need..."
            case .gatheringBasics:
                if gatheredRequirements.estimatedValue.isEmpty {
                    "Enter the estimated dollar value (e.g., $50,000)..."
                } else if gatheredRequirements.performancePeriod.isEmpty {
                    "Enter the performance period (e.g., 12 months)..."
                } else if gatheredRequirements.businessNeed.isEmpty {
                    "Describe why this is needed..."
                } else {
                    "Provide additional details..."
                }
            case .gatheringDetails:
                if gatheredRequirements.technicalRequirements.isEmpty {
                    "Describe technical requirements or type 'skip'..."
                } else {
                    "Add more details or type 'skip' to continue..."
                }
            case .analyzingRequirements:
                "Please wait while I analyze your requirements..."
            case .confirmingPredictions:
                "Confirm if the values are correct or suggest changes..."
            case .readyToGenerate:
                "Type 'generate all' or select specific documents..."
            }
        }
    }

    public enum ChatPhase: Equatable, Sendable {
        case initial
        case gatheringBasics
        case gatheringDetails
        case analyzingRequirements
        case confirmingPredictions
        case readyToGenerate
    }

    public struct UploadedDocument: Equatable, Identifiable, Sendable {
        public let id = UUID()
        public let fileName: String
        public let data: Data
        public let uploadDate = Date()
        public var extractedContent: String?
    }

    public struct RequirementsData: Equatable, Sendable {
        public var projectTitle: String = ""
        public var productOrService: String = ""
        public var estimatedValue: String = ""
        public var performancePeriod: String = ""
        public var requirementType: String = ""
        public var businessNeed: String = ""
        public var technicalRequirements: String = ""
        public var evaluationCriteria: String = ""
        public var specialConsiderations: String = ""

        public var completionPercentage: Double {
            let fields = [
                projectTitle,
                productOrService,
                estimatedValue,
                performancePeriod,
                requirementType,
                businessNeed,
            ]
            let filledFields = fields.filter { !$0.isEmpty }.count
            return Double(filledFields) / Double(fields.count)
        }

        public var hasMinimumInfo: Bool {
            !productOrService.isEmpty &&
                !estimatedValue.isEmpty &&
                !performancePeriod.isEmpty &&
                !businessNeed.isEmpty
        }

        // Convert to global RequirementsData type for use with services
        public func toGlobalRequirementsData() -> AIKO.RequirementsData {
            // Parse estimated value to Decimal
            let cleanedValue = estimatedValue.replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
            let decimalValue = Decimal(string: cleanedValue)

            // Parse technical requirements (split by newlines)
            let techReqs = technicalRequirements.isEmpty ? [] : technicalRequirements
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // Parse evaluation criteria (split by newlines)
            let evalCriteria = evaluationCriteria.isEmpty ? [] : evaluationCriteria
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // Parse special conditions from specialConsiderations
            let specialConds = specialConsiderations.isEmpty ? [] : [specialConsiderations]

            return AIKO.RequirementsData(
                projectTitle: projectTitle.isEmpty ? nil : projectTitle,
                description: productOrService.isEmpty ? nil : productOrService,
                estimatedValue: decimalValue,
                requiredDate: nil, // Not captured in this form
                technicalRequirements: techReqs,
                vendorInfo: nil, // Not captured in this form
                specialConditions: specialConds,
                attachments: [], // Not captured in this form
                performancePeriod: nil, // Could parse performancePeriod string to DateInterval
                placeOfPerformance: nil, // Not captured in this form
                businessJustification: businessNeed.isEmpty ? nil : businessNeed,
                acquisitionType: requirementType.isEmpty ? nil : requirementType,
                competitionMethod: nil, // Not captured in this form
                setAsideType: nil, // Not captured in this form
                evaluationCriteria: evalCriteria
            )
        }
    }

    public struct ChatMessage: Equatable, Identifiable, Sendable {
        public let id = UUID()
        public let role: MessageRole
        public let content: String
        public let timestamp: Date

        public init(role: MessageRole, content: String, timestamp: Date = Date()) {
            self.role = role
            self.content = content
            self.timestamp = timestamp
        }
    }

    public enum MessageRole: Equatable, Sendable {
        case user
        case assistant
    }

    public enum Action {
        case inputChanged(String)
        case sendMessage
        case processUserInput(String)
        case addAssistantMessage(String)
        case updateRequirements(RequirementsData)
        case updateDocumentReadiness([DocumentType: Bool])
        case updateRecommendedDocuments(Set<DocumentType>)
        case phaseChanged(ChatPhase)
        case confirmClose(Bool)
        case closeChat
        case generateDocuments
        case saveAcquisition
        case acquisitionSaved(UUID)
        case startVoiceRecording
        case stopVoiceRecording
        case voiceInputReceived(String)
        case showDocumentPicker
        case showImagePicker
        case documentUploaded(Data, String)
        case removeDocument(UploadedDocument.ID)
        case addReference(String)
        case updatePredictedValues([String: String])
        case confirmPrediction(String)
        case updateAcquisitionData
        case acquisitionDataUpdated
        case requestConfirmation
        case userConfirmedPredictions(Bool)
        case enhancePrompt
        case promptEnhanced(String)
        case startRecording
        case stopRecording

        // Enhanced Agentic Chat actions
        case agentStateChanged(AgentState)
        case intentRecognized(AcquisitionIntent)
        case suggestionsUpdated([String])
        case executeAction(AgentAction)
        case agentStartedTask(AgentTask)
        case agentCompletedTask(AgentTask, TaskResult)
        case agentRequestsApproval(ApprovalRequest)
        case approveAction(UUID)
        case rejectAction(UUID)

        // Follow-on Action actions
        case generateFollowOnActions
        case followOnActionsGenerated(FollowOnActionSet)
        case executeFollowOnAction(FollowOnAction)
        case followOnActionCompleted(UUID, ActionExecutionResult)
        case showActionSelector(Bool)
        case refreshFollowOnActions
    }

    @Dependency(\.aiDocumentGenerator) var aiDocumentGenerator
    @Dependency(\.acquisitionService) var acquisitionService
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    @Dependency(\.voiceRecordingClient) var voiceRecordingClient
    @Dependency(\.followOnActionService) var followOnActionService

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .inputChanged(input):
                state.currentInput = input
                return .none

            case .sendMessage:
                guard !state.currentInput.isEmpty else { return .none }

                let userMessage = ChatMessage(role: .user, content: state.currentInput)
                state.messages.append(userMessage)

                let input = state.currentInput
                state.currentInput = ""
                state.isProcessing = true

                return .send(.processUserInput(input))

            case let .processUserInput(input):
                return .run { [state] send in
                    do {
                        // Use the AI service with government acquisition prompts
                        let response = try await processUserResponseWithAI(
                            input: input,
                            currentRequirements: state.gatheredRequirements,
                            phase: state.currentPhase,
                            conversationHistory: state.messages,
                            preSelectedDocuments: state.recommendedDocuments
                        )

                        await send(.addAssistantMessage(response.message))
                        await send(.updateRequirements(response.updatedRequirements))
                        await send(.updateDocumentReadiness(response.documentReadiness))
                        await send(.updateRecommendedDocuments(response.recommendedDocuments))
                        await send(.phaseChanged(response.nextPhase))

                        // Handle predictions if any
                        if !response.predictedValues.isEmpty {
                            await send(.updatePredictedValues(response.predictedValues))
                        }

                        // Update acquisition data periodically
                        await send(.updateAcquisitionData)
                    } catch {
                        // Fallback to hardcoded response
                        let response = try await processUserResponse(
                            input: input,
                            currentRequirements: state.gatheredRequirements,
                            phase: state.currentPhase
                        )

                        await send(.addAssistantMessage(response.message))
                        await send(.updateRequirements(response.updatedRequirements))
                        await send(.updateDocumentReadiness(response.documentReadiness))
                        await send(.updateRecommendedDocuments(response.recommendedDocuments))
                        await send(.phaseChanged(response.nextPhase))
                    }
                }

            case let .addAssistantMessage(message):
                state.messages.append(ChatMessage(role: .assistant, content: message))
                state.isProcessing = false
                return .none

            case let .updateRequirements(requirements):
                state.gatheredRequirements = requirements
                return .none

            case let .updateDocumentReadiness(readiness):
                state.documentReadiness = readiness
                return .none

            case let .updateRecommendedDocuments(documents):
                state.recommendedDocuments = documents
                return .none

            case let .phaseChanged(phase):
                state.currentPhase = phase
                // Generate follow-on actions for the new phase
                return .send(.generateFollowOnActions)

            case let .confirmClose(show):
                state.showingCloseConfirmation = show
                return .none

            case .closeChat:
                // Save acquisition before closing
                if state.gatheredRequirements.hasMinimumInfo {
                    return .send(.saveAcquisition)
                }
                return .none

            case .generateDocuments:
                // This will trigger document generation in the parent feature
                return .send(.saveAcquisition)

            case .saveAcquisition:
                return .run { [state] send in
                    let title = state.gatheredRequirements.projectTitle.isEmpty
                        ? "New Acquisition - \(Date().formatted())"
                        : state.gatheredRequirements.projectTitle

                    let requirements = """
                    Product/Service: \(state.gatheredRequirements.productOrService)
                    Estimated Value: \(state.gatheredRequirements.estimatedValue)
                    Performance Period: \(state.gatheredRequirements.performancePeriod)
                    Business Need: \(state.gatheredRequirements.businessNeed)
                    Technical Requirements: \(state.gatheredRequirements.technicalRequirements)
                    Evaluation Criteria: \(state.gatheredRequirements.evaluationCriteria)
                    Special Considerations: \(state.gatheredRequirements.specialConsiderations)
                    """

                    let acquisition = try await acquisitionService.createAcquisition(
                        title,
                        requirements,
                        [] // No uploaded documents from chat yet
                    )

                    await send(.acquisitionSaved(acquisition.id))
                }

            case let .acquisitionSaved(id):
                state.acquisitionId = id
                return .none

            case .startVoiceRecording:
                state.isRecording = true

                return .run { send in
                    do {
                        // Check permissions first
                        let hasPermissions = voiceRecordingClient.checkPermissions()
                        if !hasPermissions {
                            let granted = await voiceRecordingClient.requestPermissions()
                            if !granted {
                                await send(.addAssistantMessage("Microphone access is required for voice input. Please enable it in Settings."))
                                await send(.stopVoiceRecording)
                                return
                            }
                        }

                        // Start recording
                        try await voiceRecordingClient.startRecording()
                    } catch {
                        await send(.addAssistantMessage("Failed to start voice recording. Please try typing instead."))
                        await send(.stopVoiceRecording)
                    }
                }

            case .stopVoiceRecording:
                state.isRecording = false

                return .run { send in
                    do {
                        let transcription = try await voiceRecordingClient.stopRecording()
                        await send(.voiceInputReceived(transcription))
                    } catch {
                        await send(.addAssistantMessage("Failed to process voice recording. Please try again."))
                    }
                }

            case let .voiceInputReceived(text):
                state.isProcessing = false
                state.currentInput = text
                return .send(.sendMessage)

            case .showDocumentPicker:
                state.showingDocumentPicker = true
                return .none

            case .showImagePicker:
                state.showingDocumentPicker = true // Using same picker for now
                return .none

            case let .removeDocument(documentId):
                state.uploadedDocuments.removeAll { $0.id == documentId }
                return .none

            case let .documentUploaded(data, fileName):
                state.showingDocumentPicker = false

                // Create uploaded document
                var uploadedDoc = UploadedDocument(
                    fileName: fileName,
                    data: data
                )

                // Extract text content from the document
                if let content = String(data: data, encoding: .utf8) {
                    uploadedDoc.extractedContent = content
                    state.uploadedDocuments.append(uploadedDoc)

                    // Add message with extracted content summary
                    let summary = content.prefix(200) + (content.count > 200 ? "..." : "")
                    state.messages.append(ChatMessage(
                        role: .assistant,
                        content: """
                         Successfully uploaded: **\(fileName)**

                        I've extracted the following content:
                        ```
                        \(summary)
                        ```

                        I'll incorporate this information into your acquisition requirements.
                        """
                    ))

                    // Incorporate into requirements
                    if state.gatheredRequirements.technicalRequirements.isEmpty {
                        state.gatheredRequirements.technicalRequirements = content
                    } else {
                        state.gatheredRequirements.technicalRequirements += "\n\nFrom \(fileName):\n\(content)"
                    }
                } else {
                    // Handle binary files
                    state.uploadedDocuments.append(uploadedDoc)
                    state.messages.append(ChatMessage(
                        role: .assistant,
                        content: """
                         Received document: **\(fileName)**

                        Note: This appears to be a binary file. Please provide a description of what this document contains.
                        """
                    ))
                }

                return .none

            case let .addReference(reference):
                // Add reference to requirements
                state.gatheredRequirements.specialConsiderations += "\n\nReference: \(reference)"
                state.messages.append(ChatMessage(
                    role: .assistant,
                    content: "I've added the reference to your requirements. Please continue describing your needs."
                ))
                return .none

            case let .updatePredictedValues(predictions):
                state.predictedValues = predictions
                return .none

            case let .confirmPrediction(key):
                state.confirmedPredictions.insert(key)
                return .send(.updateAcquisitionData)

            case .updateAcquisitionData:
                // Update Core Data with gathered information
                return .run { [state] send in
                    if let acquisitionId = state.currentAcquisitionId ?? state.acquisitionId {
                        try await acquisitionService.updateAcquisition(acquisitionId) { acquisition in
                            // Update acquisition with gathered data
                            acquisition.requirements = """
                            Product/Service: \(state.gatheredRequirements.productOrService)
                            Estimated Value: \(state.gatheredRequirements.estimatedValue)
                            Performance Period: \(state.gatheredRequirements.performancePeriod)
                            Business Need: \(state.gatheredRequirements.businessNeed)
                            Technical Requirements: \(state.gatheredRequirements.technicalRequirements)
                            Evaluation Criteria: \(state.gatheredRequirements.evaluationCriteria)
                            Special Considerations: \(state.gatheredRequirements.specialConsiderations)

                            Predicted Values:
                            \(state.predictedValues.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
                            """
                            acquisition.lastModifiedDate = Date()
                        }
                    }
                    await send(.acquisitionDataUpdated)
                }

            case .acquisitionDataUpdated:
                // Data saved successfully
                return .none

            case .requestConfirmation:
                state.awaitingConfirmation = true
                state.currentPhase = .confirmingPredictions
                return .none

            case let .userConfirmedPredictions(confirmed):
                state.awaitingConfirmation = false
                if confirmed {
                    // Mark all predicted values as confirmed
                    state.confirmedPredictions = Set(state.predictedValues.keys)
                    state.currentPhase = .readyToGenerate

                    // Update document readiness
                    for docType in state.recommendedDocuments {
                        state.documentReadiness[docType] = true
                    }

                    return .send(.updateAcquisitionData)
                } else {
                    // Go back to gathering details
                    state.currentPhase = .gatheringDetails
                    return .none
                }

            case .enhancePrompt:
                guard !state.currentInput.isEmpty else { return .none }

                state.isProcessing = true

                return .run { [input = state.currentInput] send in
                    do {
                        // Get AIProvider
                        guard let aiProvider = await AIProviderFactory.defaultProvider() else {
                            throw AcquisitionChatFeatureError.noProvider
                        }

                        // Use AI to enhance the prompt
                        let messages = [
                            AIMessage.user("""
                                Please enhance and improve the following prompt to make it clearer, more specific, and more effective for generating government contract documents. Keep the enhanced version concise but comprehensive:

                                Original prompt: \(input)

                                Enhanced prompt:
                                """)
                        ]

                        let request = AICompletionRequest(
                            messages: messages,
                            model: "claude-sonnet-4-20250514",
                            maxTokens: 300,
                            temperature: 0.3,
                            systemPrompt: "You are an expert at improving prompts for government acquisition document generation. Make prompts clearer, more specific, and actionable while keeping them concise."
                        )

                        let result = try await aiProvider.complete(request)

                        let enhancedText = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                        await send(.promptEnhanced(enhancedText))
                    } catch {
                        // If enhancement fails, keep the original
                        await send(.promptEnhanced(input))
                    }
                }

            case let .promptEnhanced(enhancedPrompt):
                state.isProcessing = false
                state.currentInput = enhancedPrompt
                return .none

            case .startRecording:
                return .send(.startVoiceRecording)

            case .stopRecording:
                return .send(.stopVoiceRecording)

            // Enhanced Agentic Chat action handlers
            case let .agentStateChanged(newState):
                state.agentState = newState
                return .none

            case let .intentRecognized(intent):
                state.currentIntent = intent
                return .none

            case let .suggestionsUpdated(suggestions):
                state.suggestions = suggestions
                return .none

            case let .executeAction(action):
                let task = AgentTask(action: action)
                state.activeTask = task
                state.activeTasks.append(task)
                return .send(.agentStartedTask(task))

            case let .agentStartedTask(task):
                state.agentState = .executing
                // Add status message
                let message = ChatMessage(
                    role: .assistant,
                    content: " \(task.description)"
                )
                state.messages.append(message)
                return .none

            case let .agentCompletedTask(task, result):
                state.activeTasks.removeAll { $0.id == task.id }
                if state.activeTasks.isEmpty {
                    state.agentState = .idle
                }

                switch result {
                case let .success(output):
                    let message = ChatMessage(
                        role: .assistant,
                        content: " \(task.completionMessage(output))"
                    )
                    state.messages.append(message)
                case let .failure(error):
                    let message = ChatMessage(
                        role: .assistant,
                        content: "❌ \(task.failureMessage(error))"
                    )
                    state.messages.append(message)
                }
                return .none

            case let .agentRequestsApproval(request):
                state.approvalRequests[request.id] = request
                state.agentState = .waitingForApproval

                let message = ChatMessage(
                    role: .assistant,
                    content: request.message
                )
                state.messages.append(message)
                return .none

            case let .approveAction(requestId):
                state.approvalRequests.removeValue(forKey: requestId)
                if state.approvalRequests.isEmpty {
                    state.agentState = .executing
                }
                // Process the approved action
                return .none

            case let .rejectAction(requestId):
                state.approvalRequests.removeValue(forKey: requestId)
                if state.approvalRequests.isEmpty {
                    state.agentState = .idle
                }
                // Handle rejection
                let message = ChatMessage(
                    role: .assistant,
                    content: "Understood. I won't proceed with that action. What would you like me to do instead?"
                )
                state.messages.append(message)
                return .none

            // Follow-on Action handlers
            case .generateFollowOnActions:
                return .run { [state] send in
                    do {
                        // Build context for action generation
                        let context = FollowOnActionContext(
                            currentPhase: state.currentPhase.toAcquisitionPhase(),
                            completedActions: [],
                            pendingTasks: state.activeTasks,
                            requirements: state.gatheredRequirements.toGlobalRequirementsData(),
                            documentChain: nil, // Will implement document chain later
                            reviewMode: .iterative,
                            conversationHistory: state.messages.map { msg in
                                LLMMessage(
                                    role: msg.role == .user ? .user : .assistant,
                                    content: msg.content
                                )
                            }
                        )

                        let actionSet = try await followOnActionService.generateFollowOnActions(for: state.acquisitionId ?? UUID(), context: context)
                        await send(.followOnActionsGenerated(actionSet))
                    } catch {
                        print("Failed to generate follow-on actions: \(error)")
                    }
                }

            case let .followOnActionsGenerated(actionSet):
                state.suggestedActions = actionSet

                // Add a message about available actions
                if !actionSet.actions.isEmpty {
                    let availableActions = actionSet.availableActions(completedActionIds: state.completedActionIds)
                    if !availableActions.isEmpty {
                        let message = ChatMessage(
                            role: .assistant,
                            content: """
                            💡 **Suggested Next Steps:**

                            \(availableActions.prefix(3).enumerated().map { index, action in
                                "\(index + 1). \(action.title) - \(action.description)"
                            }.joined(separator: "\n"))

                            Would you like me to help with any of these actions?
                            """
                        )
                        state.messages.append(message)
                    }
                }
                return .none

            case let .executeFollowOnAction(action):
                state.executingActionIds.insert(action.id)

                return .run { [state] send in
                    do {
                        let result = try await followOnActionService.executeAction(
                            action,
                            for: state.acquisitionId ?? UUID()
                        )
                        await send(.followOnActionCompleted(action.id, result))
                    } catch {
                        let failedResult = ActionExecutionResult(
                            actionId: action.id,
                            status: .failed,
                            output: error.localizedDescription
                        )
                        await send(.followOnActionCompleted(action.id, failedResult))
                    }
                }

            case let .followOnActionCompleted(actionId, result):
                state.executingActionIds.remove(actionId)
                state.completedActionIds.insert(actionId)

                // Add completion message
                let statusEmoji = result.status == .completed ? "✅" : "❌"
                let message = ChatMessage(
                    role: .assistant,
                    content: "\(statusEmoji) \(result.output ?? "Action completed")"
                )
                state.messages.append(message)

                // If there are new actions from the result, add them
                if let newActions = result.nextActions, !newActions.isEmpty {
                    if let currentSet = state.suggestedActions {
                        // Create a new action set with combined actions
                        let combinedActions = currentSet.actions + newActions
                        state.suggestedActions = FollowOnActionSet(
                            id: currentSet.id,
                            context: currentSet.context,
                            actions: combinedActions,
                            recommendedPath: currentSet.recommendedPath,
                            expiresAt: currentSet.expiresAt
                        )
                    }
                }

                // Refresh available actions
                return .send(.refreshFollowOnActions)

            case let .showActionSelector(show):
                state.showingActionSelector = show
                return .none

            case .refreshFollowOnActions:
                // Check if we should generate new actions
                if let actionSet = state.suggestedActions {
                    let availableActions = actionSet.availableActions(completedActionIds: state.completedActionIds)
                    if availableActions.isEmpty, state.completedActionIds.count > 0 {
                        // All current actions completed, generate new ones
                        return .send(.generateFollowOnActions)
                    }
                }
                return .none
            }
        }
    }

    private func processUserResponse(
        input: String,
        currentRequirements: RequirementsData,
        phase: ChatPhase
    ) async throws -> (
        message: String,
        updatedRequirements: RequirementsData,
        documentReadiness: [DocumentType: Bool],
        recommendedDocuments: Set<DocumentType>,
        nextPhase: ChatPhase
    ) {
        var requirements = currentRequirements
        var readiness: [DocumentType: Bool] = [:]
        var recommended: Set<DocumentType> = []
        var nextPhase = phase
        var responseMessage = ""

        // Process based on current phase
        switch phase {
        case .initial:
            requirements.productOrService = input
            nextPhase = .gatheringBasics
            responseMessage = """
            Great! I understand you need **\(input)**.

            Let me gather some key information to help generate the right documents:

            **What is the estimated dollar value** of this acquisition? 
            (This helps determine the appropriate procurement method)
            """

        case .gatheringBasics:
            // Check what we're missing and ask for it
            if requirements.estimatedValue.isEmpty {
                requirements.estimatedValue = input
                responseMessage = """
                Perfect, I've noted the estimated value as **\(input)**.

                **What is the expected performance period** for this contract?
                (e.g., "12 months", "3 years", "6 months with 2 option years")
                """
            } else if requirements.performancePeriod.isEmpty {
                requirements.performancePeriod = input
                responseMessage = """
                Excellent! Performance period: **\(input)**

                **What is the primary business need** this acquisition will address?
                (Brief description of why this product/service is needed)
                """
            } else if requirements.businessNeed.isEmpty {
                requirements.businessNeed = input
                nextPhase = .gatheringDetails

                // Start checking document readiness
                readiness[.marketResearch] = true
                readiness[.rrd] = true
                recommended.insert(.marketResearch)
                recommended.insert(.rrd)

                responseMessage = """
                #  Great Progress!

                I now have enough information to start preparing some initial documents:

                 **Market Research Report** - Ready to generate
                 **Requirements Document** - Ready to generate

                Would you like to provide **technical requirements or specifications**? 
                This will help me prepare more detailed documents like the Statement of Work.

                *(You can type "skip" to proceed with document generation)*
                """
            }

        case .gatheringDetails:
            if input.lowercased() != "skip" {
                requirements.technicalRequirements = input

                // Update readiness for more documents
                readiness[.marketResearch] = true
                readiness[.rrd] = true
                readiness[.sow] = true
                readiness[.costEstimate] = true
                readiness[.acquisitionPlan] = true

                // Set recommended documents
                recommended = [.marketResearch, .rrd, .sow, .costEstimate, .acquisitionPlan]
            }

            nextPhase = .readyToGenerate
            responseMessage = """
            #  Ready to Generate Documents!

            Based on our conversation, I can now generate the following documents:

            **Recommended Documents:**
            -  Market Research Report
            -  Requirements Document (RRD)
            -  Statement of Work (SOW)
            - 💰 Cost Estimate (IGCE)
            - 📅 Acquisition Plan

            **Options:**
            1.  **Generate All Recommended** - I'll create all documents automatically
            2.  **Select Specific Documents** - Return to the main view to choose
            3. 💬 **Continue Refining** - Provide more details for better documents

            What would you like to do?
            """

        case .analyzingRequirements:
            // This phase is for processing
            nextPhase = .readyToGenerate

        case .readyToGenerate:
            // Handle user's choice
            if input.lowercased().contains("generate all") || input.contains("1") {
                responseMessage = """
                # 🎉 Excellent Choice!

                I'll now generate all recommended documents based on your requirements.

                This process will:
                1. Create detailed documents tailored to your acquisition
                2. Ensure FAR compliance
                3. Include all necessary sections and clauses

                *Closing this chat will save your acquisition and begin document generation...*
                """
            } else {
                responseMessage = """
                No problem! You can:
                - Close this chat to return to the main view
                - Select specific documents to generate
                - View and edit your requirements

                Your acquisition data has been saved and is ready for document generation.
                """
            }

        case .confirmingPredictions:
            // This phase would handle confirming AI predictions
            // For now, just maintain the current state
            responseMessage = """
            Please confirm the information we've gathered so far.
            """
            nextPhase = .readyToGenerate
        }

        // Predict project title if not set
        if requirements.projectTitle.isEmpty, !requirements.productOrService.isEmpty {
            requirements.projectTitle = "Acquisition for \(requirements.productOrService)"
        }

        return (responseMessage, requirements, readiness, recommended, nextPhase)
    }

    private func processUserResponseWithAI(
        input: String,
        currentRequirements: RequirementsData,
        phase: ChatPhase,
        conversationHistory: [ChatMessage],
        preSelectedDocuments: Set<DocumentType> = []
    ) async throws -> (
        message: String,
        updatedRequirements: RequirementsData,
        documentReadiness: [DocumentType: Bool],
        recommendedDocuments: Set<DocumentType>,
        nextPhase: ChatPhase,
        predictedValues: [String: String]
    ) {
        // Build conversation context
        var context = """
        Current Requirements Gathered:
        - Product/Service: \(currentRequirements.productOrService)
        - Estimated Value: \(currentRequirements.estimatedValue)
        - Performance Period: \(currentRequirements.performancePeriod)
        - Business Need: \(currentRequirements.businessNeed)
        - Technical Requirements: \(currentRequirements.technicalRequirements)
        - Evaluation Criteria: \(currentRequirements.evaluationCriteria)
        - Special Considerations: \(currentRequirements.specialConsiderations)

        Conversation History:
        """

        for message in conversationHistory.suffix(5) {
            context += "\n\(message.role == .user ? "User" : "Assistant"): \(message.content)"
        }

        context += "\nUser: \(input)"

        // Get the appropriate prompt for the current phase
        let systemPrompt = GovernmentAcquisitionPrompts.chatPrompt(
            for: phase,
            previousContext: context,
            targetDocuments: preSelectedDocuments
        )

        // Call the AI service

        // Get AIProvider
        guard let aiProvider = await AIProviderFactory.defaultProvider() else {
            throw AcquisitionChatFeatureError.noProvider
        }

        // Convert to AICompletionRequest
        let messages = [
            AIMessage.user("""
                Based on the current phase of acquisition planning (\(phase)) and the user's input, 
                provide a response that:
                1. Acknowledges and processes their input
                2. Updates the requirements data as appropriate
                3. Asks the next relevant question or provides guidance
                4. Determines which documents are ready to generate
                5. Recommends the next phase

                Current user input: \(input)

                IMPORTANT: 
                - When you have enough information to predict values, present them clearly
                - Ask for explicit confirmation before marking documents as ready
                - If user responds with "yes", "correct", "confirm" or similar, treat as confirmation
                - Update predicted values in your response

                Response format when presenting predictions:
                ```
                Based on our discussion, I've prepared the following values:

                **Predicted Values:**
                - Contract Type: [predicted value]
                - Evaluation Method: [predicted value]
                - Set-aside: [predicted value]

                Please confirm if these are correct, or let me know what needs to be changed.
                ```

                Respond in a conversational but professional manner as a government contracting expert.
                Format your response using markdown for better readability.
                """)
        ]

        let request = AICompletionRequest(
            messages: messages,
            model: "claude-sonnet-4-20250514",
            maxTokens: 2048,
            temperature: 0.7,
            systemPrompt: systemPrompt
        )

        let result = try await aiProvider.complete(request)

        // Spell check the AI response
        @Dependency(\.spellCheckService) var spellCheckService
        let aiResponse = await spellCheckService.checkAndCorrect(result.content)

        // Parse the AI response and extract updates
        var requirements = currentRequirements
        var readiness: [DocumentType: Bool] = [:]
        var recommended: Set<DocumentType> = []
        var nextPhase = phase
        var predictedValues: [String: String] = [:]

        // Check if AI response contains predictions
        if aiResponse.contains("**Predicted Values:**") || aiResponse.contains("Based on our discussion") {
            // Extract predictions from the response
            let lines = aiResponse.components(separatedBy: .newlines)
            for line in lines {
                if line.contains(":"), line.contains("-") {
                    let components = line.components(separatedBy: ":")
                    if components.count == 2 {
                        let key = components[0].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
                        let value = components[1].trimmingCharacters(in: .whitespaces)
                        predictedValues[key] = value
                    }
                }
            }

            // If we have predictions, move to confirmation phase
            if !predictedValues.isEmpty, phase != .confirmingPredictions {
                nextPhase = .confirmingPredictions
            }
        }

        // Check if user is confirming predictions
        let confirmationWords = ["yes", "correct", "confirm", "agreed", "looks good", "that's right", "accurate"]
        let userConfirming = confirmationWords.contains { input.lowercased().contains($0) }

        if userConfirming, phase == .confirmingPredictions {
            // User confirmed predictions
            nextPhase = .readyToGenerate

            // Mark all documents as ready
            for docType in preSelectedDocuments {
                readiness[docType] = true
            }
            recommended = preSelectedDocuments
        } else {
            // Continue with normal phase logic

            // Update requirements based on phase (same logic as before)
            switch phase {
            case .initial:
                requirements.productOrService = input
                nextPhase = .gatheringBasics

            case .gatheringBasics:
                if requirements.estimatedValue.isEmpty {
                    requirements.estimatedValue = input
                } else if requirements.performancePeriod.isEmpty {
                    requirements.performancePeriod = input
                } else if requirements.businessNeed.isEmpty {
                    requirements.businessNeed = input
                    nextPhase = .gatheringDetails
                    readiness[.marketResearch] = true
                    readiness[.rrd] = true
                    recommended.insert(.marketResearch)
                    recommended.insert(.rrd)
                }

            case .gatheringDetails:
                if input.lowercased() != "skip" {
                    requirements.technicalRequirements = input
                    readiness[.marketResearch] = true
                    readiness[.rrd] = true
                    readiness[.sow] = true
                    readiness[.costEstimate] = true
                    readiness[.acquisitionPlan] = true

                    // If we have pre-selected documents, use those
                    if !preSelectedDocuments.isEmpty {
                        recommended = preSelectedDocuments
                        // Mark all pre-selected documents as ready
                        for docType in preSelectedDocuments {
                            readiness[docType] = true
                        }
                    } else {
                        recommended = [.marketResearch, .rrd, .sow, .costEstimate, .acquisitionPlan]
                    }
                }
                nextPhase = .readyToGenerate

            case .analyzingRequirements, .readyToGenerate:
                nextPhase = .readyToGenerate

            case .confirmingPredictions:
                // When confirming predictions, maintain current state
                nextPhase = .confirmingPredictions
            }

            // Predict project title if not set
            if requirements.projectTitle.isEmpty, !requirements.productOrService.isEmpty {
                requirements.projectTitle = "Acquisition for \(requirements.productOrService)"
            }
        }

        // Return enhanced response with predictions
        return (aiResponse, requirements, readiness, recommended, nextPhase, predictedValues)
    }
}

// Helper extension to convert ChatPhase to AcquisitionPhase
private extension AcquisitionChatFeature.ChatPhase {
    func toAcquisitionPhase() -> AcquisitionPhase {
        switch self {
        case .initial, .gatheringBasics, .gatheringDetails:
            .planning
        case .analyzingRequirements:
            .requirementsDevelopment
        case .confirmingPredictions, .readyToGenerate:
            .planning
        }
    }
}

public enum AcquisitionChatFeatureError: Error {
    case noProvider
}
