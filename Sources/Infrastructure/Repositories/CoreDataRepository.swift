import Combine
@preconcurrency import CoreData
import Foundation

/// Base Core Data repository implementing common CRUD operations using actor-based Core Data access
/// This is an abstract base class - subclasses should provide Sendable DTOs
open class CoreDataRepository<Entity: NSManagedObject>: @unchecked Sendable {
    public typealias Model = Entity

    let coreDataActor: CoreDataActor
    let entityName: String

    public init(coreDataActor: CoreDataActor, entityType: Entity.Type) {
        self.coreDataActor = coreDataActor
        entityName = String(describing: entityType)
    }

    // MARK: - Protected Methods for Subclasses

    /// Perform a fetch and transform to Sendable type within the context
    func fetch<T: Sendable>(
        with request: NSFetchRequest<Entity>,
        transform: @Sendable @escaping (Entity) -> T
    ) async throws -> [T] {
        try await coreDataActor.performViewContextTask { context in
            let entities = try context.fetch(request)
            return entities.map(transform)
        }
    }

    /// Perform a single fetch and transform to Sendable type within the context
    func fetchSingle<T: Sendable>(
        with request: NSFetchRequest<Entity>,
        transform: @Sendable @escaping (Entity) -> T?
    ) async throws -> T? {
        try await coreDataActor.performViewContextTask { context in
            request.fetchLimit = 1
            let entities = try context.fetch(request)
            return entities.first.flatMap(transform)
        }
    }

    /// Create entity and transform to Sendable type within the context
    func create<T: Sendable>(
        configure: @Sendable @escaping (Entity, NSManagedObjectContext) throws -> Void,
        transform: @Sendable @escaping (Entity) -> T
    ) async throws -> T {
        try await coreDataActor.performBackgroundTask { context in
            let entity = Entity(context: context)
            try configure(entity, context)
            try context.save()
            return transform(entity)
        }
    }

    /// Update entity and transform to Sendable type within the context
    func update<T: Sendable>(
        objectID: NSManagedObjectID,
        update: @Sendable @escaping (Entity) throws -> Void,
        transform: @Sendable @escaping (Entity) -> T
    ) async throws -> T {
        try await coreDataActor.performBackgroundTask { context in
            guard let entity = try context.existingObject(with: objectID) as? Entity else {
                throw RepositoryError.notFound
            }
            try update(entity)
            try context.save()
            return transform(entity)
        }
    }

    /// Delete entity by objectID
    func delete(objectID: NSManagedObjectID) async throws {
        try await coreDataActor.performBackgroundTask { context in
            guard let entity = try context.existingObject(with: objectID) as? Entity else {
                throw RepositoryError.notFound
            }
            context.delete(entity)
            try context.save()
        }
    }

    /// Batch delete with predicate
    func batchDelete(predicate: NSPredicate) async throws -> Int {
        return try await coreDataActor.batchDelete(Entity.self, predicate: predicate)
    }

    /// Count entities with predicate
    func count(predicate: NSPredicate?) async throws -> Int {
        return try await coreDataActor.count(Entity.self, predicate: predicate)
    }

    /// Perform custom operation in background context
    func performBackgroundTask<T: Sendable>(_ block: @Sendable @escaping (NSManagedObjectContext) async throws -> T) async throws -> T {
        try await coreDataActor.performBackgroundTask(block)
    }

    /// Perform custom operation in view context
    func performViewContextTask<T: Sendable>(_ block: @Sendable @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await coreDataActor.performViewContextTask(block)
    }
}

// MARK: - Repository Error

public enum RepositoryError: LocalizedError {
    case notFound
    case invalidEntity
    case transactionFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .notFound:
            "Entity not found"
        case .invalidEntity:
            "Invalid entity type"
        case let .transactionFailed(error):
            "Transaction failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Specialized Repositories

/// Repository for Acquisition entities with domain-specific operations
public final class AcquisitionCoreDataRepository: CoreDataRepository<Acquisition>, @unchecked Sendable {
    public func findByStatus(_ status: String) async throws -> [AcquisitionInfo] {
        let request = NSFetchRequest<Acquisition>(entityName: entityName)
        request.predicate = NSPredicate(format: "status == %@", status)

        return try await fetch(with: request) { acquisition in
            AcquisitionInfo(
                id: acquisition.id ?? UUID(),
                title: acquisition.title ?? "",
                status: acquisition.status ?? "",
                projectNumber: acquisition.projectNumber ?? "",
                requirements: acquisition.requirements ?? "",
                createdDate: acquisition.createdDate ?? Date()
            )
        }
    }

    public func findByDateRange(from startDate: Date, to endDate: Date) async throws -> [AcquisitionInfo] {
        let request = NSFetchRequest<Acquisition>(entityName: entityName)
        request.predicate = NSPredicate(format: "createdDate >= %@ AND createdDate <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

        return try await fetch(with: request) { acquisition in
            AcquisitionInfo(
                id: acquisition.id ?? UUID(),
                title: acquisition.title ?? "",
                status: acquisition.status ?? "",
                projectNumber: acquisition.projectNumber ?? "",
                requirements: acquisition.requirements ?? "",
                createdDate: acquisition.createdDate ?? Date()
            )
        }
    }

    public func findWithDocuments() async throws -> [AcquisitionInfo] {
        let request = NSFetchRequest<Acquisition>(entityName: entityName)
        request.predicate = NSPredicate(format: "documents.@count > 0")

        return try await fetch(with: request) { acquisition in
            AcquisitionInfo(
                id: acquisition.id ?? UUID(),
                title: acquisition.title ?? "",
                status: acquisition.status ?? "",
                projectNumber: acquisition.projectNumber ?? "",
                requirements: acquisition.requirements ?? "",
                createdDate: acquisition.createdDate ?? Date()
            )
        }
    }
}

/// Repository for Document entities
public final class DocumentCoreDataRepository: CoreDataRepository<AcquisitionDocument>, @unchecked Sendable {
    public func findByType(_ type: String) async throws -> [DocumentInfo] {
        let request = NSFetchRequest<AcquisitionDocument>(entityName: entityName)
        request.predicate = NSPredicate(format: "documentType == %@", type)

        return try await fetch(with: request) { document in
            DocumentInfo(
                id: document.id ?? UUID(),
                content: document.content ?? "",
                documentType: document.documentType ?? "",
                createdDate: document.createdDate ?? Date(),
                acquisitionId: document.acquisition?.id ?? UUID()
            )
        }
    }

    public func findRecentDocuments(limit: Int = 10) async throws -> [DocumentInfo] {
        let request = NSFetchRequest<AcquisitionDocument>(entityName: entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        request.fetchLimit = limit

        return try await fetch(with: request) { document in
            DocumentInfo(
                id: document.id ?? UUID(),
                content: document.content ?? "",
                documentType: document.documentType ?? "",
                createdDate: document.createdDate ?? Date(),
                acquisitionId: document.acquisition?.id ?? UUID()
            )
        }
    }
}

// MARK: - Sendable DTOs

/// Sendable representation of Acquisition data
public struct AcquisitionInfo: Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let status: String
    public let projectNumber: String
    public let requirements: String
    public let createdDate: Date

    public init(id: UUID, title: String, status: String, projectNumber: String, requirements: String, createdDate: Date) {
        self.id = id
        self.title = title
        self.status = status
        self.projectNumber = projectNumber
        self.requirements = requirements
        self.createdDate = createdDate
    }
}

/// DocumentInfo is already defined in DocumentRepository.swift
