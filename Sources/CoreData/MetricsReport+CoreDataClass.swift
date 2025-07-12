import Foundation
import CoreData

@objc(MetricsReportEntity)
public class MetricsReportEntity: NSManagedObject {
    
    // MARK: - Core Data to Model Conversion
    public func toModel() -> MetricsReport? {
        guard let id = id,
              let title = title,
              let startDate = periodStart,
              let endDate = periodEnd,
              let generatedAt = generatedAt,
              let executiveSummary = executiveSummary,
              let summary = summary?.toModel() else {
            return nil
        }
        
        let period = DateInterval(start: startDate, end: endDate)
        
        let measurements = (detailedMeasurements?.allObjects as? [MetricMeasurementEntity] ?? [])
            .compactMap { $0.toModel() }
            .sorted { $0.timestamp < $1.timestamp }
        
        let trends = (trends?.allObjects as? [MetricTrendEntity] ?? [])
            .compactMap { $0.toModel() }
        
        let comparisons = (comparisons?.allObjects as? [MetricComparisonEntity] ?? [])
            .compactMap { $0.toModel() }
        
        return MetricsReport(
            id: id,
            title: title,
            period: period,
            generatedAt: generatedAt,
            summary: summary,
            detailedMeasurements: measurements,
            trends: trends,
            comparisons: comparisons,
            executiveSummary: executiveSummary
        )
    }
    
    // MARK: - Model to Core Data Conversion
    public static func fromModel(_ model: MetricsReport, context: NSManagedObjectContext) -> MetricsReportEntity {
        let entity = MetricsReportEntity(context: context)
        entity.id = model.id
        entity.title = model.title
        entity.periodStart = model.period.start
        entity.periodEnd = model.period.end
        entity.generatedAt = model.generatedAt
        entity.executiveSummary = model.executiveSummary
        
        // Convert summary
        entity.summary = MetricsSummaryEntity.fromModel(model.summary, context: context)
        
        // Convert measurements
        let measurementEntities = model.detailedMeasurements.map { measurement in
            MetricMeasurementEntity.fromModel(measurement, context: context)
        }
        entity.detailedMeasurements = NSSet(array: measurementEntities)
        
        // Convert trends
        let trendEntities = model.trends.map { trend in
            MetricTrendEntity.fromModel(trend, context: context)
        }
        entity.trends = NSSet(array: trendEntities)
        
        // Convert comparisons
        let comparisonEntities = model.comparisons.map { comparison in
            MetricComparisonEntity.fromModel(comparison, context: context)
        }
        entity.comparisons = NSSet(array: comparisonEntities)
        
        return entity
    }
}