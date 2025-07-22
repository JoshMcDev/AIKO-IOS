import ComposableArchitecture
import Foundation

#if canImport(VisionKit)
    import VisionKit
#endif

// MARK: - Document Scanner Service Protocol

/// Unified protocol for document scanning service with VisionKit integration
/// Consolidates scattered VisionKit usage into a single, dependency-injectable service
@DependencyClient
public struct DocumentScannerService: Sendable {
    // MARK: - Core Scanning Operations

    /// Initiates VisionKit document scanning with modern VNDocumentCameraViewController
    /// Returns: ScannedDocument with processed pages
    /// Throws: DocumentScannerError for various failure cases
    public var scanDocument: @Sendable () async throws -> ScannedDocument

    /// Scans multiple documents in a session with page management
    /// Returns: MultiPageSession for managing across multiple scanning sessions
    public var startMultiPageSession: @Sendable () async throws -> MultiPageSession

    /// Adds additional pages to an existing session
    public var addPagesToSession: @Sendable (MultiPageSession.ID) async throws -> MultiPageSession

    /// Finalizes a multi-page session into a complete document
    public var finalizeSession: @Sendable (MultiPageSession.ID) async throws -> ScannedDocument

    // MARK: - Platform Availability

    /// Checks if VisionKit document scanning is available on current device/OS
    public var isDocumentScanningAvailable: @Sendable () -> Bool = { false }

    /// Checks specific VisionKit features availability
    public var isFeatureAvailable: @Sendable (VisionKitFeature) -> Bool = { _ in false }

    // MARK: - Page Processing Integration

    /// Processes scanned pages using existing DocumentImageProcessor
    /// Integrates with Phase 4.1 advanced processing pipeline
    public var processPages: @Sendable ([ScannedPage], DocumentImageProcessor.ProcessingMode, DocumentImageProcessor.ProcessingOptions) async throws -> [ScannedPage]

    /// Processes a single page with progress tracking
    public var processPage: @Sendable (ScannedPage, DocumentImageProcessor.ProcessingMode, DocumentImageProcessor.ProcessingOptions) async throws -> ScannedPage

    // MARK: - OCR Integration

    /// Performs OCR on processed pages using enhanced OCR pipeline
    /// Integrates with Phase 4.2 enhanced OCR features
    public var performEnhancedOCR: @Sendable ([ScannedPage]) async throws -> [ScannedPage]

    /// Performs OCR on a single page
    public var performPageOCR: @Sendable (ScannedPage) async throws -> ScannedPage

    // MARK: - Quality Assessment

    /// Assesses quality of scanned pages for processing recommendations
    public var assessPageQuality: @Sendable (ScannedPage) async throws -> QualityAssessment

    /// Provides processing recommendations based on quality assessment
    public var getProcessingRecommendations: @Sendable ([QualityAssessment]) -> ProcessingRecommendations = { _ in ProcessingRecommendations(recommendedMode: .basic, recommendedOptions: DocumentImageProcessor.ProcessingOptions(), estimatedProcessingTime: 1.0, confidenceScore: 0.8) }

    // MARK: - Session Management

    /// Retrieves active multi-page sessions
    public var getActiveSessions: @Sendable () async -> [MultiPageSession] = { [] }

    /// Cancels an active session
    public var cancelSession: @Sendable (MultiPageSession.ID) async throws -> Void

    /// Saves session state for later resumption
    public var saveSessionState: @Sendable (MultiPageSession) async throws -> Void

    /// Restores saved session state
    public var restoreSessionState: @Sendable (MultiPageSession.ID) async throws -> MultiPageSession?

    // MARK: - Performance Monitoring

    /// Tracks scanning performance for optimization
    public var recordScanningMetrics: @Sendable (ScanningMetrics) async -> Void = { _ in }

    /// Gets performance insights and recommendations
    public var getPerformanceInsights: @Sendable () async -> PerformanceInsights = { PerformanceInsights(averageScanTime: 1.0, averageProcessingTime: 2.0, averageQualityScore: 0.8) }

    /// Estimates processing time for given configuration
    public var estimateProcessingTime: @Sendable (Int, DocumentImageProcessor.ProcessingMode) async -> TimeInterval = { _, _ in 1.0 }
}

// MARK: - Supporting Types

/// VisionKit feature availability check
public enum VisionKitFeature: String, CaseIterable, Sendable {
    case documentScanning = "document_scanning"
    case textRecognition = "text_recognition"
    case dataDetectors = "data_detectors"
    case multiPageCapture = "multi_page_capture"
    case liveTextInteraction = "live_text_interaction"

    public var displayName: String {
        switch self {
        case .documentScanning: "Document Scanning"
        case .textRecognition: "Text Recognition"
        case .dataDetectors: "Data Detectors"
        case .multiPageCapture: "Multi-Page Capture"
        case .liveTextInteraction: "Live Text Interaction"
        }
    }
}

/// Quality assessment result for a scanned page
public struct QualityAssessment: Equatable, Sendable {
    public let pageId: ScannedPage.ID
    public let overallScore: Double // 0.0 to 1.0
    public let qualityMetrics: DocumentImageProcessor.QualityMetrics
    public let issues: [QualityIssue]
    public let recommendations: [QualityRecommendation]
    public let assessmentTime: Date

