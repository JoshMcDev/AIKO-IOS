@testable import AIKO
import AppCore
import SwiftUI
import XCTest

/// Performance tests for Agentic Suggestion UI Framework following TDD RED phase approach
/// Tests rendering performance, memory usage, and responsiveness targets
@MainActor
final class AgenticSuggestionUIPerformanceTests: XCTestCase {
    // MARK: - Test Properties

    var viewModel: SuggestionViewModel?
    var mockOrchestrator: MockAgenticOrchestrator?
    var mockComplianceGuardian: MockComplianceGuardian?
    var performanceMonitor: PerformanceMonitor?

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        mockOrchestrator = MockAgenticOrchestrator()
        mockComplianceGuardian = MockComplianceGuardian()
        performanceMonitor = PerformanceMonitor()

        viewModel = await SuggestionViewModel(
            orchestrator: mockOrchestrator,
            complianceGuardian: mockComplianceGuardian
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockOrchestrator = nil
        mockComplianceGuardian = nil
        performanceMonitor = nil
        try await super.tearDown()
    }

    // MARK: - Rendering Performance Tests

    func testSuggestionRendering_MeetsP95Target() throws {
        // Given: Large set of suggestions for performance testing
        let suggestions = createLargeSuggestionSet(count: 50)
        viewModel.currentSuggestions = suggestions

        // When: Measuring rendering performance
        let renderingTime = measureRenderingPerformance {
            let view = AgenticSuggestionView(viewModel: viewModel)
            return view
        }

        // Then: Should meet P95 target of <250ms
        XCTAssertLessThan(renderingTime.p95, 0.25, "P95 rendering time should be under 250ms")
        XCTAssertLessThan(renderingTime.average, 0.15, "Average rendering time should be under 150ms")
        XCTFail("RED PHASE: Rendering performance optimization not implemented")
    }

    func testConfidenceIndicator_UpdatePerformance() throws {
        // Given: Rapid confidence updates scenario
        let confidenceUpdates = Array(0 ..< 100).map { Double($0) / 100.0 }

        // When: Measuring confidence update performance
        let updateTimes = confidenceUpdates.map { confidence in
            measureTime {
                let visualization = ConfidenceVisualization(
                    confidence: confidence,
                    factorCount: 10,
                    reasoning: "Performance test",
                    trend: .stable
                )
                let indicator = ConfidenceIndicator(visualization: visualization)
                return indicator
            }
        }

        // Then: Should meet <50ms target for confidence updates
        let averageUpdateTime = updateTimes.reduce(0, +) / Double(updateTimes.count)
        XCTAssertLessThan(averageUpdateTime, 0.05, "Average confidence update should be under 50ms")
        XCTFail("RED PHASE: Confidence update performance not optimized")
    }

    func testAIReasoningView_ComplexReasoningPerformance() throws {
        // Given: Complex decision with extensive reasoning
        let complexDecision = createComplexDecisionResponse()
        let complianceContext = createComplexComplianceContext()

        // When: Measuring complex reasoning rendering
        let renderingTime = measureTime {
            let view = AIReasoningView(
                decisionResponse: complexDecision,
                complianceContext: complianceContext
            )
            return view
        }

        // Then: Should render complex reasoning within performance targets
        XCTAssertLessThan(renderingTime, 0.1, "Complex reasoning should render within 100ms")
        XCTFail("RED PHASE: Complex reasoning performance not optimized")
    }

    // MARK: - Memory Usage Tests

    func testSuggestionViewModel_MemoryUsage_StaysWithinLimits() throws {
        // Given: Large suggestion dataset
        let largeSuggestionSet = createLargeSuggestionSet(count: 200)

        // When: Loading large suggestion set
        let memoryBefore = performanceMonitor.currentMemoryUsage()
        viewModel.currentSuggestions = largeSuggestionSet
        let memoryAfter = performanceMonitor.currentMemoryUsage()

        // Then: Should stay within 10MB additional memory limit
        let memoryIncrease = memoryAfter - memoryBefore
        XCTAssertLessThan(memoryIncrease, 10_000_000, "Memory increase should be under 10MB")
        XCTFail("RED PHASE: Memory usage optimization not implemented")
    }

