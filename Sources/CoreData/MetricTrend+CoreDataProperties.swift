import Foundation
import CoreData

extension MetricTrendEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricTrendEntity> {
        return NSFetchRequest<MetricTrendEntity>(entityName: "MetricTrend")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var metricName: String?
    @NSManaged public var direction: String?
    @NSManaged public var magnitude: Double
    @NSManaged public var significance: Double
    @NSManaged public var report: MetricsReportEntity?
    @NSManaged public var trendDataPoints: NSSet?
}

// MARK: Generated accessors for trendDataPoints
extension MetricTrendEntity {
    
    @objc(addTrendDataPointsObject:)
    @NSManaged public func addToTrendDataPoints(_ value: TrendDataPointEntity)
    
    @objc(removeTrendDataPointsObject:)
    @NSManaged public func removeFromTrendDataPoints(_ value: TrendDataPointEntity)
    
    @objc(addTrendDataPoints:)
    @NSManaged public func addToTrendDataPoints(_ values: NSSet)
    
    @objc(removeTrendDataPoints:)
    @NSManaged public func removeFromTrendDataPoints(_ values: NSSet)
}

extension MetricTrendEntity : Identifiable {
}