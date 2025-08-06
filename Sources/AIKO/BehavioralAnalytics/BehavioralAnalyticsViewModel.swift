import Foundation
import SwiftUI

/// ViewModel for Behavioral Analytics Dashboard using @Observable
@Observable
@MainActor
public final class BehavioralAnalyticsViewModel {
    // MARK: - Properties

    private let analyticsRepository: any AnalyticsRepositoryProtocol

    public var selectedTab: DashboardTab = .overview
    public var isLoading = false
    public var error: Error?
    public var dashboardData: AnalyticsDashboardData?

    // MARK: - Initialization

    public init(analyticsRepository: any AnalyticsRepositoryProtocol) {
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - Actions

    public func viewAppeared() async {
        await loadDashboardData()
    }

    public func selectTab(_ tab: DashboardTab) {
        selectedTab = tab
    }

    public func refresh() async {
        await loadDashboardData()
    }

    public func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func loadDashboardData() async {
        isLoading = true
        error = nil

        await analyticsRepository.loadDashboardData()
        dashboardData = analyticsRepository.dashboardData

        isLoading = false
    }
}

/// Dashboard tab enumeration
public enum DashboardTab: String, CaseIterable {
    case overview = "Overview"
    case learning = "Learning"
    case timeSaved = "Time Saved"
    case patterns = "Patterns"
    case personalization = "Personalization"

    public var displayName: String { rawValue }

    public var systemImage: String {
        switch self {
        case .overview: "chart.bar.fill"
        case .learning: "brain.head.profile"
        case .timeSaved: "clock.fill"
        case .patterns: "waveform.path.ecg"
        case .personalization: "person.crop.circle.fill"
        }
    }
}
