import CoreData
import Foundation

@objc(AcquisitionDocument)
public class AcquisitionDocument: NSManagedObject {
    override public func awakeFromInsert() {
        super.awakeFromInsert()

        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdDate")
        setPrimitiveValue("draft", forKey: "status")
    }
}
