@testable import AppCore
import ComposableArchitecture
import XCTest

@MainActor
final class ProgressClientTests: XCTestCase {
    func testProgressClientAvailability() {
        let client = ProgressClient.testValue
        XCTAssertTrue(client.isAvailable())
    }

    func testStartSessionReturnsStream() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        let stream = await client.startSession(sessionId)

        var receivedUpdates: [ProgressUpdate] = []
        var iterator = stream.makeAsyncIterator()

        // Get the first update (initial)
        if let firstUpdate = await iterator.next() {
            receivedUpdates.append(firstUpdate)
            XCTAssertEqual(firstUpdate.sessionId, sessionId)
            XCTAssertEqual(firstUpdate.phase, .initializing)
        }

        // Get a few more updates
        for _ in 0 ..< 3 {
            if let update = await iterator.next() {
                receivedUpdates.append(update)
            }
        }

        XCTAssertGreaterThan(receivedUpdates.count, 1)
        XCTAssertTrue(receivedUpdates.allSatisfy { $0.sessionId == sessionId })
    }

    func testGetSessionStateReturnsValidState() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        let state = await client.getSessionState(sessionId)

        XCTAssertNotNil(state)
        XCTAssertEqual(state?.sessionId, sessionId)
    }

    func testGetActiveSessionsReturnsArray() async {
        let client = ProgressClient.testValue

        let sessions = await client.getActiveSessions()

        XCTAssertNotNil(sessions)
    }

    func testSubmitUpdateDoesNotThrow() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()
        let update = ProgressUpdate.phaseTransition(sessionId: sessionId, to: .scanning)

        // Should not throw
        await client.submitUpdate(update)
    }

    func testCancelSessionDoesNotThrow() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        // Should not throw
        await client.cancelSession(sessionId)
    }

    func testCompleteSessionDoesNotThrow() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        // Should not throw
        await client.completeSession(sessionId)
    }

    // MARK: - Convenience Methods Tests

    func testStartSessionWithoutConfig() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        let stream = await client.startSession(sessionId)
        var iterator = stream.makeAsyncIterator()

        let firstUpdate = await iterator.next()
        XCTAssertNotNil(firstUpdate)
        XCTAssertEqual(firstUpdate?.sessionId, sessionId)
    }

    func testSubmitPhaseTransition() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        // Should not throw
        await client.submitPhaseTransition(sessionId: sessionId, to: .scanning)
        await client.submitPhaseTransition(
            sessionId: sessionId,
            to: .processing,
            metadata: ["test": "metadata"]
        )
    }

    func testSubmitPhaseProgress() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        // Should not throw
        await client.submitPhaseProgress(
            sessionId: sessionId,
            phase: .scanning,
            progress: 0.5
        )

        await client.submitPhaseProgress(
            sessionId: sessionId,
            phase: .processing,
            progress: 0.75,
            operation: "Custom operation",
            estimatedTimeRemaining: 30.0
        )
    }

    func testSubmitError() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        // Should not throw
        await client.submitError(
            sessionId: sessionId,
            phase: .scanning,
            phaseProgress: 0.3,
            error: "Test error message"
        )

        await client.submitError(
            sessionId: sessionId,
            phase: .ocr,
            phaseProgress: 0.8,
            error: "OCR failed",
            metadata: ["error_code": "E001"]
        )
    }

    func testTrackProgressCallbackSuccess() async throws {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        let result = try await client.trackProgressCallback(
            sessionId: sessionId,
            phase: .processing
        ) {
            // Simulate successful operation
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            return "Success result"
        }

        XCTAssertEqual(result, "Success result")
    }

    func testTrackProgressCallbackFailure() async {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        do {
            _ = try await client.trackProgressCallback(
                sessionId: sessionId,
                phase: .ocr
            ) {
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testTrackProgressCallbackWithMapper() async throws {
        let client = ProgressClient.testValue
        let sessionId = UUID()

        let result = try await client.trackProgressCallback(
            sessionId: sessionId,
            phase: .processing,
            operation: {
                42
            },
            progressMapper: { progress in
                // Double the progress
                min(1.0, progress * 2.0)
            }
        )

        XCTAssertEqual(result, 42)
    }
}

// MARK: - Integration Tests with DependencyValues

final class ProgressClientDependencyTests: XCTestCase {
    func testDependencyRegistration() {
        let dependencies = DependencyValues()
        let client = dependencies.progressClient

        XCTAssertNotNil(client)
    }

    func testDependencyCanBeOverridden() {
        var dependencies = DependencyValues()
        let customClient = ProgressClient.testValue

        dependencies.progressClient = customClient

        XCTAssertTrue(dependencies.progressClient.isAvailable())
    }
}
