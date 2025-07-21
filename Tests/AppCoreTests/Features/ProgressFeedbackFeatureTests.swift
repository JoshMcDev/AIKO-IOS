import XCTest
@testable import AppCore
import ComposableArchitecture
import Combine
import Foundation

@MainActor
final class ProgressFeedbackFeatureTests: XCTestCase {
    
    // MARK: - State Tests
    
    func testProgressFeedbackFeatureStateInitialization() {
        let state = ProgressFeedbackFeature.State()
        
        XCTAssertTrue(state.activeSessions.isEmpty)
        XCTAssertNil(state.currentSession)
        XCTAssertTrue(state.accessibilityAnnouncements.isEmpty)
        XCTAssertTrue(state.lastAnnouncedProgress.isEmpty)
        XCTAssertNil(state.currentProgress)
        XCTAssertFalse(state.isActive)
    }
    
    func testProgressFeedbackFeatureStateWithActiveSessions() {
        var state = ProgressFeedbackFeature.State()
        let sessionId = UUID()
        let progressState = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Scanning page 1"
        )
        
        state.activeSessions[sessionId] = progressState
        state.currentSession = sessionId
        
        XCTAssertEqual(state.activeSessions.count, 1)
        XCTAssertEqual(state.currentSession, sessionId)
        XCTAssertEqual(state.currentProgress?.phase, .scanning)
        XCTAssertTrue(state.isActive)
    }
    
    func testProgressFeedbackFeatureStateCurrentProgressWithNoCurrentSession() {
        var state = ProgressFeedbackFeature.State()
        let sessionId = UUID()
        state.activeSessions[sessionId] = ProgressState(
            phase: .processing,
            fractionCompleted: 0.7,
            currentStep: "Processing"
        )
        // Don't set currentSession
        
        XCTAssertNil(state.currentProgress)
        XCTAssertTrue(state.isActive) // Still active due to sessions
    }
    
    // MARK: - Start Session Action Tests
    
    func testStartSessionAction() async {
        let store = TestStore(initialState: ProgressFeedbackFeature.State()) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        let config = ProgressSessionConfig.defaultSinglePageScan
        await store.send(.startSession(config))
        
        await store.receive(._sessionCreated) { state in
            XCTAssertEqual(state.activeSessions.count, 1)
            XCTAssertNotNil(state.currentSession)
            
            let firstSession = state.activeSessions.first
            XCTAssertEqual(firstSession?.value.phase, .preparing)
            XCTAssertEqual(firstSession?.value.fractionCompleted, 0.0)
            XCTAssertEqual(firstSession?.value.currentStep, "Initializing...")
        }
    }
    
    func testStartMultipleSessionsAction() async {
        let store = TestStore(initialState: ProgressFeedbackFeature.State()) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        await store.send(.startSession(.defaultSinglePageScan))
        await store.receive(._sessionCreated) { state in
            XCTAssertEqual(state.activeSessions.count, 1)
            XCTAssertNotNil(state.currentSession)
        }
        
        await store.send(.startSession(.defaultMultiPageScan))
        await store.receive(._sessionCreated) { state in
            XCTAssertEqual(state.activeSessions.count, 2)
            // Current session should remain the first one
            XCTAssertNotNil(state.currentSession)
        }
    }
    
    // MARK: - Update Progress Action Tests
    
    func testUpdateProgressAction() async {
        let sessionId = UUID()
        let store = TestStore(initialState: ProgressFeedbackFeature.State()) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.6,
            message: "Processing images"
        )
        
        await store.send(.updateProgress(sessionId, update))
        // No immediate state change expected, only effect sent
    }
    
    func testProgressReceivedAction() async {
        let sessionId = UUID()
        var initialState = ProgressFeedbackFeature.State()
        initialState.activeSessions[sessionId] = ProgressState(
            phase: .preparing,
            fractionCompleted: 0.0,
            currentStep: "Initial"
        )
        initialState.currentSession = sessionId
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        }
        
        let newProgressState = ProgressState(
            phase: .processing,
            fractionCompleted: 0.6,
            currentStep: "Processing images"
        )
        
        await store.send(._progressReceived(sessionId, newProgressState)) { state in
            XCTAssertEqual(state.activeSessions[sessionId]?.phase, .processing)
            XCTAssertEqual(state.activeSessions[sessionId]?.fractionCompleted, 0.6)
            XCTAssertEqual(state.activeSessions[sessionId]?.currentStep, "Processing images")
        }
    }
    
    func testProgressReceivedWithAccessibilityAnnouncement() async {
        let sessionId = UUID()
        var initialState = ProgressFeedbackFeature.State()
        initialState.activeSessions[sessionId] = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.0,
            currentStep: "Starting"
        )
        initialState.currentSession = sessionId
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        }
        
        // Progress that should trigger announcement (25% threshold)
        let newProgressState = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.25,
            currentStep: "Scanning page 1"
        )
        
        await store.send(._progressReceived(sessionId, newProgressState)) { state in
            XCTAssertEqual(state.activeSessions[sessionId]?.fractionCompleted, 0.25)
            XCTAssertEqual(state.lastAnnouncedProgress[sessionId], 25)
            XCTAssertFalse(state.accessibilityAnnouncements.isEmpty)
        }
        
        await store.receive(._announceProgress)
    }
    
    func testProgressReceivedNoAnnouncementBelowThreshold() async {
        let sessionId = UUID()
        var initialState = ProgressFeedbackFeature.State()
        initialState.activeSessions[sessionId] = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.0,
            currentStep: "Starting"
        )
        initialState.currentSession = sessionId
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        }
        
        // Progress below 25% threshold
        let newProgressState = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.15,
            currentStep: "Scanning"
        )
        
        await store.send(._progressReceived(sessionId, newProgressState)) { state in
            XCTAssertEqual(state.activeSessions[sessionId]?.fractionCompleted, 0.15)
            // No announcement should be triggered
            XCTAssertTrue(state.accessibilityAnnouncements.isEmpty)
            XCTAssertNil(state.lastAnnouncedProgress[sessionId])
        }
    }
    
    // MARK: - Complete Session Action Tests
    
    func testCompleteSessionAction() async {
        let sessionId = UUID()
        var initialState = ProgressFeedbackFeature.State()
        initialState.activeSessions[sessionId] = ProgressState(
            phase: .processing,
            fractionCompleted: 0.8,
            currentStep: "Almost done"
        )
        initialState.currentSession = sessionId
        initialState.lastAnnouncedProgress[sessionId] = 75
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        await store.send(.completeSession(sessionId))
        
        await store.receive(._sessionCompleted(sessionId)) { state in
            XCTAssertNil(state.activeSessions[sessionId])
            XCTAssertNil(state.currentSession)
            XCTAssertNil(state.lastAnnouncedProgress[sessionId])
            XCTAssertFalse(state.isActive)
        }
    }
    
    func testCompleteSessionWithMultipleSessions() async {
        let sessionId1 = UUID()
        let sessionId2 = UUID()
        
        var initialState = ProgressFeedbackFeature.State()
        initialState.activeSessions[sessionId1] = ProgressState(
            phase: .completing,
            fractionCompleted: 1.0,
            currentStep: "Complete"
        )
        initialState.activeSessions[sessionId2] = ProgressState(
            phase: .processing,
            fractionCompleted: 0.5,
            currentStep: "Processing"
        )
        initialState.currentSession = sessionId1
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        await store.send(.completeSession(sessionId1))
        
        await store.receive(._sessionCompleted(sessionId1)) { state in
            XCTAssertNil(state.activeSessions[sessionId1])
            XCTAssertNotNil(state.activeSessions[sessionId2])
            XCTAssertEqual(state.currentSession, sessionId2) // Should switch to remaining session
            XCTAssertTrue(state.isActive)
        }
    }
    
    // MARK: - Cancel Session Action Tests
    
    func testCancelSessionAction() async {
        let sessionId = UUID()
        var initialState = ProgressFeedbackFeature.State()
        initialState.activeSessions[sessionId] = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.3,
            currentStep: "Scanning"
        )
        initialState.currentSession = sessionId
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        await store.send(.cancelSession(sessionId))
        
        await store.receive(._sessionCancelled(sessionId)) { state in
            XCTAssertNil(state.activeSessions[sessionId])
            XCTAssertNil(state.currentSession)
            XCTAssertFalse(state.isActive)
        }
    }
    
    func testCancelNonExistentSession() async {
        let nonExistentSessionId = UUID()
        let store = TestStore(initialState: ProgressFeedbackFeature.State()) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        await store.send(.cancelSession(nonExistentSessionId))
        
        await store.receive(._sessionCancelled(nonExistentSessionId)) { state in
            // State should remain unchanged
            XCTAssertTrue(state.activeSessions.isEmpty)
            XCTAssertNil(state.currentSession)
            XCTAssertFalse(state.isActive)
        }
    }
    
    // MARK: - Set Current Session Action Tests
    
    func testSetCurrentSessionAction() async {
        let sessionId1 = UUID()
        let sessionId2 = UUID()
        
        var initialState = ProgressFeedbackFeature.State()
        initialState.activeSessions[sessionId1] = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.3,
            currentStep: "Scanning"
        )
        initialState.activeSessions[sessionId2] = ProgressState(
            phase: .processing,
            fractionCompleted: 0.7,
            currentStep: "Processing"
        )
        initialState.currentSession = sessionId1
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        }
        
        await store.send(.setCurrentSession(sessionId2)) { state in
            XCTAssertEqual(state.currentSession, sessionId2)
            XCTAssertEqual(state.currentProgress?.phase, .processing)
            XCTAssertEqual(state.currentProgress?.fractionCompleted, 0.7)
        }
    }
    
    func testSetCurrentSessionToNil() async {
        let sessionId = UUID()
        var initialState = ProgressFeedbackFeature.State()
        initialState.activeSessions[sessionId] = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Scanning"
        )
        initialState.currentSession = sessionId
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        }
        
        await store.send(.setCurrentSession(nil)) { state in
            XCTAssertNil(state.currentSession)
            XCTAssertNil(state.currentProgress)
            XCTAssertTrue(state.isActive) // Still active due to sessions
        }
    }
    
    // MARK: - Clear Accessibility Announcements Action Tests
    
    func testClearAccessibilityAnnouncementsAction() async {
        var initialState = ProgressFeedbackFeature.State()
        initialState.accessibilityAnnouncements = [
            "Scanning: 25% complete",
            "Processing: 50% complete",
            "Analyzing: 75% complete"
        ]
        
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        }
        
        await store.send(.clearAccessibilityAnnouncements) { state in
            XCTAssertTrue(state.accessibilityAnnouncements.isEmpty)
        }
    }
    
    // MARK: - Action Equatable Tests
    
    func testProgressFeedbackActionEquality() {
        let sessionId = UUID()
        let config = ProgressSessionConfig.defaultSinglePageScan
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Test"
        )
        let progressState = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.3,
            currentStep: "Test"
        )
        
        // Test public actions equality
        XCTAssertEqual(
            ProgressFeedbackFeature.Action.startSession(config),
            ProgressFeedbackFeature.Action.startSession(config)
        )
        
        XCTAssertEqual(
            ProgressFeedbackFeature.Action.updateProgress(sessionId, update),
            ProgressFeedbackFeature.Action.updateProgress(sessionId, update)
        )
        
        XCTAssertEqual(
            ProgressFeedbackFeature.Action.completeSession(sessionId),
            ProgressFeedbackFeature.Action.completeSession(sessionId)
        )
        
        XCTAssertEqual(
            ProgressFeedbackFeature.Action.cancelSession(sessionId),
            ProgressFeedbackFeature.Action.cancelSession(sessionId)
        )
        
        XCTAssertEqual(
            ProgressFeedbackFeature.Action.setCurrentSession(sessionId),
            ProgressFeedbackFeature.Action.setCurrentSession(sessionId)
        )
        
        XCTAssertEqual(
            ProgressFeedbackFeature.Action.clearAccessibilityAnnouncements,
            ProgressFeedbackFeature.Action.clearAccessibilityAnnouncements
        )
        
        // Test internal actions equality
        XCTAssertEqual(
            ProgressFeedbackFeature.Action._progressReceived(sessionId, progressState),
            ProgressFeedbackFeature.Action._progressReceived(sessionId, progressState)
        )
        
        XCTAssertEqual(
            ProgressFeedbackFeature.Action._sessionCompleted(sessionId),
            ProgressFeedbackFeature.Action._sessionCompleted(sessionId)
        )
        
        XCTAssertEqual(
            ProgressFeedbackFeature.Action._announceProgress,
            ProgressFeedbackFeature.Action._announceProgress
        )
    }
    
    func testProgressFeedbackActionInequality() {
        let sessionId1 = UUID()
        let sessionId2 = UUID()
        
        XCTAssertNotEqual(
            ProgressFeedbackFeature.Action.completeSession(sessionId1),
            ProgressFeedbackFeature.Action.completeSession(sessionId2)
        )
        
        XCTAssertNotEqual(
            ProgressFeedbackFeature.Action.startSession(.defaultSinglePageScan),
            ProgressFeedbackFeature.Action.startSession(.defaultMultiPageScan)
        )
        
        XCTAssertEqual(
            ProgressFeedbackFeature.Action._announceProgress,
            ProgressFeedbackFeature.Action._announceProgress
        )
    }
    
    // MARK: - CancelID Tests
    
    func testProgressFeedbackCancelIDEquality() {
        let sessionId = UUID()
        
        let cancelId1 = ProgressFeedbackFeature.CancelID.progressSubscription(sessionId)
        let cancelId2 = ProgressFeedbackFeature.CancelID.progressSubscription(sessionId)
        let cancelId3 = ProgressFeedbackFeature.CancelID.progressSubscription(UUID())
        
        XCTAssertEqual(cancelId1, cancelId2)
        XCTAssertNotEqual(cancelId1, cancelId3)
    }
    
    func testProgressFeedbackCancelIDHashable() {
        let sessionId = UUID()
        let cancelId = ProgressFeedbackFeature.CancelID.progressSubscription(sessionId)
        
        var set = Set<ProgressFeedbackFeature.CancelID>()
        set.insert(cancelId)
        
        XCTAssertTrue(set.contains(cancelId))
        XCTAssertEqual(set.count, 1)
        
        // Adding the same ID should not increase count
        set.insert(ProgressFeedbackFeature.CancelID.progressSubscription(sessionId))
        XCTAssertEqual(set.count, 1)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteProgressWorkflow() async {
        let store = TestStore(initialState: ProgressFeedbackFeature.State()) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        // Start session
        await store.send(.startSession(.defaultSinglePageScan))
        await store.receive(._sessionCreated) { state in
            XCTAssertEqual(state.activeSessions.count, 1)
            let sessionId = state.activeSessions.keys.first!
            XCTAssertEqual(state.currentSession, sessionId)
        }
        
        // Get session ID from state
        let sessionId = store.state.activeSessions.keys.first!
        
        // Send progress update
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .scanning,
            fractionCompleted: 0.5,
            message: "Halfway through"
        )
        
        await store.send(.updateProgress(sessionId, update))
        
        // Complete session
        await store.send(.completeSession(sessionId))
        await store.receive(._sessionCompleted(sessionId)) { state in
            XCTAssertTrue(state.activeSessions.isEmpty)
            XCTAssertNil(state.currentSession)
            XCTAssertFalse(state.isActive)
        }
    }
    
    // MARK: - Performance Tests
    
    func testProgressFeedbackFeaturePerformance() async {
        let store = TestStore(initialState: ProgressFeedbackFeature.State()) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        measure {
            Task {
                for _ in 0..<100 {
                    await store.send(.startSession(.defaultSinglePageScan), assert: { _ in })
                    await store.receive(._sessionCreated, assert: { _ in })
                }
            }
        }
    }
}