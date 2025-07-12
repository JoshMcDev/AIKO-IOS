import CoreData
import Foundation

public extension Acquisition {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Acquisition> {
        NSFetchRequest<Acquisition>(entityName: "Acquisition")
    }

    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var projectNumber: String?
    @NSManaged var requirements: String?
    @NSManaged var status: String?
    @NSManaged var createdDate: Date?
    @NSManaged var lastModifiedDate: Date?
    @NSManaged var documentChainMetadata: Data?
    @NSManaged var documents: NSSet?
    @NSManaged var uploadedFiles: NSSet?
    @NSManaged var generatedFiles: NSSet?
}

// MARK: Generated accessors for documents

public extension Acquisition {
    @objc(addDocumentsObject:)
    @NSManaged func addToDocuments(_ value: AcquisitionDocument)

    @objc(removeDocumentsObject:)
    @NSManaged func removeFromDocuments(_ value: AcquisitionDocument)

    @objc(addDocuments:)
    @NSManaged func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged func removeFromDocuments(_ values: NSSet)
}

// MARK: Generated accessors for uploadedFiles

public extension Acquisition {
    @objc(addUploadedFilesObject:)
    @NSManaged func addToUploadedFiles(_ value: UploadedFile)

    @objc(removeUploadedFilesObject:)
    @NSManaged func removeFromUploadedFiles(_ value: UploadedFile)

    @objc(addUploadedFiles:)
    @NSManaged func addToUploadedFiles(_ values: NSSet)

    @objc(removeUploadedFiles:)
    @NSManaged func removeFromUploadedFiles(_ values: NSSet)
}

// MARK: Generated accessors for generatedFiles

public extension Acquisition {
    @objc(addGeneratedFilesObject:)
    @NSManaged func addToGeneratedFiles(_ value: GeneratedFile)

    @objc(removeGeneratedFilesObject:)
    @NSManaged func removeFromGeneratedFiles(_ value: GeneratedFile)

    @objc(addGeneratedFiles:)
    @NSManaged func addToGeneratedFiles(_ values: NSSet)

    @objc(removeGeneratedFiles:)
    @NSManaged func removeFromGeneratedFiles(_ values: NSSet)
}

extension Acquisition: Identifiable {}
