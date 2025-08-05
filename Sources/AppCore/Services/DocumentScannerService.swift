import Foundation
import os.log

#if canImport(VisionKit) && canImport(UIKit)
import UIKit
import VisionKit
#endif

// MARK: - Document Scanner Service Implementation

/// Main @MainActor coordinator for document scanning operations
/// Consolidates VisionKit usage and integrates with existing AIKO processing pipeline
@MainActor
public final class DocumentScannerServiceImpl: ObservableObject {
    // MARK: - Dependencies

    private let imageProcessor: DocumentImageProcessor?
    private let scannerClient: DocumentScannerClient?
    private let uuidGenerator: () -> UUID

    public init(
        imageProcessor: DocumentImageProcessor? = nil,
        scannerClient: DocumentScannerClient? = nil,
        uuidGenerator: @escaping () -> UUID = UUID.init
    ) {
        self.imageProcessor = imageProcessor
        self.scannerClient = scannerClient
        self.uuidGenerator = uuidGenerator
    }

    // MARK: - State Management

    @Published public private(set) var activeSessions: [MultiPageSession] = []
    @Published public private(set) var currentSession: MultiPageSession?
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var performanceInsights: PerformanceInsights?

    // MARK: - Performance Tracking

    private var scanningMetricsHistory: [ScanningMetrics] = []
    private var sessionStates: [UUID: MultiPageSession] = [:]
    private let logger = Logger(subsystem: "com.aiko.documentscanner", category: "DocumentScannerService")

    // MARK: - Initialization

    public convenience init() {
        self.init(imageProcessor: nil, scannerClient: nil, uuidGenerator: UUID.init)
        logger.info("DocumentScannerService initialized")
        loadPerformanceInsights()
    }

    // MARK: - Core Scanning Operations

    /// Initiates VisionKit document scanning with modern VNDocumentCameraViewController
    public func scanDocument() async throws -> ScannedDocument {
        logger.info("Starting document scan")

        #if canImport(VisionKit) && canImport(UIKit)
        guard VNDocumentCameraViewController.isSupported else {
            logger.error("Document scanning not supported on this device")
            throw DocumentScannerError.scanningNotAvailable
        }

        isScanning = true
        defer { isScanning = false }

        let startTime = Date()

        do {
            // Use the existing scannerClient for actual scanning
            guard let scannerClient else {
                throw DocumentScannerError.scanningNotAvailable
            }
            let document = try await scannerClient.scan()

            // Record metrics
            let scanDuration = Date().timeIntervalSince(startTime)
            await recordScanningMetrics(
                ScanningMetrics(
                    scanDuration: scanDuration,
                    pagesScanned: document.pages.count,
                    averagePageSize: calculateAveragePageSize(document.pages),
                    qualityScores: document.pages.compactMap(\.qualityScore),
                    deviceModel: getDeviceModel(),
                    osVersion: getOSVersion()
                )
            )

            logger.info("Document scan completed successfully with \(document.pages.count) pages")
            return document

        } catch {
            logger.error("Document scan failed: \(error.localizedDescription)")
            throw error
        }
        #else
        logger.error("VisionKit not available on this platform")
        throw DocumentScannerError.scanningNotAvailable
        #endif
    }

    /// Starts a new multi-page scanning session
    public func startMultiPageSession() async throws -> MultiPageSession {
        logger.info("Starting multi-page session")

        #if canImport(VisionKit) && canImport(UIKit)
        guard VNDocumentCameraViewController.isSupported else {
            throw DocumentScannerError.scanningNotAvailable
        }

        let session = MultiPageSession(
            id: uuidGenerator(),
            title: "Document Session \(Date().formatted(date: .abbreviated, time: .shortened))"
        )

        sessionStates[session.id] = session
        activeSessions.append(session)
        currentSession = session

        logger.info("Started multi-page session: \(session.id)")
        return session
        #else
        throw DocumentScannerError.scanningNotAvailable
        #endif
    }

