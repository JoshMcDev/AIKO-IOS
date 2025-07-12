import Foundation
import CoreData

@objc(AcquisitionDocument)
public class AcquisitionDocument: NSManagedObject {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdDate")
        setPrimitiveValue("draft", forKey: "status")
    }
}