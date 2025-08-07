import XCTest
import SwiftUI
import Charts
import Combine
@testable import AIKO

/// Comprehensive tests for Chart ViewModels - Chart data preparation and filtering
/// RED PHASE: All tests should FAIL initially as chart components don't exist yet
@MainActor
final class ChartViewModelTests: XCTestCase {

    // MARK: - Properties

    var chartViewModel: ChartViewModel?
    var mockDataProvider: MockChartDataProvider?
    var cancellables: Set<AnyCancellable> = []

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        let mockProvider = MockChartDataProvider()
        mockDataProvider = mockProvider

        // RED: Will fail as ChartViewModel doesn't exist
        chartViewModel = ChartViewModel(dataProvider: mockProvider)
    }

    // MARK: - Helper Methods

    private func getChartViewModel() throws -> ChartViewModel {
        guard let viewModel = chartViewModel else {
            throw XCTestError(.failureWhileWaiting, userInfo: [NSLocalizedDescriptionKey: "ChartViewModel not initialized"])
        }
        return viewModel
    }

    private func getMockDataProvider() throws -> MockChartDataProvider {
        guard let provider = mockDataProvider else {
            throw XCTestError(.failureWhileWaiting, userInfo: [NSLocalizedDescriptionKey: "MockDataProvider not initialized"])
        }
        return provider
    }

    override func tearDown() async throws {
        cancellables.removeAll()
        chartViewModel = nil
        mockDataProvider = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_ChartViewModel_initialization() throws {
        // RED: Will fail as ChartViewModel doesn't exist
        let viewModel = try getChartViewModel()
        XCTAssertEqual(viewModel.selectedTimeRange, .thirtyDays)
        XCTAssertEqual(viewModel.selectedMetricType, .learningEffectiveness)
        XCTAssertTrue(viewModel.chartData.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_chartViewModel_initialState() {
        // RED: Will fail as chart state management doesn't exist
        XCTAssertNil(chartViewModel.error)
        XCTAssertFalse(chartViewModel.hasData)
        XCTAssertTrue(chartViewModel.isInEmptyState)
    }

    // MARK: - Data Loading Tests

    func test_loadChartData_updatesChartData() async {
        // RED: Will fail as loadChartData method doesn't exist
        mockDataProvider.mockData = createMockTimeSeriesData()

        await chartViewModel.loadChartData()

        XCTAssertFalse(chartViewModel.chartData.isEmpty)
        XCTAssertEqual(chartViewModel.chartData.count, mockDataProvider.mockData.count)
        XCTAssertFalse(chartViewModel.isLoading)
    }

    func test_loadChartData_setsLoadingState() async {
        // RED: Will fail as loading state management doesn't exist
        mockDataProvider.delayResponse = true

        let loadingExpectation = expectation(description: "Loading state set")

        chartViewModel.$isLoading
            .sink { isLoading in
                if isLoading {
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        Task {
            await chartViewModel.loadChartData()
        }

        await fulfillment(of: [loadingExpectation], timeout: 1.0)
    }

    func test_loadChartData_handlesErrors() async {
        // RED: Will fail as error handling doesn't exist
        mockDataProvider.shouldThrowError = true

        await chartViewModel.loadChartData()

        XCTAssertNotNil(chartViewModel.error)
        XCTAssertFalse(chartViewModel.isLoading)
        XCTAssertTrue(chartViewModel.chartData.isEmpty)
    }

    // MARK: - Time Range Filtering Tests

    func test_timeRangeChange_filtersDataCorrectly() async {
        // RED: Will fail as time range filtering doesn't exist
        mockDataProvider.mockData = createMockTimeSeriesData(days: 90)
        await chartViewModel.loadChartData()

        chartViewModel.selectedTimeRange = .sevenDays
        await chartViewModel.applyFilters()

        // Should only contain data from last 7 days
        guard let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            XCTFail("Failed to create date for 7 days ago")
            return
        }
        let filteredData = chartViewModel.chartData.filter { $0.date >= sevenDaysAgo }
        XCTAssertEqual(chartViewModel.chartData.count, filteredData.count)
    }

    func test_timeRangeChange_updatesAxisConfiguration() async {
        // RED: Will fail as axis configuration doesn't exist
        chartViewModel.selectedTimeRange = .sevenDays
        await chartViewModel.applyFilters()

        XCTAssertEqual(chartViewModel.axisConfiguration.stride, .day)

        chartViewModel.selectedTimeRange = .oneYear
        await chartViewModel.applyFilters()

        XCTAssertEqual(chartViewModel.axisConfiguration.stride, .month)
    }

    func test_timeRangeEdgeCases_handledCorrectly() async {
        // RED: Will fail as edge case handling doesn't exist
        // Test with no data
        mockDataProvider.mockData = []
        chartViewModel.selectedTimeRange = .sevenDays
        await chartViewModel.applyFilters()

        XCTAssertTrue(chartViewModel.chartData.isEmpty)
        XCTAssertTrue(chartViewModel.isInEmptyState)

        // Test with data older than selected range
        mockDataProvider.mockData = createMockTimeSeriesData(startDaysAgo: 100, days: 30)
        chartViewModel.selectedTimeRange = .sevenDays
        await chartViewModel.applyFilters()

        XCTAssertTrue(chartViewModel.chartData.isEmpty)
        XCTAssertTrue(chartViewModel.isInEmptyState)
    }

    // MARK: - Metric Type Filtering Tests

    func test_metricTypeChange_filtersDataCorrectly() async {
        // RED: Will fail as metric type filtering doesn't exist
        mockDataProvider.mockData = createMixedMetricTypeData()
        await chartViewModel.loadChartData()

        chartViewModel.selectedMetricType = .timeSaved
        await chartViewModel.applyFilters()

        let timeSavedData = chartViewModel.chartData.filter { $0.category.contains("Time Saved") }
        XCTAssertEqual(chartViewModel.chartData.count, timeSavedData.count)
    }

    func test_metricTypeChange_updatesChartConfiguration() async {
        // RED: Will fail as chart configuration doesn't exist
        chartViewModel.selectedMetricType = .learningEffectiveness
        await chartViewModel.applyFilters()

        XCTAssertEqual(chartViewModel.chartConfiguration.yAxisLabel, "Learning Effectiveness")
        XCTAssertEqual(chartViewModel.chartConfiguration.valueFormat, .percentage)

        chartViewModel.selectedMetricType = .timeSaved
        await chartViewModel.applyFilters()

        XCTAssertEqual(chartViewModel.chartConfiguration.yAxisLabel, "Time Saved")
        XCTAssertEqual(chartViewModel.chartConfiguration.valueFormat, .duration)
    }

    func test_allMetricTypes_supportedCorrectly() async {
        // RED: Will fail as metric type support doesn't exist
        let allTypes: [MetricType] = [
            .learningEffectiveness,
            .timeSaved,
            .patternInsights,
            .personalization
        ]

        for metricType in allTypes {
            mockDataProvider.mockData = createMockDataForMetricType(metricType)
            chartViewModel.selectedMetricType = metricType
            await chartViewModel.applyFilters()

            XCTAssertFalse(chartViewModel.chartData.isEmpty,
                           "Should have data for metric type: \(metricType)")
            XCTAssertNotNil(chartViewModel.chartConfiguration.yAxisLabel,
                            "Should have y-axis label for metric type: \(metricType)")
        }
    }

    // MARK: - Data Aggregation Tests

    func test_dataAggregation_combinesDataPointsCorrectly() async {
        // RED: Will fail as data aggregation doesn't exist
        let rawData = createMockRawAnalyticsData()
        mockDataProvider.mockRawData = rawData

        chartViewModel.aggregationLevel = .daily
        await chartViewModel.loadChartData()

        // Should aggregate multiple data points per day into single points
        let uniqueDays = Set(chartViewModel.chartData.map {
            Calendar.current.startOfDay(for: $0.date)
        })
        XCTAssertEqual(chartViewModel.chartData.count, uniqueDays.count)
    }

    func test_aggregationLevel_changesDataGranularity() async {
        // RED: Will fail as aggregation level changes don't exist
        mockDataProvider.mockRawData = createMockRawAnalyticsData(dataPointsPerDay: 24) // Hourly data

        chartViewModel.aggregationLevel = .hourly
        await chartViewModel.loadChartData()
        let hourlyCount = chartViewModel.chartData.count

        chartViewModel.aggregationLevel = .daily
        await chartViewModel.applyFilters()
        let dailyCount = chartViewModel.chartData.count

        XCTAssertGreaterThan(hourlyCount, dailyCount)
    }

    func test_aggregation_calculatesStatisticsCorrectly() async {
        // RED: Will fail as statistics calculation doesn't exist
        let testData = [
            MockRawDataPoint(date: Date(), value: 0.8),
            MockRawDataPoint(date: Date(), value: 0.6),
            MockRawDataPoint(date: Date(), value: 0.9)
        ]

        let aggregated = await chartViewModel.aggregateDataPoints(testData, method: .average)
        XCTAssertEqual(aggregated.value, 0.77, accuracy: 0.01)

        let maxAggregated = await chartViewModel.aggregateDataPoints(testData, method: .maximum)
        XCTAssertEqual(maxAggregated.value, 0.9)

        let minAggregated = await chartViewModel.aggregateDataPoints(testData, method: .minimum)
        XCTAssertEqual(minAggregated.value, 0.6)
    }

    // MARK: - Performance Tests

    func test_chartRendering_performsWithinTimeLimit() async {
        // RED: Will fail as performance optimization doesn't exist
        let startTime = CFAbsoluteTimeGetCurrent()

        // Load large dataset (1000+ points)
        mockDataProvider.mockData = createLargeTimeSeriesDataset()
        await chartViewModel.loadChartData()

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(processingTime, 0.1, "Chart data processing should complete within 100ms")
    }

    func test_filterApplication_performsEfficiently() async {
        // RED: Will fail as efficient filtering doesn't exist
        mockDataProvider.mockData = createLargeTimeSeriesDataset()
        await chartViewModel.loadChartData()

        let startTime = CFAbsoluteTimeGetCurrent()

        chartViewModel.selectedTimeRange = .sevenDays
        chartViewModel.selectedMetricType = .learningEffectiveness
        await chartViewModel.applyFilters()

        let filterTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(filterTime, 0.05, "Filter application should complete within 50ms")
    }

    func test_memoryUsage_staysWithinLimits() async {
        // RED: Will fail as memory management doesn't exist
        let beforeMemory = getMemoryUsage()

        // Process very large dataset
        mockDataProvider.mockData = createMassiveTimeSeriesDataset(pointCount: 10000)
        await chartViewModel.loadChartData()

        let afterMemory = getMemoryUsage()
        let memoryIncrease = afterMemory - beforeMemory

        // Should stay under 25MB increase for chart data
        XCTAssertLessThan(memoryIncrease, 25 * 1024 * 1024, "Memory usage should stay within 25MB")
    }

    // MARK: - Chart Configuration Tests

    func test_chartConfiguration_adaptsToDataRange() async {
        // RED: Will fail as adaptive configuration doesn't exist
        // Test with percentage data (0-1 range)
        mockDataProvider.mockData = createMockDataWithRange(min: 0.0, max: 1.0)
        await chartViewModel.loadChartData()

        XCTAssertEqual(chartViewModel.chartConfiguration.yAxisMin, 0.0)
        XCTAssertEqual(chartViewModel.chartConfiguration.yAxisMax, 1.0)
        XCTAssertEqual(chartViewModel.chartConfiguration.valueFormat, .percentage)

        // Test with large time values (seconds)
        mockDataProvider.mockData = createMockDataWithRange(min: 0, max: 7200) // 2 hours
        await chartViewModel.loadChartData()

        XCTAssertEqual(chartViewModel.chartConfiguration.valueFormat, .duration)
    }

    func test_colorScheme_adaptsToDataCategories() async {
        // RED: Will fail as color scheme adaptation doesn't exist
        mockDataProvider.mockData = createMockDataWithCategories([
            "Learning Effectiveness",
            "Time Saved",
            "Pattern Recognition"
        ])
        await chartViewModel.loadChartData()

        let colorMap = chartViewModel.chartConfiguration.categoryColors
        XCTAssertEqual(colorMap.count, 3)
        XCTAssertNotNil(colorMap["Learning Effectiveness"])
        XCTAssertNotNil(colorMap["Time Saved"])
        XCTAssertNotNil(colorMap["Pattern Recognition"])
    }

    // MARK: - Accessibility Tests

    func test_chartAccessibility_providesAudioDescription() async {
        // RED: Will fail as accessibility support doesn't exist
        mockDataProvider.mockData = createMockTrendData()
        await chartViewModel.loadChartData()

        let audioDescription = chartViewModel.generateAudioDescription()

        XCTAssertTrue(audioDescription.contains("Learning effectiveness"))
        XCTAssertTrue(audioDescription.contains("trending upward") ||
                        audioDescription.contains("trending downward") ||
                        audioDescription.contains("stable"))
    }

    func test_chartAccessibility_providesDataSummary() async {
        // RED: Will fail as data summary doesn't exist
        mockDataProvider.mockData = createMockTimeSeriesData()
        await chartViewModel.loadChartData()

        let summary = chartViewModel.generateDataSummary()

        XCTAssertTrue(summary.contains("data points"))
        XCTAssertTrue(summary.contains("average"))
        XCTAssertTrue(summary.contains("range"))
    }

    // MARK: - Real-time Update Tests

    func test_realtimeUpdates_refreshDataPeriodically() async {
        // RED: Will fail as real-time updates don't exist
        chartViewModel.enableRealtimeUpdates(interval: 0.1) // 100ms for testing

        let updateExpectation = expectation(description: "Real-time update received")

        chartViewModel.$chartData
            .dropFirst() // Skip initial empty value
            .sink { data in
                if !data.isEmpty {
                    updateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Simulate data provider having new data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.mockDataProvider.mockData = self.createMockTimeSeriesData()
        }

        await fulfillment(of: [updateExpectation], timeout: 1.0)
    }

    func test_realtimeUpdates_canBeDisabled() async {
        // RED: Will fail as real-time update control doesn't exist
        chartViewModel.enableRealtimeUpdates(interval: 0.1)
        chartViewModel.disableRealtimeUpdates()

        let noUpdateExpectation = expectation(description: "No updates after disable")
        noUpdateExpectation.isInverted = true

        chartViewModel.$chartData
            .dropFirst()
            .sink { _ in
                noUpdateExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate data change that shouldn't trigger update
        mockDataProvider.mockData = createMockTimeSeriesData()

        await fulfillment(of: [noUpdateExpectation], timeout: 0.5)
    }

    // MARK: - Export Tests

    func test_exportChartData_generatesCorrectFormat() async {
        // RED: Will fail as chart data export doesn't exist
        mockDataProvider.mockData = createMockTimeSeriesData()
        await chartViewModel.loadChartData()

        let csvData = await chartViewModel.exportData(format: .csv)
        XCTAssertTrue(csvData.contains("Date,Value,Category"))
        XCTAssertTrue(csvData.components(separatedBy: "\n").count > 1)

        let jsonData = await chartViewModel.exportData(format: .json)
        XCTAssertTrue(jsonData.contains("\"date\""))
        XCTAssertTrue(jsonData.contains("\"value\""))
        XCTAssertTrue(jsonData.contains("\"category\""))
    }

    // MARK: - Mock Helper Methods

    private func createMockTimeSeriesData(days: Int = 30, startDaysAgo: Int = 30) -> [ChartDataPoint] {
        (0..<days).map { day in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-(startDaysAgo - day) * 86400)),
                value: Double.random(in: 0.6...0.9),
                category: "Learning Effectiveness"
            )
        }
    }

    private func createMixedMetricTypeData() -> [ChartDataPoint] {
        var data: [ChartDataPoint] = []

        // Learning effectiveness data
        data.append(contentsOf: (0..<15).map { day in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                value: Double.random(in: 0.6...0.9),
                category: "Learning Effectiveness"
            )
        })

        // Time saved data
        data.append(contentsOf: (0..<15).map { day in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                value: Double.random(in: 1800...7200), // 30 minutes to 2 hours
                category: "Time Saved"
            )
        })

        return data
    }

    private func createMockDataForMetricType(_ type: MetricType) -> [ChartDataPoint] {
        let category = type.displayName
        let valueRange: ClosedRange<Double>

        switch type {
        case .learningEffectiveness, .patternInsights, .personalization:
            valueRange = 0.0...1.0
        case .timeSaved:
            valueRange = 0...7200
        }

        return (0..<15).map { day in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                value: Double.random(in: valueRange),
                category: category
            )
        }
    }

    private func createMockRawAnalyticsData(dataPointsPerDay: Int = 8) -> [MockRawDataPoint] {
        var data: [MockRawDataPoint] = []

        for day in 0..<7 {
            for hour in stride(from: 0, to: 24, by: 24 / dataPointsPerDay) {
                guard let date = Calendar.current.date(byAdding: .day, value: -day, to: Date()),
                      let hourDate = Calendar.current.date(byAdding: .hour, value: hour, to: Calendar.current.startOfDay(for: date)) else {
                    continue
                }

                data.append(MockRawDataPoint(
                    date: hourDate,
                    value: Double.random(in: 0.6...0.9)
                ))
            }
        }

        return data
    }

    private func createLargeTimeSeriesDataset() -> [ChartDataPoint] {
        (0..<1000).map { index in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-index * 3600)), // Hourly data
                value: Double.random(in: 0.6...0.9),
                category: "Learning Effectiveness"
            )
        }
    }

    private func createMassiveTimeSeriesDataset(pointCount: Int) -> [ChartDataPoint] {
        (0..<pointCount).map { index in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-index * 60)), // Minute data
                value: Double.random(in: 0.0...1.0),
                category: "Test Data"
            )
        }
    }

    private func createMockDataWithRange(min: Double, max: Double) -> [ChartDataPoint] {
        (0..<10).map { day in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                value: Double.random(in: min...max),
                category: "Test Data"
            )
        }
    }

    private func createMockDataWithCategories(_ categories: [String]) -> [ChartDataPoint] {
        var data: [ChartDataPoint] = []

        for category in categories {
            data.append(contentsOf: (0..<5).map { day in
                ChartDataPoint(
                    date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                    value: Double.random(in: 0.0...1.0),
                    category: category
                )
            })
        }

        return data
    }

    private func createMockTrendData() -> [ChartDataPoint] {
        (0..<30).map { day in
            let baseValue = 0.6
            let trend = Double(day) * 0.01 // Upward trend
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                value: baseValue + trend + Double.random(in: -0.05...0.05),
                category: "Learning Effectiveness"
            )
        }.reversed()
    }

    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

