import Combine
import Foundation

/// Service for collecting and aggregating behavioral analytics data
@MainActor
public final class AnalyticsCollectorService: ObservableObject {
    // MARK: - Properties

    private let repository: AnalyticsRepository
    private var eventQueue: [AnalyticsEvent] = []
    private var cancellables = Set<AnyCancellable>()
    private let processingQueue = DispatchQueue(label: "analytics.processing", qos: .utility)

    @Published public private(set) var isCollecting = false
    @Published public private(set) var collectionMetrics = CollectionMetrics()

    // MARK: - Initialization

    public init(repository: AnalyticsRepository) {
        self.repository = repository
        setupEventProcessing()
    }

    // MARK: - Public Methods

    /// Start analytics collection
    public func startCollection() {
        isCollecting = true
        collectionMetrics.startedAt = Date()
    }

    /// Stop analytics collection
    public func stopCollection() {
        isCollecting = false
        collectionMetrics.stoppedAt = Date()
    }

    /// Record user interaction event
    public func recordEvent(_ event: AnalyticsEvent) {
        guard isCollecting else { return }

        eventQueue.append(event)
        collectionMetrics.eventsCollected += 1

        if eventQueue.count >= 10 {
            processEventQueue()
        }
    }

    /// Get current analytics data
    public func getCurrentAnalytics() async -> AnalyticsDashboardData? {
        await repository.loadDashboardData()
        return repository.dashboardData
    }

    /// Process learning feedback
    public func processFeedback(_ feedback: AnalyticsUserFeedback) async {
        let event = AnalyticsEvent(
            id: UUID(),
            type: .feedback,
            data: [
                "rating": String(feedback.rating),
                "category": feedback.category,
                "comments": feedback.comments,
            ],
            timestamp: Date()
        )

        recordEvent(event)
        await updateLearningMetrics(from: feedback)
    }

    /// Record workflow completion
    public func recordWorkflowCompletion(
        workflowType: String,
        duration: TimeInterval,
        success: Bool
    ) {
        let event = AnalyticsEvent(
            id: UUID(),
            type: .workflowCompletion,
            data: [
                "workflowType": workflowType,
                "duration": String(duration),
                "success": String(success),
            ],
            timestamp: Date()
        )

        recordEvent(event)
    }

    /// Record time saved metric
    public func recordTimeSaved(category: String, seconds: Double) {
        let event = AnalyticsEvent(
            id: UUID(),
            type: .timeSaved,
            data: [
                "category": category,
                "seconds": String(seconds),
            ],
            timestamp: Date()
        )

        recordEvent(event)
        collectionMetrics.totalTimeSaved += seconds
    }

    /// Export analytics data
    public func exportAnalytics(format: ExportFormat) async throws -> Data {
        guard let data = repository.dashboardData else {
            throw AnalyticsError.noDataAvailable
        }

        switch format {
        case .json:
            return try JSONEncoder().encode(data)
        case .csv:
            return try generateCSVData(from: data)
        case .pdf:
            return try await generatePDFData(from: data)
        }
    }

    // MARK: - Private Methods

    private func setupEventProcessing() {
        Timer.publish(every: 30, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.processEventQueue()
            }
            .store(in: &cancellables)
    }

    private func processEventQueue() {
        guard !eventQueue.isEmpty else { return }

        let eventsToProcess = Array(eventQueue)
        eventQueue.removeAll()

        Task { @MainActor in
            await processEvents(eventsToProcess)
        }
    }

    private func processEvents(_ events: [AnalyticsEvent]) async {
        for event in events {
            await processSingleEvent(event)
        }
        collectionMetrics.eventsProcessed += events.count
    }

    private func processSingleEvent(_ event: AnalyticsEvent) async {
        switch event.type {
        case .feedback:
            await processFeedbackEvent(event)
        case .workflowCompletion:
            await processWorkflowEvent(event)
        case .timeSaved:
            await processTimeSavedEvent(event)
        case .userInteraction:
            await processInteractionEvent(event)
        }
    }

    private func processFeedbackEvent(_: AnalyticsEvent) async {
        // Process feedback data and update learning metrics
    }

    private func processWorkflowEvent(_: AnalyticsEvent) async {
        // Process workflow completion data
    }

    private func processTimeSavedEvent(_: AnalyticsEvent) async {
        // Process time saved metrics
    }

    private func processInteractionEvent(_: AnalyticsEvent) async {
        // Process user interaction patterns
    }

    private func updateLearningMetrics(from _: AnalyticsUserFeedback) async {
        // Update learning effectiveness based on user feedback
    }

    private func generateCSVData(from data: AnalyticsDashboardData) throws -> Data {
        var csv = "Metric,Value,Unit\n"
        csv += "Total Time Saved,\(data.overview.totalTimeSaved),seconds\n"
        csv += "Learning Progress,\(data.overview.learningProgress),%\n"
        csv += "Personalization Level,\(data.overview.personalizationLevel),%\n"
        csv += "Automation Success,\(data.overview.automationSuccess),%\n"

        return csv.data(using: .utf8) ?? Data()
    }

    private func generatePDFData(from _: AnalyticsDashboardData) async throws -> Data {
        // Generate PDF report from analytics data
        // For now, return empty data
        Data()
    }
}

// MARK: - Supporting Types

/// Analytics event types
public enum AnalyticsEventType: String, CaseIterable, Codable, Sendable {
    case feedback
    case workflowCompletion = "workflow_completion"
    case timeSaved = "time_saved"
    case userInteraction = "user_interaction"
}

/// Analytics event
public struct AnalyticsEvent: Codable, Equatable, Sendable {
    public let id: UUID
    public let type: AnalyticsEventType
    public let data: [String: String]
    public let timestamp: Date

    public init(id: UUID, type: AnalyticsEventType, data: [String: String], timestamp: Date) {
        self.id = id
        self.type = type
        self.data = data
        self.timestamp = timestamp
    }
}

/// Analytics user feedback
public struct AnalyticsUserFeedback: Codable, Equatable, Sendable {
    public let rating: Int
    public let category: String
    public let comments: String

    public init(rating: Int, category: String, comments: String) {
        self.rating = rating
        self.category = category
        self.comments = comments
    }
}

/// Collection metrics
public struct CollectionMetrics: Codable, Equatable, Sendable {
    public var eventsCollected: Int = 0
    public var eventsProcessed: Int = 0
    public var totalTimeSaved: Double = 0
    public var startedAt: Date?
    public var stoppedAt: Date?

    public init() {}
}

/// Analytics errors
public enum AnalyticsError: Error, Equatable {
    case noDataAvailable
    case exportFailed
    case invalidFormat
}
