import XCTest
@testable import AIKO

/// @Observable ViewModel tests for BehavioralAnalyticsViewModel
/// GREEN PHASE: Tests should PASS as the feature has been implemented
final class BehavioralAnalyticsFeatureTests: XCTestCase {

    @MainActor
    func test_viewModel_viewAppeared_loadsData() async {
        // GREEN: Should pass with @Observable implementation
        let mockRepository = MockAnalyticsRepository()
        mockRepository.mockDashboardData = MockAnalyticsData.sampleDashboardData

        let viewModel = BehavioralAnalyticsViewModel(analyticsRepository: mockRepository)

        // Act
        await viewModel.viewAppeared()

        // Assert
        XCTAssertEqual(viewModel.dashboardData, MockAnalyticsData.sampleDashboardData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    @MainActor
    func test_viewModel_tabSelection_updatesState() async {
        // GREEN: Should pass with @Observable implementation
        let mockRepository = MockAnalyticsRepository()
        let viewModel = BehavioralAnalyticsViewModel(analyticsRepository: mockRepository)

        // Act & Assert
        viewModel.selectTab(.learning)
        XCTAssertEqual(viewModel.selectedTab, .learning)

        viewModel.selectTab(.timeSaved)
        XCTAssertEqual(viewModel.selectedTab, .timeSaved)

        viewModel.selectTab(.patterns)
        XCTAssertEqual(viewModel.selectedTab, .patterns)
    }

    @MainActor
    func test_viewModel_refresh_loadsData() async {
        // GREEN: Should pass with @Observable implementation
        let mockRepository = MockAnalyticsRepository()
        mockRepository.mockDashboardData = MockAnalyticsData.sampleDashboardData
        let viewModel = BehavioralAnalyticsViewModel(analyticsRepository: mockRepository)

        // Act
        await viewModel.refresh()

        // Assert
        XCTAssertEqual(viewModel.dashboardData, MockAnalyticsData.sampleDashboardData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    @MainActor
    func test_viewModel_clearError_removesError() async {
        // GREEN: Should pass with @Observable implementation
        let mockRepository = MockAnalyticsRepository()
        let viewModel = BehavioralAnalyticsViewModel(analyticsRepository: mockRepository)

        // Set an error first
        viewModel.error = NSError(domain: "Test", code: 1, userInfo: nil)

        // Act
        viewModel.clearError()

        // Assert
        XCTAssertNil(viewModel.error)
    }

    @MainActor
    func test_viewModel_errorHandling_setsError() async {
        // GREEN: Should pass with @Observable implementation
        let failingRepository = FailingAnalyticsRepository()
        let viewModel = BehavioralAnalyticsViewModel(analyticsRepository: failingRepository)

        // Act
        await viewModel.viewAppeared()

        // Assert
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.isLoading == false)
        XCTAssertNil(viewModel.dashboardData)
    }
}

// MARK: - Mock Services (GREEN: Updated for @Observable pattern with protocol)

@MainActor
class MockAnalyticsRepository: ObservableObject, AnalyticsRepositoryProtocol {
    @Published public private(set) var dashboardData: AnalyticsDashboardData?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?

    var mockDashboardData: AnalyticsDashboardData?
    var shouldFail = false

    init() {
        // Initialize with empty state
    }

    func loadDashboardData() async {
        isLoading = true
        error = nil

        // Simulate a small delay
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        if shouldFail {
            error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
            isLoading = false
            return
        }

        dashboardData = mockDashboardData
        isLoading = false
    }
}

@MainActor
class FailingAnalyticsRepository: ObservableObject, AnalyticsRepositoryProtocol {
    @Published public private(set) var dashboardData: AnalyticsDashboardData?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?

    init() {
        // Initialize with empty state
    }

    func loadDashboardData() async {
        isLoading = true
        error = nil

        // Simulate a small delay
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
        isLoading = false
    }
}

// MARK: - Mock Data (GREEN: Updated for actual types)

struct MockAnalyticsData {
    static let sampleDashboardData = AnalyticsDashboardData(
        overview: OverviewMetrics(
            totalTimeSaved: 7200,
            learningProgress: 0.75,
            personalizationLevel: 0.80,
            automationSuccess: 0.85
        ),
        learningEffectiveness: LearningEffectivenessMetrics(
            accuracyTrend: [
                TimeValuePair(date: Date(), value: 0.75),
                TimeValuePair(date: Date().addingTimeInterval(3600), value: 0.82)
            ],
            predictionSuccessRate: 0.78,
            learningCurveProgression: [
                ProgressionPoint(phase: "Beginner", score: 0.6),
                ProgressionPoint(phase: "Intermediate", score: 0.8)
            ],
            confidenceLevel: 0.85
        ),
        timeSaved: TimeSavedMetrics(
            totalTimeSaved: 7200,
            timeSavedByCategory: ["Document Generation": 3600, "Data Extraction": 2400, "Automation": 1200],
            automationEfficiency: 0.85,
            weeklyTrend: [TimeValuePair(date: Date(), value: 7200)]
        ),
        patternInsights: PatternInsightMetrics(
            detectedPatterns: [
                DetectedBehaviorPattern(name: "Morning Workflow", frequency: 0.85, description: "Consistent morning routine")
            ],
            temporalPatterns: [TemporalPattern(timeOfDay: 9, frequency: 0.9)],
            workflowEfficiency: 0.82
        ),
        personalization: PersonalizationMetrics(
            adaptationLevel: 0.75,
            preferenceAccuracy: 0.85,
            customizationEffectiveness: 0.80
        ),
        lastUpdated: Date()
    )
}
