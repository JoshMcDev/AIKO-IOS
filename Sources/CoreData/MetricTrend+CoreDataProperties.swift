import CoreData
import Foundation

public extension MetricTrendEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MetricTrendEntity> {
        NSFetchRequest<MetricTrendEntity>(entityName: "MetricTrend")
    }

    @NSManaged var id: UUID?
    @NSManaged var metricName: String?
    @NSManaged var direction: String?
    @NSManaged var magnitude: Double
    @NSManaged var significance: Double
    @NSManaged var report: MetricsReportEntity?
    @NSManaged var trendDataPoints: NSSet?
}

// MARK: Generated accessors for trendDataPoints

public extension MetricTrendEntity {
    @objc(addTrendDataPointsObject:)
    @NSManaged func addToTrendDataPoints(_ value: TrendDataPointEntity)

    @objc(removeTrendDataPointsObject:)
    @NSManaged func removeFromTrendDataPoints(_ value: TrendDataPointEntity)

    @objc(addTrendDataPoints:)
    @NSManaged func addToTrendDataPoints(_ values: NSSet)

    @objc(removeTrendDataPoints:)
    @NSManaged func removeFromTrendDataPoints(_ values: NSSet)
}

extension MetricTrendEntity: Identifiable {}
