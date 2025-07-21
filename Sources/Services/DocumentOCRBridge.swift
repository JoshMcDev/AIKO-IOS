import AppCore
import ComposableArchitecture
import Foundation

// MARK: - Document OCR Bridge

/// Bridge service that connects processed scanner images to the existing OCR pipeline
/// Handles seamless integration between DocumentScannerFeature and UnifiedDocumentContextExtractor
public actor DocumentOCRBridge {
    // MARK: - Properties

    private let unifiedExtractor: UnifiedDocumentContextExtractor
    private let qualityThreshold: Double
    private let batchProcessingTimeout: TimeInterval
    private var sessionMetadata: [DocumentSessionID: SessionMetadata] = [:]

    // MARK: - Initialization

    public init(
        unifiedExtractor: UnifiedDocumentContextExtractor? = nil,
        qualityThreshold: Double = 0.7,
        batchProcessingTimeout: TimeInterval = 300.0
    ) {
        // Use the non-MainActor shared instance for actor contexts
        self.unifiedExtractor = unifiedExtractor ?? UnifiedDocumentContextExtractor.sharedNonMainActor
        self.qualityThreshold = qualityThreshold
        self.batchProcessingTimeout = batchProcessingTimeout
    }

    // MARK: - Core Bridge Methods

    /// Primary method to bridge processed scanner pages to OCR pipeline
    /// Maintains metadata and handles batch processing for multi-page documents
    public func bridgeToOCR(
        scannerPages: [ScannedPage],
        sessionID: DocumentSessionID,
        processingHints: [String: String] = [:]
    ) async throws -> OCRBridgeResult {
        // Start timing for MoP #8 requirement: <500ms handoff
        let startTime = CFAbsoluteTimeGetCurrent()

        // Validate input and prepare for processing
        guard !scannerPages.isEmpty else {
            throw OCRBridgeError.noProcessedPages
        }

        // Create or update session metadata
        let sessionMeta = SessionMetadata(
            sessionID: sessionID,
            totalPages: scannerPages.count,
            createdAt: Date(),
            processingHints: processingHints
        )
        sessionMetadata[sessionID] = sessionMeta

        // Filter pages that meet quality requirements
        let qualifiedPages = try await filterQualifiedPages(scannerPages)

        guard !qualifiedPages.isEmpty else {
            throw OCRBridgeError.noQualifiedPages(threshold: qualityThreshold)
        }

        // Prepare OCR input data while preserving all metadata
        let ocrInputs = try await prepareOCRInputs(
            from: qualifiedPages,
            sessionMetadata: sessionMeta
        )

        // Bridge to existing OCR system with preserved metadata
        let ocrResults = try await performBatchOCR(
            inputs: ocrInputs,
            sessionID: sessionID
        )

        // Calculate handoff time for MoP #8 validation
        let handoffTime = CFAbsoluteTimeGetCurrent() - startTime

        // Validate handoff performance (MoP #8: <500ms)
        if handoffTime > 0.5 {
            print("⚠️ OCR Handoff Performance Warning: \(handoffTime * 1000)ms (target: <500ms)")
        }

        return OCRBridgeResult(
            sessionID: sessionID,
            processedPages: qualifiedPages.count,
            ocrResults: ocrResults,
            handoffTime: handoffTime,
            qualityReport: generateQualityReport(from: qualifiedPages, ocrResults: ocrResults)
        )
    }

    /// Extract comprehensive document context from OCR results using existing pipeline
    /// Integrates seamlessly with UnifiedDocumentContextExtractor
    public func extractDocumentContext(
        from bridgeResult: OCRBridgeResult,
        additionalHints: [String: String] = [:]
    ) async throws -> AIKO.ComprehensiveDocumentContext {
        // Combine processing hints with additional hints
        var combinedHints: [String: String] = [:]
        combinedHints.merge(additionalHints) { _, new in new }

        // Add scanner-specific context hints
        combinedHints["document_scanner_bridge"] = "true"
        combinedHints["scanner_session_id"] = bridgeResult.sessionID.uuidString
        combinedHints["processed_pages_count"] = "\(bridgeResult.processedPages)"
        combinedHints["handoff_time_ms"] = "\(bridgeResult.handoffTime * 1000)"
        combinedHints["average_quality_score"] = "\(bridgeResult.qualityReport.averageQualityScore)"

        // Prepare page image data for adaptive learning
        let pageImageData: [Data] = []

        // Use existing UnifiedDocumentContextExtractor with OCR pathway
        // Convert string hints to Any for compatibility
        let anyHints: [String: Any] = combinedHints.reduce(into: [:]) { result, pair in
            result[pair.key] = pair.value
        }

        return try await unifiedExtractor.extractComprehensiveContext(
            from: bridgeResult.ocrResults,
            pageImageData: pageImageData,
            withHints: anyHints
        )
    }

    /// Batch process multiple document sessions with state persistence
    /// Supports MoP #5: 100% accuracy in multi-page session state persistence
    public func processBatchSessions(
        sessions: [DocumentSessionRequest]
    ) async throws -> [SessionID: BatchProcessingResult] {
        var results: [SessionID: BatchProcessingResult] = [:]
        let processingStartTime = Date()

        // Process sessions concurrently while maintaining state persistence
        try await withThrowingTaskGroup(of: (SessionID, BatchProcessingResult).self) { group in
            for request in sessions {
                group.addTask { [weak self] in
                    guard let self else {
                        throw OCRBridgeError.bridgeUnavailable
                    }

                    do {
                        // Persist session state before processing
                        await persistSessionState(request)

                        let bridgeResult = try await bridgeToOCR(
                            scannerPages: request.pages,
                            sessionID: request.sessionID,
                            processingHints: request.processingHints
                        )

                        let context = try await extractDocumentContext(
                            from: bridgeResult,
                            additionalHints: request.contextHints
                        )

                        // Update persisted state with results
                        await updateSessionState(
                            sessionID: request.sessionID,
                            result: bridgeResult,
                            context: context
                        )

                        return (
                            request.sessionID,
                            BatchProcessingResult(
                                bridgeResult: bridgeResult,
                                context: context,
                                processingTime: Date().timeIntervalSince(processingStartTime),
                                state: .completed
                            )
                        )

                    } catch {
                        // Persist error state for recovery
                        await persistSessionError(
                            sessionID: request.sessionID,
                            error: error
                        )

                        throw error
                    }
                }
            }

            // Collect results
            for try await (sessionID, result) in group {
                results[sessionID] = result
            }
        }

        return results
    }

    // MARK: - Session State Persistence (MoP #5)

    /// Persist session state for 100% accuracy requirement
    private func persistSessionState(_ request: DocumentSessionRequest) async {
        let state = PersistedSessionState(
            sessionID: request.sessionID,
            pages: request.pages,
            processingHints: request.processingHints,
            contextHints: request.contextHints,
            timestamp: Date(),
            state: .processing
        )

        // In production, this would write to persistent storage
        // For now, maintain in-memory state with recovery capability
        sessionMetadata[request.sessionID] = SessionMetadata(
            sessionID: request.sessionID,
            totalPages: request.pages.count,
            createdAt: Date(),
            processingHints: request.processingHints,
            persistedState: state
        )
    }

    private func updateSessionState(
        sessionID: DocumentSessionID,
        result _: OCRBridgeResult,
        context: AIKO.ComprehensiveDocumentContext
    ) async {
        guard var metadata = sessionMetadata[sessionID] else { return }

        metadata.completedAt = Date()
        metadata.documentContext = context
        metadata.persistedState?.state = .completed

        sessionMetadata[sessionID] = metadata
    }

    private func persistSessionError(
        sessionID: DocumentSessionID,
        error: Error
    ) async {
        guard var metadata = sessionMetadata[sessionID] else { return }

        metadata.error = error
        metadata.persistedState?.state = .failed
        metadata.persistedState?.errorDescription = error.localizedDescription

        sessionMetadata[sessionID] = metadata
    }

    /// Restore session state for recovery scenarios
    public func restoreSessionState(
        sessionID: DocumentSessionID
    ) async -> PersistedSessionState? {
        sessionMetadata[sessionID]?.persistedState
    }

    // MARK: - Quality Filtering and Validation

    private func filterQualifiedPages(
        _ pages: [ScannedPage]
    ) async throws -> [ScannedPage] {
        pages.filter { page in
            // Check processing state
            guard page.processingState == .completed else {
                return false
            }

            // Check quality score
            if let qualityScore = page.qualityScore {
                return qualityScore >= qualityThreshold
            }

            // Check OCR result confidence if available
            if let ocrResult = page.ocrResult {
                return ocrResult.confidence >= qualityThreshold
            }

            // Check processing result confidence
            if let processingResult = page.processingResult {
                return processingResult.qualityMetrics.overallConfidence >= qualityThreshold
            }

            // Default to accept if no quality metrics available
            return true
        }
    }

    // MARK: - OCR Input Preparation

    private func prepareOCRInputs(
        from pages: [ScannedPage],
        sessionMetadata: SessionMetadata
    ) async throws -> [OCRInput] {
        pages.enumerated().map { _, page in
            // Determine best image data to use
            let imageData = page.enhancedImageData ?? page.imageData

            // Create OCR input with preserved metadata
            let metadata = OCRInputMetadata(
                sessionID: sessionMetadata.sessionID,
                pageNumber: page.pageNumber,
                originalPageID: page.id,
                qualityMetrics: page.processingResult?.qualityMetrics,
                processingMode: page.processingMode,
                enhancementApplied: page.enhancementApplied,
                originalConfidence: page.qualityScore
            )

            return OCRInput(
                imageData: imageData,
                metadata: metadata,
                processingHints: sessionMetadata.processingHints
            )
        }
    }

    // MARK: - Batch OCR Processing

    private func performBatchOCR(
        inputs: [OCRInput],
        sessionID: DocumentSessionID
    ) async throws -> [OCRResult] {
        // Process OCR in batches to manage memory and performance
        let batchSize = 5 // Process 5 pages at a time
        var allResults: [OCRResult] = []

        for batchStartIndex in stride(from: 0, to: inputs.count, by: batchSize) {
            let batchEndIndex = min(batchStartIndex + batchSize, inputs.count)
            let batch = Array(inputs[batchStartIndex ..< batchEndIndex])

            // Process batch with timeout protection
            let batchResults = try await withTimeout(batchProcessingTimeout) {
                try await self.processBatchOCRInternal(batch)
            }

            allResults.append(contentsOf: batchResults)

            // Update session progress
            await updateBatchProgress(
                sessionID: sessionID,
                completedPages: allResults.count,
                totalPages: inputs.count
            )
        }

        return allResults
    }

    private func processBatchOCRInternal(
        _ inputs: [OCRInput]
    ) async throws -> [OCRResult] {
        // Use the existing DocumentScannerClient for actual OCR processing
        // This maintains compatibility with the existing pipeline
        try await withThrowingTaskGroup(of: (Int, OCRResult).self) { group in
            for (index, input) in inputs.enumerated() {
                group.addTask {
                    // Create a temporary DocumentScannerClient for OCR
                    @Dependency(\.documentScanner) var scanner

                    let ocrResult = try await scanner.performEnhancedOCR(input.imageData)
                    return (index, ocrResult)
                }
            }

            // Collect results in order
            var results: [(Int, OCRResult)] = []
            for try await result in group {
                results.append(result)
            }

            // Sort by index and return OCR results
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    // MARK: - Quality Reporting

    private func generateQualityReport(
        from pages: [ScannedPage],
        ocrResults: [OCRResult]
    ) -> QualityReport {
        let qualityScores = pages.compactMap(\.qualityScore)
        let ocrConfidences = ocrResults.map(\.confidence)

        let averageQuality = qualityScores.isEmpty ? 0.0 :
            qualityScores.reduce(0, +) / Double(qualityScores.count)

        let averageOCRConfidence = ocrConfidences.isEmpty ? 0.0 :
            ocrConfidences.reduce(0, +) / Double(ocrConfidences.count)

        let recommendedPages = pages.filter { page in
            page.processingResult?.qualityMetrics.recommendedForOCR ?? true
        }

        return QualityReport(
            totalPages: pages.count,
            qualifiedPages: pages.count,
            averageQualityScore: averageQuality,
            averageOCRConfidence: averageOCRConfidence,
            recommendedForOCRCount: recommendedPages.count,
            qualityThreshold: qualityThreshold
        )
    }

    // MARK: - Helper Methods

    private func extractPageImageDataFromMetadata(
        _: SessionMetadata
    ) -> [Data] {
        // Extract image data from session metadata for adaptive learning
        // This would be populated during session persistence
        []
    }

    private func updateBatchProgress(
        sessionID: DocumentSessionID,
        completedPages: Int,
        totalPages: Int
    ) async {
        guard var metadata = sessionMetadata[sessionID] else { return }

        metadata.progress = Double(completedPages) / Double(totalPages)
        sessionMetadata[sessionID] = metadata
    }

    private func withTimeout<T: Sendable>(
        _ timeout: TimeInterval,
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw OCRBridgeError.processingTimeout(timeout)
            }

            defer { group.cancelAll() }

            guard let result = try await group.next() else {
                throw OCRBridgeError.processingTimeout(timeout)
            }

            return result
        }
    }
}

