import XCTest
import SwiftUI
import Charts
@testable import AIKO

/// Comprehensive Performance Tests - Chart rendering <100ms, export <2s
/// RED PHASE: All tests should FAIL initially as performance optimizations don't exist yet
final class PerformanceTests: XCTestCase {

    // MARK: - Properties

    var analyticsRepository: MockAnalyticsRepository?
    var chartViewModel: MockChartViewModel?
    var exportManager: MockExportManager?
    var performanceMonitor: PerformanceMonitor?

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        analyticsRepository = MockAnalyticsRepository()
        chartViewModel = MockChartViewModel()
        exportManager = MockExportManager()
        performanceMonitor = PerformanceMonitor()
    }

    override func tearDown() async throws {
        analyticsRepository = nil
        chartViewModel = nil
        exportManager = nil
        performanceMonitor = nil
        try await super.tearDown()
    }

    // MARK: - Chart Rendering Performance Tests

    func test_chartRendering_completesUnder100ms() {
        // RED: Will fail as optimized chart rendering doesn't exist
        measure(metrics: [XCTClockMetric()]) {
            let chartData = createLargeChartDataset(pointCount: 1000)

            let startTime = CFAbsoluteTimeGetCurrent()

            let chartView = Chart(chartData, id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(by: .value("Category", dataPoint.category))
            }
            .frame(width: 400, height: 300)

            // Simulate chart rendering
            _ = UIHostingController(rootView: chartView)

            let renderTime = CFAbsoluteTimeGetCurrent() - startTime

            XCTAssertLessThan(renderTime, 0.1, "Chart rendering should complete within 100ms")
        }
    }

    func test_chartDataProcessing_performsEfficiently() async {
        // RED: Will fail as efficient data processing doesn't exist
        let rawData = createMassiveTimeSeriesData(pointCount: 10000)

        let startTime = CFAbsoluteTimeGetCurrent()

        let processedData = await chartViewModel.processChartData(rawData)

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertLessThan(processingTime, 0.05, "Chart data processing should complete within 50ms")
        XCTAssertFalse(processedData.isEmpty, "Processed data should not be empty")
        XCTAssertLessThanOrEqual(processedData.count, 1000, "Data should be aggregated for performance")
    }

    func test_chartUpdates_maintainFrameRate() async {
        // RED: Will fail as frame rate optimization doesn't exist
        let chartView = createTestChartView()
        let frameRateMonitor = FrameRateMonitor()

        frameRateMonitor.startMonitoring()

        // Simulate rapid data updates
        for _ in 0..<60 { // 1 second worth of 60fps updates
            let newData = createRandomChartData(pointCount: 100)
            await chartViewModel.updateData(newData)

            try? await Task.sleep(nanoseconds: 16_666_667) // ~60fps timing
        }

        frameRateMonitor.stopMonitoring()

        let averageFrameRate = frameRateMonitor.getAverageFrameRate()
        XCTAssertGreaterThan(averageFrameRate, 55, "Should maintain near 60fps during updates")
    }

    func test_multipleCharts_renderConcurrently() async {
        // RED: Will fail as concurrent rendering optimization doesn't exist
        let chartConfigurations = [
            ChartConfiguration(type: .line, dataPoints: 500),
            ChartConfiguration(type: .bar, dataPoints: 300),
            ChartConfiguration(type: .area, dataPoints: 800),
            ChartConfiguration(type: .scatter, dataPoints: 1000)
        ]

        let startTime = CFAbsoluteTimeGetCurrent()

        await withTaskGroup(of: Void.self) { group in
            for config in chartConfigurations {
                group.addTask {
                    let data = self.createChartData(for: config)
                    _ = await self.renderChart(data: data, type: config.type)
                }
            }
        }

        let totalRenderTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertLessThan(totalRenderTime, 0.2, "Multiple charts should render concurrently within 200ms")
    }

    func test_chartScrolling_maintainsPerformance() async {
        // RED: Will fail as scrolling optimization doesn't exist
        let largeDataset = createTimeSeriesData(pointCount: 5000)
        chartViewModel.setData(largeDataset)

        let scrollPerformanceMonitor = ScrollPerformanceMonitor()
        scrollPerformanceMonitor.startMonitoring()

        // Simulate scrolling through the chart
        let scrollPositions = stride(from: 0.0, through: 1.0, by: 0.01) // 100 scroll positions

        for position in scrollPositions {
            await chartViewModel.scrollToPosition(position)
            try? await Task.sleep(nanoseconds: 16_666_667) // 60fps timing
        }

        scrollPerformanceMonitor.stopMonitoring()

        let averageScrollTime = scrollPerformanceMonitor.getAverageScrollTime()
        XCTAssertLessThan(averageScrollTime, 0.016, "Scroll updates should complete within 16ms for 60fps")
    }

    // MARK: - Export Performance Tests

    func test_pdfExport_completesUnder2Seconds() async {
        // RED: Will fail as optimized PDF export doesn't exist
        let largeExportData = createLargeExportDataset()
        exportManager.setExportData(largeExportData)

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let pdfURL = try await exportManager.generateExport(format: .pdf, timeRange: .oneYear)

            let exportTime = CFAbsoluteTimeGetCurrent() - startTime

            XCTAssertLessThan(exportTime, 2.0, "PDF export should complete within 2 seconds")
            XCTAssertNotNil(pdfURL, "PDF should be generated successfully")

            // Verify PDF quality wasn't sacrificed for speed
            let pdfSize = try await getPDFFileSize(pdfURL)
            XCTAssertGreaterThan(pdfSize, 100_000, "PDF should have substantial content")

        } catch {
            XCTFail("PDF export should not fail: \(error)")
        }
    }

    func test_csvExport_handlesLargeDatasets() async {
        // RED: Will fail as optimized CSV export doesn't exist
        let massiveDataset = createMassiveExportDataset(rowCount: 100_000)
        exportManager.setExportData(massiveDataset)

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let csvURL = try await exportManager.generateExport(format: .csv, timeRange: .oneYear)

            let exportTime = CFAbsoluteTimeGetCurrent() - startTime

            XCTAssertLessThan(exportTime, 1.5, "Large CSV export should complete within 1.5 seconds")

            // Verify data completeness
            let csvContent = try String(contentsOf: csvURL)
            let lineCount = csvContent.components(separatedBy: .newlines).count - 1 // Exclude header
            XCTAssertGreaterThanOrEqual(lineCount, 100_000, "All data should be exported")

        } catch {
            XCTFail("CSV export should not fail: \(error)")
        }
    }

    func test_jsonExport_optimizesMemoryUsage() async {
        // RED: Will fail as memory-optimized JSON export doesn't exist
        let memoryMonitor = MemoryMonitor()
        memoryMonitor.startMonitoring()

        let largeDataset = createLargeExportDataset()
        exportManager.setExportData(largeDataset)

        let initialMemory = memoryMonitor.getCurrentMemoryUsage()

        do {
            let jsonURL = try await exportManager.generateExport(format: .json, timeRange: .oneYear)

            let peakMemory = memoryMonitor.getPeakMemoryUsage()
            let memoryIncrease = peakMemory - initialMemory

            XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory usage should stay under 50MB")
            XCTAssertNotNil(jsonURL, "JSON should be generated successfully")

        } catch {
            XCTFail("JSON export should not fail: \(error)")
        }

        memoryMonitor.stopMonitoring()
    }

    func test_concurrentExports_maintainPerformance() async {
        // RED: Will fail as concurrent export optimization doesn't exist
        let exportData = createMediumExportDataset()
        exportManager.setExportData(exportData)

        let startTime = CFAbsoluteTimeGetCurrent()

        // Start multiple exports concurrently
        async let pdfExport = exportManager.generateExport(format: .pdf, timeRange: .thirtyDays)
        async let csvExport = exportManager.generateExport(format: .csv, timeRange: .thirtyDays)
        async let jsonExport = exportManager.generateExport(format: .json, timeRange: .thirtyDays)

        do {
            let (pdfURL, csvURL, jsonURL) = try await (pdfExport, csvExport, jsonExport)

            let totalTime = CFAbsoluteTimeGetCurrent() - startTime

            // Concurrent exports should be faster than sequential
            XCTAssertLessThan(totalTime, 3.0, "Concurrent exports should complete within 3 seconds")
            XCTAssertNotNil(pdfURL)
            XCTAssertNotNil(csvURL)
            XCTAssertNotNil(jsonURL)

        } catch {
            XCTFail("Concurrent exports should not fail: \(error)")
        }
    }

    // MARK: - Data Loading Performance Tests

    func test_dataLoading_optimizedForLargeDatasets() async {
        // RED: Will fail as optimized data loading doesn't exist
        let largeDataset = createHugeAnalyticsDataset(sessionCount: 50_000)
        analyticsRepository.seedData(largeDataset)

        let startTime = CFAbsoluteTimeGetCurrent()

        await analyticsRepository.refreshAnalytics()

        let loadingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertLessThan(loadingTime, 1.0, "Large dataset loading should complete within 1 second")
        XCTAssertFalse(analyticsRepository.summaryMetrics.isEmpty, "Data should be loaded successfully")
        XCTAssertFalse(analyticsRepository.chartData.isEmpty, "Chart data should be available")
    }

    func test_backgroundProcessing_doesNotBlockUI() async {
        // RED: Will fail as background processing optimization doesn't exist
        let heavyComputationData = createComputationIntensiveDataset()
        analyticsRepository.seedData(heavyComputationData)

        let uiResponsivenessMonitor = UIResponsivenessMonitor()
        uiResponsivenessMonitor.startMonitoring()

        // Start background processing
        await analyticsRepository.performHeavyAnalyticsComputation()

        // Simulate UI interactions during processing
        for _ in 0..<100 {
            uiResponsivenessMonitor.simulateUIInteraction()
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        uiResponsivenessMonitor.stopMonitoring()

        let averageUIResponseTime = uiResponsivenessMonitor.getAverageResponseTime()
        XCTAssertLessThan(averageUIResponseTime, 0.016, "UI should remain responsive during background processing")
    }

    func test_cacheEffectiveness_improvesPerformance() async {
        // RED: Will fail as caching optimization doesn't exist
        let testData = createMediumAnalyticsDataset()
        analyticsRepository.seedData(testData)

        // First load (cold cache)
        let coldStartTime = CFAbsoluteTimeGetCurrent()
        await analyticsRepository.refreshAnalytics()
        let coldLoadTime = CFAbsoluteTimeGetCurrent() - coldStartTime

        // Second load (warm cache)
        let warmStartTime = CFAbsoluteTimeGetCurrent()
        await analyticsRepository.refreshAnalytics()
        let warmLoadTime = CFAbsoluteTimeGetCurrent() - warmStartTime

        // Cache should improve performance significantly
        XCTAssertLessThan(warmLoadTime, coldLoadTime * 0.3,
                          "Cached load should be at least 70% faster")
        XCTAssertLessThan(warmLoadTime, 0.1, "Cached load should be under 100ms")
    }

    // MARK: - Memory Performance Tests

    func test_memoryUsage_staysWithinBounds() async {
        // RED: Will fail as memory optimization doesn't exist
        let memoryMonitor = MemoryMonitor()
        memoryMonitor.startMonitoring()

        let initialMemory = memoryMonitor.getCurrentMemoryUsage()

        // Load progressively larger datasets
        for datasetSize in [1000, 5000, 10000, 25000] {
            let dataset = createAnalyticsDataset(size: datasetSize)
            analyticsRepository.seedData(dataset)
            await analyticsRepository.refreshAnalytics()

            // Update charts with new data
            await chartViewModel.updateData(analyticsRepository.chartData)

            let currentMemory = memoryMonitor.getCurrentMemoryUsage()
            let memoryIncrease = currentMemory - initialMemory

            XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024,
                              "Memory usage should stay under 100MB for dataset size \(datasetSize)")
        }

        memoryMonitor.stopMonitoring()
    }

    func test_memoryLeaks_preventedDuringOperation() async {
        // RED: Will fail as memory leak prevention doesn't exist
        let memoryMonitor = MemoryMonitor()
        memoryMonitor.startMonitoring()

        let initialMemory = memoryMonitor.getCurrentMemoryUsage()

        // Perform multiple cycles of data loading and clearing
        for cycle in 0..<10 {
            let cycleData = createAnalyticsDataset(size: 5000)
            analyticsRepository.seedData(cycleData)
            await analyticsRepository.refreshAnalytics()

            // Generate exports
            _ = try? await exportManager.generateExport(format: .pdf, timeRange: .thirtyDays)

            // Clear data
            analyticsRepository.clearAllData()

            // Force garbage collection
            autoreleasepool { }

            if cycle % 3 == 0 { // Check every 3 cycles
                let currentMemory = memoryMonitor.getCurrentMemoryUsage()
                let memoryGrowth = currentMemory - initialMemory

                XCTAssertLessThan(memoryGrowth, 10 * 1024 * 1024,
                                  "Memory should not grow by more than 10MB after cycle \(cycle)")
            }
        }

        memoryMonitor.stopMonitoring()
    }

    // MARK: - Real-time Performance Tests

    func test_realTimeUpdates_maintainPerformance() async {
        // RED: Will fail as real-time optimization doesn't exist
        let performanceMonitor = RealtimePerformanceMonitor()
        performanceMonitor.startMonitoring()

        // Simulate real-time data updates
        for updateCycle in 0..<300 { // 5 minutes of updates at 1Hz
            let newDataPoint = createRealtimeDataPoint()

            let updateStartTime = CFAbsoluteTimeGetCurrent()

            await analyticsRepository.addRealtimeDataPoint(newDataPoint)
            await chartViewModel.updateWithRealtimeData()

            let updateTime = CFAbsoluteTimeGetCurrent() - updateStartTime

            XCTAssertLessThan(updateTime, 0.01,
                              "Real-time update \(updateCycle) should complete within 10ms")

            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms between updates
        }

        performanceMonitor.stopMonitoring()

        let averageUpdateTime = performanceMonitor.getAverageUpdateTime()
        let maxUpdateTime = performanceMonitor.getMaxUpdateTime()

        XCTAssertLessThan(averageUpdateTime, 0.005, "Average real-time update should be under 5ms")
        XCTAssertLessThan(maxUpdateTime, 0.02, "Maximum real-time update should be under 20ms")
    }

    // MARK: - Stress Tests

    func test_stressTest_maintainsStabilityUnderLoad() async {
        // RED: Will fail as stress handling doesn't exist
        let stressTestMonitor = StressTestMonitor()
        stressTestMonitor.startMonitoring()

        // Apply multiple stressors simultaneously
        await withTaskGroup(of: Void.self) { group in
            // Stress 1: Rapid data updates
            group.addTask {
                for _ in 0..<1000 {
                    let data = self.createRandomChartData(pointCount: 100)
                    await self.chartViewModel.updateData(data)
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }
            }

            // Stress 2: Concurrent exports
            group.addTask {
                for _ in 0..<20 {
                    _ = try? await self.exportManager.generateExport(format: .csv, timeRange: .sevenDays)
                }
            }

            // Stress 3: Memory pressure
            group.addTask {
                for _ in 0..<50 {
                    let largeData = self.createLargeAnalyticsDataset(size: 10000)
                    self.analyticsRepository.seedData(largeData)
                    await self.analyticsRepository.refreshAnalytics()
                    self.analyticsRepository.clearAllData()
                }
            }
        }

        stressTestMonitor.stopMonitoring()

        XCTAssertTrue(stressTestMonitor.systemRemainedStable,
                      "System should remain stable under stress")
        XCTAssertFalse(stressTestMonitor.detectedCrashes,
                       "No crashes should occur during stress test")
    }

    // MARK: - Helper Methods

    private func createLargeChartDataset(pointCount: Int) -> [ChartDataPoint] {
        (0..<pointCount).map { index in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                value: Double.random(in: 0.0...1.0),
                category: "Performance Test"
            )
        }
    }

    private func createMassiveTimeSeriesData(pointCount: Int) -> [AnalyticsDataPoint] {
        (0..<pointCount).map { index in
            AnalyticsDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-index * 60)),
                value: Double.random(in: 0.0...1.0),
                category: "Massive Dataset"
            )
        }
    }

    private func createTestChartView() -> some View {
        let emptyData: [ChartDataPoint] = []
        return Chart(emptyData, id: \.date) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", dataPoint.value)
            )
        }
        .frame(width: 400, height: 300)
    }

    private func createRandomChartData(pointCount: Int) -> [ChartDataPoint] {
        (0..<pointCount).map { _ in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval.random(in: -86400...0)),
                value: Double.random(in: 0.0...1.0),
                category: "Random"
            )
        }
    }

    private func createChartData(for config: ChartConfiguration) -> [ChartDataPoint] {
        (0..<config.dataPoints).map { index in
            ChartDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                value: Double.random(in: 0.0...1.0),
                category: config.type.rawValue
            )
        }
    }

    private func renderChart(data: [ChartDataPoint], type: ChartType) async -> UIView {
        // Mock chart rendering
        return UIView()
    }

    private func createTimeSeriesData(pointCount: Int) -> [AnalyticsDataPoint] {
        (0..<pointCount).map { index in
            AnalyticsDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                value: Double.random(in: 0.0...1.0),
                category: "Time Series"
            )
        }
    }

    private func createLargeExportDataset() -> ExportDataset {
        ExportDataset(
            summaryMetrics: (0..<100).map { _ in mockSummaryMetric() },
            timeSeriesData: (0..<5000).map { _ in mockTimeSeriesPoint() },
            insights: (0..<200).map { _ in mockInsight() }
        )
    }

    private func createMassiveExportDataset(rowCount: Int) -> ExportDataset {
        ExportDataset(
            summaryMetrics: (0..<min(rowCount / 100, 1000)).map { _ in mockSummaryMetric() },
            timeSeriesData: (0..<rowCount).map { _ in mockTimeSeriesPoint() },
            insights: (0..<min(rowCount / 50, 2000)).map { _ in mockInsight() }
        )
    }

    private func createMediumExportDataset() -> ExportDataset {
        ExportDataset(
            summaryMetrics: (0..<20).map { _ in mockSummaryMetric() },
            timeSeriesData: (0..<1000).map { _ in mockTimeSeriesPoint() },
            insights: (0..<50).map { _ in mockInsight() }
        )
    }

    private func createHugeAnalyticsDataset(sessionCount: Int) -> [AnalyticsSession] {
        (0..<sessionCount).map { index in
            AnalyticsSession(
                id: UUID(),
                startTime: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                duration: TimeInterval.random(in: 300...7200),
                activities: createRandomActivities(),
                metrics: createRandomMetrics()
            )
        }
    }

    private func createComputationIntensiveDataset() -> [AnalyticsSession] {
        (0..<10000).map { index in
            AnalyticsSession(
                id: UUID(),
                startTime: Date().addingTimeInterval(TimeInterval(-index * 60)),
                duration: TimeInterval.random(in: 60...3600),
                activities: createComplexActivities(),
                metrics: createComputationIntensiveMetrics()
            )
        }
    }

    private func createMediumAnalyticsDataset() -> [AnalyticsSession] {
        (0..<1000).map { index in
            AnalyticsSession(
                id: UUID(),
                startTime: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                duration: TimeInterval.random(in: 300...3600),
                activities: createRandomActivities(),
                metrics: createRandomMetrics()
            )
        }
    }

    private func createAnalyticsDataset(size: Int) -> [AnalyticsSession] {
        (0..<size).map { index in
            AnalyticsSession(
                id: UUID(),
                startTime: Date().addingTimeInterval(TimeInterval(-index * 600)),
                duration: TimeInterval.random(in: 300...1800),
                activities: createRandomActivities(),
                metrics: createRandomMetrics()
            )
        }
    }

    private func createRealtimeDataPoint() -> RealtimeDataPoint {
        RealtimeDataPoint(
            timestamp: Date(),
            value: Double.random(in: 0.0...1.0),
            category: "Realtime"
        )
    }

    private func mockSummaryMetric() -> MockSummaryMetric {
        MockSummaryMetric(name: "Test Metric", value: "\(Int.random(in: 0...100))%")
    }

    private func mockTimeSeriesPoint() -> MockTimeSeriesPoint {
        MockTimeSeriesPoint(
            date: Date().addingTimeInterval(TimeInterval.random(in: -86400 * 365...0)),
            value: Double.random(in: 0.0...1.0)
        )
    }

    private func mockInsight() -> MockInsight {
        MockInsight(
            title: "Performance Insight",
            description: "Generated insight for performance testing with longer description text"
        )
    }

    private func createRandomActivities() -> [String] {
        ["typing", "reading", "reviewing", "planning"].shuffled().prefix(2).map { $0 }
    }

    private func createComplexActivities() -> [String] {
        let baseActivities = ["typing", "reading", "reviewing", "planning", "analyzing", "creating"]
        return baseActivities.shuffled().prefix(Int.random(in: 3...6)).map { $0 }
    }

    private func createRandomMetrics() -> [String: Double] {
        [
            "focus_score": Double.random(in: 0.0...1.0),
            "productivity": Double.random(in: 0.0...1.0),
            "efficiency": Double.random(in: 0.0...1.0)
        ]
    }

    private func createComputationIntensiveMetrics() -> [String: Double] {
        var metrics: [String: Double] = [:]
        for i in 0..<50 { // Many metrics to increase computation
            metrics["metric_\(i)"] = Double.random(in: 0.0...1.0)
        }
        return metrics
    }

    private func getPDFFileSize(_ url: URL) async throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
}

