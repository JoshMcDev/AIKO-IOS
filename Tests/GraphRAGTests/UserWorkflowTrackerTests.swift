import CryptoKit
import Foundation
@testable import GraphRAG
import XCTest

// MARK: - Test Error Types

private enum WorkflowTestError: Error, LocalizedError {
    case serviceNotInitialized
    case invalidTestData
    case testTimeout
    case assertionFailure(String)

    var errorDescription: String? {
        switch self {
        case .serviceNotInitialized:
            return "Test service was not properly initialized"
        case .invalidTestData:
            return "Test data is invalid or corrupted"
        case .testTimeout:
            return "Test operation timed out"
        case let .assertionFailure(message):
            return "Test assertion failed: \(message)"
        }
    }
}

/// User Workflow Tracker Test Suite - TDD RED Phase
/// Tests designed to FAIL initially, implementing the consensus-validated TDD rubric
@available(iOS 16.0, *)
final class UserWorkflowTrackerTests: XCTestCase {
    private var workflowTracker: UserWorkflowTracker?
    private var testUserId: String?

    override func setUpWithError() throws {
        // This will fail until UserWorkflowTracker is implemented
        workflowTracker = UserWorkflowTracker()
        testUserId = "test-user-" + UUID().uuidString
    }

    override func tearDownWithError() throws {
        // Clean up test data - async cleanup not supported in tearDown
        // Will be cleaned up in next test run
        workflowTracker = nil
        testUserId = nil
    }

    // MARK: - MoE Test: Privacy Compliance

    /// Test privacy compliance: 100% data encryption and zero data leakage
    /// This test WILL FAIL initially until privacy compliance is implemented
    func testPrivacyCompliance() async throws {
        guard let workflowTracker = workflowTracker,
              let testUserId = testUserId
        else {
            throw WorkflowTestError.serviceNotInitialized
        }

        let sensitiveWorkflowData = createSensitiveWorkflowData()

        // Store sensitive workflow data
        try await workflowTracker.recordWorkflowStep(
            userId: testUserId,
            workflowStep: sensitiveWorkflowData
        )

        // Validate encryption at rest
        let storedData = try await workflowTracker.getRawStoredData(userId: testUserId)

        // MoE Validation: 100% encryption compliance
        XCTAssertTrue(isDataEncrypted(storedData), "MoE: All stored data must be encrypted")
        XCTAssertFalse(containsPlaintextSensitiveData(storedData), "MoE: No plaintext sensitive data allowed")

        // Validate data isolation between users
        let otherUserId = "other-user-" + UUID().uuidString
        let otherUserData = try await workflowTracker.getRawStoredData(userId: otherUserId)

        XCTAssertFalse(dataContainsUserInfo(otherUserData, targetUserId: testUserId),
                       "MoE: User data isolation must be perfect (0% cross-contamination)")

        // Validate encryption key management
        let encryptionKeyAccess = try await workflowTracker.validateEncryptionKeyAccess(userId: testUserId)
        XCTAssertTrue(encryptionKeyAccess.isUserSpecific, "Encryption keys must be user-specific")
        XCTAssertTrue(encryptionKeyAccess.isSecurelyStored, "Encryption keys must be securely stored")
        XCTAssertFalse(encryptionKeyAccess.isAccessibleByOtherUsers, "Encryption keys must not be accessible by other users")
    }

    // MARK: - MoE Test: Data Encryption Effectiveness

