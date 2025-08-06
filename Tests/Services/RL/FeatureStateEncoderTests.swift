@testable import AIKO
@testable import AppCore
import Foundation
import XCTest

/// Comprehensive test suite for FeatureStateEncoder
/// Testing feature extraction and context-to-feature conversion
///
/// Testing Layers:
/// 1. Feature extraction accuracy and consistency
/// 2. Normalization and encoding validation
/// 3. Edge case handling and error scenarios
/// 4. Performance requirements for encoding speed
final class FeatureStateEncoderTests: XCTestCase {
    // MARK: - Test Properties

    var testContext: TestAcquisitionContext?
    var complexContext: TestAcquisitionContext?
    var minimalContext: TestAcquisitionContext?

    override func setUp() async throws {
        // Standard test context
        testContext = TestAcquisitionContext(
            acquisitionId: UUID(),
            documentType: .purchaseRequest,
            acquisitionValue: 150_000.0,
            complexity: TestComplexityLevel(score: 0.6, factors: ["multi-step", "regulatory"]),
            timeConstraints: TestTimeConstraints(
                daysRemaining: 45,
                isUrgent: false,
                expectedDuration: 5400.0
            ),
            regulatoryRequirements: Set([
                AppCore.TestFARClause(clauseNumber: "52.215-1", isCritical: true),
                AppCore.TestFARClause(clauseNumber: "52.209-5", isCritical: false),
                AppCore.TestFARClause(clauseNumber: "52.233-1", isCritical: true),
            ]),
            historicalSuccess: 0.75,
            userProfile: TestUserProfile(experienceLevel: 0.8),
            workflowProgress: 0.25,
            completedDocuments: ["initial-requirements", "market-research"]
        )

        // Complex context with many features
        complexContext = TestAcquisitionContext(
            acquisitionId: UUID(),
            documentType: .sourceSelection,
            acquisitionValue: 5_000_000.0,
            complexity: TestComplexityLevel(score: 0.95, factors: ["complex", "multi-vendor", "high-value", "critical"]),
            timeConstraints: TestTimeConstraints(
                daysRemaining: 5,
                isUrgent: true,
                expectedDuration: 28800.0
            ),
            regulatoryRequirements: Set((1 ... 15).map {
                AppCore.TestFARClause(clauseNumber: "52.215-\($0)", isCritical: $0 <= 5)
            }),
            historicalSuccess: 0.45,
            userProfile: TestUserProfile(experienceLevel: 0.3),
            workflowProgress: 0.8,
            completedDocuments: Array(1 ... 10).map { "document-\($0)" }
        )

        // Minimal context
        minimalContext = TestAcquisitionContext(
            acquisitionId: UUID(),
            documentType: .simplePurchase,
            acquisitionValue: 1000.0,
            complexity: TestComplexityLevel(score: 0.1, factors: ["simple"]),
            timeConstraints: TestTimeConstraints(
                daysRemaining: 90,
                isUrgent: false,
                expectedDuration: 1800.0
            ),
            regulatoryRequirements: Set(),
            historicalSuccess: 0.95,
            userProfile: TestUserProfile(experienceLevel: 0.9),
            workflowProgress: 0.0,
            completedDocuments: []
        )
    }

    override func tearDown() async throws {
        testContext = nil
        complexContext = nil
        minimalContext = nil
    }

    // MARK: - Feature Extraction Tests

    func testFeatureExtraction_DocumentTypeEncoding() throws {
        // RED PHASE: This test should FAIL initially
        // Testing one-hot encoding of document types

        guard let testContext,
              let complexContext
        else {
            XCTFail("Test contexts should be initialized")
            return
        }

        // When: Context is encoded
        let features = FeatureStateEncoder.encode(testContext)

        // Then: Document type should be one-hot encoded
        XCTAssertEqual(features.features["docType_purchaseRequest"], 1.0, "Document type should be one-hot encoded")
        XCTAssertNil(features.features["docType_sourceSelection"], "Other document types should not be present")
        XCTAssertNil(features.features["docType_emergencyProcurement"], "Other document types should not be present")

        // Test different document type
        let sourceSelectionFeatures = FeatureStateEncoder.encode(complexContext)
        XCTAssertEqual(sourceSelectionFeatures.features["docType_sourceSelection"], 1.0, "Source selection type should be encoded")
        XCTAssertNil(sourceSelectionFeatures.features["docType_purchaseRequest"], "Other document types should not be present")
    }

