import CoreData
import Foundation

public extension MetricsReportEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MetricsReportEntity> {
        NSFetchRequest<MetricsReportEntity>(entityName: "MetricsReport")
    }

    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var periodStart: Date?
    @NSManaged var periodEnd: Date?
    @NSManaged var generatedAt: Date?
    @NSManaged var executiveSummary: String?
    @NSManaged var summary: MetricsSummaryEntity?
    @NSManaged var detailedMeasurements: NSSet?
    @NSManaged var trends: NSSet?
    @NSManaged var comparisons: NSSet?
}

// MARK: Generated accessors for detailedMeasurements

public extension MetricsReportEntity {
    @objc(addDetailedMeasurementsObject:)
    @NSManaged func addToDetailedMeasurements(_ value: MetricMeasurementEntity)

    @objc(removeDetailedMeasurementsObject:)
    @NSManaged func removeFromDetailedMeasurements(_ value: MetricMeasurementEntity)

    @objc(addDetailedMeasurements:)
    @NSManaged func addToDetailedMeasurements(_ values: NSSet)

    @objc(removeDetailedMeasurements:)
    @NSManaged func removeFromDetailedMeasurements(_ values: NSSet)
}

// MARK: Generated accessors for trends

public extension MetricsReportEntity {
    @objc(addTrendsObject:)
    @NSManaged func addToTrends(_ value: MetricTrendEntity)

    @objc(removeTrendsObject:)
    @NSManaged func removeFromTrends(_ value: MetricTrendEntity)

    @objc(addTrends:)
    @NSManaged func addToTrends(_ values: NSSet)

    @objc(removeTrends:)
    @NSManaged func removeFromTrends(_ values: NSSet)
}

// MARK: Generated accessors for comparisons

public extension MetricsReportEntity {
    @objc(addComparisonsObject:)
    @NSManaged func addToComparisons(_ value: MetricComparisonEntity)

    @objc(removeComparisonsObject:)
    @NSManaged func removeFromComparisons(_ value: MetricComparisonEntity)

    @objc(addComparisons:)
    @NSManaged func addToComparisons(_ values: NSSet)

    @objc(removeComparisons:)
    @NSManaged func removeFromComparisons(_ values: NSSet)
}

extension MetricsReportEntity: Identifiable {}
