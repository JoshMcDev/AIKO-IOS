@testable import AppCore
import XCTest

final class ProgressModelsTests: XCTestCase {
    // MARK: - ProgressPhase Tests

    func testProgressPhaseDisplayNames() {
        XCTAssertEqual(ProgressPhase.initializing.displayName, "Initializing")
        XCTAssertEqual(ProgressPhase.scanning.displayName, "Scanning Document")
        XCTAssertEqual(ProgressPhase.processing.displayName, "Processing Image")
        XCTAssertEqual(ProgressPhase.ocr.displayName, "Recognizing Text")
        XCTAssertEqual(ProgressPhase.formPopulation.displayName, "Populating Form")
        XCTAssertEqual(ProgressPhase.finalizing.displayName, "Finalizing")
        XCTAssertEqual(ProgressPhase.completed.displayName, "Completed")
        XCTAssertEqual(ProgressPhase.error.displayName, "Error")
    }

    func testProgressPhaseOperationDescriptions() {
        XCTAssertEqual(ProgressPhase.initializing.operationDescription, "Setting up document scanning...")
        XCTAssertEqual(ProgressPhase.scanning.operationDescription, "Capturing document with camera...")
        XCTAssertEqual(ProgressPhase.processing.operationDescription, "Enhancing image quality...")
        XCTAssertEqual(ProgressPhase.ocr.operationDescription, "Extracting text from document...")
        XCTAssertEqual(ProgressPhase.formPopulation.operationDescription, "Auto-filling form fields...")
        XCTAssertEqual(ProgressPhase.finalizing.operationDescription, "Completing processing...")
        XCTAssertEqual(ProgressPhase.completed.operationDescription, "Document processing complete")
        XCTAssertEqual(ProgressPhase.error.operationDescription, "An error occurred")
    }

    func testProgressPhaseRelativeDurations() {
        let totalDuration = ProgressPhase.allCases
            .filter { !$0.isTerminal }
            .reduce(0.0) { $0 + $1.relativeDuration }

        XCTAssertEqual(totalDuration, 1.0, accuracy: 0.01)
    }

    func testProgressPhaseCancellation() {
        XCTAssertTrue(ProgressPhase.initializing.canCancel)
        XCTAssertTrue(ProgressPhase.scanning.canCancel)
        XCTAssertTrue(ProgressPhase.processing.canCancel)
        XCTAssertTrue(ProgressPhase.ocr.canCancel)
        XCTAssertTrue(ProgressPhase.formPopulation.canCancel)
        XCTAssertTrue(ProgressPhase.finalizing.canCancel)
        XCTAssertFalse(ProgressPhase.completed.canCancel)
        XCTAssertFalse(ProgressPhase.error.canCancel)
    }

    func testProgressPhaseTerminalStates() {
        XCTAssertFalse(ProgressPhase.initializing.isTerminal)
        XCTAssertFalse(ProgressPhase.scanning.isTerminal)
        XCTAssertFalse(ProgressPhase.processing.isTerminal)
        XCTAssertFalse(ProgressPhase.ocr.isTerminal)
        XCTAssertFalse(ProgressPhase.formPopulation.isTerminal)
        XCTAssertFalse(ProgressPhase.finalizing.isTerminal)
        XCTAssertTrue(ProgressPhase.completed.isTerminal)
        XCTAssertTrue(ProgressPhase.error.isTerminal)
    }

    // MARK: - ProgressUpdate Tests

    func testProgressUpdateInitialization() {
        let sessionId = UUID()
        let timestamp = Date()

        let update = ProgressUpdate(
            sessionId: sessionId,
            timestamp: timestamp,
            phase: .scanning,
            phaseProgress: 0.5,
            overallProgress: 0.3,
            operation: "Custom operation",
            metadata: ["key": "value"],
            estimatedTimeRemaining: 30.0
        )

        XCTAssertEqual(update.sessionId, sessionId)
        XCTAssertEqual(update.timestamp, timestamp)
        XCTAssertEqual(update.phase, .scanning)
        XCTAssertEqual(update.phaseProgress, 0.5)
        XCTAssertEqual(update.overallProgress, 0.3)
        XCTAssertEqual(update.operation, "Custom operation")
        XCTAssertEqual(update.metadata["key"], "value")
        XCTAssertEqual(update.estimatedTimeRemaining, 30.0)
    }

    func testProgressUpdateBoundsClamping() {
        let sessionId = UUID()

        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: -0.5, // Should be clamped to 0.0
            overallProgress: 1.5 // Should be clamped to 1.0
        )