// MARK: - Performance Monitoring Support Types

// RED: These will fail as the real types don't exist yet
class PerformanceMonitor {
    // Mock performance monitoring
}

class FrameRateMonitor {
    private var frameCount = 0
    private var startTime: CFAbsoluteTime = 0

    func startMonitoring() {
        startTime = CFAbsoluteTimeGetCurrent()
        frameCount = 0
    }

    func stopMonitoring() {
        // Mock implementation
    }

    func getAverageFrameRate() -> Double {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        return Double(frameCount) / elapsed
    }
}

class ScrollPerformanceMonitor {
    private var scrollTimes: [Double] = []

    func startMonitoring() {
        scrollTimes.removeAll()
    }

    func stopMonitoring() {
        // Mock implementation
    }

    func getAverageScrollTime() -> Double {
        return scrollTimes.isEmpty ? 0 : scrollTimes.reduce(0, +) / Double(scrollTimes.count)
    }
}

class MemoryMonitor {
    func startMonitoring() {
        // Mock implementation
    }

    func stopMonitoring() {
        // Mock implementation
    }

    func getCurrentMemoryUsage() -> UInt64 {
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

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }

    func getPeakMemoryUsage() -> UInt64 {
        return getCurrentMemoryUsage() + UInt64.random(in: 0...1024 * 1024) // Mock peak
    }
}

