import Charts
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Main Behavioral Analytics Dashboard View
public struct BehavioralAnalyticsDashboardView: View {
    @State private var viewModel: BehavioralAnalyticsViewModel

    public init(analyticsRepository: any AnalyticsRepositoryProtocol) {
        _viewModel = State(initialValue: BehavioralAnalyticsViewModel(analyticsRepository: analyticsRepository))
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Navigation
                TabNavigationView(
                    selectedTab: viewModel.selectedTab,
                    onTabSelected: { viewModel.selectTab($0) }
                )

                // Content Area
                contentView(for: viewModel.selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Behavioral Analytics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    refreshButton()
                }
            }
            .alert(
                "Error",
                isPresented: .constant(viewModel.error != nil)
            ) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
        }
        .task {
            await viewModel.viewAppeared()
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private func contentView(for tab: DashboardTab) -> some View {
        switch tab {
        case .overview:
            OverviewTabView(dashboardData: viewModel.dashboardData, isLoading: viewModel.isLoading)
        case .learning:
            LearningTabView(dashboardData: viewModel.dashboardData, isLoading: viewModel.isLoading)
        case .timeSaved:
            TimeSavedTabView(dashboardData: viewModel.dashboardData, isLoading: viewModel.isLoading)
        case .patterns:
            PatternsTabView(dashboardData: viewModel.dashboardData, isLoading: viewModel.isLoading)
        case .personalization:
            PersonalizationTabView(dashboardData: viewModel.dashboardData, isLoading: viewModel.isLoading)
        }
    }

    private func refreshButton() -> some View {
        Button(action: {
            Task {
                await viewModel.refresh()
            }
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewModel.isLoading)
    }
}

// MARK: - Tab Navigation

struct TabNavigationView: View {
    let selectedTab: DashboardTab
    let onTabSelected: (DashboardTab) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.displayName,
                        systemImage: tab.systemImage,
                        isSelected: tab == selectedTab,
                        action: { onTabSelected(tab) }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .background(.quaternary)
    }
}

struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)

                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .foregroundColor(isSelected ? .primary : .secondary)
        .padding(.vertical, 8)
    }
}

// MARK: - Tab Content Views

struct OverviewTabView: View {
    let dashboardData: AnalyticsDashboardData?
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading analytics...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let data = dashboardData {
                OverviewContentView(data: data)
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct OverviewContentView: View {
    let data: AnalyticsDashboardData

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 16) {
                AnalyticsMetricCard(
                    title: "Time Saved",
                    value: formatTime(data.overview.totalTimeSaved),
                    trend: .up,
                    changeValue: 15.0
                )

                AnalyticsMetricCard(
                    title: "Learning Progress",
                    value: "\(Int(data.overview.learningProgress * 100))%",
                    trend: .up,
                    changeValue: 8.0
                )

                AnalyticsMetricCard(
                    title: "Personalization",
                    value: "\(Int(data.overview.personalizationLevel * 100))%",
                    trend: .up,
                    changeValue: 5.0
                )

                AnalyticsMetricCard(
                    title: "Automation Success",
                    value: "\(Int(data.overview.automationSuccess * 100))%",
                    trend: .neutral,
                    changeValue: 0.0
                )
            }
            .padding()
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

private struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let changeValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                trendIcon
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            if changeValue != 0 {
                Text("\(changeValue > 0 ? "+" : "")\(changeValue, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(changeValue > 0 ? .green : .red)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shadow(radius: 2, y: 1)
    }

    @ViewBuilder
    private var trendIcon: some View {
        switch trend {
        case .up:
            Image(systemName: "arrow.up")
                .foregroundColor(.green)
        case .down:
            Image(systemName: "arrow.down")
                .foregroundColor(.red)
        case .neutral:
            Image(systemName: "minus")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Other Tab Views (Minimal Implementation)

struct LearningTabView: View {
    let dashboardData: AnalyticsDashboardData?
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading learning analytics...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Text("Learning Analytics")
                        .font(.headline)
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
}

struct TimeSavedTabView: View {
    let dashboardData: AnalyticsDashboardData?
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading time saved analytics...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Text("Time Saved Analytics")
                        .font(.headline)
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
}

struct PatternsTabView: View {
    let dashboardData: AnalyticsDashboardData?
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading pattern analytics...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Text("Pattern Analytics")
                        .font(.headline)
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
}

struct PersonalizationTabView: View {
    let dashboardData: AnalyticsDashboardData?
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading personalization analytics...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Text("Personalization Analytics")
                        .font(.headline)
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
}

// MARK: - Supporting Types

// TrendDirection is defined in BehavioralAnalyticsTypes.swift
