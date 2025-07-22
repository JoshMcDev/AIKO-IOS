//
//  LearningFeedbackLoop.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Combine
import Foundation
import os.log

/// Manages the feedback loop for continuous learning and improvement
@MainActor
final class LearningFeedbackLoop: ObservableObject {
    // MARK: - Properties

    /// Feedback processing queue
    private let feedbackQueue = DispatchQueue(label: "com.aiko.feedback", attributes: .concurrent)

    /// Logger
    private let logger = Logger(subsystem: "com.aiko", category: "FeedbackLoop")

    /// Feedback history for analysis
    @Published private(set) var feedbackHistory: [ProcessedFeedback] = []

    /// Learning metrics
    @Published private(set) var learningMetrics = LearningMetrics()

    /// Feedback processors
    private let implicitProcessor = ImplicitFeedbackProcessor()
    private let explicitProcessor = ExplicitFeedbackProcessor()
    private let behavioralProcessor = BehavioralFeedbackProcessor()

    /// Learning rate controller
    private let learningRateController = AdaptiveLearningRateController()

    /// Confidence adjuster
    private let confidenceAdjuster = ConfidenceAdjustmentEngine()

    /// Pattern reinforcement engine
    private let reinforcementEngine = PatternReinforcementEngine()

    /// Active feedback sessions
    private var activeSessions: [UUID: FeedbackSession] = [:]

