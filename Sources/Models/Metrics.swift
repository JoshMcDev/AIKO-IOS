import Foundation

// MARK: - Measures of Performance (MOPs)

/// Technical metrics that measure how well the system performs its functions
public enum MeasureOfPerformance: String, CaseIterable, Codable {
    // Speed & Efficiency
    case responseTime = "response_time"
    case processingSpeed = "processing_speed"
    case throughput
    case latency

    // Resource Utilization
    case cpuUsage = "cpu_usage"
    case memoryUsage = "memory_usage"
    case diskUsage = "disk_usage"
    case networkBandwidth = "network_bandwidth"

    // Accuracy & Quality
    case accuracy
    case precision
    case recall
    case f1Score = "f1_score"

    // Reliability
    case uptime
    case errorRate = "error_rate"
    case recoveryTime = "recovery_time"
    case availability

    // Scalability
    case concurrentUsers = "concurrent_users"
    case transactionRate = "transaction_rate"
    case queueLength = "queue_length"
    case loadCapacity = "load_capacity"

    public var unit: MetricUnit {
        switch self {
        case .responseTime, .processingSpeed, .latency, .recoveryTime:
            .milliseconds
        case .throughput, .transactionRate:
            .perSecond
        case .cpuUsage, .memoryUsage, .diskUsage, .accuracy, .precision, .recall, .f1Score, .uptime, .availability:
            .percentage
        case .networkBandwidth:
            .megabitsPerSecond
        case .errorRate:
            .perThousand
        case .concurrentUsers, .queueLength:
            .count
        case .loadCapacity:
            .percentage
        }
    }

    public var category: MOPCategory {
        switch self {
        case .responseTime, .processingSpeed, .throughput, .latency:
            .speed
        case .cpuUsage, .memoryUsage, .diskUsage, .networkBandwidth:
            .resources
        case .accuracy, .precision, .recall, .f1Score:
            .quality
        case .uptime, .errorRate, .recoveryTime, .availability:
            .reliability
        case .concurrentUsers, .transactionRate, .queueLength, .loadCapacity:
            .scalability
        }
    }
}

public enum MOPCategory: String, CaseIterable, Codable {
    case speed
    case resources
    case quality
    case reliability
    case scalability
}

// MARK: - Measures of Effectiveness (MOEs)

/// Business/mission metrics that measure how well the system achieves its intended outcomes
public enum MeasureOfEffectiveness: String, CaseIterable, Codable {
    // User Satisfaction
    case userSatisfaction = "user_satisfaction"
    case netPromoterScore = "net_promoter_score"
    case customerEffortScore = "customer_effort_score"
    case taskCompletionRate = "task_completion_rate"

    // Business Value
    case timeSaved = "time_saved"
    case costReduction = "cost_reduction"
    case revenueIncrease = "revenue_increase"
    case processEfficiency = "process_efficiency"

    // Mission Success
    case goalAchievement = "goal_achievement"
    case complianceRate = "compliance_rate"
    case decisionQuality = "decision_quality"
    case missionReadiness = "mission_readiness"

    // User Adoption
    case adoptionRate = "adoption_rate"
    case activeUsers = "active_users"
    case featureUtilization = "feature_utilization"
    case userRetention = "user_retention"

    // Knowledge & Learning
    case learningRate = "learning_rate"
    case knowledgeRetention = "knowledge_retention"
    case insightGeneration = "insight_generation"
    case adaptationSpeed = "adaptation_speed"

    public var unit: MetricUnit {
        switch self {
        case .userSatisfaction, .netPromoterScore, .customerEffortScore:
            .score
        case .taskCompletionRate, .costReduction, .revenueIncrease, .processEfficiency,
             .goalAchievement, .complianceRate, .decisionQuality, .missionReadiness,
             .adoptionRate, .featureUtilization, .userRetention, .learningRate,
             .knowledgeRetention, .adaptationSpeed:
            .percentage
        case .timeSaved:
            .hours
        case .activeUsers:
            .count
        case .insightGeneration:
            .perDay
        }
    }

    public var category: MOECategory {
        switch self {
        case .userSatisfaction, .netPromoterScore, .customerEffortScore, .taskCompletionRate:
            .userExperience
        case .timeSaved, .costReduction, .revenueIncrease, .processEfficiency:
            .businessValue
        case .goalAchievement, .complianceRate, .decisionQuality, .missionReadiness:
            .missionSuccess
        case .adoptionRate, .activeUsers, .featureUtilization, .userRetention:
            .adoption
        case .learningRate, .knowledgeRetention, .insightGeneration, .adaptationSpeed:
            .learning
        }
    }
}

public enum MOECategory: String, CaseIterable, Codable {
    case userExperience
    case businessValue
    case missionSuccess
    case adoption
    case learning
}

