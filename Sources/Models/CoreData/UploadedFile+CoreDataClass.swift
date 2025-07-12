import Foundation
import CoreData

@objc(UploadedFile)
public class UploadedFile: NSManagedObject {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "uploadDate")
    }
}