    /// Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupFeedbackMonitoring()
        loadHistoricalMetrics()
    }

    // MARK: - Public Methods

    /// Process user feedback
    func processFeedback(_ feedback: UserFeedback) {
        feedbackQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            Task { @MainActor in
                // Determine feedback type and process accordingly
                let processed: ProcessedFeedback = switch self.categorizeFeedback(feedback) {
                case .implicit:
                    await self.implicitProcessor.process(feedback)
                case .explicit:
                    await self.explicitProcessor.process(feedback)
                case .behavioral:
                    await self.behavioralProcessor.process(feedback)
                }

                // Update learning metrics
                self.updateLearningMetrics(with: processed)

                // Apply feedback to pattern confidence
                await self.applyFeedbackToPatterns(processed)

                // Store processed feedback
                self.feedbackHistory.append(processed)

                // Trigger learning rate adjustment if needed
                self.adjustLearningRate(based: processed)

                self.logger.info("Processed feedback: \(feedback.type) with impact: \(processed.impact)")
            }
        }
    }

    /// Start a feedback session for continuous monitoring
    func startFeedbackSession(for context: FeedbackContext) -> UUID {
        let sessionId = UUID()
        let session = FeedbackSession(
            id: sessionId,
            context: context,
            startTime: Date(),
            feedbackItems: []
        )

        activeSessions[sessionId] = session

        logger.info("Started feedback session: \(sessionId)")
        return sessionId
    }

    /// End a feedback session and analyze results
    func endFeedbackSession(_ sessionId: UUID) async -> FeedbackSessionSummary? {
        guard var session = activeSessions.removeValue(forKey: sessionId) else {
            logger.warning("No active session found: \(sessionId)")
            return nil
        }

        session.endTime = Date()

        // Analyze session feedback
        let summary = await analyzeFeedbackSession(session)

        // Apply session learnings
        await applySessionLearnings(summary)

        logger.info("Ended feedback session: \(sessionId) with \(session.feedbackItems.count) items")

        return summary
    }

    /// Get learning effectiveness score
    func getLearningEffectiveness() -> Double {
        learningMetrics.calculateEffectiveness()
    }

    /// Get feedback trends
    func getFeedbackTrends(period: TimeInterval) -> FeedbackTrends {
        let cutoffDate = Date().addingTimeInterval(-period)
        let relevantFeedback = feedbackHistory.filter { $0.timestamp > cutoffDate }

        return analyzeFeedbackTrends(relevantFeedback)
    }

    /// Apply reinforcement learning
    func applyReinforcement(for patternId: UUID, reward: Double) async {
        await reinforcementEngine.reinforce(patternId: patternId, reward: reward)

        // Update metrics
        learningMetrics.totalReinforcements += 1
        learningMetrics.averageReward =
            (learningMetrics.averageReward * Double(learningMetrics.totalReinforcements - 1) + reward) /
            Double(learningMetrics.totalReinforcements)
    }

    // MARK: - Private Methods

    private func setupFeedbackMonitoring() {
        // Monitor app lifecycle for implicit feedback
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.recordImplicitFeedback(.appOpened)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.recordImplicitFeedback(.appClosed)
            }
            .store(in: &cancellables)
    }

    private func loadHistoricalMetrics() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "LearningMetrics"),
           let metrics = try? JSONDecoder().decode(LearningMetrics.self, from: data) {
            learningMetrics = metrics
        }
    }

    private func categorizeFeedback(_ feedback: UserFeedback) -> FeedbackCategory {
        // Categorize based on feedback characteristics
        if feedback.context?.contains("automatic") == true {
            .implicit
        } else if feedback.context?.contains("user_action") == true {
            .behavioral
        } else {
            .explicit
        }
    }

    private func updateLearningMetrics(with feedback: ProcessedFeedback) {
        learningMetrics.totalFeedbackProcessed += 1

        switch feedback.impact {
        case .positive:
            learningMetrics.positiveFeedbackCount += 1
        case .negative:
            learningMetrics.negativeFeedbackCount += 1
        case .neutral:
            learningMetrics.neutralFeedbackCount += 1
        }

        learningMetrics.lastUpdated = Date()

        // Save metrics
        saveMetrics()
    }

    private func applyFeedbackToPatterns(_ feedback: ProcessedFeedback) async {
        guard let patternId = feedback.targetPatternId else { return }

        // Calculate confidence adjustment
        let adjustment = confidenceAdjuster.calculateAdjustment(
            currentConfidence: feedback.currentConfidence,
            feedbackType: feedback.originalFeedback.type,
            impact: feedback.impact,
            learningRate: learningRateController.currentRate
        )

        // Apply adjustment through pattern learning engine
        await UserPatternLearningEngine.shared.applyConfidenceAdjustment(
            patternId: patternId,
            adjustment: adjustment
        )
    }

    private func adjustLearningRate(based _: ProcessedFeedback) {
        // Adjust learning rate based on feedback consistency
        let recentFeedback = feedbackHistory.suffix(10)
        let consistency = calculateFeedbackConsistency(recentFeedback)

        learningRateController.adjustRate(basedOn: consistency)
    }

    private func analyzeFeedbackSession(_ session: FeedbackSession) async -> FeedbackSessionSummary {
        let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0

        // Analyze feedback patterns in session
        let positiveCount = session.feedbackItems.filter { $0.type == .positive }.count
        let negativeCount = session.feedbackItems.filter { $0.type == .negative }.count
        let neutralCount = session.feedbackItems.filter { $0.type == .neutral }.count

        // Calculate session effectiveness
        let effectiveness = Double(positiveCount) / Double(max(1, session.feedbackItems.count))

        // Identify key learnings
        let keyLearnings = extractKeyLearnings(from: session)

        return FeedbackSessionSummary(
            sessionId: session.id,
            duration: duration,
            totalFeedback: session.feedbackItems.count,
            positiveCount: positiveCount,
            negativeCount: negativeCount,
            neutralCount: neutralCount,
            effectiveness: effectiveness,
            keyLearnings: keyLearnings,
            recommendations: generateRecommendations(from: keyLearnings)
        )
    }

    private func applySessionLearnings(_ summary: FeedbackSessionSummary) async {
        for learning in summary.keyLearnings {
            // Apply each learning to the pattern engine
            await reinforcementEngine.applyLearning(learning)
        }

        // Update global metrics
        learningMetrics.sessionCount += 1
        learningMetrics.averageSessionEffectiveness =
            (learningMetrics.averageSessionEffectiveness * Double(learningMetrics.sessionCount - 1) + summary.effectiveness) /
            Double(learningMetrics.sessionCount)
    }

    private func analyzeFeedbackTrends(_ feedback: [ProcessedFeedback]) -> FeedbackTrends {
        var trends = FeedbackTrends()

        // Group by day
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: feedback) { item in
            calendar.startOfDay(for: item.timestamp)
        }

        // Calculate daily trends
        for (date, items) in groupedByDay {
            let positive = items.filter { $0.impact == .positive }.count
            let negative = items.filter { $0.impact == .negative }.count
            let total = items.count

            trends.dailyTrends.append(DailyTrend(
                date: date,
                positiveRatio: Double(positive) / Double(max(1, total)),
                negativeRatio: Double(negative) / Double(max(1, total)),
                totalFeedback: total
            ))
        }

        // Sort by date
        trends.dailyTrends.sort { $0.date < $1.date }

        // Calculate moving averages
        trends.calculateMovingAverages()

        return trends
    }

    private func recordImplicitFeedback(_ type: ImplicitFeedbackType) {
        let feedback = UserFeedback(
            id: UUID(),
            patternId: nil,
            type: .neutral,
            timestamp: Date(),
            context: "implicit_\(type.rawValue)"
        )

        processFeedback(feedback)
    }

    private func calculateFeedbackConsistency(_ feedback: [ProcessedFeedback]) -> Double {
        guard feedback.count >= 2 else { return 1.0 }

        var consistentPairs = 0
        var totalPairs = 0

        for i in 0 ..< feedback.count - 1 {
            for j in i + 1 ..< feedback.count where feedback[i].targetPatternId == feedback[j].targetPatternId {
                totalPairs += 1
                if feedback[i].impact == feedback[j].impact {
                    consistentPairs += 1
                }
            }
        }

        return totalPairs > 0 ? Double(consistentPairs) / Double(totalPairs) : 1.0
    }

    private func extractKeyLearnings(from session: FeedbackSession) -> [KeyLearning] {
        var learnings: [KeyLearning] = []

        // Group feedback by pattern
        let groupedByPattern = Dictionary(grouping: session.feedbackItems) { $0.patternId }

        for (patternId, items) in groupedByPattern {
            guard let patternId else { continue }

            let positiveCount = items.filter { $0.type == .positive }.count
            let negativeCount = items.filter { $0.type == .negative }.count

            if positiveCount > negativeCount * 2 {
                // Strong positive signal
                learnings.append(KeyLearning(
                    patternId: patternId,
                    type: .reinforce,
                    strength: Double(positiveCount) / Double(items.count),
                    evidence: items.count
                ))
            } else if negativeCount > positiveCount * 2 {
                // Strong negative signal
                learnings.append(KeyLearning(
                    patternId: patternId,
                    type: .suppress,
                    strength: Double(negativeCount) / Double(items.count),
                    evidence: items.count
                ))
            }
        }

        return learnings
    }

    private func generateRecommendations(from learnings: [KeyLearning]) -> [String] {
        var recommendations: [String] = []

        for learning in learnings {
            switch learning.type {
            case .reinforce:
                recommendations.append("Increase confidence for pattern \(learning.patternId) by \(Int(learning.strength * 100))%")
            case .suppress:
                recommendations.append("Decrease confidence for pattern \(learning.patternId) by \(Int(learning.strength * 100))%")
            case .modify:
                recommendations.append("Consider modifying pattern \(learning.patternId) based on user feedback")
            }
        }

        return recommendations
    }

    private func saveMetrics() {
        if let data = try? JSONEncoder().encode(learningMetrics) {
            UserDefaults.standard.set(data, forKey: "LearningMetrics")
        }
    }
}

