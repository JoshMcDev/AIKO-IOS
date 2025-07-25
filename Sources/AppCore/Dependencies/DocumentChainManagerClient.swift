import Foundation

public struct DocumentChainManagerClient: Sendable {
    public var createChain: @Sendable (UUID, [DocumentType]) async throws -> DocumentChainProgress
    public var validateChain: @Sendable (UUID) async throws -> ChainValidation
    public var updateChainProgress: @Sendable (UUID, DocumentType, GeneratedDocument) async throws -> DocumentChainProgress
    public var extractAndPropagate: @Sendable (UUID, GeneratedDocument) async throws -> CollectedData
    public var getNextInChain: @Sendable (UUID) async throws -> DocumentType?
}

extension DocumentChainManagerClient {
    public static let testValue = Self(
        createChain: { acquisitionId, documentOrder in DocumentChainProgress(acquisitionId: acquisitionId, documentOrder: documentOrder) },
        validateChain: { _ in ChainValidation(isValid: true) },
        updateChainProgress: { acquisitionId, _, _ in DocumentChainProgress(acquisitionId: acquisitionId, documentOrder: []) },
        extractAndPropagate: { _, _ in CollectedData() },
        getNextInChain: { _ in nil }
    )
}
