import ComposableArchitecture
import CoreData
import Foundation

public struct WorkflowEngine {
    public var startWorkflow: (UUID) async throws -> WorkflowContext
    public var loadWorkflow: (UUID) async throws -> WorkflowContext
    public var updateWorkflowState: (UUID, WorkflowState) async throws -> WorkflowContext
    public var recordWorkflowStep: (UUID, WorkflowStep) async throws -> Void
    public var collectData: (UUID, CollectedData) async throws -> Void
    public var generatePrompts: (WorkflowContext) async throws -> [SuggestedPrompt]
    public var processLLMResponse: (UUID, String, CollectedData) async throws -> WorkflowContext
    public var requestApproval: (UUID, WorkflowStep) async throws -> Void
    public var processApproval: (UUID, UUID, ApprovalStatus) async throws -> WorkflowContext
    public var getNextSteps: (WorkflowContext) -> [WorkflowState]
    public var shouldAutomate: (WorkflowContext, WorkflowState) -> Bool
    public var extractDataFromDocument: (GeneratedDocument) async throws -> CollectedData
    public var buildDocumentContext: (UUID, DocumentType) async throws -> DocumentGenerationContext

    public init(
        startWorkflow: @escaping (UUID) async throws -> WorkflowContext,
        loadWorkflow: @escaping (UUID) async throws -> WorkflowContext,
        updateWorkflowState: @escaping (UUID, WorkflowState) async throws -> WorkflowContext,
        recordWorkflowStep: @escaping (UUID, WorkflowStep) async throws -> Void,
        collectData: @escaping (UUID, CollectedData) async throws -> Void,
        generatePrompts: @escaping (WorkflowContext) async throws -> [SuggestedPrompt],
        processLLMResponse: @escaping (UUID, String, CollectedData) async throws -> WorkflowContext,
        requestApproval: @escaping (UUID, WorkflowStep) async throws -> Void,
        processApproval: @escaping (UUID, UUID, ApprovalStatus) async throws -> WorkflowContext,
        getNextSteps: @escaping (WorkflowContext) -> [WorkflowState],
        shouldAutomate: @escaping (WorkflowContext, WorkflowState) -> Bool,
        extractDataFromDocument: @escaping (GeneratedDocument) async throws -> CollectedData,
        buildDocumentContext: @escaping (UUID, DocumentType) async throws -> DocumentGenerationContext
    ) {
        self.startWorkflow = startWorkflow
        self.loadWorkflow = loadWorkflow
        self.updateWorkflowState = updateWorkflowState
        self.recordWorkflowStep = recordWorkflowStep
        self.collectData = collectData
        self.generatePrompts = generatePrompts
        self.processLLMResponse = processLLMResponse
        self.requestApproval = requestApproval
        self.processApproval = processApproval
        self.getNextSteps = getNextSteps
        self.shouldAutomate = shouldAutomate
        self.extractDataFromDocument = extractDataFromDocument
        self.buildDocumentContext = buildDocumentContext
    }
}

