import Foundation
import CoreData

extension MetricValueEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricValueEntity> {
        return NSFetchRequest<MetricValueEntity>(entityName: "MetricValue")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var value: Double
    @NSManaged public var unit: String?
    @NSManaged public var metadataData: Data?
    @NSManaged public var measurement: MetricMeasurementEntity?
}

extension MetricValueEntity : Identifiable {
}