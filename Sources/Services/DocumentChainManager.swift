import ComposableArchitecture
import CoreData
import Foundation

// MARK: - Document Chain Manager

public struct DocumentChainManager {
    public var createChain: (UUID, [DocumentType]) async throws -> DocumentChain
    public var updateChainProgress: (UUID, DocumentType, GeneratedDocument) async throws -> DocumentChain
    public var getNextInChain: (UUID) async throws -> DocumentType?
    public var extractAndPropagate: (UUID, GeneratedDocument) async throws -> CollectedData
    public var validateChain: (UUID) async throws -> ChainValidation

    public init(
        createChain: @escaping (UUID, [DocumentType]) async throws -> DocumentChain,
        updateChainProgress: @escaping (UUID, DocumentType, GeneratedDocument) async throws -> DocumentChain,
        getNextInChain: @escaping (UUID) async throws -> DocumentType?,
        extractAndPropagate: @escaping (UUID, GeneratedDocument) async throws -> CollectedData,
        validateChain: @escaping (UUID) async throws -> ChainValidation
    ) {
        self.createChain = createChain
        self.updateChainProgress = updateChainProgress
        self.getNextInChain = getNextInChain
        self.extractAndPropagate = extractAndPropagate
        self.validateChain = validateChain
    }
}

// MARK: - Document Chain Model

public struct DocumentChain: Equatable, Codable {
    public let id: UUID
    public let acquisitionId: UUID
    public let plannedDocuments: [DocumentType]
    public let completedDocuments: [DocumentType: GeneratedDocument]
    public let propagatedData: CollectedData
    public let currentIndex: Int
    public let createdAt: Date
    public let updatedAt: Date

    // Custom Codable implementation to handle dictionary with DocumentType keys
    private enum CodingKeys: String, CodingKey {
        case id, acquisitionId, plannedDocuments, completedDocuments
        case propagatedData, currentIndex, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        acquisitionId = try container.decode(UUID.self, forKey: .acquisitionId)
        plannedDocuments = try container.decode([DocumentType].self, forKey: .plannedDocuments)

        // Decode completedDocuments as [String: GeneratedDocument] and convert
        let completedDict = try container.decode([String: GeneratedDocument].self, forKey: .completedDocuments)
        var converted: [DocumentType: GeneratedDocument] = [:]
        for (key, value) in completedDict {
            if let docType = DocumentType(rawValue: key) {
                converted[docType] = value
            }
        }
        completedDocuments = converted

        propagatedData = try container.decode(CollectedData.self, forKey: .propagatedData)
        currentIndex = try container.decode(Int.self, forKey: .currentIndex)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(acquisitionId, forKey: .acquisitionId)
        try container.encode(plannedDocuments, forKey: .plannedDocuments)

        // Convert completedDocuments to [String: GeneratedDocument] for encoding
        var stringKeyedDict: [String: GeneratedDocument] = [:]
        for (key, value) in completedDocuments {
            stringKeyedDict[key.rawValue] = value
        }
        try container.encode(stringKeyedDict, forKey: .completedDocuments)

        try container.encode(propagatedData, forKey: .propagatedData)
        try container.encode(currentIndex, forKey: .currentIndex)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    public init(
        id: UUID = UUID(),
        acquisitionId: UUID,
        plannedDocuments: [DocumentType],
        completedDocuments: [DocumentType: GeneratedDocument] = [:],
        propagatedData: CollectedData = CollectedData(),
        currentIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.acquisitionId = acquisitionId
        self.plannedDocuments = plannedDocuments
        self.completedDocuments = completedDocuments
        self.propagatedData = propagatedData
        self.currentIndex = currentIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var currentDocument: DocumentType? {
        guard currentIndex < plannedDocuments.count else { return nil }
        return plannedDocuments[currentIndex]
    }

    public var progress: Double {
        guard !plannedDocuments.isEmpty else { return 0 }
        return Double(completedDocuments.count) / Double(plannedDocuments.count)
    }

    public var isComplete: Bool {
        completedDocuments.count == plannedDocuments.count
    }
}

// MARK: - Broken Link

public struct BrokenLink: Equatable {
    public let from: DocumentType
    public let to: DocumentType
    public let reason: String

    public init(from: DocumentType, to: DocumentType, reason: String) {
        self.from = from
        self.to = to
        self.reason = reason
    }
}

// MARK: - Chain Validation

public struct ChainValidation: Equatable {
    public let isValid: Bool
    public let brokenLinks: [BrokenLink]
    public let missingData: [DocumentType: [String]]
    public let recommendations: [String]

