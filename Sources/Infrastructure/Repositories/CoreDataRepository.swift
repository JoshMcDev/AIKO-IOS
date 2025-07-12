import Foundation
import CoreData
import Combine

/// Base Core Data repository implementing common CRUD operations
open class CoreDataRepository<Entity: NSManagedObject> {
    public typealias Model = Entity
    
    private let context: NSManagedObjectContext
    private let entityName: String
    
    public init(context: NSManagedObjectContext, entityType: Entity.Type) {
        self.context = context
        self.entityName = String(describing: entityType)
    }
    
    // MARK: - Repository Protocol
    
    public func create(_ model: Entity) async throws -> Entity {
        return try await context.perform {
            self.context.insert(model)
            try self.context.save()
            return model
        }
    }
    
    public func read(id: Entity.ID) async throws -> Entity? where Entity: Identifiable {
        // For Core Data entities, we need to find by the id property
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id as! CVarArg)
        request.fetchLimit = 1
        
        return try await context.perform {
            try self.context.fetch(request).first
        }
    }
    
    // Original Core Data method
    public func read(objectID: NSManagedObjectID) async throws -> Entity? {
        return try await context.perform {
            try self.context.existingObject(with: objectID) as? Entity
        }
    }
    
    public func update(_ model: Entity) async throws -> Entity {
        return try await context.perform {
            guard self.context.hasChanges else { return model }
            try self.context.save()
            return model
        }
    }
    
    public func delete(id: Entity.ID) async throws where Entity: Identifiable {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id as! CVarArg)
        request.fetchLimit = 1
        
        try await context.perform {
            if let object = try self.context.fetch(request).first {
                self.context.delete(object)
                try self.context.save()
            }
        }
    }
    
    // Original Core Data method
    public func delete(objectID: NSManagedObjectID) async throws {
        try await context.perform {
            guard let object = try self.context.existingObject(with: objectID) as? Entity else {
                throw RepositoryError.notFound
            }
            self.context.delete(object)
            try self.context.save()
        }
    }
    
    public func list() async throws -> [Entity] {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        return try await context.perform {
            try self.context.fetch(request)
        }
    }
    
    // MARK: - QueryableRepository Protocol
    
    public func query(predicate: NSPredicate) async throws -> [Entity] {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.predicate = predicate
        
        return try await context.perform {
            try self.context.fetch(request)
        }
    }
    
    public func query(predicates: [NSPredicate], sortDescriptors: [NSSortDescriptor]?, limit: Int?) async throws -> [Entity] {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = sortDescriptors
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        return try await context.perform {
            try self.context.fetch(request)
        }
    }
    
    public func count(predicate: NSPredicate?) async throws -> Int {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.predicate = predicate
        
        return try await context.perform {
            try self.context.count(for: request)
        }
    }
    
    // MARK: - Batch Operations
    
    public func batchCreate(_ models: [Entity]) async throws -> [Entity] {
        return try await context.perform {
            models.forEach { self.context.insert($0) }
            try self.context.save()
            return models
        }
    }
    
    public func batchDelete(predicate: NSPredicate) async throws -> Int {
        let request = NSFetchRequest<Entity>(entityName: entityName)
        request.predicate = predicate
        
        return try await context.perform {
            let objects = try self.context.fetch(request)
            objects.forEach { self.context.delete($0) }
            try self.context.save()
            return objects.count
        }
    }
    
    // MARK: - Transaction Support
    
    public func performTransaction<T>(_ block: @escaping (NSManagedObjectContext) async throws -> T) async throws -> T {
        let context = self.context
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                Task {
                    do {
                        let result = try await block(context)
                        if context.hasChanges {
                            try context.save()
                        }
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
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
            return "Entity not found"
        case .invalidEntity:
            return "Invalid entity type"
        case .transactionFailed(let error):
            return "Transaction failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Specialized Repositories

/// Repository for Acquisition entities with domain-specific operations
public final class AcquisitionCoreDataRepository: CoreDataRepository<Acquisition> {
    
    public func findByStatus(_ status: String) async throws -> [Acquisition] {
        let predicate = NSPredicate(format: "status == %@", status)
        return try await query(predicate: predicate)
    }
    
    public func findByDateRange(from startDate: Date, to endDate: Date) async throws -> [Acquisition] {
        let predicate = NSPredicate(format: "createdDate >= %@ AND createdDate <= %@", startDate as NSDate, endDate as NSDate)
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        return try await query(predicates: [predicate], sortDescriptors: [sortDescriptor], limit: nil)
    }
    
    public func findWithDocuments() async throws -> [Acquisition] {
        let predicate = NSPredicate(format: "documents.@count > 0")
        return try await query(predicate: predicate)
    }
}

/// Repository for Document entities
public final class DocumentCoreDataRepository: CoreDataRepository<AcquisitionDocument> {
    
    public func findByType(_ type: String) async throws -> [AcquisitionDocument] {
        let predicate = NSPredicate(format: "documentType == %@", type)
        return try await query(predicate: predicate)
    }
    
    public func findRecentDocuments(limit: Int = 10) async throws -> [AcquisitionDocument] {
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        return try await query(predicates: [], sortDescriptors: [sortDescriptor], limit: limit)
    }
}

// RegulationUpdate repository would go here when that model is created