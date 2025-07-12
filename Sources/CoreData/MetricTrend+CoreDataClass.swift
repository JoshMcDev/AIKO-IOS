import CoreData
import Foundation

@objc(MetricTrendEntity)
public class MetricTrendEntity: NSManagedObject {
    // MARK: - Core Data to Model Conversion

    public func toModel() -> MetricTrend? {
        guard let id,
              let metricName,
              let directionString = direction,
              let direction = MetricTrend.TrendDirection(rawValue: directionString)
        else {
            return nil
        }

        // Convert data points
        let dataPoints = (trendDataPoints?.allObjects as? [TrendDataPointEntity] ?? [])
            .compactMap { entity -> MetricTrend.TrendDataPoint? in
                guard let timestamp = entity.timestamp else { return nil }
                return MetricTrend.TrendDataPoint(
                    timestamp: timestamp,
                    value: entity.value
                )
            }
            .sorted { $0.timestamp < $1.timestamp }

        return MetricTrend(
            id: id,
            metricName: metricName,
            direction: direction,
            magnitude: magnitude,
            significance: significance,
            dataPoints: dataPoints
        )
    }

    // MARK: - Model to Core Data Conversion

    public static func fromModel(_ model: MetricTrend, context: NSManagedObjectContext) -> MetricTrendEntity {
        let entity = MetricTrendEntity(context: context)
        entity.id = model.id
        entity.metricName = model.metricName
        entity.direction = model.direction.rawValue
        entity.magnitude = model.magnitude
        entity.significance = model.significance

        // Convert data points
        let dataPointEntities = model.dataPoints.map { dataPoint in
            let dpEntity = TrendDataPointEntity(context: context)
            dpEntity.timestamp = dataPoint.timestamp
            dpEntity.value = dataPoint.value
            dpEntity.trend = entity
            return dpEntity
        }
        entity.trendDataPoints = NSSet(array: dataPointEntities)

        return entity
    }
}
