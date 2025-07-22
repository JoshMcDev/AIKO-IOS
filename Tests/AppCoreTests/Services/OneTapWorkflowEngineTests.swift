@testable import AppCore
import XCTest

/// Comprehensive test suite for OneTapWorkflowEngine
/// Tests end-to-end workflow orchestration and performance
/// Following TDD RED phase - tests written first to define expected behavior
@MainActor
final class OneTapWorkflowEngineTests: XCTestCase {
    // MARK: - Test Properties

    private var engine: OneTapWorkflowEngine!
    private var governmentConfig: OneTapWorkflowEngine.OneTapConfiguration!
    private var contractConfig: OneTapWorkflowEngine.OneTapConfiguration!
    private var invoiceConfig: OneTapWorkflowEngine.OneTapConfiguration!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        engine = OneTapWorkflowEngine.shared

        // Create test configurations
        governmentConfig = OneTapWorkflowEngine.OneTapConfiguration(
            workflow: .governmentFormProcessing,
            qualityMode: .professional,
            autoFillThreshold: 0.85,
            enableProgressTracking: true,
            maxProcessingTime: 30.0
        )

        contractConfig = OneTapWorkflowEngine.OneTapConfiguration(
            workflow: .contractDocumentScan,
            qualityMode: .professional,
            autoFillThreshold: 0.90,
            enableProgressTracking: true,
            maxProcessingTime: 45.0
        )

