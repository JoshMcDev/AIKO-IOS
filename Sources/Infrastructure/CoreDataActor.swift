@preconcurrency import CoreData
import Foundation

/// Actor-based Core Data manager that ensures thread-safe access to Core Data operations
/// This follows Swift concurrency best practices by isolating Core Data contexts within an actor
public actor CoreDataActor {
    // MARK: - Properties

    private let persistentContainer: NSPersistentContainer
    private let viewContext: NSManagedObjectContext

    // MARK: - Initialization

    public init(containerName: String = "AIKO", inMemory: Bool = false) {
        // Find the model in the module bundle
        if let modelURL = Bundle.module.url(forResource: containerName, withExtension: "momd") {
            guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError("Failed to load Core Data model from URL: \(modelURL)")
            }
            persistentContainer = NSPersistentContainer(name: containerName, managedObjectModel: model)
        } else if let xcdatamodeldURL = Bundle.module.url(forResource: containerName, withExtension: "xcdatamodeld") {
            // Try looking for xcdatamodeld as fallback
            let modelName = "\(containerName).xcdatamodel"
            let modelURL = xcdatamodeldURL.appendingPathComponent(modelName)
            if let model = NSManagedObjectModel(contentsOf: modelURL) {
                persistentContainer = NSPersistentContainer(name: containerName, managedObjectModel: model)
            } else {
                fatalError("Failed to load Core Data model from \(modelURL)")
            }
        } else {
            fatalError("Failed to find Core Data model")
        }

        // Configure for in-memory store if needed (useful for testing)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        } else {
            // Enable automatic migration
            let description = persistentContainer.persistentStoreDescriptions.first
            description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        // Load persistent stores synchronously
        var loadError: Error?
        persistentContainer.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError {
            fatalError("Failed to load Core Data store: \(error)")
        }

        viewContext = persistentContainer.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Context Management

    /// Creates a new background context for batch operations
    public func createBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    // MARK: - CRUD Operations

    // MARK: - DEPRECATED METHODS REMOVED
    // The following methods were removed due to Sendable conformance violations:
    // - fetch<T: NSManagedObject>(_:) -> [T]
    // - fetchObject<T: NSManagedObject>(ofType:objectID:) -> T?
    // - create<T: NSManagedObject>(_:) -> T
    // 
    // Use performViewContextTask or performBackgroundTask instead to keep
    // Core Data entities within actor boundaries and maintain Sendable compliance.

    /// Saves the view context
    public func save() async throws {
        try await viewContext.perform { @Sendable in
            if self.viewContext.hasChanges {
                try self.viewContext.save()
            }
        }
    }

    // delete(_ object:) method was also removed for Sendable compliance
    // Use performViewContextTask { context in context.delete(object); try context.save() }

    // MARK: - Batch Operations

    /// Performs a batch delete operation
    public func batchDelete(_ type: (some NSManagedObject).Type, predicate: NSPredicate? = nil) async throws -> Int {
        let entityName = String(describing: type)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate

        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeCount

        return try await viewContext.perform { @Sendable in
            let result = try self.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let count = result?.result as? Int ?? 0

            // Merge changes to ensure UI updates
            self.viewContext.refreshAllObjects()

            return count
        }
    }

    /// Performs a batch update operation
    public func batchUpdate(
        _ type: (some NSManagedObject).Type,
        predicate: NSPredicate? = nil,
        propertiesToUpdate: [String: Any]
    ) async throws -> Int {
        let entityName = String(describing: type)
        let batchUpdateRequest = NSBatchUpdateRequest(entityName: entityName)
        batchUpdateRequest.predicate = predicate
        batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
        batchUpdateRequest.resultType = .updatedObjectsCountResultType

        return try await viewContext.perform { @Sendable in
            let result = try self.viewContext.execute(batchUpdateRequest) as? NSBatchUpdateResult
            let count = result?.result as? Int ?? 0

            // Merge changes to ensure UI updates
            self.viewContext.refreshAllObjects()

            return count
        }
    }

    // MARK: - Transaction Support

    /// Performs a transaction within a background context
    public func performBackgroundTask<T: Sendable>(_ block: @Sendable @escaping (NSManagedObjectContext) async throws -> T) async throws -> T {
        let context = createBackgroundContext()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                Task { @Sendable in
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

    /// Performs a transaction within the view context
    public func performViewContextTask<T: Sendable>(_ block: @Sendable @escaping (NSManagedObjectContext) async throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                Task { @Sendable in
                    do {
                        let result = try await block(self.viewContext)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Performs a synchronous read-only task on the view context
    public func performViewContextTask<T: Sendable>(_ block: @Sendable @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await viewContext.perform { @Sendable in
            try block(self.viewContext)
        }
    }

    // MARK: - Query Helpers

    /// Counts objects matching the given predicate
    public func count<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) async throws -> Int {
        let entityName = String(describing: type)
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate

        return try await viewContext.perform { @Sendable in
            try self.viewContext.count(for: request)
        }
    }

    /// Checks if any objects exist matching the predicate
    public func exists(_ type: (some NSManagedObject).Type, predicate: NSPredicate) async throws -> Bool {
        let count = try await count(type, predicate: predicate)
        return count > 0
    }

    // MARK: - Context Management

    /// Resets the view context to discard unsaved changes and refresh objects
    public func reset() async {
        await viewContext.perform { @Sendable in
            self.viewContext.reset()
        }
    }

    /// Import data from JSON export format  
    public func importFromJSON(_ exportData: [String: [[String: Any]]]) async throws {
        let context = createBackgroundContext()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    var objectIDMap: [String: NSManagedObject] = [:]

                    // First pass: Create all objects
                    for (entityName, objects) in exportData {
                        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
                            continue
                        }

                        for objectData in objects {
                            let object = NSManagedObject(entity: entity, insertInto: context)

                            // Import attributes only
                            for (key, attribute) in entity.attributesByName {
                                if let value = objectData[key] {
                                    if attribute.attributeType == .dateAttributeType,
                                       let timestamp = value as? TimeInterval {
                                        object.setValue(Date(timeIntervalSince1970: timestamp), forKey: key)
                                    } else if attribute.attributeType == .binaryDataAttributeType,
                                              let base64String = value as? String,
                                              let data = Data(base64Encoded: base64String) {
                                        object.setValue(data, forKey: key)
                                    } else {
                                        object.setValue(value, forKey: key)
                                    }
                                }
                            }

                            // Store object for relationship mapping
                            if let idString = objectData["objectID"] as? String {
                                objectIDMap[idString] = object
                            }
                        }
                    }

                    // Second pass: Restore relationships
                    // Note: This is simplified - in production, you'd need more sophisticated relationship mapping

                    if context.hasChanges {
                        try context.save()
                    }

                    // Reset view context to pick up changes
                    Task { @Sendable in
                        await self.reset()
                    }

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Sendable DTOs

/// Sendable representation of Core Data object IDs for crossing actor boundaries
public struct ManagedObjectReference: Sendable {
    public let uriRepresentation: URL

    public init(objectID: NSManagedObjectID) {
        uriRepresentation = objectID.uriRepresentation()
    }

    public func objectID(in coordinator: NSPersistentStoreCoordinator) -> NSManagedObjectID? {
        coordinator.managedObjectID(forURIRepresentation: uriRepresentation)
    }
}

// MARK: - Error Types

public enum CoreDataActorError: LocalizedError, Sendable {
    case objectNotFound
    case saveFailed(String)
    case invalidObjectID
    case fetchFailed(String)

    public var errorDescription: String? {
        switch self {
        case .objectNotFound:
            "The requested object was not found"
        case let .saveFailed(reason):
            "Failed to save: \(reason)"
        case .invalidObjectID:
            "Invalid object ID"
        case let .fetchFailed(reason):
            "Failed to fetch: \(reason)"
        }
    }
}
