import CoreData
import Foundation

@objc(MetricRecommendationEntity)
public class MetricRecommendationEntity: NSManagedObject {
    // MARK: - Core Data to Model Conversion

    public func toModel() -> MetricRecommendation? {
        guard let id,
              let priorityString = priority,
              let priority = MetricRecommendation.RecommendationPriority(rawValue: Int(priorityString) ?? 0),
              let categoryString = category,
              let category = MetricRecommendation.RecommendationCategory(rawValue: categoryString),
              let title,
              let desc
        else {
            return nil
        }

        // Decode arrays
        let requiredActions = (requiredActionsData
                                .flatMap { try? JSONDecoder().decode([String].self, from: $0) }) ?? []
        let relatedMetrics = (relatedMetricsData
                                .flatMap { try? JSONDecoder().decode([String].self, from: $0) }) ?? []

        // Decode expected impact
        var metricImprovements: [String: Double] = [:]
        if let impactData = expectedImpactData,
           let impactDict = try? JSONDecoder().decodeDictionary(from: impactData) {
            metricImprovements = (impactDict["metricImprovements"] as? [String: Double]) ?? [:]
        }

        let expectedImpact = MetricRecommendation.ExpectedImpact(
            metricImprovements: metricImprovements,
            timeToImpact: timeToImpact,
            confidence: impactConfidence
        )

        return MetricRecommendation(
            id: id,
            priority: priority,
            category: category,
            title: title,
            description: desc,
            expectedImpact: expectedImpact,
            requiredActions: requiredActions,
            relatedMetrics: relatedMetrics
        )
    }

    // MARK: - Model to Core Data Conversion

    public static func fromModel(_ model: MetricRecommendation, context: NSManagedObjectContext) -> MetricRecommendationEntity {
        let entity = MetricRecommendationEntity(context: context)
        entity.id = model.id
        entity.priority = String(model.priority.rawValue)
        entity.category = model.category.rawValue
        entity.title = model.title
        entity.desc = model.description
        entity.timeToImpact = model.expectedImpact.timeToImpact
        entity.impactConfidence = model.expectedImpact.confidence

        // Encode arrays
        if let actionsData = try? JSONEncoder().encode(model.requiredActions) {
            entity.requiredActionsData = actionsData
        }
        if let metricsData = try? JSONEncoder().encode(model.relatedMetrics) {
            entity.relatedMetricsData = metricsData
        }

        // Encode expected impact
        let impactDict: [String: Any] = [
            "metricImprovements": model.expectedImpact.metricImprovements,
        ]
        if let impactData = try? JSONSerialization.data(withJSONObject: impactDict) {
            entity.expectedImpactData = impactData
        }

        return entity
    }
}

// MARK: - JSON Helper Extension

extension JSONDecoder {
    func decodeDictionary(from data: Data) throws -> [String: Any]? {
        try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}