    func testConfidenceIndicator_MemoryLeakPrevention() throws {
        // Given: Repeated confidence indicator creation/destruction
        let initialMemory = performanceMonitor.currentMemoryUsage()

        // When: Creating and destroying many confidence indicators
        for i in 0 ..< 1000 {
            let visualization = ConfidenceVisualization(
                confidence: Double(i % 100) / 100.0,
                factorCount: i % 20 + 1,
                reasoning: "Memory test \(i)",
                trend: .stable
            )
            let indicator = ConfidenceIndicator(visualization: visualization)
            // Simulate use and release
            _ = indicator
        }

        // Force garbage collection
        performanceMonitor.forceGarbageCollection()

        let finalMemory = performanceMonitor.currentMemoryUsage()

        // Then: Should not leak memory
        let memoryGrowth = finalMemory - initialMemory
        XCTAssertLessThan(memoryGrowth, 1_000_000, "Memory growth should be under 1MB after cleanup")
        XCTFail("RED PHASE: Memory leak prevention not implemented")
    }

    // MARK: - CPU Usage Tests

    func testSuggestionProcessing_CPUOverhead() async throws {
        // Given: CPU monitoring setup
        let cpuBefore = performanceMonitor.currentCPUUsage()

        // When: Processing suggestions with CPU monitoring
        let testContext = createTestAcquisitionContext()
        try await viewModel.loadSuggestions(for: testContext)

        let cpuAfter = performanceMonitor.currentCPUUsage()

        // Then: Should maintain CPU overhead under 5%
        let cpuOverhead = cpuAfter - cpuBefore
        XCTAssertLessThan(cpuOverhead, 0.05, "CPU overhead should be under 5%")
        XCTFail("RED PHASE: CPU usage optimization not implemented")
    }

    func testBackgroundProcessing_MinimalImpact() async throws {
        // Given: Background suggestion processing
        let cpuBefore = performanceMonitor.currentCPUUsage()

        // When: Running background processing tasks
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 5 {
                group.addTask {
                    let context = self.createTestAcquisitionContext()
                    try? await self.viewModel.loadSuggestions(for: context)
                }
            }
        }

        let cpuAfter = performanceMonitor.currentCPUUsage()

