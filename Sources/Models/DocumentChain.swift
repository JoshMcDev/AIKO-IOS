import AppCore
import Foundation

// MARK: - Document Chain Model

/// Represents a chain of documents required for an acquisition process
public struct DocumentChain: Equatable, Identifiable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String
    public let acquisitionType: AcquisitionType
    public let estimatedValue: Decimal
    public let complexity: ComplexityLevel
    public let nodes: [DocumentNode]
    public let edges: [DocumentEdge] // Dependencies between documents
    public let reviewMode: ReviewMode
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        acquisitionType: AcquisitionType,
        estimatedValue: Decimal,
        complexity: ComplexityLevel = .medium,
        nodes: [DocumentNode],
        edges: [DocumentEdge] = [],
        reviewMode: ReviewMode = .iterative,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.acquisitionType = acquisitionType
        self.estimatedValue = estimatedValue
        self.complexity = complexity
        self.nodes = nodes
        self.edges = edges
        self.reviewMode = reviewMode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Document Node

/// Represents a single document in the chain
public struct DocumentNode: Equatable, Identifiable, Codable, Sendable {
    public let id: UUID
    public let documentType: DocumentType
    public let title: String
    public let description: String
    public let phase: AcquisitionPhase
    public let estimatedGenerationTime: TimeInterval
    public let requiredInputs: [RequiredInput]
    public let status: NodeStatus
    public let reviewers: [ReviewerRole]
    public let metadata: NodeMetadata?

    public init(
        id: UUID = UUID(),
        documentType: DocumentType,
        title: String,
        description: String,
        phase: AcquisitionPhase,
        estimatedGenerationTime: TimeInterval = 600, // 10 minutes default
        requiredInputs: [RequiredInput] = [],
        status: NodeStatus = .pending,
        reviewers: [ReviewerRole] = [],
        metadata: NodeMetadata? = nil
    ) {
        self.id = id
        self.documentType = documentType
        self.title = title
        self.description = description
        self.phase = phase
        self.estimatedGenerationTime = estimatedGenerationTime
        self.requiredInputs = requiredInputs
        self.status = status
        self.reviewers = reviewers
        self.metadata = metadata
    }
}

// MARK: - Document Edge

/// Represents a dependency between two documents
public struct DocumentEdge: Equatable, Codable, Sendable {
    public let from: UUID // Source node ID
    public let to: UUID // Destination node ID
    public let dependencyType: DependencyType
    public let isOptional: Bool

    public init(
        from: UUID,
        to: UUID,
        dependencyType: DependencyType = .requires,
        isOptional: Bool = false
    ) {
        self.from = from
        self.to = to
        self.dependencyType = dependencyType
        self.isOptional = isOptional
    }
}

// MARK: - Supporting Types

/// Type of acquisition
public enum AcquisitionType: String, Codable, CaseIterable, Sendable {
    case simplifiedAcquisition = "Simplified Acquisition"
    case commercialItem = "Commercial Item"
    case nonCommercialService = "Non-Commercial Service"
    case majorSystem = "Major System"
    case constructionProject = "Construction Project"
    case researchDevelopment = "Research & Development"
    case otherTransaction = "Other Transaction"

    public var thresholds: AcquisitionThresholds {
        switch self {
        case .simplifiedAcquisition:
            AcquisitionThresholds(micro: 10000, simplified: 250_000, standard: nil)
        case .commercialItem:
            AcquisitionThresholds(micro: 10000, simplified: 250_000, standard: 7_500_000)
        case .nonCommercialService:
            AcquisitionThresholds(micro: 10000, simplified: 250_000, standard: nil)
        case .majorSystem:
            AcquisitionThresholds(micro: nil, simplified: nil, standard: 500_000_000)
        case .constructionProject:
            AcquisitionThresholds(micro: 2000, simplified: 2_000_000, standard: nil)
        case .researchDevelopment:
            AcquisitionThresholds(micro: 10000, simplified: 250_000, standard: nil)
        case .otherTransaction:
            AcquisitionThresholds(micro: nil, simplified: nil, standard: nil)
        }
    }
}

/// Acquisition thresholds
public struct AcquisitionThresholds: Equatable, Codable, Sendable {
    public let micro: Decimal?
    public let simplified: Decimal?
    public let standard: Decimal?
}

/// Complexity level of the acquisition
public enum ComplexityLevel: String, Codable, CaseIterable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    public var color: String {
        switch self {
        case .low: "green"
        case .medium: "yellow"
        case .high: "orange"
        case .critical: "red"
        }
    }
}

/// Acquisition phases
public enum AcquisitionPhase: String, Codable, CaseIterable, Sendable, Hashable {
    case planning = "Planning"
    case marketResearch = "Market Research"
    case requirementsDevelopment = "Requirements Development"
    case solicitation = "Solicitation"
    case evaluation = "Evaluation"
    case negotiation = "Negotiation"
    case award = "Award"
    case administration = "Administration"
    case closeout = "Closeout"

    public var order: Int {
        switch self {
        case .planning: 1
        case .marketResearch: 2
        case .requirementsDevelopment: 3
        case .solicitation: 4
        case .evaluation: 5
        case .negotiation: 6
        case .award: 7
        case .administration: 8
        case .closeout: 9
        }
    }
}