// MARK: - Mock Types

// RED: These will fail as the real types don't exist yet
struct ChartDataPoint {
    let date: Date
    let value: Double
    let category: String
}

struct MockRawDataPoint {
    let date: Date
    let value: Double
}

enum MetricType: String, CaseIterable {
    case learningEffectiveness = "learning"
    case timeSaved = "time"
    case patternInsights = "patterns"
    case personalization = "personal"

    var displayName: String {
        switch self {
        case .learningEffectiveness: return "Learning Effectiveness"
        case .timeSaved: return "Time Saved"
        case .patternInsights: return "Pattern Insights"
        case .personalization: return "Personalization"
        }
    }
}

enum AggregationLevel {
    case hourly, daily, weekly, monthly
}

enum AggregationMethod {
    case average, maximum, minimum, sum
}

enum ExportFormat {
    case csv, json
}

class MockChartDataProvider {
    var mockData: [ChartDataPoint] = []
    var mockRawData: [MockRawDataPoint] = []
    var shouldThrowError = false
    var delayResponse = false

    func getData() async throws -> [ChartDataPoint] {
        if shouldThrowError {
            throw ChartDataError.dataUnavailable
        }

        if delayResponse {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        return mockData
    }
}

enum ChartDataError: Error {
    case dataUnavailable
}
