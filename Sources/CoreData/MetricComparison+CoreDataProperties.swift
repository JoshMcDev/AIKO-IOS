import Foundation
import CoreData

extension MetricComparisonEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricComparisonEntity> {
        return NSFetchRequest<MetricComparisonEntity>(entityName: "MetricComparison")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var difference: Double
    @NSManaged public var percentageChange: Double
    @NSManaged public var interpretation: String?
    @NSManaged public var baseline: MetricMeasurementEntity?
    @NSManaged public var comparison: MetricMeasurementEntity?
    @NSManaged public var report: MetricsReportEntity?
}

extension MetricComparisonEntity : Identifiable {
}