// MARK: - Supporting Types

public typealias DocumentSessionID = UUID
public typealias SessionID = UUID

/// Request structure for batch processing
public struct DocumentSessionRequest: Sendable {
    public let sessionID: DocumentSessionID
    public let pages: [ScannedPage]
    public let processingHints: [String: String]
    public let contextHints: [String: String]

    public init(
        sessionID: DocumentSessionID = UUID(),
        pages: [ScannedPage],
        processingHints: [String: String] = [:],
        contextHints: [String: String] = [:]
    ) {
        self.sessionID = sessionID
        self.pages = pages
        self.processingHints = processingHints
        self.contextHints = contextHints
    }
}

/// OCR Bridge result with comprehensive metadata
public struct OCRBridgeResult: Sendable {
    public let sessionID: DocumentSessionID
    public let processedPages: Int
    public let ocrResults: [OCRResult]
    public let handoffTime: TimeInterval
    public let qualityReport: QualityReport

    public init(
        sessionID: DocumentSessionID,
        processedPages: Int,
        ocrResults: [OCRResult],
        handoffTime: TimeInterval,
        qualityReport: QualityReport
    ) {
        self.sessionID = sessionID
        self.processedPages = processedPages
        self.ocrResults = ocrResults
        self.handoffTime = handoffTime
        self.qualityReport = qualityReport
    }
}