extension WorkflowEngine: DependencyKey {
    public static var liveValue: WorkflowEngine {
        _ = CoreDataStack.shared
        _ = RequirementAnalyzer.liveValue
        let userProfileService = UserProfileService.liveValue
        let acquisitionService = AcquisitionService.liveValue
        let documentDependencyService = DocumentDependencyService.liveValue

        return WorkflowEngine(
            startWorkflow: { acquisitionId in
                let context = WorkflowContext(
                    acquisitionId: acquisitionId,
                    currentState: .initial,
                    automationSettings: loadAutomationSettings()
                )

                // Record initial step
                _ = WorkflowStep(
                    state: .initial,
                    action: "Workflow started",
                    requiresApproval: false
                )

                // Save to Core Data
                try await saveWorkflowContext(context, to: acquisitionId)

                return context
            },

            loadWorkflow: { acquisitionId in
                guard let acquisition = try await acquisitionService.fetchAcquisition(acquisitionId) else {
                    throw WorkflowError.acquisitionNotFound
                }

                // Load workflow data from Core Data
                let workflowData = try await loadWorkflowData(from: acquisition)

                return WorkflowContext(
                    acquisitionId: acquisitionId,
                    currentState: workflowData.currentState,
                    workflowSteps: workflowData.steps,
                    automationSettings: workflowData.automationSettings,
                    collectedData: workflowData.collectedData,
                    suggestedPrompts: [],
                    pendingApprovals: workflowData.pendingApprovals
                )
            },

            updateWorkflowState: { acquisitionId, newState in
                var context = try await loadWorkflowContext(for: acquisitionId)
                let previousState = context.currentState
                context.currentState = newState

                // Record state transition
                let step = WorkflowStep(
                    state: newState,
                    action: "Transitioned from \(previousState.displayName) to \(newState.displayName)",
                    requiresApproval: false
                )
                context.workflowSteps.append(step)

                // Generate new prompts for the new state
                context.suggestedPrompts = try await generatePromptsForState(newState, context: context)

                // Save updated context
                try await saveWorkflowContext(context, to: acquisitionId)

                return context
            },

            recordWorkflowStep: { acquisitionId, step in
                var context = try await loadWorkflowContext(for: acquisitionId)
                context.workflowSteps.append(step)

                if step.requiresApproval {
                    context.pendingApprovals.append(step)
                }

                try await saveWorkflowContext(context, to: acquisitionId)
            },

            collectData: { acquisitionId, data in
                var context = try await loadWorkflowContext(for: acquisitionId)

                // Merge new data with existing
                for (key, value) in data.data {
                    context.collectedData[key] = value
                }

                // Update Core Data
                try await updateAcquisitionData(acquisitionId, with: data)
                try await saveWorkflowContext(context, to: acquisitionId)
            },

            generatePrompts: { context in
                var prompts: [SuggestedPrompt] = []

                // Based on current state and collected data, generate relevant prompts
                switch context.currentState {
                case .gatheringRequirements:
                    prompts.append(SuggestedPrompt(
                        prompt: "What type of acquisition is this? (e.g., Services, Supplies, Construction)",
                        category: .dataCollection,
                        priority: .high,
                        dataToCollect: ["acquisitionType"]
                    ))
                    prompts.append(SuggestedPrompt(
                        prompt: "What is the estimated value of this acquisition?",
                        category: .dataCollection,
                        priority: .high,
                        dataToCollect: ["estimatedValue"]
                    ))

                case .analyzingRequirements:
                    prompts.append(SuggestedPrompt(
                        prompt: "Would you like me to suggest appropriate documents based on your requirements?",
                        category: .documentSelection,
                        priority: .high,
                        nextState: .suggestingDocuments
                    ))

                case .suggestingDocuments:
                    let existingDocs = try await fetchGeneratedDocumentTypes(for: context.acquisitionId)
                    let suggestedDocs = documentDependencyService.suggestNextDocuments(existingDocs, context.collectedData)

                    for doc in suggestedDocs {
                        // Check dependencies for this document
                        let validation = try await documentDependencyService.validateDependencies(
                            fetchPreviousDocuments(for: context.acquisitionId),
                            doc
                        )

                        let priority: SuggestedPrompt.PromptPriority
                        var promptText = "Generate \(doc.shortName)"

                        if !validation.isValid {
                            priority = .low
                            if !validation.missingDocuments.isEmpty {
                                promptText += " (Missing: \(validation.missingDocuments.map(\.shortName).joined(separator: ", ")))"
                            }
                        } else if validation.warnings.isEmpty {
                            priority = .high
                            promptText += " ✓"
                        } else {
                            priority = .medium
                        }

                        prompts.append(SuggestedPrompt(
                            prompt: promptText,
                            category: .documentSelection,
                            priority: priority,
                            dataToCollect: ["selectedDocument_\(doc.rawValue)"]
                        ))
                    }

                case .collectingData:
                    let missingFields = try await identifyMissingDataFields(context)
                    for field in missingFields {
                        prompts.append(SuggestedPrompt(
                            prompt: "Please provide: \(field.displayName)",
                            category: .dataCollection,
                            priority: field.isRequired ? .high : .medium,
                            dataToCollect: [field.key]
                        ))
                    }

                case .generatingDocuments:
                    if context.automationSettings.requireApprovalForDocumentGeneration {
                        prompts.append(SuggestedPrompt(
                            prompt: "Review and approve document generation?",
                            category: .approval,
                            priority: .critical
                        ))
                    }

                default:
                    break
                }

                // Add next step suggestions
                let nextSteps = context.currentState.nextStates
                for nextState in nextSteps {
                    prompts.append(SuggestedPrompt(
                        prompt: "Proceed to \(nextState.displayName)?",
                        category: .nextStep,
                        priority: .low,
                        nextState: nextState
                    ))
                }

                return prompts.sorted { $0.priority.rawValue > $1.priority.rawValue }
            },

            processLLMResponse: { acquisitionId, response, extractedData in
                var context = try await loadWorkflowContext(for: acquisitionId)

                // Extract and store data from LLM response
                let processedData = try await processAndExtractData(from: response, existingData: context.collectedData)

                // Merge with provided extracted data
                var mergedData = processedData
                for (key, value) in extractedData.data {
                    mergedData.data[key] = value
                }

                // Update context
                context.collectedData = mergedData

                // Record the interaction
                let step = WorkflowStep(
                    state: context.currentState,
                    action: "Processed LLM response",
                    llmPrompt: nil,
                    userResponse: response,
                    dataCollected: extractedData,
                    requiresApproval: false
                )
                context.workflowSteps.append(step)

                // Update Core Data
                try await updateAcquisitionData(acquisitionId, with: processedData)

                // Generate new prompts based on updated data
                context.suggestedPrompts = try await generatePromptsForState(context.currentState, context: context)

                try await saveWorkflowContext(context, to: acquisitionId)

                return context
            },

            requestApproval: { acquisitionId, step in
                var context = try await loadWorkflowContext(for: acquisitionId)
                context.pendingApprovals.append(step)
                try await saveWorkflowContext(context, to: acquisitionId)

                // Notify user of pending approval (could integrate with notifications)
            },

            processApproval: { acquisitionId, stepId, status in
                var context = try await loadWorkflowContext(for: acquisitionId)

                // Find and update the approval step
                if let index = context.pendingApprovals.firstIndex(where: { $0.id == stepId }) {
                    var step = context.pendingApprovals[index]
                    step = WorkflowStep(
                        timestamp: step.timestamp,
                        state: step.state,
                        action: step.action,
                        llmPrompt: step.llmPrompt,
                        userResponse: step.userResponse,
                        dataCollected: step.dataCollected,
                        requiresApproval: step.requiresApproval,
                        approvalStatus: status
                    )

                    // Remove from pending
                    context.pendingApprovals.remove(at: index)

                    // Add to completed steps
                    context.workflowSteps.append(step)

                    // If approved and it was a state transition, update state
                    if status == .approved, let nextState = step.state.nextStates.first {
                        context.currentState = nextState
                    }
                }

                try await saveWorkflowContext(context, to: acquisitionId)

                return context
            },

            getNextSteps: { context in
                context.currentState.nextStates
            },

            shouldAutomate: { context, proposedState in
                guard context.automationSettings.enabled else { return false }

                switch proposedState {
                case .generatingDocuments:
                    return !context.automationSettings.requireApprovalForDocumentGeneration
                case .collectingData:
                    return !context.automationSettings.requireApprovalForDataCollection
                default:
                    return !context.automationSettings.requireApprovalForWorkflowTransitions
                }
            },

            extractDataFromDocument: { document in
                // Use dependency service to extract data
                documentDependencyService.extractDataForDependents(document)
            },

            buildDocumentContext: { acquisitionId, documentType in
                // Fetch all necessary data for document generation
                let acquisition = try await acquisitionService.fetchAcquisition(acquisitionId)
                let userProfile = try await userProfileService.loadProfile()
                let previousDocs = try await fetchPreviousDocuments(for: acquisitionId)

                let acquisitionData = try await extractAcquisitionData(from: acquisition)
                let profileData = extractProfileData(from: userProfile)
                var previousDocsData = CollectedData()
                for doc in previousDocs {
                    let extractedData = documentDependencyService.extractDataForDependents(doc)
                    for (key, value) in extractedData.data {
                        previousDocsData[key] = value
                    }
                }

                // Build template variables
                let templateVars = buildTemplateVariables(
                    acquisitionData: acquisitionData,
                    profileData: profileData,
                    previousDocsData: previousDocsData,
                    documentType: documentType
                )

                return DocumentGenerationContext(
                    documentType: documentType,
                    acquisitionData: acquisitionData,
                    userProfileData: profileData,
                    previousDocumentsData: previousDocsData,
                    templateVariables: templateVars
                )
            }
        )
    }
}

