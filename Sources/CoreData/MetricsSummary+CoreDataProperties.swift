import CoreData
import Foundation

public extension MetricsSummaryEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MetricsSummaryEntity> {
        NSFetchRequest<MetricsSummaryEntity>(entityName: "MetricsSummary")
    }

    @NSManaged var periodStart: Date?
    @NSManaged var periodEnd: Date?
    @NSManaged var mopScoresData: Data?
    @NSManaged var moeScoresData: Data?
    @NSManaged var overallMOPScore: Double
    @NSManaged var overallMOEScore: Double
    @NSManaged var combinedScore: Double
    @NSManaged var insights: NSSet?
    @NSManaged var recommendations: NSSet?
    @NSManaged var report: MetricsReportEntity?
}

// MARK: Generated accessors for insights

public extension MetricsSummaryEntity {
    @objc(addInsightsObject:)
    @NSManaged func addToInsights(_ value: MetricInsightEntity)

    @objc(removeInsightsObject:)
    @NSManaged func removeFromInsights(_ value: MetricInsightEntity)

    @objc(addInsights:)
    @NSManaged func addToInsights(_ values: NSSet)

    @objc(removeInsights:)
    @NSManaged func removeFromInsights(_ values: NSSet)
}

// MARK: Generated accessors for recommendations

public extension MetricsSummaryEntity {
    @objc(addRecommendationsObject:)
    @NSManaged func addToRecommendations(_ value: MetricRecommendationEntity)

    @objc(removeRecommendationsObject:)
    @NSManaged func removeFromRecommendations(_ value: MetricRecommendationEntity)

    @objc(addRecommendations:)
    @NSManaged func addToRecommendations(_ values: NSSet)

    @objc(removeRecommendations:)
    @NSManaged func removeFromRecommendations(_ values: NSSet)
}

extension MetricsSummaryEntity: Identifiable {}
