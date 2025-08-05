@preconcurrency import CoreData
import Foundation

/// Persistence manager for RL state and bandit storage
/// Manages Core Data integration for contextual bandits and Q-learning state
public actor RLPersistenceManager {
    // MARK: - Dependencies

    private let coreDataStack: CoreDataStack

    // MARK: - Configuration

    private let batchSize: Int = 100
    private let maxRetentionDays: Int = 90

    // MARK: - Initialization

    public init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Bandit Persistence

    /// Save contextual bandits to Core Data
    public func saveBandits(_ bandits: [ActionIdentifier: ContextualBandit]) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            for (identifier, bandit) in bandits {
                // Check if bandit already exists
                let fetchRequest: NSFetchRequest<BanditEntity> = BanditEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(
                    format: "actionId == %@ AND contextHash == %@",
                    identifier.actionId,
                    identifier.contextHash
                )

                let existingBandits = try context.fetch(fetchRequest)
                let banditEntity = existingBandits.first ?? BanditEntity(context: context)

                // Update bandit entity
                banditEntity.actionId = identifier.actionId
                banditEntity.contextHash = identifier.contextHash
                banditEntity.successCount = bandit.successCount
                banditEntity.failureCount = bandit.failureCount
                banditEntity.lastUpdate = bandit.lastUpdate
                banditEntity.totalSamples = Int32(bandit.totalSamples)

                // Store feature vector
                if let featuresData = try? JSONEncoder().encode(bandit.contextFeatures.features) {
                    banditEntity.contextFeatures = featuresData
                }

                try context.save()
            }
        }
    }

    /// Load contextual bandits from Core Data
    public func loadBandits() async throws -> [ActionIdentifier: ContextualBandit] {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let fetchRequest: NSFetchRequest<BanditEntity> = BanditEntity.fetchRequest()
            let banditEntities = try context.fetch(fetchRequest)

            var bandits: [ActionIdentifier: ContextualBandit] = [:]

            for entity in banditEntities {
                guard let actionId = entity.actionId,
                      let contextHash = entity.contextHash,
                      let featuresData = entity.contextFeatures
                else {
                    continue
                }

                // Decode feature vector
                let features = try JSONDecoder().decode([String: Double].self, from: featuresData)
                let featureVector = FeatureVector(features: features)

                let identifier = ActionIdentifier(actionId: actionId, contextHash: contextHash)
                let bandit = ContextualBandit(
                    contextFeatures: featureVector,
                    successCount: entity.successCount,
                    failureCount: entity.failureCount,
                    lastUpdate: entity.lastUpdate ?? Date(),
                    totalSamples: Int(entity.totalSamples)
                )

                bandits[identifier] = bandit
            }

            return bandits
        }
    }

    /// Save Q-learning state to Core Data
    public func saveQLearningState(_ qTable: [String: [String: Double]]) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            // Clear existing Q-table entries
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: QTableEntity.fetchRequest())
            try context.execute(deleteRequest)

            // Save new Q-table entries
            for (stateKey, actions) in qTable {
                for (actionKey, qValue) in actions {
                    let qEntity = QTableEntity(context: context)
                    qEntity.stateKey = stateKey
                    qEntity.actionKey = actionKey
                    qEntity.qValue = qValue
                    qEntity.lastUpdate = Date()
                }
            }

            try context.save()
        }
    }

    /// Load Q-learning state from Core Data
    public func loadQLearningState() async throws -> [String: [String: Double]] {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let fetchRequest: NSFetchRequest<QTableEntity> = QTableEntity.fetchRequest()
            let qEntities = try context.fetch(fetchRequest)

            var qTable: [String: [String: Double]] = [:]

            for entity in qEntities {
                guard let stateKey = entity.stateKey,
                      let actionKey = entity.actionKey
                else {
                    continue
                }

                if qTable[stateKey] == nil {
                    qTable[stateKey] = [:]
                }

                qTable[stateKey]?[actionKey] = entity.qValue
            }

            return qTable
        }
    }

    /// Clean up old data based on retention policy
    public func cleanupOldData() async throws {
        let context = coreDataStack.newBackgroundContext()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxRetentionDays, to: Date()) ?? Date()

        try await context.perform {
            // Clean up old bandit data
            let banditFetch: NSFetchRequest<BanditEntity> = BanditEntity.fetchRequest()
            banditFetch.predicate = NSPredicate(format: "lastUpdate < %@", cutoffDate as NSDate)

            let oldBandits = try context.fetch(banditFetch)
            for bandit in oldBandits {
                context.delete(bandit)
            }

            // Clean up old Q-table data
            let qTableFetch: NSFetchRequest<QTableEntity> = QTableEntity.fetchRequest()
            qTableFetch.predicate = NSPredicate(format: "lastUpdate < %@", cutoffDate as NSDate)

            let oldQEntries = try context.fetch(qTableFetch)
            for qEntry in oldQEntries {
                context.delete(qEntry)
            }

            try context.save()
        }
    }

    /// Get storage statistics
    public func getStorageStatistics() async throws -> StorageStatistics {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let banditCount = try context.count(for: BanditEntity.fetchRequest())
            let qTableCount = try context.count(for: QTableEntity.fetchRequest())

            return StorageStatistics(
                banditCount: banditCount,
                qTableEntries: qTableCount,
                estimatedSizeKB: Double(banditCount + qTableCount) * 0.5 // Rough estimate
            )
        }
    }
}

