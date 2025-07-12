import Foundation
import CoreData

extension AcquisitionDocument {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AcquisitionDocument> {
        return NSFetchRequest<AcquisitionDocument>(entityName: "AcquisitionDocument")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var documentType: String?
    @NSManaged public var status: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var acquisition: Acquisition?

}

extension AcquisitionDocument : Identifiable {

}