    /// Adds additional pages to an existing session
    public func addPagesToSession(_ sessionId: UUID) async throws -> MultiPageSession {
        logger.info("Adding pages to session: \(sessionId)")

        guard var session = sessionStates[sessionId] else {
            throw SessionError.sessionNotFound(sessionId)
        }

        guard session.sessionState.canAddPages else {
            throw SessionError.sessionNotActive(sessionId)
        }

        guard session.pages.count < session.configuration.maxPagesPerSession else {
            throw SessionError.maxPagesReached(session.configuration.maxPagesPerSession)
        }

        isScanning = true
        defer { isScanning = false }

        do {
            // Scan new document
            let scannedDocument = try await scanDocument()

            // Add pages to session
            session.addPages(scannedDocument.pages)

            // Auto-process if enabled
            if session.configuration.autoProcessPages {
                let processedPages = try await processPages(
                    scannedDocument.pages,
                    session.configuration.processingMode,
                    session.configuration.createProcessingOptions()
                )

                // Update session with processed pages
                for processedPage in processedPages {
                    if let index = session.pages.firstIndex(where: { $0.id == processedPage.id }) {
                        session.pages[index] = processedPage
                    }
                }
            }

            // Update stored session
            sessionStates[sessionId] = session
            if let index = activeSessions.firstIndex(where: { $0.id == sessionId }) {
                activeSessions[index] = session
            }

            currentSession = session

            logger.info("Added \(scannedDocument.pages.count) pages to session: \(sessionId)")
            return session

        } catch {
            logger.error("Failed to add pages to session: \(error.localizedDescription)")
            throw error
        }
    }

    /// Finalizes a multi-page session into a complete document
    public func finalizeSession(_ sessionId: UUID) async throws -> ScannedDocument {
        logger.info("Finalizing session: \(sessionId)")

        guard var session = sessionStates[sessionId] else {
            throw SessionError.sessionNotFound(sessionId)
        }

        guard session.canFinalize else {
            throw SessionError.sessionStateConflict(session.sessionState, .completed)
        }

        // Update session state
        session.updateState(.completed)
        sessionStates[sessionId] = session

        // Remove from active sessions
        activeSessions.removeAll { $0.id == sessionId }

        // Create final document
        let document = session.createDocument()

        logger.info("Finalized session \(sessionId) into document with \(document.pages.count) pages")
        return document
    }

    // MARK: - Platform Availability

    public func isDocumentScanningAvailable() -> Bool {
        #if canImport(VisionKit) && canImport(UIKit)
        return VNDocumentCameraViewController.isSupported
        #else
        return false
        #endif
    }

