@testable import AIKO
import CoreData
import Foundation
import XCTest

/// Comprehensive test suite for RLPersistenceManager
/// Testing Core Data integration for RL state persistence
///
/// Testing Layers:
/// 1. Bandit persistence and retrieval operations
/// 2. Core Data schema validation
/// 3. Performance requirements for persistence operations
/// 4. Error handling and data integrity
final class RLPersistenceManagerTests: XCTestCase {
    // MARK: - Test Properties

    var persistenceManager: RLPersistenceManager?
    var mockCoreDataStack: AIKO.MockCoreDataStack?
    private var testBandits: [AIKO.ActionIdentifier: AIKO.ContextualBandit]?
    var testFeatureVector: FeatureVector?

    override func setUp() async throws {
        mockCoreDataStack = AIKO.MockCoreDataStack()
        guard let mockCoreDataStack else {
            XCTFail("MockCoreDataStack should be initialized")
            return
        }
        persistenceManager = RLPersistenceManager(coreDataStack: mockCoreDataStack)

        // Create test feature vector
        testFeatureVector = FeatureVector(features: [
            "docType_purchaseRequest": 1.0,
            "value_normalized": 0.5,
            "complexity_score": 0.6,
            "days_remaining": 30.0,
            "is_urgent": 0.0,
        ])
        
        guard let testFeatureVector else {
            XCTFail("TestFeatureVector should be initialized")
            return
        }

        // Create test bandits using AIKO types
        testBandits = [
            AIKO.ActionIdentifier(actionId: "action-1", contextHash: testFeatureVector.hash): AIKO.ContextualBandit(
                contextFeatures: testFeatureVector,
                successCount: 3.0,
                failureCount: 2.0,
                lastUpdate: Date(),
                totalSamples: 5
            ),
            AIKO.ActionIdentifier(actionId: "action-2", contextHash: testFeatureVector.hash): AIKO.ContextualBandit(
                contextFeatures: testFeatureVector,
                successCount: 5.0,
                failureCount: 1.0,
                lastUpdate: Date().addingTimeInterval(-3600),
                totalSamples: 6
            ),
        ]
    }

    override func tearDown() async throws {
        persistenceManager = nil
        mockCoreDataStack = nil
        testBandits = nil
        testFeatureVector = nil
    }

    // MARK: - Bandit Persistence Tests

