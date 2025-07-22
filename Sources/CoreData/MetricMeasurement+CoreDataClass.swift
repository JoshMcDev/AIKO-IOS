import CoreData
import Foundation

@objc(MetricMeasurementEntity)
public class MetricMeasurementEntity: NSManagedObject {
    // MARK: - Core Data to Model Conversion

    public func toModel() -> MetricMeasurement? {
        guard let id,
              let name,
              metricType != nil,
              let contextData,
              let context = try? JSONDecoder().decode(MetricContext.self, from: contextData)
        else {
            return nil
        }

        // Decode metric type
        let type: MetricMeasurement.MetricType
        if let mopString = mopType,
           let mop = MeasureOfPerformance(rawValue: mopString) {
            type = .mop(mop)
        } else if let moeString = moeType,
                  let moe = MeasureOfEffectiveness(rawValue: moeString) {
            type = .moe(moe)
        } else {
            return nil
        }

        // Convert values
        let values: [MetricValue] = (metricValues?.allObjects as? [MetricValueEntity] ?? [])
            .compactMap { $0.toModel() }
            .sorted { $0.timestamp < $1.timestamp }

        return MetricMeasurement(
            id: id,
            name: name,
            type: type,
            timestamp: timestamp ?? Date(),
            values: values,
            aggregatedValue: aggregatedValue,
            score: score,
            context: context
        )
    }

    // MARK: - Model to Core Data Conversion

    public static func fromModel(_ model: MetricMeasurement, context: NSManagedObjectContext) -> MetricMeasurementEntity {
        let entity = MetricMeasurementEntity(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.timestamp = model.timestamp
        entity.aggregatedValue = model.aggregatedValue
        entity.score = model.score

        // Store metric type
        switch model.type {
        case let .mop(mop):
            entity.metricType = "mop"
            entity.mopType = mop.rawValue
        case let .moe(moe):
            entity.metricType = "moe"
            entity.moeType = moe.rawValue
        }

        // Store context
        if let contextData = try? JSONEncoder().encode(model.context) {
            entity.contextData = contextData
        }

        // Convert values
        let valueEntities = model.values.map { value in
            MetricValueEntity.fromModel(value, context: context)
        }
        entity.metricValues = NSSet(array: valueEntities)

        return entity
    }
}
