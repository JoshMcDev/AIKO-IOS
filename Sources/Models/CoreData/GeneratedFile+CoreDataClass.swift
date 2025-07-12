import CoreData
import Foundation

@objc(GeneratedFile)
public class GeneratedFile: NSManagedObject {
    override public func awakeFromInsert() {
        super.awakeFromInsert()

        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdDate")
    }
}