    func testSaveBandits_PersistenceOperation() async throws {
        guard let persistenceManager,
              let testBandits,
              let mockCoreDataStack
        else {
            XCTFail("Test dependencies should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing basic bandit persistence to Core Data

        // When: Bandits are saved
        try await persistenceManager.saveBandits(testBandits)

        // Then: Core Data should contain the saved bandits
        let context = mockCoreDataStack.backgroundContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RLBandit")

        let results = try await context.perform {
            try context.fetch(fetchRequest)
        }

        XCTAssertEqual(results.count, testBandits.count, "Should save all bandits to Core Data")

        // Verify bandit data integrity
        for result in results {
            XCTAssertNotNil(result.value(forKey: "actionId"), "Action ID should be saved")
            XCTAssertNotNil(result.value(forKey: "contextHash"), "Context hash should be saved")
            XCTAssertNotNil(result.value(forKey: "successCount"), "Success count should be saved")
            XCTAssertNotNil(result.value(forKey: "failureCount"), "Failure count should be saved")
            XCTAssertNotNil(result.value(forKey: "lastUpdate"), "Last update should be saved")
            XCTAssertNotNil(result.value(forKey: "totalSamples"), "Total samples should be saved")
            XCTAssertNotNil(result.value(forKey: "contextFeatures"), "Context features should be encoded and saved")
        }
    }

    func testLoadBandits_RetrievalOperation() async throws {
        guard let persistenceManager,
              let testBandits
        else {
            XCTFail("Test dependencies should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing bandit retrieval from Core Data

        // Given: Bandits are saved first
        try await persistenceManager.saveBandits(testBandits)

        // When: Bandits are loaded
        let loadedBandits = try await persistenceManager.loadBandits()

        // Then: Loaded bandits should match saved bandits
        XCTAssertEqual(loadedBandits.count, testBandits.count, "Should load all saved bandits")

        for (identifier, originalBandit) in testBandits {
            guard let loadedBandit = loadedBandits[identifier] else {
                XCTFail("Should load bandit for identifier \(identifier)")
                continue
            }

            XCTAssertEqual(loadedBandit.successCount, originalBandit.successCount, "Success count should match")
            XCTAssertEqual(loadedBandit.failureCount, originalBandit.failureCount, "Failure count should match")
            XCTAssertEqual(loadedBandit.totalSamples, originalBandit.totalSamples, "Total samples should match")
            XCTAssertEqual(loadedBandit.contextFeatures, originalBandit.contextFeatures, "Context features should match")
        }
    }

    func testSaveLoad_RoundTripConsistency() async throws {
        guard let persistenceManager,
              var testBandits
        else {
            XCTFail("Test dependencies should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing round-trip persistence consistency

        // Given: Multiple save-load cycles
        for iteration in 0 ..< 5 {
            // Update bandits with new data
            for (identifier, _) in testBandits {
                testBandits[identifier]?.updatePosterior(reward: Double(iteration) / 10.0)
            }

            // Save and load
            try await persistenceManager.saveBandits(testBandits)
            let loadedBandits = try await persistenceManager.loadBandits()

            // Verify consistency
            XCTAssertEqual(loadedBandits.count, testBandits.count, "Round-trip \(iteration) should preserve count")

            for (identifier, originalBandit) in testBandits {
                guard let loadedBandit = loadedBandits[identifier] else {
                    XCTFail("Round-trip \(iteration) should preserve bandit \(identifier)")
                    continue
                }

                XCTAssertEqual(loadedBandit.successCount, originalBandit.successCount, accuracy: 0.001, "Round-trip \(iteration) should preserve success count")
                XCTAssertEqual(loadedBandit.failureCount, originalBandit.failureCount, accuracy: 0.001, "Round-trip \(iteration) should preserve failure count")
            }

            // Update test bandits for next iteration
            testBandits = loadedBandits
        }
    }

    // MARK: - Data Integrity Tests

    func testSaveBandits_OverwriteExisting() async throws {
        guard let persistenceManager,
              let testBandits,
              let mockCoreDataStack
        else {
            XCTFail("Test dependencies should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing that saving bandits overwrites existing data

        // Given: Initial bandits are saved
        try await persistenceManager.saveBandits(testBandits)

        // When: Modified bandits are saved
        let modifiedBandits = testBandits.mapValues { bandit in
            var modified = bandit
            modified.updatePosterior(reward: 1.0)
            return modified
        }

        try await persistenceManager.saveBandits(modifiedBandits)

        // Then: Should have updated values, not duplicates
        let context = mockCoreDataStack.backgroundContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RLBandit")

        let results = try await context.perform {
            try context.fetch(fetchRequest)
        }

        XCTAssertEqual(results.count, testBandits.count, "Should not create duplicate entries")

        // Verify updated values
        let loadedBandits = try await persistenceManager.loadBandits()
        for (identifier, modifiedBandit) in modifiedBandits {
            guard let loadedBandit = loadedBandits[identifier] else {
                XCTFail("Should load modified bandit for identifier \(identifier)")
                continue
            }

            XCTAssertEqual(loadedBandit.successCount, modifiedBandit.successCount, "Should have updated success count")
            XCTAssertNotEqual(loadedBandit.successCount, testBandits[identifier]?.successCount, "Should not have original success count")
        }
    }

    func testLoadBandits_EmptyDatabase() async throws {
        guard let persistenceManager else {
            XCTFail("Persistence manager should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing loading from empty database

        // When: Loading from empty database
        let loadedBandits = try await persistenceManager.loadBandits()

        // Then: Should return empty dictionary
        XCTAssertTrue(loadedBandits.isEmpty, "Should return empty dictionary for empty database")
    }

    func testFeatureVectorEncoding_JSONSerialization() async throws {
        guard let persistenceManager else {
            XCTFail("Persistence manager should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing JSON encoding/decoding of feature vectors

        // Given: Complex feature vector
        let complexFeatures = FeatureVector(features: [
            "docType_emergencyProcurement": 1.0,
            "value_normalized": 0.95,
            "complexity_score": 0.85,
            "days_remaining": 1.0,
            "is_urgent": 1.0,
            "has_52.215-1": 1.0,
            "has_52.209-5": 1.0,
            "workflow_progress": 0.75,
            "documents_completed": 5.0,
        ])

        let complexBandits = [
            ActionIdentifier(actionId: "complex-action", contextHash: complexFeatures.hash): ContextualBandit(
                contextFeatures: complexFeatures,
                successCount: 10.0,
                failureCount: 3.0,
                lastUpdate: Date(),
                totalSamples: 13
            ),
        ]

        // When: Saving and loading complex features
        try await persistenceManager.saveBandits(complexBandits)
        let loadedBandits = try await persistenceManager.loadBandits()

        // Then: Complex features should be preserved
        guard let loadedBandit = loadedBandits.first?.value else {
            XCTFail("Should load complex bandit")
            return
        }

        XCTAssertEqual(loadedBandit.contextFeatures.features.count, complexFeatures.features.count, "Should preserve all features")

        for (key, originalValue) in complexFeatures.features {
            guard let loadedValue = loadedBandit.contextFeatures.features[key] else {
                XCTFail("Should preserve feature \(key)")
                continue
            }
            XCTAssertEqual(loadedValue, originalValue, accuracy: 0.001, "Should preserve feature value for \(key)")
        }
    }

    // MARK: - Performance Tests

    func testSaveBandits_PerformanceLatency() async throws {
        guard let persistenceManager else {
            XCTFail("Persistence manager should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing save operation performance requirements

        // Given: Large number of bandits
        var largeBanditSet: [ActionIdentifier: ContextualBandit] = [:]
        for i in 0 ..< 1000 {
            let features = FeatureVector(features: [
                "docType_test\(i % 5)": 1.0,
                "value_normalized": Double(i % 100) / 100.0,
                "complexity_score": Double(i % 10) / 10.0,
            ])

            let identifier = ActionIdentifier(actionId: "action-\(i)", contextHash: features.hash)
            largeBanditSet[identifier] = ContextualBandit(
                contextFeatures: features,
                successCount: Double(i % 10 + 1),
                failureCount: Double(i % 5 + 1),
                lastUpdate: Date(),
                totalSamples: i % 15 + 2
            )
        }

        // When: Measuring save performance
        let startTime = CFAbsoluteTimeGetCurrent()
        try await persistenceManager.saveBandits(largeBanditSet)
        let endTime = CFAbsoluteTimeGetCurrent()

        let saveTime = endTime - startTime

        // Then: Save operation should meet performance requirements
        XCTAssertLessThan(saveTime, 2.0, "Saving 1000 bandits should complete within 2 seconds")
    }

    func testLoadBandits_PerformanceLatency() async throws {
        guard let persistenceManager else {
            XCTFail("Persistence manager should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing load operation performance requirements

        // Given: Large bandit set is already saved
        var largeBanditSet: [ActionIdentifier: ContextualBandit] = [:]
        for i in 0 ..< 500 {
            let features = FeatureVector(features: [
                "docType_load\(i % 3)": 1.0,
                "value_normalized": Double(i % 50) / 50.0,
            ])

            let identifier = ActionIdentifier(actionId: "load-action-\(i)", contextHash: features.hash)
            largeBanditSet[identifier] = ContextualBandit(
                contextFeatures: features,
                successCount: Double(i % 8 + 1),
                failureCount: Double(i % 4 + 1),
                lastUpdate: Date(),
                totalSamples: i % 12 + 2
            )
        }

        try await persistenceManager.saveBandits(largeBanditSet)

        // When: Measuring load performance
        let startTime = CFAbsoluteTimeGetCurrent()
        let loadedBandits = try await persistenceManager.loadBandits()
        let endTime = CFAbsoluteTimeGetCurrent()

        let loadTime = endTime - startTime

        // Then: Load operation should meet performance requirements
        XCTAssertLessThan(loadTime, 1.0, "Loading 500 bandits should complete within 1 second")
        XCTAssertEqual(loadedBandits.count, largeBanditSet.count, "Should load all bandits")
    }

    // MARK: - Error Handling Tests

    func testSaveBandits_DatabaseError() async throws {
        guard let persistenceManager,
              let testBandits,
              let mockCoreDataStack
        else {
            XCTFail("Test dependencies should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing error handling for database failures

        // Given: Mock Core Data stack configured to fail
        mockCoreDataStack.shouldFailSave = true

        // When: Attempting to save bandits
        do {
            try await persistenceManager.saveBandits(testBandits)
            XCTFail("Should throw error when Core Data save fails")
        } catch {
            // Then: Should propagate Core Data error
            XCTAssertTrue(error is CoreDataError, "Should throw CoreDataError")
        }
    }

    func testLoadBandits_CorruptedData() async throws {
        guard let persistenceManager,
              let mockCoreDataStack
        else {
            XCTFail("Test dependencies should be initialized")
            return
        }
        // RED PHASE: This test should FAIL initially
        // Testing error handling for corrupted data

        // Given: Corrupted bandit data in Core Data
        let context = mockCoreDataStack.backgroundContext

        try await context.perform {
            guard let entity = NSEntityDescription.entity(forEntityName: "RLBandit", in: context) else {
                XCTFail("Failed to get RLBandit entity description")
                return
            }
            let corruptedObject = NSManagedObject(entity: entity, insertInto: context)

            // Set invalid data
            corruptedObject.setValue("valid-action", forKey: "actionId")
            corruptedObject.setValue(12345, forKey: "contextHash")
            corruptedObject.setValue("invalid-data", forKey: "successCount") // Should be Double
            corruptedObject.setValue(2.0, forKey: "failureCount")
            corruptedObject.setValue(Date(), forKey: "lastUpdate")
            corruptedObject.setValue(3, forKey: "totalSamples")
            corruptedObject.setValue(Data(), forKey: "contextFeatures") // Empty/invalid JSON

            try context.save()
        }

        // When: Loading corrupted data
        let loadedBandits = try await persistenceManager.loadBandits()

        // Then: Should handle corrupted data gracefully
        XCTAssertTrue(loadedBandits.isEmpty, "Should skip corrupted entries and return empty result")
    }

    func testConcurrentAccess_ThreadSafety() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing thread safety under concurrent access

        let concurrentOperations = 20

        // When: Multiple concurrent save operations
        guard let persistenceManagerLocal = persistenceManager else {
            XCTFail("Persistence manager should be initialized")
            return
        }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0 ..< concurrentOperations {
                group.addTask {
                    let features = FeatureVector(features: [
                        "docType_concurrent\(i)": 1.0,
                        "value_normalized": Double(i) / 100.0,
                    ])

                    let bandits = [
                        ActionIdentifier(actionId: "concurrent-\(i)", contextHash: features.hash): ContextualBandit(
                            contextFeatures: features,
                            successCount: Double(i + 1),
                            failureCount: 1.0,
                            lastUpdate: Date(),
                            totalSamples: i + 2
                        ),
                    ]

                    try await persistenceManagerLocal.saveBandits(bandits)
                }
            }

            try await group.waitForAll()
        }

        // Then: All operations should complete without data corruption
        let finalBandits = try await persistenceManagerLocal.loadBandits()
        XCTAssertGreaterThan(finalBandits.count, 0, "Should have saved at least some bandits")

        // Verify data integrity
        for (_, bandit) in finalBandits {
            XCTAssertGreaterThan(bandit.successCount, 0, "Success count should be valid")
            XCTAssertGreaterThan(bandit.totalSamples, 0, "Total samples should be valid")
            XCTAssertFalse(bandit.contextFeatures.features.isEmpty, "Features should not be empty")
        }
    }

    // MARK: - Helper Types

    // Using AIKO module types instead of private definitions
}

// MARK: - Mock Core Data Stack

class MockCoreDataStack {
    var shouldFailSave = false

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TestModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load store: \(error)")
            }
        }

        return container
    }()

    var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
}

enum CoreDataError: Error {
    case saveFailed
    case loadFailed
    case corruptedData
}
