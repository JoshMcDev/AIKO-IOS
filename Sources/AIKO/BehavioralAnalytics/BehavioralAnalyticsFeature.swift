import CoreData
import Foundation
import SwiftUI

/// @Observable Model for Behavioral Analytics Feature (converted from TCA)
@Observable
@MainActor
public final class BehavioralAnalyticsModel {
    // MARK: - Properties

    public var selectedTab: AnalyticsTab = .overview
    public var dashboardState: DashboardState = .idle
    public var metricsData: AnalyticsDashboardData?
    public var selectedTimeRange: TimeRange = .thirtyDays
    public var isExporting: Bool = false
    public var exportFormat: ExportFormat = .pdf
    public var privacySettings: PrivacySettings = .init()
    public var error: AnalyticsError?

    private let analyticsCollector: AnalyticsCollectorService

    // MARK: - Initialization

    public init(analyticsCollector: AnalyticsCollectorService? = nil) {
        self.analyticsCollector = analyticsCollector ?? AnalyticsCollectorService(
            repository: AnalyticsRepository(
                coreDataStack: BehavioralAnalyticsMockCoreDataStack(),
                userPatternEngine: MockUserPatternEngine(),
                learningLoop: BehavioralAnalyticsMockLearningLoop(),
                agenticOrchestrator: MockAgenticOrchestrator()
            )
        )
    }

    // MARK: - Actions

    public func viewAppeared() async {
        dashboardState = .loading
        error = nil

        if let data = await analyticsCollector.getCurrentAnalytics() {
            metricsData = data
            dashboardState = .loaded(data)
        } else {
            error = .noDataAvailable
            dashboardState = .error(.noDataAvailable)
        }
    }

    public func selectTab(_ tab: AnalyticsTab) {
        selectedTab = tab
    }

    public func changeTimeRange(_ timeRange: TimeRange) async {
        selectedTimeRange = timeRange
        dashboardState = .loading

        if let data = await analyticsCollector.getCurrentAnalytics() {
            metricsData = data
            dashboardState = .loaded(data)
        }
    }

    public func refreshData() async {
        dashboardState = .loading
        error = nil

        if let data = await analyticsCollector.getCurrentAnalytics() {
            metricsData = data
            dashboardState = .loaded(data)
        } else {
            error = .noDataAvailable
            dashboardState = .error(.noDataAvailable)
        }
    }

    public func requestExport(format: ExportFormat) async {
        isExporting = true
        exportFormat = format

        do {
            _ = try await analyticsCollector.exportAnalytics(format: format)
            // Export succeeded
        } catch let error as AnalyticsError {
            self.error = error
        } catch {
            self.error = .exportFailed
        }

        isExporting = false
    }

    public func updatePrivacySettings(_ settings: PrivacySettings) {
        privacySettings = settings
    }

    public func clearError() {
        error = nil
    }
}

// MARK: - Supporting Types

/// Analytics dashboard tabs
public enum AnalyticsTab: String, CaseIterable, Equatable, Sendable {
    case overview
    case learning
    case timeSaved = "time_saved"
    case patterns
    case personalization
    case privacy
    case export

    public var displayName: String {
        switch self {
        case .overview: "Overview"
        case .learning: "Learning"
        case .timeSaved: "Time Saved"
        case .patterns: "Patterns"
        case .personalization: "Personalization"
        case .privacy: "Privacy"
        case .export: "Export"
        }
    }
}

/// Dashboard loading states
public enum DashboardState: Equatable, Sendable {
    case idle
    case loading
    case loaded(AnalyticsDashboardData)
    case error(AnalyticsError)
}

/// Privacy settings
public struct PrivacySettings: Codable, Equatable, Sendable {
    public var analyticsEnabled: Bool = true
    public var dataRetentionDays: Int = 90
    public var shareAnalytics: Bool = false
    public var anonymizeData: Bool = true

    public init(
        analyticsEnabled: Bool = true,
        dataRetentionDays: Int = 90,
        shareAnalytics: Bool = false,
        anonymizeData: Bool = true
    ) {
        self.analyticsEnabled = analyticsEnabled
        self.dataRetentionDays = dataRetentionDays
        self.shareAnalytics = shareAnalytics
        self.anonymizeData = anonymizeData
    }
}

// MARK: - Mock Implementations for Testing

private class BehavioralAnalyticsMockCoreDataStack: CoreDataStackProtocol {
    var viewContext: NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        return context
    }
}

private class MockUserPatternEngine: UserPatternLearningEngineProtocol {}

private class BehavioralAnalyticsMockLearningLoop: LearningLoopProtocol {}

private class MockAgenticOrchestrator: AnalyticsAgenticOrchestratorProtocol {}
