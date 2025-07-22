import ComposableArchitecture
import Foundation

// MARK: - Multi-Page Scanning Session

/// Represents a multi-page document scanning session
/// Manages state across multiple scanning operations for building complex documents
public struct MultiPageSession: Equatable, Sendable, Identifiable {
    public let id: UUID
    public var title: String
    public var pages: IdentifiedArrayOf<ScannedPage>
    public var sessionState: SessionState
    public var configuration: SessionConfiguration
    public var metadata: SessionMetadata
    public let createdAt: Date
    public var lastModified: Date

    // Session Progress Tracking
    public var totalPagesScanned: Int { pages.count }
    public var processedPagesCount: Int {
        pages.count(where: { $0.processingState == .completed })
    }

    public var averageQualityScore: Double {
        let scores = pages.compactMap(\.qualityScore)
        guard !scores.isEmpty else { return 0.0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    public init(
        id: UUID = UUID(),
        title: String = "New Document Session",
        pages: IdentifiedArrayOf<ScannedPage> = [],
        sessionState: SessionState = .active,
        configuration: SessionConfiguration = SessionConfiguration(),
        metadata: SessionMetadata = SessionMetadata(),
        createdAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.pages = pages
        self.sessionState = sessionState
        self.configuration = configuration
        self.metadata = metadata
        self.createdAt = createdAt
        self.lastModified = lastModified
    }

    // MARK: - Session Management

    /// Adds a new page to the session
    public mutating func addPage(_ page: ScannedPage) {
        var updatedPage = page
        updatedPage.pageNumber = pages.count + 1
        pages.append(updatedPage)
        lastModified = Date()

        // Update session metadata
        metadata.totalScanningTime += 1.0 // Placeholder - should be tracked during actual scanning
        metadata.lastPageAddedAt = Date()
    }

    /// Adds multiple pages to the session
    public mutating func addPages(_ newPages: [ScannedPage]) {
        for page in newPages {
            addPage(page)
        }
    }

    /// Removes a page from the session and renumbers remaining pages
    public mutating func removePage(withId pageId: ScannedPage.ID) {
        pages.remove(id: pageId)
        renumberPages()
        lastModified = Date()
    }

    /// Reorders pages and updates page numbers
    public mutating func reorderPages(from source: IndexSet, to destination: Int) {
        pages.move(fromOffsets: source, toOffset: destination)
        renumberPages()
        lastModified = Date()
    }

    /// Renumbers all pages sequentially
    private mutating func renumberPages() {
        for (index, page) in pages.enumerated() {
            pages[id: page.id]?.pageNumber = index + 1
        }
    }

    /// Updates session state and metadata
    public mutating func updateState(_ newState: SessionState) {
        sessionState = newState
        lastModified = Date()

        switch newState {
        case .completed:
            metadata.completedAt = Date()
        case .cancelled:
            metadata.cancelledAt = Date()
        case .paused:
            metadata.pausedAt = Date()
        case .active:
            break
        }
    }

    /// Checks if session can be finalized into a document
    public var canFinalize: Bool {
        !pages.isEmpty &&
            sessionState == .active &&
            processedPagesCount == totalPagesScanned
    }

    /// Estimates total processing time for remaining pages
    public var estimatedRemainingProcessingTime: TimeInterval {
        let unprocessedPages = pages.filter { $0.processingState != .completed }
        let baseTimePerPage: TimeInterval = configuration.processingMode == .enhanced ? 8.0 : 3.0
        let ocrMultiplier: TimeInterval = configuration.enableOCR ? 1.5 : 1.0

        return Double(unprocessedPages.count) * baseTimePerPage * ocrMultiplier
    }

    /// Creates a ScannedDocument from the current session
    public func createDocument() -> ScannedDocument {
        ScannedDocument(
            id: UUID(),
            pages: Array(pages),
            title: title,
            scannedAt: createdAt,
            metadata: DocumentMetadata(
                source: .scanner,
                captureDate: createdAt,
                deviceInfo: metadata.deviceInfo
            )
        )
    }
}

// MARK: - Session State

public enum SessionState: String, CaseIterable, Equatable, Sendable {
    case active
    case paused
    case completed
    case cancelled

    public var displayName: String {
        switch self {
        case .active: "Active"
        case .paused: "Paused"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }

    public var canAddPages: Bool {
        self == .active
    }

    public var canModifyPages: Bool {
        self == .active || self == .paused
    }
}

// MARK: - Session Configuration

/// Configuration settings for a multi-page scanning session
public struct SessionConfiguration: Equatable, Sendable {
    public var processingMode: DocumentImageProcessor.ProcessingMode
    public var enableImageEnhancement: Bool
    public var enableOCR: Bool
    public var enableEnhancedOCR: Bool
    public var autoProcessPages: Bool
    public var qualityTarget: DocumentImageProcessor.QualityTarget
    public var maxPagesPerSession: Int
    public var autoSaveInterval: TimeInterval // seconds

    // Advanced Processing Settings
    public var preserveColors: Bool
    public var optimizeForOCR: Bool
    public var enhancementPreviewEnabled: Bool
    public var qualityAssessmentEnabled: Bool

    public init(
        processingMode: DocumentImageProcessor.ProcessingMode = .basic,
        enableImageEnhancement: Bool = true,
        enableOCR: Bool = true,
        enableEnhancedOCR: Bool = true,
        autoProcessPages: Bool = true,
        qualityTarget: DocumentImageProcessor.QualityTarget = .balanced,
        maxPagesPerSession: Int = 50,
        autoSaveInterval: TimeInterval = 30.0,
        preserveColors: Bool = true,
        optimizeForOCR: Bool = true,
        enhancementPreviewEnabled: Bool = false,
        qualityAssessmentEnabled: Bool = true
    ) {
        self.processingMode = processingMode
        self.enableImageEnhancement = enableImageEnhancement
        self.enableOCR = enableOCR
        self.enableEnhancedOCR = enableEnhancedOCR
        self.autoProcessPages = autoProcessPages
        self.qualityTarget = qualityTarget
        self.maxPagesPerSession = maxPagesPerSession
        self.autoSaveInterval = autoSaveInterval
        self.preserveColors = preserveColors
        self.optimizeForOCR = optimizeForOCR
        self.enhancementPreviewEnabled = enhancementPreviewEnabled
        self.qualityAssessmentEnabled = qualityAssessmentEnabled
    }

    /// Returns ProcessingOptions based on current configuration
    public func createProcessingOptions() -> DocumentImageProcessor.ProcessingOptions {
        DocumentImageProcessor.ProcessingOptions(
            progressCallback: nil, // Will be set during actual processing
            qualityTarget: qualityTarget,
            preserveColors: preserveColors,
            optimizeForOCR: optimizeForOCR
        )
    }
}

// MARK: - Session Metadata

/// Metadata and analytics for a scanning session
public struct SessionMetadata: Equatable, Sendable {
    public var deviceInfo: String
    public var osVersion: String
    public var appVersion: String
    public var totalScanningTime: TimeInterval
    public var totalProcessingTime: TimeInterval
    public var averagePageProcessingTime: TimeInterval
    public var qualityScores: [Double]
    public var errorCount: Int
    public var warningCount: Int

    // Progress Tracking
    public var progressSessionId: UUID?

    // Timestamps
    public var firstPageScannedAt: Date?
    public var lastPageAddedAt: Date?
    public var completedAt: Date?
    public var cancelledAt: Date?
    public var pausedAt: Date?

    // Performance Metrics
    public var peakMemoryUsage: Int64 // bytes
    public var averageMemoryUsage: Int64 // bytes
    public var cpuUsageSpikes: [CPUUsageSpike]

    // Quality Metrics
    public var commonQualityIssues: [QualityIssue]
    public var processingRecommendations: [QualityRecommendation]

    public init(
        deviceInfo: String = "",
        osVersion: String = "",
        appVersion: String = "",
        totalScanningTime: TimeInterval = 0,
        totalProcessingTime: TimeInterval = 0,
        averagePageProcessingTime: TimeInterval = 0,
        qualityScores: [Double] = [],
        errorCount: Int = 0,
        warningCount: Int = 0,
        progressSessionId: UUID? = nil,
        firstPageScannedAt: Date? = nil,
        lastPageAddedAt: Date? = nil,
        completedAt: Date? = nil,
        cancelledAt: Date? = nil,
        pausedAt: Date? = nil,
        peakMemoryUsage: Int64 = 0,
        averageMemoryUsage: Int64 = 0,
        cpuUsageSpikes: [CPUUsageSpike] = [],
        commonQualityIssues: [QualityIssue] = [],
        processingRecommendations: [QualityRecommendation] = []
    ) {
        self.deviceInfo = deviceInfo
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.totalScanningTime = totalScanningTime
        self.totalProcessingTime = totalProcessingTime
        self.averagePageProcessingTime = averagePageProcessingTime
        self.qualityScores = qualityScores
        self.errorCount = errorCount
        self.warningCount = warningCount
        self.progressSessionId = progressSessionId
        self.firstPageScannedAt = firstPageScannedAt
        self.lastPageAddedAt = lastPageAddedAt
        self.completedAt = completedAt
        self.cancelledAt = cancelledAt
        self.pausedAt = pausedAt
        self.peakMemoryUsage = peakMemoryUsage
        self.averageMemoryUsage = averageMemoryUsage
        self.cpuUsageSpikes = cpuUsageSpikes
        self.commonQualityIssues = commonQualityIssues
        self.processingRecommendations = processingRecommendations
    }

    /// Adds a quality score and updates related metrics
    public mutating func addQualityScore(_ score: Double) {
        qualityScores.append(score)

        // Update average processing time if we have timing data
        if !qualityScores.isEmpty {
            averagePageProcessingTime = totalProcessingTime / Double(qualityScores.count)
        }
    }

    /// Records an error occurrence
    public mutating func recordError() {
        errorCount += 1
    }

    /// Records a warning occurrence
    public mutating func recordWarning() {
        warningCount += 1
    }

    /// Adds processing time for a page
    public mutating func addProcessingTime(_ time: TimeInterval) {
        totalProcessingTime += time

        if !qualityScores.isEmpty {
            averagePageProcessingTime = totalProcessingTime / Double(qualityScores.count)
        }
    }

    /// Records memory usage spike
    public mutating func recordMemoryUsage(_ usage: Int64, at _: Date = Date()) {
        peakMemoryUsage = max(peakMemoryUsage, usage)

        // Update running average (simplified)
        if averageMemoryUsage == 0 {
            averageMemoryUsage = usage
        } else {
            averageMemoryUsage = (averageMemoryUsage + usage) / 2
        }
    }

    /// Adds a CPU usage spike
    public mutating func addCPUSpike(_ spike: CPUUsageSpike) {
        cpuUsageSpikes.append(spike)
    }

    /// Gets session duration up to current time or completion
    public var sessionDuration: TimeInterval {
        let endTime = completedAt ?? cancelledAt ?? Date()
        return endTime.timeIntervalSince(firstPageScannedAt ?? Date())
    }
}

// MARK: - Performance Monitoring Types

/// CPU usage spike information
public struct CPUUsageSpike: Equatable, Sendable {
    public let usage: Double // 0.0 to 1.0
    public let duration: TimeInterval
    public let timestamp: Date
    public let context: String? // What was happening during the spike

    public init(
        usage: Double,
        duration: TimeInterval,
        timestamp: Date = Date(),
        context: String? = nil
    ) {
        self.usage = usage
        self.duration = duration
        self.timestamp = timestamp
        self.context = context
    }
}

// MARK: - Session Error Types

/// Errors specific to multi-page sessions
public enum SessionError: LocalizedError, Equatable {
    case sessionNotFound(UUID)
    case sessionNotActive(UUID)
    case maxPagesReached(Int)
    case pageNotFound(ScannedPage.ID)
    case invalidConfiguration(String)
    case sessionStateConflict(SessionState, SessionState)
    case saveFailed(String)
    case restoreFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .sessionNotFound(id):
            "Session with ID \(id) not found"
        case let .sessionNotActive(id):
            "Session \(id) is not active"
        case let .maxPagesReached(max):
            "Maximum pages per session reached (\(max))"
        case let .pageNotFound(pageId):
            "Page with ID \(pageId) not found"
        case let .invalidConfiguration(reason):
            "Invalid session configuration: \(reason)"
        case let .sessionStateConflict(current, attempted):
            "Cannot change session state from \(current) to \(attempted)"
        case let .saveFailed(reason):
            "Failed to save session: \(reason)"
        case let .restoreFailed(reason):
            "Failed to restore session: \(reason)"
        }
    }
}

// MARK: - Extensions

public extension MultiPageSession {
    /// Creates a session with default configuration optimized for quick scanning
    static func quickScanSession(title: String = "Quick Scan") -> MultiPageSession {
        let config = SessionConfiguration(
            processingMode: .basic,
            enableImageEnhancement: true,
            enableOCR: false,
            autoProcessPages: true,
            qualityTarget: .speed,
            maxPagesPerSession: 10
        )

        return MultiPageSession(
            title: title,
            configuration: config
        )
    }

    /// Creates a session with configuration optimized for high quality documents
    static func qualityDocumentSession(title: String = "Quality Document") -> MultiPageSession {
        let config = SessionConfiguration(
            processingMode: .enhanced,
            enableImageEnhancement: true,
            enableOCR: true,
            enableEnhancedOCR: true,
            autoProcessPages: true,
            qualityTarget: .quality,
            maxPagesPerSession: 25,
            enhancementPreviewEnabled: true,
            qualityAssessmentEnabled: true
        )

        return MultiPageSession(
            title: title,
            configuration: config
        )
    }
}
