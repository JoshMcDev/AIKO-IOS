import Foundation
import CoreData

extension MetricsReportEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricsReportEntity> {
        return NSFetchRequest<MetricsReportEntity>(entityName: "MetricsReport")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var periodStart: Date?
    @NSManaged public var periodEnd: Date?
    @NSManaged public var generatedAt: Date?
    @NSManaged public var executiveSummary: String?
    @NSManaged public var summary: MetricsSummaryEntity?
    @NSManaged public var detailedMeasurements: NSSet?
    @NSManaged public var trends: NSSet?
    @NSManaged public var comparisons: NSSet?
}

// MARK: Generated accessors for detailedMeasurements
extension MetricsReportEntity {
    
    @objc(addDetailedMeasurementsObject:)
    @NSManaged public func addToDetailedMeasurements(_ value: MetricMeasurementEntity)
    
    @objc(removeDetailedMeasurementsObject:)
    @NSManaged public func removeFromDetailedMeasurements(_ value: MetricMeasurementEntity)
    
    @objc(addDetailedMeasurements:)
    @NSManaged public func addToDetailedMeasurements(_ values: NSSet)
    
    @objc(removeDetailedMeasurements:)
    @NSManaged public func removeFromDetailedMeasurements(_ values: NSSet)
}

// MARK: Generated accessors for trends
extension MetricsReportEntity {
    
    @objc(addTrendsObject:)
    @NSManaged public func addToTrends(_ value: MetricTrendEntity)
    
    @objc(removeTrendsObject:)
    @NSManaged public func removeFromTrends(_ value: MetricTrendEntity)
    
    @objc(addTrends:)
    @NSManaged public func addToTrends(_ values: NSSet)
    
    @objc(removeTrends:)
    @NSManaged public func removeFromTrends(_ values: NSSet)
}

// MARK: Generated accessors for comparisons
extension MetricsReportEntity {
    
    @objc(addComparisonsObject:)
    @NSManaged public func addToComparisons(_ value: MetricComparisonEntity)
    
    @objc(removeComparisonsObject:)
    @NSManaged public func removeFromComparisons(_ value: MetricComparisonEntity)
    
    @objc(addComparisons:)
    @NSManaged public func addToComparisons(_ values: NSSet)
    
    @objc(removeComparisons:)
    @NSManaged public func removeFromComparisons(_ values: NSSet)
}

extension MetricsReportEntity : Identifiable {
}