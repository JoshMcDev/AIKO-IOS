import Foundation
import CoreData

extension TrendDataPointEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrendDataPointEntity> {
        return NSFetchRequest<TrendDataPointEntity>(entityName: "TrendDataPoint")
    }
    
    @NSManaged public var timestamp: Date?
    @NSManaged public var value: Double
    @NSManaged public var trend: MetricTrendEntity?
}

extension TrendDataPointEntity : Identifiable {
}