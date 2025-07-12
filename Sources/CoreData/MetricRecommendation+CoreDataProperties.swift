import Foundation
import CoreData

extension MetricRecommendationEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricRecommendationEntity> {
        return NSFetchRequest<MetricRecommendationEntity>(entityName: "MetricRecommendation")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var priority: String?
    @NSManaged public var category: String?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var expectedImpactData: Data?
    @NSManaged public var timeToImpact: TimeInterval
    @NSManaged public var impactConfidence: Double
    @NSManaged public var requiredActionsData: Data?
    @NSManaged public var relatedMetricsData: Data?
    @NSManaged public var summary: MetricsSummaryEntity?
}

extension MetricRecommendationEntity : Identifiable {
}