import Foundation
import CoreData

extension Acquisition {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Acquisition> {
        return NSFetchRequest<Acquisition>(entityName: "Acquisition")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var projectNumber: String?
    @NSManaged public var requirements: String?
    @NSManaged public var status: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var lastModifiedDate: Date?
    @NSManaged public var documentChainMetadata: Data?
    @NSManaged public var documents: NSSet?
    @NSManaged public var uploadedFiles: NSSet?
    @NSManaged public var generatedFiles: NSSet?

}

// MARK: Generated accessors for documents
extension Acquisition {

    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: AcquisitionDocument)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: AcquisitionDocument)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)

}

// MARK: Generated accessors for uploadedFiles
extension Acquisition {

    @objc(addUploadedFilesObject:)
    @NSManaged public func addToUploadedFiles(_ value: UploadedFile)

    @objc(removeUploadedFilesObject:)
    @NSManaged public func removeFromUploadedFiles(_ value: UploadedFile)

    @objc(addUploadedFiles:)
    @NSManaged public func addToUploadedFiles(_ values: NSSet)

    @objc(removeUploadedFiles:)
    @NSManaged public func removeFromUploadedFiles(_ values: NSSet)

}

// MARK: Generated accessors for generatedFiles
extension Acquisition {

    @objc(addGeneratedFilesObject:)
    @NSManaged public func addToGeneratedFiles(_ value: GeneratedFile)

    @objc(removeGeneratedFilesObject:)
    @NSManaged public func removeFromGeneratedFiles(_ value: GeneratedFile)

    @objc(addGeneratedFiles:)
    @NSManaged public func addToGeneratedFiles(_ values: NSSet)

    @objc(removeGeneratedFiles:)
    @NSManaged public func removeFromGeneratedFiles(_ values: NSSet)

}

extension Acquisition : Identifiable {

}