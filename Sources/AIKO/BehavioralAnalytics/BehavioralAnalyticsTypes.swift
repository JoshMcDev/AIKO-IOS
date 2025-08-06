import Foundation
import SwiftUI

// MARK: - Behavioral Analytics Types

/// Summary metric for the dashboard
public struct SummaryMetric: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let value: Double
    public let unit: String
    public let trend: TrendDirection
    public let changeValue: Double

    public init(title: String, value: Double, unit: String = "", trend: TrendDirection = .neutral, changeValue: Double = 0) {
        self.title = title
        self.value = value
        self.unit = unit
        self.trend = trend
        self.changeValue = changeValue
    }
}

/// Trend direction for metrics
public enum TrendDirection: String, CaseIterable {
    case up
    case down
    case neutral
}

/// Chart data point
public struct ChartDataPoint: Identifiable, Hashable {
    public let id = UUID()
    public let date: Date
    public let value: Double
    public let category: String

    public init(date: Date, value: Double, category: String = "default") {
        self.date = date
        self.value = value
        self.category = category
    }
}

/// Behavioral insight
public struct BehavioralInsight: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let confidence: Double
    public let actionable: Bool

    public init(title: String, description: String, confidence: Double, actionable: Bool = true) {
        self.title = title
        self.description = description
        self.confidence = confidence
        self.actionable = actionable
    }
}

/// Time range options
public enum TimeRange: String, CaseIterable, Codable, Sendable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case oneYear = "1Y"

    public var displayName: String {
        switch self {
        case .sevenDays: "Last 7 days"
        case .thirtyDays: "Last 30 days"
        case .ninetyDays: "Last 90 days"
        case .oneYear: "Last year"
        }
    }

    public var days: Int {
        switch self {
        case .sevenDays: 7
        case .thirtyDays: 30
        case .ninetyDays: 90
        case .oneYear: 365
        }
    }
}

/// Chart metric types
public enum ChartMetricType: String, CaseIterable {
    case focusTime = "focus_time"
    case completionRate = "completion_rate"
    case learningProgress = "learning_progress"
    case workflowEfficiency = "workflow_efficiency"

    public var displayName: String {
        switch self {
        case .focusTime: "Focus Time"
        case .completionRate: "Completion Rate"
        case .learningProgress: "Learning Progress"
        case .workflowEfficiency: "Workflow Efficiency"
        }
    }
}

/// Export format options
public enum ExportFormat: String, CaseIterable, Codable, Sendable {
    case pdf
    case csv
    case json

    public var displayName: String {
        switch self {
        case .pdf: "PDF"
        case .csv: "CSV"
        case .json: "JSON"
        }
    }

    public var fileExtension: String {
        rawValue
    }
}