    public init(
        pageId: ScannedPage.ID,
        overallScore: Double,
        qualityMetrics: DocumentImageProcessor.QualityMetrics,
        issues: [QualityIssue] = [],
        recommendations: [QualityRecommendation] = [],
        assessmentTime: Date = Date()
    ) {
        self.pageId = pageId
        self.overallScore = overallScore
        self.qualityMetrics = qualityMetrics
        self.issues = issues
        self.recommendations = recommendations
        self.assessmentTime = assessmentTime
    }
}

/// Quality issues detected in scanned pages
public enum QualityIssue: String, CaseIterable, Equatable, Sendable {
    case lowResolution = "low_resolution"
    case poorContrast = "poor_contrast"
    case skewed
    case blurry
    case noiseHeavy = "noise_heavy"
    case partiallyObscured = "partially_obscured"
    case poorLighting = "poor_lighting"

    public var description: String {
        switch self {
        case .lowResolution: "Image resolution is too low"
        case .poorContrast: "Poor contrast between text and background"
        case .skewed: "Document appears skewed or rotated"
        case .blurry: "Image is blurry or out of focus"
        case .noiseHeavy: "Heavy noise or artifacts detected"
        case .partiallyObscured: "Parts of the document are obscured"
        case .poorLighting: "Poor lighting conditions detected"
        }
    }

    public var severity: QualityIssueSeverity {
        switch self {
        case .lowResolution, .blurry: .high
        case .poorContrast, .skewed: .medium
        case .noiseHeavy, .partiallyObscured, .poorLighting: .low
        }
    }
}

public enum QualityIssueSeverity: String, CaseIterable, Equatable, Sendable {
    case low
    case medium
    case high
    case critical
}

/// Quality recommendations for improving scan results
public enum QualityRecommendation: String, CaseIterable, Equatable, Sendable {
    case rescan
    case useEnhancedProcessing = "use_enhanced_processing"
    case adjustLighting = "adjust_lighting"
    case improveStability = "improve_stability"
    case removeObstructions = "remove_obstructions"
    case useDifferentAngle = "use_different_angle"

    public var description: String {
        switch self {
        case .rescan: "Consider rescanning for better quality"
        case .useEnhancedProcessing: "Use enhanced processing mode"
        case .adjustLighting: "Improve lighting conditions"
        case .improveStability: "Hold device more steadily"
        case .removeObstructions: "Remove any obstructions"
        case .useDifferentAngle: "Try a different scanning angle"
        }
    }

    public var priority: RecommendationPriority {
        switch self {
        case .rescan: .high
        case .useEnhancedProcessing: .medium
        case .adjustLighting, .improveStability: .high
        case .removeObstructions, .useDifferentAngle: .medium
        }
    }
}

public enum RecommendationPriority: String, CaseIterable, Equatable, Sendable {
    case low
    case medium
    case high
}

/// Processing recommendations based on quality assessments
public struct ProcessingRecommendations: Equatable, Sendable {
    public let recommendedMode: DocumentImageProcessor.ProcessingMode
    public let recommendedOptions: DocumentImageProcessor.ProcessingOptions
    public let qualityImprovements: [QualityRecommendation]
    public let estimatedProcessingTime: TimeInterval
    public let confidenceScore: Double // 0.0 to 1.0

    public init(
        recommendedMode: DocumentImageProcessor.ProcessingMode,
        recommendedOptions: DocumentImageProcessor.ProcessingOptions,
        qualityImprovements: [QualityRecommendation] = [],
        estimatedProcessingTime: TimeInterval,
        confidenceScore: Double
    ) {
        self.recommendedMode = recommendedMode
        self.recommendedOptions = recommendedOptions
        self.qualityImprovements = qualityImprovements
        self.estimatedProcessingTime = estimatedProcessingTime
        self.confidenceScore = confidenceScore
    }
}

/// Scanning performance metrics
public struct ScanningMetrics: Equatable, Sendable {
    public let sessionId: MultiPageSession.ID?
    public let scanDuration: TimeInterval
    public let pagesScanned: Int
    public let averagePageSize: Double // bytes
    public let qualityScores: [Double]
    public let processingMode: DocumentImageProcessor.ProcessingMode?
    public let deviceModel: String
    public let osVersion: String
    public let timestamp: Date

    public init(
        sessionId: MultiPageSession.ID? = nil,
        scanDuration: TimeInterval,
        pagesScanned: Int,
        averagePageSize: Double,
        qualityScores: [Double],
        processingMode: DocumentImageProcessor.ProcessingMode? = nil,
        deviceModel: String,
        osVersion: String,
        timestamp: Date = Date()
    ) {
        self.sessionId = sessionId
        self.scanDuration = scanDuration
        self.pagesScanned = pagesScanned
        self.averagePageSize = averagePageSize
        self.qualityScores = qualityScores
        self.processingMode = processingMode
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.timestamp = timestamp
    }
}

