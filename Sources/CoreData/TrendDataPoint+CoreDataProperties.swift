import CoreData
import Foundation

public extension TrendDataPointEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TrendDataPointEntity> {
        NSFetchRequest<TrendDataPointEntity>(entityName: "TrendDataPoint")
    }

    @NSManaged var timestamp: Date?
    @NSManaged var value: Double
    @NSManaged var trend: MetricTrendEntity?
}

extension TrendDataPointEntity: Identifiable {}
