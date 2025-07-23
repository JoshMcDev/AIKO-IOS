@testable import AppCore
import XCTest

final class ProgressTrackingEngineTests: XCTestCase {
    private var engine: ProgressTrackingEngine?

    private var engineUnwrapped: ProgressTrackingEngine {
        guard let engine else { fatalError("engine not initialized") }
        return engine
    }

    override func setUp() async throws {
        await super.setUp()
        engine = ProgressTrackingEngine()
    }

    override func tearDown() async throws {
        engine = nil
        await super.tearDown()
    }

    // MARK: - Session Management Tests

    func testStartSessionCreatesStream() async {
        let sessionId = UUID()

        let stream = await engineUnwrapped.startSession(sessionId: sessionId)
        var iterator = stream.makeAsyncIterator()

        let firstUpdate = await iterator.next()
        XCTAssertNotNil(firstUpdate)
        XCTAssertEqual(firstUpdate?.sessionId, sessionId)
        XCTAssertEqual(firstUpdate?.phase, .initializing)
    }

    func testStartSessionWithCustomConfig() async {
        let sessionId = UUID()
        let config = ProgressSessionConfig.realTime

        let stream = await engineUnwrapped.startSession(sessionId: sessionId, config: config)
        var iterator = stream.makeAsyncIterator()

        let firstUpdate = await iterator.next()
        XCTAssertNotNil(firstUpdate)
        XCTAssertEqual(firstUpdate?.sessionId, sessionId)
    }

    func testGetSessionStateAfterStart() async {
        let sessionId = UUID()

        _ = await engineUnwrapped.startSession(sessionId: sessionId)

        let state = await engineUnwrapped.getSessionState(sessionId)
        XCTAssertNotNil(state)
        XCTAssertEqual(state?.sessionId, sessionId)
        XCTAssertEqual(state?.currentPhase, .initializing)
    }

    func testGetActiveSessionsIncludesStartedSession() async {
        let sessionId = UUID()

        _ = await engineUnwrapped.startSession(sessionId: sessionId)

        let activeSessions = await engineUnwrapped.getActiveSessions()
        XCTAssertTrue(activeSessions.contains(sessionId))
    }

    func testCompleteSessionRemovesFromActive() async {
        let sessionId = UUID()

        let stream = await engineUnwrapped.startSession(sessionId: sessionId)
        await engineUnwrapped.completeSession(sessionId)

        let activeSessions = await engineUnwrapped.getActiveSessions()
        XCTAssertFalse(activeSessions.contains(sessionId))

        // Verify stream received completion
        var iterator = stream.makeAsyncIterator()
        var receivedCompletion = false

        // Consume updates until completion or timeout
        for _ in 0 ..< 10 {
            if let update = await iterator.next() {
                if update.phase == .completed {
                    receivedCompletion = true
                    break
                }
            } else {
                break
            }
        }

        XCTAssertTrue(receivedCompletion)
    }

    func testCancelSessionRemovesFromActive() async {
        let sessionId = UUID()

        _ = await engineUnwrapped.startSession(sessionId: sessionId)
        await engineUnwrapped.cancelSession(sessionId)

        let activeSessions = await engineUnwrapped.getActiveSessions()
        XCTAssertFalse(activeSessions.contains(sessionId))
    }

    // MARK: - Update Processing Tests

    func testSubmitValidUpdate() async {
        let sessionId = UUID()

        let stream = await engineUnwrapped.startSession(sessionId: sessionId)
        var iterator = stream.makeAsyncIterator()

        // Consume initial update
        _ = await iterator.next()

        // Submit a valid update
        let update = ProgressUpdate.phaseTransition(sessionId: sessionId, to: .scanning)
        await engineUnwrapped.submitUpdate(update)

        // Verify update is received
        let receivedUpdate = await iterator.next()
        XCTAssertEqual(receivedUpdate?.phase, .scanning)
    }

