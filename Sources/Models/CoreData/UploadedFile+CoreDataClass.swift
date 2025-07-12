import CoreData
import Foundation

@objc(UploadedFile)
public class UploadedFile: NSManagedObject {
    override public func awakeFromInsert() {
        super.awakeFromInsert()

        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "uploadDate")
    }
}