    public func isFeatureAvailable(_ feature: VisionKitFeature) -> Bool {
        switch feature {
        case .documentScanning:
            #if canImport(VisionKit) && canImport(UIKit)
            return VNDocumentCameraViewController.isSupported
            #else
            return false
            #endif
        case .textRecognition:
            return true // Available on iOS 13+
        case .dataDetectors:
            return true // Available on iOS 13+
        case .multiPageCapture:
            #if canImport(VisionKit) && canImport(UIKit)
            return VNDocumentCameraViewController.isSupported
            #else
            return false
            #endif
        case .liveTextInteraction:
            if #available(iOS 15.0, *) {
                return true
            }
            return false
        }
    }

    // MARK: - Page Processing Integration

    /// Processes scanned pages using existing DocumentImageProcessor
    public func processPages(
        _ pages: [ScannedPage],
        _ mode: DocumentImageProcessor.ProcessingMode,
        _ options: DocumentImageProcessor.ProcessingOptions
    ) async throws -> [ScannedPage] {
        logger.info("Processing \(pages.count) pages with mode: \(mode.rawValue)")

        isProcessing = true
        defer { isProcessing = false }

        var processedPages: [ScannedPage] = []

        for page in pages {
            let processedPage = try await processPage(page, mode, options)
            processedPages.append(processedPage)
        }

        logger.info("Completed processing \(processedPages.count) pages")
        return processedPages
    }

    /// Processes a single page with progress tracking
    public func processPage(
        _ page: ScannedPage,
        _ mode: DocumentImageProcessor.ProcessingMode,
        _ options: DocumentImageProcessor.ProcessingOptions
    ) async throws -> ScannedPage {
        logger.debug("Processing page: \(page.id)")

        var updatedPage = page
        updatedPage.processingState = .processing
        updatedPage.processingMode = mode

        let startTime = Date()

        do {
            // Use existing image processor
            guard let imageProcessor else {
                throw DocumentScannerError.enhancementFailed
            }
            let result = try await imageProcessor.processImage(
                page.imageData,
                mode,
                options
            )

            // Update page with results
            updatedPage.enhancedImageData = result.processedImageData
            updatedPage.qualityMetrics = result.qualityMetrics
            updatedPage.processingResult = result
            updatedPage.enhancementApplied = true
            updatedPage.processingState = .completed

            let processingTime = Date().timeIntervalSince(startTime)
            logger.debug("Page \(page.id) processed in \(processingTime)s")

            return updatedPage

        } catch {
            logger.error("Failed to process page \(page.id): \(error.localizedDescription)")
            updatedPage.processingState = .failed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - OCR Integration

    /// Performs OCR on processed pages using enhanced OCR pipeline
    public func performEnhancedOCR(_ pages: [ScannedPage]) async throws -> [ScannedPage] {
        logger.info("Performing enhanced OCR on \(pages.count) pages")

        var processedPages: [ScannedPage] = []

        for page in pages {
            let processedPage = try await performPageOCR(page)
            processedPages.append(processedPage)
        }

        logger.info("Completed OCR on \(processedPages.count) pages")
        return processedPages
    }

    /// Performs OCR on a single page
    public func performPageOCR(_ page: ScannedPage) async throws -> ScannedPage {
        logger.debug("Performing OCR on page: \(page.id)")

        var updatedPage = page
        let imageData = page.enhancedImageData ?? page.imageData

        do {
            // Use enhanced OCR from scannerClient
            guard let scannerClient else {
                throw DocumentScannerError.ocrFailed("Scanner client not available")
            }
            let ocrResult = try await scannerClient.performEnhancedOCR(imageData)

            updatedPage.ocrText = ocrResult.fullText
            updatedPage.ocrResult = ocrResult

            logger.debug("OCR completed for page \(page.id)")
            return updatedPage

        } catch {
            logger.error("OCR failed for page \(page.id): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Quality Assessment

    /// Assesses quality of scanned pages for processing recommendations
    public func assessPageQuality(_ page: ScannedPage) async throws -> QualityAssessment {
        logger.debug("Assessing quality for page: \(page.id)")

        // Use existing quality metrics if available
        if let qualityMetrics = page.qualityMetrics {
            return QualityAssessment(
                pageId: page.id,
                overallScore: qualityMetrics.overallConfidence,
                qualityMetrics: qualityMetrics,
                issues: generateQualityIssues(from: qualityMetrics),
                recommendations: generateRecommendations(from: qualityMetrics)
            )
        }

        // Otherwise, process the page to get quality metrics
        guard let imageProcessor else {
            throw DocumentScannerError.unknownError("Image processor not available")
        }
        let options = DocumentImageProcessor.ProcessingOptions(qualityTarget: .quality)
        let result = try await imageProcessor.processImage(
            page.imageData,
            .basic,
            options
        )

        return QualityAssessment(
            pageId: page.id,
            overallScore: result.qualityMetrics.overallConfidence,
            qualityMetrics: result.qualityMetrics,
            issues: generateQualityIssues(from: result.qualityMetrics),
            recommendations: generateRecommendations(from: result.qualityMetrics)
        )
    }

    /// Provides processing recommendations based on quality assessments
    public func getProcessingRecommendations(_ assessments: [QualityAssessment]) -> ProcessingRecommendations {
        logger.debug("Generating processing recommendations for \(assessments.count) assessments")

        let averageScore = assessments.map(\.overallScore).reduce(0, +) / Double(assessments.count)
        _ = assessments.flatMap(\.issues)
        let allRecommendations = assessments.flatMap(\.recommendations)

        // Determine recommended mode based on quality scores
        let recommendedMode: DocumentImageProcessor.ProcessingMode = averageScore < 0.7 ? .enhanced : .basic

        // Create processing options
        let options = DocumentImageProcessor.ProcessingOptions(
            qualityTarget: averageScore < 0.6 ? .quality : .balanced,
            optimizeForOCR: true
        )

        // Estimate processing time
        let baseTime: TimeInterval = recommendedMode == .enhanced ? 8.0 : 3.0
        let estimatedTime = baseTime * Double(assessments.count)

        return ProcessingRecommendations(
            recommendedMode: recommendedMode,
            recommendedOptions: options,
            qualityImprovements: Array(Set(allRecommendations)),
            estimatedProcessingTime: estimatedTime,
            confidenceScore: averageScore
        )
    }

    // MARK: - Session Management

    /// Retrieves active multi-page sessions
    public func getActiveSessions() async -> [MultiPageSession] {
        activeSessions
    }

    /// Cancels an active session
    public func cancelSession(_ sessionId: UUID) async throws {
        logger.info("Cancelling session: \(sessionId)")

        guard var session = sessionStates[sessionId] else {
            throw SessionError.sessionNotFound(sessionId)
        }

        session.updateState(.cancelled)
        sessionStates[sessionId] = session

        // Remove from active sessions
        activeSessions.removeAll { $0.id == sessionId }

        if currentSession?.id == sessionId {
            currentSession = nil
        }

        logger.info("Cancelled session: \(sessionId)")
    }

    /// Saves session state for later resumption
    public func saveSessionState(_ session: MultiPageSession) async throws {
        logger.debug("Saving session state: \(session.id)")

        sessionStates[session.id] = session

        // Update in active sessions if present
        if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
            activeSessions[index] = session
        }

        // Here you could implement persistent storage if needed
        // For now, we're keeping it in memory
    }

    /// Restores saved session state
    public func restoreSessionState(_ sessionId: UUID) async throws -> MultiPageSession? {
        logger.debug("Restoring session state: \(sessionId)")

        guard let session = sessionStates[sessionId] else {
            return nil
        }

        // Add back to active sessions if not already present
        if !activeSessions.contains(where: { $0.id == sessionId }) {
            activeSessions.append(session)
        }

        return session
    }

    // MARK: - Performance Monitoring

    /// Tracks scanning performance for optimization
    public func recordScanningMetrics(_ metrics: ScanningMetrics) async {
        logger.debug("Recording scanning metrics")

        scanningMetricsHistory.append(metrics)

        // Keep only recent metrics (last 100 scans)
        if scanningMetricsHistory.count > 100 {
            scanningMetricsHistory.removeFirst()
        }

        // Update performance insights
        await updatePerformanceInsights()
    }

    /// Gets performance insights and recommendations
    public func getPerformanceInsights() async -> PerformanceInsights {
        performanceInsights ?? generateDefaultInsights()
    }

    /// Estimates processing time for given configuration
    public func estimateProcessingTime(_ pageCount: Int, _ mode: DocumentImageProcessor.ProcessingMode) async -> TimeInterval {
        let baseTime: TimeInterval = mode == .enhanced ? 8.0 : 3.0
        let estimatedTime = baseTime * Double(pageCount)

        logger.debug("Estimated processing time for \(pageCount) pages in \(mode.rawValue) mode: \(estimatedTime)s")
        return estimatedTime
    }

    // MARK: - Private Helpers

    private func calculateAveragePageSize(_ pages: [ScannedPage]) -> Double {
        guard !pages.isEmpty else { return 0.0 }
        let totalSize = pages.map { Double($0.imageData.count) }.reduce(0, +)
        return totalSize / Double(pages.count)
    }

    private func getDeviceModel() async -> String {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                #if canImport(UIKit)
                let model = UIDevice.current.model
                continuation.resume(returning: model)
                #else
                continuation.resume(returning: "Unknown")
                #endif
            }
        }
    }

    private func getOSVersion() async -> String {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                #if canImport(UIKit)
                let version = UIDevice.current.systemVersion
                continuation.resume(returning: version)
                #else
                continuation.resume(returning: "Unknown")
                #endif
            }
        }
    }

    private func generateQualityIssues(from metrics: DocumentImageProcessor.QualityMetrics) -> [QualityIssue] {
        var issues: [QualityIssue] = []

        if metrics.sharpnessScore < 0.6 {
            issues.append(.blurry)
        }

        if metrics.contrastScore < 0.5 {
            issues.append(.poorContrast)
        }

        if metrics.noiseLevel > 0.7 {
            issues.append(.noiseHeavy)
        }

        if metrics.textClarity < 0.6 {
            issues.append(.poorLighting)
        }

        return issues
    }

    private func generateRecommendations(from metrics: DocumentImageProcessor.QualityMetrics) -> [QualityRecommendation] {
        var recommendations: [QualityRecommendation] = []

        if metrics.overallConfidence < 0.6 {
            recommendations.append(.rescan)
        }

        if metrics.sharpnessScore < 0.7 || metrics.contrastScore < 0.7 {
            recommendations.append(.useEnhancedProcessing)
        }

        if metrics.textClarity < 0.6 {
            recommendations.append(.adjustLighting)
        }

        if metrics.noiseLevel > 0.6 {
            recommendations.append(.improveStability)
        }

        return recommendations
    }

    private func loadPerformanceInsights() {
        // Initialize with default insights
        performanceInsights = generateDefaultInsights()
    }

    private func updatePerformanceInsights() async {
        guard !scanningMetricsHistory.isEmpty else { return }

        let avgScanTime = scanningMetricsHistory.map(\.scanDuration).reduce(0, +) / Double(scanningMetricsHistory.count)
        let avgQuality = scanningMetricsHistory.flatMap(\.qualityScores).reduce(0, +) / Double(scanningMetricsHistory.flatMap(\.qualityScores).count)

        let insights = PerformanceInsights(
            averageScanTime: avgScanTime,
            averageProcessingTime: 0.0, // Would need to track separately
            averageQualityScore: avgQuality,
            commonIssues: [],
            recommendations: generatePerformanceRecommendations(from: scanningMetricsHistory)
        )

        await MainActor.run {
            self.performanceInsights = insights
        }
    }

    private func generateDefaultInsights() -> PerformanceInsights {
        PerformanceInsights(
            averageScanTime: 2.0,
            averageProcessingTime: 1.0,
            averageQualityScore: 0.85
        )
    }

    private func generatePerformanceRecommendations(from metrics: [ScanningMetrics]) -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []

        let avgScanTime = metrics.map(\.scanDuration).reduce(0, +) / Double(metrics.count)

        if avgScanTime > 5.0 {
            recommendations.append(.optimizeForSpeed)
        }

        let avgQuality = metrics.flatMap(\.qualityScores).reduce(0, +) / Double(metrics.flatMap(\.qualityScores).count)

        if avgQuality < 0.7 {
            recommendations.append(.adjustScanningEnvironment)
        }

        return recommendations
    }
}

// MARK: - Service Factory

/// Factory for creating DocumentScannerService instances
public enum DocumentScannerServiceFactory {
    /// Creates a live instance of the DocumentScannerService
    @MainActor
    public static func createLiveService() -> DocumentScannerServiceImpl {
        DocumentScannerServiceImpl()
    }

    /// Creates a test instance with mock behavior
    @MainActor
    public static func createTestService() -> DocumentScannerServiceImpl {
        // Create test service with mock dependencies
        DocumentScannerServiceImpl(
            imageProcessor: DocumentImageProcessor.testValue,
            scannerClient: DocumentScannerClient.testValue
        )
    }
}