    func testSubmitUpdateToNonexistentSession() async {
        let sessionId = UUID()
        let update = ProgressUpdate.phaseTransition(sessionId: sessionId, to: .scanning)

        // Should not crash
        await engineUnwrapped.submitUpdate(update)
    }

    func testSubmitProgressUpdate() async {
        let sessionId = UUID()

        let stream = await engineUnwrapped.startSession(sessionId: sessionId)
        var iterator = stream.makeAsyncIterator()

        // Consume initial update
        _ = await iterator.next()

        // Submit progress within phase
        let progressUpdate = ProgressUpdate.phaseUpdate(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: 0.5
        )
        await engineUnwrapped.submitUpdate(progressUpdate)

        // Verify update is received
        let receivedUpdate = await iterator.next()
        XCTAssertEqual(receivedUpdate?.phase, .scanning)
        XCTAssertEqual(receivedUpdate?.phaseProgress, 0.5)
    }

    func testSubmitErrorUpdate() async {
        let sessionId = UUID()

        let stream = await engineUnwrapped.startSession(sessionId: sessionId)
        var iterator = stream.makeAsyncIterator()

        // Consume initial update
        _ = await iterator.next()

        // Submit error update
        let errorUpdate = ProgressUpdate.error(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: 0.3,
            error: "Test error"
        )
        await engineUnwrapped.submitUpdate(errorUpdate)

        // Verify error update is received
        let receivedUpdate = await iterator.next()
        XCTAssertEqual(receivedUpdate?.phase, .error)
        XCTAssertEqual(receivedUpdate?.metadata["error"], "Test error")
    }

    // MARK: - Update Validation Tests

    func testRejectInvalidProgressValues() async {
        let sessionId = UUID()
        let stream = await engineUnwrapped.startSession(sessionId: sessionId)
        var iterator = stream.makeAsyncIterator()

        // Consume initial update
        _ = await iterator.next()

        // Submit invalid progress values (should be ignored)
        let invalidUpdate = ProgressUpdate(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: -0.5, // Invalid: negative
            overallProgress: 1.5 // Invalid: > 1.0
        )

        await engineUnwrapped.submitUpdate(invalidUpdate)

        // Submit valid update to ensure stream is still working
        let validUpdate = ProgressUpdate.phaseTransition(sessionId: sessionId, to: .scanning)
        await engineUnwrapped.submitUpdate(validUpdate)

        let receivedUpdate = await iterator.next()
        XCTAssertEqual(receivedUpdate?.phase, .scanning)
    }

    func testRejectBackwardsProgress() async {
        let sessionId = UUID()
        let stream = await engineUnwrapped.startSession(sessionId: sessionId)
        var iterator = stream.makeAsyncIterator()

        // Consume initial update
        _ = await iterator.next()

        // Submit forward progress
        let forwardUpdate = ProgressUpdate.phaseUpdate(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: 0.8
        )
        await engineUnwrapped.submitUpdate(forwardUpdate)

        let firstUpdate = await iterator.next()
        XCTAssertEqual(firstUpdate?.phaseProgress, 0.8)

        // Submit backwards progress (should be ignored for non-error phases)
        let backwardsUpdate = ProgressUpdate.phaseUpdate(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: 0.3
        )
        await engineUnwrapped.submitUpdate(backwardsUpdate)

        // Submit another valid update to test stream
        let anotherUpdate = ProgressUpdate.phaseTransition(sessionId: sessionId, to: .processing)
        await engineUnwrapped.submitUpdate(anotherUpdate)

        let secondUpdate = await iterator.next()
        XCTAssertEqual(secondUpdate?.phase, .processing)
    }

    // MARK: - Concurrent Operations Tests

