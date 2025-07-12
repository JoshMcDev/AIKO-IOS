import CoreData
import Foundation

public extension MetricRecommendationEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MetricRecommendationEntity> {
        NSFetchRequest<MetricRecommendationEntity>(entityName: "MetricRecommendation")
    }

    @NSManaged var id: UUID?
    @NSManaged var priority: String?
    @NSManaged var category: String?
    @NSManaged var title: String?
    @NSManaged var desc: String?
    @NSManaged var expectedImpactData: Data?
    @NSManaged var timeToImpact: TimeInterval
    @NSManaged var impactConfidence: Double
    @NSManaged var requiredActionsData: Data?
    @NSManaged var relatedMetricsData: Data?
    @NSManaged var summary: MetricsSummaryEntity?
}

extension MetricRecommendationEntity: Identifiable {}