// MARK: - Metric Types

public enum MetricUnit: String, Codable {
    case milliseconds
    case seconds
    case minutes
    case hours
    case percentage
    case count
    case perSecond
    case perMinute
    case perHour
    case perDay
    case perThousand
    case megabitsPerSecond
    case score
    case dollars
}

/// A recorded metric value
public struct MetricValue: Identifiable, Equatable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let value: Double
    public let unit: MetricUnit
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        value: Double,
        unit: MetricUnit,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.unit = unit
        self.metadata = metadata
    }

    /// Normalized value between 0 and 1 for scoring
    public func normalizedValue(min: Double, max: Double) -> Double {
        guard max > min else { return 0 }
        return (value - min) / (max - min)
    }
}

/// A collection of metrics for a specific measurement
public struct MetricMeasurement: Identifiable, Equatable, Codable {
    public let id: UUID
    public let name: String
    public let type: MetricType
    public let timestamp: Date
    public let values: [MetricValue]
    public let aggregatedValue: Double
    public let score: Double // 0-1 normalized score
    public let context: MetricContext

    public enum MetricType: Equatable, Codable {
        case mop(MeasureOfPerformance)
        case moe(MeasureOfEffectiveness)

        public var name: String {
            switch self {
            case let .mop(measure):
                measure.rawValue
            case let .moe(measure):
                measure.rawValue
            }
        }

        public var unit: MetricUnit {
            switch self {
            case let .mop(measure):
                measure.unit
            case let .moe(measure):
                measure.unit
            }
        }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        type: MetricType,
        timestamp: Date = Date(),
        values: [MetricValue],
        aggregatedValue: Double,
        score: Double,
        context: MetricContext
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.timestamp = timestamp
        self.values = values
        self.aggregatedValue = aggregatedValue
        self.score = min(max(score, 0), 1) // Ensure 0-1 range
        self.context = context
    }
}

/// Context for a metric measurement
public struct MetricContext: Equatable, Codable {
    public let sessionId: String
    public let userId: String
    public let feature: String
    public let action: String?
    public let environment: String
    public let tags: Set<String>

    public init(
        sessionId: String,
        userId: String,
        feature: String,
        action: String? = nil,
        environment: String = "production",
        tags: Set<String> = []
    ) {
        self.sessionId = sessionId
        self.userId = userId
        self.feature = feature
        self.action = action
        self.environment = environment
        self.tags = tags
    }
}

/// Summary of metrics over a time period
public struct MetricsSummary: Equatable, Codable {
    public let period: DateInterval
    public let mopScores: [MeasureOfPerformance: Double]
    public let moeScores: [MeasureOfEffectiveness: Double]
    public let overallMOPScore: Double
    public let overallMOEScore: Double
    public let combinedScore: Double
    public let insights: [MetricInsight]
    public let recommendations: [MetricRecommendation]

    public init(
        period: DateInterval,
        mopScores: [MeasureOfPerformance: Double],
        moeScores: [MeasureOfEffectiveness: Double],
        insights: [MetricInsight] = [],
        recommendations: [MetricRecommendation] = []
    ) {
        self.period = period
        self.mopScores = mopScores
        self.moeScores = moeScores

        // Calculate overall scores
        let mopSum = mopScores.values.reduce(0, +)
        let mopCount = Double(mopScores.count)
        overallMOPScore = mopCount > 0 ? mopSum / mopCount : 0

        let moeSum = moeScores.values.reduce(0, +)
        let moeCount = Double(moeScores.count)
        overallMOEScore = moeCount > 0 ? moeSum / moeCount : 0

        // Combined score with 60% weight on effectiveness, 40% on performance
        combinedScore = (overallMOEScore * 0.6) + (overallMOPScore * 0.4)

        self.insights = insights
        self.recommendations = recommendations
    }
}

/// An insight derived from metrics analysis
public struct MetricInsight: Identifiable, Equatable, Codable {
    public let id: UUID
    public let type: InsightType
    public let severity: InsightSeverity
    public let message: String
    public let affectedMetrics: [String]
    public let confidence: Double
    public let timestamp: Date

    public enum InsightType: String, Codable {
        case anomaly
        case trend
        case correlation
        case threshold
        case improvement
        case degradation
    }

    public enum InsightSeverity: String, Codable {
        case info
        case warning
        case critical
        case positive
    }

    public init(
        id: UUID = UUID(),
        type: InsightType,
        severity: InsightSeverity,
        message: String,
        affectedMetrics: [String],
        confidence: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.message = message
        self.affectedMetrics = affectedMetrics
        self.confidence = min(max(confidence, 0), 1)
        self.timestamp = timestamp
    }
}

