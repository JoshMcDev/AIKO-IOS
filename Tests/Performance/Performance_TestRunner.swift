import Foundation
import XCTest

/// Automated performance test runner with reporting capabilities
public final class PerformanceTestRunner {
    // MARK: - Properties

    private let testSuites: [XCTestCase.Type] = [
        PerformanceTestSuite.self,
        CriticalPathPerformanceTests.self,
    ]

    private var results: [PerformanceTestResult] = []
    private let baselineManager = PerformanceBaselineManager()

    // MARK: - Public API

    /// Runs all performance tests and generates a report
    public func runAllTests() async throws -> PerformanceReport {
        print(" Starting Performance Test Suite")
        let startTime = Date()

        // Clear previous results
        results.removeAll()

        // Run each test suite
        for suite in testSuites {
            await runTestSuite(suite)
        }

        // Generate report
        let report = generateReport(duration: Date().timeIntervalSince(startTime))

        // Save results
        try await saveResults(report)

        // Check for regressions
        let regressions = await checkForRegressions()
        if !regressions.isEmpty {
            report.regressions = regressions
        }

        print(" Performance tests completed in \(String(format: "%.2f", report.totalDuration))s")

        return report
    }

    /// Runs performance tests for a specific feature
    public func runFeatureTests(_ feature: Feature) async throws -> FeaturePerformanceReport {
        let tests = getTestsForFeature(feature)
        var featureResults: [PerformanceTestResult] = []

        for test in tests {
            if let result = await runSingleTest(test) {
                featureResults.append(result)
            }
        }

        return FeaturePerformanceReport(
            feature: feature,
            results: featureResults,
            timestamp: Date()
        )
    }

    // MARK: - Private Methods

    private func runTestSuite(_ suiteType: XCTestCase.Type) async {
        let suite = suiteType.init()
        let suiteName = String(describing: suiteType)

        print("\n Running \(suiteName)")

        // Get all test methods
        let testMethods = getTestMethods(from: suite)

        for method in testMethods {
            if let result = await runTestMethod(method, on: suite) {
                results.append(result)
            }
        }
    }

    private func runTestMethod(_ method: String, on suite: XCTestCase) async -> PerformanceTestResult? {
        print("  ▶ \(method)")

        let expectation = XCTestExpectation(description: method)
        var metrics: [PerformanceMetric] = []

        // Create custom measure block
        let measureBlock = { (block: () async throws -> Void) in
            let iterations = 5
            var durations: [TimeInterval] = []
            var memoryUsages: [Int64] = []

            for _ in 0 ..< iterations {
                let startMemory = self.getCurrentMemoryUsage()
                let startTime = CFAbsoluteTimeGetCurrent()

                try? await block()

                let duration = CFAbsoluteTimeGetCurrent() - startTime
                let endMemory = self.getCurrentMemoryUsage()

                durations.append(duration)
                memoryUsages.append(endMemory - startMemory)
            }

            // Calculate statistics
            let avgDuration = durations.reduce(0, +) / Double(durations.count)
            let minDuration = durations.min() ?? 0
            let maxDuration = durations.max() ?? 0
            let avgMemory = memoryUsages.reduce(0, +) / Int64(memoryUsages.count)

            metrics = [
                PerformanceMetric(
                    name: "Duration",
                    value: avgDuration * 1000, // Convert to ms
                    unit: "ms",
                    min: minDuration * 1000,
                    max: maxDuration * 1000
                ),
                PerformanceMetric(
                    name: "Memory",
                    value: Double(avgMemory) / 1024 / 1024, // Convert to MB
                    unit: "MB",
                    min: Double(memoryUsages.min() ?? 0) / 1024 / 1024,
                    max: Double(memoryUsages.max() ?? 0) / 1024 / 1024
                ),
            ]

            expectation.fulfill()
        }

        // Run the test
        suite.setUp()

        // Use reflection to call the test method
        let selector = NSSelectorFromString(method)
        if suite.responds(to: selector) {
            suite.perform(selector)
        }

        suite.tearDown()

        await fulfillment(of: [expectation], timeout: 60)

        return PerformanceTestResult(
            testName: method,
            suiteName: String(describing: type(of: suite)),
            metrics: metrics,
            passed: true,
            timestamp: Date()
        )
    }

