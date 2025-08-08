import Foundation
import os.log

// MARK: - MemoryPermitSystem

/// Global memory permit system enforcing strict 50MB limit
/// Uses FIFO queue for permit requests with timeout support
actor MemoryPermitSystem: MemoryPermitSystemProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(limitBytes: Int64) {
        self.limitBytes = limitBytes
        logger.info("MemoryPermitSystem initialized with limit: \(limitBytes / 1024 / 1024)MB")
    }

    // MARK: Internal

    let limitBytes: Int64

    var usedBytes: Int64 {
        get async { _usedBytes }
    }

    // MARK: - Permit Management

    func acquire(bytes: Int64, timeout: TimeInterval? = nil) async throws -> MemoryPermit {
        logger.debug("Requesting permit for \(bytes) bytes")

        // Check if request can be satisfied immediately
        if canGrantImmediately(bytes: bytes) {
            return grantPermit(bytes: bytes)
        }

        // Queue the request
        return try await withCheckedThrowingContinuation { continuation in
            let requestID = UUID()
            let request = MemoryRequest(
                id: requestID,
                bytes: bytes,
                timestamp: Date(),
                continuation: continuation
            )

            pendingRequests.append(request)

            // Set up timeout if specified
            if let timeout {
                Task {
                    try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    await handleTimeout(requestID: requestID)
                }
            }

            // Process pending requests in case some memory was freed
            Task { await processPendingRequests() }
        }
    }

    func release(_ permit: MemoryPermit) async {
        logger.debug("Releasing permit: \(permit.id), bytes: \(permit.bytes)")

        guard activePermits.removeValue(forKey: permit.id) != nil else {
            logger.warning("Attempted to release unknown permit: \(permit.id)")
            return
        }

        _usedBytes -= permit.bytes
        logger.debug("Memory usage after release: \(self._usedBytes) / \(self.limitBytes) bytes")

        // Process any pending requests that can now be fulfilled
        await processPendingRequests()
    }

    func emergencyMemoryRelease() async {
        logger.warning("Emergency memory release triggered - releasing all permits")

        let releasedCount = activePermits.count
        let releasedBytes = _usedBytes

        activePermits.removeAll()
        _usedBytes = 0

        // Cancel all pending requests
        for request in pendingRequests {
            request.continuation.resume(throwing: MemoryPermitError.systemOverloaded)
        }
        pendingRequests.removeAll()

        logger.warning("Emergency release complete: \(releasedCount) permits, \(releasedBytes) bytes released")
    }

    // MARK: Private

    /// Request tracking
    private struct MemoryRequest {
        let id: UUID
        let bytes: Int64
        let timestamp: Date
        let continuation: CheckedContinuation<MemoryPermit, Error>
    }

    private let logger: Logger = .init(subsystem: "com.aiko.graphrag", category: "MemoryPermitSystem")

    private var _usedBytes: Int64 = 0
    private var activePermits: [UUID: MemoryPermit] = [:]

    /// FIFO queue for pending requests
    private var pendingRequests: [MemoryRequest] = []

    // MARK: - Private Methods

    private func canGrantImmediately(bytes: Int64) -> Bool {
        (_usedBytes + bytes) <= limitBytes
    }

    private func grantPermit(bytes: Int64) -> MemoryPermit {
        let permit = MemoryPermit(bytes: bytes)
        activePermits[permit.id] = permit
        _usedBytes += bytes

        logger.debug("Granted permit: \(permit.id), bytes: \(bytes), total used: \(self._usedBytes) / \(self.limitBytes)")

        return permit
    }

    private func processPendingRequests() async {
        guard !pendingRequests.isEmpty else {
            return
        }

        logger.debug("Processing \(self.pendingRequests.count) pending requests")

        var requestsToProcess: [MemoryRequest] = []
        var remainingRequests: [MemoryRequest] = []

        // Process FIFO - check requests in order
        for request in pendingRequests {
            if canGrantImmediately(bytes: request.bytes) {
                requestsToProcess.append(request)
            } else {
                remainingRequests.append(request)
            }
        }

        pendingRequests = remainingRequests

        // Grant permits for processable requests
        for request in requestsToProcess {
            let permit = grantPermit(bytes: request.bytes)
            request.continuation.resume(returning: permit)
        }

        logger.debug("Processed \(requestsToProcess.count) requests, \(remainingRequests.count) remaining")
    }

    private func handleTimeout(requestID: UUID) async {
        logger.debug("Handling timeout for request: \(requestID)")

        // Find and remove the timed-out request
        if let index = pendingRequests.firstIndex(where: { $0.id == requestID }) {
            let request = pendingRequests.remove(at: index)
            request.continuation.resume(throwing: MemoryPermitError.timeout)
            logger.warning("Request timed out: \(requestID)")
        }
    }
}

// MARK: - MemoryPermit

/// Memory permit representing allocated memory
public struct MemoryPermit: Sendable {
    // MARK: Lifecycle

    public init(bytes: Int64) {
        self.bytes = bytes
        timestamp = Date()
        id = UUID()
        self.releaseHandler = nil
    }

    public init(bytes: Int64, releaseHandler: (@Sendable () -> Void)? = nil) {
        self.bytes = bytes
        timestamp = Date()
        id = UUID()
        self.releaseHandler = releaseHandler
    }

    // MARK: Internal

    public let bytes: Int64
    public let timestamp: Date
    public let id: UUID
    private let releaseHandler: (@Sendable () -> Void)?

    /// Release the memory permit
    public func release() {
        releaseHandler?()
    }
}

// MARK: - MemoryPermitError

/// Memory permit system errors
enum MemoryPermitError: Error {
    case timeout
    case systemOverloaded
    case invalidRequest
}
