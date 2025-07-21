import ComposableArchitecture
import Foundation
import Combine

// Progress integration for DocumentScannerFeature
extension DocumentScannerFeature.State {
    public var progressFeedback: ProgressFeedbackFeature.State {
        get {
            // Return a state based on current scanning/processing progress
            var progressState = ProgressFeedbackFeature.State()

            // If we have a current progress session, populate it
            if let sessionId = progressSessionId {
                let currentProgress = ProgressState(
                    sessionId: sessionId,
                    currentPhase: currentProgressPhase,
                    phaseProgress: 0.5, // Current phase progress
                    overallProgress: overallProgress,
                    currentOperation: currentProgressMessage
                )
                progressState.activeSessions[sessionId] = currentProgress
                progressState.currentSession = sessionId
            }

            return progressState
        }
        set {
            // Update our scanning state based on progress feedback
            if let currentSession = newValue.currentSession,
               let _ = newValue.activeSessions[currentSession] {
                // Update our progress tracking based on the progress state
                // This allows for bidirectional sync
                self._progressSessionId = currentSession
            }
        }
    }

    // Internal progress tracking properties
    private var _progressSessionId: UUID? {
        get {
            // Store in metadata or similar - for now return nil
            nil
        }
        set {
            // Store the session ID - implementation would store in metadata
        }
    }

    public var progressSessionId: UUID? {
        get { _progressSessionId }
        set { _progressSessionId = newValue }
    }

    // Computed progress properties
    public var currentProgressPhase: ProgressPhase {
        if isProcessingAllPages {
            return .processing
        } else if isScannerPresented {
            return .scanning
        } else if isExtractingContext {
            return .ocr
        } else if isAutoPopulating {
            return .formPopulation
        } else if isSavingToDocumentPipeline {
            return .finalizing
        } else {
            return .initializing
        }
    }

    public var overallProgress: Double {
        guard !scannedPages.isEmpty else { return 0.0 }

        if isProcessingAllPages {
            // Base progress on page processing
            let processedPages = Double(processedPagesCount)
            let totalPages = Double(scannedPages.count)
            return processedPages / totalPages
        } else if isScannerPresented {
            // Scanning progress is indeterminate, show 25% while scanning
            return 0.25
        } else if isExtractingContext || isAutoPopulating {
            // Analysis phase, show 85%
            return 0.85
        } else if isSavingToDocumentPipeline {
            // Completing, show 95%
            return 0.95
        } else {
            // Idle or completed
            return scannedPages.isEmpty ? 0.0 : 1.0
        }
    }

    public var currentProgressMessage: String {
        if isProcessingAllPages {
            if let currentPageId = currentProcessingPage {
                let pageIndex = scannedPages.firstIndex { $0.id == currentPageId } ?? 0
                return "Processing page \(pageIndex + 1) of \(scannedPages.count)"
            }
            return "Processing pages..."
        } else if isScannerPresented {
            return "Scanning document..."
        } else if isExtractingContext {
            return "Extracting document context..."
        } else if isAutoPopulating {
            return "Auto-populating form fields..."
        } else if isSavingToDocumentPipeline {
            return "Saving document..."
        } else {
            return hasScannedPages ? "Ready" : "Tap to start scanning"
        }
    }
}

extension DocumentScannerFeature.Action {
    // Progress feedback action integration
    public static func progressFeedback(_ action: ProgressFeedbackFeature.Action) -> Self {
        // Map progress actions to document scanner actions where appropriate
        switch action {
        case .startSession(let config):
            // Start progress tracking for scanning session
            return .startProgressTracking(config)
        case .completeSession(let sessionId):
            // Complete progress tracking
            return .completeProgressTracking(sessionId)
        case .cancelSession(let sessionId):
            // Cancel progress tracking
            return .cancelProgressTracking(sessionId)
        default:
            // For other progress actions, we can use a generic progress update action
            return ._progressFeedbackReceived(action)
        }
    }

    // Note: Additional progress-related actions are defined in the main DocumentScannerFeature.Action enum
    // - case startProgressTracking(ProgressSessionConfig)
    // - case completeProgressTracking(UUID)
    // - case cancelProgressTracking(UUID)
    // - case _progressFeedbackReceived(ProgressFeedbackFeature.Action)
}

// MARK: - Progress Integration Extensions for MultiPageSession

extension MultiPageSession {
    /// Progress session ID for tracking multi-page scanning progress
    public var progressSessionId: UUID? {
        get {
            // Store progress session ID in metadata for persistence
            // For now, we'll use the session ID as the progress session ID
            return id
        }
        set {
            // In a real implementation, this would update the metadata
            // For now, we use the session ID as the progress session ID
        }
    }

    /// Current page scanning progress (0.0 - 1.0)
    public var currentPageProgress: Double {
        get {
            // Current page progress based on processing state
            guard !pages.isEmpty else { return 0.0 }

            // Find the page currently being processed
            if let currentPage = pages.first(where: { $0.processingState == .processing }) {
                // Return progress based on processing stage
                switch currentPage.processingState {
                case .pending:
                    return 0.0
                case .processing:
                    return 0.5 // Halfway through processing
                case .completed:
                    return 1.0
                case .failed:
                    return 0.0
                }
            }

            // If no page is currently processing, return overall completion
            return Double(processedPagesCount) / Double(totalPagesScanned)
        }
        set {
            // In a real implementation, this would update the current page's progress
            // For now, this is a computed property
        }
    }

    /// Overall session progress including all pages
    public var overallProgress: Double {
        guard !pages.isEmpty else { return 0.0 }

        // Calculate progress based on completed pages
        let completedPages = Double(processedPagesCount)
        let totalPages = Double(totalPagesScanned)

        // If we have a page in progress, add partial progress
        let inProgressBonus: Double = {
            if let _ = pages.first(where: { $0.processingState == .processing }) {
                return currentPageProgress / totalPages
            }
            return 0.0
        }()

        let baseProgress = completedPages / totalPages
        return min(1.0, baseProgress + inProgressBonus)
    }

    /// Updates progress for the current scanning session
    public func updateProgress(
        currentPageProgress: Double,
        using progressClient: ProgressClient
    ) async {
        guard let sessionId = progressSessionId else { return }

        // Create progress update based on current session state
        let currentPhase: ProgressPhase = {
            switch sessionState {
            case .active:
                if processedPagesCount == 0 {
                    return .initializing
                } else if processedPagesCount < totalPagesScanned {
                    return .processing
                } else {
                    return .finalizing
                }
            case .paused:
                return .initializing
            case .completed:
                return .completed
            case .cancelled:
                return .error
            }
        }()

        let progressMessage: String = {
            if totalPagesScanned == 0 {
                return "Preparing to scan..."
            } else if processedPagesCount < totalPagesScanned {
                return "Processing page \(processedPagesCount + 1) of \(totalPagesScanned)"
            } else {
                return "Finalizing document..."
            }
        }()

        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: currentPhase,
            phaseProgress: currentPageProgress,
            overallProgress: overallProgress,
            operation: progressMessage,
            metadata: [
                "session_id": id.uuidString,
                "total_pages": "\(totalPagesScanned)",
                "processed_pages": "\(processedPagesCount)",
                "current_page_progress": "\(currentPageProgress)"
            ]
        )

        await progressClient.submitUpdate(update)
    }
}

// MARK: - Progress Integration with Existing DocumentImageProcessor
// Note: DocumentImageProcessor.ProcessingProgress already exists and is used by the existing implementation
