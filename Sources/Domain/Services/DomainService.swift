import Foundation

/// Base protocol for all domain services
/// Provides a marker interface for domain-layer services
public protocol DomainService {
    // Marker protocol for domain services
}

/// Protocol for services that require repository access
public protocol RepositoryService: DomainService {
    associatedtype RepositoryType
    var repository: RepositoryType { get }
}

/// Protocol for services that perform validation
public protocol ValidationService: DomainService {
    associatedtype ValidationType
    func validate(_ item: ValidationType) throws
}

/// Protocol for services that handle transactions
public protocol TransactionService: DomainService {
    func beginTransaction() async throws
    func commitTransaction() async throws
    func rollbackTransaction() async throws
}