    func testFeatureExtraction_ValueNormalization() throws {
        // RED PHASE: This test should FAIL initially
        // Testing acquisition value normalization

        guard let testContext,
              let complexContext,
              let minimalContext
        else {
            XCTFail("Test contexts should be initialized")
            return
        }

        // When: Different contexts with varying values are encoded
        let standardFeatures = FeatureStateEncoder.encode(testContext) // $150k
        let highValueFeatures = FeatureStateEncoder.encode(complexContext) // $5M
        let lowValueFeatures = FeatureStateEncoder.encode(minimalContext) // $1k

        // Then: Values should be normalized to [0,1] range
        guard let standardValue = standardFeatures.features["value_normalized"] else {
            XCTFail("Standard value_normalized feature should exist")
            return
        }
        guard let highValue = highValueFeatures.features["value_normalized"] else {
            XCTFail("High value_normalized feature should exist")
            return
        }
        guard let lowValue = lowValueFeatures.features["value_normalized"] else {
            XCTFail("Low value_normalized feature should exist")
            return
        }

        XCTAssertTrue(standardValue >= 0.0 && standardValue <= 1.0, "Standard value should be normalized")
        XCTAssertTrue(highValue >= 0.0 && highValue <= 1.0, "High value should be normalized")
        XCTAssertTrue(lowValue >= 0.0 && lowValue <= 1.0, "Low value should be normalized")

        // Higher acquisition values should result in higher normalized values
        XCTAssertGreaterThan(highValue, standardValue, "Higher acquisition value should have higher normalized value")
        XCTAssertGreaterThan(standardValue, lowValue, "Medium value should be higher than low value")

        // Test log scaling
        guard let standardLogValue = standardFeatures.features["value_log"] else {
            XCTFail("Standard value_log feature should exist")
            return
        }
        guard let highLogValue = highValueFeatures.features["value_log"] else {
            XCTFail("High value_log feature should exist")
            return
        }

        XCTAssertGreaterThan(highLogValue, standardLogValue, "Log values should preserve ordering")
        XCTAssertGreaterThan(standardLogValue, 0.0, "Log values should be positive")
    }

    func testFeatureExtraction_ComplexityFeatures() throws {
        // RED PHASE: This test should FAIL initially
        // Testing complexity score and requirement count encoding

        guard let testContext,
              let complexContext,
              let minimalContext
        else {
            XCTFail("Test contexts should be initialized")
            return
        }

        // When: Contexts with different complexity are encoded
        let simpleFeatures = FeatureStateEncoder.encode(minimalContext)
        let standardFeatures = FeatureStateEncoder.encode(testContext)
        let complexFeatures = FeatureStateEncoder.encode(complexContext)

        // Then: Complexity scores should be preserved
        XCTAssertEqual(simpleFeatures.features["complexity_score"], 0.1, "Simple complexity should be encoded")
        XCTAssertEqual(standardFeatures.features["complexity_score"], 0.6, "Standard complexity should be encoded")
        XCTAssertEqual(complexFeatures.features["complexity_score"], 0.95, "Complex complexity should be encoded")

        // Requirement counts should be encoded
        XCTAssertEqual(simpleFeatures.features["num_requirements"], 0.0, "No requirements should be 0")
        XCTAssertEqual(standardFeatures.features["num_requirements"], 3.0, "Three requirements should be encoded")
        XCTAssertEqual(complexFeatures.features["num_requirements"], 15.0, "Fifteen requirements should be encoded")
    }

    func testFeatureExtraction_TimeConstraintFeatures() throws {
        // RED PHASE: This test should FAIL initially
        // Testing time constraint feature encoding

        guard let complexContext, let testContext, let minimalContext else {
            XCTFail("Test contexts should be initialized")
            return
        }
        
        // When: Contexts with different time constraints are encoded
        let urgentFeatures = FeatureStateEncoder.encode(complexContext) // 5 days, urgent
        let routineFeatures = FeatureStateEncoder.encode(testContext) // 45 days, not urgent
        let relaxedFeatures = FeatureStateEncoder.encode(minimalContext) // 90 days, not urgent

        // Then: Time features should be encoded correctly
        XCTAssertEqual(urgentFeatures.features["days_remaining"], 5.0, "Urgent deadline should be encoded")
        XCTAssertEqual(urgentFeatures.features["is_urgent"], 1.0, "Urgent flag should be 1.0")

        XCTAssertEqual(routineFeatures.features["days_remaining"], 45.0, "Routine deadline should be encoded")
        XCTAssertEqual(routineFeatures.features["is_urgent"], 0.0, "Non-urgent flag should be 0.0")

        XCTAssertEqual(relaxedFeatures.features["days_remaining"], 90.0, "Relaxed deadline should be encoded")
        XCTAssertEqual(relaxedFeatures.features["is_urgent"], 0.0, "Non-urgent flag should be 0.0")
    }

