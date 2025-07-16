import Foundation

/// Represents different types of objects that can be handled by the adaptive intelligence system
public enum ObjectType: String, CaseIterable, Codable {
    // Document-related objects
    case document
    case documentTemplate = "document_template"
    case documentDraft = "document_draft"
    case documentSection = "document_section"

    // Acquisition-related objects
    case acquisition
    case requirement
    case vendor
    case contract

    // Workflow-related objects
    case workflow
    case workflowStep = "workflow_step"
    case approval
    case task

    // Data-related objects
    case dataField = "data_field"
    case regulation
    case compliance
    case metric

    // User-related objects
    case userQuery = "user_query"
    case userPreference = "user_preference"
    case userHistory = "user_history"

    // System objects
    case systemConfiguration = "system_configuration"
    case integrationEndpoint = "integration_endpoint"
    case notification

    public var category: ObjectCategory {
        switch self {
        case .document, .documentTemplate, .documentDraft, .documentSection:
            .document
        case .acquisition, .requirement, .vendor, .contract:
            .acquisition
        case .workflow, .workflowStep, .approval, .task:
            .workflow
        case .dataField, .regulation, .compliance, .metric:
            .data
        case .userQuery, .userPreference, .userHistory:
            .user
        case .systemConfiguration, .integrationEndpoint, .notification:
            .system
        }
    }

    public var supportedActions: [ActionType] {
        switch self {
        case .document:
            [.create, .read, .update, .delete, .analyze, .generate, .validate, .export]
        case .documentTemplate:
            [.read, .apply, .customize, .validate]
        case .acquisition:
            [.create, .read, .update, .analyze, .track, .report]
        case .workflow:
            [.start, .pause, .resume, .complete, .analyze, .optimize]
        case .task:
            [.assign, .execute, .complete, .prioritize, .schedule]
        case .userQuery:
            [.parse, .analyze, .respond, .learn]
        case .metric:
            [.record, .calculate, .analyze, .visualize, .report]
        default:
            [.read, .update]
        }
    }
}

public enum ObjectCategory: String, CaseIterable, Codable {
    case document
    case acquisition
    case workflow
    case data
    case user
    case system
}

public enum ActionType: String, CaseIterable, Codable {
    // CRUD operations
    case create
    case read
    case update
    case delete

    // Document operations
    case generate
    case analyze
    case validate
    case export
    case `import`

    // Workflow operations
    case start
    case pause
    case resume
    case complete
    case approve
    case reject

    // Task operations
    case assign
    case execute
    case schedule
    case prioritize

    // Data operations
    case parse
    case transform
    case calculate
    case aggregate
    case record

    // Learning operations
    case learn
    case adapt
    case optimize
    case predict

    // Utility operations
    case track
    case report
    case visualize
    case notify
    case customize
    case apply
    case respond
}

/// Represents an action that can be performed on an object
public struct ObjectAction: Identifiable, Equatable, Codable {
    public let id: UUID
    public let type: ActionType
    public let objectType: ObjectType
    public let objectId: String
    public let parameters: [String: Any]
    public let context: ActionContext
    public let priority: ObjectActionPriority
    public let estimatedDuration: TimeInterval
    public let requiredCapabilities: Set<Capability>

    public init(
        id: UUID = UUID(),
        type: ActionType,
        objectType: ObjectType,
        objectId: String,
        parameters: [String: Any] = [:],
        context: ActionContext,
        priority: ObjectActionPriority = .normal,
        estimatedDuration: TimeInterval = 0,
        requiredCapabilities: Set<Capability> = []
    ) {
        self.id = id
        self.type = type
        self.objectType = objectType
        self.objectId = objectId
        self.parameters = parameters
        self.context = context
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.requiredCapabilities = requiredCapabilities
    }

    // Codable conformance for parameters dictionary
    enum CodingKeys: String, CodingKey {
        case id, type, objectType, objectId, context, priority, estimatedDuration, requiredCapabilities
        case parameters
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ActionType.self, forKey: .type)
        objectType = try container.decode(ObjectType.self, forKey: .objectType)
        objectId = try container.decode(String.self, forKey: .objectId)
        context = try container.decode(ActionContext.self, forKey: .context)
        priority = try container.decode(ObjectActionPriority.self, forKey: .priority)
        estimatedDuration = try container.decode(TimeInterval.self, forKey: .estimatedDuration)
        requiredCapabilities = try container.decode(Set<Capability>.self, forKey: .requiredCapabilities)

