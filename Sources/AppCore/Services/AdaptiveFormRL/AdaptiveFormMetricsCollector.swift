import Foundation

/// Metrics collector for adaptive form performance monitoring
/// Tracks system performance, user satisfaction, and learning effectiveness
public actor AdaptiveFormMetricsCollector {
    // MARK: - Metrics Storage

    private var performanceMetrics: [AdaptivePerformanceMetric] = []
    private var userSatisfactionMetrics: [UserSatisfactionMetric] = []
    private var learningEffectivenessMetrics: [LearningEffectivenessMetric] = []
    private var systemHealthMetrics: [SystemHealthMetric] = []

    // MARK: - Configuration

    private let maxMetricsRetention: Int = 10000
    private let performanceThreshold: TimeInterval = 0.2 // 200ms
    private let acceptanceRateThreshold: Double = 0.85 // 85%

    // MARK: - Rolling Averages

    private var rollingPerformanceWindow: [TimeInterval] = []
    private var rollingAcceptanceWindow: [Double] = []
    private let windowSize: Int = 100

    // MARK: - Public Interface

    /// Record performance metric for form population
    public func recordPerformance(_ duration: TimeInterval) {
        let metric = AdaptivePerformanceMetric(
            duration: duration,
            timestamp: Date(),
            withinThreshold: duration <= performanceThreshold
        )

        performanceMetrics.append(metric)
        updateRollingPerformance(duration)
        trimMetricsIfNeeded()
    }

    /// Record user satisfaction metric
    public func recordUserSatisfaction(
        acceptanceRate: Double,
        modificationCount: Int,
        timeToComplete: TimeInterval,
        context: ContextCategory
    ) {
        let metric = UserSatisfactionMetric(
            acceptanceRate: acceptanceRate,
            modificationCount: modificationCount,
            timeToComplete: timeToComplete,
            context: context,
            timestamp: Date()
        )

        userSatisfactionMetrics.append(metric)
        updateRollingAcceptance(acceptanceRate)
        trimMetricsIfNeeded()
    }

    /// Record learning effectiveness metric
    public func recordLearningEffectiveness(
        qTableSize: Int,
        explorationRate: Double,
        convergenceIndicator: Double,
        catastrophicForgettingScore: Double
    ) {
        let metric = LearningEffectivenessMetric(
            qTableSize: qTableSize,
            explorationRate: explorationRate,
            convergenceIndicator: convergenceIndicator,
            catastrophicForgettingScore: catastrophicForgettingScore,
            timestamp: Date()
        )

        learningEffectivenessMetrics.append(metric)
        trimMetricsIfNeeded()
    }

    /// Record system health metric
    public func recordSystemHealth(
        memoryUsage: Double,
        cpuUsage: Double,
        errorCount: Int,
        fallbackRate: Double
    ) {
        let metric = SystemHealthMetric(
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            errorCount: errorCount,
            fallbackRate: fallbackRate,
            timestamp: Date()
        )

        systemHealthMetrics.append(metric)
        trimMetricsIfNeeded()
    }

    /// Get comprehensive performance summary
    public func getPerformanceSummary() -> AdaptiveMetricsSummary {
        let avgPerformance = calculateAveragePerformance()
        let avgAcceptanceRate = calculateAverageAcceptanceRate()
        let systemHealth = getCurrentSystemHealth()
        let learningProgress = getCurrentLearningProgress()

        return AdaptiveMetricsSummary(
            averagePerformanceMs: avgPerformance * 1000,
            averageAcceptanceRate: avgAcceptanceRate,
            systemHealth: systemHealth,
            learningProgress: learningProgress,
            meetsPerformanceTarget: avgPerformance <= performanceThreshold,
            meetsAcceptanceTarget: avgAcceptanceRate >= acceptanceRateThreshold,
            totalSessions: performanceMetrics.count,
            dataCollectionPeriod: getDataCollectionPeriod()
        )
    }

    /// Get context-specific metrics
    public func getContextMetrics(for context: ContextCategory) -> ContextSpecificMetrics {
        let contextMetrics = userSatisfactionMetrics.filter { $0.context == context }

        let avgAcceptance = contextMetrics.map(\.acceptanceRate).reduce(0, +) / Double(max(1, contextMetrics.count))
        let avgModifications = contextMetrics.map(\.modificationCount).reduce(0, +) / max(1, contextMetrics.count)
        let avgCompletion = contextMetrics.map(\.timeToComplete).reduce(0, +) / Double(max(1, contextMetrics.count))

        return ContextSpecificMetrics(
            context: context,
            averageAcceptanceRate: avgAcceptance,
            averageModificationCount: Double(avgModifications),
            averageCompletionTime: avgCompletion,
            sessionCount: contextMetrics.count
        )
    }

    /// Get learning convergence data
    public func getLearningConvergence() -> LearningConvergenceData {
        let recentMetrics = learningEffectivenessMetrics.suffix(50)

        let convergenceTrend = recentMetrics.map(\.convergenceIndicator)
        let explorationTrend = recentMetrics.map(\.explorationRate)
        let forgettingTrend = recentMetrics.map(\.catastrophicForgettingScore)

        return LearningConvergenceData(
            convergenceTrend: convergenceTrend,
            explorationTrend: explorationTrend,
            catastrophicForgettingTrend: forgettingTrend,
            isConverging: isSystemConverging(convergenceTrend),
            recommendedActions: generateRecommendedActions(convergenceTrend, explorationTrend, forgettingTrend)
        )
    }

    /// Export metrics for analysis
    public func exportMetrics() -> MetricsExport {
        MetricsExport(
            performanceMetrics: performanceMetrics,
            userSatisfactionMetrics: userSatisfactionMetrics,
            learningEffectivenessMetrics: learningEffectivenessMetrics,
            systemHealthMetrics: systemHealthMetrics,
            exportDate: Date(),
            summary: getPerformanceSummary()
        )
    }

    /// Reset all metrics (for testing or fresh starts)
    public func resetMetrics() {
        performanceMetrics.removeAll()
        userSatisfactionMetrics.removeAll()
        learningEffectivenessMetrics.removeAll()
        systemHealthMetrics.removeAll()
        rollingPerformanceWindow.removeAll()
        rollingAcceptanceWindow.removeAll()
    }

    // MARK: - Private Methods

    private func updateRollingPerformance(_ duration: TimeInterval) {
        rollingPerformanceWindow.append(duration)
        if rollingPerformanceWindow.count > windowSize {
            rollingPerformanceWindow.removeFirst()
        }
    }

    private func updateRollingAcceptance(_ acceptanceRate: Double) {
        rollingAcceptanceWindow.append(acceptanceRate)
        if rollingAcceptanceWindow.count > windowSize {
            rollingAcceptanceWindow.removeFirst()
        }
    }

    private func calculateAveragePerformance() -> TimeInterval {
        guard !rollingPerformanceWindow.isEmpty else { return 0.0 }
        return rollingPerformanceWindow.reduce(0, +) / Double(rollingPerformanceWindow.count)
    }

    private func calculateAverageAcceptanceRate() -> Double {
        guard !rollingAcceptanceWindow.isEmpty else { return 0.0 }
        return rollingAcceptanceWindow.reduce(0, +) / Double(rollingAcceptanceWindow.count)
    }

    private func getCurrentSystemHealth() -> SystemHealthSummary {
        guard let latestHealth = systemHealthMetrics.last else {
            return SystemHealthSummary(
                memoryUsage: 0.0,
                cpuUsage: 0.0,
                errorRate: 0.0,
                fallbackRate: 0.0,
                healthScore: 1.0
            )
        }

        let healthScore = calculateHealthScore(latestHealth)

        return SystemHealthSummary(
            memoryUsage: latestHealth.memoryUsage,
            cpuUsage: latestHealth.cpuUsage,
            errorRate: Double(latestHealth.errorCount) / 100.0, // Normalized
            fallbackRate: latestHealth.fallbackRate,
            healthScore: healthScore
        )
    }

    private func getCurrentLearningProgress() -> LearningProgressSummary {
        guard let latestLearning = learningEffectivenessMetrics.last else {
            return LearningProgressSummary(
                qTableGrowth: 0.0,
                explorationDecay: 0.0,
                convergenceRate: 0.0,
                stabilityScore: 0.0
            )
        }

        let qTableGrowth = calculateQTableGrowthRate()
        let convergenceRate = latestLearning.convergenceIndicator
        let stabilityScore = 1.0 - latestLearning.catastrophicForgettingScore

        return LearningProgressSummary(
            qTableGrowth: qTableGrowth,
            explorationDecay: latestLearning.explorationRate,
            convergenceRate: convergenceRate,
            stabilityScore: stabilityScore
        )
    }

    private func calculateHealthScore(_ metric: SystemHealthMetric) -> Double {
        let memoryScore = max(0.0, 1.0 - metric.memoryUsage / 100.0)
        let cpuScore = max(0.0, 1.0 - metric.cpuUsage / 100.0)
        let errorScore = max(0.0, 1.0 - Double(metric.errorCount) / 10.0)
        let fallbackScore = max(0.0, 1.0 - metric.fallbackRate)

        return (memoryScore + cpuScore + errorScore + fallbackScore) / 4.0
    }

    private func calculateQTableGrowthRate() -> Double {
        guard learningEffectivenessMetrics.count >= 2 else { return 0.0 }

        let recent = learningEffectivenessMetrics.suffix(10)
        if recent.count < 2 { return 0.0 }

        let oldSize = Double(recent.first?.qTableSize ?? 0)
        let newSize = Double(recent.last?.qTableSize ?? 0)

        return oldSize > 0 ? (newSize - oldSize) / oldSize : 0.0
    }

    private func isSystemConverging(_ convergenceTrend: [Double]) -> Bool {
        guard convergenceTrend.count >= 10 else { return false }

        let recent = convergenceTrend.suffix(10)
        let slope = calculateSlope(Array(recent))

        return slope > -0.01 && recent.last ?? 0.0 > 0.8
    }

    private func calculateSlope(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }

        let n = Double(values.count)
        let xSum = (0 ..< values.count).reduce(0, +)
        let ySum = values.reduce(0, +)
        let xySum = zip(0 ..< values.count, values).map { Double($0.0) * $0.1 }.reduce(0, +)
        let x2Sum = (0 ..< values.count).map { Double($0 * $0) }.reduce(0, +)

        let slope = (n * xySum - Double(xSum) * ySum) / (n * x2Sum - Double(xSum * xSum))
        return slope
    }

    private func generateRecommendedActions(
        _ convergence: [Double],
        _ exploration: [Double],
        _ forgetting: [Double]
    ) -> [String] {
        var recommendations: [String] = []

        if let lastConvergence = convergence.last, lastConvergence < 0.7 {
            recommendations.append("Consider adjusting learning rate or reward function")
        }

        if let lastExploration = exploration.last, lastExploration > 0.2 {
            recommendations.append("Exploration rate may be too high for current learning stage")
        }

        if let lastForgetting = forgetting.last, lastForgetting > 0.1 {
            recommendations.append("Implement stronger catastrophic forgetting prevention")
        }

        if recommendations.isEmpty {
            recommendations.append("System performance is within acceptable parameters")
        }

        return recommendations
    }

    private func getDataCollectionPeriod() -> String {
        guard let earliest = performanceMetrics.first?.timestamp,
              let latest = performanceMetrics.last?.timestamp
        else {
            return "No data collected"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short

        return "\(formatter.string(from: earliest)) to \(formatter.string(from: latest))"
    }

    private func trimMetricsIfNeeded() {
        if performanceMetrics.count > maxMetricsRetention {
            performanceMetrics = Array(performanceMetrics.suffix(maxMetricsRetention / 2))
        }

        if userSatisfactionMetrics.count > maxMetricsRetention {
            userSatisfactionMetrics = Array(userSatisfactionMetrics.suffix(maxMetricsRetention / 2))
        }

        if learningEffectivenessMetrics.count > maxMetricsRetention {
            learningEffectivenessMetrics = Array(learningEffectivenessMetrics.suffix(maxMetricsRetention / 2))
        }

        if systemHealthMetrics.count > maxMetricsRetention {
            systemHealthMetrics = Array(systemHealthMetrics.suffix(maxMetricsRetention / 2))
        }
    }
}

