import AppCore
import ComposableArchitecture
import Foundation

@Reducer
public struct DocumentAnalysisFeature {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var requirements: String = ""
        public var isAnalyzingRequirements: Bool = false
        public var showingLLMConfirmation: Bool = false
        public var recommendedDocuments: [DocumentType] = []
        public var showingDocumentRecommendation: Bool = false
        public var conversationHistory: [String] = []
        public var llmResponse: String = ""
        public var documentReadinessStatus: [DocumentType: DocumentStatus] = [:]
        public var error: String?

        // Document upload states
        public var showingDocumentPicker = false
        public var showingImagePicker = false
        public var uploadedDocuments: [UploadedDocument] = []
        public var isProcessingDocuments = false

        // Acquisition tracking
        public var currentAcquisitionId: UUID?
        public var currentAcquisitionTitle: String = ""

        // Workflow integration
        public var workflowContext: WorkflowContext?
        public var suggestedPrompts: [SuggestedPrompt] = []
        public var showingAutomationSettings = false
        public var automationSettings = AutomationSettings()
        public var pendingApprovals: [WorkflowStep] = []
        public var isLoadingAcquisition = false

        // Document chain tracking
        public var documentChain: DocumentChainProgress?
        public var chainValidation: ChainValidation?

        // Voice recording state
        public var isRecording: Bool = false

