import Combine
import Foundation

// MARK: - Core Analytics Data Models

/// Overview metrics for the dashboard summary
public struct OverviewMetrics: Codable, Equatable, Sendable {
    public let totalTimeSaved: Double
    public let learningProgress: Double
    public let personalizationLevel: Double
    public let automationSuccess: Double

    public init(
        totalTimeSaved: Double,
        learningProgress: Double,
        personalizationLevel: Double,
        automationSuccess: Double
    ) {
        self.totalTimeSaved = totalTimeSaved
        self.learningProgress = learningProgress
        self.personalizationLevel = personalizationLevel
        self.automationSuccess = automationSuccess
    }
}

/// Learning effectiveness tracking
public struct LearningEffectivenessMetrics: Codable, Equatable, Sendable {
    public let accuracyTrend: [TimeValuePair]
    public let predictionSuccessRate: Double
    public let learningCurveProgression: [ProgressionPoint]
    public let confidenceLevel: Double

    public init(
        accuracyTrend: [TimeValuePair],
        predictionSuccessRate: Double,
        learningCurveProgression: [ProgressionPoint],
        confidenceLevel: Double
    ) {
        self.accuracyTrend = accuracyTrend
        self.predictionSuccessRate = predictionSuccessRate
        self.learningCurveProgression = learningCurveProgression
        self.confidenceLevel = confidenceLevel
    }
}

/// Time saved metrics and analysis
public struct TimeSavedMetrics: Codable, Equatable, Sendable {
    public let totalTimeSaved: Double
    public let timeSavedByCategory: [String: Double]
    public let automationEfficiency: Double
    public let weeklyTrend: [TimeValuePair]

    public init(
        totalTimeSaved: Double,
        timeSavedByCategory: [String: Double],
        automationEfficiency: Double,
        weeklyTrend: [TimeValuePair]
    ) {
        self.totalTimeSaved = totalTimeSaved
        self.timeSavedByCategory = timeSavedByCategory
        self.automationEfficiency = automationEfficiency
        self.weeklyTrend = weeklyTrend
    }
}

/// Pattern insight metrics
public struct PatternInsightMetrics: Codable, Equatable, Sendable {
    public let detectedPatterns: [DetectedBehaviorPattern]
    public let temporalPatterns: [TemporalPattern]
    public let workflowEfficiency: Double

    public init(
        detectedPatterns: [DetectedBehaviorPattern],
        temporalPatterns: [TemporalPattern],
        workflowEfficiency: Double
    ) {
        self.detectedPatterns = detectedPatterns
        self.temporalPatterns = temporalPatterns
        self.workflowEfficiency = workflowEfficiency
    }
}

/// Personalization metrics
public struct PersonalizationMetrics: Codable, Equatable, Sendable {
    public let adaptationLevel: Double
    public let preferenceAccuracy: Double
    public let customizationEffectiveness: Double

    public init(
        adaptationLevel: Double,
        preferenceAccuracy: Double,
        customizationEffectiveness: Double
    ) {
        self.adaptationLevel = adaptationLevel
        self.preferenceAccuracy = preferenceAccuracy
        self.customizationEffectiveness = customizationEffectiveness
    }
}

/// Complete dashboard data model
public struct AnalyticsDashboardData: Codable, Equatable, Sendable {
    public let overview: OverviewMetrics
    public let learningEffectiveness: LearningEffectivenessMetrics
    public let timeSaved: TimeSavedMetrics
    public let patternInsights: PatternInsightMetrics
    public let personalization: PersonalizationMetrics
    public let lastUpdated: Date

    public init(
        overview: OverviewMetrics,
        learningEffectiveness: LearningEffectivenessMetrics,
        timeSaved: TimeSavedMetrics,
        patternInsights: PatternInsightMetrics,
        personalization: PersonalizationMetrics,
        lastUpdated: Date
    ) {
        self.overview = overview
        self.learningEffectiveness = learningEffectiveness
        self.timeSaved = timeSaved
        self.patternInsights = patternInsights
        self.personalization = personalization
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Supporting Types

/// Time-value pair for trends
public struct TimeValuePair: Codable, Equatable, Sendable {
    public let date: Date
    public let value: Double

    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

/// Learning progression point
public struct ProgressionPoint: Codable, Equatable, Sendable {
    public let phase: String
    public let score: Double

    public init(phase: String, score: Double) {
        self.phase = phase
        self.score = score
    }
}

/// Detected behavior pattern
public struct DetectedBehaviorPattern: Codable, Equatable, Sendable {
    public let name: String
    public let frequency: Double
    public let description: String

    public init(name: String, frequency: Double, description: String) {
        self.name = name
        self.frequency = frequency
        self.description = description
    }
}

/// Temporal pattern analysis
public struct TemporalPattern: Codable, Equatable, Sendable {
    public let timeOfDay: Int
    public let frequency: Double

    public init(timeOfDay: Int, frequency: Double) {
        self.timeOfDay = timeOfDay
        self.frequency = frequency
    }
}
