import Foundation

// MARK: - Media Workflow Types

/// Step in a media workflow
public struct MediaWorkflowStep: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: WorkflowStepType
    public let order: Int
    public let configuration: [String: String]
    public let inputs: [String]
    public let outputs: [String]
    public let dependencies: [UUID]
    public let isOptional: Bool
    public let estimatedDuration: TimeInterval

    public init(
        id: UUID = UUID(),
        name: String,
        type: WorkflowStepType,
        order: Int,
        configuration: [String: String] = [:],
        inputs: [String] = [],
        outputs: [String] = [],
        dependencies: [UUID] = [],
        isOptional: Bool = false,
        estimatedDuration: TimeInterval = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.order = order
        self.configuration = configuration
        self.inputs = inputs
        self.outputs = outputs
        self.dependencies = dependencies
        self.isOptional = isOptional
        self.estimatedDuration = estimatedDuration
    }
}

/// Types of workflow steps
public enum WorkflowStepType: String, Sendable, CaseIterable {
    case preprocessing
    case analysis
    case transformation
    case enhancement
    case validation
    case export
    case notification
    case custom

    public var displayName: String {
        switch self {
        case .preprocessing: "Preprocessing"
        case .analysis: "Analysis"
        case .transformation: "Transformation"
        case .enhancement: "Enhancement"
        case .validation: "Validation"
        case .export: "Export"
        case .notification: "Notification"
        case .custom: "Custom"
        }
    }
}

/// Represents a complete media processing workflow
public struct MediaWorkflow: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let steps: [MediaWorkflowStep]
    public let inputs: [WorkflowInput]
    public let outputs: [WorkflowOutput]
    public let metadata: [String: String]
    public let version: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        steps: [MediaWorkflowStep] = [],
        inputs: [WorkflowInput] = [],
        outputs: [WorkflowOutput] = [],
        metadata: [String: String] = [:],
        version: String = "1.0",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
        self.inputs = inputs
        self.outputs = outputs
        self.metadata = metadata
        self.version = version
        self.createdAt = createdAt
    }
}

/// Workflow definition template
public struct WorkflowDefinition: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let category: WorkflowCategory
    public let template: MediaWorkflow
    public let isBuiltIn: Bool
    public let isPublic: Bool
    public let tags: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        category: WorkflowCategory,
        template: MediaWorkflow,
        isBuiltIn: Bool = false,
        isPublic: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.template = template
        self.isBuiltIn = isBuiltIn
        self.isPublic = isPublic
        self.tags = tags
    }
}

/// Categories of workflows
public enum WorkflowCategory: String, Sendable, CaseIterable {
    case imageProcessing
    case videoProcessing
    case audioProcessing
    case documentProcessing
    case qualityAssurance
    case security
    case backup
    case sharing
    case custom

    public var displayName: String {
        switch self {
        case .imageProcessing: "Image Processing"
        case .videoProcessing: "Video Processing"
        case .audioProcessing: "Audio Processing"
        case .documentProcessing: "Document Processing"
        case .qualityAssurance: "Quality Assurance"
        case .security: "Security"
        case .backup: "Backup"
        case .sharing: "Sharing"
        case .custom: "Custom"
        }
    }
}

/// Handle for tracking workflow execution
public struct WorkflowExecutionHandle: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let workflowId: UUID
    public let startTime: Date
    public let sessionId: String

    public init(
        id: UUID = UUID(),
        workflowId: UUID,
        startTime: Date = Date(),
        sessionId: String = UUID().uuidString
    ) {
        self.id = id
        self.workflowId = workflowId
        self.startTime = startTime
        self.sessionId = sessionId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: WorkflowExecutionHandle, rhs: WorkflowExecutionHandle) -> Bool {
        lhs.id == rhs.id
    }
}

/// Status of workflow execution
public enum WorkflowExecutionStatus: String, Sendable, CaseIterable {
    case pending
    case running
    case paused
    case completed
    case failed
    case cancelled

