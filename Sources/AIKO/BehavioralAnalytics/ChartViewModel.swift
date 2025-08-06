import Combine
import Foundation
import SwiftUI

/// View model for analytics charts and visualizations
@Observable
@MainActor
public final class ChartViewModel {
    // MARK: - Properties

    public var chartData: [ChartDataPoint] = []
    public var selectedTimeRange: TimeRange = .thirtyDays
    public var selectedMetricType: ChartMetricType = .focusTime
    public var isLoading = false
    public var error: ChartError?

    // MARK: - Private Properties

    private let analyticsRepository: AnalyticsRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(analyticsRepository: AnalyticsRepository) {
        self.analyticsRepository = analyticsRepository
        setupBindings()
    }

    // MARK: - Public Methods

    /// Load chart data for current settings
    public func loadChartData() async {
        isLoading = true
        error = nil

        do {
            let data = try await fetchChartData(
                timeRange: selectedTimeRange,
                metricType: selectedMetricType
            )

            await MainActor.run {
                self.chartData = data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = ChartError.loadFailed(error)
                self.isLoading = false
            }
        }
    }

    /// Update time range and reload data
    public func updateTimeRange(_ timeRange: TimeRange) async {
        selectedTimeRange = timeRange
        await loadChartData()
    }

    /// Update metric type and reload data
    public func updateMetricType(_ metricType: ChartMetricType) async {
        selectedMetricType = metricType
        await loadChartData()
    }

    /// Get chart configuration for current metric type
    public func getChartConfiguration() -> ChartConfiguration {
        ChartConfiguration(
            title: selectedMetricType.displayName,
            yAxisLabel: getYAxisLabel(),
            color: getChartColor(),
            showTrendLine: shouldShowTrendLine(),
            chartType: getChartType()
        )
    }

    /// Calculate trend for current data
    public func calculateTrend() -> TrendAnalysis {
        guard chartData.count >= 2 else {
            return TrendAnalysis(direction: .neutral, changePercentage: 0, confidence: 0)
        }

        let sortedData = chartData.sorted { $0.date < $1.date }
        let firstValue = sortedData.first?.value ?? 0
        let lastValue = sortedData.last?.value ?? 0

        let changePercentage = firstValue != 0 ? ((lastValue - firstValue) / firstValue) * 100 : 0
        let direction: TrendDirection = changePercentage > 5 ? .up : (changePercentage < -5 ? .down : .neutral)

        return TrendAnalysis(
            direction: direction,
            changePercentage: changePercentage,
            confidence: calculateTrendConfidence(sortedData)
        )
    }

    /// Get summary statistics for current data
    public func getSummaryStatistics() -> ChartSummaryStatistics {
        guard !chartData.isEmpty else {
            return ChartSummaryStatistics(
                min: 0, max: 0, average: 0, total: 0, count: 0
            )
        }

        let values = chartData.map(\.value)
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        let total = values.reduce(0, +)
        let average = total / Double(values.count)

        return ChartSummaryStatistics(
            min: min,
            max: max,
            average: average,
            total: total,
            count: values.count
        )
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // With @Observable, we rely on explicit refresh calls rather than binding
        // The repository will notify when data changes through other mechanisms
    }

    private func fetchChartData(timeRange: TimeRange, metricType: ChartMetricType) async throws -> [ChartDataPoint] {
        // Generate mock data based on time range and metric type
        let calendar = Calendar.current
        let endDate = Date()

        var dataPoints: [ChartDataPoint] = []

        for dayOffset in 0 ..< timeRange.days {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) ?? endDate
            let value = generateMockValue(for: metricType, date: date)

            dataPoints.append(ChartDataPoint(
                date: date,
                value: value,
                category: metricType.rawValue
            ))
        }