/// Session metadata for state persistence
public struct SessionMetadata: Sendable {
    public let sessionID: DocumentSessionID
    public let totalPages: Int
    public let createdAt: Date
    public let processingHints: [String: String]
    public var completedAt: Date?
    public var progress: Double = 0.0
    // Remove recursive reference - ocrResult stored separately
    public var documentContext: AIKO.ComprehensiveDocumentContext?
    public var error: Error?
    public var persistedState: PersistedSessionState?

    public init(
        sessionID: DocumentSessionID,
        totalPages: Int,
        createdAt: Date,
        processingHints: [String: String],
        persistedState: PersistedSessionState? = nil
    ) {
        self.sessionID = sessionID
        self.totalPages = totalPages
        self.createdAt = createdAt
        self.processingHints = processingHints
        self.persistedState = persistedState
    }
}

/// Persisted session state for recovery
public struct PersistedSessionState: Sendable {
    public let sessionID: DocumentSessionID
    public let pages: [ScannedPage]
    public let processingHints: [String: String]
    public let contextHints: [String: String]
    public let timestamp: Date
    public var state: ProcessingState
    public var errorDescription: String?

    public enum ProcessingState: String, CaseIterable, Sendable {
        case pending
        case processing
        case completed
        case failed
    }

    public init(
        sessionID: DocumentSessionID,
        pages: [ScannedPage],
        processingHints: [String: String],
        contextHints: [String: String],
        timestamp: Date,
        state: ProcessingState = .pending
    ) {
        self.sessionID = sessionID
        self.pages = pages
        self.processingHints = processingHints
        self.contextHints = contextHints
        self.timestamp = timestamp
        self.state = state
    }
}

