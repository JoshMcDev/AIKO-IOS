import Combine
import Foundation
import os.log

/// Service responsible for tracking, analyzing, and reporting on system metrics (MOPs and MOEs)
public struct MetricsService: Sendable {
    public var recordMOP: @Sendable (MeasureOfPerformance, Double, MetricContext) async throws -> Void
    public var recordMOE: @Sendable (MeasureOfEffectiveness, Double, MetricContext) async throws -> Void
    public var recordMetric: @Sendable (MetricMeasurement) async throws -> Void
    public var getMetricsSummary: @Sendable (DateInterval?) async throws -> MetricsSummary
    public var generateReport: @Sendable (DateInterval, String) async throws -> MetricsReport
    public var analyzeMetrics: @Sendable () async throws -> ([MetricInsight], [MetricRecommendation])
    public var getRealtimeMetrics: @Sendable () async throws -> [String: Double]
    public var subscribeToMetrics: @Sendable ([MetricMeasurement.MetricType]) -> AsyncStream<MetricMeasurement>
}

// MARK: - Live Implementation

public extension MetricsService {
    static let live: Self = {
        let storage = MetricsStorage()
        let analyzer = MetricsAnalyzer()
        let logger = Logger(subsystem: "com.aiko.metrics", category: "MetricsService")

        return Self(
            recordMOP: { mop, value, context in
                let measurement = MetricMeasurement(
                    name: mop.rawValue,
                    type: .mop(mop),
                    values: [MetricValue(value: value, unit: mop.unit)],
                    aggregatedValue: value,
                    score: normalizeScore(value, for: mop),
                    context: context
                )

                await storage.store(measurement)
                logger.debug("Recorded MOP: \(mop.rawValue) = \(value)")

                // Check for threshold violations
                if let insight = analyzer.checkThresholds(measurement) {
                    await storage.storeInsight(insight)
                }
            },

            recordMOE: { moe, value, context in
                let measurement = MetricMeasurement(
                    name: moe.rawValue,
                    type: .moe(moe),
                    values: [MetricValue(value: value, unit: moe.unit)],
                    aggregatedValue: value,
                    score: normalizeScore(value, for: moe),
                    context: context
                )

                await storage.store(measurement)
                logger.debug("Recorded MOE: \(moe.rawValue) = \(value)")

                // Analyze for insights
                if let insight = analyzer.checkThresholds(measurement) {
                    await storage.storeInsight(insight)
                }
            },

            recordMetric: { measurement in
                await storage.store(measurement)
                logger.debug("Recorded metric: \(measurement.name)")

                // Run real-time analysis
                let insights = await analyzer.analyzeMeasurement(measurement)
                for insight in insights {
                    await storage.storeInsight(insight)
                }
            },

            getMetricsSummary: { period in
                let interval = period ?? DateInterval(
                    start: Date().addingTimeInterval(-24 * 60 * 60), // Last 24 hours
                    end: Date()
                )

                let measurements = await storage.getMeasurements(for: interval)

                // Calculate MOP scores
                var mopScores: [MeasureOfPerformance: Double] = [:]
                for mop in MeasureOfPerformance.allCases {
                    let mopMeasurements = measurements.filter {
                        if case let .mop(measure) = $0.type {
                            return measure == mop
                        }
                        return false
                    }
                    if !mopMeasurements.isEmpty {
                        let avgScore = mopMeasurements.map(\.score).reduce(0, +) / Double(mopMeasurements.count)
                        mopScores[mop] = avgScore
                    }
                }

                // Calculate MOE scores
                var moeScores: [MeasureOfEffectiveness: Double] = [:]
                for moe in MeasureOfEffectiveness.allCases {
                    let moeMeasurements = measurements.filter {
                        if case let .moe(measure) = $0.type {
                            return measure == moe
                        }
                        return false
                    }
                    if !moeMeasurements.isEmpty {
                        let avgScore = moeMeasurements.map(\.score).reduce(0, +) / Double(moeMeasurements.count)
                        moeScores[moe] = avgScore
                    }
                }

                // Get insights and recommendations
                let insights = await storage.getInsights(for: interval)
                let recommendations = await analyzer.generateRecommendations(
                    mopScores: mopScores,
                    moeScores: moeScores,
                    insights: insights
                )

                return MetricsSummary(
                    period: interval,
                    mopScores: mopScores,
                    moeScores: moeScores,
                    insights: insights,
                    recommendations: recommendations
                )
            },

            generateReport: { period, title in
                let summary = try await Self.live.getMetricsSummary(period)
                let measurements = await storage.getMeasurements(for: period)

                // Generate trends
                let trends = await analyzer.analyzeTrends(measurements, period: period)

                // Generate comparisons
                let previousPeriod = DateInterval(
                    start: period.start.addingTimeInterval(-period.duration),
                    end: period.start
                )
                let previousMeasurements = await storage.getMeasurements(for: previousPeriod)
                let comparisons = analyzer.generateComparisons(
                    current: measurements,
                    previous: previousMeasurements
                )

                // Generate executive summary
                let executiveSummary = generateExecutiveSummary(
                    summary: summary,
                    trends: trends,
                    comparisons: comparisons
                )

                return MetricsReport(
                    title: title,
                    period: period,
                    summary: summary,
                    detailedMeasurements: measurements,
                    trends: trends,
                    comparisons: comparisons,
                    executiveSummary: executiveSummary
                )
            },

            analyzeMetrics: {
                let last24Hours = DateInterval(
                    start: Date().addingTimeInterval(-24 * 60 * 60),
                    end: Date()
                )

                let measurements = await storage.getMeasurements(for: last24Hours)
                let insights = await analyzer.performComprehensiveAnalysis(measurements)

                let summary = try await Self.live.getMetricsSummary(last24Hours)
                let recommendations = await analyzer.generateRecommendations(
                    mopScores: summary.mopScores,
                    moeScores: summary.moeScores,
                    insights: insights
                )

                return (insights, recommendations)
            },

            getRealtimeMetrics: {
                let last5Minutes = DateInterval(
                    start: Date().addingTimeInterval(-5 * 60),
                    end: Date()
                )

                let measurements = await storage.getMeasurements(for: last5Minutes)
                var realtimeMetrics: [String: Double] = [:]

                // Aggregate recent measurements
                for measurement in measurements {
                    realtimeMetrics[measurement.name] = measurement.aggregatedValue
                }

                // Add system metrics
                realtimeMetrics["active_sessions"] = await Double(storage.getActiveSessions())
                realtimeMetrics["queue_size"] = await Double(storage.getQueueSize())

                return realtimeMetrics
            },

            subscribeToMetrics: { types in
                AsyncStream { continuation in
                    Task {
                        for await measurement in storage.metricsStream.stream {
                            // Filter by requested types
                            if types.isEmpty || types.contains(measurement.type) {
                                continuation.yield(measurement)
                            }
                        }
                    }
                }
            }
        )
    }()
}

