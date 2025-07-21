import ComposableArchitecture
import Foundation

/// Bridge between existing progress systems and the new ProgressClient
public actor ProgressBridge {
    
    private var activeProgressSessions: [UUID: ProgressSession] = [:]
    
    // MARK: - Session Management
    
    public init() {}
    
    /// Create a progress bridge for a specific session
    public func createProgressSession(
        sessionId: UUID,
        progressClient: ProgressClient
    ) async -> ProgressSession {
        let session = ProgressSession(
            sessionId: sessionId,
            progressClient: progressClient
        )
        
        activeProgressSessions[sessionId] = session
        
        return session
    }
    
    /// Remove a progress session
    public func removeProgressSession(_ sessionId: UUID) async {
        activeProgressSessions.removeValue(forKey: sessionId)
    }
    
    /// Get an active progress session
    public func getProgressSession(_ sessionId: UUID) async -> ProgressSession? {
        return activeProgressSessions[sessionId]
    }
}

// MARK: - Progress Session

/// Represents an active progress tracking session that bridges different progress systems
public class ProgressSession: @unchecked Sendable {
    private let sessionId: UUID
    private let progressClient: ProgressClient
    private var currentPhase: ProgressPhase = .initializing
    
    public init(sessionId: UUID, progressClient: ProgressClient) {
        self.sessionId = sessionId
        self.progressClient = progressClient
    }
    
    /// Create a DocumentImageProcessor progress callback
    public func createProcessingProgressCallback() -> (@Sendable (ProcessingProgress) -> Void) {
        return { [weak self, sessionId, progressClient] processingProgress in
            guard let self = self else { return }
            
            Task {
                let progressPhase: ProgressPhase = .processing
                self.currentPhase = progressPhase
                
                let update = ProgressUpdate.phaseUpdate(
                    sessionId: sessionId,
                    phase: progressPhase,
                    phaseProgress: processingProgress.stepProgress,
                    operation: "Processing: \(processingProgress.currentStep.displayName)",
                    estimatedTimeRemaining: processingProgress.estimatedTimeRemaining
                )
                
                await progressClient.submitUpdate(update)
            }
        }
    }
    
    /// Create an OCR progress callback
    public func createOCRProgressCallback() -> (@Sendable (OCRProgress) -> Void) {
        return { [weak self, sessionId, progressClient] ocrProgress in
            guard let self = self else { return }
            
            Task {
                let progressPhase: ProgressPhase = .ocr
                self.currentPhase = progressPhase
                
                let operation = switch ocrProgress.currentStep {
                case .preprocessing:
                    "Preparing image for OCR..."
                case .textDetection:
                    "Detecting text regions..."
                case .textRecognition:
                    "Recognizing text (\(ocrProgress.recognizedTextCount) items)..."
                case .languageDetection:
                    "Detecting language..."
                case .structureAnalysis:
                    "Analyzing document structure..."
                case .postprocessing:
                    "Post-processing results..."
                }
                
                let update = ProgressUpdate.phaseUpdate(
                    sessionId: sessionId,
                    phase: progressPhase,
                    phaseProgress: ocrProgress.stepProgress,
                    operation: operation,
                    estimatedTimeRemaining: ocrProgress.estimatedTimeRemaining
                )
                
                await progressClient.submitUpdate(update)
            }
        }
    }
    
    /// Create a VisionKit scanning progress callback
    public func createScanningProgressCallback() -> (@Sendable (Double) -> Void) {
        return { [weak self, sessionId, progressClient] scanProgress in
            guard let self = self else { return }
            
            Task {
                let progressPhase: ProgressPhase = .scanning
                self.currentPhase = progressPhase
                
                let update = ProgressUpdate.phaseUpdate(
                    sessionId: sessionId,
                    phase: progressPhase,
                    phaseProgress: scanProgress,
                    operation: "Scanning document..."
                )
                
                await progressClient.submitUpdate(update)
            }
        }
    }
    
    /// Create a form population progress callback
    public func createFormPopulationProgressCallback() -> (@Sendable (String, Double) -> Void) {
        return { [weak self, sessionId, progressClient] fieldName, progress in
            guard let self = self else { return }
            
            Task {
                let progressPhase: ProgressPhase = .formPopulation
                self.currentPhase = progressPhase
                
                let update = ProgressUpdate.phaseUpdate(
                    sessionId: sessionId,
                    phase: progressPhase,
                    phaseProgress: progress,
                    operation: "Auto-filling \(fieldName)..."
                )
                
                await progressClient.submitUpdate(update)
            }
        }
    }
    
    /// Submit a phase transition
    public func transitionToPhase(_ phase: ProgressPhase, operation: String? = nil) async {
        currentPhase = phase
        
        let update = ProgressUpdate.phaseTransition(
            sessionId: sessionId,
            to: phase,
            metadata: operation.map { ["operation": $0] } ?? [:]
        )
        
        await progressClient.submitUpdate(update)
    }
    
    /// Submit an error
    public func submitError(_ error: String, phase: ProgressPhase? = nil) async {
        let errorPhase = phase ?? currentPhase
        
        let update = ProgressUpdate.error(
            sessionId: sessionId,
            phase: errorPhase,
            phaseProgress: 0.0,
            error: error
        )
        
        await progressClient.submitUpdate(update)
    }
    
    /// Complete the session
    public func complete() async {
        let update = ProgressUpdate.completion(sessionId: sessionId)
        await progressClient.submitUpdate(update)
    }
}

// MARK: - Dependency Registration

extension ProgressBridge: DependencyKey {
    public static let liveValue: ProgressBridge = ProgressBridge()
    public static let testValue: ProgressBridge = ProgressBridge()
}

public extension DependencyValues {
    var progressBridge: ProgressBridge {
        get { self[ProgressBridge.self] }
        set { self[ProgressBridge.self] = newValue }
    }
}