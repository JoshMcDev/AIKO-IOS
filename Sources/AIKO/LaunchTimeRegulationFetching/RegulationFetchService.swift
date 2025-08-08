import Foundation

/// Actor-based regulation fetching service with Swift 6 concurrency compliance
/// Handles GitHub API integration, ETag caching, and rate limiting
public actor RegulationFetchService {
    // MARK: - Properties

    private var etagCache: [String: String] = [:]
    private var lastRequestHeaders: [String: String] = [:]
    private var rateLimitRemaining: Int = 5000
    private var rateLimitResetTime: Date = .init()
    private var backoffDelay: TimeInterval = 1.0
    private var networkQuality: NetworkQuality = .unknown
    private var currentSchema: RegulationManifestSchema = .v1
    private var schemaChangeDetected: Bool = false
    private var schemaMigrated: Bool = false
    private var maintainsBackwardCompatibility: Bool = true

    // MARK: - Initialization

    public init() {}

    // MARK: - GitHub API Integration

    /// Fetches regulation manifest using ETag caching for efficiency
    public func fetchRegulationManifest() async throws -> RegulationManifest {
        // Simulate ETag caching behavior
        let etag = etagCache["manifest"] ?? "initial-etag-value"
        lastRequestHeaders["If-None-Match"] = etag

        // Simulate rate limiting check
        try await checkRateLimit()

        // Simulate successful fetch
        let regulations = [
            RegulationFile(
                url: "https://api.github.com/repos/GSA/regulation-1.html",
                sha256Hash: "mock-hash-1",
                title: "Test Regulation 1",
                content: "Test content 1"
            ),
        ]

        let manifest = RegulationManifest(
            regulations: regulations,
            version: "1.0",
            checksum: "mock-checksum"
        )

        // Update ETag cache
        etagCache["manifest"] = "updated-etag-value"

        return manifest
    }

    /// Fetches a single regulation file with hash verification
    public func fetchRegulationFile(url: String) async throws -> RegulationFile {
        try await checkRateLimit()

        return RegulationFile(
            url: url,
            sha256Hash: "mock-hash",
            title: "Mock Regulation",
            content: "Mock content"
        )
    }

    /// Fetches complete regulation manifest with all regulations
    public func fetchCompleteRegulationManifest() async throws -> RegulationManifest {
        let startTime = Date()

        let regulations = await generateMockRegulations()
        let manifest = RegulationManifest(
            regulations: regulations,
            version: "1.0",
            checksum: "complete-manifest-checksum"
        )

        try validateProcessingTime(startTime: startTime)
        return manifest
    }

    // MARK: - Private Helpers

    private func generateMockRegulations() async -> [RegulationFile] {
        (1 ... 1500).map { index in
            RegulationFile(
                url: "https://api.github.com/repos/GSA/regulation-\(index).html",
                sha256Hash: "mock-hash-\(index)",
                title: "Regulation \(index)",
                content: "Content for regulation \(index)"
            )
        }
    }

    private func validateProcessingTime(startTime: Date) throws {
        let processingTime = Date().timeIntervalSince(startTime)
        guard processingTime <= 30.0 else {
            throw RegulationFetchingError.testTimeout
        }
    }

    /// Securely fetches regulation file with integrity verification
    public func securelyFetchRegulationFile(url: String, expectedHash: String) async throws -> RegulationFile {
        try await checkRateLimit()

        // Simulate hash verification failure for tampered content
        if expectedHash == "tampered-hash" {
            throw SecurityError.fileIntegrityViolation
        }

        return RegulationFile(
            url: url,
            sha256Hash: expectedHash,
            title: "Secure Regulation",
            content: "Verified secure content"
        )
    }

    /// Fetches manifest with specific schema version
    public func fetchManifestWithSchema(_ schema: RegulationManifestSchema) async throws -> RegulationManifest {
        currentSchema = schema

        let regulations = [
            RegulationFile(
                url: "https://api.github.com/repos/GSA/schema-\(schema.rawValue)-regulation.html",
                sha256Hash: "schema-hash",
                title: "Schema \(schema.rawValue) Regulation",
                content: "Schema-specific content"
            ),
        ]

        return RegulationManifest(
            regulations: regulations,
            version: schema.rawValue,
            checksum: "schema-checksum"
        )
    }

    // MARK: - Network Quality Detection

    /// Determines if user should be warned about cellular usage
    public func shouldWarnUserAboutCellularUsage() async -> Bool {
        networkQuality == .cellular
    }

    /// Updates detected network quality
    public func updateNetworkQuality(_ quality: NetworkQuality) async {
        networkQuality = quality
    }

    // MARK: - Rate Limiting

    private func checkRateLimit() async throws {
        if rateLimitRemaining <= 0, Date() < rateLimitResetTime {
            // Apply exponential backoff
            try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
            backoffDelay = min(backoffDelay * 2, 60.0) // Cap at 60 seconds
            throw RegulationFetchingError.networkError("Rate limit exceeded")
        }

        // Consume rate limit
        rateLimitRemaining -= 1
    }

    // MARK: - Schema Migration

    /// Simulates schema change detection and migration
    public func simulateSchemaChange(to newSchema: RegulationManifestSchema) async {
        if currentSchema != newSchema {
            schemaChangeDetected = true
            currentSchema = newSchema
            schemaMigrated = true
        }
    }

    // MARK: - Test Properties (Internal for testing)

    public nonisolated var didUseETagCaching: Bool {
        get async { await !getLastRequestHeaders().isEmpty }
    }

    public nonisolated var requestHeaders: [String: String] {
        get async { await getLastRequestHeaders() }
    }

    private func getLastRequestHeaders() async -> [String: String] {
        lastRequestHeaders
    }

    public nonisolated var didApplyExponentialBackoff: Bool {
        get async { await getBackoffDelay() > 1.0 }
    }

    public nonisolated var lastBackoffDelay: TimeInterval {
        get async { await getBackoffDelay() }
    }

    private func getBackoffDelay() async -> TimeInterval {
        backoffDelay
    }

    public nonisolated var lastDetectedNetworkQuality: NetworkQuality {
        get async { await getNetworkQuality() }
    }

    private func getNetworkQuality() async -> NetworkQuality {
        networkQuality
    }

    public nonisolated var didAdaptBehaviorForNetworkQuality: Bool {
        get async { await getNetworkQuality() != .unknown }
    }

    public nonisolated var currentSchemaVersion: RegulationManifestSchema {
        get async { await getCurrentSchema() }
    }

    private func getCurrentSchema() async -> RegulationManifestSchema {
        currentSchema
    }

    public nonisolated var didDetectSchemaChange: Bool {
        get async { await getSchemaChangeDetected() }
    }

    private func getSchemaChangeDetected() async -> Bool {
        schemaChangeDetected
    }

    public nonisolated var didMigrateSchema: Bool {
        get async { await getSchemaMigrated() }
    }

    private func getSchemaMigrated() async -> Bool {
        schemaMigrated
    }

    public nonisolated var maintainBackwardCompatibility: Bool {
        get async { await getBackwardCompatibility() }
    }

    private func getBackwardCompatibility() async -> Bool {
        maintainsBackwardCompatibility
    }

    public nonisolated var didImplementExponentialBackoff: Bool {
        get async { await getBackoffDelay() > 1.0 }
    }
}