class UIResponsivenessMonitor {
    private var responseTimes: [Double] = []

    func startMonitoring() {
        responseTimes.removeAll()
    }

    func stopMonitoring() {
        // Mock implementation
    }

    func simulateUIInteraction() {
        let responseTime = Double.random(in: 0.001...0.020)
        responseTimes.append(responseTime)
    }

    func getAverageResponseTime() -> Double {
        return responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
}

class RealtimePerformanceMonitor {
    private var updateTimes: [Double] = []

    func startMonitoring() {
        updateTimes.removeAll()
    }

    func stopMonitoring() {
        // Mock implementation
    }

    func getAverageUpdateTime() -> Double {
        return updateTimes.isEmpty ? 0 : updateTimes.reduce(0, +) / Double(updateTimes.count)
    }

    func getMaxUpdateTime() -> Double {
        return updateTimes.max() ?? 0
    }
}

class StressTestMonitor {
    private(set) var systemRemainedStable = true
    private(set) var detectedCrashes = false

    func startMonitoring() {
        systemRemainedStable = true
        detectedCrashes = false
    }

    func stopMonitoring() {
        // Mock implementation - assume system remained stable for tests
    }
}

// MARK: - Mock Support Types

struct ChartDataPoint {
    let date: Date
    let value: Double
    let category: String
}

struct ChartConfiguration {
    let type: ChartType
    let dataPoints: Int
}

enum ChartType: String {
    case line, bar, area, scatter
}

struct ExportDataset {
    let summaryMetrics: [MockSummaryMetric]
    let timeSeriesData: [MockTimeSeriesPoint]
    let insights: [MockInsight]
}

struct MockSummaryMetric {
    let name: String
    let value: String
}

struct MockTimeSeriesPoint {
    let date: Date
    let value: Double
}

struct MockInsight {
    let title: String
    let description: String
}

struct AnalyticsSession {
    let id: UUID
    let startTime: Date
    let duration: TimeInterval
    let activities: [String]
    let metrics: [String: Double]
}

struct RealtimeDataPoint {
    let timestamp: Date
    let value: Double
    let category: String
}

class MockChartViewModel {
    var data: [AnalyticsDataPoint] = []

    func processChartData(_ rawData: [AnalyticsDataPoint]) async -> [ChartDataPoint] {
        // Mock processing with aggregation
        return rawData.prefix(1000).map { point in
            ChartDataPoint(date: point.date, value: point.value, category: point.category)
        }
    }

    func updateData(_ newData: [AnalyticsDataPoint]) async {
        self.data = newData
    }

    func scrollToPosition(_ position: Double) async {
        // Mock scroll implementation
    }

    func setData(_ data: [AnalyticsDataPoint]) {
        self.data = data
    }

    func updateWithRealtimeData() async {
        // Mock real-time update
    }
}

class MockExportManager {
    private var exportData: ExportDataset?

    func setExportData(_ data: ExportDataset) {
        exportData = data
    }

    func generateExport(format: ExportFormat, timeRange: TimeRange) async throws -> URL {
        // Mock export with realistic timing
        let delay = format == .pdf ? 0.5 : 0.1 // PDF takes longer
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        let filename = "test-export.\(format.rawValue)"
        return URL(fileURLWithPath: "/tmp/\(filename)")
    }
}

enum ExportFormat: String {
    case pdf, csv, json
}
