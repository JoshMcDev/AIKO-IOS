import CoreData
import Foundation

public extension GeneratedFile {
    @nonobjc class func fetchRequest() -> NSFetchRequest<GeneratedFile> {
        NSFetchRequest<GeneratedFile>(entityName: "GeneratedFile")
    }

    @NSManaged var id: UUID?
    @NSManaged var fileName: String?
    @NSManaged var content: Data?
    @NSManaged var fileType: String?
    @NSManaged var createdDate: Date?
    @NSManaged var acquisition: Acquisition?
}

extension GeneratedFile: Identifiable {}
