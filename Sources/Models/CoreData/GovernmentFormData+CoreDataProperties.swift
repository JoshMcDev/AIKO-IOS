import CoreData
import Foundation

public extension GovernmentFormData {
    @nonobjc class func fetchRequest() -> NSFetchRequest<GovernmentFormData> {
        NSFetchRequest<GovernmentFormData>(entityName: "GovernmentFormData")
    }

    @NSManaged var id: UUID?
    @NSManaged var formType: String?
    @NSManaged var formNumber: String?
    @NSManaged var revision: String?
    @NSManaged var formData: Data?
    @NSManaged var createdDate: Date?
    @NSManaged var lastModifiedDate: Date?
    @NSManaged var status: String?
    @NSManaged var metadata: Data?
    @NSManaged var acquisition: Acquisition?
}

// MARK: - Fetch Request Helpers

extension GovernmentFormData {
    /// Fetch all forms for a specific acquisition
    static func fetchForAcquisition(_ acquisitionId: UUID, in context: NSManagedObjectContext) -> [GovernmentFormData] {
        let request: NSFetchRequest<GovernmentFormData> = fetchRequest()
        request.predicate = NSPredicate(format: "acquisition.id == %@", acquisitionId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching forms for acquisition: \(error)")
            return []
        }
    }

    /// Fetch forms by type
    static func fetchByType(_ formType: String, in context: NSManagedObjectContext) -> [GovernmentFormData] {
        let request: NSFetchRequest<GovernmentFormData> = fetchRequest()
        request.predicate = NSPredicate(format: "formType == %@", formType)
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching forms by type: \(error)")
            return []
        }
    }

    /// Fetch forms by status
    static func fetchByStatus(_ status: String, in context: NSManagedObjectContext) -> [GovernmentFormData] {
        let request: NSFetchRequest<GovernmentFormData> = fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", status)
        request.sortDescriptors = [NSSortDescriptor(key: "lastModifiedDate", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching forms by status: \(error)")
            return []
        }
    }

    /// Fetch a specific form by ID
    static func fetchById(_ id: UUID, in context: NSManagedObjectContext) -> GovernmentFormData? {
        let request: NSFetchRequest<GovernmentFormData> = fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching form by ID: \(error)")
            return nil
        }
    }
}

// MARK: Generated accessors for GovernmentFormData

extension GovernmentFormData: Identifiable {}
