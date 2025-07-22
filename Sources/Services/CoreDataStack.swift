import CoreData
import Foundation

public final class CoreDataStack: @unchecked Sendable {
    public static let shared = CoreDataStack()

    private let coreDataActor: CoreDataActor

    private init() {
        coreDataActor = CoreDataActor(containerName: "AIKO")
    }

    // MARK: - Core Data Actor Access

    /// Get the shared CoreDataActor for all Core Data operations
    public var actor: CoreDataActor {
        coreDataActor
    }

    // MARK: - Deprecated Direct Access

    // These methods are kept for backward compatibility but should be migrated to use CoreDataActor

    @available(*, deprecated, message: "Use actor.fetch() instead")
    public lazy var persistentContainer: NSPersistentContainer = {
        // This is now handled internally by CoreDataActor
        // Creating a dummy container for compatibility
        fatalError("Direct persistentContainer access is deprecated. Use CoreDataStack.shared.actor instead")
    }()

    // MARK: - Async Methods (New API)

    public func save() async throws {
        try await coreDataActor.save()
    }

    // MARK: - DEPRECATED METHODS REMOVED

    // The following methods were removed due to Sendable conformance violations:
    // - fetch<T: NSManagedObject>(_:) -> [T]
    // - create<T: NSManagedObject>(_:) -> T
    // - delete(_ object:)
    //
    // Use repository classes that convert Core Data entities to Sendable domain models,
    // or use coreDataActor.performViewContextTask/performBackgroundTask directly.

    // MARK: - Deprecated Sync Methods

    @available(*, deprecated, message: "Use async save() instead")
    public var viewContext: NSManagedObjectContext {
        fatalError("Direct viewContext access is deprecated. Use CoreDataStack.shared.actor instead")
    }

    @available(*, deprecated, message: "Use actor.createBackgroundContext() instead")
    public func newBackgroundContext() -> NSManagedObjectContext {
        fatalError("Direct context creation is deprecated. Use CoreDataStack.shared.actor.createBackgroundContext() instead")
    }

    // MARK: - Batch Operations

    public func batchDelete(_ type: (some NSManagedObject).Type, predicate: NSPredicate? = nil) async throws {
        nonisolated(unsafe) let pred = predicate
        _ = try await coreDataActor.batchDelete(type, predicate: pred)
    }

    // MARK: - Export/Import Operations

    public func exportCoreDataToJSON() async throws -> Data {
        try await coreDataActor.performViewContextTask { context in
            var exportData: [String: [[String: Any]]] = [:]

            // Export all entities
            let model = context.persistentStoreCoordinator?.managedObjectModel
            let entities = model?.entities ?? []

            for entity in entities {
                guard let entityName = entity.name else { continue }

                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let objects = try context.fetch(fetchRequest)

                var entityData: [[String: Any]] = []

                for object in objects {
                    var objectDict: [String: Any] = [:]

                    // Export attributes
                    for (key, _) in entity.attributesByName {
                        if let value = object.value(forKey: key) {
                            if let date = value as? Date {
                                objectDict[key] = date.timeIntervalSince1970
                            } else if let data = value as? Data {
                                objectDict[key] = data.base64EncodedString()
                            } else {
                                objectDict[key] = value
                            }
                        }
                    }

                    // Export to-one relationships (store as object ID)
                    for (key, relationship) in entity.relationshipsByName where !relationship.isToMany {
                        if let relatedObject = object.value(forKey: key) as? NSManagedObject {
                            objectDict[key] = relatedObject.objectID.uriRepresentation().absoluteString
                        }
                    }

                    // Export to-many relationships
                    for (key, relationship) in entity.relationshipsByName where relationship.isToMany {
                        if let relatedObjects = object.value(forKey: key) as? Set<NSManagedObject> {
                            let relatedIDs = relatedObjects.map { $0.objectID.uriRepresentation().absoluteString }
                            objectDict[key] = relatedIDs
                        }
                    }

                    entityData.append(objectDict)
                }

                if !entityData.isEmpty {
                    exportData[entityName] = entityData
                }
            }

            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        }
    }

    public func importCoreDataFromJSON(_ data: Data) async throws {
        guard let exportData = try JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] else {
            throw NSError(domain: "CoreDataStack", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }

        try await coreDataActor.importFromJSON(exportData)
    }
}
