import CoreData
import Foundation

public extension MetricInsightEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MetricInsightEntity> {
        NSFetchRequest<MetricInsightEntity>(entityName: "MetricInsight")
    }

    @NSManaged var id: UUID?
    @NSManaged var type: String?
    @NSManaged var severity: String?
    @NSManaged var message: String?
    @NSManaged var affectedMetricsData: Data?
    @NSManaged var confidence: Double
    @NSManaged var timestamp: Date?
    @NSManaged var measurements: NSSet?
    @NSManaged var summary: MetricsSummaryEntity?
}

// MARK: Generated accessors for measurements

public extension MetricInsightEntity {
    @objc(addMeasurementsObject:)
    @NSManaged func addToMeasurements(_ value: MetricMeasurementEntity)

    @objc(removeMeasurementsObject:)
    @NSManaged func removeFromMeasurements(_ value: MetricMeasurementEntity)

    @objc(addMeasurements:)
    @NSManaged func addToMeasurements(_ values: NSSet)

    @objc(removeMeasurements:)
    @NSManaged func removeFromMeasurements(_ values: NSSet)
}

extension MetricInsightEntity: Identifiable {}
