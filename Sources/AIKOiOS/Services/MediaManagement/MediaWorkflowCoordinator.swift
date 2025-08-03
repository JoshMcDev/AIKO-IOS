import AppCore
import Combine
import Foundation

/// iOS implementation of media workflow coordinator
@available(iOS 16.0, *)
public actor MediaWorkflowCoordinator: MediaWorkflowCoordinatorProtocol {
    private var workflows: [UUID: MediaWorkflow] = [:]
    private var executions: [UUID: WorkflowExecutionState] = [:]
    private var templates: [String: MediaWorkflow] = [:]
    private var executionHistory: [WorkflowExecutionResult] = []
    private var progressContinuations: [UUID: AsyncStream<WorkflowExecutionUpdate>.Continuation] = [:]

    public init() {
        // Templates will be set up lazily when first accessed
    }

    // MARK: - Private Methods
    
    private func ensureTemplatesInitialized() {
        guard templates.isEmpty else { return }
        setupBuiltInTemplates()
    }

    // MARK: - MediaWorkflowCoordinatorProtocol Methods

    public func executeWorkflow(_ workflow: MediaWorkflow) async throws -> WorkflowExecutionHandle {
        let handle = WorkflowExecutionHandle(
            id: UUID(),
            workflowId: workflow.id,
            assetIds: [],
            startTime: Date()
        )
        
        // Store workflow for reference
        workflows[workflow.id] = workflow
        
        // Create execution state
        let executionState = WorkflowExecutionState(
            handle: handle,
            workflow: workflow,
            assets: [],
            status: .pending,
            currentStepIndex: 0,
            results: [],
            errors: []
        )
        executions[handle.id] = executionState
        
        // Start execution asynchronously
        Task {
            await performWorkflowExecution(handle: handle)
        }
        
        return handle
    }

    public func getWorkflowDefinitions() async -> [WorkflowDefinition] {
        return Array(workflows.values).map { workflow in
            WorkflowDefinition(
                id: workflow.id,
                name: workflow.name,
                version: "1.0",
                requiredSteps: workflow.steps.map { $0.type },
                supportedFormats: Set(["image", "video", "document"])
            )
        }
    }

    public func createWorkflowFromTemplate(_ template: WorkflowTemplate) async throws -> MediaWorkflow {
        ensureTemplatesInitialized()
        guard let templateWorkflow = templates[template.name] else {
            throw MediaError.processingFailed("Template '\(template.name)' not found")
        }
        
        // Create new workflow with unique ID from template
        let newWorkflow = MediaWorkflow(
            id: UUID(),
            name: "\(templateWorkflow.name) - Copy",
            description: templateWorkflow.description,
            steps: templateWorkflow.steps
        )
        
        workflows[newWorkflow.id] = newWorkflow
        return newWorkflow
    }

    public func getExecutionStatus(_ handle: WorkflowExecutionHandle) async throws -> WorkflowExecutionStatus {
        guard let execution = executions[handle.id] else {
            throw MediaError.processingFailed("Execution not found")
        }
        return execution.status
    }

    public func getExecutionResults(_ handle: WorkflowExecutionHandle) async throws -> WorkflowExecutionResult {
        guard let execution = executions[handle.id] else {
            throw MediaError.processingFailed("Execution not found")
        }
        
        return WorkflowExecutionResult(
            executionHandle: handle,
            status: execution.status,
            processedAssets: execution.results.map { $0.assetId },
            failedAssets: [],
            errors: execution.errors.map { $0.message },
            duration: Date().timeIntervalSince(handle.startTime)
        )
    }

    public func getAvailableTemplates() async -> [WorkflowTemplate] {
        ensureTemplatesInitialized()
        return templates.map { (name, workflow) in
            WorkflowTemplate(
                name: name,
                description: workflow.description,
                workflow: workflow,
                category: .general
            )
        }
    }

    public func getWorkflowCategories() async -> [WorkflowCategory] {
        return [
            .photography,
            .videos,
            .documents,
            .compression,
            .enhancement,
            .general
        ]
    }

    public func getWorkflowHistory(limit: Int) async -> [WorkflowExecutionResult] {
        return Array(executionHistory.suffix(limit))
    }

    public func validateWorkflow(_ definition: WorkflowDefinition) async -> WorkflowValidationResult {
        var errors: [String] = []
        let warnings: [String] = []
        
        // Basic validation
        if definition.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Workflow name cannot be empty")
        }
        
        if definition.requiredSteps.isEmpty {
            errors.append("Workflow must have at least one step")
        }
        
        // Step validation
        for (index, stepType) in definition.requiredSteps.enumerated() {
            if stepType.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Step \(index + 1) must have a name")
            }
        }
        
        return WorkflowValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }

    // MARK: - Extended Methods

    public func createWorkflow(_ definition: WorkflowDefinition) async throws -> MediaWorkflow {
        let validationResult = await validateWorkflow(definition)
        if !validationResult.isValid {
            throw MediaError.processingFailed("Invalid workflow definition: \(validationResult.errors.joined(separator: ", "))")
        }
        
        let workflow = MediaWorkflow(
            id: definition.id,
            name: definition.name,
            description: nil,
            steps: definition.requiredSteps.map { stepType in
                MediaWorkflowStep(
                    type: stepType,
                    name: stepType.displayName,
                    order: definition.requiredSteps.firstIndex(of: stepType) ?? 0
                )
            }
        )
        
        workflows[workflow.id] = workflow
        return workflow
    }

    public func executeWorkflow(_ workflow: MediaWorkflow, with assets: [MediaAsset]) async throws -> WorkflowExecutionHandle {
        let handle = WorkflowExecutionHandle(
            id: UUID(),
            workflowId: workflow.id,
            assetIds: assets.map { $0.id },
            startTime: Date()
        )
        
        // Store workflow for reference
        workflows[workflow.id] = workflow
        
        // Create execution state with assets
        let executionState = WorkflowExecutionState(
            handle: handle,
            workflow: workflow,
            assets: assets,
            status: .pending,
            currentStepIndex: 0,
            results: [],
            errors: []
        )
        executions[handle.id] = executionState
        
        // Start execution asynchronously
        Task {
            await performWorkflowExecution(handle: handle)
        }
        
        return handle
    }

    public func monitorExecution(_ handle: WorkflowExecutionHandle) -> AsyncStream<WorkflowExecutionUpdate> {
        return AsyncStream { continuation in
            progressContinuations[handle.id] = continuation
            
            // Send initial status
            if let execution = executions[handle.id] {
                let update = WorkflowExecutionUpdate(
                    executionId: handle.id,
                    status: execution.status,
                    currentStep: execution.currentStepIndex,
                    totalSteps: execution.workflow.steps.count,
                    processedAssets: 0,
                    message: "Monitoring started"
                )
                continuation.yield(update)
            }
            
            continuation.onTermination = { _ in
                Task { await self.removeProgressContinuation(for: handle.id) }
            }
        }
    }

    public func pauseExecution(_ handle: WorkflowExecutionHandle) async throws {
        guard var execution = executions[handle.id] else {
            throw MediaError.processingFailed("Execution not found")
        }
        
        guard execution.status == .running else {
            throw MediaError.processingFailed("Cannot pause execution in status: \(execution.status)")
        }
        
        execution.status = .paused
        executions[handle.id] = execution
        
        await notifyProgressUpdate(handle: handle, message: "Execution paused")
    }

    public func resumeExecution(_ handle: WorkflowExecutionHandle) async throws {
        guard var execution = executions[handle.id] else {
            throw MediaError.processingFailed("Execution not found")
        }
        
        guard execution.status == .paused else {
            throw MediaError.processingFailed("Cannot resume execution in status: \(execution.status)")
        }
        
        execution.status = .running
        executions[handle.id] = execution
        
        await notifyProgressUpdate(handle: handle, message: "Execution resumed")
        
        // Continue execution
        Task {
            await continueWorkflowExecution(handle: handle)
        }
    }

    public func cancelExecution(_ handle: WorkflowExecutionHandle) async throws {
        guard var execution = executions[handle.id] else {
            throw MediaError.processingFailed("Execution not found")
        }
        
        execution.status = .cancelled
        executions[handle.id] = execution
        
        await notifyProgressUpdate(handle: handle, message: "Execution cancelled")
        await finishExecution(handle: handle)
    }

    public func saveWorkflowTemplate(_ workflow: MediaWorkflow, name: String) async throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MediaError.invalidInput("Template name cannot be empty")
        }
        
        let templateWorkflow = MediaWorkflow(
            id: UUID(),
            name: workflow.name,
            description: workflow.description,
            steps: workflow.steps
        )
        
        templates[name] = templateWorkflow
    }

    public func loadWorkflowTemplate(_ name: String) async throws -> MediaWorkflow {
        guard let template = templates[name] else {
            throw MediaError.processingFailed("Template '\(name)' not found")
        }
        
        // Return a copy with new ID
        return MediaWorkflow(
            id: UUID(),
            name: template.name,
            description: template.description,
            steps: template.steps
        )
    }

    public func listWorkflowTemplates() async -> [WorkflowTemplate] {
        return await getAvailableTemplates()
    }

    public func deleteWorkflowTemplate(_ name: String) async throws {
        guard templates[name] != nil else {
            throw MediaError.processingFailed("Template '\(name)' not found")
        }
        
        templates.removeValue(forKey: name)
    }
    
    // MARK: - Private Execution Methods
    
    private func performWorkflowExecution(handle: WorkflowExecutionHandle) async {
        guard var execution = executions[handle.id] else { return }
        
        execution.status = .running
        executions[handle.id] = execution
        
        await notifyProgressUpdate(handle: handle, message: "Starting workflow execution")
        
        await continueWorkflowExecution(handle: handle)
    }
    
    private func continueWorkflowExecution(handle: WorkflowExecutionHandle) async {
        guard var execution = executions[handle.id] else { return }
        
        while execution.currentStepIndex < execution.workflow.steps.count && execution.status == .running {
            let step = execution.workflow.steps[execution.currentStepIndex]
            
            await notifyProgressUpdate(
                handle: handle,
                message: "Executing step: \(step.name)"
            )
            
            do {
                // Execute current step
                let stepResults = try await executeWorkflowStep(step, with: execution.assets)
                execution.results.append(contentsOf: stepResults)
                
                execution.currentStepIndex += 1
                executions[handle.id] = execution
                
                // Brief pause between steps to allow for cancellation/pausing
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                // Refresh execution state to check for status changes
                guard let updatedExecution = executions[handle.id] else { return }
                execution = updatedExecution
                
            } catch {
                let workflowError = WorkflowError(
                    message: error.localizedDescription,
                    stepIndex: execution.currentStepIndex,
                    assetId: nil
                )
                execution.errors.append(workflowError)
                execution.status = .failed
                executions[handle.id] = execution
                break
            }
        }
        
        // Determine final status
        if execution.status == .running {
            execution.status = .completed
            executions[handle.id] = execution
        }
        
        await finishExecution(handle: handle)
    }
    
    private func executeWorkflowStep(_ step: MediaWorkflowStep, with assets: [MediaAsset]) async throws -> [ProcessedAsset] {
        var results: [ProcessedAsset] = []
        
        // Basic step execution - in a real implementation, this would handle different step types
        for asset in assets {
            let processedAsset = ProcessedAsset(
                assetId: asset.id,
                resultData: asset.data, // Pass-through for now
                metadata: ["processedBy": step.name, "stepType": step.type.rawValue]
            )
            results.append(processedAsset)
        }
        
        return results
    }
    
    private func finishExecution(handle: WorkflowExecutionHandle) async {
        guard let execution = executions[handle.id] else { return }
        
        // Create final result and add to history
        let finalResult = WorkflowExecutionResult(
            executionHandle: handle,
            status: execution.status,
            processedAssets: execution.results.map { $0.assetId },
            failedAssets: [],
            errors: execution.errors.map { $0.message },
            duration: Date().timeIntervalSince(handle.startTime)
        )
        
        executionHistory.append(finalResult)
        
        // Send final notification
        await notifyProgressUpdate(
            handle: handle,
            message: "Workflow \(execution.status.rawValue)"
        )
        
        // Clean up
        if let continuation = progressContinuations[handle.id] {
            continuation.finish()
            progressContinuations.removeValue(forKey: handle.id)
        }
    }
    
    private func notifyProgressUpdate(handle: WorkflowExecutionHandle, message: String) async {
        guard let execution = executions[handle.id],
              let continuation = progressContinuations[handle.id] else { return }
        
        let update = WorkflowExecutionUpdate(
            executionId: handle.id,
            status: execution.status,
            currentStep: execution.currentStepIndex,
            totalSteps: execution.workflow.steps.count,
            processedAssets: execution.results.count,
            message: message
        )
        
        continuation.yield(update)
    }
    
    private func removeProgressContinuation(for id: UUID) async {
        progressContinuations.removeValue(forKey: id)
    }
    
    private func setupBuiltInTemplates() {
        // Image processing template
        let imageResizeTemplate = MediaWorkflow(
            id: UUID(),
            name: "Image Resize",
            description: "Resize images to specified dimensions",
            steps: [
                MediaWorkflowStep(
                    type: .validate,
                    name: "Validate Image",
                    order: 0
                ),
                MediaWorkflowStep(
                    type: .resize,
                    name: "Resize Image",
                    order: 1
                )
            ]
        )
        templates["image_resize"] = imageResizeTemplate
        
        // Document processing template
        let documentOCRTemplate = MediaWorkflow(
            id: UUID(),
            name: "Document OCR",
            description: "Extract text from document images",
            steps: [
                MediaWorkflowStep(
                    type: .validate,
                    name: "Validate Document",
                    order: 0
                ),
                MediaWorkflowStep(
                    type: .ocr,
                    name: "Extract Text",
                    order: 1
                ),
                MediaWorkflowStep(
                    type: .export,
                    name: "Format Results",
                    order: 2
                )
            ]
        )
        templates["document_ocr"] = documentOCRTemplate
    }
}

// MARK: - Private Types

private struct ProcessedAsset {
    let assetId: UUID
    let resultData: Data?
    let metadata: [String: String]
}

private struct WorkflowError {
    let message: String
    let stepIndex: Int?
    let assetId: UUID?
}

private struct WorkflowExecutionState {
    let handle: WorkflowExecutionHandle
    let workflow: MediaWorkflow
    let assets: [MediaAsset]
    var status: WorkflowExecutionStatus
    var currentStepIndex: Int
    var results: [ProcessedAsset]
    var errors: [WorkflowError]
}