        public init() {}
    }

    public enum Action {
        case requirementsChanged(String)
        case analyzeRequirements
        case requirementsAnalyzed(String, [DocumentType])
        case analysisError(String)
        case confirmRequirements(Bool)
        case showDocumentRecommendation(Bool)
        case addToConversation(String)
        case updateLLMResponse(String)
        case updateDocumentStatus(DocumentType, DocumentStatus)
        case showDocumentPicker(Bool)
        case showImagePicker(Bool)
        case uploadDocument(Data, String)
        case uploadDocuments([(Data, String)])
        case documentUploaded(String, [DocumentType])
        case documentsProcessed([UploadedDocument])
        case uploadImage(Data)
        case imageUploaded(String, [DocumentType])
        case removeUploadedDocument(UploadedDocument.ID)
        case clearError
        case createAcquisition
        case acquisitionCreated(UUID)
        case updateAcquisitionTitle(String)
        case enhancePrompt
        case promptEnhanced(String)
        case startVoiceRecording
        case stopVoiceRecording
        case voiceTranscriptionReceived(String)

        // Workflow actions
        case loadAcquisition(UUID)
        case acquisitionLoaded(AppCore.Acquisition, WorkflowContext)
        case workflowStateChanged(WorkflowState)
        case selectPrompt(SuggestedPrompt)
        case processPromptResponse(String, CollectedData)
        case toggleAutomationSettings(Bool)
        case updateAutomationSettings(AutomationSettings)
        case approveWorkflowStep(WorkflowStep.ID, ApprovalStatus)
        case refreshWorkflowContext
        case workflowContextUpdated(WorkflowContext)

        // Document chain actions
        case createDocumentChain([DocumentType])
        case documentChainCreated(DocumentChainProgress)
        case validateDocumentChain
        case chainValidated(ChainValidation)
        case documentGeneratedInChain(GeneratedDocument)

        // State management
        case saveCurrentState
    }

    public enum DocumentStatus: Equatable, Sendable {
        case notReady
        case needsMoreInfo
        case ready
    }

    @Dependency(\.requirementAnalyzer) var requirementAnalyzer
    @Dependency(\.acquisitionService) var acquisitionService
    @Dependency(\.workflowEngine) var workflowEngine
    @Dependency(\.documentChainManager) var documentChainManager
    @Dependency(\.voiceRecordingClient) var voiceRecordingClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .requirementsChanged(requirements):
                state.requirements = requirements
                return .none

            case .analyzeRequirements:
                guard !state.requirements.isEmpty || !state.uploadedDocuments.isEmpty else { return .none }

                state.isAnalyzingRequirements = true
                state.error = nil

                // Create acquisition and workflow if this is a new analysis
                if state.currentAcquisitionId == nil {
                    return .concatenate(
                        .send(.createAcquisition),
                        .run { [requirements = state.requirements,
                                uploadedDocs = state.uploadedDocuments,
                                requirementAnalyzer = self.requirementAnalyzer] send in
                                // Build enhanced requirements including uploaded documents
                                var enhancedRequirements = requirements

                                if !uploadedDocs.isEmpty {
                                    enhancedRequirements += "\n\nAdditional context from uploaded documents:\n"
                                    for doc in uploadedDocs {
                                        if let summary = doc.contentSummary {
                                            enhancedRequirements += "\n- \(doc.fileName): \(summary)"
                                        }
                                    }
                                }

                                await send(.addToConversation("User: \(requirements)"))
                                if !uploadedDocs.isEmpty {
                                    await send(.addToConversation("[Uploaded \(uploadedDocs.count) document(s)]"))
                                }

                                do {
                                    let (response, recommendedDocs) = try await requirementAnalyzer.analyzeRequirements(enhancedRequirements)
                                    await send(.requirementsAnalyzed(response, recommendedDocs))
                                } catch {
                                    await send(.analysisError(error.localizedDescription))
                                }
                        }
                    )
                } else {
                    // Acquisition already exists, just analyze
                    return .run { [requirements = state.requirements,
                                   uploadedDocs = state.uploadedDocuments,
                                   requirementAnalyzer = self.requirementAnalyzer] send in
                            // Build enhanced requirements including uploaded documents
                            var enhancedRequirements = requirements

                            if !uploadedDocs.isEmpty {
                                enhancedRequirements += "\n\nAdditional context from uploaded documents:\n"
                                for doc in uploadedDocs {
                                    if let summary = doc.contentSummary {
                                        enhancedRequirements += "\n- \(doc.fileName): \(summary)"
                                    }
                                }
                            }

                            await send(.addToConversation("User: \(requirements)"))
                            if !uploadedDocs.isEmpty {
                                await send(.addToConversation("[Uploaded \(uploadedDocs.count) document(s)]"))
                            }

                            do {
                                let (response, recommendedDocs) = try await requirementAnalyzer.analyzeRequirements(enhancedRequirements)
                                await send(.requirementsAnalyzed(response, recommendedDocs))
                            } catch {
                                await send(.analysisError(error.localizedDescription))
                            }
                    }
                }

            case let .requirementsAnalyzed(response, recommendedDocs):
                state.isAnalyzingRequirements = false
                state.llmResponse = response
                state.recommendedDocuments = recommendedDocs
                state.conversationHistory.append("AIKO: \(response)")

                // In chat mode with loaded acquisition, don't show confirmation dialog
                // Just update the conversation and clear the input
                if state.currentAcquisitionId != nil, state.requirements.isEmpty == false {
                    // This is a chat message, not initial analysis
                    state.requirements = "" // Clear input after sending
                    // Don't show LLM confirmation for chat messages
                } else {
                    // Initial analysis mode - no longer show confirmation dialog
                    // The Agentic Chat Interface will be used instead when needed
                    state.showingLLMConfirmation = false
                }

                // Update document readiness status
                for docType in DocumentType.allCases {
                    if recommendedDocs.contains(docType) {
                        state.documentReadinessStatus[docType] = .ready
                    } else {
                        state.documentReadinessStatus[docType] = .needsMoreInfo
                    }
                }

                return .none

            case let .analysisError(error):
                state.isAnalyzingRequirements = false
                state.error = error
                return .none

            case let .confirmRequirements(confirmed):
                state.showingLLMConfirmation = false

                if confirmed, !state.recommendedDocuments.isEmpty {
                    state.showingDocumentRecommendation = true
                }

                return .none

            case let .showDocumentRecommendation(show):
                state.showingDocumentRecommendation = show
                return .none

            case let .addToConversation(message):
                state.conversationHistory.append(message)
                return .none

            case let .updateLLMResponse(response):
                state.llmResponse = response
                return .none

            case let .updateDocumentStatus(documentType, status):
                state.documentReadinessStatus[documentType] = status
                return .none

            case let .showDocumentPicker(show):
                state.showingDocumentPicker = show
                return .none

            case let .showImagePicker(show):
                state.showingImagePicker = show
                return .none

            case let .uploadDocument(data, fileName):
                state.isAnalyzingRequirements = true
                state.error = nil

                return .run { [requirementAnalyzer = self.requirementAnalyzer] send in
                    await send(.addToConversation("User uploaded: \(fileName)"))

                    do {
                        let (response, recommendedDocs) = try await requirementAnalyzer.analyzeDocumentContent(data, fileName)
                        await send(.documentUploaded(response, recommendedDocs))
                    } catch {
                        await send(.analysisError(error.localizedDescription))
                    }
                }

            case let .documentUploaded(response, recommendedDocs):
                state.isAnalyzingRequirements = false
                state.llmResponse = response
                state.recommendedDocuments = recommendedDocs
                state.conversationHistory.append("AIKO: \(response)")
                state.showingLLMConfirmation = true

                // Update document readiness status based on completeness assessment
                let completenessScore = extractCompletenessScore(from: response)

                for docType in DocumentType.allCases {
                    if recommendedDocs.contains(docType) {
                        state.documentReadinessStatus[docType] = completenessScore >= 5 ? .ready : .needsMoreInfo
                    } else {
                        state.documentReadinessStatus[docType] = .notReady
                    }
                }

                return .none

            case let .uploadDocuments(documents):
                state.isProcessingDocuments = true
                state.error = nil
                state.showingDocumentPicker = false

                return .run { [existingDocs = state.uploadedDocuments, requirementAnalyzer = self.requirementAnalyzer] send in
                    var processedDocs = existingDocs

                    for (data, fileName) in documents {
                        await send(.addToConversation("User uploaded: \(fileName)"))

                        do {
                            // Get a quick summary of the document for display
                            let (summary, _) = try await requirementAnalyzer.analyzeDocumentContent(data, fileName)
                            let doc = UploadedDocument(fileName: fileName, data: data, contentSummary: summary)
                            processedDocs.append(doc)
                        } catch {
                            await send(.analysisError("Failed to process \(fileName): \(error.localizedDescription)"))
                        }
                    }

                    await send(.documentsProcessed(processedDocs))
                }

            case let .documentsProcessed(documents):
                state.isProcessingDocuments = false
                state.uploadedDocuments = documents

                // Update requirements with combined content summary
                if !documents.isEmpty {
                    let fileNames = documents.map(\.fileName).joined(separator: ", ")
                    state.requirements += "\n\nUploaded documents: \(fileNames)"
                }

                return .none

            case let .removeUploadedDocument(id):
                state.uploadedDocuments.removeAll { $0.id == id }
                return .none

            case let .uploadImage(data):
                state.isAnalyzingRequirements = true
                state.error = nil

                return .run { [requirementAnalyzer = self.requirementAnalyzer] send in
                    await send(.addToConversation("User uploaded an image"))

                    do {
                        let (response, recommendedDocs) = try await requirementAnalyzer.analyzeDocumentContent(data, "image.jpg")
                        await send(.imageUploaded(response, recommendedDocs))
                    } catch {
                        await send(.analysisError(error.localizedDescription))
                    }
                }

            case let .imageUploaded(response, recommendedDocs):
                return .send(.documentUploaded(response, recommendedDocs))

            case .clearError:
                state.error = nil
                return .none

            case .enhancePrompt:
                guard !state.requirements.isEmpty else { return .none }

                state.isAnalyzingRequirements = true

                return .run { [requirements = state.requirements, requirementAnalyzer = self.requirementAnalyzer] send in
                    do {
                        // Use AI to enhance the prompt
                        let enhancedPrompt = try await requirementAnalyzer.enhancePrompt(requirements)
                        await send(.promptEnhanced(enhancedPrompt))
                    } catch {
                        // If enhancement fails, keep the original prompt
                        await send(.promptEnhanced(requirements))
                    }
                }

            case let .promptEnhanced(enhancedPrompt):
                state.isAnalyzingRequirements = false
                state.requirements = enhancedPrompt
                return .none

            case .startVoiceRecording:
                state.isRecording = true

                return .run { [voiceRecordingClient = self.voiceRecordingClient] send in
                    do {
                        // Check permissions first
                        let hasPermissions = voiceRecordingClient.checkPermissions()
                        if !hasPermissions {
                            let granted = await voiceRecordingClient.requestPermissions()
                            if !granted {
                                await send(.analysisError("Microphone access is required for voice input. Please enable it in Settings."))
                                await send(.stopVoiceRecording)
                                return
                            }
                        }

                        // Start recording
                        try await voiceRecordingClient.startRecording()
                    } catch {
                        await send(.analysisError("Failed to start voice recording."))
                        await send(.stopVoiceRecording)
                    }
                }

            case .stopVoiceRecording:
                state.isRecording = false

                return .run { [voiceRecordingClient = self.voiceRecordingClient] send in
                    do {
                        let transcription = try await voiceRecordingClient.stopRecording()
                        await send(.voiceTranscriptionReceived(transcription))
                    } catch {
                        await send(.analysisError("Failed to process voice recording."))
                    }
                }

            case let .voiceTranscriptionReceived(text):
                state.requirements = text
                return .none

            case .createAcquisition:
                // Generate a title from requirements or default
                let title = state.requirements.isEmpty ? "New Acquisition" : String(state.requirements.prefix(50))
                state.currentAcquisitionTitle = title

                return .run { [title, requirements = state.requirements, uploadedDocs = state.uploadedDocuments, acquisitionService = self.acquisitionService] send in
                    do {
                        let acquisition = try await acquisitionService.createAcquisition(
                            title,
                            requirements,
                            uploadedDocs
                        )
                        await send(.acquisitionCreated(acquisition.id))
                    } catch {
                        await send(.analysisError("Failed to create acquisition: \(error.localizedDescription)"))
                    }
                }

            case let .acquisitionCreated(id):
                state.currentAcquisitionId = id

                // Start workflow for the new acquisition
                return .run { [workflowEngine = self.workflowEngine, id] send in
                    do {
                        let workflowContext = try await workflowEngine.startWorkflow(id)
                        await send(.workflowContextUpdated(workflowContext))

                        // Move to gathering requirements state
                        await send(.workflowStateChanged(.gatheringRequirements))
                    } catch {
                        // Workflow is optional, don't fail the acquisition creation
                        print("Failed to start workflow: \(error)")
                    }
                }

            case let .updateAcquisitionTitle(title):
                state.currentAcquisitionTitle = title

                guard let acquisitionId = state.currentAcquisitionId else { return .none }

                return .run { [acquisitionService = self.acquisitionService, acquisitionId] send in
                    do {
                        try await acquisitionService.updateAcquisition(acquisitionId) { acquisition in
                            acquisition.title = title
                        }
                    } catch {
                        await send(.analysisError("Failed to update acquisition title: \(error.localizedDescription)"))
                    }
                }

            // Workflow actions
            case let .loadAcquisition(acquisitionId):
                state.isLoadingAcquisition = true
                state.error = nil

                return .run { [acquisitionService = self.acquisitionService, workflowEngine = self.workflowEngine] send in
                    do {
                        guard let acquisition = try await acquisitionService.fetchAcquisition(acquisitionId) else {
                            throw AcquisitionError.notFound
                        }

                        let workflowContext = try await workflowEngine.loadWorkflow(acquisitionId)
                        await send(.acquisitionLoaded(acquisition, workflowContext))
                    } catch {
                        await send(.analysisError("Failed to load acquisition: \(error.localizedDescription)"))
                    }
                }

            case let .acquisitionLoaded(acquisition, workflowContext):
                state.isLoadingAcquisition = false
                state.currentAcquisitionId = acquisition.id
                state.currentAcquisitionTitle = acquisition.title
                state.requirements = "" // Keep input field empty when loading acquisition
                state.workflowContext = workflowContext
                state.suggestedPrompts = workflowContext.suggestedPrompts
                state.pendingApprovals = workflowContext.pendingApprovals
                state.automationSettings = workflowContext.automationSettings

                // Initialize chat conversation
                let generatedCount = acquisition.generatedFilesArray.count
                let uploadedCount = acquisition.uploadedFilesArray.count
                state.conversationHistory.append("AIKO: Welcome back! I have loaded your acquisition. You have \(generatedCount) generated documents and \(uploadedCount) uploaded files. How may I assist you with this acquisition?")

                // Load any uploaded files
                state.uploadedDocuments = acquisition.uploadedFilesArray.map { file in
                    UploadedDocument(
                        fileName: file.fileName,
                        data: file.data,
                        uploadDate: file.uploadDate,
                        contentSummary: file.contentSummary
                    )
                }

                return .none

            case let .workflowStateChanged(newState):
                guard let acquisitionId = state.currentAcquisitionId else { return .none }

                return .run { [workflowEngine = self.workflowEngine, acquisitionId] send in
                    do {
                        let updatedContext = try await workflowEngine.updateWorkflowState(acquisitionId, newState)
                        await send(.workflowContextUpdated(updatedContext))
                    } catch {
                        await send(.analysisError("Failed to update workflow state: \(error.localizedDescription)"))
                    }
                }

            case let .selectPrompt(prompt):
                state.conversationHistory.append("Selected: \(prompt.prompt)")

                // Handle different prompt categories
                switch prompt.category {
                case .nextStep:
                    if let nextState = prompt.nextState {
                        return .send(.workflowStateChanged(nextState))
                    }
                case .documentSelection:
                    // Handle document selection
                    return .none
                case .dataCollection:
                    // Prepare for data collection
                    return .none
                case .approval:
                    // Show approval UI
                    return .none
                case .clarification:
                    // Handle clarification request
                    return .none
                }

                return .none

            case let .processPromptResponse(response, extractedData):
                guard let acquisitionId = state.currentAcquisitionId else { return .none }

                return .run { [workflowEngine = self.workflowEngine, acquisitionId] send in
                    do {
                        let updatedContext = try await workflowEngine.processLLMResponse(
                            acquisitionId,
                            response,
                            extractedData
                        )
                        await send(.workflowContextUpdated(updatedContext))
                    } catch {
                        await send(.analysisError("Failed to process response: \(error.localizedDescription)"))
                    }
                }

            case let .toggleAutomationSettings(show):
                state.showingAutomationSettings = show
                return .none

            case let .updateAutomationSettings(settings):
                state.automationSettings = settings

                guard let acquisitionId = state.currentAcquisitionId,
                      var context = state.workflowContext else { return .none }

                context.automationSettings = settings
                state.workflowContext = context

                return .run { [workflowEngine = self.workflowEngine, acquisitionId, settings] send in
                    do {
                        // Save automation settings
                        let encoder = JSONEncoder()
                        if let settingsData = try? encoder.encode(settings),
                           let settingsString = String(data: settingsData, encoding: .utf8) {
                            let collectedData = CollectedData(data: ["automationSettings": settingsString])
                            try await workflowEngine.collectData(acquisitionId, collectedData)
                        }
                    } catch {
                        await send(.analysisError("Failed to save automation settings: \(error.localizedDescription)"))
                    }
                }

            case let .approveWorkflowStep(stepId, status):
                guard let acquisitionId = state.currentAcquisitionId else { return .none }

                return .run { [workflowEngine = self.workflowEngine, acquisitionId] send in
                    do {
                        let updatedContext = try await workflowEngine.processApproval(
                            acquisitionId,
                            stepId,
                            status
                        )
                        await send(.workflowContextUpdated(updatedContext))
                    } catch {
                        await send(.analysisError("Failed to process approval: \(error.localizedDescription)"))
                    }
                }

            case .refreshWorkflowContext:
                guard let acquisitionId = state.currentAcquisitionId else { return .none }

                return .run { [workflowEngine = self.workflowEngine, acquisitionId] send in
                    do {
                        let updatedContext = try await workflowEngine.loadWorkflow(acquisitionId)
                        await send(.workflowContextUpdated(updatedContext))
                    } catch {
                        await send(.analysisError("Failed to refresh workflow: \(error.localizedDescription)"))
                    }
                }

            case let .workflowContextUpdated(context):
                state.workflowContext = context
                state.suggestedPrompts = context.suggestedPrompts
                state.pendingApprovals = context.pendingApprovals

                // Generate new prompts if needed
                if context.suggestedPrompts.isEmpty {
                    return .run { [context, workflowEngine = self.workflowEngine] send in
                        do {
                            let prompts = try await workflowEngine.generatePrompts(context)
                            var updatedContext = context
                            updatedContext.suggestedPrompts = prompts
                            await send(.workflowContextUpdated(updatedContext))
                        } catch {
                            // Prompts generation is not critical
                        }
                    }
                }

                return .none

            // Document Chain Actions
            case let .createDocumentChain(documentTypes):
                guard let acquisitionId = state.currentAcquisitionId else { return .none }

                return .run { [documentChainManager = self.documentChainManager, acquisitionId] send in
                    do {
                        let chain = try await documentChainManager.createChain(acquisitionId, documentTypes)
                        await send(.documentChainCreated(chain))
                        await send(.validateDocumentChain)
                    } catch {
                        await send(.analysisError("Failed to create document chain: \(error.localizedDescription)"))
                    }
                }

            case let .documentChainCreated(chain):
                state.documentChain = chain
                return .none

            case .validateDocumentChain:
                guard let acquisitionId = state.currentAcquisitionId else { return .none }

                return .run { [documentChainManager = self.documentChainManager, acquisitionId] send in
                    do {
                        let validation = try await documentChainManager.validateChain(acquisitionId)
                        await send(.chainValidated(validation))
                    } catch {
                        await send(.analysisError("Failed to validate chain: \(error.localizedDescription)"))
                    }
                }

            case let .chainValidated(validation):
                state.chainValidation = validation
                return .none

            case let .documentGeneratedInChain(document):
                guard let acquisitionId = state.currentAcquisitionId,
                      let documentType = document.documentType else { return .none }

                let hasWorkflowContext = state.workflowContext != nil

                return .run { [documentChainManager = self.documentChainManager, workflowEngine = self.workflowEngine, acquisitionId, hasWorkflowContext] send in
                    do {
                        // Update chain progress
                        let updatedChain = try await documentChainManager.updateChainProgress(
                            acquisitionId,
                            documentType,
                            document
                        )
                        await send(.documentChainCreated(updatedChain))

                        // Extract and propagate data
                        let propagatedData = try await documentChainManager.extractAndPropagate(
                            acquisitionId,
                            document
                        )

                        // Update workflow context with propagated data
                        if hasWorkflowContext {
                            try await workflowEngine.collectData(
                                acquisitionId,
                                propagatedData
                            )
                            // Context will be updated through workflow engine
                        }

                        // Get next document in chain
                        if let nextDocument = try await documentChainManager.getNextInChain(acquisitionId) {
                            await send(.addToConversation("Ready to generate \(nextDocument.shortName). This document will use data from previously generated documents."))
                        }

                        // Validate chain after update
                        await send(.validateDocumentChain)
                    } catch {
                        await send(.analysisError("Failed to update document chain: \(error.localizedDescription)"))
                    }
                }

            case .saveCurrentState:
                // Save current state to Core Data
                guard let acquisitionId = state.currentAcquisitionId else { return .none }

                return .run { [state, acquisitionService = self.acquisitionService, acquisitionId] send in
                    do {
                        // Update acquisition with current state
                        try await acquisitionService.updateAcquisition(acquisitionId) { acquisition in
                            acquisition.requirements = state.requirements
                            acquisition.title = state.currentAcquisitionTitle.isEmpty ? "Untitled Acquisition" : state.currentAcquisitionTitle
                        }

                        // Workflow context and document chain are saved automatically
                    } catch {
                        await send(.analysisError("Failed to save acquisition state: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }

    // Helper function to extract completeness score from LLM response
    private func extractCompletenessScore(from response: String) -> Int {
        let patterns = [
            "COMPLETENESS ASSESSMENT: (\\d+)",
            "completeness.*?(\\d+)",
            "score.*?(\\d+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: response, options: [], range: NSRange(location: 0, length: response.count)),
               let scoreRange = Range(match.range(at: 1), in: response) {
                if let score = Int(response[scoreRange]) {
                    return score
                }
            }
        }

        return 5 // Default moderate score if not found
    }
}
