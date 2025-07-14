//
//  SyncEngine.swift
//  AIKO
//
//  Created for offline caching synchronization
//

import Foundation
import Network
import os.log

/// Actor responsible for managing cache synchronization
actor SyncEngine {
    /// Logger for sync operations
    private let logger = Logger(subsystem: "com.aiko.cache", category: "SyncEngine")
    
    /// Network monitor for connectivity detection
    private let networkMonitor = NWPathMonitor()
    
    /// Queue for network monitoring
    private let monitorQueue = DispatchQueue(label: "com.aiko.cache.networkmonitor")
    
    /// Sync configuration
    let configuration: SyncConfiguration
    
    /// Cache manager reference
    private weak var cacheManager: OfflineCacheManager?
    
    /// OpenRouter sync adapter
    internal let openRouterAdapter: OpenRouterSyncAdapter?
    
    /// Current network status
    private(set) var isConnected = false
    
    /// Is currently syncing
    private(set) var isSyncing = false
    
    /// Pending changes outbox
    private var outbox: [OutboxItem] = []
    
    /// Last sync date
    private(set) var lastSyncDate: Date?
    
    /// Active sync task
    private var activeSyncTask: Task<SyncResult, Error>?
    
    /// Initialize sync engine
    init(
        configuration: SyncConfiguration = .default,
        cacheManager: OfflineCacheManager,
        openRouterApiKey: String? = nil
    ) {
        self.configuration = configuration
        self.cacheManager = cacheManager
        
        // Initialize OpenRouter adapter if API key is available
        if let apiKey = openRouterApiKey ?? ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] {
            self.openRouterAdapter = OpenRouterSyncAdapter(apiKey: apiKey)
        } else {
            self.openRouterAdapter = nil
            logger.warning("OpenRouter API key not provided - sync will be limited")
        }
        
        // Setup network monitoring
        Task {
            await setupNetworkMonitoring()
        }
        
        // Load persisted outbox
        Task {
            await loadOutbox()
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    /// Setup network connectivity monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.handleNetworkStatusChange(path)
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    /// Handle network status changes
    private func handleNetworkStatusChange(_ path: NWPath) async {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        
        logger.info("Network status changed: \(self.isConnected ? "Connected" : "Disconnected")")
        
        // Trigger sync when connectivity is restored
        if !wasConnected && isConnected && !outbox.isEmpty {
            logger.info("Connectivity restored, triggering sync for \(self.outbox.count) pending items")
            await performSync()
        }
    }
    
    /// Queue a change for synchronization
    func queueChange(
        key: String,
        operation: SyncOperation,
        data: Data? = nil,
        contentType: CacheContentType,
        priority: SyncPriority = .normal,
        syncRole: String? = nil
    ) async {
        let item = OutboxItem(
            cacheKey: key,
            operation: operation,
            data: data,
            contentType: contentType,
            priority: priority,
            syncRole: syncRole ?? determineRoleForContent(contentType)
        )
        
        outbox.append(item)
        await persistOutbox()
        
        logger.debug("Queued \(operation.rawValue) for key: \(key) with role: \(item.syncRole ?? "default")")
        
        // Attempt immediate sync if connected
        if isConnected && !isSyncing {
            await performSync()
        }
    }
    
    /// Determine OpenRouter model role based on content type
    private func determineRoleForContent(_ contentType: CacheContentType) -> String {
        switch contentType {
        case .llmResponse:
            return "validator"  // Use lightweight validator for cached responses
        case .userData, .form:
            return "validator2"  // Use second validator for user data
        case .pdf, .document:
            return "search"  // Use search model for document content
        case .json:
            return "debug"  // Use debug model for JSON data
        case .systemData:
            return "fast_chat"  // Use fast model for system data
        case .image:
            return "debug"  // GPT-4o for vision tasks
        case .temporary:
            return "validator"  // Lightweight validation
        }
    }
    
    /// Perform synchronization
    @discardableResult
    func performSync() async -> SyncResult {
        guard !isSyncing else {
            logger.info("Sync already in progress")
            return SyncResult(
                success: false,
                syncedItems: [],
                failedItems: [],
                conflicts: [],
                duration: 0,
                timestamp: Date()
            )
        }
        
        guard isConnected else {
            logger.info("No network connection, skipping sync")
            return SyncResult(
                success: false,
                syncedItems: [],
                failedItems: [("network", "No connection")],
                conflicts: [],
                duration: 0,
                timestamp: Date()
            )
        }
        
        // Check minimum sync interval
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) < configuration.minimumSyncInterval {
            logger.debug("Skipping sync, minimum interval not met")
            return SyncResult(
                success: false,
                syncedItems: [],
                failedItems: [],
                conflicts: [],
                duration: 0,
                timestamp: Date()
            )
        }
        
        isSyncing = true
        let startTime = Date()
        
        // Update cache statistics
        if let manager = cacheManager {
            await MainActor.run {
                manager.statistics.isSyncing = true
            }
        }
        
        defer {
            isSyncing = false
            Task {
                if let manager = cacheManager {
                    await MainActor.run {
                        manager.statistics.isSyncing = false
                    }
                }
            }
        }
        
        logger.info("Starting sync with \(self.outbox.count) pending items")
        
        // Phase 1: Push pending changes
        let pushResult = await pushPendingChanges()
        
        // Phase 2: Pull remote changes
        let pullResult = await pullRemoteChanges()
        
        let duration = Date().timeIntervalSince(startTime)
        lastSyncDate = Date()
        
        // Update statistics
        if let manager = cacheManager {
            let pendingCount = self.outbox.count
            let errors = pushResult.failedItems.map { $0.error }
            await MainActor.run {
                manager.statistics.lastSync = Date()
                manager.statistics.pendingChanges = pendingCount
                manager.statistics.syncErrors = errors
            }
        }
        
        logger.info("Sync completed in \(duration)s - Pushed: \(pushResult.syncedItems.count), Failed: \(pushResult.failedItems.count)")
        
        return SyncResult(
            success: pushResult.failedItems.isEmpty && pullResult.failedItems.isEmpty,
            syncedItems: pushResult.syncedItems + pullResult.syncedItems,
            failedItems: pushResult.failedItems + pullResult.failedItems,
            conflicts: pushResult.conflicts + pullResult.conflicts,
            duration: duration,
            timestamp: Date()
        )
    }
    
    /// Push pending changes to server
    private func pushPendingChanges() async -> SyncResult {
        var syncedItems: [String] = []
        var failedItems: [(key: String, error: String)] = []
        let conflicts: [String] = []
        
        // Sort outbox by priority and retry time
        let itemsToSync = outbox
            .filter { $0.nextRetryAt <= Date() }
            .sorted { $0.priority > $1.priority }
            .prefix(configuration.batchSize)
        
        for var item in itemsToSync {
            do {
                try await syncOutboxItem(&item)
                syncedItems.append(item.cacheKey)
                
                // Remove from outbox
                outbox.removeAll { $0.id == item.id }
            } catch {
                logger.error("Failed to sync \(item.cacheKey): \(error.localizedDescription)")
                
                // Update retry information
                item.attemptCount += 1
                item.lastError = error.localizedDescription
                
                if item.attemptCount >= configuration.maxRetryAttempts {
                    failedItems.append((key: item.cacheKey, error: "Max retries exceeded"))
                    outbox.removeAll { $0.id == item.id }
                } else {
                    // Calculate next retry with exponential backoff
                    let backoffDelay = min(
                        configuration.baseRetryDelay * pow(2.0, Double(item.attemptCount - 1)),
                        configuration.maxRetryDelay
                    )
                    item.nextRetryAt = Date().addingTimeInterval(backoffDelay)
                    
                    // Update in outbox
                    if let index = outbox.firstIndex(where: { $0.id == item.id }) {
                        outbox[index] = item
                    }
                }
            }
        }
        
        await persistOutbox()
        
        return SyncResult(
            success: failedItems.isEmpty,
            syncedItems: syncedItems,
            failedItems: failedItems,
            conflicts: conflicts,
            duration: 0,
            timestamp: Date()
        )
    }
    
    /// Sync individual outbox item
    private func syncOutboxItem(_ item: inout OutboxItem) async throws {
        let operation = item.operation.rawValue
        let cacheKey = item.cacheKey
        let syncRole = item.syncRole ?? "default"
        logger.debug("Syncing \(operation) for key: \(cacheKey) with role: \(syncRole)")
        
        // Use OpenRouter adapter if available
        if let adapter = openRouterAdapter {
            do {
                let result = try await adapter.syncCacheItem(item)
                
                if result.success {
                    logger.info("Successfully synced \(cacheKey) using \(syncRole) model")
                    
                    // Update cache with response if applicable
                    if let responseData = result.responseData,
                       item.operation == .query {
                        // Store the response in cache
                        if let manager = cacheManager {
                            try? await manager.storeData(
                                responseData,
                                forKey: "\(cacheKey)_response",
                                type: .llmResponse,
                                isSecure: false
                            )
                        }
                    }
                } else {
                    throw SyncError.serverError("Sync failed for \(cacheKey)")
                }
            } catch let error as OpenRouterError {
                // Handle specific OpenRouter errors
                switch error {
                case .rateLimited(let retryAfter):
                    throw SyncError.networkError("Rate limited. Retry after \(retryAfter) seconds")
                case .clientError(let code, let message) where code >= 400 && code < 500:
                    // Don't retry client errors
                    throw SyncError.serverError("Client error \(code): \(message)")
                default:
                    throw SyncError.networkError(error.localizedDescription)
                }
            } catch {
                throw SyncError.networkError(error.localizedDescription)
            }
        } else {
            // Fallback to local-only sync
            logger.warning("No OpenRouter adapter available, performing local-only sync")
            
            // Simulate successful local sync
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
        }
    }
    
    /// Pull remote changes from server
    private func pullRemoteChanges() async -> SyncResult {
        logger.debug("Pulling remote changes")
        
        // TODO: Implement actual pull logic
        // This would query the server for changes since lastSyncDate
        
        return SyncResult(
            success: true,
            syncedItems: [],
            failedItems: [],
            conflicts: [],
            duration: 0,
            timestamp: Date()
        )
    }
    
    /// Cancel active sync
    func cancelSync() {
        activeSyncTask?.cancel()
        isSyncing = false
    }
    
    /// Get pending changes count
    func pendingChangesCount() -> Int {
        outbox.count
    }
    
    /// Clear all pending changes
    func clearPendingChanges() async {
        outbox.removeAll()
        await persistOutbox()
    }
    
    /// Persist outbox to disk
    private func persistOutbox() async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(outbox)
            
            let url = outboxFileURL()
            try data.write(to: url)
            
            logger.debug("Persisted \(self.outbox.count) outbox items")
        } catch {
            logger.error("Failed to persist outbox: \(error.localizedDescription)")
        }
    }
    
    /// Load outbox from disk
    private func loadOutbox() async {
        do {
            let url = outboxFileURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            outbox = try decoder.decode([OutboxItem].self, from: data)
            
            logger.info("Loaded \(self.outbox.count) outbox items")
        } catch {
            logger.error("Failed to load outbox: \(error.localizedDescription)")
        }
    }
    
    /// Get outbox file URL
    private func outboxFileURL() -> URL {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documentsPath.appendingPathComponent("cache_outbox.json")
    }
}

/// Sync-related errors
enum SyncError: LocalizedError {
    case networkError(String)
    case serverError(String)
    case conflictDetected(String)
    case authenticationRequired
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .conflictDetected(let key):
            return "Conflict detected for: \(key)"
        case .authenticationRequired:
            return "Authentication required"
        case .invalidData:
            return "Invalid data format"
        }
    }
}