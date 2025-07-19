import ComposableArchitecture
import Foundation

@DependencyClient
public struct DocumentChainManagerClient {
    public var createChain: @Sendable (UUID, [DocumentType]) async throws -> DocumentChainProgress
    public var validateChain: @Sendable (UUID) async throws -> ChainValidation
    public var updateChainProgress: @Sendable (UUID, DocumentType, GeneratedDocument) async throws -> DocumentChainProgress
    public var extractAndPropagate: @Sendable (UUID, GeneratedDocument) async throws -> CollectedData
    public var getNextInChain: @Sendable (UUID) async throws -> DocumentType?
}

extension DocumentChainManagerClient: TestDependencyKey {
    public static let testValue = Self()
}

public extension DependencyValues {
    var documentChainManager: DocumentChainManagerClient {
        get { self[DocumentChainManagerClient.self] }
        set { self[DocumentChainManagerClient.self] = newValue }
    }
}