    func testFeatureExtraction_HistoricalFeatures() throws {
        // RED PHASE: This test should FAIL initially
        // Testing historical success and user experience encoding

        guard let testContext, let complexContext, let minimalContext else {
            XCTFail("Test contexts should be initialized")
            return
        }
        
        // When: Context is encoded
        let features = FeatureStateEncoder.encode(testContext)

        // Then: Historical features should be present
        XCTAssertEqual(features.features["past_success_rate"], 0.75, "Historical success rate should be encoded")
        XCTAssertEqual(features.features["user_experience_level"], 0.8, "User experience level should be encoded")

        // Test different experience levels
        let noviceFeatures = FeatureStateEncoder.encode(complexContext) // 0.3 experience
        let expertFeatures = FeatureStateEncoder.encode(minimalContext) // 0.9 experience

        XCTAssertEqual(noviceFeatures.features["user_experience_level"], 0.3, "Novice experience should be encoded")
        XCTAssertEqual(expertFeatures.features["user_experience_level"], 0.9, "Expert experience should be encoded")
    }

    func testFeatureExtraction_RegulatoryFeatures() throws {
        // RED PHASE: This test should FAIL initially
        // Testing regulatory requirement encoding (up to 10 most common)

        guard let testContext,
              let complexContext,
              let minimalContext
        else {
            XCTFail("Test contexts should be initialized")
            return
        }

        // When: Context with multiple requirements is encoded
        let features = FeatureStateEncoder.encode(testContext)

        // Then: Regulatory features should be encoded as binary indicators
        XCTAssertEqual(features.features["has_52.215-1"], 1.0, "Critical requirement should be encoded")
        XCTAssertEqual(features.features["has_52.209-5"], 1.0, "Standard requirement should be encoded")
        XCTAssertEqual(features.features["has_52.233-1"], 1.0, "Additional requirement should be encoded")

        // Test context with no requirements
        let noReqFeatures = FeatureStateEncoder.encode(minimalContext)
        let regulatoryFeatureCount = noReqFeatures.features.filter { $0.key.hasPrefix("has_") }.count
        XCTAssertEqual(regulatoryFeatureCount, 0, "Context with no requirements should have no regulatory features")

        // Test context with many requirements (should be limited to first 10)
        let manyReqFeatures = FeatureStateEncoder.encode(complexContext)
        let manyRegulatoryFeatures = manyReqFeatures.features.filter { $0.key.hasPrefix("has_") }
        XCTAssertLessThanOrEqual(manyRegulatoryFeatures.count, 10, "Should limit to max 10 regulatory features")
    }

    func testFeatureExtraction_WorkflowStateFeatures() throws {
        // RED PHASE: This test should FAIL initially
        // Testing workflow progress and completion features

        guard let testContext,
              let complexContext,
              let minimalContext
        else {
            XCTFail("Test contexts should be initialized")
            return
        }

        // When: Context is encoded
        let features = FeatureStateEncoder.encode(testContext)

        // Then: Workflow state features should be present
        XCTAssertEqual(features.features["workflow_progress"], 0.25, "Workflow progress should be encoded")
        XCTAssertEqual(features.features["documents_completed"], 2.0, "Completed document count should be encoded")

        // Test different workflow states
        let earlyFeatures = FeatureStateEncoder.encode(minimalContext) // 0.0 progress, 0 docs
        let lateFeatures = FeatureStateEncoder.encode(complexContext) // 0.8 progress, 10 docs

        XCTAssertEqual(earlyFeatures.features["workflow_progress"], 0.0, "Early workflow progress should be 0")
        XCTAssertEqual(earlyFeatures.features["documents_completed"], 0.0, "No completed documents should be 0")

        XCTAssertEqual(lateFeatures.features["workflow_progress"], 0.8, "Late workflow progress should be 0.8")
        XCTAssertEqual(lateFeatures.features["documents_completed"], 10.0, "Ten completed documents should be encoded")
    }

    // MARK: - Feature Vector Tests

