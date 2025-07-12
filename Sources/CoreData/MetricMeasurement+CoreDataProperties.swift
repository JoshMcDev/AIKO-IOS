import CoreData
import Foundation

public extension MetricMeasurementEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MetricMeasurementEntity> {
        NSFetchRequest<MetricMeasurementEntity>(entityName: "MetricMeasurement")
    }

    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var metricType: String? // "mop" or "moe"
    @NSManaged var mopType: String? // Raw value of MeasureOfPerformance
    @NSManaged var moeType: String? // Raw value of MeasureOfEffectiveness
    @NSManaged var timestamp: Date?
    @NSManaged var aggregatedValue: Double
    @NSManaged var score: Double
    @NSManaged var contextData: Data?
    @NSManaged var metricValues: NSSet?
    @NSManaged var insights: NSSet?
    @NSManaged var report: MetricsReportEntity?
}

// MARK: Generated accessors for metricValues

public extension MetricMeasurementEntity {
    @objc(addMetricValuesObject:)
    @NSManaged func addToMetricValues(_ value: MetricValueEntity)

    @objc(removeMetricValuesObject:)
    @NSManaged func removeFromMetricValues(_ value: MetricValueEntity)

    @objc(addMetricValues:)
    @NSManaged func addToMetricValues(_ values: NSSet)

    @objc(removeMetricValues:)
    @NSManaged func removeFromMetricValues(_ values: NSSet)
}

// MARK: Generated accessors for insights

public extension MetricMeasurementEntity {
    @objc(addInsightsObject:)
    @NSManaged func addToInsights(_ value: MetricInsightEntity)

    @objc(removeInsightsObject:)
    @NSManaged func removeFromInsights(_ value: MetricInsightEntity)

    @objc(addInsights:)
    @NSManaged func addToInsights(_ values: NSSet)

    @objc(removeInsights:)
    @NSManaged func removeFromInsights(_ values: NSSet)
}

extension MetricMeasurementEntity: Identifiable {}
