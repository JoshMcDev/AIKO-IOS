import Foundation

// Document chain related types
public struct DocumentChainProgress: Equatable {
    public let acquisitionId: UUID
    public let documentOrder: [DocumentType]
    public var completedDocuments: [DocumentType]
    public var currentDocument: DocumentType?
    public var propagatedData: [String: String]
    
    public init(
        acquisitionId: UUID,
        documentOrder: [DocumentType],
        completedDocuments: [DocumentType] = [],
        currentDocument: DocumentType? = nil,
        propagatedData: [String: String] = [:]
    ) {
        self.acquisitionId = acquisitionId
        self.documentOrder = documentOrder
        self.completedDocuments = completedDocuments
        self.currentDocument = currentDocument
        self.propagatedData = propagatedData
    }
}

public struct ChainValidation: Equatable {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    
    public init(isValid: Bool, errors: [String] = [], warnings: [String] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

public protocol DocumentChainManagerProtocol {
    func createChain(_ acquisitionId: UUID, _ documentTypes: [DocumentType]) async throws -> DocumentChainProgress
    func validateChain(_ acquisitionId: UUID) async throws -> ChainValidation
    func updateChainProgress(_ acquisitionId: UUID, _ documentType: DocumentType, _ document: GeneratedDocument) async throws -> DocumentChainProgress
    func extractAndPropagate(_ acquisitionId: UUID, _ document: GeneratedDocument) async throws -> CollectedData
    func getNextInChain(_ acquisitionId: UUID) async throws -> DocumentType?
}