// MARK: - Helper Functions

private func loadAutomationSettings() -> AutomationSettings {
    // Load from UserDefaults or configuration
    AutomationSettings()
}

private func saveWorkflowContext(_: WorkflowContext, to _: UUID) async throws {
    // Save workflow context to Core Data or persistent storage
    // This would update the acquisition entity with workflow data
}

private func loadWorkflowContext(for _: UUID) async throws -> WorkflowContext {
    // Load workflow context from Core Data
    throw WorkflowError.notImplemented
}

private func loadWorkflowData(from _: Acquisition) async throws -> (currentState: WorkflowState, steps: [WorkflowStep], automationSettings: AutomationSettings, collectedData: CollectedData, pendingApprovals: [WorkflowStep]) {
    // Extract workflow data from Core Data
    throw WorkflowError.notImplemented
}

private func generatePromptsForState(_: WorkflowState, context _: WorkflowContext) async throws -> [SuggestedPrompt] {
    // Generate state-specific prompts
    []
}

private func updateAcquisitionData(_: UUID, with _: CollectedData) async throws {
    // Update acquisition entity with collected data
}

private func fetchGeneratedDocumentTypes(for acquisitionId: UUID) async throws -> [DocumentType] {
    let acquisition = try await AcquisitionService.liveValue.fetchAcquisition(acquisitionId)
    let generatedFiles = acquisition?.generatedFilesArray ?? []

    var documentTypes: [DocumentType] = []
    for file in generatedFiles {
        // Parse the document type from the file type string
        if let docType = DocumentType.allCases.first(where: { $0.rawValue == file.fileType }) {
            documentTypes.append(docType)
        }
    }

    return documentTypes
}