// MARK: - Supporting Types

enum FeedbackCategory {
    case implicit
    case explicit
    case behavioral
}

enum ImplicitFeedbackType: String {
    case appOpened = "app_opened"
    case appClosed = "app_closed"
    case featureUsed = "feature_used"
    case featureIgnored = "feature_ignored"
    case suggestionAccepted = "suggestion_accepted"
    case suggestionRejected = "suggestion_rejected"
}

struct ProcessedFeedback {
    let id: UUID
    let originalFeedback: UserFeedback
    let category: FeedbackCategory
    let impact: FeedbackImpact
    let confidence: Double
    let timestamp: Date
    let targetPatternId: UUID?
    let currentConfidence: Double
    let adjustedConfidence: Double?
    let metadata: [String: Any]
}

enum FeedbackImpact {
    case positive
    case negative
    case neutral
}

struct FeedbackSession {
    let id: UUID
    let context: FeedbackContext
    let startTime: Date
    var endTime: Date?
    var feedbackItems: [UserFeedback]
}

struct FeedbackContext {
    let userId: String
    let feature: String
    let metadata: [String: Any]
}

struct FeedbackSessionSummary {
    let sessionId: UUID
    let duration: TimeInterval
    let totalFeedback: Int
    let positiveCount: Int
    let negativeCount: Int
    let neutralCount: Int
    let effectiveness: Double
    let keyLearnings: [KeyLearning]
    let recommendations: [String]
}