// MARK: - Supporting Types

public struct ActionIdentifier: Hashable, Sendable {
    public let actionId: String
    public let contextHash: String

    public init(actionId: String, contextHash: String) {
        self.actionId = actionId
        self.contextHash = contextHash
    }
}

public struct ContextualBandit: Sendable {
    public let contextFeatures: FeatureVector
    public var successCount: Double
    public var failureCount: Double
    public var lastUpdate: Date
    public var totalSamples: Int

    public init(contextFeatures: FeatureVector, successCount: Double, failureCount: Double, lastUpdate: Date, totalSamples: Int) {
        self.contextFeatures = contextFeatures
        self.successCount = successCount
        self.failureCount = failureCount
        self.lastUpdate = lastUpdate
        self.totalSamples = totalSamples
    }

    /// Update bandit posterior with reward signal
    public mutating func updatePosterior(reward: Double) {
        if reward > 0.5 {
            successCount += 1.0
        } else {
            failureCount += 1.0
        }
        totalSamples += 1
        lastUpdate = Date()
    }

    public var successRate: Double {
        let total = successCount + failureCount
        return total > 0 ? successCount / total : 0.0
    }

    public var confidence: Double {
        // Using Wilson score interval for confidence
        let n = Double(totalSamples)
        let p = successRate

        if n == 0 { return 0.0 }

        let z = 1.96 // 95% confidence
        let denominator = 1 + z * z / n
        let centre = p + z * z / (2 * n)
        let adjustment = z * sqrt(p * (1 - p) / n + z * z / (4 * n * n))

        return max(0.0, min(1.0, (centre - adjustment) / denominator))
    }
}

public struct StorageStatistics: Sendable {
    public let banditCount: Int
    public let qTableEntries: Int
    public let estimatedSizeKB: Double

    public init(banditCount: Int, qTableEntries: Int, estimatedSizeKB: Double) {
        self.banditCount = banditCount
        self.qTableEntries = qTableEntries
        self.estimatedSizeKB = estimatedSizeKB
    }
}

// MARK: - Core Data Stack Protocol

public protocol CoreDataStack {
    func newBackgroundContext() -> NSManagedObjectContext
}

// MARK: - Mock Core Data Stack for Testing

public class MockCoreDataStack: CoreDataStack {
    private let persistentContainer: NSPersistentContainer

    public init() {
        // Create in-memory store for testing
        persistentContainer = NSPersistentContainer(name: "TestModel")
        persistentContainer.persistentStoreDescriptions.first?.type = NSInMemoryStoreType

        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load store: \(error)")
            }
        }
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
}

// MARK: - Core Data Entities (Simplified)

/// Core Data entity for bandit storage
@objc(BanditEntity)
public class BanditEntity: NSManagedObject {
    @NSManaged public var actionId: String?
    @NSManaged public var contextHash: String?
    @NSManaged public var successCount: Double
    @NSManaged public var failureCount: Double
    @NSManaged public var lastUpdate: Date?
    @NSManaged public var totalSamples: Int32
    @NSManaged public var contextFeatures: Data?
}

public extension BanditEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<BanditEntity> {
        NSFetchRequest<BanditEntity>(entityName: "BanditEntity")
    }
}

/// Core Data entity for Q-table storage
@objc(QTableEntity)
public class QTableEntity: NSManagedObject {
    @NSManaged public var stateKey: String?
    @NSManaged public var actionKey: String?
    @NSManaged public var qValue: Double
    @NSManaged public var lastUpdate: Date?
}

public extension QTableEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<QTableEntity> {
        NSFetchRequest<QTableEntity>(entityName: "QTableEntity")
    }
}