// MARK: - Helper Functions

private func normalizeScore(_ value: Double, for type: MetricMeasurement.MetricType) -> Double {
    switch type {
    case let .mop(measure):
        normalizeScore(value, for: measure)
    case let .moe(measure):
        normalizeScore(value, for: measure)
    }
}

private func normalizeScore(_ value: Double, for mop: MeasureOfPerformance) -> Double {
    // Normalize based on expected ranges for each MOP
    switch mop {
    case .responseTime:
        // Lower is better, target < 100ms
        if value <= 100 { return 1.0 }
        if value <= 500 { return 0.8 }
        if value <= 1000 { return 0.6 }
        if value <= 2000 { return 0.4 }
        return 0.2

    case .accuracy, .precision, .recall, .f1Score, .uptime, .availability:
        // Higher is better, already in percentage
        return value / 100.0

    case .errorRate:
        // Lower is better, per thousand
        if value == 0 { return 1.0 }
        if value <= 1 { return 0.9 }
        if value <= 5 { return 0.7 }
        if value <= 10 { return 0.5 }
        return 0.2

    case .cpuUsage, .memoryUsage:
        // Lower is better, percentage
        if value <= 20 { return 1.0 }
        if value <= 40 { return 0.8 }
        if value <= 60 { return 0.6 }
        if value <= 80 { return 0.4 }
        return 0.2

    default:
        // Generic normalization
        return min(value / 100.0, 1.0)
    }
}

private func normalizeScore(_ value: Double, for moe: MeasureOfEffectiveness) -> Double {
    // Normalize based on expected ranges for each MOE
    switch moe {
    case .userSatisfaction:
        // Assuming 1-5 scale
        (value - 1) / 4.0

    case .netPromoterScore:
        // NPS ranges from -100 to 100
        (value + 100) / 200.0

    case .taskCompletionRate, .complianceRate, .adoptionRate, .userRetention:
        // Already in percentage
        value / 100.0

    case .timeSaved:
        // Hours saved, normalize to 0-1 based on expected max of 40 hours
        min(value / 40.0, 1.0)

    default:
        // Generic normalization
        min(value / 100.0, 1.0)
    }
}

