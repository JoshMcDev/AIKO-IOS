import Foundation
import CoreData

extension MetricInsightEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricInsightEntity> {
        return NSFetchRequest<MetricInsightEntity>(entityName: "MetricInsight")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var severity: String?
    @NSManaged public var message: String?
    @NSManaged public var affectedMetricsData: Data?
    @NSManaged public var confidence: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var measurements: NSSet?
    @NSManaged public var summary: MetricsSummaryEntity?
}

// MARK: Generated accessors for measurements
extension MetricInsightEntity {
    
    @objc(addMeasurementsObject:)
    @NSManaged public func addToMeasurements(_ value: MetricMeasurementEntity)
    
    @objc(removeMeasurementsObject:)
    @NSManaged public func removeFromMeasurements(_ value: MetricMeasurementEntity)
    
    @objc(addMeasurements:)
    @NSManaged public func addToMeasurements(_ values: NSSet)
    
    @objc(removeMeasurements:)
    @NSManaged public func removeFromMeasurements(_ values: NSSet)
}

extension MetricInsightEntity : Identifiable {
}