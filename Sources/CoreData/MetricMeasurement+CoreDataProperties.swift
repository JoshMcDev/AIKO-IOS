import Foundation
import CoreData

extension MetricMeasurementEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricMeasurementEntity> {
        return NSFetchRequest<MetricMeasurementEntity>(entityName: "MetricMeasurement")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var metricType: String? // "mop" or "moe"
    @NSManaged public var mopType: String? // Raw value of MeasureOfPerformance
    @NSManaged public var moeType: String? // Raw value of MeasureOfEffectiveness
    @NSManaged public var timestamp: Date?
    @NSManaged public var aggregatedValue: Double
    @NSManaged public var score: Double
    @NSManaged public var contextData: Data?
    @NSManaged public var metricValues: NSSet?
    @NSManaged public var insights: NSSet?
    @NSManaged public var report: MetricsReportEntity?
}

// MARK: Generated accessors for metricValues
extension MetricMeasurementEntity {
    
    @objc(addMetricValuesObject:)
    @NSManaged public func addToMetricValues(_ value: MetricValueEntity)
    
    @objc(removeMetricValuesObject:)
    @NSManaged public func removeFromMetricValues(_ value: MetricValueEntity)
    
    @objc(addMetricValues:)
    @NSManaged public func addToMetricValues(_ values: NSSet)
    
    @objc(removeMetricValues:)
    @NSManaged public func removeFromMetricValues(_ values: NSSet)
}

// MARK: Generated accessors for insights
extension MetricMeasurementEntity {
    
    @objc(addInsightsObject:)
    @NSManaged public func addToInsights(_ value: MetricInsightEntity)
    
    @objc(removeInsightsObject:)
    @NSManaged public func removeFromInsights(_ value: MetricInsightEntity)
    
    @objc(addInsights:)
    @NSManaged public func addToInsights(_ values: NSSet)
    
    @objc(removeInsights:)
    @NSManaged public func removeFromInsights(_ values: NSSet)
}

extension MetricMeasurementEntity : Identifiable {
}