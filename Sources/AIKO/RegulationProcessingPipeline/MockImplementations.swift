import Foundation
import os

// MARK: - Enhanced Mock Implementations with Realistic Async Behavior

/// Enhanced mock regulation service with comprehensive error simulation
public actor MockRegulationService {
    // MARK: - Configuration

    public struct Configuration: Sendable {
        public let enableRandomFailures: Bool
        public let failureRate: Double
        public let simulateNetworkLatency: Bool
        public let minLatencyMs: UInt64
        public let maxLatencyMs: UInt64
        public let simulateMemoryPressure: Bool
        public let simulateRateLimiting: Bool
        public let maxRequestsPerSecond: Int

        public init(
            enableRandomFailures: Bool = false,
            failureRate: Double = 0.1,
            simulateNetworkLatency: Bool = true,
            minLatencyMs: UInt64 = 10,
            maxLatencyMs: UInt64 = 500,
            simulateMemoryPressure: Bool = false,
            simulateRateLimiting: Bool = false,
            maxRequestsPerSecond: Int = 10
        ) {
            self.enableRandomFailures = enableRandomFailures
            self.failureRate = failureRate
            self.simulateNetworkLatency = simulateNetworkLatency
            self.minLatencyMs = minLatencyMs
            self.maxLatencyMs = maxLatencyMs
            self.simulateMemoryPressure = simulateMemoryPressure
            self.simulateRateLimiting = simulateRateLimiting
            self.maxRequestsPerSecond = maxRequestsPerSecond
        }

        public static let production = Configuration(
            enableRandomFailures: false,
            simulateNetworkLatency: true,
            minLatencyMs: 20,
            maxLatencyMs: 100
        )

        public static let testing = Configuration(
            enableRandomFailures: true,
            failureRate: 0.2,
            simulateNetworkLatency: true,
            minLatencyMs: 5,
            maxLatencyMs: 50,
            simulateMemoryPressure: true,
            simulateRateLimiting: true
        )

        public static let chaos = Configuration(
            enableRandomFailures: true,
            failureRate: 0.5,
            simulateNetworkLatency: true,
            minLatencyMs: 100,
            maxLatencyMs: 2000,
            simulateMemoryPressure: true,
            simulateRateLimiting: true,
            maxRequestsPerSecond: 2
        )
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let logger = Logger(subsystem: "com.aiko.mocks", category: "RegulationService")
    private var requestCount = 0
    private var lastRequestTime = Date()
    private var failureHistory: [FailureRecord] = []
    private let maxFailureHistory = 100

    // MARK: - Initialization

    public init(configuration: Configuration = .production) {
        self.configuration = configuration
    }

    // MARK: - Public API

    /// Fetch regulation with realistic async behavior and error simulation
    public func fetchRegulation(id: String) async throws -> MockRegulation {
        // Simulate rate limiting
        if configuration.simulateRateLimiting {
            try await enforceRateLimit()
        }

        // Simulate network latency
        if configuration.simulateNetworkLatency {
            try await simulateNetworkLatency()
        }

        // Simulate random failures
        if configuration.enableRandomFailures {
            try await simulateRandomFailure(operation: "fetchRegulation", id: id)
        }

        // Simulate memory pressure
        if configuration.simulateMemoryPressure {
            try await simulateMemoryPressure()
        }

        // Return mock regulation
        return createMockRegulation(id: id)
    }

    /// Batch fetch with realistic concurrency and partial failure handling
    public func fetchRegulationBatch(ids: [String]) async throws -> [Result<MockRegulation, Error>] {
        logger.info("📦 Fetching batch of \(ids.count) regulations")

        return await withTaskGroup(of: Result<MockRegulation, Error>.self) { group in
            for id in ids {
                group.addTask {
                    do {
                        let regulation = try await self.fetchRegulation(id: id)
                        return .success(regulation)
                    } catch {
                        self.logger.error("❌ Failed to fetch regulation \(id): \(error)")
                        return .failure(error)
                    }
                }
            }

            var results: [Result<MockRegulation, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    /// Search regulations with pagination and filtering
    public func searchRegulations(
        query: String,
        filters: SearchFilters = SearchFilters(),
        pagination: PaginationParams = PaginationParams()
    ) async throws -> SearchResults {
        // Simulate search latency
        if configuration.simulateNetworkLatency {
            try await simulateNetworkLatency()
        }

        // Generate mock results
        let totalCount = Int.random(in: 50 ... 200)
        let pageCount = min(pagination.limit, totalCount - pagination.offset)

        var regulations: [MockRegulation] = []
        for i in 0 ..< pageCount {
            let id = "search-result-\(pagination.offset + i)"
            regulations.append(createMockRegulation(id: id, matchesQuery: query))
        }

        return SearchResults(
            regulations: regulations,
            totalCount: totalCount,
            offset: pagination.offset,
            hasMore: pagination.offset + pageCount < totalCount,
            facets: generateFacets(for: query, filters: filters)
        )
    }

    // MARK: - Error Simulation

    private func simulateRandomFailure(operation: String, id: String) async throws {
        let shouldFail = Double.random(in: 0 ... 1) < configuration.failureRate

        if shouldFail {
            guard let errorType = MockServiceError.allCases.randomElement() else {
                throw MockNetworkError.invalidResponse(reason: "Failed to generate random error")
            }
            let error = createError(type: errorType, operation: operation, id: id)

            // Record failure
            let record = FailureRecord(
                timestamp: Date(),
                operation: operation,
                error: error,
                recovered: false
            )
            failureHistory.append(record)
            if failureHistory.count > maxFailureHistory {
                failureHistory.removeFirst()
            }

            logger.error("🔥 Simulated error for \(operation) with id: \(id)")
            throw error
        }
    }

    private func createError(type: MockServiceError, operation: String, id: String) -> Error {
        switch type {
        case .networkTimeout:
            return MockNetworkError.timeout(operation: operation, id: id)
        case .serverError:
            return MockNetworkError.serverError(statusCode: Int.random(in: 500 ... 503))
        case .invalidResponse:
            return MockNetworkError.invalidResponse(reason: "Malformed JSON in response")
        case .rateLimited:
            return MockNetworkError.rateLimited(retryAfter: TimeInterval.random(in: 1 ... 10))
        case .unauthorized:
            return MockNetworkError.unauthorized
        case .notFound:
            return MockNetworkError.notFound(id: id)
        case .memoryExhausted:
            return SystemError.memoryExhausted
        case .diskFull:
            return SystemError.diskFull
        }
    }

    // MARK: - Latency Simulation

    private func simulateNetworkLatency() async throws {
        let latencyMs = UInt64.random(in: configuration.minLatencyMs ... configuration.maxLatencyMs)
        try await Task.sleep(nanoseconds: latencyMs * 1_000_000)
    }

    // MARK: - Rate Limiting

    private func enforceRateLimit() async throws {
        requestCount += 1

        let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
        let minInterval = 1.0 / Double(configuration.maxRequestsPerSecond)

        if timeSinceLastRequest < minInterval {
            let waitTime = minInterval - timeSinceLastRequest
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }

        lastRequestTime = Date()
    }

    // MARK: - Memory Pressure Simulation

    private func simulateMemoryPressure() async throws {
        let memoryMonitor = UnifiedMemoryMonitor.shared
        let currentUsage = await memoryMonitor.currentMemoryUsage()
        let availableMemory = ProcessInfo.processInfo.physicalMemory - UInt64(currentUsage)

        // Simulate high memory usage scenario
        if availableMemory < 100_000_000 { // Less than 100MB available
            if Bool.random() { // 50% chance to fail under pressure
                throw SystemError.memoryExhausted
            }
        }
    }

    // MARK: - Mock Data Generation

    private func createMockRegulation(id: String, matchesQuery: String? = nil) -> MockRegulation {
        let sections = [
            "15.201", "15.202", "15.203", "15.204", "15.205",
            "15.301", "15.302", "15.303", "15.304", "15.305",
        ]

        let titles = [
            "Exchanges with industry before receipt of proposals",
            "Advisory Multi-Step Process",
            "Requests for information",
            "Presolicitation notices",
            "Special situations",
            "Policy",
            "Definitions",
            "Evaluation factors",
            "Procedures",
            "Responsibilities",
        ]

        let sectionIndex = abs(id.hashValue) % sections.count
        let section = sections[sectionIndex]
        let title = titles[sectionIndex]

        var content = """
        \(section) \(title)

        (a) General. Exchanges of information among all interested parties, from the
        earliest identification of a requirement through receipt of proposals, are
        encouraged. Any exchange of information must be consistent with procurement
        integrity requirements (see 3.104). Interested parties include potential
        offerors, end users, Government acquisition and supporting personnel, and
        others involved in the conduct or outcome of the acquisition.

        (b) The purpose of exchanging information is to improve the understanding of
        Government requirements and industry capabilities, thereby allowing potential
        offerors to judge whether or how they can satisfy the Government's requirements,
        and enhancing the Government's ability to obtain quality supplies and services.
        """

        if let query = matchesQuery {
            content += "\n\n(c) Search match: This regulation contains information about '\(query)'."
        }

        return MockRegulation(
            id: UUID(),
            content: content,
            hierarchy: RegulationHierarchy(
                part: "PART 15",
                subpart: "Subpart 15.2",
                section: section,
                subsection: "(a)",
                paragraph: nil,
                subparagraph: nil
            ),
            metadata: [
                "source": "Federal Acquisition Regulation",
                "effectiveDate": "2024-01-01",
                "lastModified": ISO8601DateFormatter().string(from: Date()),
                "version": "1.0.0",
            ]
        )
    }

    private func generateFacets(for _: String, filters _: SearchFilters) -> [SearchFacet] {
        var facets: [SearchFacet] = []

        // Generate category facets
        facets.append(SearchFacet(
            name: "category",
            values: [
                FacetValue(value: "Contracting", count: Int.random(in: 10 ... 50)),
                FacetValue(value: "Acquisition", count: Int.random(in: 5 ... 30)),
                FacetValue(value: "Procurement", count: Int.random(in: 8 ... 25)),
            ]
        ))

        // Generate date range facets
        facets.append(SearchFacet(
            name: "dateRange",
            values: [
                FacetValue(value: "Last 30 days", count: Int.random(in: 5 ... 15)),
                FacetValue(value: "Last 90 days", count: Int.random(in: 10 ... 30)),
                FacetValue(value: "Last year", count: Int.random(in: 20 ... 60)),
            ]
        ))

        return facets
    }

    // MARK: - Monitoring

    public func getFailureHistory() async -> [FailureRecord] {
        failureHistory
    }

    public func getRequestMetrics() async -> RequestMetrics {
        RequestMetrics(
            totalRequests: requestCount,
            failureRate: Double(failureHistory.count) / Double(max(1, requestCount)),
            averageLatency: configuration.simulateNetworkLatency
                ? Double(configuration.minLatencyMs + configuration.maxLatencyMs) / 2.0
                : 0
        )
    }
}

// MARK: - Supporting Types

public struct SearchFilters: Sendable {
    public let categories: [String]
    public let dateRange: MockDateRange?
    public let includeArchived: Bool

    public init(
        categories: [String] = [],
        dateRange: MockDateRange? = nil,
        includeArchived: Bool = false
    ) {
        self.categories = categories
        self.dateRange = dateRange
        self.includeArchived = includeArchived
    }
}

public struct MockDateRange: Sendable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

public struct PaginationParams: Sendable {
    public let offset: Int
    public let limit: Int

    public init(offset: Int = 0, limit: Int = 20) {
        self.offset = offset
        self.limit = min(100, limit) // Cap at 100 for safety
    }
}

public struct SearchResults: Sendable {
    public let regulations: [MockRegulation]
    public let totalCount: Int
    public let offset: Int
    public let hasMore: Bool
    public let facets: [SearchFacet]
}

public struct SearchFacet: Sendable {
    public let name: String
    public let values: [FacetValue]
}

public struct FacetValue: Sendable {
    public let value: String
    public let count: Int
}

public struct FailureRecord: Sendable {
    public let timestamp: Date
    public let operation: String
    public let error: Error
    public let recovered: Bool
}

public struct RequestMetrics: Sendable {
    public let totalRequests: Int
    public let failureRate: Double
    public let averageLatency: Double
}

// MARK: - Error Types

public enum MockServiceError: CaseIterable {
    case networkTimeout
    case serverError
    case invalidResponse
    case rateLimited
    case unauthorized
    case notFound
    case memoryExhausted
    case diskFull
}

public enum MockNetworkError: LocalizedError {
    case timeout(operation: String, id: String)
    case serverError(statusCode: Int)
    case invalidResponse(reason: String)
    case rateLimited(retryAfter: TimeInterval)
    case unauthorized
    case notFound(id: String)

    public var errorDescription: String? {
        switch self {
        case let .timeout(operation, id):
            "Network timeout during \(operation) for id: \(id)"
        case let .serverError(statusCode):
            "Server error with status code: \(statusCode)"
        case let .invalidResponse(reason):
            "Invalid response: \(reason)"
        case let .rateLimited(retryAfter):
            "Rate limited. Retry after \(Int(retryAfter)) seconds"
        case .unauthorized:
            "Unauthorized access"
        case let .notFound(id):
            "Resource not found: \(id)"
        }
    }
}

public enum SystemError: LocalizedError {
    case memoryExhausted
    case diskFull

    public var errorDescription: String? {
        switch self {
        case .memoryExhausted:
            "System memory exhausted"
        case .diskFull:
            "Disk space full"
        }
    }
}

// MARK: - Enhanced Mock Pipeline Components

/// Mock async channel with back-pressure simulation
public actor MockAsyncChannel<T: Sendable> {
    private var buffer: [T] = []
    private let capacity: Int
    private var isClosed = false
    private var backPressureSimulation = false
    private var dropRate: Double = 0.0

    public init(capacity: Int = 100) {
        self.capacity = capacity
    }

    public func send(_ value: T) async throws {
        guard !isClosed else {
            throw ChannelError.closed
        }

        // Simulate back-pressure
        if buffer.count >= capacity {
            if backPressureSimulation {
                // Simulate waiting for space
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            throw ChannelError.backPressure
        }

        // Simulate random drops
        if dropRate > 0, Double.random(in: 0 ... 1) < dropRate {
            throw ChannelError.dropped
        }

        buffer.append(value)
    }

    public func receive() async throws -> T? {
        guard !isClosed || !buffer.isEmpty else {
            return nil
        }

        // Simulate processing delay
        if !buffer.isEmpty {
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
            return buffer.removeFirst()
        }

        // Wait for data
        while buffer.isEmpty, !isClosed {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        return buffer.isEmpty ? nil : buffer.removeFirst()
    }

    public func close() {
        isClosed = true
    }

    public func enableBackPressureSimulation(_ enabled: Bool) {
        backPressureSimulation = enabled
    }

    public func setDropRate(_ rate: Double) {
        dropRate = min(1.0, max(0.0, rate))
    }

    public func getBufferStatus() -> (count: Int, capacity: Int, isFull: Bool) {
        (buffer.count, capacity, buffer.count >= capacity)
    }
}

public enum ChannelError: LocalizedError {
    case closed
    case backPressure
    case dropped

    public var errorDescription: String? {
        switch self {
        case .closed:
            "Channel is closed"
        case .backPressure:
            "Channel experiencing back-pressure"
        case .dropped:
            "Message dropped due to congestion"
        }
    }
}

// MARK: - Mock Processing Components

/// Mock processor with configurable behavior
public actor MockProcessor {
    public struct ProcessingConfig: Sendable {
        public let processingTimeMs: UInt64
        public let failureRate: Double
        public let memoryUsagePerItem: Int64
        public let enableConcurrency: Bool
        public let maxConcurrent: Int

        public init(
            processingTimeMs: UInt64 = 10,
            failureRate: Double = 0.0,
            memoryUsagePerItem: Int64 = 1024,
            enableConcurrency: Bool = true,
            maxConcurrent: Int = 10
        ) {
            self.processingTimeMs = processingTimeMs
            self.failureRate = failureRate
            self.memoryUsagePerItem = memoryUsagePerItem
            self.enableConcurrency = enableConcurrency
            self.maxConcurrent = maxConcurrent
        }
    }

    private let config: ProcessingConfig
    private var processedCount = 0
    private var failedCount = 0

    public init(config: ProcessingConfig = ProcessingConfig()) {
        self.config = config
    }

    public func process<T: Sendable>(_ items: [T]) async throws -> ProcessingResult<T> {
        let startTime = Date()
        var successful: [T] = []
        var failed: [(T, Error)] = []

        if config.enableConcurrency {
            // Process concurrently with limited parallelism
            await withTaskGroup(of: Result<T, Error>.self) { group in
                for item in items.prefix(config.maxConcurrent) {
                    group.addTask {
                        await self.processSingleItem(item)
                    }
                }

                for await result in group {
                    switch result {
                    case let .success(item):
                        successful.append(item)
                        processedCount += 1
                    case .failure(_):
                        if case let .failure(error) = result,
                           let item = items.first {
                            failed.append((item, error))
                            failedCount += 1
                        }
                    }
                }
            }
        } else {
            // Process sequentially
            for item in items {
                let result = await processSingleItem(item)
                switch result {
                case let .success(processedItem):
                    successful.append(processedItem)
                    processedCount += 1
                case let .failure(error):
                    failed.append((item, error))
                    failedCount += 1
                }
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return ProcessingResult(
            successful: successful,
            failed: failed,
            processingTime: processingTime,
            memoryUsed: Int64(items.count) * config.memoryUsagePerItem
        )
    }

    private func processSingleItem<T: Sendable>(_ item: T) async -> Result<T, Error> {
        // Simulate processing time
        do {
            try await Task.sleep(nanoseconds: config.processingTimeMs * 1_000_000)
        } catch {
            return .failure(error)
        }

        // Simulate random failures
        if Double.random(in: 0 ... 1) < config.failureRate {
            return .failure(MockProcessingError.randomFailure)
        }

        return .success(item)
    }

    public func getMetrics() -> ProcessorMetrics {
        ProcessorMetrics(
            totalProcessed: processedCount,
            totalFailed: failedCount,
            successRate: Double(processedCount) / Double(max(1, processedCount + failedCount))
        )
    }
}

public struct ProcessingResult<T> {
    public let successful: [T]
    public let failed: [(T, Error)]
    public let processingTime: TimeInterval
    public let memoryUsed: Int64
}

public struct ProcessorMetrics: Sendable {
    public let totalProcessed: Int
    public let totalFailed: Int
    public let successRate: Double
}

public enum MockProcessingError: LocalizedError {
    case randomFailure

    public var errorDescription: String? {
        "Random processing failure for testing"
    }
}
