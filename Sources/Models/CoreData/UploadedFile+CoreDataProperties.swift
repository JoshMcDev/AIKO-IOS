import CoreData
import Foundation

public extension UploadedFile {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UploadedFile> {
        NSFetchRequest<UploadedFile>(entityName: "UploadedFile")
    }

    @NSManaged var id: UUID?
    @NSManaged var fileName: String?
    @NSManaged var data: Data?
    @NSManaged var uploadDate: Date?
    @NSManaged var contentSummary: String?
    @NSManaged var acquisition: Acquisition?
}

extension UploadedFile: Identifiable {}