// MARK: - Supporting Types

public struct AdaptivePerformanceMetric {
    public let duration: TimeInterval
    public let timestamp: Date
    public let withinThreshold: Bool

    public init(duration: TimeInterval, timestamp: Date, withinThreshold: Bool) {
        self.duration = duration
        self.timestamp = timestamp
        self.withinThreshold = withinThreshold
    }
}

public struct UserSatisfactionMetric {
    public let acceptanceRate: Double
    public let modificationCount: Int
    public let timeToComplete: TimeInterval
    public let context: ContextCategory
    public let timestamp: Date

    public init(acceptanceRate: Double, modificationCount: Int, timeToComplete: TimeInterval, context: ContextCategory, timestamp: Date) {
        self.acceptanceRate = acceptanceRate
        self.modificationCount = modificationCount
        self.timeToComplete = timeToComplete
        self.context = context
        self.timestamp = timestamp
    }
}

public struct LearningEffectivenessMetric {
    public let qTableSize: Int
    public let explorationRate: Double
    public let convergenceIndicator: Double
    public let catastrophicForgettingScore: Double
    public let timestamp: Date

    public init(qTableSize: Int, explorationRate: Double, convergenceIndicator: Double, catastrophicForgettingScore: Double, timestamp: Date) {
        self.qTableSize = qTableSize
        self.explorationRate = explorationRate
        self.convergenceIndicator = convergenceIndicator
        self.catastrophicForgettingScore = catastrophicForgettingScore
        self.timestamp = timestamp
    }
}

