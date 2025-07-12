import Foundation
import CoreData

extension GeneratedFile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeneratedFile> {
        return NSFetchRequest<GeneratedFile>(entityName: "GeneratedFile")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var fileName: String?
    @NSManaged public var content: Data?
    @NSManaged public var fileType: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var acquisition: Acquisition?

}

extension GeneratedFile : Identifiable {

}