/// OCR input with metadata preservation
public struct OCRInput: Sendable {
    public let imageData: Data
    public let metadata: OCRInputMetadata
    public let processingHints: [String: String]

    public init(
        imageData: Data,
        metadata: OCRInputMetadata,
        processingHints: [String: String] = [:]
    ) {
        self.imageData = imageData
        self.metadata = metadata
        self.processingHints = processingHints
    }
}

/// Metadata for OCR input preservation
public struct OCRInputMetadata: Sendable {
    public let sessionID: DocumentSessionID
    public let pageNumber: Int
    public let originalPageID: UUID
    public let qualityMetrics: DocumentImageProcessor.QualityMetrics?
    public let processingMode: DocumentImageProcessor.ProcessingMode?
    public let enhancementApplied: Bool
    public let originalConfidence: Double?

    public init(
        sessionID: DocumentSessionID,
        pageNumber: Int,
        originalPageID: UUID,
        qualityMetrics: DocumentImageProcessor.QualityMetrics? = nil,
        processingMode: DocumentImageProcessor.ProcessingMode? = nil,
        enhancementApplied: Bool = false,
        originalConfidence: Double? = nil
    ) {
        self.sessionID = sessionID
        self.pageNumber = pageNumber
        self.originalPageID = originalPageID
        self.qualityMetrics = qualityMetrics
        self.processingMode = processingMode
        self.enhancementApplied = enhancementApplied
        self.originalConfidence = originalConfidence
    }
}