    func testFeatureVector_HashConsistency() throws {
        // RED PHASE: This test should FAIL initially
        // Testing hash consistency for identical contexts

        // Given: Two identical contexts
        guard let context1 = testContext else {
            XCTFail("Test context should be initialized")
            return
        }
        let context2 = TestAcquisitionContext(
            acquisitionId: UUID(), // Different ID but same content
            documentType: context1.documentType,
            acquisitionValue: context1.acquisitionValue,
            complexity: context1.complexity,
            timeConstraints: context1.timeConstraints,
            regulatoryRequirements: context1.regulatoryRequirements,
            historicalSuccess: context1.historicalSuccess,
            userProfile: context1.userProfile,
            workflowProgress: context1.workflowProgress,
            completedDocuments: context1.completedDocuments
        )

        // When: Both contexts are encoded
        let features1 = FeatureStateEncoder.encode(context1)
        let features2 = FeatureStateEncoder.encode(context2)

        // Then: Feature vectors should have identical hashes
        XCTAssertEqual(features1.hash, features2.hash, "Identical contexts should produce identical feature hashes")
        XCTAssertEqual(features1.features.count, features2.features.count, "Feature count should be identical")

        // Individual features should match
        for (key, value1) in features1.features {
            let value2 = features2.features[key]
            XCTAssertNotNil(value2, "Feature \(key) should exist in both vectors")
            guard let value2 else {
                XCTFail("Feature \(key) should exist in both vectors")
                return
            }
            XCTAssertEqual(value1, value2, accuracy: 1e-6, "Feature \(key) values should match")
        }
    }

    func testFeatureVector_HashStability() throws {
        // RED PHASE: This test should FAIL initially
        // Testing hash stability across multiple encodings

        guard let context = testContext else {
            XCTFail("Test context should be initialized")
            return
        }
        var hashes: [Int] = []

        // When: Same context is encoded multiple times
        for _ in 0 ..< 10 {
            let features = FeatureStateEncoder.encode(context)
            hashes.append(features.hash)
        }

        // Then: All hashes should be identical
        let uniqueHashes = Set(hashes)
        XCTAssertEqual(uniqueHashes.count, 1, "Multiple encodings of same context should produce identical hashes")
    }

    func testFeatureVector_Equatability() throws {
        // RED PHASE: This test should FAIL initially
        // Testing FeatureVector equality comparison

        guard let testContext,
              let complexContext
        else {
            XCTFail("Test contexts should be initialized")
            return
        }

        let features1 = FeatureStateEncoder.encode(testContext)
        let features2 = FeatureStateEncoder.encode(testContext)
        let features3 = FeatureStateEncoder.encode(complexContext)

        // Then: Identical feature vectors should be equal
        XCTAssertEqual(features1, features2, "Identical feature vectors should be equal")
        XCTAssertNotEqual(features1, features3, "Different feature vectors should not be equal")
    }

    // MARK: - Edge Case Tests

    func testFeatureExtraction_EmptyRegulatory() throws {
        // RED PHASE: This test should FAIL initially
        // Testing context with no regulatory requirements

        guard let minimalContext else {
            XCTFail("Minimal context should be initialized")
            return
        }

        // When: Context with empty regulatory requirements is encoded
        let features = FeatureStateEncoder.encode(minimalContext)

        // Then: Should handle empty requirements gracefully
        XCTAssertEqual(features.features["num_requirements"], 0.0, "Empty requirements should result in 0 count")

        // No regulatory features should be present
        let regulatoryFeatures = features.features.filter { $0.key.hasPrefix("has_") }
        XCTAssertEqual(regulatoryFeatures.count, 0, "No regulatory features should be present for empty requirements")
    }

    func testFeatureExtraction_ExtremeValues() throws {
        // RED PHASE: This test should FAIL initially
        // Testing extreme acquisition values

        let extremeContext = TestAcquisitionContext(
            acquisitionId: UUID(),
            documentType: .majorConstruction,
            acquisitionValue: 100_000_000.0, // $100M
            complexity: TestComplexityLevel(score: 1.0, factors: ["extreme"]),
            timeConstraints: TestTimeConstraints(daysRemaining: 1, isUrgent: true, expectedDuration: 86400.0),
            regulatoryRequirements: Set(),
            historicalSuccess: 0.0,
            userProfile: TestUserProfile(experienceLevel: 0.0),
            workflowProgress: 1.0,
            completedDocuments: []
        )

        // When: Extreme context is encoded
        let features = FeatureStateEncoder.encode(extremeContext)

        // Then: Values should still be properly normalized
        guard let normalizedValue = features.features["value_normalized"] else {
            XCTFail("value_normalized feature should exist")
            return
        }
        XCTAssertTrue(normalizedValue >= 0.0 && normalizedValue <= 1.0, "Extreme values should be normalized")
        XCTAssertGreaterThan(normalizedValue, 0.9, "Very high values should approach 1.0")

        // Other extreme values should be handled
        XCTAssertEqual(features.features["complexity_score"], 1.0, "Maximum complexity should be 1.0")
        XCTAssertEqual(features.features["workflow_progress"], 1.0, "Complete progress should be 1.0")
        XCTAssertEqual(features.features["past_success_rate"], 0.0, "Zero success rate should be preserved")
    }