private func generateExecutiveSummary(
    summary: MetricsSummary,
    trends: [MetricTrend],
    comparisons _: [MetricComparison]
) -> String {
    var sections: [String] = []

    // Overall performance
    sections.append("## Overall Performance")
    sections.append("- Combined Score: \(String(format: "%.1f%%", summary.combinedScore * 100))")
    sections.append("- Performance (MOPs): \(String(format: "%.1f%%", summary.overallMOPScore * 100))")
    sections.append("- Effectiveness (MOEs): \(String(format: "%.1f%%", summary.overallMOEScore * 100))")

    // Key insights
    if !summary.insights.isEmpty {
        sections.append("\n## Key Insights")
        for insight in summary.insights.prefix(3) {
            sections.append("- \(insight.message)")
        }
    }

    // Significant trends
    let significantTrends = trends.filter { $0.significance > 0.8 }
    if !significantTrends.isEmpty {
        sections.append("\n## Significant Trends")
        for trend in significantTrends.prefix(3) {
            let direction = trend.direction == .increasing ? "↑" : "↓"
            sections.append("- \(trend.metricName): \(direction) \(String(format: "%.1f%%", abs(trend.magnitude)))")
        }
    }

    // Top recommendations
    if !summary.recommendations.isEmpty {
        sections.append("\n## Top Recommendations")
        for rec in summary.recommendations.sorted(by: { $0.priority > $1.priority }).prefix(3) {
            sections.append("- \(rec.title)")
        }
    }

    return sections.joined(separator: "\n")
}

// MARK: - Supporting Types

private actor MetricsStorage {
    private var measurements: [MetricMeasurement] = []
    private var insights: [MetricInsight] = []
    private let maxStorageSize = 10000

    let metricsStream = AsyncStream<MetricMeasurement>.makeStream()

    func store(_ measurement: MetricMeasurement) {
        measurements.append(measurement)
        metricsStream.continuation.yield(measurement)

        // Maintain storage limit
        if measurements.count > maxStorageSize {
            measurements.removeFirst(measurements.count - maxStorageSize)
        }
    }

    func storeInsight(_ insight: MetricInsight) {
        insights.append(insight)

        // Maintain storage limit
        if insights.count > 1000 {
            insights.removeFirst(insights.count - 1000)
        }
    }

    func getMeasurements(for period: DateInterval) -> [MetricMeasurement] {
        measurements.filter { period.contains($0.timestamp) }
    }

    func getInsights(for period: DateInterval) -> [MetricInsight] {
        insights.filter { period.contains($0.timestamp) }
    }

    func getActiveSessions() -> Int {
        // Count unique session IDs in recent measurements
        let recentMeasurements = measurements.filter {
            $0.timestamp > Date().addingTimeInterval(-5 * 60)
        }
        let uniqueSessions = Set(recentMeasurements.map(\.context.sessionId))
        return uniqueSessions.count
    }

    func getQueueSize() -> Int {
        // Simulated queue size
        Int.random(in: 0 ... 100)
    }
}

private struct MetricsAnalyzer {
    private let thresholds: [String: (min: Double, max: Double)] = [
        MeasureOfPerformance.responseTime.rawValue: (0, 500),
        MeasureOfPerformance.errorRate.rawValue: (0, 5),
        MeasureOfPerformance.cpuUsage.rawValue: (0, 80),
        MeasureOfPerformance.memoryUsage.rawValue: (0, 80),
        MeasureOfEffectiveness.userSatisfaction.rawValue: (3.5, 5.0),
        MeasureOfEffectiveness.taskCompletionRate.rawValue: (80, 100),
    ]

    func checkThresholds(_ measurement: MetricMeasurement) -> MetricInsight? {
        guard let (min, max) = thresholds[measurement.name] else { return nil }

        if measurement.aggregatedValue < min {
            return MetricInsight(
                type: .threshold,
                severity: .critical,
                message: "\(measurement.name) below minimum threshold (\(measurement.aggregatedValue) < \(min))",
                affectedMetrics: [measurement.name],
                confidence: 1.0
            )
        } else if measurement.aggregatedValue > max {
            return MetricInsight(
                type: .threshold,
                severity: .warning,
                message: "\(measurement.name) above maximum threshold (\(measurement.aggregatedValue) > \(max))",
                affectedMetrics: [measurement.name],
                confidence: 1.0
            )
        }

        return nil
    }

