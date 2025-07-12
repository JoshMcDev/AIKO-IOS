import CoreData
import Foundation

public extension AcquisitionDocument {
    @nonobjc class func fetchRequest() -> NSFetchRequest<AcquisitionDocument> {
        NSFetchRequest<AcquisitionDocument>(entityName: "AcquisitionDocument")
    }

    @NSManaged var id: UUID?
    @NSManaged var content: String?
    @NSManaged var documentType: String?
    @NSManaged var status: String?
    @NSManaged var createdDate: Date?
    @NSManaged var acquisition: Acquisition?
}

extension AcquisitionDocument: Identifiable {}