/// Performance insights and optimization recommendations
public struct PerformanceInsights: Equatable, Sendable {
    public let averageScanTime: TimeInterval
    public let averageProcessingTime: TimeInterval
    public let averageQualityScore: Double
    public let commonIssues: [QualityIssue]
    public let recommendations: [PerformanceRecommendation]
    public let trendsOverTime: [PerformanceTrend]

    public init(
        averageScanTime: TimeInterval,
        averageProcessingTime: TimeInterval,
        averageQualityScore: Double,
        commonIssues: [QualityIssue] = [],
        recommendations: [PerformanceRecommendation] = [],
        trendsOverTime: [PerformanceTrend] = []
    ) {
        self.averageScanTime = averageScanTime
        self.averageProcessingTime = averageProcessingTime
        self.averageQualityScore = averageQualityScore
        self.commonIssues = commonIssues
        self.recommendations = recommendations
        self.trendsOverTime = trendsOverTime
    }
}

public enum PerformanceRecommendation: String, CaseIterable, Equatable, Sendable {
    case optimizeForSpeed = "optimize_for_speed"
    case optimizeForQuality = "optimize_for_quality"
    case adjustScanningEnvironment = "adjust_scanning_environment"
    case updateScanningTechnique = "update_scanning_technique"
    case useAlternativeMode = "use_alternative_mode"

    public var description: String {
        switch self {
        case .optimizeForSpeed: "Consider using faster processing modes"
        case .optimizeForQuality: "Use higher quality settings for better results"
        case .adjustScanningEnvironment: "Improve scanning environment (lighting, stability)"
        case .updateScanningTechnique: "Adjust scanning technique for better results"
        case .useAlternativeMode: "Try alternative processing modes"
        }
    }
}

public struct PerformanceTrend: Equatable, Sendable {
    public let metric: PerformanceMetric
    public let trend: TrendDirection
    public let changePercent: Double
    public let timeFrame: TimeInterval

    public init(
        metric: PerformanceMetric,
        trend: TrendDirection,
        changePercent: Double,
        timeFrame: TimeInterval
    ) {
        self.metric = metric
        self.trend = trend
        self.changePercent = changePercent
        self.timeFrame = timeFrame
    }
}

public enum PerformanceMetric: String, CaseIterable, Equatable, Sendable {
    case scanTime = "scan_time"
    case processingTime = "processing_time"
    case qualityScore = "quality_score"
    case successRate = "success_rate"
}

public enum TrendDirection: String, CaseIterable, Equatable, Sendable {
    case improving
    case declining
    case stable
}

// MARK: - Dependency Registration

extension DocumentScannerService: DependencyKey {
    public static let liveValue: Self = .init()

    public static let testValue: Self = .init(
        scanDocument: {
            ScannedDocument(
                pages: [
                    ScannedPage(
                        imageData: Data(),
                        pageNumber: 1
                    ),
                ],
                title: "Test Document"
            )
        },
        startMultiPageSession: {
            MultiPageSession(
                id: UUID(),
                title: "Test Session",
                pages: [],
                createdAt: Date(),
                lastModified: Date()
            )
        },
        addPagesToSession: { _ in
            MultiPageSession(
                id: UUID(),
                title: "Test Session",
                pages: [],
                createdAt: Date(),
                lastModified: Date()
            )
        },
        finalizeSession: { _ in
            ScannedDocument(
                pages: [
                    ScannedPage(
                        imageData: Data(),
                        pageNumber: 1
                    ),
                ],
                title: "Test Document"
            )
        },
        isDocumentScanningAvailable: { true },
        isFeatureAvailable: { _ in true },
        processPages: { pages, _, _ in pages },
        processPage: { page, _, _ in page },
        performEnhancedOCR: { pages in pages },
        performPageOCR: { page in page },
        assessPageQuality: { page in
            QualityAssessment(
                pageId: page.id,
                overallScore: 0.85,
                qualityMetrics: DocumentImageProcessor.QualityMetrics(
                    overallConfidence: 0.85,
                    sharpnessScore: 0.8,
                    contrastScore: 0.9,
                    noiseLevel: 0.2,
                    textClarity: 0.85,
                    recommendedForOCR: true
                )
            )
        },
        getProcessingRecommendations: { _ in
            ProcessingRecommendations(
                recommendedMode: .basic,
                recommendedOptions: DocumentImageProcessor.ProcessingOptions(),
                estimatedProcessingTime: 1.0,
                confidenceScore: 0.8
            )
        },
        getActiveSessions: { [] },
        cancelSession: { _ in },
        saveSessionState: { _ in },
        restoreSessionState: { _ in nil },
        recordScanningMetrics: { _ in },
        getPerformanceInsights: {
            PerformanceInsights(
                averageScanTime: 2.0,
                averageProcessingTime: 1.0,
                averageQualityScore: 0.85
            )
        },
        estimateProcessingTime: { pages, mode in
            let baseTime: TimeInterval = mode == .enhanced ? 2.0 : 0.5
            return baseTime * Double(pages)
        }
    )
}

public extension DependencyValues {
    var documentScannerService: DocumentScannerService {
        get { self[DocumentScannerService.self] }
        set { self[DocumentScannerService.self] = newValue }
    }
}