    func analyzeMeasurement(_ measurement: MetricMeasurement) async -> [MetricInsight] {
        var insights: [MetricInsight] = []

        // Check for anomalies
        if measurement.score < 0.3 {
            insights.append(MetricInsight(
                type: .anomaly,
                severity: .critical,
                message: "Critically low performance detected for \(measurement.name)",
                affectedMetrics: [measurement.name],
                confidence: 0.9
            ))
        }

        // Check for improvements
        if measurement.score > 0.9 {
            insights.append(MetricInsight(
                type: .improvement,
                severity: .positive,
                message: "Excellent performance achieved for \(measurement.name)",
                affectedMetrics: [measurement.name],
                confidence: 0.95
            ))
        }

        return insights
    }

    func analyzeTrends(_ measurements: [MetricMeasurement], period _: DateInterval) async -> [MetricTrend] {
        var trends: [MetricTrend] = []

        // Group measurements by metric name
        let groupedMeasurements = Dictionary(grouping: measurements) { $0.name }

        for (metricName, metricMeasurements) in groupedMeasurements {
            guard metricMeasurements.count >= 3 else { continue }

            // Sort by timestamp
            let sorted = metricMeasurements.sorted { $0.timestamp < $1.timestamp }

            // Calculate trend
            let firstHalf = sorted.prefix(sorted.count / 2)
            let secondHalf = sorted.suffix(sorted.count / 2)

            let firstAvg = firstHalf.map(\.aggregatedValue).reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.map(\.aggregatedValue).reduce(0, +) / Double(secondHalf.count)

            let change = ((secondAvg - firstAvg) / firstAvg) * 100
            let direction: MetricTrend.TrendDirection = if abs(change) < 5 {
                .stable
            } else if change > 0 {
                .increasing
            } else {
                .decreasing
            }

            let dataPoints = sorted.map {
                MetricTrend.TrendDataPoint(timestamp: $0.timestamp, value: $0.aggregatedValue)
            }

            trends.append(MetricTrend(
                metricName: metricName,
                direction: direction,
                magnitude: abs(change),
                significance: min(abs(change) / 20.0, 1.0), // Significance based on magnitude
                dataPoints: dataPoints
            ))
        }

        return trends
    }

    func generateComparisons(current: [MetricMeasurement], previous: [MetricMeasurement]) -> [MetricComparison] {
        var comparisons: [MetricComparison] = []

        // Group by metric name
        let currentGrouped = Dictionary(grouping: current) { $0.name }
        let previousGrouped = Dictionary(grouping: previous) { $0.name }

        for (metricName, currentMeasurements) in currentGrouped {
            guard let previousMeasurements = previousGrouped[metricName],
                  !currentMeasurements.isEmpty,
                  !previousMeasurements.isEmpty else { continue }

            // Use average measurement for comparison
            let currentAvg = currentMeasurements.map(\.aggregatedValue).reduce(0, +) / Double(currentMeasurements.count)
            let previousAvg = previousMeasurements.map(\.aggregatedValue).reduce(0, +) / Double(previousMeasurements.count)

            // Create representative measurements
            guard let currentRep = currentMeasurements.first else { continue }
            let previousRep = MetricMeasurement(
                name: currentRep.name,
                type: currentRep.type,
                values: [MetricValue(value: previousAvg, unit: currentRep.values.first?.unit ?? .count)],
                aggregatedValue: previousAvg,
                score: normalizeScore(previousAvg, for: currentRep.type),
                context: currentRep.context
            )

            let interpretation = interpretComparison(
                metric: metricName,
                current: currentAvg,
                previous: previousAvg
            )

            comparisons.append(MetricComparison(
                type: .periodOverPeriod,
                baseline: previousRep,
                comparison: currentRep,
                interpretation: interpretation
            ))
        }

        return comparisons
    }

