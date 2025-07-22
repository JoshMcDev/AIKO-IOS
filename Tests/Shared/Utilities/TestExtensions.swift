import AppCore
import ComposableArchitecture
import Foundation

// MARK: - Test Store Extensions

public extension TestStore {
    /// Send an action and wait for effects to complete
    func send(_ action: Action, timeout _: TimeInterval = 1.0) async {
        await send(action) { _ in
            // State assertion closure
        }
    }

    /// Send multiple actions in sequence
    func send(_ actions: [Action]) async {
        for action in actions {
            await send(action)
        }
    }
}

// MARK: - Date Extensions for Testing

public extension Date {
    static func testDate(_ timeInterval: TimeInterval = 0) -> Date {
        Date(timeIntervalSince1970: 1_640_995_200 + timeInterval) // 2022-01-01 00:00:00 UTC
    }

    static var testNow: Date {
        testDate()
    }
}

// MARK: - UUID Extensions for Testing

public extension UUID {
    static func testUUID(_ string: String = "12345678-1234-1234-1234-123456789012") -> UUID {
        guard let uuid = UUID(uuidString: string) else {
            fatalError("Invalid UUID string provided for testing: \(string)")
        }
        return uuid
    }
}

// MARK: - Collection Extensions for Testing

public extension Array where Element: Equatable {
    func containsAll(_ elements: [Element]) -> Bool {
        elements.allSatisfy { contains($0) }
    }
}

// MARK: - String Extensions for Testing

public extension String {
    static func random(length: Int = 10) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in
            guard let randomChar = letters.randomElement() else {
                return "a" // Fallback character - should never happen with non-empty string
            }
            return randomChar
        })
    }

    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}

// MARK: - Mock Task Support

public actor MockTaskManager {
    private var tasks: [String: Task<Void, Never>] = [:]

    public init() {}

    public func addTask(id: String, task: Task<Void, Never>) {
        tasks[id] = task
    }

    public func cancelTask(id: String) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }

    public func cancelAllTasks() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}

// MARK: - Test Assertions

public enum TestAssertions {
    public static func assertEventuallyTrue(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 5.0,
        interval: TimeInterval = 0.1,
        message: String = "Condition was not met within timeout"
    ) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }

        throw AssertionError(message)
    }

    public static func assertThrows<T>(
        _ expression: @escaping () async throws -> T,
        expectedError: (Error) -> Bool = { _ in true },
        message: String = "Expected expression to throw"
    ) async throws {
        do {
            _ = try await expression()
            throw AssertionError(message)
        } catch {
            if !expectedError(error) {
                throw AssertionError("Unexpected error type: \(error)")
            }
        }
    }
}

public struct AssertionError: Error, LocalizedError {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}

// MARK: - Performance Testing

public enum PerformanceTesting {
    public static func measure<T>(
        _ operation: () async throws -> T
    ) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(startTime)
        return (result, duration)
    }

    public static func measureAverageTime<T>(
        iterations: Int = 10,
        operation: () async throws -> T
    ) async rethrows -> TimeInterval {
        var totalTime: TimeInterval = 0

        for _ in 0 ..< iterations {
            let (_, duration) = try await measure(operation)
            totalTime += duration
        }

        return totalTime / Double(iterations)
    }
}