public struct SystemHealthMetric {
    public let memoryUsage: Double
    public let cpuUsage: Double
    public let errorCount: Int
    public let fallbackRate: Double
    public let timestamp: Date

    public init(memoryUsage: Double, cpuUsage: Double, errorCount: Int, fallbackRate: Double, timestamp: Date) {
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.errorCount = errorCount
        self.fallbackRate = fallbackRate
        self.timestamp = timestamp
    }
}

public struct AdaptiveMetricsSummary {
    public let averagePerformanceMs: Double
    public let averageAcceptanceRate: Double
    public let systemHealth: SystemHealthSummary
    public let learningProgress: LearningProgressSummary
    public let meetsPerformanceTarget: Bool
    public let meetsAcceptanceTarget: Bool
    public let totalSessions: Int
    public let dataCollectionPeriod: String

    public init(averagePerformanceMs: Double, averageAcceptanceRate: Double, systemHealth: SystemHealthSummary, learningProgress: LearningProgressSummary, meetsPerformanceTarget: Bool, meetsAcceptanceTarget: Bool, totalSessions: Int, dataCollectionPeriod: String) {
        self.averagePerformanceMs = averagePerformanceMs
        self.averageAcceptanceRate = averageAcceptanceRate
        self.systemHealth = systemHealth
        self.learningProgress = learningProgress
        self.meetsPerformanceTarget = meetsPerformanceTarget
        self.meetsAcceptanceTarget = meetsAcceptanceTarget
        self.totalSessions = totalSessions
        self.dataCollectionPeriod = dataCollectionPeriod
    }
}