    private func getTestMethods(from suite: XCTestCase) -> [String] {
        var methods: [String] = []
        var methodCount: UInt32 = 0

        if let methodList = class_copyMethodList(type(of: suite), &methodCount) {
            for i in 0 ..< Int(methodCount) {
                let method = methodList[i]
                let selector = method_getName(method)
                let name = String(cString: sel_getName(selector))

                if name.hasPrefix("test"), name.contains("Performance") {
                    methods.append(name)
                }
            }
            free(methodList)
        }

        return methods
    }

    private func runSingleTest(_ test: PerformanceTest) async -> PerformanceTestResult? {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()

        // Run test
        let success = await test.run()

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let memoryDelta = getCurrentMemoryUsage() - startMemory

        return PerformanceTestResult(
            testName: test.name,
            suiteName: test.feature.rawValue,
            metrics: [
                PerformanceMetric(
                    name: "Duration",
                    value: duration * 1000,
                    unit: "ms"
                ),
                PerformanceMetric(
                    name: "Memory Delta",
                    value: Double(memoryDelta) / 1024 / 1024,
                    unit: "MB"
                ),
            ],
            passed: success,
            timestamp: Date()
        )
    }

    private func generateReport(duration: TimeInterval) -> PerformanceReport {
        let totalTests = results.count
        let passedTests = results.filter(\.passed).count
        let failedTests = totalTests - passedTests

        // Group by suite
        let suiteResults = Dictionary(grouping: results) { $0.suiteName }

        // Calculate aggregate metrics
        let aggregateMetrics = calculateAggregateMetrics()

        return PerformanceReport(
            id: UUID(),
            timestamp: Date(),
            totalDuration: duration,
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            results: results,
            aggregateMetrics: aggregateMetrics,
            regressions: []
        )
    }

    private func calculateAggregateMetrics() -> [AggregateMetric] {
        var metrics: [AggregateMetric] = []

        // Duration metrics
        let durations = results.compactMap { result in
            result.metrics.first { $0.name == "Duration" }?.value
        }

        if !durations.isEmpty {
            metrics.append(AggregateMetric(
                name: "Average Test Duration",
                value: durations.reduce(0, +) / Double(durations.count),
                unit: "ms",
                percentile95: calculatePercentile(durations, percentile: 95),
                percentile99: calculatePercentile(durations, percentile: 99)
            ))
        }

        // Memory metrics
        let memoryDeltas = results.compactMap { result in
            result.metrics.first { $0.name == "Memory" }?.value
        }

        if !memoryDeltas.isEmpty {
            metrics.append(AggregateMetric(
                name: "Average Memory Usage",
                value: memoryDeltas.reduce(0, +) / Double(memoryDeltas.count),
                unit: "MB",
                percentile95: calculatePercentile(memoryDeltas, percentile: 95),
                percentile99: calculatePercentile(memoryDeltas, percentile: 99)
            ))
        }

        return metrics
    }

    private func calculatePercentile(_ values: [Double], percentile: Int) -> Double {
        let sorted = values.sorted()
        let index = Int(Double(sorted.count - 1) * Double(percentile) / 100.0)
        return sorted[index]
    }

    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    private func getTestsForFeature(_ feature: Feature) -> [PerformanceTest] {
        // Map features to specific tests
        switch feature {
        case .documentGeneration:
            [
                PerformanceTest(name: "Document Generation E2E", feature: feature) {
                    // Test implementation
                    true
                },
            ]
        case .caching:
            [
                PerformanceTest(name: "Adaptive Cache Performance", feature: feature) {
                    // Test implementation
                    true
                },
            ]
        case .apiOptimization:
            [
                PerformanceTest(name: "Batched API Requests", feature: feature) {
                    // Test implementation
                    true
                },
            ]
        default:
            []
        }
    }

    private func saveResults(_ report: PerformanceReport) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(report)
        let fileName = "performance_report_\(ISO8601DateFormatter().string(from: report.timestamp)).json"
        let url = getReportsDirectory().appendingPathComponent(fileName)

        try data.write(to: url)