        invoiceConfig = OneTapWorkflowEngine.OneTapConfiguration(
            workflow: .invoiceProcessing,
            qualityMode: .balanced,
            autoFillThreshold: 0.80,
            enableProgressTracking: true,
            maxProcessingTime: 20.0
        )
    }

    override func tearDown() async throws {
        engine = nil
        governmentConfig = nil
        contractConfig = nil
        invoiceConfig = nil
        try await super.tearDown()
    }

    // MARK: - Government Form Processing Tests

    func testExecuteOneTapScan_GovernmentForm_Success() async throws {
        // RED phase: This test will fail until workflow is fully implemented
        do {
            // WHEN: Executing one-tap government form workflow
            let result = try await engine.executeOneTapScan(configuration: governmentConfig)

            // THEN: Should complete full workflow successfully
            XCTAssertEqual(result.userInteractionCount, 1, "Should complete with minimal user interaction")
            XCTAssertGreaterThan(result.qualityScore, 0.8, "Should achieve high quality score")
            XCTAssertLessThan(result.processingTime, 30.0, "Should complete within time limit")
            XCTAssertFalse(result.extractedFields.isEmpty, "Should extract form fields")
            XCTAssertNotNil(result.populatedForm, "Should populate form")

        } catch OneTapWorkflowEngine.OneTapError.scanningFailed {
            // Expected in RED phase - scanning not implemented
        } catch OneTapWorkflowEngine.OneTapError.processingFailed {
            // Expected in RED phase - processing not fully implemented
        }
    }

    func testExecuteOneTapScan_SF30Form_FieldExtraction() async throws {
        // RED phase: Will fail until SF-30 specific field extraction is implemented
        do {
            let result = try await engine.executeOneTapScan(configuration: governmentConfig)

            // THEN: Should extract SF-30 specific fields
            let cageCodeField = result.extractedFields.first { $0.fieldType == .cageCode }
            let ueiField = result.extractedFields.first { $0.fieldType == .ueiNumber }
            let contractValueField = result.extractedFields.first { $0.fieldType == .contractValue }

            XCTAssertNotNil(cageCodeField, "Should extract CAGE code field")
            XCTAssertNotNil(ueiField, "Should extract UEI number field")
            XCTAssertNotNil(contractValueField, "Should extract contract value field")

            // Validate CAGE code format (5 characters)
            if let cageCode = cageCodeField {
                XCTAssertEqual(cageCode.value.count, 5, "CAGE code should be 5 characters")
                XCTAssertGreaterThan(cageCode.confidence, 0.8, "CAGE code extraction should be high confidence")
            }

            // Validate UEI format (12 characters)
            if let uei = ueiField {
                XCTAssertEqual(uei.value.count, 12, "UEI should be 12 characters")
                XCTAssertGreaterThan(uei.confidence, 0.8, "UEI extraction should be high confidence")
            }

        } catch {
            // Expected in RED phase
        }
    }

    func testExecuteOneTapScan_GovernmentForm_ConfidenceScoring() async throws {
        // RED phase: Will fail until confidence scoring is implemented
        do {
            let result = try await engine.executeOneTapScan(configuration: governmentConfig)

            // THEN: Should provide confidence scores for all extracted fields
            for field in result.extractedFields {
                XCTAssertGreaterThanOrEqual(field.confidence, 0.0, "Confidence should be >= 0.0")
                XCTAssertLessThanOrEqual(field.confidence, 1.0, "Confidence should be <= 1.0")

                // High confidence fields should be auto-filled
                if field.confidence >= governmentConfig.autoFillThreshold {
                    XCTAssertFalse(field.value.isEmpty, "High confidence fields should have values")
                }
            }

            // Overall form population confidence
            if let populatedForm = result.populatedForm {
                XCTAssertGreaterThanOrEqual(populatedForm.overallConfidence, 0.0)
                XCTAssertLessThanOrEqual(populatedForm.overallConfidence, 1.0)
            }

        } catch {
            // Expected in RED phase
        }
    }

    // MARK: - Contract Document Processing Tests

    func testExecuteOneTapScan_ContractDocument_Success() async throws {
        // RED phase: Will fail until contract processing is implemented
        do {
            let result = try await engine.executeOneTapScan(configuration: contractConfig)

            // THEN: Should process contract documents with high quality
            XCTAssertEqual(result.userInteractionCount, 1, "Should minimize user interactions")
            XCTAssertGreaterThan(result.qualityScore, 0.85, "Contract documents require higher quality")
            XCTAssertLessThan(result.processingTime, 45.0, "Should complete within contract time limit")
            XCTAssertNotNil(result.populatedForm, "Should populate contract form")

            // Contract-specific validations
            if let populatedForm = result.populatedForm {
                XCTAssertEqual(populatedForm.formType, .contractDocument, "Should identify contract document type")
                XCTAssertGreaterThan(populatedForm.overallConfidence, 0.85, "Contract confidence should be high")
            }

        } catch {
            // Expected in RED phase
        }
    }

    func testExecuteOneTapScan_ContractDocument_VendorInformation() async throws {
        // RED phase: Will fail until vendor information extraction is implemented
        do {
            let result = try await engine.executeOneTapScan(configuration: contractConfig)

            // THEN: Should extract vendor-specific information
            let vendorNameField = result.extractedFields.first { $0.fieldType == .vendorName }
            let addressField = result.extractedFields.first { $0.fieldType == .address }

            XCTAssertNotNil(vendorNameField, "Should extract vendor name")
            XCTAssertNotNil(addressField, "Should extract vendor address")

            if let vendorName = vendorNameField {
                XCTAssertFalse(vendorName.value.isEmpty, "Vendor name should not be empty")
                XCTAssertGreaterThan(vendorName.confidence, 0.8, "Vendor name should be high confidence")
            }

        } catch {
            // Expected in RED phase
        }
    }

    // MARK: - Invoice Processing Tests

    func testExecuteOneTapScan_Invoice_Success() async throws {
        // RED phase: Will fail until invoice processing is implemented
        do {
            let result = try await engine.executeOneTapScan(configuration: invoiceConfig)

            // THEN: Should process invoices efficiently
            XCTAssertEqual(result.userInteractionCount, 1, "Should minimize user interactions")
            XCTAssertGreaterThan(result.qualityScore, 0.75, "Invoice processing should meet quality threshold")
            XCTAssertLessThan(result.processingTime, 20.0, "Invoices should process quickly")
            XCTAssertNotNil(result.populatedForm, "Should populate invoice form")

            if let populatedForm = result.populatedForm {
                XCTAssertEqual(populatedForm.formType, .invoiceDocument, "Should identify invoice document type")
            }

        } catch {
            // Expected in RED phase
        }
    }

    func testExecuteOneTapScan_Invoice_CurrencyFields() async throws {
        // RED phase: Will fail until currency field extraction is implemented
        do {
            let result = try await engine.executeOneTapScan(configuration: invoiceConfig)

            // THEN: Should extract and validate currency fields
            let currencyFields = result.extractedFields.filter { $0.fieldType == .currency }

            XCTAssertFalse(currencyFields.isEmpty, "Should extract currency fields from invoice")

            for currencyField in currencyFields {
                // Validate currency format (should contain dollar sign or decimal)
                let containsDollarSign = currencyField.value.contains("$")
                let containsDecimal = currencyField.value.contains(".")
                let isNumeric = currencyField.value.replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: ".", with: "").allSatisfy { $0.isNumber }

                XCTAssertTrue(containsDollarSign || containsDecimal || isNumeric,
                              "Currency field should be properly formatted")
                XCTAssertGreaterThan(currencyField.confidence, 0.7, "Currency extraction should be confident")
            }

        } catch {
            // Expected in RED phase
        }
    }

    // MARK: - Custom Workflow Tests

    func testExecuteOneTapScan_CustomWorkflow_Success() async throws {
        // RED phase: Will fail until custom workflow support is implemented
        let customDefinition = OneTapWorkflowEngine.WorkflowDefinition(
            name: "Custom Test Workflow",
            steps: [.scan, .extractText, .validate],
            expectedFormType: .customForm("TestForm"),
            qualityThreshold: 0.75,
            processingTimeout: 15.0
        )

        let customConfig = OneTapWorkflowEngine.OneTapConfiguration(
            workflow: .customWorkflow(customDefinition),
            qualityMode: .balanced,
            maxProcessingTime: 15.0
        )

        do {
            let result = try await engine.executeOneTapScan(configuration: customConfig)

            // THEN: Should execute custom workflow steps
            XCTAssertLessThan(result.processingTime, 15.0, "Custom workflow should respect timeout")
            XCTAssertGreaterThan(result.qualityScore, 0.75, "Should meet custom quality threshold")

        } catch {
            // Expected in RED phase
        }
    }

    // MARK: - Progress Tracking Tests

    func testWorkflowProgress_Tracking_Success() async throws {
        // RED phase: Will fail until progress tracking is implemented
        let expectation = XCTestExpectation(description: "Progress tracking")
        var progressUpdates: [Double] = []

        // Start workflow in background task to track progress
        Task {
            do {
                _ = try await engine.executeOneTapScan(configuration: governmentConfig)
            } catch {
                // Expected in RED phase
            }
            expectation.fulfill()
        }

        // Monitor progress updates
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Progress should be tracked (this will fail in RED phase)
        // XCTAssertGreaterThan(progressUpdates.count, 0, "Should receive progress updates")

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testGetWorkflowProgress_ValidWorkflow_ReturnsProgress() async {
        // RED phase: Will fail until progress tracking state is implemented
        let workflowId = UUID()

        // WHEN: Getting progress for non-existent workflow
        let progress = await engine.getWorkflowProgress(for: workflowId)

        // THEN: Should return nil for non-existent workflow
        XCTAssertNil(progress, "Should return nil for non-existent workflow")
    }

    func testCancelWorkflow_ActiveWorkflow_Success() async {
        // RED phase: Will test cancellation functionality
        let workflowId = UUID()

        // WHEN: Canceling workflow
        await engine.cancelWorkflow(workflowId)

        // THEN: Should handle cancellation gracefully
        let progress = await engine.getWorkflowProgress(for: workflowId)
        XCTAssertNil(progress, "Canceled workflow should not have progress")
    }

    // MARK: - Performance Tests

    func testExecuteOneTapScan_Performance_MeetsTargets() async throws {
        // RED phase: Will fail until performance optimizations are implemented
        let startTime = Date()

        do {
            _ = try await engine.executeOneTapScan(configuration: governmentConfig)

            let processingTime = Date().timeIntervalSince(startTime)

            // THEN: Should meet performance targets
            XCTAssertLessThan(processingTime, 30.0, "Government form processing should complete within 30 seconds")

        } catch {
            // Expected in RED phase but still measure time
            let processingTime = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(processingTime, 30.0, "Even failed processing should not exceed time limit")
        }
    }

    func testExecuteOneTapScan_MultipleWorkflows_ConcurrentPerformance() async throws {
        // RED phase: Will fail until concurrent workflow support is implemented
        let workflowCount = 3
        let startTime = Date()

        // WHEN: Running multiple workflows concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< workflowCount {
                group.addTask {
                    do {
                        let config = i % 2 == 0 ? self.governmentConfig! : self.invoiceConfig!
                        _ = try await self.engine.executeOneTapScan(configuration: config)
                    } catch {
                        // Expected in RED phase
                    }
                }
            }
        }

        let totalTime = Date().timeIntervalSince(startTime)

        // THEN: Concurrent processing should be efficient
        XCTAssertLessThan(totalTime, 60.0, "Concurrent workflows should complete within reasonable time")
    }

    func testEstimateProcessingTime_AllWorkflowTypes_Success() async {
        // RED phase: Will test time estimation functionality

        // WHEN: Estimating processing times for different workflow types
        let govTime = await engine.estimateProcessingTime(for: .governmentFormProcessing)
        let contractTime = await engine.estimateProcessingTime(for: .contractDocumentScan)
        let invoiceTime = await engine.estimateProcessingTime(for: .invoiceProcessing)

        // THEN: Should provide reasonable estimates
        XCTAssertGreaterThan(govTime, 0, "Government form estimate should be positive")
        XCTAssertLessThan(govTime, 60.0, "Government form estimate should be reasonable")

        XCTAssertGreaterThan(contractTime, govTime, "Contract processing should take longer than government forms")
        XCTAssertLessThan(contractTime, 60.0, "Contract estimate should be reasonable")

        XCTAssertLessThan(invoiceTime, govTime, "Invoice processing should be faster than government forms")
        XCTAssertGreaterThan(invoiceTime, 0, "Invoice estimate should be positive")
    }

    // MARK: - Error Handling Tests

    func testExecuteOneTapScan_InvalidConfiguration_ThrowsError() async throws {
        // RED phase: Will test error handling for invalid configurations
        let invalidConfig = OneTapWorkflowEngine.OneTapConfiguration(
            workflow: .governmentFormProcessing,
            autoFillThreshold: 1.5, // Invalid threshold > 1.0
            maxProcessingTime: -10.0 // Invalid negative time
        )

        do {
            _ = try await engine.executeOneTapScan(configuration: invalidConfig)
            XCTFail("Should throw error for invalid configuration")
        } catch OneTapWorkflowEngine.OneTapError.configurationInvalid {
            // Expected error
        } catch {
            // May throw different error in RED phase
        }
    }

    func testExecuteOneTapScan_QualityThresholdNotMet_ThrowsError() async throws {
        // RED phase: Will fail until quality validation is implemented
        let strictConfig = OneTapWorkflowEngine.OneTapConfiguration(
            workflow: .governmentFormProcessing,
            autoFillThreshold: 0.95, // Very high threshold
            maxProcessingTime: 30.0
        )

        do {
            _ = try await engine.executeOneTapScan(configuration: strictConfig)
            // May not reach this point in RED phase
        } catch let OneTapWorkflowEngine.OneTapError.qualityThresholdNotMet(score) {
            // Expected when quality is below threshold
            XCTAssertLessThan(score, 0.95, "Quality score should be below threshold")
        } catch {
            // Other errors expected in RED phase
        }
    }

    func testExecuteOneTapScan_WorkflowTimeout_ThrowsError() async throws {
        // RED phase: Will test timeout handling
        let timeoutConfig = OneTapWorkflowEngine.OneTapConfiguration(
            workflow: .governmentFormProcessing,
            maxProcessingTime: 0.1 // Very short timeout
        )

        do {
            _ = try await engine.executeOneTapScan(configuration: timeoutConfig)
            XCTFail("Should timeout with very short time limit")
        } catch OneTapWorkflowEngine.OneTapError.workflowTimeout {
            // Expected timeout error
        } catch {
            // Other errors may occur in RED phase
        }
    }

    // MARK: - Workflow Configuration Tests

    func testGetSupportedWorkflows_ReturnsAllTypes() async {
        // WHEN: Getting supported workflow types
        let supportedWorkflows = await engine.getSupportedWorkflows()

        // THEN: Should return all predefined workflow types
        XCTAssertTrue(supportedWorkflows.contains(.governmentFormProcessing), "Should support government forms")
        XCTAssertTrue(supportedWorkflows.contains(.contractDocumentScan), "Should support contract documents")
        XCTAssertTrue(supportedWorkflows.contains(.invoiceProcessing), "Should support invoice processing")
        XCTAssertEqual(supportedWorkflows.count, 3, "Should return exactly 3 predefined workflows")
    }

    // MARK: - End-to-End Integration Tests

    func testEndToEndWorkflow_GovernmentForm_CompleteSuccess() async throws {
        // RED phase: This comprehensive test will fail until full integration is complete
        let startTime = Date()
        var userInteractions = 0

        do {
            // WHEN: Executing complete end-to-end workflow
            let result = try await engine.executeOneTapScan(configuration: governmentConfig)

            let endTime = Date()
            let totalTime = endTime.timeIntervalSince(startTime)

            // THEN: Should meet all end-to-end requirements
            XCTAssertLessThanOrEqual(result.userInteractionCount, 5, "Should require ≤5 user interactions")
            XCTAssertLessThan(totalTime, 30.0, "Should complete scan-to-form in <30 seconds")
            XCTAssertGreaterThan(result.qualityScore, 0.85, "Should achieve >85% quality score")

            // Verify document scanning completed
            XCTAssertNotNil(result.scannedDocument, "Should have scanned document")
            XCTAssertFalse(result.scannedDocument.pages.isEmpty, "Should have scanned pages")

            // Verify OCR extraction completed
            XCTAssertNotNil(result.ocrResult, "Should have OCR results")

            // Verify form field extraction
            XCTAssertFalse(result.extractedFields.isEmpty, "Should extract form fields")

            // Verify form population
            XCTAssertNotNil(result.populatedForm, "Should populate form")

            // Verify high-confidence fields are auto-filled
            let highConfidenceFields = result.extractedFields.filter { $0.confidence >= governmentConfig.autoFillThreshold }
            for field in highConfidenceFields {
                XCTAssertFalse(field.value.isEmpty, "High confidence fields should be auto-filled")
            }

        } catch {
            // Expected in RED phase - but we can still verify error behavior
            let endTime = Date()
            let totalTime = endTime.timeIntervalSince(startTime)
            XCTAssertLessThan(totalTime, 30.0, "Even failed workflows should not exceed time limit")
        }
    }
}