private func identifyMissingDataFields(_: WorkflowContext) async throws -> [(key: String, displayName: String, isRequired: Bool)] {
    // Identify missing required fields
    []
}

private func processAndExtractData(from _: String, existingData: CollectedData) async throws -> CollectedData {
    // Process LLM response and extract structured data
    existingData
}

private func parseDocumentContent(_: GeneratedDocument) async throws -> CollectedData {
    // Parse document and extract data
    CollectedData()
}

private func fetchPreviousDocuments(for _: UUID) async throws -> [GeneratedDocument] {
    // Fetch previously generated documents
    []
}

private func extractAcquisitionData(from _: Acquisition?) async throws -> CollectedData {
    // Extract data from acquisition entity
    CollectedData()
}

private func extractProfileData(from _: UserProfile?) -> CollectedData {
    // Extract data from user profile
    CollectedData()
}

private func extractDataFromDocuments(_: [GeneratedDocument]) async throws -> CollectedData {
    // Extract and merge data from multiple documents
    CollectedData()
}

private func buildTemplateVariables(acquisitionData _: CollectedData, profileData _: CollectedData, previousDocsData _: CollectedData, documentType _: DocumentType) -> [String: String] {
    // Build template variables for document generation
    [:]
}

// MARK: - Errors

enum WorkflowError: LocalizedError {
    case acquisitionNotFound
    case invalidState
    case missingRequiredData
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .acquisitionNotFound:
            "Acquisition not found"
        case .invalidState:
            "Invalid workflow state"
        case .missingRequiredData:
            "Missing required data for operation"
        case .notImplemented:
            "Feature not yet implemented"
        }
    }
}

public extension DependencyValues {
    var workflowEngine: WorkflowEngine {
        get { self[WorkflowEngine.self] }
        set { self[WorkflowEngine.self] = newValue }
    }
}