        // Decode parameters as JSON
        if let parametersData = try? container.decode(Data.self, forKey: .parameters),
           let params = try? JSONSerialization.jsonObject(with: parametersData) as? [String: Any]
        {
            parameters = params
        } else {
            parameters = [:]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(objectType, forKey: .objectType)
        try container.encode(objectId, forKey: .objectId)
        try container.encode(context, forKey: .context)
        try container.encode(priority, forKey: .priority)
        try container.encode(estimatedDuration, forKey: .estimatedDuration)
        try container.encode(requiredCapabilities, forKey: .requiredCapabilities)

        // Encode parameters as JSON
        if let parametersData = try? JSONSerialization.data(withJSONObject: parameters) {
            try container.encode(parametersData, forKey: .parameters)
        }
    }

    public static func == (lhs: ObjectAction, rhs: ObjectAction) -> Bool {
        lhs.id == rhs.id
    }
}

public struct ActionContext: Equatable, Codable {
    public let userId: String
    public let sessionId: String
    public let timestamp: Date
    public let environment: Environment
    public let metadata: [String: String]

    public init(
        userId: String,
        sessionId: String,
        timestamp: Date = Date(),
        environment: Environment = .production,
        metadata: [String: String] = [:]
    ) {
        self.userId = userId
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.environment = environment
        self.metadata = metadata
    }

    public enum Environment: String, Codable {
        case development
        case staging
        case production
    }
}

public enum ObjectActionPriority: Int, Codable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    public static func < (lhs: ObjectActionPriority, rhs: ObjectActionPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum Capability: String, CaseIterable, Codable {
    case documentGeneration
    case dataAnalysis
    case workflowExecution
    case userInteraction
    case systemIntegration
    case machineLearning
    case naturalLanguageProcessing
    case compliance
    case security
    case realTimeProcessing
}

/// Result of an action execution
public struct ActionResult: Equatable, Codable, Sendable {
    public let actionId: UUID
    public let status: ActionStatus
    public let output: ActionOutput?
    public let metrics: ActionMetrics
    public let errors: [ActionError]
    public let learningInsights: [LearningInsight]

    public init(
        actionId: UUID,
        status: ActionStatus,
        output: ActionOutput? = nil,
        metrics: ActionMetrics,
        errors: [ActionError] = [],
        learningInsights: [LearningInsight] = []
    ) {
        self.actionId = actionId
        self.status = status
        self.output = output
        self.metrics = metrics
        self.errors = errors
        self.learningInsights = learningInsights
    }
}

public enum ActionStatus: String, Codable, Sendable {
    case pending
    case inProgress
    case completed
    case failed
    case cancelled
    case timeout
}

public struct ActionOutput: Equatable, Codable, Sendable {
    public let type: OutputType
    public let data: Data
    public let metadata: [String: String]

    public init(type: OutputType, data: Data, metadata: [String: String] = [:]) {
        self.type = type
        self.data = data
        self.metadata = metadata
    }

    public enum OutputType: String, Codable, Sendable {
        case text
        case json
        case binary
        case document
        case metrics
        case visualization
    }
}

public struct ActionMetrics: Equatable, Codable, Sendable {
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let successRate: Double
    public let performanceScore: Double // MOP: 0-1
    public let effectivenessScore: Double // MOE: 0-1

    public init(
        startTime: Date,
        endTime: Date,
        cpuUsage: Double,
        memoryUsage: Double,
        successRate: Double,
        performanceScore: Double,
        effectivenessScore: Double
    ) {
        self.startTime = startTime
        self.endTime = endTime
        duration = endTime.timeIntervalSince(startTime)
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.successRate = successRate
        self.performanceScore = min(max(performanceScore, 0), 1)
        self.effectivenessScore = min(max(effectivenessScore, 0), 1)
    }
}

public struct ActionError: Equatable, Codable, Sendable {
    public let code: String
    public let message: String
    public let timestamp: Date
    public let severity: ErrorSeverity
    public let recoverable: Bool

    public init(
        code: String,
        message: String,
        timestamp: Date = Date(),
        severity: ErrorSeverity,
        recoverable: Bool
    ) {
        self.code = code
        self.message = message
        self.timestamp = timestamp
        self.severity = severity
        self.recoverable = recoverable
    }

    public enum ErrorSeverity: String, Codable, Sendable {
        case warning
        case error
        case critical
    }
}

public struct LearningInsight: Equatable, Codable, Sendable {
    public let id: UUID
    public let type: InsightType
    public let description: String
    public let confidence: Double
    public let actionableRecommendation: String?
    public let impact: ImpactLevel

    public init(
        id: UUID = UUID(),
        type: InsightType,
        description: String,
        confidence: Double,
        actionableRecommendation: String? = nil,
        impact: ImpactLevel
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.confidence = min(max(confidence, 0), 1)
        self.actionableRecommendation = actionableRecommendation
        self.impact = impact
    }

    public enum InsightType: String, Codable, Sendable {
        case pattern
        case anomaly
        case optimization
        case prediction
        case recommendation
    }

    public enum ImpactLevel: String, Codable, Sendable {
        case low
        case medium
        case high
    }
}