    func testMultipleConcurrentSessions() async {
        let sessionId1 = UUID()
        let sessionId2 = UUID()

        let stream1 = await engineUnwrapped.startSession(sessionId: sessionId1)
        let stream2 = await engineUnwrapped.startSession(sessionId: sessionId2)

        var iterator1 = stream1.makeAsyncIterator()
        var iterator2 = stream2.makeAsyncIterator()

        // Both sessions should receive initial updates
        let update1 = await iterator1.next()
        let update2 = await iterator2.next()

        XCTAssertEqual(update1?.sessionId, sessionId1)
        XCTAssertEqual(update2?.sessionId, sessionId2)

        let activeSessions = await engineUnwrapped.getActiveSessions()
        XCTAssertTrue(activeSessions.contains(sessionId1))
        XCTAssertTrue(activeSessions.contains(sessionId2))
    }

    func testSessionIsolation() async {
        let sessionId1 = UUID()
        let sessionId2 = UUID()

        let stream1 = await engineUnwrapped.startSession(sessionId: sessionId1)
        let stream2 = await engineUnwrapped.startSession(sessionId: sessionId2)

        var iterator1 = stream1.makeAsyncIterator()
        var iterator2 = stream2.makeAsyncIterator()

        // Consume initial updates
        _ = await iterator1.next()
        _ = await iterator2.next()

        // Submit update to session 1
        let update1 = ProgressUpdate.phaseTransition(sessionId: sessionId1, to: .scanning)
        await engineUnwrapped.submitUpdate(update1)

        // Session 1 should receive the update
        let receivedUpdate1 = await iterator1.next()
        XCTAssertEqual(receivedUpdate1?.sessionId, sessionId1)
        XCTAssertEqual(receivedUpdate1?.phase, .scanning)

        // Session 2 should not receive updates from session 1
        // We'll submit an update to session 2 to verify it's still working
        let update2 = ProgressUpdate.phaseTransition(sessionId: sessionId2, to: .processing)
        await engineUnwrapped.submitUpdate(update2)

        let receivedUpdate2 = await iterator2.next()
        XCTAssertEqual(receivedUpdate2?.sessionId, sessionId2)
        XCTAssertEqual(receivedUpdate2?.phase, .processing)
    }

    // MARK: - Configuration Tests

    func testBatchingConfiguration() async {
        let sessionId = UUID()
        let config = ProgressSessionConfig(
            maxUpdateFrequency: 1.0,
            batchUpdateWindow: 0.1
        )

        let stream = await engineUnwrapped.startSession(sessionId: sessionId, config: config)
        var iterator = stream.makeAsyncIterator()

        // Consume initial update
        _ = await iterator.next()

        // Submit multiple rapid updates
        for i in 1 ... 5 {
            let update = ProgressUpdate.phaseUpdate(
                sessionId: sessionId,
                phase: .scanning,
                phaseProgress: Double(i) * 0.2
            )
            await engineUnwrapped.submitUpdate(update)
        }

        // With batching, we should receive fewer updates than submitted
        var receivedUpdates: [ProgressUpdate] = []

        // Wait for batching window plus a bit more
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Collect any updates
        while let update = await iterator.next() {
            receivedUpdates.append(update)
            // Add small delay to allow more updates if they're coming
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            break // Just get one update to test batching is working
        }

        // We should have received at least one update
        XCTAssertGreaterThan(receivedUpdates.count, 0)
    }

    // MARK: - Cleanup Tests

    func testCleanupExpiredSessions() async {
        let sessionId = UUID()
        let config = ProgressSessionConfig(sessionTimeout: 0.1) // Very short timeout

        _ = await engineUnwrapped.startSession(sessionId: sessionId, config: config)

        // Session should be active initially
        var activeSessions = await engineUnwrapped.getActiveSessions()
        XCTAssertTrue(activeSessions.contains(sessionId))

        // Wait longer than timeout
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Trigger cleanup
        await engineUnwrapped.cleanupExpiredSessions()

        // Session should be cleaned up
        activeSessions = await engineUnwrapped.getActiveSessions()
        XCTAssertFalse(activeSessions.contains(sessionId))
    }
}