/// A recommendation based on metrics analysis
public struct MetricRecommendation: Identifiable, Equatable, Codable {
    public let id: UUID
    public let priority: RecommendationPriority
    public let category: RecommendationCategory
    public let title: String
    public let description: String
    public let expectedImpact: ExpectedImpact
    public let requiredActions: [String]
    public let relatedMetrics: [String]

    public enum RecommendationPriority: Int, Codable, Comparable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3

        public static func < (lhs: RecommendationPriority, rhs: RecommendationPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public enum RecommendationCategory: String, Codable {
        case performance
        case effectiveness
        case cost
        case user
        case system
    }

    public struct ExpectedImpact: Equatable, Codable {
        public let metricImprovements: [String: Double] // Metric name to expected % improvement
        public let timeToImpact: TimeInterval
        public let confidence: Double

        public init(
            metricImprovements: [String: Double],
            timeToImpact: TimeInterval,
            confidence: Double
        ) {
            self.metricImprovements = metricImprovements
            self.timeToImpact = timeToImpact
            self.confidence = min(max(confidence, 0), 1)
        }
    }

    public init(
        id: UUID = UUID(),
        priority: RecommendationPriority,
        category: RecommendationCategory,
        title: String,
        description: String,
        expectedImpact: ExpectedImpact,
        requiredActions: [String],
        relatedMetrics: [String]
    ) {
        self.id = id
        self.priority = priority
        self.category = category
        self.title = title
        self.description = description
        self.expectedImpact = expectedImpact
        self.requiredActions = requiredActions
        self.relatedMetrics = relatedMetrics
    }
}

/// Report containing comprehensive metrics analysis
public struct MetricsReport: Equatable, Codable {
    public let id: UUID
    public let title: String
    public let period: DateInterval
    public let generatedAt: Date
    public let summary: MetricsSummary
    public let detailedMeasurements: [MetricMeasurement]
    public let trends: [MetricTrend]
    public let comparisons: [MetricComparison]
    public let executiveSummary: String

    public init(
        id: UUID = UUID(),
        title: String,
        period: DateInterval,
        generatedAt: Date = Date(),
        summary: MetricsSummary,
        detailedMeasurements: [MetricMeasurement],
        trends: [MetricTrend],
        comparisons: [MetricComparison],
        executiveSummary: String
    ) {
        self.id = id
        self.title = title
        self.period = period
        self.generatedAt = generatedAt
        self.summary = summary
        self.detailedMeasurements = detailedMeasurements
        self.trends = trends
        self.comparisons = comparisons
        self.executiveSummary = executiveSummary
    }
}

/// Trend analysis for a metric over time
public struct MetricTrend: Identifiable, Equatable, Codable {
    public let id: UUID
    public let metricName: String
    public let direction: TrendDirection
    public let magnitude: Double // Percentage change
    public let significance: Double // Statistical significance 0-1
    public let dataPoints: [TrendDataPoint]

    public enum TrendDirection: String, Codable {
        case increasing
        case decreasing
        case stable
        case volatile
    }

    public struct TrendDataPoint: Equatable, Codable {
        public let timestamp: Date
        public let value: Double

        public init(timestamp: Date, value: Double) {
            self.timestamp = timestamp
            self.value = value
        }
    }

    public init(
        id: UUID = UUID(),
        metricName: String,
        direction: TrendDirection,
        magnitude: Double,
        significance: Double,
        dataPoints: [TrendDataPoint]
    ) {
        self.id = id
        self.metricName = metricName
        self.direction = direction
        self.magnitude = magnitude
        self.significance = min(max(significance, 0), 1)
        self.dataPoints = dataPoints
    }
}

/// Comparison between different metrics or time periods
public struct MetricComparison: Identifiable, Equatable, Codable {
    public let id: UUID
    public let type: ComparisonType
    public let baseline: MetricMeasurement
    public let comparison: MetricMeasurement
    public let difference: Double
    public let percentageChange: Double
    public let interpretation: String

    public enum ComparisonType: String, Codable {
        case periodOverPeriod
        case targetVsActual
        case userVsAverage
        case systemVsBaseline
    }

    public init(
        id: UUID = UUID(),
        type: ComparisonType,
        baseline: MetricMeasurement,
        comparison: MetricMeasurement,
        interpretation: String
    ) {
        self.id = id
        self.type = type
        self.baseline = baseline
        self.comparison = comparison
        difference = comparison.aggregatedValue - baseline.aggregatedValue
        percentageChange = baseline.aggregatedValue > 0
            ? ((comparison.aggregatedValue - baseline.aggregatedValue) / baseline.aggregatedValue) * 100
            : 0
        self.interpretation = interpretation
    }
}