/// Review mode for document chain
public enum ReviewMode: String, Codable, Sendable {
    case iterative = "Iterative" // Review each document as generated
    case batch = "Batch" // Generate all, then review

    public var description: String {
        switch self {
        case .iterative:
            "Review and approve each document as it's generated"
        case .batch:
            "Generate all documents first, then review as a complete package"
        }
    }
}

/// Status of a document node
public enum NodeStatus: String, Codable, Sendable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case generated = "Generated"
    case underReview = "Under Review"
    case approved = "Approved"
    case rejected = "Rejected"
    case revised = "Revised"

    public var icon: String {
        switch self {
        case .pending: "circle"
        case .inProgress: "circle.dotted"
        case .generated: "circle.fill"
        case .underReview: "eye.circle"
        case .approved: "checkmark.circle.fill"
        case .rejected: "xmark.circle.fill"
        case .revised: "arrow.triangle.2.circlepath.circle"
        }
    }
}

/// Required input for document generation
public struct RequiredInput: Equatable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String
    public let inputType: InputType
    public let isOptional: Bool
    public let defaultValue: String?

    public enum InputType: String, Codable, Sendable {
        case text = "Text"
        case number = "Number"
        case date = "Date"
        case selection = "Selection"
        case document = "Document"
        case boolean = "Boolean"
    }

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        inputType: InputType,
        isOptional: Bool = false,
        defaultValue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.inputType = inputType
        self.isOptional = isOptional
        self.defaultValue = defaultValue
    }
}

/// Reviewer roles
public enum ReviewerRole: String, Codable, CaseIterable, Sendable {
    case contractingOfficer = "Contracting Officer"
    case requirementsOwner = "Requirements Owner"
    case legalCounsel = "Legal Counsel"
    case technicalExpert = "Technical Expert"
    case fiscalLaw = "Fiscal Law"
    case smallBusiness = "Small Business"
    case competition = "Competition Advocate"
    case cor = "COR"
}

/// Dependency types between documents
public enum DependencyType: String, Codable, Sendable {
    case requires = "Requires" // Must be completed before
    case informs = "Informs" // Provides input to
    case validates = "Validates" // Validates content of
    case supplements = "Supplements" // Adds to
}

/// Node metadata
public struct NodeMetadata: Equatable, Codable, Sendable {
    public let farReferences: [String]?
    public let estimatedReviewTime: TimeInterval?
    public let criticalPath: Bool?
    public let automationEnabled: Bool?
    public let customFields: [String: String]?

    public init(
        farReferences: [String]? = nil,
        estimatedReviewTime: TimeInterval? = nil,
        criticalPath: Bool? = nil,
        automationEnabled: Bool? = nil,
        customFields: [String: String]? = nil
    ) {
        self.farReferences = farReferences
        self.estimatedReviewTime = estimatedReviewTime
        self.criticalPath = criticalPath
        self.automationEnabled = automationEnabled
        self.customFields = customFields
    }
}

// MARK: - Document Chain Extensions

public extension DocumentChain {
    /// Get nodes for a specific phase
    func nodes(for phase: AcquisitionPhase) -> [DocumentNode] {
        nodes.filter { $0.phase == phase }
    }

    /// Get all dependencies for a node
    func dependencies(for nodeId: UUID) -> [DocumentNode] {
        let dependencyIds = edges
            .filter { $0.to == nodeId }
            .map(\.from)

        return nodes.filter { dependencyIds.contains($0.id) }
    }

    /// Get nodes that depend on a given node
    func dependents(of nodeId: UUID) -> [DocumentNode] {
        let dependentIds = edges
            .filter { $0.from == nodeId }
            .map(\.to)

        return nodes.filter { dependentIds.contains($0.id) }
    }

    /// Calculate critical path through the document chain
    func criticalPath() -> [DocumentNode] {
        // Simplified critical path - in production would use proper algorithm
        nodes
            .filter { $0.metadata?.criticalPath == true }
            .sorted { $0.phase.order < $1.phase.order }
    }

    /// Get next available nodes to work on
    func availableNodes(completedNodeIds: Set<UUID>) -> [DocumentNode] {
        nodes.filter { node in
            // Node is not completed
            !completedNodeIds.contains(node.id) &&
                // All dependencies are completed
                dependencies(for: node.id).allSatisfy { completedNodeIds.contains($0.id) }
        }
    }

    /// Estimate total time for chain completion
    var estimatedTotalTime: TimeInterval {
        switch reviewMode {
        case .iterative:
            // Sum of all generation times plus review times
            return nodes.reduce(0) { total, node in
                total + node.estimatedGenerationTime + (node.metadata?.estimatedReviewTime ?? 300)
            }
        case .batch:
            // Max path time for generation, then sum of review times
            let maxGenerationTime = criticalPath().reduce(0) { $0 + $1.estimatedGenerationTime }
            let totalReviewTime = nodes.reduce(0) { total, node in
                total + (node.metadata?.estimatedReviewTime ?? 300)
            }
            return maxGenerationTime + totalReviewTime
        }
    }
}
