import Combine
import Foundation

/// Protocol defining distributed cache operations
public protocol DistributedCacheProtocol {
    /// Get value from distributed cache
    func get<T: Codable & Sendable>(_ key: String) async throws -> T?

    /// Set value in distributed cache
    func set(_ key: String, value: some Codable & Sendable, ttl: TimeInterval?) async throws

    /// Remove value from distributed cache
    func remove(_ key: String) async throws

    /// Check if key exists in distributed cache
    func exists(_ key: String) async throws -> Bool

    /// Get multiple values
    func getMultiple<T: Codable & Sendable>(_ keys: [String], type: T.Type) async throws -> [String: T]

    /// Set multiple values
    func setMultiple(_ values: [String: some Codable & Sendable], ttl: TimeInterval?) async throws

    /// Remove multiple values
    func removeMultiple(_ keys: [String]) async throws

    /// Get cache statistics
    func getStats() async throws -> DistributedCacheStats

    /// Subscribe to cache events
    func subscribe() -> AnyPublisher<DistributedCacheEvent, Never>
}

/// Statistics for distributed cache
public struct DistributedCacheStats: Sendable {
    public let totalNodes: Int
    public let activeNodes: Int
    public let totalKeys: Int
    public let memoryUsage: Int64
    public let hitRate: Double
    public let averageLatency: TimeInterval
    public let replicationFactor: Int

    public init(
        totalNodes: Int,
        activeNodes: Int,
        totalKeys: Int,
        memoryUsage: Int64,
        hitRate: Double,
        averageLatency: TimeInterval,
        replicationFactor: Int
    ) {
        self.totalNodes = totalNodes
        self.activeNodes = activeNodes
        self.totalKeys = totalKeys
        self.memoryUsage = memoryUsage
        self.hitRate = hitRate
        self.averageLatency = averageLatency
        self.replicationFactor = replicationFactor
    }
}

/// Events emitted by distributed cache
public enum DistributedCacheEvent: Sendable {
    case nodeJoined(nodeId: String)
    case nodeLeft(nodeId: String)
    case keyInvalidated(key: String, nodeId: String)
    case replicationComplete(key: String, nodes: [String])
    case failover(fromNode: String, toNode: String)
    case rebalancing(progress: Double)
}

/// Configuration for distributed cache
public struct DistributedCacheConfiguration: Sendable {
    public let nodeId: String
    public let clusterEndpoints: [String]
    public let replicationFactor: Int
    public let consistencyLevel: ConsistencyLevel
    public let partitionStrategy: PartitionStrategy
    public let syncInterval: TimeInterval
    public let heartbeatInterval: TimeInterval
    public let failoverTimeout: TimeInterval

    public enum ConsistencyLevel: Sendable {
        case eventual
        case strong
        case quorum
    }

    public enum PartitionStrategy: Sendable {
        case consistentHashing
        case range
        case modulo
    }

    public init(
        nodeId: String = UUID().uuidString,
        clusterEndpoints: [String] = ["localhost:7000"],
        replicationFactor: Int = 3,
        consistencyLevel: ConsistencyLevel = .quorum,
        partitionStrategy: PartitionStrategy = .consistentHashing,
        syncInterval: TimeInterval = 5.0,
        heartbeatInterval: TimeInterval = 1.0,
        failoverTimeout: TimeInterval = 10.0
    ) {
        self.nodeId = nodeId
        self.clusterEndpoints = clusterEndpoints
        self.replicationFactor = replicationFactor
        self.consistencyLevel = consistencyLevel
        self.partitionStrategy = partitionStrategy
        self.syncInterval = syncInterval
        self.heartbeatInterval = heartbeatInterval
        self.failoverTimeout = failoverTimeout
    }
}