    public init(
        isValid: Bool,
        brokenLinks: [BrokenLink] = [],
        missingData: [DocumentType: [String]] = [:],
        recommendations: [String] = []
    ) {
        self.isValid = isValid
        self.brokenLinks = brokenLinks
        self.missingData = missingData
        self.recommendations = recommendations
    }
}

// MARK: - Live Implementation

extension DocumentChainManager: DependencyKey {
    public static var liveValue: DocumentChainManager {
        let documentDependencyService = DocumentDependencyService.liveValue
        _ = AcquisitionService.liveValue

        // In-memory storage for chains (would be persisted in real implementation)
        var chains: [UUID: DocumentChain] = [:]

        return DocumentChainManager(
            createChain: { acquisitionId, plannedDocuments in
                let chain = DocumentChain(
                    acquisitionId: acquisitionId,
                    plannedDocuments: plannedDocuments
                )
                chains[acquisitionId] = chain

                // Store in Core Data
                let context = CoreDataStack.shared.viewContext
                let fetchRequest: NSFetchRequest<Acquisition> = Acquisition.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

                if let acquisition = try? context.fetch(fetchRequest).first {
                    try? acquisition.setDocumentChainCodable(chain)
                    try? CoreDataStack.shared.save()
                }

                return chain
            },

            updateChainProgress: { acquisitionId, documentType, generatedDocument in
                guard let chain = chains[acquisitionId] else {
                    throw ChainError.chainNotFound
                }

                // Update completed documents
                var updatedCompleted = chain.completedDocuments
                updatedCompleted[documentType] = generatedDocument

                // Extract data from the document
                let extractedData = documentDependencyService.extractDataForDependents(generatedDocument)

                // Merge extracted data with propagated data
                var updatedPropagatedData = chain.propagatedData
                for (key, value) in extractedData.data {
                    updatedPropagatedData[key] = value
                }

                // Find next document index
                let nextIndex = chain.currentIndex + 1

                // Create updated chain
                let updatedChain = DocumentChain(
                    id: chain.id,
                    acquisitionId: chain.acquisitionId,
                    plannedDocuments: chain.plannedDocuments,
                    completedDocuments: updatedCompleted,
                    propagatedData: updatedPropagatedData,
                    currentIndex: nextIndex,
                    createdAt: chain.createdAt,
                    updatedAt: Date()
                )

                chains[acquisitionId] = updatedChain

                // Update Core Data with chain metadata
                let context = CoreDataStack.shared.viewContext
                let fetchRequest: NSFetchRequest<Acquisition> = Acquisition.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

                if let acquisition = try? context.fetch(fetchRequest).first {
                    try? acquisition.setDocumentChainCodable(updatedChain)
                    try? CoreDataStack.shared.save()
                }

                return updatedChain
            },

            getNextInChain: { acquisitionId in
                guard let chain = chains[acquisitionId] else {
                    throw ChainError.chainNotFound
                }

                // Find the next uncompleted document
                for document in chain.plannedDocuments {
                    if chain.completedDocuments[document] == nil {
                        // Validate dependencies before suggesting
                        let previousDocs = Array(chain.completedDocuments.values)
                        let validation = documentDependencyService.validateDependencies(previousDocs, document)

                        if validation.isValid {
                            return document
                        }
                    }
                }

                return nil
            },

            extractAndPropagate: { acquisitionId, generatedDocument in
                guard let chain = chains[acquisitionId] else {
                    throw ChainError.chainNotFound
                }

                // Extract data from the document
                let extractedData = documentDependencyService.extractDataForDependents(generatedDocument)

                // Propagate to dependent documents
                if let documentType = generatedDocument.documentType {
                    // Find all documents that depend on this one
                    for plannedDoc in chain.plannedDocuments {
                        let dependencies = documentDependencyService.getDependencies(plannedDoc)

                        if dependencies.contains(where: { $0.sourceDocumentType == documentType }) {
                            // This document depends on the generated one
                            print("Data from \(documentType.shortName) will flow to \(plannedDoc.shortName)")
                        }
                    }
                }

                return extractedData
            },

            validateChain: { acquisitionId in
                guard let chain = chains[acquisitionId] else {
                    throw ChainError.chainNotFound
                }

                var brokenLinks: [BrokenLink] = []
                var missingData: [DocumentType: [String]] = [:]
                var recommendations: [String] = []

                // Validate each planned document
                for (index, document) in chain.plannedDocuments.enumerated() {
                    let dependencies = documentDependencyService.getDependencies(document)

                    for dependency in dependencies where dependency.isRequired {
                        // Check if the source document is in the chain and comes before
                        if let sourceIndex = chain.plannedDocuments.firstIndex(of: dependency.sourceDocumentType) {
                            if sourceIndex > index {
                                brokenLinks.append(BrokenLink(
                                    from: dependency.sourceDocumentType,
                                    to: document,
                                    reason: "\(dependency.sourceDocumentType.shortName) should come before \(document.shortName)"
                                ))
                            }
                        } else if dependency.isRequired {
                            brokenLinks.append(BrokenLink(
                                from: dependency.sourceDocumentType,
                                to: document,
                                reason: "Required dependency \(dependency.sourceDocumentType.shortName) is not in the chain"
                            ))
                        }
                    }

                    // Check for missing data fields
                    let requiredFields = dependencies.flatMap(\.dataFields)
                    let availableFields = Set(chain.propagatedData.data.keys)
                    let missing = requiredFields.filter { !availableFields.contains($0) }

                    if !missing.isEmpty {
                        missingData[document] = missing
                    }
                }

                // Generate recommendations
                if chain.plannedDocuments.isEmpty {
                    recommendations.append("Start by selecting documents to generate")
                } else if chain.completedDocuments.isEmpty {
                    recommendations.append("Begin with \(chain.plannedDocuments.first?.shortName ?? "the first document")")
                } else {
                    let completion = Int(chain.progress * 100)
                    recommendations.append("Chain is \(completion)% complete")

                    if let next = chain.currentDocument {
                        recommendations.append("Next: Generate \(next.shortName)")
                    }
                }

                let isValid = brokenLinks.isEmpty && missingData.isEmpty

                return ChainValidation(
                    isValid: isValid,
                    brokenLinks: brokenLinks,
                    missingData: missingData,
                    recommendations: recommendations
                )
            }
        )
    }
}

// MARK: - Chain Errors

enum ChainError: LocalizedError {
    case chainNotFound
    case invalidDocumentOrder
    case missingDependencies

    var errorDescription: String? {
        switch self {
        case .chainNotFound:
            "Document chain not found for this acquisition"
        case .invalidDocumentOrder:
            "Invalid document order in chain"
        case .missingDependencies:
            "Missing required document dependencies"
        }
    }
}

public extension DependencyValues {
    var documentChainManager: DocumentChainManager {
        get { self[DocumentChainManager.self] }
        set { self[DocumentChainManager.self] = newValue }
    }
}