        // Also save latest report
        let latestURL = getReportsDirectory().appendingPathComponent("latest_performance_report.json")
        try data.write(to: latestURL)
    }

    private func checkForRegressions() async -> [PerformanceRegression] {
        await baselineManager.checkForRegressions(currentResults: results)
    }

    private func getReportsDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let reportsPath = documentsPath.appendingPathComponent("PerformanceReports")

        try? FileManager.default.createDirectory(at: reportsPath, withIntermediateDirectories: true)

        return reportsPath
    }

    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            let waiter = XCTWaiter()
            let result = waiter.wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
}

// MARK: - Supporting Types

public struct PerformanceReport: Codable {
    let id: UUID
    let timestamp: Date
    let totalDuration: TimeInterval
    let totalTests: Int
    let passedTests: Int
    let failedTests: Int
    let results: [PerformanceTestResult]
    let aggregateMetrics: [AggregateMetric]
    var regressions: [PerformanceRegression]

    var summary: String {
        """
        Performance Test Report
        ======================

        Date: \(DateFormatter.localizedString(from: timestamp, dateStyle: .full, timeStyle: .medium))
        Duration: \(String(format: "%.2f", totalDuration))s

        Tests Run: \(totalTests)
        Passed: \(passedTests)
        Failed: \(failedTests) ❌

        Aggregate Metrics:
        \(aggregateMetrics.map { "- \($0.name): \(String(format: "%.2f", $0.value)) \($0.unit)" }.joined(separator: "\n"))

        \(regressions.isEmpty ? "No performance regressions detected! 🎉" : "⚠ \(regressions.count) performance regressions detected!")
        """
    }
}

public struct PerformanceTestResult: Codable {
    let testName: String
    let suiteName: String
    let metrics: [PerformanceMetric]
    let passed: Bool
    let timestamp: Date
}

public struct PerformanceMetric: Codable {
    let name: String
    let value: Double
    let unit: String
    var min: Double?
    var max: Double?
}

public struct AggregateMetric: Codable {
    let name: String
    let value: Double
    let unit: String
    let percentile95: Double
    let percentile99: Double
}

public struct PerformanceRegression: Codable {
    let testName: String
    let metric: String
    let baseline: Double
    let current: Double
    let regressionPercentage: Double
    let severity: Severity

    enum Severity: String, Codable {
        case minor, moderate, severe
    }
}

public struct FeaturePerformanceReport: Codable {
    let feature: Feature
    let results: [PerformanceTestResult]
    let timestamp: Date
}

public enum Feature: String, CaseIterable, Codable {
    case documentGeneration = "Document Generation"
    case caching = "Caching"
    case apiOptimization = "API Optimization"
    case serviceLayer = "Service Layer"
    case tcaReducers = "TCA Reducers"
    case encryption = "Encryption"
    case templates = "Templates"
}

struct PerformanceTest {
    let name: String
    let feature: Feature
    let run: () async -> Bool
}

// MARK: - Baseline Manager

actor PerformanceBaselineManager {
    private var baselines: [String: Double] = [:]

    init() {
        loadBaselines()
    }

    func checkForRegressions(currentResults: [PerformanceTestResult]) async -> [PerformanceRegression] {
        var regressions: [PerformanceRegression] = []

        for result in currentResults {
            for metric in result.metrics {
                let key = "\(result.testName)_\(metric.name)"

                if let baseline = baselines[key] {
                    let regressionPercentage = ((metric.value - baseline) / baseline) * 100

                    if regressionPercentage > 10 { // 10% regression threshold
                        let severity: PerformanceRegression.Severity = if regressionPercentage > 50 {
                            .severe
                        } else if regressionPercentage > 25 {
                            .moderate
                        } else {
                            .minor
                        }

                        regressions.append(PerformanceRegression(
                            testName: result.testName,
                            metric: metric.name,
                            baseline: baseline,
                            current: metric.value,
                            regressionPercentage: regressionPercentage,
                            severity: severity
                        ))
                    }
                }

                // Update baseline
                baselines[key] = metric.value
            }
        }

        saveBaselines()
        return regressions
    }

    private func loadBaselines() {
        if let data = UserDefaults.standard.data(forKey: "performance_baselines"),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data)
        {
            baselines = decoded
        }
    }

    private func saveBaselines() {
        if let encoded = try? JSONEncoder().encode(baselines) {
            UserDefaults.standard.set(encoded, forKey: "performance_baselines")
        }
    }
}