    public var displayName: String {
        switch self {
        case .pending: "Pending"
        case .running: "Running"
        case .paused: "Paused"
        case .completed: "Completed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }
}

/// Update from workflow execution
public struct WorkflowExecutionUpdate: Sendable {
    public let handle: WorkflowExecutionHandle
    public let status: WorkflowExecutionStatus
    public let currentStep: MediaWorkflowStep?
    public let progress: BatchProgress
    public let timestamp: Date
    public let message: String?

    public init(
        handle: WorkflowExecutionHandle,
        status: WorkflowExecutionStatus,
        currentStep: MediaWorkflowStep? = nil,
        progress: BatchProgress,
        timestamp: Date = Date(),
        message: String? = nil
    ) {
        self.handle = handle
        self.status = status
        self.currentStep = currentStep
        self.progress = progress
        self.timestamp = timestamp
        self.message = message
    }
}

/// Result of workflow execution
public struct WorkflowExecutionResult: Sendable {
    public let handle: WorkflowExecutionHandle
    public let status: WorkflowExecutionStatus
    public let outputs: [ProcessedAsset]
    public let errors: [WorkflowError]
    public let executionTime: TimeInterval
    public let completedAt: Date
    public let stepResults: [WorkflowStepResult]

    public init(
        handle: WorkflowExecutionHandle,
        status: WorkflowExecutionStatus,
        outputs: [ProcessedAsset] = [],
        errors: [WorkflowError] = [],
        executionTime: TimeInterval,
        completedAt: Date = Date(),
        stepResults: [WorkflowStepResult] = []
    ) {
        self.handle = handle
        self.status = status
        self.outputs = outputs
        self.errors = errors
        self.executionTime = executionTime
        self.completedAt = completedAt
        self.stepResults = stepResults
    }
}

/// Result of individual workflow step
public struct WorkflowStepResult: Sendable, Identifiable {
    public let id: UUID
    public let stepId: UUID
    public let success: Bool
    public let output: Data?
    public let error: WorkflowError?
    public let executionTime: TimeInterval
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        stepId: UUID,
        success: Bool,
        output: Data? = nil,
        error: WorkflowError? = nil,
        executionTime: TimeInterval,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.stepId = stepId
        self.success = success
        self.output = output
        self.error = error
        self.executionTime = executionTime
        self.metadata = metadata
    }
}

/// Processed asset output from workflow
public struct ProcessedAsset: Sendable, Identifiable {
    public let id: UUID
    public let originalAssetId: UUID?
    public let type: MediaType
    public let data: Data
    public let metadata: MediaMetadata
    public let processingSteps: [String]
    public let quality: ProcessingQuality
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        originalAssetId: UUID? = nil,
        type: MediaType,
        data: Data,
        metadata: MediaMetadata,
        processingSteps: [String] = [],
        quality: ProcessingQuality = .standard,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.originalAssetId = originalAssetId
        self.type = type
        self.data = data
        self.metadata = metadata
        self.processingSteps = processingSteps
        self.quality = quality
        self.createdAt = createdAt
    }
}

/// Quality level of processed asset
public enum ProcessingQuality: String, Sendable, CaseIterable {
    case draft
    case standard
    case high
    case premium

    public var displayName: String {
        switch self {
        case .draft: "Draft"
        case .standard: "Standard"
        case .high: "High"
        case .premium: "Premium"
        }
    }
}

/// Workflow-specific error types
public enum WorkflowError: Error, Sendable, LocalizedError {
    case invalidConfiguration(String)
    case stepFailed(String, underlying: Error?)
    case dependencyNotMet(String)
    case timeout(String)
    case resourceUnavailable(String)
    case validationFailed(String)
    case cancelled(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidConfiguration(message):
            "Invalid configuration: \(message)"
        case let .stepFailed(message, _):
            "Step failed: \(message)"
        case let .dependencyNotMet(message):
            "Dependency not met: \(message)"
        case let .timeout(message):
            "Timeout: \(message)"
        case let .resourceUnavailable(message):
            "Resource unavailable: \(message)"
        case let .validationFailed(message):
            "Validation failed: \(message)"
        case let .cancelled(message):
            "Cancelled: \(message)"
        case let .unknown(message):
            "Unknown error: \(message)"
        }
    }
}