    /// Test data encryption effectiveness: AES-256 with secure key management
    /// This test WILL FAIL initially until data encryption is implemented
    func testDataEncryptionEffectiveness() async throws {
        guard let workflowTracker = workflowTracker,
              let testUserId = testUserId
        else {
            throw WorkflowTestError.serviceNotInitialized
        }

        let plaintextWorkflow = createTestWorkflowData()

        // Store workflow data (should be encrypted automatically)
        try await workflowTracker.recordWorkflowStep(
            userId: testUserId,
            workflowStep: plaintextWorkflow
        )

        // Retrieve raw encrypted data
        let encryptedData = try await workflowTracker.getEncryptedWorkflowData(userId: testUserId)

        // MoE Validation: AES-256 encryption standard
        let encryptionInfo = try await workflowTracker.getEncryptionInfo(userId: testUserId)
        XCTAssertEqual(encryptionInfo.algorithm, .aes256, "Must use AES-256 encryption")
        XCTAssertGreaterThanOrEqual(encryptionInfo.keyLength, 256, "Key length must be >= 256 bits")

        // Validate encryption effectiveness
        let entropyScore = calculateDataEntropy(encryptedData)
        XCTAssertGreaterThan(entropyScore, 0.95, "MoE: Encrypted data entropy should be >95%")

        // Validate decryption integrity
        let decryptedWorkflow = try await workflowTracker.getWorkflowHistory(userId: testUserId)
        XCTAssertEqual(decryptedWorkflow.first?.documentType, plaintextWorkflow.documentType,
                       "Decrypted data should match original")
        XCTAssertEqual(decryptedWorkflow.first?.formFields.count, plaintextWorkflow.formFields.count,
                       "All workflow data should be preserved through encryption/decryption")

        // Validate key rotation capability
        try await workflowTracker.rotateEncryptionKey(userId: testUserId)
        let newEncryptionInfo = try await workflowTracker.getEncryptionInfo(userId: testUserId)
        XCTAssertNotEqual(encryptionInfo.keyId, newEncryptionInfo.keyId, "Key rotation should generate new key")

        // Verify data accessibility after key rotation
        let postRotationWorkflow = try await workflowTracker.getWorkflowHistory(userId: testUserId)
        XCTAssertFalse(postRotationWorkflow.isEmpty, "Data should remain accessible after key rotation")
    }

    // MARK: - MoE Test: Workflow Pattern Recognition

    /// Test workflow pattern recognition: >80% accuracy for pattern detection
    /// This test WILL FAIL initially until pattern recognition is implemented
    func testWorkflowPatternRecognition() async throws {
        guard let workflowTracker = workflowTracker,
              let testUserId = testUserId
        else {
            throw WorkflowTestError.serviceNotInitialized
        }

        // Generate diverse workflow sequences
        let workflowSequences = createDiverseWorkflowSequences(count: 50)

        // Record workflow sequences over time
        for sequence in workflowSequences {
            for step in sequence.steps {
                try await workflowTracker.recordWorkflowStep(
                    userId: testUserId,
                    workflowStep: step
                )

                // Simulate temporal spacing
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms between steps
            }
        }

        // Analyze pattern recognition results
        let patternAnalysis = try await workflowTracker.analyzeWorkflowPatterns(userId: testUserId)

        // MoE Validation: >80% pattern recognition accuracy
        XCTAssertGreaterThan(patternAnalysis.overallAccuracy, 0.80,
                             "MoE: Pattern recognition accuracy insufficient - expected >80%")

        // Validate pattern diversity detection
        XCTAssertGreaterThan(patternAnalysis.detectedPatterns.count, 5,
                             "Should detect multiple workflow patterns")

        // Validate pattern confidence scoring
        for pattern in patternAnalysis.detectedPatterns {
            XCTAssertTrue(pattern.confidence >= 0.0 && pattern.confidence <= 1.0,
                          "Pattern confidence should be between 0.0 and 1.0")

            if pattern.confidence > 0.8 {
                XCTAssertGreaterThan(pattern.supportingEvidence.count, 3,
                                     "High-confidence patterns should have multiple supporting evidence")
            }
        }

        // Validate temporal pattern recognition
        let temporalPatterns = patternAnalysis.temporalPatterns
        XCTAssertFalse(temporalPatterns.isEmpty, "Should detect temporal workflow patterns")

        let avgTemporalAccuracy = temporalPatterns.map(\.accuracy).reduce(0, +) / Float(temporalPatterns.count)
        XCTAssertGreaterThan(avgTemporalAccuracy, 0.75, "Temporal pattern accuracy should be >75%")
    }

    // MARK: - MoP Test: Real-Time Tracking Performance

