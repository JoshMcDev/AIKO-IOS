import Foundation
import CoreData

@objc(MetricComparisonEntity)
public class MetricComparisonEntity: NSManagedObject {
    
    // MARK: - Core Data to Model Conversion
    public func toModel() -> MetricComparison? {
        guard let id = id,
              let typeString = type,
              let type = MetricComparison.ComparisonType(rawValue: typeString),
              let baseline = baseline?.toModel(),
              let comparison = comparison?.toModel(),
              let interpretation = interpretation else {
            return nil
        }
        
        return MetricComparison(
            id: id,
            type: type,
            baseline: baseline,
            comparison: comparison,
            interpretation: interpretation
        )
    }
    
    // MARK: - Model to Core Data Conversion
    public static func fromModel(_ model: MetricComparison, context: NSManagedObjectContext) -> MetricComparisonEntity {
        let entity = MetricComparisonEntity(context: context)
        entity.id = model.id
        entity.type = model.type.rawValue
        entity.difference = model.difference
        entity.percentageChange = model.percentageChange
        entity.interpretation = model.interpretation
        
        // Create new measurement entities for baseline and comparison
        entity.baseline = MetricMeasurementEntity.fromModel(model.baseline, context: context)
        entity.comparison = MetricMeasurementEntity.fromModel(model.comparison, context: context)
        
        return entity
    }
}