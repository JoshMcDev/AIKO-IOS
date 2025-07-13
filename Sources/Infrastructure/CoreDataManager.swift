//
//  CoreDataManager.swift
//  AIKO
//
//  Core Data Manager placeholder to resolve build errors
//

import Foundation
import CoreData

/// Placeholder Core Data Manager to resolve build errors
@MainActor
public class CoreDataManager: ObservableObject {
    public static let shared = CoreDataManager()
    
    private init() {}
    
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AIKO")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    public func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }
}

// MARK: - Placeholder Entities
// These are temporary to resolve build errors

@objc(DocumentData)
public class DocumentData: NSManagedObject {
}

@objc(DocumentAttribute)
public class DocumentAttribute: NSManagedObject {
}