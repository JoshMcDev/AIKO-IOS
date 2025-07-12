import Foundation
import CoreData

extension UploadedFile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UploadedFile> {
        return NSFetchRequest<UploadedFile>(entityName: "UploadedFile")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var fileName: String?
    @NSManaged public var data: Data?
    @NSManaged public var uploadDate: Date?
    @NSManaged public var contentSummary: String?
    @NSManaged public var acquisition: Acquisition?

}

extension UploadedFile : Identifiable {

}