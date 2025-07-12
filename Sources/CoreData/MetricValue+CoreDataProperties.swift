import CoreData
import Foundation

public extension MetricValueEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MetricValueEntity> {
        NSFetchRequest<MetricValueEntity>(entityName: "MetricValue")
    }

    @NSManaged var id: UUID?
    @NSManaged var timestamp: Date?
    @NSManaged var value: Double
    @NSManaged var unit: String?
    @NSManaged var metadataData: Data?
    @NSManaged var measurement: MetricMeasurementEntity?
}

extension MetricValueEntity: Identifiable {}