public struct SystemHealthSummary {
    public let memoryUsage: Double
    public let cpuUsage: Double
    public let errorRate: Double
    public let fallbackRate: Double
    public let healthScore: Double

    public init(memoryUsage: Double, cpuUsage: Double, errorRate: Double, fallbackRate: Double, healthScore: Double) {
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.errorRate = errorRate
        self.fallbackRate = fallbackRate
        self.healthScore = healthScore
    }
}

public struct LearningProgressSummary {
    public let qTableGrowth: Double
    public let explorationDecay: Double
    public let convergenceRate: Double
    public let stabilityScore: Double

    public init(qTableGrowth: Double, explorationDecay: Double, convergenceRate: Double, stabilityScore: Double) {
        self.qTableGrowth = qTableGrowth
        self.explorationDecay = explorationDecay
        self.convergenceRate = convergenceRate
        self.stabilityScore = stabilityScore
    }
}

public struct ContextSpecificMetrics {
    public let context: ContextCategory
    public let averageAcceptanceRate: Double
    public let averageModificationCount: Double
    public let averageCompletionTime: TimeInterval
    public let sessionCount: Int

    public init(context: ContextCategory, averageAcceptanceRate: Double, averageModificationCount: Double, averageCompletionTime: TimeInterval, sessionCount: Int) {
        self.context = context
        self.averageAcceptanceRate = averageAcceptanceRate
        self.averageModificationCount = averageModificationCount
        self.averageCompletionTime = averageCompletionTime
        self.sessionCount = sessionCount
    }
}

public struct LearningConvergenceData {
    public let convergenceTrend: [Double]
    public let explorationTrend: [Double]
    public let catastrophicForgettingTrend: [Double]
    public let isConverging: Bool
    public let recommendedActions: [String]

    public init(convergenceTrend: [Double], explorationTrend: [Double], catastrophicForgettingTrend: [Double], isConverging: Bool, recommendedActions: [String]) {
        self.convergenceTrend = convergenceTrend
        self.explorationTrend = explorationTrend
        self.catastrophicForgettingTrend = catastrophicForgettingTrend
        self.isConverging = isConverging
        self.recommendedActions = recommendedActions
    }
}

public struct MetricsExport {
    public let performanceMetrics: [AdaptivePerformanceMetric]
    public let userSatisfactionMetrics: [UserSatisfactionMetric]
    public let learningEffectivenessMetrics: [LearningEffectivenessMetric]
    public let systemHealthMetrics: [SystemHealthMetric]
    public let exportDate: Date
    public let summary: AdaptiveMetricsSummary

    public init(performanceMetrics: [AdaptivePerformanceMetric], userSatisfactionMetrics: [UserSatisfactionMetric], learningEffectivenessMetrics: [LearningEffectivenessMetric], systemHealthMetrics: [SystemHealthMetric], exportDate: Date, summary: AdaptiveMetricsSummary) {
        self.performanceMetrics = performanceMetrics
        self.userSatisfactionMetrics = userSatisfactionMetrics
        self.learningEffectivenessMetrics = learningEffectivenessMetrics
        self.systemHealthMetrics = systemHealthMetrics
        self.exportDate = exportDate
        self.summary = summary
    }
}
