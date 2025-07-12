import CoreData
import Foundation

@objc(MetricValueEntity)
public class MetricValueEntity: NSManagedObject {
    // MARK: - Core Data to Model Conversion

    public func toModel() -> MetricValue? {
        guard let id,
              let timestamp,
              let unitString = unit,
              let unit = MetricUnit(rawValue: unitString)
        else {
            return nil
        }

        var metadata: [String: String] = [:]
        if let metadataData {
            metadata = (try? JSONDecoder().decode([String: String].self, from: metadataData)) ?? [:]
        }

        return MetricValue(
            id: id,
            timestamp: timestamp,
            value: value,
            unit: unit,
            metadata: metadata
        )
    }

    // MARK: - Model to Core Data Conversion

    public static func fromModel(_ model: MetricValue, context: NSManagedObjectContext) -> MetricValueEntity {
        let entity = MetricValueEntity(context: context)
        entity.id = model.id
        entity.timestamp = model.timestamp
        entity.value = model.value
        entity.unit = model.unit.rawValue

        if !model.metadata.isEmpty,
           let metadataData = try? JSONEncoder().encode(model.metadata)
        {
            entity.metadataData = metadataData
        }

        return entity
    }
}
