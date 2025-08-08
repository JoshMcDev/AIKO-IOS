import Foundation
import XCTest

// MARK: - Shared Test Utilities

/// Common test error types used across GraphRAG test suites
public enum GraphRAGTestError: Error, LocalizedError {
    case serviceNotInitialized
    case invalidTestData
    case testTimeout
    case assertionFailure(String)

    public var errorDescription: String? {
        switch self {
        case .serviceNotInitialized:
            "Test service was not properly initialized"
        case .invalidTestData:
            "Test data is invalid or corrupted"
        case .testTimeout:
            "Test operation timed out"
        case let .assertionFailure(message):
            "Test assertion failed: \(message)"
        }
    }
}

// MARK: - Test Utilities Extension

public extension XCTestCase {
    /// Safely unwrap an optional service with a clear failure message
    func unwrapService<T>(_ service: T?, file: StaticString = #filePath, line: UInt = #line) throws -> T {
        guard let service else {
            XCTFail("Service not initialized", file: file, line: line)
            throw GraphRAGTestError.serviceNotInitialized
        }
        return service
    }

    /// Assert that an async operation completes within a specified timeout
    func assertAsyncTimeout<T: Sendable>(
        timeout: TimeInterval = 5.0,
        operation: @escaping @Sendable () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw GraphRAGTestError.testTimeout
            }

            guard let result = try await group.next() else {
                XCTFail("No result from async operation", file: file, line: line)
                throw GraphRAGTestError.testTimeout
            }

            group.cancelAll()
            return result
        }
    }
}