    func performComprehensiveAnalysis(_ measurements: [MetricMeasurement]) async -> [MetricInsight] {
        var insights: [MetricInsight] = []

        // Correlation analysis
        let correlations = findCorrelations(measurements)
        for correlation in correlations {
            insights.append(MetricInsight(
                type: .correlation,
                severity: .info,
                message: correlation.message,
                affectedMetrics: correlation.metrics,
                confidence: correlation.confidence
            ))
        }

        // Pattern detection
        let patterns = detectPatterns(measurements)
        for pattern in patterns {
            insights.append(MetricInsight(
                type: .trend,
                severity: pattern.isPositive ? .positive : .warning,
                message: pattern.message,
                affectedMetrics: pattern.metrics,
                confidence: pattern.confidence
            ))
        }

        return insights
    }

    func generateRecommendations(
        mopScores: [MeasureOfPerformance: Double],
        moeScores: [MeasureOfEffectiveness: Double],
        insights: [MetricInsight]
    ) async -> [MetricRecommendation] {
        var recommendations: [MetricRecommendation] = []

        // Performance recommendations
        for (mop, score) in mopScores where score < 0.7 {
            let recommendation = generatePerformanceRecommendation(mop: mop, score: score)
            recommendations.append(recommendation)
        }

        // Effectiveness recommendations
        for (moe, score) in moeScores where score < 0.7 {
            let recommendation = generateEffectivenessRecommendation(moe: moe, score: score)
            recommendations.append(recommendation)
        }

        // Insight-based recommendations
        for insight in insights where insight.severity == .critical {
            if let recommendation = generateInsightRecommendation(insight: insight) {
                recommendations.append(recommendation)
            }
        }

        return recommendations.sorted { $0.priority > $1.priority }
    }

    private func interpretComparison(metric: String, current: Double, previous: Double) -> String {
        let change = ((current - previous) / previous) * 100
        let direction = change > 0 ? "increased" : "decreased"
        let magnitude = abs(change)

        if magnitude < 5 {
            return "\(metric) remained stable"
        } else if magnitude < 20 {
            return "\(metric) \(direction) moderately by \(String(format: "%.1f%%", magnitude))"
        } else {
            return "\(metric) \(direction) significantly by \(String(format: "%.1f%%", magnitude))"
        }
    }

    private func findCorrelations(_ measurements: [MetricMeasurement]) -> [(message: String, metrics: [String], confidence: Double)] {
        // Simplified correlation detection
        var correlations: [(message: String, metrics: [String], confidence: Double)] = []

        // Example: CPU usage and response time correlation
        let cpuMeasurements = measurements.filter { $0.name == MeasureOfPerformance.cpuUsage.rawValue }
        let responseMeasurements = measurements.filter { $0.name == MeasureOfPerformance.responseTime.rawValue }

        if !cpuMeasurements.isEmpty, !responseMeasurements.isEmpty {
            let cpuAvg = cpuMeasurements.map(\.aggregatedValue).reduce(0, +) / Double(cpuMeasurements.count)
            let responseAvg = responseMeasurements.map(\.aggregatedValue).reduce(0, +) / Double(responseMeasurements.count)

            if cpuAvg > 70, responseAvg > 500 {
                correlations.append((
                    message: "High CPU usage correlates with increased response times",
                    metrics: [MeasureOfPerformance.cpuUsage.rawValue, MeasureOfPerformance.responseTime.rawValue],
                    confidence: 0.85
                ))
            }
        }

        return correlations
    }

    private func detectPatterns(_ measurements: [MetricMeasurement]) -> [(message: String, metrics: [String], confidence: Double, isPositive: Bool)] {
        var patterns: [(message: String, metrics: [String], confidence: Double, isPositive: Bool)] = []

        // Group by metric type
        let groupedByType = Dictionary(grouping: measurements) { $0.name }

        for (metricName, metricMeasurements) in groupedByType {
            guard metricMeasurements.count >= 5 else { continue }

            // Check for consistent improvement
            let scores = metricMeasurements.sorted { $0.timestamp < $1.timestamp }.map(\.score)
            let isImproving = scores.enumerated().allSatisfy { index, score in
                index == 0 || score >= scores[index - 1] * 0.95
            }

            if isImproving, let lastScore = scores.last, let firstScore = scores.first, lastScore > firstScore * 1.1 {
                patterns.append((
                    message: "\(metricName) shows consistent improvement pattern",
                    metrics: [metricName],
                    confidence: 0.9,
                    isPositive: true
                ))
            }
        }

        return patterns
    }

