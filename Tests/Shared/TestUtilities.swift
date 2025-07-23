import AikoCompat
import AppCore
import ComposableArchitecture
import Foundation

// MARK: - Mock AI Provider Factory

public enum MockAIProviderFactory {
    public static var mockProvider: MockAIProvider?

    public static func setMockProvider(_ provider: MockAIProvider) {
        mockProvider = provider
    }

    public static func reset() {
        mockProvider = nil
    }
}

// MARK: - Mock AI Provider

public final class MockAIProvider: AIProvider, @unchecked Sendable {
    public var responses: [String] = []
    public var callCount = 0
    public var lastRequest: AICompletionRequest?

    public init(responses: [String] = []) {
        self.responses = responses
    }

    public func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse {
        callCount += 1
        lastRequest = request

        let response = responses.isEmpty ? "Mock response" : responses[min(callCount - 1, responses.count - 1)]

        return AICompletionResponse(
            content: response,
            model: request.model,
            tokenUsage: AITokenUsage(promptTokens: 100, completionTokens: 50, totalTokens: 150)
        )
    }
}

// MARK: - Test Dependencies

public extension DependencyValues {
    var testAIProvider: MockAIProvider {
        get { self[TestAIProviderKey.self] }
        set { self[TestAIProviderKey.self] = newValue }
    }
}

private enum TestAIProviderKey: DependencyKey {
    static let liveValue = MockAIProvider()
    static let testValue = MockAIProvider()
}

// MARK: - Test Data Generators

public enum TestDataGenerator {
    public static func sampleRequirementsData() -> RequirementsData {
        var data = RequirementsData()
        data.projectTitle = "Test Project"
        data.description = "Test description"
        data.estimatedValue = 50000.0
        data.businessNeed = "Test business need"
        data.performancePeriod = "12 months"
        data.technicalRequirements = ["Requirement 1", "Requirement 2"]
        return data
    }

    public static func sampleGeneratedDocument() -> GeneratedDocument {
        GeneratedDocument(
            id: UUID(),
            documentCategory: .contractingOfficerOrder,
            title: "Test Document",
            content: "Test content",
            dateGenerated: Date(),
            requirements: "Test requirements"
        )
    }

    public static func sampleAcquisition() -> Acquisition {
        Acquisition(
            id: UUID(),
            title: "Test Acquisition",
            description: "Test description",
            estimatedValue: 50000.0,
            vendor: "Test Vendor",
            status: .planning,
            createdDate: Date(),
            lastModified: Date(),
            requirements: sampleRequirementsData()
        )
    }
}

// MARK: - Test Utilities

public enum TestUtilities {
    /// Waits for an async operation to complete with a timeout
    public static func waitFor<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError()
            }

            for try await result in group {
                group.cancelAll()
                return result
            }

            throw TimeoutError()
        }
    }

    /// Creates a test store with mock dependencies
    public static func createTestStore<State, Action>(
        initialState: State,
        reducer: some Reducer<State, Action>
    ) -> TestStore<State, Action> {
        TestStore(initialState: initialState, reducer: { reducer }) {
            $0.testAIProvider = MockAIProvider()
        }
    }
}

// MARK: - Test Errors

public struct TimeoutError: Error, LocalizedError {
    public var errorDescription: String? {
        "Operation timed out"
    }
}

// MARK: - Mock Services

public final class MockDocumentCacheService: DocumentCacheServiceProtocol, @unchecked Sendable {
    public var cachedDocuments: [String: GeneratedDocument] = [:]
    public var statistics = CacheStatistics(
        totalCachedDocuments: 0,
        totalCachedAnalyses: 0,
        cacheSize: 0,
        hitRate: 0,
        averageRetrievalTime: 0,
        lastCleanup: nil,
        mostAccessedDocumentTypes: []
    )

    public init() {}

    public func cacheDocument(_ document: GeneratedDocument) async throws {
        let key = "\(document.documentCategory.rawValue)-\(document.title)"
        cachedDocuments[key] = document
        statistics.totalCachedDocuments = cachedDocuments.count
    }

    public func getCachedDocument(type: DocumentType, requirements: String) async -> GeneratedDocument? {
        let key = "\(type.rawValue)-\(requirements)"
        return cachedDocuments[key]
    }

    public func clearCache() async throws {
        cachedDocuments.removeAll()
        statistics.totalCachedDocuments = 0
    }

    public func getCacheStatistics() async -> CacheStatistics {
        statistics
    }

    public func preloadFrequentDocuments() async throws {
        // Mock implementation
    }

    public func optimizeCacheForMemory() async throws {
        // Mock implementation
    }
}

// MARK: - Mock Acquisition Service

public final class MockAcquisitionService: AcquisitionServiceProtocol, @unchecked Sendable {
    public var acquisitions: [Acquisition] = []

    public init() {}

    public func createAcquisition(
        _ title: String,
        _ description: String,
        _: [UploadedDocument]
    ) async throws -> Acquisition {
        let acquisition = Acquisition(
            id: UUID(),
            title: title,
            description: description,
            estimatedValue: 0,
            vendor: "",
            status: .planning,
            createdDate: Date(),
            lastModified: Date(),
            requirements: RequirementsData()
        )
        acquisitions.append(acquisition)
        return acquisition
    }

    public func updateAcquisition(_ acquisition: Acquisition) async throws {
        if let index = acquisitions.firstIndex(where: { $0.id == acquisition.id }) {
            acquisitions[index] = acquisition
        }
    }

    public func getAcquisition(id: UUID) async throws -> Acquisition? {
        acquisitions.first { $0.id == id }
    }

    public func getAllAcquisitions() async throws -> [Acquisition] {
        acquisitions
    }

    public func deleteAcquisition(id: UUID) async throws {
        acquisitions.removeAll { $0.id == id }
    }
}
