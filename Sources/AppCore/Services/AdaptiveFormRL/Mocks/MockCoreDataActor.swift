@preconcurrency import CoreData
import Foundation

/// Mock Core Data actor for testing adaptive form RL components
public actor MockCoreDataActor: CoreDataActor {
    // MARK: - Mock Storage

    private var storedData: [String: Any] = [:]
    private var modificationData: [String: Any] = [:]

    // MARK: - Configuration

    private let shouldSimulateFailure: Bool
    private let simulatedLatency: TimeInterval

    // MARK: - Initialization

    public init(shouldSimulateFailure: Bool = false, simulatedLatency: TimeInterval = 0.01) {
        self.shouldSimulateFailure = shouldSimulateFailure
        self.simulatedLatency = simulatedLatency
    }

    // MARK: - Core Data Protocol Implementation

    public func save(context _: NSManagedObjectContext) async throws {
        if simulatedLatency > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        }

        if shouldSimulateFailure {
            throw MockCoreDataError.saveFailed
        }
    }

    public nonisolated func fetch<T: NSManagedObject>(
        request _: NSFetchRequest<T>,
        context _: NSManagedObjectContext
    ) async throws -> [T] {
        if simulatedLatency > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        }

        if shouldSimulateFailure {
            throw MockCoreDataError.fetchFailed
        }

        // Return mock data based on request type
        return []
    }

    public func count(
        for _: NSFetchRequest<some NSManagedObject>,
        context _: NSManagedObjectContext
    ) async throws -> Int {
        if shouldSimulateFailure {
            throw MockCoreDataError.countFailed
        }

        return storedData.count
    }

    public func delete(
        object _: NSManagedObject,
        context _: NSManagedObjectContext
    ) async throws {
        if shouldSimulateFailure {
            throw MockCoreDataError.deleteFailed
        }
    }

    // MARK: - Mock-Specific Methods

    public func storeData(_ data: Any, forKey key: String) {
        storedData[key] = data
    }

    public func getData(forKey key: String) -> Any? {
        storedData[key]
    }

    public func clearAllData() {
        storedData.removeAll()
        modificationData.removeAll()
    }

    public func getStoredDataCount() -> Int {
        storedData.count
    }

    // MARK: - Modification Tracking Mock Methods

    public func deleteAllModificationData() async throws {
        if simulatedLatency > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        }

        if shouldSimulateFailure {
            throw MockCoreDataError.deleteFailed
        }

        modificationData.removeAll()
    }

    public func storeModificationData(_ data: Any, forKey key: String) {
        modificationData[key] = data
    }

    public func getModificationData(forKey key: String) -> Any? {
        modificationData[key]
    }

    public func getModificationDataCount() -> Int {
        modificationData.count
    }
}

// MARK: - Mock Errors

public enum MockCoreDataError: Error {
    case saveFailed
    case fetchFailed
    case countFailed
    case deleteFailed
    case configurationError
}

// MARK: - Core Data Actor Protocol

/// Protocol that CoreDataActor should conform to
public protocol CoreDataActor: Actor {
    func save(context: NSManagedObjectContext) async throws
    nonisolated func fetch<T: NSManagedObject>(request: NSFetchRequest<T>, context: NSManagedObjectContext) async throws -> [T]
    func count(for request: NSFetchRequest<some NSManagedObject>, context: NSManagedObjectContext) async throws -> Int
    func delete(object: NSManagedObject, context: NSManagedObjectContext) async throws
    func deleteAllModificationData() async throws
}

// MARK: - Test Utilities

public extension MockCoreDataActor {
    /// Create mock actor with specific test configuration
    static func forTesting(
        withFailure: Bool = false,
        latency: TimeInterval = 0.0
    ) -> MockCoreDataActor {
        MockCoreDataActor(
            shouldSimulateFailure: withFailure,
            simulatedLatency: latency
        )
    }

    /// Reset mock to initial state
    func reset() {
        clearAllData()
    }
}
