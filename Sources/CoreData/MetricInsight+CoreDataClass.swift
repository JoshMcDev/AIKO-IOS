import CoreData
import Foundation

@objc(MetricInsightEntity)
public class MetricInsightEntity: NSManagedObject {
    // MARK: - Core Data to Model Conversion

    public func toModel() -> MetricInsight? {
        guard let id,
              let typeString = type,
              let type = MetricInsight.InsightType(rawValue: typeString),
              let severityString = severity,
              let severity = MetricInsight.InsightSeverity(rawValue: severityString),
              let message,
              let timestamp
        else {
            return nil
        }

        let affectedMetrics = (affectedMetricsData
            .flatMap { try? JSONDecoder().decode([String].self, from: $0) }) ?? []

        return MetricInsight(
            id: id,
            type: type,
            severity: severity,
            message: message,
            affectedMetrics: affectedMetrics,
            confidence: confidence,
            timestamp: timestamp
        )
    }

    // MARK: - Model to Core Data Conversion

    public static func fromModel(_ model: MetricInsight, context: NSManagedObjectContext) -> MetricInsightEntity {
        let entity = MetricInsightEntity(context: context)
        entity.id = model.id
        entity.type = model.type.rawValue
        entity.severity = model.severity.rawValue
        entity.message = model.message
        entity.confidence = model.confidence
        entity.timestamp = model.timestamp

        if !model.affectedMetrics.isEmpty,
           let metricsData = try? JSONEncoder().encode(model.affectedMetrics) {
            entity.affectedMetricsData = metricsData
        }

        return entity
    }
}