    /// Test real-time tracking performance: <50ms latency for workflow recording
    /// This test WILL FAIL initially until real-time tracking optimization is implemented
    func testRealTimeTrackingPerformance() async throws {
        guard let workflowTracker = workflowTracker,
              let testUserId = testUserId
        else {
            throw WorkflowTestError.serviceNotInitialized
        }

        let workflowSteps = createRealTimeWorkflowSteps(count: 100)
        var recordingLatencies: [TimeInterval] = []

        for step in workflowSteps {
            let startTime = CFAbsoluteTimeGetCurrent()

            try await workflowTracker.recordWorkflowStep(
                userId: testUserId,
                workflowStep: step
            )

            let latency = CFAbsoluteTimeGetCurrent() - startTime
            recordingLatencies.append(latency)
        }

        let averageLatency = recordingLatencies.reduce(0, +) / Double(recordingLatencies.count)
        let maxLatency = recordingLatencies.max() ?? 0

        // MoP Validation: <50ms average latency for real-time tracking
        XCTAssertLessThan(averageLatency, 0.05, "Real-time tracking exceeded MoP target of 50ms average latency")
        XCTAssertLessThan(maxLatency, 0.1, "Maximum latency should not exceed 100ms")

        // MoE Validation: Latency consistency (95th percentile <75ms)
        let sortedLatencies = recordingLatencies.sorted()
        let p95Index = Int(Double(sortedLatencies.count) * 0.95)
        let p95Latency = sortedLatencies[p95Index]
        XCTAssertLessThan(p95Latency, 0.075, "MoE: 95th percentile latency should be <75ms")

        // Validate concurrent tracking performance
        let concurrentSteps = createRealTimeWorkflowSteps(count: 20)
        let concurrentStartTime = CFAbsoluteTimeGetCurrent()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for step in concurrentSteps {
                group.addTask { [workflowTracker = self.workflowTracker, testUserId = self.testUserId] in
                    guard let workflowTracker = workflowTracker,
                          let testUserId = testUserId
                    else {
                        throw WorkflowTestError.serviceNotInitialized
                    }
                    try await workflowTracker.recordWorkflowStep(
                        userId: testUserId,
                        workflowStep: step
                    )
                }
            }

            try await group.waitForAll()
        }