struct KeyLearning {
    let patternId: UUID
    let type: LearningType
    let strength: Double
    let evidence: Int

    enum LearningType {
        case reinforce
        case suppress
        case modify
    }
}

struct LearningMetrics: Codable {
    var totalFeedbackProcessed: Int = 0
    var positiveFeedbackCount: Int = 0
    var negativeFeedbackCount: Int = 0
    var neutralFeedbackCount: Int = 0
    var sessionCount: Int = 0
    var averageSessionEffectiveness: Double = 0
    var totalReinforcements: Int = 0
    var averageReward: Double = 0
    var lastUpdated: Date = .init()

    func calculateEffectiveness() -> Double {
        guard totalFeedbackProcessed > 0 else { return 0.5 }

        let positiveRatio = Double(positiveFeedbackCount) / Double(totalFeedbackProcessed)
        let recentnessWeight = min(1.0, -lastUpdated.timeIntervalSinceNow / 86400) // Decay over days

        return positiveRatio * (1.0 - recentnessWeight * 0.2) // 20% decay max
    }
}

struct FeedbackTrends {
    var dailyTrends: [DailyTrend] = []
    var movingAverage7Day: Double = 0
    var movingAverage30Day: Double = 0
    var trend: TrendDirection = .stable

    mutating func calculateMovingAverages() {
        guard !dailyTrends.isEmpty else { return }

        // 7-day moving average
        let recent7 = dailyTrends.suffix(7)
        movingAverage7Day = recent7.map(\.positiveRatio).reduce(0, +) / Double(recent7.count)

        // 30-day moving average
        let recent30 = dailyTrends.suffix(30)
        movingAverage30Day = recent30.map(\.positiveRatio).reduce(0, +) / Double(recent30.count)

        // Determine trend
        if movingAverage7Day > movingAverage30Day * 1.1 {
            trend = .improving
        } else if movingAverage7Day < movingAverage30Day * 0.9 {
            trend = .declining
        } else {
            trend = .stable
        }
    }
}

struct DailyTrend {
    let date: Date
    let positiveRatio: Double
    let negativeRatio: Double
    let totalFeedback: Int
}

enum TrendDirection {
    case improving
    case stable
    case declining
}

// MARK: - Feedback Processors

actor ImplicitFeedbackProcessor {
    func process(_ feedback: UserFeedback) async -> ProcessedFeedback {
        // Process implicit feedback signals
        let impact = determineImplicitImpact(feedback)

        return ProcessedFeedback(
            id: UUID(),
            originalFeedback: feedback,
            category: .implicit,
            impact: impact,
            confidence: 0.6, // Lower confidence for implicit
            timestamp: Date(),
            targetPatternId: feedback.patternId,
            currentConfidence: 0.5,
            adjustedConfidence: nil,
            metadata: [:]
        )
    }

    private func determineImplicitImpact(_ feedback: UserFeedback) -> FeedbackImpact {
        guard let context = feedback.context else { return .neutral }

        if context.contains("accepted") || context.contains("used") {
            return .positive
        } else if context.contains("rejected") || context.contains("ignored") {
            return .negative
        }

        return .neutral
    }
}

