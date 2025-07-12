import CoreData
import Foundation

public class CoreDataStack {
    public static let shared = CoreDataStack()
    
    private init() {}
    
    public lazy var persistentContainer: NSPersistentContainer = {
        // Find the model in the module bundle
        guard let modelURL = Bundle.module.url(forResource: "AIKO", withExtension: "momd") else {
            print("CoreData Error: Failed to find AIKO.momd in bundle")
            print("Bundle path: \(Bundle.module.bundlePath)")
            print("Bundle resources: \(Bundle.module.urls(forResourcesWithExtension: "momd", subdirectory: nil) ?? [])")
            
            // Try looking for xcdatamodeld
            if let xcdatamodeldURL = Bundle.module.url(forResource: "AIKO", withExtension: "xcdatamodeld") {
                print("Found xcdatamodeld at: \(xcdatamodeldURL)")
                // For SPM, we need to look inside the xcdatamodeld
                let modelName = "AIKO.xcdatamodel"
                let modelURL = xcdatamodeldURL.appendingPathComponent(modelName)
                if let model = NSManagedObjectModel(contentsOf: modelURL) {
                    let container = NSPersistentContainer(name: "AIKO", managedObjectModel: model)
                    self.setupContainer(container)
                    return container
                }
            }
            
            fatalError("Failed to find Core Data model")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model from URL: \(modelURL)")
        }
        
        let container = NSPersistentContainer(name: "AIKO", managedObjectModel: model)
        setupContainer(container)
        
        return container
    }()
    
    private func setupContainer(_ container: NSPersistentContainer) {
        // Enable automatic migration
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Enable CloudKit sync if desired
        // description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourcompany.aiko")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                print("CoreData Error: Failed to load persistent store")
                print("Store URL: \(storeDescription.url?.absoluteString ?? "Unknown")")
                print("Error: \(error), \(error.userInfo)")
                fatalError("Failed to load Core Data store: \(error)")
            } else {
                print("CoreData: Successfully loaded store at \(storeDescription.url?.absoluteString ?? "Unknown")")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    public func save() throws {
        let context = viewContext
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Batch Operations
    
    public func batchDelete<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        fetchRequest.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
        
        let changes = [NSDeletedObjectsKey: objectIDArray]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
    }
    
    // MARK: - Export/Import Operations
    
    public func exportCoreDataToJSON() throws -> Data {
        let context = viewContext
        var exportData: [String: [[String: Any]]] = [:]
        
        // Export all entities
        let entities = persistentContainer.managedObjectModel.entities
        
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
    
    public func importCoreDataFromJSON(_ data: Data) throws {
        let context = newBackgroundContext()
        
        guard let exportData = try JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] else {
            throw NSError(domain: "CoreDataStack", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        
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
        
        try context.save()
        
        // Merge changes to main context
        viewContext.performAndWait {
            viewContext.reset()
        }
    }
}