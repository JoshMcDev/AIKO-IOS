import CoreData
import Foundation

public extension MetricComparisonEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MetricComparisonEntity> {
        NSFetchRequest<MetricComparisonEntity>(entityName: "MetricComparison")
    }

    @NSManaged var id: UUID?
    @NSManaged var type: String?
    @NSManaged var difference: Double
    @NSManaged var percentageChange: Double
    @NSManaged var interpretation: String?
    @NSManaged var baseline: MetricMeasurementEntity?
    @NSManaged var comparison: MetricMeasurementEntity?
    @NSManaged var report: MetricsReportEntity?
}

extension MetricComparisonEntity: Identifiable {}