        // Then: Background processing should have minimal CPU impact
        let cpuIncrease = cpuAfter - cpuBefore
        XCTAssertLessThan(cpuIncrease, 0.03, "Background processing CPU impact should be under 3%")
        XCTFail("RED PHASE: Background processing optimization not implemented")
    }

    // MARK: - Network Performance Tests

    func testFeedbackSubmission_NetworkPerformance() async throws {
        // Given: Feedback submission with network timing
        let suggestion = createTestDecisionResponse()
        let feedback = AgenticUserFeedback(
            outcome: .success,
            satisfactionScore: 0.85,
            workflowCompleted: true
        )

        // When: Measuring feedback submission time
        let submissionTime = await measureAsyncTime {
            try await viewModel.submitFeedback(feedback, for: suggestion)
        }

        // Then: Should complete within 200ms target
        XCTAssertLessThan(submissionTime, 0.2, "Feedback submission should complete within 200ms")
        XCTFail("RED PHASE: Network performance optimization not implemented")
    }

    func testOfflineMode_PerformanceImpact() async throws {
        // Given: Offline mode simulation
        mockOrchestrator.simulateOfflineMode = true

        // When: Operating in offline mode
        let offlineTime = await measureAsyncTime {
            try? await viewModel.loadSuggestions(for: createTestAcquisitionContext())
        }

        // Then: Offline mode should maintain reasonable performance
        XCTAssertLessThan(offlineTime, 0.5, "Offline mode should respond within 500ms")
        XCTFail("RED PHASE: Offline mode performance not implemented")
    }

    // MARK: - Stress Testing

    func testHighFrequencySuggestionUpdates_Performance() async throws {
        // Given: High frequency update scenario
        let updateCount = 100
        let updateInterval: TimeInterval = 0.01 // 10ms intervals

        // When: Performing high frequency updates
        let totalTime = await measureAsyncTime {
            for i in 0 ..< updateCount {
                let suggestion = DecisionResponse(
                    selectedAction: WorkflowAction.placeholder,
                    confidence: Double(i) / Double(updateCount),
                    decisionMode: .assisted,
                    reasoning: "High frequency update \(i)",
                    alternativeActions: [],
                    context: createTestAcquisitionContext(),
                    timestamp: Date()
                )

                try? await viewModel.processRealTimeUpdate(suggestion)

                // Simulate real-time intervals
                try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
            }
        }

        // Then: Should handle high frequency updates efficiently
        let averageUpdateTime = totalTime / Double(updateCount)
        XCTAssertLessThan(averageUpdateTime, 0.05, "Average high frequency update should be under 50ms")
        XCTFail("RED PHASE: High frequency update handling not optimized")
    }

    func testMemoryPressure_GracefulDegradation() throws {
        // Given: Memory pressure simulation
        performanceMonitor.simulateMemoryPressure()

        // When: Operating under memory pressure
        let suggestions = createLargeSuggestionSet(count: 500)
        let processingTime = measureTime {
            viewModel.currentSuggestions = suggestions
        }

        // Then: Should degrade gracefully under memory pressure
        XCTAssertNotNil(viewModel.currentSuggestions, "Should maintain functionality under memory pressure")
        XCTFail("RED PHASE: Memory pressure handling not implemented")
    }

    // MARK: - Scalability Tests

    func testLargeDatasetHandling_ScalesEfficiently() throws {
        // Given: Progressively larger datasets
        let datasetSizes = [10, 50, 100, 200, 500]
        var renderingTimes: [TimeInterval] = []

        // When: Testing scalability with increasing dataset sizes
        for size in datasetSizes {
            let suggestions = createLargeSuggestionSet(count: size)

            let renderingTime = measureTime {
                viewModel.currentSuggestions = suggestions
                let view = AgenticSuggestionView(viewModel: viewModel)
                return view
            }

            renderingTimes.append(renderingTime)
        }

        // Then: Should scale sub-linearly with dataset size
        guard let lastRenderTime = renderingTimes.last,
              let firstRenderTime = renderingTimes.first,
              let lastDatasetSize = datasetSizes.last,
              let firstDatasetSize = datasetSizes.first else {
            XCTFail("Missing performance data")
            return
        }

        let scalingFactor = lastRenderTime / firstRenderTime
        let datasetGrowthFactor = Double(lastDatasetSize) / Double(firstDatasetSize)

        XCTAssertLessThan(scalingFactor, datasetGrowthFactor, "Rendering should scale better than O(n)")
        XCTFail("RED PHASE: Scalability optimization not implemented")
    }

    // MARK: - Battery Impact Tests

    func testExtendedUsage_BatteryImpact() async throws {
        // Given: Extended usage simulation (24 hours compressed to test duration)
        let simulatedHours = 24
        let operationsPerHour = 100

        let batteryBefore = performanceMonitor.currentBatteryLevel()

        // When: Simulating extended usage
        for hour in 0 ..< simulatedHours {
            for operation in 0 ..< operationsPerHour {
                let context = createTestAcquisitionContext()
                try? await viewModel.loadSuggestions(for: context)

                // Simulate time passage (compressed)
                if operation % 10 == 0 {
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms to simulate passage
                }
            }
        }

        let batteryAfter = performanceMonitor.currentBatteryLevel()

        // Then: Should stay within 1% battery impact per 24 hours
        let batteryDrain = batteryBefore - batteryAfter
        XCTAssertLessThan(batteryDrain, 0.01, "Battery drain should be under 1% for 24 hours usage")
        XCTFail("RED PHASE: Battery impact optimization not implemented")
    }

    // MARK: - Helper Methods

    private func measureTime<T>(_ operation: () -> T) -> TimeInterval {
        let startTime = Date()
        _ = operation()
        return Date().timeIntervalSince(startTime)
    }

    private func measureAsyncTime<T>(_ operation: () async throws -> T) async -> TimeInterval {
        let startTime = Date()
        try? await operation()
        return Date().timeIntervalSince(startTime)
    }

    private func measureRenderingPerformance<T>(_ operation: () -> T) -> PerformanceMetrics {
        var times: [TimeInterval] = []

        // Perform multiple renders for statistical analysis
        for _ in 0 ..< 20 {
            let time = measureTime(operation)
            times.append(time)
        }

        times.sort()
        let average = times.reduce(0, +) / Double(times.count)
        let p95Index = Int(Double(times.count) * 0.95)
        let p95 = times[min(p95Index, times.count - 1)]

        return PerformanceMetrics(average: average, p95: p95)
    }

    private func createLargeSuggestionSet(count: Int) -> [DecisionResponse] {
        Array(0 ..< count).map { index in
            DecisionResponse(
                selectedAction: WorkflowAction.placeholder,
                confidence: Double.random(in: 0.3 ... 0.95),
                decisionMode: .assisted,
                reasoning: "Performance test suggestion \(index) with detailed reasoning and multiple factors for comprehensive testing",
                alternativeActions: Array(0 ..< 3).map { _ in
                    AlternativeAction(
                        action: WorkflowAction.placeholder,
                        confidence: Double.random(in: 0.2 ... 0.8)
                    )
                },
                context: createTestAcquisitionContext(),
                timestamp: Date()
            )
        }
    }

    private func createComplexDecisionResponse() -> DecisionResponse {
        DecisionResponse(
            selectedAction: WorkflowAction.placeholder,
            confidence: 0.87,
            decisionMode: .autonomous,
            reasoning: """
            This comprehensive recommendation integrates multiple analysis vectors including acquisition value assessment,
            regulatory compliance validation, historical performance patterns, stakeholder requirements, and risk mitigation strategies.
            The decision incorporates advanced machine learning insights from similar procurement scenarios with 89% similarity scores,
            validated through extensive SHAP explanation analysis covering 25 contributing factors across compliance, efficiency,
            and outcome prediction dimensions.
            """,
            alternativeActions: Array(0 ..< 5).map { index in
                AlternativeAction(
                    action: WorkflowAction.placeholder,
                    confidence: 0.6 + Double(index) * 0.05
                )
            },
            context: createTestAcquisitionContext(),
            timestamp: Date()
        )
    }

    private func createComplexComplianceContext() -> ComplianceContext {
        ComplianceContext(
            farReferences: Array(0 ..< 10).map { index in
                FARReference(
                    section: "52.212-\(index + 1)",
                    title: "Complex Regulation \(index + 1)",
                    url: "https://acquisition.gov/far/52.212-\(index + 1)"
                )
            },
            dfarsReferences: Array(0 ..< 5).map { index in
                DFARSReference(
                    section: "252.212-700\(index + 1)",
                    title: "DFARS Requirement \(index + 1)",
                    url: "https://acquisition.gov/dfars/252.212-700\(index + 1)"
                )
            },
            complianceScore: 0.94,
            riskFactors: [
                "complex procurement value",
                "multi-phase timeline",
                "regulatory complexity",
                "stakeholder coordination",
                "technical requirements",
            ]
        )
    }

    private func createTestAcquisitionContext() -> AcquisitionContext {
        AcquisitionContext(
            acquisitionId: UUID(),
            documentType: .requestForProposal,
            acquisitionValue: Double.random(in: 50000 ... 500_000),
            complexity: TestComplexityLevel(score: Double.random(in: 1.0 ... 4.0), factors: ["technical", "regulatory"]),
            timeConstraints: TestTimeConstraints(
                daysRemaining: Int.random(in: 15 ... 90),
                isUrgent: Bool.random(),
                expectedDuration: TimeInterval.random(in: 1_000_000 ... 10_000_000)
            ),
            regulatoryRequirements: [TestFARClause(clauseNumber: "52.212-1", isCritical: true)],
            historicalSuccess: Double.random(in: 0.5 ... 0.95),
            userProfile: TestUserProfile(experienceLevel: Double.random(in: 0.3 ... 1.0)),
            workflowProgress: Double.random(in: 0.0 ... 1.0),
            completedDocuments: ["requirements"]
        )
    }

    private func createTestDecisionResponse() -> DecisionResponse {
        DecisionResponse(
            selectedAction: WorkflowAction.placeholder,
            confidence: 0.78,
            decisionMode: .assisted,
            reasoning: "Performance test decision response",
            alternativeActions: [],
            context: createTestAcquisitionContext(),
            timestamp: Date()
        )
    }
}

// MARK: - Performance Support Classes

class PerformanceMonitor {
    func currentMemoryUsage() -> UInt64 {
        // RED PHASE: Not implemented
        return 0
    }

    func currentCPUUsage() -> Double {
        // RED PHASE: Not implemented
        return 0.0
    }

    func currentBatteryLevel() -> Double {
        // RED PHASE: Not implemented
        return 1.0
    }

    func forceGarbageCollection() {
        // RED PHASE: Not implemented
    }

    func simulateMemoryPressure() {
        // RED PHASE: Not implemented
    }
}

struct PerformanceMetrics {
    let average: TimeInterval
    let p95: TimeInterval
}

// MARK: - Extended Mock for Performance Testing

extension MockAgenticOrchestrator {
    var simulateOfflineMode = false

    override func makeDecision(_ request: DecisionRequest) async throws -> DecisionResponse {
        if simulateOfflineMode {
            // Simulate offline processing delay
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        return try await super.makeDecision(request)
    }
}