actor ExplicitFeedbackProcessor {
    func process(_ feedback: UserFeedback) async -> ProcessedFeedback {
        // Process explicit user feedback
        let impact: FeedbackImpact = switch feedback.type {
        case .positive:
            .positive
        case .negative:
            .negative
        case .neutral:
            .neutral
        }

        return ProcessedFeedback(
            id: UUID(),
            originalFeedback: feedback,
            category: .explicit,
            impact: impact,
            confidence: 0.9, // High confidence for explicit
            timestamp: Date(),
            targetPatternId: feedback.patternId,
            currentConfidence: 0.5,
            adjustedConfidence: nil,
            metadata: [:]
        )
    }
}

actor BehavioralFeedbackProcessor {
    func process(_ feedback: UserFeedback) async -> ProcessedFeedback {
        // Process behavioral feedback patterns
        let impact = analyzeBehavioralPattern(feedback)

        return ProcessedFeedback(
            id: UUID(),
            originalFeedback: feedback,
            category: .behavioral,
            impact: impact,
            confidence: 0.75, // Medium confidence for behavioral
            timestamp: Date(),
            targetPatternId: feedback.patternId,
            currentConfidence: 0.5,
            adjustedConfidence: nil,
            metadata: [:]
        )
    }

    private func analyzeBehavioralPattern(_: UserFeedback) -> FeedbackImpact {
        // Analyze user behavior patterns
        // This is simplified - real implementation would be more sophisticated
        .neutral
    }
}

// MARK: - Learning Controllers

class AdaptiveLearningRateController {
    private(set) var currentRate: Double = 0.1
    private let minRate: Double = 0.01
    private let maxRate: Double = 0.5

    func adjustRate(basedOn consistency: Double) {
        if consistency > 0.8 {
            // High consistency - increase learning rate
            currentRate = min(maxRate, currentRate * 1.1)
        } else if consistency < 0.5 {
            // Low consistency - decrease learning rate
            currentRate = max(minRate, currentRate * 0.9)
        }
    }
}

class ConfidenceAdjustmentEngine {
    func calculateAdjustment(
        currentConfidence: Double,
        feedbackType: UserFeedback.FeedbackType,
        impact: FeedbackImpact,
        learningRate: Double
    ) -> Double {
        var adjustment: Double = 0

        switch (feedbackType, impact) {
        case (.positive, .positive):
            adjustment = learningRate
        case (.negative, .negative):
            adjustment = -learningRate
        case (.positive, .negative), (.negative, .positive):
            adjustment = -learningRate * 0.5 // Contradictory signal
        default:
            adjustment = 0
        }

        // Apply sigmoid to keep confidence in [0, 1]
        let newConfidence = currentConfidence + adjustment
        return max(0, min(1, newConfidence)) - currentConfidence
    }
}

actor PatternReinforcementEngine {
    private var reinforcementHistory: [UUID: [Double]] = [:]

    func reinforce(patternId: UUID, reward: Double) {
        var history = reinforcementHistory[patternId] ?? []
        history.append(reward)

        // Keep last 100 reinforcements
        if history.count > 100 {
            history.removeFirst()
        }

        reinforcementHistory[patternId] = history
    }

    func applyLearning(_ learning: KeyLearning) {
        // Apply the learning to pattern confidence
        let reward: Double = switch learning.type {
        case .reinforce:
            learning.strength
        case .suppress:
            -learning.strength
        case .modify:
            0 // No direct reward for modification
        }

        await reinforce(patternId: learning.patternId, reward: reward)
    }

    func getAverageReward(for patternId: UUID) -> Double? {
        guard let history = reinforcementHistory[patternId], !history.isEmpty else {
            return nil
        }

        return history.reduce(0, +) / Double(history.count)
    }
}

// MARK: - Extensions

extension UserPatternLearningEngine {
    func applyConfidenceAdjustment(patternId: UUID, adjustment: Double) async {
        // This would be implemented in UserPatternLearningEngine
        // For now, just log
        logger.info("Applying confidence adjustment \(adjustment) to pattern \(patternId)")
    }
}