        XCTAssertEqual(update.phaseProgress, 0.0)
        XCTAssertEqual(update.overallProgress, 1.0)
    }

    func testProgressUpdateDefaultValues() {
        let sessionId = UUID()

        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: 0.5,
            overallProgress: 0.3
        )

        XCTAssertEqual(update.operation, ProgressPhase.scanning.operationDescription)
        XCTAssertTrue(update.metadata.isEmpty)
        XCTAssertNil(update.estimatedTimeRemaining)
    }

    func testProgressUpdatePhaseUpdate() {
        let sessionId = UUID()

        let update = ProgressUpdate.phaseUpdate(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: 0.5
        )

        XCTAssertEqual(update.sessionId, sessionId)
        XCTAssertEqual(update.phase, .scanning)
        XCTAssertEqual(update.phaseProgress, 0.5)
        XCTAssertGreaterThan(update.overallProgress, 0.0)
    }

    func testProgressUpdatePhaseTransition() {
        let sessionId = UUID()

        let update = ProgressUpdate.phaseTransition(
            sessionId: sessionId,
            to: .processing
        )

        XCTAssertEqual(update.sessionId, sessionId)
        XCTAssertEqual(update.phase, .processing)
        XCTAssertEqual(update.phaseProgress, 0.0)
    }

    func testProgressUpdateCompletion() {
        let sessionId = UUID()

        let update = ProgressUpdate.completion(sessionId: sessionId)

        XCTAssertEqual(update.sessionId, sessionId)
        XCTAssertEqual(update.phase, .completed)
        XCTAssertEqual(update.phaseProgress, 1.0)
        XCTAssertEqual(update.overallProgress, 1.0)
        XCTAssertEqual(update.estimatedTimeRemaining, 0)
    }

    func testProgressUpdateError() {
        let sessionId = UUID()
        let errorMessage = "Test error"

        let update = ProgressUpdate.error(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: 0.3,
            error: errorMessage
        )

        XCTAssertEqual(update.sessionId, sessionId)
        XCTAssertEqual(update.phase, .error)
        XCTAssertEqual(update.phaseProgress, 0.3)
        XCTAssertEqual(update.metadata["error"], errorMessage)
        XCTAssertEqual(update.metadata["failed_phase"], "scanning")
    }

    // MARK: - ProgressState Tests

    func testProgressStateInitialization() {
        let sessionId = UUID()
        let startTime = Date()

        let state = ProgressState(
            sessionId: sessionId,
            currentPhase: .scanning,
            phaseProgress: 0.5,
            overallProgress: 0.3,
            currentOperation: "Test operation",
            startTime: startTime,
            updateCount: 5
        )

        XCTAssertEqual(state.sessionId, sessionId)
        XCTAssertEqual(state.currentPhase, .scanning)
        XCTAssertEqual(state.phaseProgress, 0.5)
        XCTAssertEqual(state.overallProgress, 0.3)
        XCTAssertEqual(state.currentOperation, "Test operation")
        XCTAssertEqual(state.startTime, startTime)
        XCTAssertEqual(state.updateCount, 5)
        XCTAssertTrue(state.canCancel)
    }

    func testProgressStateBoundsClamping() {
        let sessionId = UUID()

        let state = ProgressState(
            sessionId: sessionId,
            currentPhase: .scanning,
            phaseProgress: -0.5, // Should be clamped to 0.0
            overallProgress: 1.5, // Should be clamped to 1.0
            currentOperation: "Test"
        )

        XCTAssertEqual(state.phaseProgress, 0.0)
        XCTAssertEqual(state.overallProgress, 1.0)
    }

    func testProgressStateInitialState() {
        let sessionId = UUID()

        let state = ProgressState.initial(sessionId: sessionId)

        XCTAssertEqual(state.sessionId, sessionId)
        XCTAssertEqual(state.currentPhase, .initializing)
        XCTAssertEqual(state.phaseProgress, 0.0)
        XCTAssertEqual(state.overallProgress, 0.0)
        XCTAssertEqual(state.updateCount, 0)
        XCTAssertFalse(state.canCancel)
    }

    func testProgressStateApplyingUpdate() {
        let sessionId = UUID()
        let initialState = ProgressState.initial(sessionId: sessionId)

        let update = ProgressUpdate.phaseTransition(sessionId: sessionId, to: .scanning)
        let newState = initialState.applying(update)

        XCTAssertEqual(newState.sessionId, sessionId)
        XCTAssertEqual(newState.currentPhase, .scanning)
        XCTAssertEqual(newState.updateCount, initialState.updateCount + 1)
        XCTAssertEqual(newState.lastUpdateTime, update.timestamp)
    }

    func testProgressStateCompleted() {
        let sessionId = UUID()
        let initialState = ProgressState.initial(sessionId: sessionId)

        let completedState = initialState.completed()

        XCTAssertEqual(completedState.currentPhase, .completed)
        XCTAssertEqual(completedState.phaseProgress, 1.0)
        XCTAssertEqual(completedState.overallProgress, 1.0)
        XCTAssertEqual(completedState.estimatedTimeRemaining, 0)
        XCTAssertFalse(completedState.canCancel)
    }

    func testProgressStateWithError() {
        let sessionId = UUID()
        let initialState = ProgressState(
            sessionId: sessionId,
            currentPhase: .scanning,
            phaseProgress: 0.5,
            overallProgress: 0.3,
            currentOperation: "Scanning"
        )

        let error = ProgressError(
            type: .serviceFailure,
            message: "Service failed"
        )

        let errorState = initialState.withError(error)

        XCTAssertEqual(errorState.currentPhase, .error)
        XCTAssertEqual(errorState.phaseProgress, 0.5) // Preserved
        XCTAssertEqual(errorState.overallProgress, 0.3) // Preserved
        XCTAssertEqual(errorState.errorState, error)
        XCTAssertFalse(errorState.canCancel)
    }

    // MARK: - ProcessingSpeed Tests

    func testProcessingSpeedInitialization() {
        let speed = ProcessingSpeed(
            operationsPerSecond: 5.0,
            updateFrequency: 10.0,
            efficiency: 0.85
        )

        XCTAssertEqual(speed.operationsPerSecond, 5.0)
        XCTAssertEqual(speed.updateFrequency, 10.0)
        XCTAssertEqual(speed.efficiency, 0.85)
    }

    func testProcessingSpeedBoundsClamping() {
        let speed = ProcessingSpeed(
            operationsPerSecond: -1.0, // Should be clamped to 0
            updateFrequency: -2.0, // Should be clamped to 0
            efficiency: 1.5 // Should be clamped to 1.0
        )

        XCTAssertEqual(speed.operationsPerSecond, 0.0)
        XCTAssertEqual(speed.updateFrequency, 0.0)
        XCTAssertEqual(speed.efficiency, 1.0)
    }

    // MARK: - ProgressError Tests

    func testProgressErrorInitialization() {
        let error = ProgressError(
            type: .networkError,
            message: "Network connection failed",
            metadata: ["code": "E001"],
            isRecoverable: false
        )

        XCTAssertEqual(error.type, .networkError)
        XCTAssertEqual(error.message, "Network connection failed")
        XCTAssertEqual(error.metadata["code"], "E001")
        XCTAssertFalse(error.isRecoverable)
        XCTAssertEqual(error.errorDescription, "Network connection failed")
    }

    func testProgressErrorDefaultValues() {
        let error = ProgressError(
            type: .unknown,
            message: "Unknown error"
        )

        XCTAssertTrue(error.metadata.isEmpty)
        XCTAssertTrue(error.isRecoverable) // Default is true
    }

    func testProgressErrorTypeDisplayNames() {
        XCTAssertEqual(ProgressErrorType.tracking.displayName, "Tracking Error")
        XCTAssertEqual(ProgressErrorType.cancelled.displayName, "Cancelled")
        XCTAssertEqual(ProgressErrorType.timeout.displayName, "Timeout")
        XCTAssertEqual(ProgressErrorType.serviceFailure.displayName, "Service Error")
        XCTAssertEqual(ProgressErrorType.networkError.displayName, "Network Error")
        XCTAssertEqual(ProgressErrorType.unknown.displayName, "Unknown Error")
    }

    // MARK: - ProgressSessionConfig Tests

    func testProgressSessionConfigInitialization() {
        let config = ProgressSessionConfig(
            maxUpdateFrequency: 8.0,
            minProgressDelta: 0.02,
            sessionTimeout: 120.0,
            enableTimeEstimation: false,
            trackProcessingSpeed: false,
            enableAccessibilityAnnouncements: false,
            announcementMilestones: [0.5, 1.0],
            batchUpdateWindow: 0.05,
            persistState: true,
            metadata: ["test": "config"]
        )

        XCTAssertEqual(config.maxUpdateFrequency, 8.0)
        XCTAssertEqual(config.minProgressDelta, 0.02)
        XCTAssertEqual(config.sessionTimeout, 120.0)
        XCTAssertFalse(config.enableTimeEstimation)
        XCTAssertFalse(config.trackProcessingSpeed)
        XCTAssertFalse(config.enableAccessibilityAnnouncements)
        XCTAssertEqual(config.announcementMilestones, [0.5, 1.0])
        XCTAssertEqual(config.batchUpdateWindow, 0.05)
        XCTAssertTrue(config.persistState)
        XCTAssertEqual(config.metadata["test"], "config")
    }

    func testProgressSessionConfigDefaultValues() {
        let config = ProgressSessionConfig()

        XCTAssertEqual(config.maxUpdateFrequency, 5.0)
        XCTAssertEqual(config.minProgressDelta, 0.01)
        XCTAssertEqual(config.sessionTimeout, 300.0)
        XCTAssertTrue(config.enableTimeEstimation)
        XCTAssertTrue(config.trackProcessingSpeed)
        XCTAssertTrue(config.enableAccessibilityAnnouncements)
        XCTAssertEqual(config.announcementMilestones, [0.25, 0.5, 0.75, 1.0])
        XCTAssertEqual(config.batchUpdateWindow, 0.1)
        XCTAssertFalse(config.persistState)
        XCTAssertTrue(config.metadata.isEmpty)
    }

    func testProgressSessionConfigBoundsClamping() {
        let config = ProgressSessionConfig(
            maxUpdateFrequency: 20.0, // Should be clamped to 10.0
            minProgressDelta: 0.2, // Should be clamped to 0.1
            sessionTimeout: 5.0, // Should be clamped to 10.0
            batchUpdateWindow: 2.0 // Should be clamped to 1.0
        )

        XCTAssertEqual(config.maxUpdateFrequency, 10.0)
        XCTAssertEqual(config.minProgressDelta, 0.1)
        XCTAssertEqual(config.sessionTimeout, 10.0)
        XCTAssertEqual(config.batchUpdateWindow, 1.0)
    }

    func testProgressSessionConfigPresets() {
        // Test real-time preset
        let realTime = ProgressSessionConfig.realTime
        XCTAssertEqual(realTime.maxUpdateFrequency, 10.0)
        XCTAssertEqual(realTime.batchUpdateWindow, 0.05)
        XCTAssertTrue(realTime.enableTimeEstimation)

        // Test balanced preset
        let balanced = ProgressSessionConfig.balanced
        XCTAssertEqual(balanced.maxUpdateFrequency, 5.0)
        XCTAssertEqual(balanced.batchUpdateWindow, 0.1)

        // Test battery optimized preset
        let batteryOptimized = ProgressSessionConfig.batteryOptimized
        XCTAssertEqual(batteryOptimized.maxUpdateFrequency, 2.0)
        XCTAssertFalse(batteryOptimized.enableTimeEstimation)
        XCTAssertFalse(batteryOptimized.trackProcessingSpeed)

        // Test accessibility preset
        let accessibility = ProgressSessionConfig.accessibility
        XCTAssertTrue(accessibility.enableAccessibilityAnnouncements)
        XCTAssertEqual(accessibility.announcementMilestones, [0.1, 0.25, 0.5, 0.75, 0.9, 1.0])

        // Test testing preset
        let testing = ProgressSessionConfig.testing
        XCTAssertEqual(testing.maxUpdateFrequency, 20.0)
        XCTAssertEqual(testing.sessionTimeout, 30.0)
        XCTAssertEqual(testing.metadata["environment"], "testing")
    }

    func testProgressSessionConfigValidation() {
        let validConfig = ProgressSessionConfig()
        XCTAssertTrue(validConfig.isValid)

        let invalidConfig = ProgressSessionConfig(
            maxUpdateFrequency: 0.0,
            minProgressDelta: 0.0
        )
        XCTAssertFalse(invalidConfig.isValid)
    }

    func testProgressSessionConfigUpdateInterval() {
        let config = ProgressSessionConfig(maxUpdateFrequency: 5.0)
        XCTAssertEqual(config.updateInterval, 0.2) // 1/5
    }

    func testProgressSessionConfigShouldBatchUpdates() {
        let batchingConfig = ProgressSessionConfig(
            maxUpdateFrequency: 5.0, // 0.2s interval
            batchUpdateWindow: 0.3 // > 0.2s
        )
        XCTAssertTrue(batchingConfig.shouldBatchUpdates)

        let nonBatchingConfig = ProgressSessionConfig(
            maxUpdateFrequency: 5.0, // 0.2s interval
            batchUpdateWindow: 0.1 // < 0.2s
        )
        XCTAssertFalse(nonBatchingConfig.shouldBatchUpdates)
    }
}