    func testFeatureExtraction_NilHandling() throws {
        // RED PHASE: This test should FAIL initially
        // Testing handling of nil or missing values

        // This test will need to be implemented when we have contexts with optional values
        // For now, test with minimal data

        let sparseContext = TestAcquisitionContext(
            acquisitionId: UUID(),
            documentType: .other,
            acquisitionValue: 0.0,
            complexity: TestComplexityLevel(score: 0.0, factors: []),
            timeConstraints: TestTimeConstraints(daysRemaining: 0, isUrgent: false, expectedDuration: 0.0),
            regulatoryRequirements: Set(),
            historicalSuccess: 0.0,
            userProfile: TestUserProfile(experienceLevel: 0.0),
            workflowProgress: 0.0,
            completedDocuments: []
        )

        // When: Sparse context is encoded
        let features = FeatureStateEncoder.encode(sparseContext)

        // Then: Should handle sparse data gracefully
        XCTAssertNotNil(features.features["value_normalized"], "Normalized value should not be nil")
        XCTAssertNotNil(features.features["complexity_score"], "Complexity score should not be nil")
        XCTAssertEqual(features.features["num_requirements"], 0.0, "Empty requirements should be 0")
    }

    // MARK: - Performance Tests

    func testFeatureExtraction_EncodingLatency() throws {
        // RED PHASE: This test should FAIL initially
        // Testing feature encoding performance requirements

        guard let testCtx = testContext,
              let complexCtx = complexContext,
              let minimalCtx = minimalContext
        else {
            XCTFail("Test contexts should be initialized")
            return
        }
        let contexts = [testCtx, complexCtx, minimalCtx]
        let iterations = 1000

        // When: Multiple encoding operations are performed
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0 ..< iterations {
            for context in contexts {
                _ = FeatureStateEncoder.encode(context)
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations * contexts.count)

        // Then: Encoding should meet performance requirements
        XCTAssertLessThan(averageTime, 0.005, "Average encoding time should be < 5ms")
        XCTAssertLessThan(totalTime, 10.0, "Total encoding time should be reasonable")
    }

    func testFeatureExtraction_MemoryEfficiency() throws {
        // RED PHASE: This test should FAIL initially
        // Testing memory usage of feature vectors

        let initialMemory = getMemoryUsage()

        // Create many feature vectors
        var featureVectors: [AppCore.FeatureVector] = []
        for i in 0 ..< 1000 {
            let context = createVariedContext(index: i)
            let features = FeatureStateEncoder.encode(context)
            featureVectors.append(features)
        }

        let peakMemory = getMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory

        // Then: Memory usage should be reasonable
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024, "Memory increase should be < 10MB for 1000 feature vectors")

        // Verify feature vectors are still accessible
        XCTAssertEqual(featureVectors.count, 1000, "All feature vectors should be created")
        XCTAssertGreaterThan(featureVectors[0].features.count, 0, "Feature vectors should contain features")
    }

    // MARK: - Helper Methods

    private func createVariedContext(index: Int) -> TestAcquisitionContext {
        let documentTypes: [AppCore.TestDocumentType] = [.purchaseRequest, .sourceSelection, .emergencyProcurement, .simplePurchase]

        return TestAcquisitionContext(
            acquisitionId: UUID(),
            documentType: documentTypes[index % documentTypes.count],
            acquisitionValue: Double(1000 + index * 10000),
            complexity: TestComplexityLevel(score: Double(index % 100) / 100.0, factors: ["varied-\(index)"]),
            timeConstraints: TestTimeConstraints(
                daysRemaining: 1 + (index % 90),
                isUrgent: index % 10 == 0,
                expectedDuration: Double(1800 + index * 60)
            ),
            regulatoryRequirements: Set([AppCore.TestFARClause(clauseNumber: "52.215-\(index % 20 + 1)", isCritical: index % 3 == 0)]),
            historicalSuccess: Double(index % 100) / 100.0,
            userProfile: TestUserProfile(experienceLevel: Double(index % 100) / 100.0),
            workflowProgress: Double(index % 100) / 100.0,
            completedDocuments: (0 ..< (index % 5)).map { "doc-\($0)" }
        )
    }

    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        }
        return 0
    }
}