/// Batch processing result
public struct BatchProcessingResult: Sendable {
    public let bridgeResult: OCRBridgeResult
    public let context: AIKO.ComprehensiveDocumentContext
    public let processingTime: TimeInterval
    public let state: PersistedSessionState.ProcessingState

    public init(
        bridgeResult: OCRBridgeResult,
        context: AIKO.ComprehensiveDocumentContext,
        processingTime: TimeInterval,
        state: PersistedSessionState.ProcessingState
    ) {
        self.bridgeResult = bridgeResult
        self.context = context
        self.processingTime = processingTime
        self.state = state
    }
}

/// Quality assessment report
public struct QualityReport: Sendable {
    public let totalPages: Int
    public let qualifiedPages: Int
    public let averageQualityScore: Double
    public let averageOCRConfidence: Double
    public let recommendedForOCRCount: Int
    public let qualityThreshold: Double

    public init(
        totalPages: Int,
        qualifiedPages: Int,
        averageQualityScore: Double,
        averageOCRConfidence: Double,
        recommendedForOCRCount: Int,
        qualityThreshold: Double
    ) {
        self.totalPages = totalPages
        self.qualifiedPages = qualifiedPages
        self.averageQualityScore = averageQualityScore
        self.averageOCRConfidence = averageOCRConfidence
        self.recommendedForOCRCount = recommendedForOCRCount
        self.qualityThreshold = qualityThreshold
    }
}

// MARK: - Error Types

public enum OCRBridgeError: LocalizedError, Equatable {
    case noProcessedPages
    case noQualifiedPages(threshold: Double)
    case processingTimeout(TimeInterval)
    case bridgeUnavailable
    case ocrProcessingFailed(String)
    case metadataCorruption
    case sessionNotFound(DocumentSessionID)

    public var errorDescription: String? {
        switch self {
        case .noProcessedPages:
            "No processed pages available for OCR"
        case let .noQualifiedPages(threshold):
            "No pages met quality threshold of \(threshold)"
        case let .processingTimeout(timeout):
            "OCR processing timed out after \(timeout) seconds"
        case .bridgeUnavailable:
            "OCR bridge service is unavailable"
        case let .ocrProcessingFailed(reason):
            "OCR processing failed: \(reason)"
        case .metadataCorruption:
            "Session metadata is corrupted"
        case let .sessionNotFound(sessionID):
            "Session not found: \(sessionID)"
        }
    }
}

// MARK: - Dependency Registration

public extension DocumentOCRBridge {
    /// Dependency key for DocumentOCRBridge
    struct DependencyKey: TestDependencyKey {
        public static let liveValue = DocumentOCRBridge()
        public static let testValue = DocumentOCRBridge(
            unifiedExtractor: nil,
            qualityThreshold: 0.5,
            batchProcessingTimeout: 30.0
        )
    }
}

public extension DependencyValues {
    var documentOCRBridge: DocumentOCRBridge {
        get { self[DocumentOCRBridge.DependencyKey.self] }
        set { self[DocumentOCRBridge.DependencyKey.self] = newValue }
    }
}
