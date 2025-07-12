import Foundation
import CoreData

@objc(GeneratedFile)
public class GeneratedFile: NSManagedObject {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdDate")
    }
}