    private func generatePerformanceRecommendation(mop: MeasureOfPerformance, score: Double) -> MetricRecommendation {
        let (title, description, actions) = getPerformanceRecommendation(mop: mop, score: score)

        return MetricRecommendation(
            priority: score < 0.5 ? .critical : .high,
            category: .performance,
            title: title,
            description: description,
            expectedImpact: MetricRecommendation.ExpectedImpact(
                metricImprovements: [mop.rawValue: 30.0],
                timeToImpact: 7 * 24 * 60 * 60, // 1 week
                confidence: 0.8
            ),
            requiredActions: actions,
            relatedMetrics: [mop.rawValue]
        )
    }

    private func generateEffectivenessRecommendation(moe: MeasureOfEffectiveness, score: Double) -> MetricRecommendation {
        let (title, description, actions) = getEffectivenessRecommendation(moe: moe, score: score)

        return MetricRecommendation(
            priority: score < 0.5 ? .critical : .high,
            category: .effectiveness,
            title: title,
            description: description,
            expectedImpact: MetricRecommendation.ExpectedImpact(
                metricImprovements: [moe.rawValue: 25.0],
                timeToImpact: 14 * 24 * 60 * 60, // 2 weeks
                confidence: 0.75
            ),
            requiredActions: actions,
            relatedMetrics: [moe.rawValue]
        )
    }

    private func generateInsightRecommendation(insight: MetricInsight) -> MetricRecommendation? {
        guard insight.severity == .critical else { return nil }

        return MetricRecommendation(
            priority: .critical,
            category: .system,
            title: "Address Critical Issue: \(insight.affectedMetrics.first ?? "System")",
            description: insight.message,
            expectedImpact: MetricRecommendation.ExpectedImpact(
                metricImprovements: Dictionary(uniqueKeysWithValues: insight.affectedMetrics.map { ($0, 40.0) }),
                timeToImpact: 3 * 24 * 60 * 60, // 3 days
                confidence: insight.confidence
            ),
            requiredActions: ["Investigate root cause", "Implement immediate fix", "Monitor results"],
            relatedMetrics: insight.affectedMetrics
        )
    }

    private func getPerformanceRecommendation(mop: MeasureOfPerformance, score _: Double) -> (String, String, [String]) {
        switch mop {
        case .responseTime:
            (
                "Optimize Response Time",
                "Response times are above acceptable thresholds. Consider implementing caching, query optimization, or infrastructure scaling.",
                ["Implement response caching", "Optimize database queries", "Scale infrastructure"]
            )
        case .cpuUsage:
            (
                "Reduce CPU Usage",
                "CPU utilization is high. Optimize computational algorithms and consider load balancing.",
                ["Profile CPU-intensive operations", "Implement algorithm optimizations", "Add load balancing"]
            )
        case .errorRate:
            (
                "Reduce Error Rate",
                "Error rate exceeds acceptable limits. Implement better error handling and validation.",
                ["Add input validation", "Implement retry logic", "Enhance error monitoring"]
            )
        default:
            (
                "Improve \(mop.rawValue)",
                "Performance metric \(mop.rawValue) is below target. Investigation and optimization required.",
                ["Analyze root cause", "Implement targeted optimizations", "Monitor improvements"]
            )
        }
    }

    private func getEffectivenessRecommendation(moe: MeasureOfEffectiveness, score _: Double) -> (String, String, [String]) {
        switch moe {
        case .userSatisfaction:
            (
                "Improve User Satisfaction",
                "User satisfaction scores are below target. Focus on UX improvements and feature enhancements.",
                ["Conduct user surveys", "Implement UX improvements", "Add requested features"]
            )
        case .taskCompletionRate:
            (
                "Increase Task Completion Rate",
                "Users are struggling to complete tasks. Simplify workflows and improve guidance.",
                ["Simplify user workflows", "Add contextual help", "Improve error messages"]
            )
        case .adoptionRate:
            (
                "Boost Feature Adoption",
                "Feature adoption is low. Improve discoverability and user onboarding.",
                ["Enhance onboarding flow", "Add feature tutorials", "Improve feature visibility"]
            )
        default:
            (
                "Enhance \(moe.rawValue)",
                "Effectiveness metric \(moe.rawValue) needs improvement. Focus on user value and outcomes.",
                ["Gather user feedback", "Implement improvements", "Measure impact"]
            )
        }
    }
}

// MARK: - Dependency Registration

public extension MetricsService {
    static let liveValue: MetricsService = .live
}