        return dataPoints.sorted { $0.date < $1.date }
    }

    private func generateMockValue(for metricType: ChartMetricType, date: Date) -> Double {
        let baseValue: Double
        let variance: Double

        switch metricType {
        case .focusTime:
            baseValue = 240 // 4 hours in minutes
            variance = 60
        case .completionRate:
            baseValue = 0.75
            variance = 0.15
        case .learningProgress:
            baseValue = 0.65
            variance = 0.10
        case .workflowEfficiency:
            baseValue = 0.80
            variance = 0.12
        }

        // Add some randomness and weekly pattern
        let randomOffset = Double.random(in: -variance ... variance)
        let weeklyPattern = sin(date.timeIntervalSince1970 / (7 * 24 * 3600)) * (variance * 0.3)

        return max(0, baseValue + randomOffset + weeklyPattern)
    }

    private func getYAxisLabel() -> String {
        switch selectedMetricType {
        case .focusTime:
            "Minutes"
        case .completionRate, .learningProgress, .workflowEfficiency:
            "Percentage"
        }
    }

    private func getChartColor() -> Color {
        switch selectedMetricType {
        case .focusTime:
            .blue
        case .completionRate:
            .green
        case .learningProgress:
            .orange
        case .workflowEfficiency:
            .purple
        }
    }

    private func shouldShowTrendLine() -> Bool {
        chartData.count >= 3
    }

    private func getChartType() -> ChartType {
        switch selectedMetricType {
        case .focusTime:
            .line
        case .completionRate, .learningProgress:
            .bar
        case .workflowEfficiency:
            .area
        }
    }

    private func calculateTrendConfidence(_ data: [ChartDataPoint]) -> Double {
        guard data.count >= 3 else { return 0 }

        // Simple R-squared calculation for trend confidence
        let values = data.map(\.value)
        let n = Double(values.count)
        let sumX = (0 ..< values.count).reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(0 ..< values.count, values).map { Double($0) * $1 }.reduce(0, +)
        let sumX2 = (0 ..< values.count).map { $0 * $0 }.reduce(0, +)
        let sumY2 = values.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - Double(sumX) * sumY
        let denominator = sqrt((n * Double(sumX2) - Double(sumX * sumX)) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else { return 0 }

        let r = numerator / denominator
        return abs(r) // Return absolute correlation as confidence
    }
}

// MARK: - Supporting Types

/// Chart configuration
public struct ChartConfiguration: Equatable {
    public let title: String
    public let yAxisLabel: String
    public let color: Color
    public let showTrendLine: Bool
    public let chartType: ChartType

    public init(title: String, yAxisLabel: String, color: Color, showTrendLine: Bool, chartType: ChartType) {
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.color = color
        self.showTrendLine = showTrendLine
        self.chartType = chartType
    }
}

/// Chart type enumeration
public enum ChartType: String, CaseIterable {
    case line
    case bar
    case area
    case scatter
}

/// Trend analysis
public struct TrendAnalysis: Equatable {
    public let direction: TrendDirection
    public let changePercentage: Double
    public let confidence: Double

    public init(direction: TrendDirection, changePercentage: Double, confidence: Double) {
        self.direction = direction
        self.changePercentage = changePercentage
        self.confidence = confidence
    }
}

/// Chart summary statistics
public struct ChartSummaryStatistics: Equatable {
    public let min: Double
    public let max: Double
    public let average: Double
    public let total: Double
    public let count: Int

    public init(min: Double, max: Double, average: Double, total: Double, count: Int) {
        self.min = min
        self.max = max
        self.average = average
        self.total = total
        self.count = count
    }
}

/// Chart errors
public enum ChartError: Error, Equatable {
    case loadFailed(Error)
    case noDataAvailable
    case invalidTimeRange
    case invalidMetricType

    public static func == (lhs: ChartError, rhs: ChartError) -> Bool {
        switch (lhs, rhs) {
        case (.noDataAvailable, .noDataAvailable),
             (.invalidTimeRange, .invalidTimeRange),
             (.invalidMetricType, .invalidMetricType):
            true
        case (.loadFailed, .loadFailed):
            true
        default:
            false
        }
    }
}

extension ChartError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .loadFailed:
            "Failed to load chart data"
        case .noDataAvailable:
            "No chart data available"
        case .invalidTimeRange:
            "Invalid time range selected"
        case .invalidMetricType:
            "Invalid metric type selected"
        }
    }
}