/// Input specification for workflow
public struct WorkflowInput: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: WorkflowInputType
    public let required: Bool
    public let defaultValue: String?
    public let validation: String?

    public init(
        id: UUID = UUID(),
        name: String,
        type: WorkflowInputType,
        required: Bool = true,
        defaultValue: String? = nil,
        validation: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.validation = validation
    }
}

/// Output specification for workflow
public struct WorkflowOutput: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: WorkflowOutputType
    public let description: String

    public init(
        id: UUID = UUID(),
        name: String,
        type: WorkflowOutputType,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
    }
}

/// Types of workflow inputs
public enum WorkflowInputType: String, Sendable, CaseIterable {
    case file
    case image
    case video
    case audio
    case text
    case number
    case boolean
    case url
    case selection

    public var displayName: String {
        switch self {
        case .file: "File"
        case .image: "Image"
        case .video: "Video"
        case .audio: "Audio"
        case .text: "Text"
        case .number: "Number"
        case .boolean: "Boolean"
        case .url: "URL"
        case .selection: "Selection"
        }
    }
}

/// Types of workflow outputs
public enum WorkflowOutputType: String, Sendable, CaseIterable {
    case processedFile
    case extractedData
    case analysis
    case report
    case notification
    case metadata

    public var displayName: String {
        switch self {
        case .processedFile: "Processed File"
        case .extractedData: "Extracted Data"
        case .analysis: "Analysis"
        case .report: "Report"
        case .notification: "Notification"
        case .metadata: "Metadata"
        }
    }
}

/// Template for creating workflows
public struct WorkflowTemplate: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let category: WorkflowCategory
    public let steps: [WorkflowStepTemplate]
    public let estimatedDuration: TimeInterval
    public let complexity: WorkflowComplexity

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: WorkflowCategory,
        steps: [WorkflowStepTemplate] = [],
        estimatedDuration: TimeInterval = 0,
        complexity: WorkflowComplexity = .simple
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.steps = steps
        self.estimatedDuration = estimatedDuration
        self.complexity = complexity
    }
}

/// Template for workflow steps
public struct WorkflowStepTemplate: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: WorkflowStepType
    public let configurationSchema: [String: String]
    public let description: String

    public init(
        id: UUID = UUID(),
        name: String,
        type: WorkflowStepType,
        configurationSchema: [String: String] = [:],
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.configurationSchema = configurationSchema
        self.description = description
    }
}

/// Complexity level of workflow
public enum WorkflowComplexity: String, Sendable, CaseIterable {
    case simple
    case moderate
    case complex
    case advanced

    public var displayName: String {
        switch self {
        case .simple: "Simple"
        case .moderate: "Moderate"
        case .complex: "Complex"
        case .advanced: "Advanced"
        }
    }
}

/// Validation result for workflow
public struct WorkflowValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [WorkflowValidationError]
    public let warnings: [WorkflowValidationWarning]
    public let estimatedExecutionTime: TimeInterval?

    public init(
        isValid: Bool,
        errors: [WorkflowValidationError] = [],
        warnings: [WorkflowValidationWarning] = [],
        estimatedExecutionTime: TimeInterval? = nil
    ) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.estimatedExecutionTime = estimatedExecutionTime
    }
}

/// Workflow-specific validation error
public struct WorkflowValidationError: Sendable, Identifiable {
    public let id: UUID
    public let message: String
    public let field: String?
    public let code: String?

    public init(
        id: UUID = UUID(),
        message: String,
        field: String? = nil,
        code: String? = nil
    ) {
        self.id = id
        self.message = message
        self.field = field
        self.code = code
    }
}

/// Workflow-specific validation warning
public struct WorkflowValidationWarning: Sendable, Identifiable {
    public let id: UUID
    public let message: String
    public let field: String?
    public let suggestion: String?

    public init(
        id: UUID = UUID(),
        message: String,
        field: String? = nil,
        suggestion: String? = nil
    ) {
        self.id = id
        self.message = message
        self.field = field
        self.suggestion = suggestion
    }
}
