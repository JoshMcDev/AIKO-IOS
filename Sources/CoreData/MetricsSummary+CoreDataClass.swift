import CoreData
import Foundation

@objc(MetricsSummaryEntity)
public class MetricsSummaryEntity: NSManagedObject {
    // MARK: - Core Data to Model Conversion

    public func toModel() -> MetricsSummary? {
        guard let periodStart,
              let periodEnd
        else {
            return nil
        }

        let period = DateInterval(start: periodStart, end: periodEnd)

        // Decode MOP scores
        let mopScores: [MeasureOfPerformance: Double] =
            (mopScoresData.flatMap { try? JSONDecoder().decode([String: Double].self, from: $0) } ?? [:])
            .compactMapKeys { MeasureOfPerformance(rawValue: $0) }

        // Decode MOE scores
        let moeScores: [MeasureOfEffectiveness: Double] =
            (moeScoresData.flatMap { try? JSONDecoder().decode([String: Double].self, from: $0) } ?? [:])
            .compactMapKeys { MeasureOfEffectiveness(rawValue: $0) }

        // Convert insights
        let insights = (insights?.allObjects as? [MetricInsightEntity] ?? [])
            .compactMap { $0.toModel() }

        // Convert recommendations
        let recommendations = (recommendations?.allObjects as? [MetricRecommendationEntity] ?? [])
            .compactMap { $0.toModel() }

        return MetricsSummary(
            period: period,
            mopScores: mopScores,
            moeScores: moeScores,
            insights: insights,
            recommendations: recommendations
        )
    }

    // MARK: - Model to Core Data Conversion

    public static func fromModel(_ model: MetricsSummary, context: NSManagedObjectContext) -> MetricsSummaryEntity {
        let entity = MetricsSummaryEntity(context: context)
        entity.periodStart = model.period.start
        entity.periodEnd = model.period.end
        entity.overallMOPScore = model.overallMOPScore
        entity.overallMOEScore = model.overallMOEScore
        entity.combinedScore = model.combinedScore

        // Encode MOP scores
        let mopScoresDict = Dictionary(uniqueKeysWithValues: model.mopScores.map { ($0.key.rawValue, $0.value) })
        if let mopData = try? JSONEncoder().encode(mopScoresDict) {
            entity.mopScoresData = mopData
        }

        // Encode MOE scores
        let moeScoresDict = Dictionary(uniqueKeysWithValues: model.moeScores.map { ($0.key.rawValue, $0.value) })
        if let moeData = try? JSONEncoder().encode(moeScoresDict) {
            entity.moeScoresData = moeData
        }

        // Convert insights
        let insightEntities = model.insights.map { insight in
            MetricInsightEntity.fromModel(insight, context: context)
        }
        entity.insights = NSSet(array: insightEntities)

        // Convert recommendations
        let recommendationEntities = model.recommendations.map { recommendation in
            MetricRecommendationEntity.fromModel(recommendation, context: context)
        }
        entity.recommendations = NSSet(array: recommendationEntities)

        return entity
    }
}

// MARK: - Helper Extension

extension Dictionary {
    func compactMapKeys<T>(_ transform: (Key) -> T?) -> [T: Value] {
        var result = [T: Value]()
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}
