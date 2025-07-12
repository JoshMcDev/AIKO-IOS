import Foundation
import CoreData

extension MetricsSummaryEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricsSummaryEntity> {
        return NSFetchRequest<MetricsSummaryEntity>(entityName: "MetricsSummary")
    }
    
    @NSManaged public var periodStart: Date?
    @NSManaged public var periodEnd: Date?
    @NSManaged public var mopScoresData: Data?
    @NSManaged public var moeScoresData: Data?
    @NSManaged public var overallMOPScore: Double
    @NSManaged public var overallMOEScore: Double
    @NSManaged public var combinedScore: Double
    @NSManaged public var insights: NSSet?
    @NSManaged public var recommendations: NSSet?
    @NSManaged public var report: MetricsReportEntity?
}

// MARK: Generated accessors for insights
extension MetricsSummaryEntity {
    
    @objc(addInsightsObject:)
    @NSManaged public func addToInsights(_ value: MetricInsightEntity)
    
    @objc(removeInsightsObject:)
    @NSManaged public func removeFromInsights(_ value: MetricInsightEntity)
    
    @objc(addInsights:)
    @NSManaged public func addToInsights(_ values: NSSet)
    
    @objc(removeInsights:)
    @NSManaged public func removeFromInsights(_ values: NSSet)
}

// MARK: Generated accessors for recommendations
extension MetricsSummaryEntity {
    
    @objc(addRecommendationsObject:)
    @NSManaged public func addToRecommendations(_ value: MetricRecommendationEntity)
    
    @objc(removeRecommendationsObject:)
    @NSManaged public func removeFromRecommendations(_ value: MetricRecommendationEntity)
    
    @objc(addRecommendations:)
    @NSManaged public func addToRecommendations(_ values: NSSet)
    
    @objc(removeRecommendations:)
    @NSManaged public func removeFromRecommendations(_ values: NSSet)
}

extension MetricsSummaryEntity : Identifiable {
}