        let concurrentDuration = CFAbsoluteTimeGetCurrent() - concurrentStartTime
        XCTAssertLessThan(concurrentDuration, 1.0, "Concurrent tracking should complete within 1 second")
    }

    // MARK: - Test Helper Methods (WILL FAIL until implemented)

    private func createSensitiveWorkflowData() -> WorkflowStep {
        return WorkflowStep(
            stepId: UUID().uuidString,
            timestamp: Date(),
            documentType: "Classified Contract",
            formFields: [
                "contractNumber": "SECRET-2024-001",
                "vendor": "Secure Defense Corp",
                "clearanceLevel": "SECRET",
                "ssn": "123-45-6789",
                "personalData": "Sensitive information here"
            ],
            userActions: [
                UserAction(
                    actionType: "access_sensitive",
                    target: "classified_form",
                    timestamp: Date()
                ),
                UserAction(
                    actionType: "encrypt_submit",
                    target: "secure_submission",
                    timestamp: Date()
                )
            ]
        )
    }

    private func createTestWorkflowData() -> WorkflowStep {
        return WorkflowStep(
            stepId: UUID().uuidString,
            timestamp: Date(),
            documentType: "Contract Submission",
            formFields: [
                "contractNumber": "FAR-2024-001",
                "vendor": "Test Vendor Inc",
                "amount": "100000",
                "status": "pending"
            ],
            userActions: [
                UserAction(
                    actionType: "form_fill",
                    target: "contract_form",
                    timestamp: Date()
                ),
                UserAction(
                    actionType: "submit",
                    target: "contract_submission",
                    timestamp: Date()
                )
            ]
        )
    }

    private func isDataEncrypted(_ data: Data) -> Bool {
        // Simple heuristic: encrypted data should have high entropy and no recognizable patterns
        // Check for lack of common plaintext patterns
        let dataString = String(data: data, encoding: .utf8) ?? ""

        // If it can be converted to readable UTF-8, it's likely not encrypted
        if !dataString.isEmpty && dataString.contains(where: { $0.isLetter }) {
            return false
        }

        // Check entropy - encrypted data should have high entropy
        let entropy = calculateDataEntropy(data)
        return entropy > 0.9 // High entropy indicates encryption
    }

    private func containsPlaintextSensitiveData(_ data: Data) -> Bool {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return false // Can't decode as text, so no plaintext sensitive data
        }

        // Check for common sensitive data patterns in plaintext
        let sensitivePatterns = [
            "SECRET-",
            "ssn",
            "123-45-6789",
            "clearanceLevel",
            "personalData",
            "Sensitive information"
        ]

        let lowercaseData = dataString.lowercased()
        return sensitivePatterns.contains { pattern in
            lowercaseData.contains(pattern.lowercased())
        }
    }

    private func dataContainsUserInfo(_ data: Data, targetUserId: String) -> Bool {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return false
        }

        // Check if the data contains the target user ID
        return dataString.contains(targetUserId)
    }

    private func calculateDataEntropy(_ data: Data) -> Float {
        guard !data.isEmpty else { return 0.0 }

        // Calculate Shannon entropy
        var frequency: [UInt8: Int] = [:]

        // Count frequency of each byte
        for byte in data {
            frequency[byte, default: 0] += 1
        }

        let length = Float(data.count)
        var entropy: Float = 0.0

        // Calculate entropy using Shannon's formula
        for count in frequency.values {
            let probability = Float(count) / length
            if probability > 0 {
                entropy -= probability * log2(probability)
            }
        }

        // Normalize to 0-1 range (maximum entropy for 8-bit data is 8)
        return entropy / 8.0
    }

    private func createDiverseWorkflowSequences(count: Int) -> [WorkflowSequence] {
        var sequences: [WorkflowSequence] = []

        let documentTypes = ["Contract", "Invoice", "Report", "Proposal", "Amendment"]
        let patterns = ["Linear", "Branching", "Cyclical", "Hierarchical", "Random"]

        for i in 0..<count {
            let documentType = documentTypes[i % documentTypes.count]
            let pattern = patterns[i % patterns.count]

            let steps = createWorkflowStepsForSequence(
                sequenceIndex: i,
                documentType: documentType,
                stepCount: 3 + (i % 5) // 3-7 steps per sequence
            )

            let sequence = WorkflowSequence(
                sequenceId: "seq-\(i)",
                steps: steps,
                expectedPattern: pattern
            )

            sequences.append(sequence)
        }

        return sequences
    }

    private func createRealTimeWorkflowSteps(count: Int) -> [WorkflowStep] {
        var steps: [WorkflowStep] = []
        let actionTypes = ["form_fill", "submit", "review", "approve", "edit", "save"]
        let targets = ["contract_form", "invoice_form", "report_form", "submission_portal"]

        for i in 0..<count {
            let step = WorkflowStep(
                stepId: "rt-step-\(i)",
                timestamp: Date().addingTimeInterval(TimeInterval(i)),
                documentType: "RealTime Document \(i)",
                formFields: [
                    "fieldA": "value\(i)",
                    "fieldB": "data\(i % 10)",
                    "timestamp": "\(Date().timeIntervalSince1970)"
                ],
                userActions: [
                    UserAction(
                        actionType: actionTypes[i % actionTypes.count],
                        target: targets[i % targets.count],
                        timestamp: Date()
                    )
                ]
            )
            steps.append(step)
        }

        return steps
    }

    private func createWorkflowStepsForSequence(sequenceIndex: Int, documentType: String, stepCount: Int) -> [WorkflowStep] {
        var steps: [WorkflowStep] = []

        for stepIndex in 0..<stepCount {
            let step = WorkflowStep(
                stepId: "seq\(sequenceIndex)-step\(stepIndex)",
                timestamp: Date().addingTimeInterval(TimeInterval(stepIndex * 60)), // 1 minute apart
                documentType: documentType,
                formFields: [
                    "sequenceId": "\(sequenceIndex)",
                    "stepIndex": "\(stepIndex)",
                    "documentNumber": "\(documentType)-\(sequenceIndex)",
                    "status": stepIndex == stepCount - 1 ? "complete" : "in_progress"
                ],
                userActions: [
                    UserAction(
                        actionType: stepIndex == 0 ? "create" : (stepIndex == stepCount - 1 ? "finalize" : "process"),
                        target: "\(documentType.lowercased())_step\(stepIndex)",
                        timestamp: Date()
                    )
                ]
            )
            steps.append(step)
        }

        return steps
    }
}

// MARK: - Supporting Types (WILL FAIL until implemented)

// All types are defined in GraphRAGTypes.swift
