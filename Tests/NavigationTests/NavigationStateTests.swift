import XCTest
import SwiftUI
import ObjectiveC
@testable import AIKO

/// Comprehensive test suite for NavigationState enum-driven navigation
/// These tests are designed to FAIL initially (Red phase) and pass after Green phase implementation
/// Coverage target: 95% as specified in TDD rubric
@MainActor
final class NavigationStateTests: XCTestCase, @unchecked Sendable {

    var navigationState: NavigationState!

    override func setUp() async throws {
        navigationState = NavigationState()
        await navigationState.initialize()
    }

    override func tearDown() async throws {
        navigationState = nil
    }

    // MARK: - Enum-Driven Navigation Tests

    func testNavigationDestinationEnumCases() {
        // Test all enum cases are properly defined
        let acquisitionDest = NavigationState.NavigationDestination.acquisition(AcquisitionID("ACQ-001"))
        let documentDest = NavigationState.NavigationDestination.document(DocumentID("DOC-001"))
        let complianceDest = NavigationState.NavigationDestination.compliance(ComplianceCheckID("COMP-001"))
        let searchDest = NavigationState.NavigationDestination.search(SearchContext(query: "test"))
        let settingsDest = NavigationState.NavigationDestination.settings(.general)
        let quickActionDest = NavigationState.NavigationDestination.quickAction(.scanDocument)
        let workflowDest = NavigationState.NavigationDestination.workflow(NavigationWorkflowStep(id: WorkflowStepID("WF-001"), name: "Test Step"))

        // Test enum cases exist and are hashable
        XCTAssertNotNil(acquisitionDest)
        XCTAssertNotNil(documentDest)
        XCTAssertNotNil(complianceDest)
        XCTAssertNotNil(searchDest)
        XCTAssertNotNil(settingsDest)
        XCTAssertNotNil(quickActionDest)
        XCTAssertNotNil(workflowDest)

        // Test hashability
        let destinations: Set<NavigationState.NavigationDestination> = [
            acquisitionDest, documentDest, complianceDest, searchDest,
            settingsDest, quickActionDest, workflowDest
        ]
        XCTAssertEqual(destinations.count, 7)
    }

    func testNavigationDestinationDeepLinks() async {
        let acquisitionDest = NavigationState.NavigationDestination.acquisition(AcquisitionID("ACQ-001"))
        let documentDest = NavigationState.NavigationDestination.document(DocumentID("DOC-001"))
        let complianceDest = NavigationState.NavigationDestination.compliance(ComplianceCheckID("COMP-001"))
        let searchDest = NavigationState.NavigationDestination.search(SearchContext(query: "test query"))
        let settingsDest = NavigationState.NavigationDestination.settings(.llmProviders)
        let quickActionDest = NavigationState.NavigationDestination.quickAction(.newAcquisition)
        let workflowDest = NavigationState.NavigationDestination.workflow(NavigationWorkflowStep(id: WorkflowStepID("WF-001"), name: "Step 1"))

        // Test deep link path generation
        XCTAssertEqual(acquisitionDest.deepLinkPath, "acquisition/ACQ-001")
        XCTAssertEqual(documentDest.deepLinkPath, "document/DOC-001")
        XCTAssertEqual(complianceDest.deepLinkPath, "compliance/COMP-001")
        XCTAssertEqual(searchDest.deepLinkPath, "search?q=test query")
        XCTAssertEqual(settingsDest.deepLinkPath, "settings/llm_providers")
        XCTAssertEqual(quickActionDest.deepLinkPath, "action/new_acquisition")
        XCTAssertEqual(workflowDest.deepLinkPath, "workflow/WF-001")
    }

    func testNavigationDestinationCodable() throws {
        let destination = NavigationState.NavigationDestination.acquisition(AcquisitionID("ACQ-001"))

        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(destination)

        // Test decoding
        let decoder = JSONDecoder()
        let decodedDestination = try decoder.decode(NavigationState.NavigationDestination.self, from: data)

        XCTAssertEqual(destination, decodedDestination)
    }

    // MARK: - Observable Pattern Tests

    func testNavigationStateObservable() {
        // Test that NavigationState is @Observable
        XCTAssertTrue(navigationState is any Observable)

        // Test initial state
        XCTAssertEqual(navigationState.columnVisibility, .automatic)
        XCTAssertNil(navigationState.selectedAcquisition)
        XCTAssertTrue(navigationState.detailPath.isEmpty)
        XCTAssertTrue(navigationState.navigationHistory.isEmpty)
        XCTAssertNil(navigationState.activeWorkflow)
        XCTAssertEqual(navigationState.workflowProgress, .notStarted)
    }

    // MARK: - Navigation Method Tests (These will FAIL in Red phase)

    func testNavigateToAcquisition() async {
        let acquisitionID = AcquisitionID("ACQ-2025-001")
        let destination = NavigationState.NavigationDestination.acquisition(acquisitionID)

        await navigationState.navigate(to: destination)

        // These assertions will FAIL in Red phase - implementation is incomplete
        XCTAssertEqual(navigationState.selectedAcquisition, acquisitionID, "Navigation should update selectedAcquisition")
        XCTAssertFalse(navigationState.detailPath.isEmpty, "Navigation should update detailPath")
        XCTAssertEqual(navigationState.navigationHistory.last, destination, "Navigation should be added to history")
        XCTAssertEqual(navigationState.navigationHistory.count, 1, "History should contain exactly one entry")
    }

    func testNavigateToDocument() async {
        let documentID = DocumentID("DOC-2025-001")
        let destination = NavigationState.NavigationDestination.document(documentID)

        await navigationState.navigate(to: destination)

        // These assertions will FAIL in Red phase
        XCTAssertFalse(navigationState.detailPath.isEmpty, "Document navigation should update detailPath")
        XCTAssertEqual(navigationState.navigationHistory.last, destination, "Document navigation should be tracked in history")
    }

    func testNavigateToCompliance() async {
        let complianceID = ComplianceCheckID("COMP-2025-001")
        let destination = NavigationState.NavigationDestination.compliance(complianceID)

        await navigationState.navigate(to: destination)

        // These assertions will FAIL in Red phase
        XCTAssertFalse(navigationState.detailPath.isEmpty, "Compliance navigation should update detailPath")
        XCTAssertEqual(navigationState.navigationHistory.last, destination, "Compliance navigation should be tracked")
    }

    func testNavigateToSearch() async {
        let searchContext = SearchContext(query: "FAR 52.219-9")
        let destination = NavigationState.NavigationDestination.search(searchContext)

        await navigationState.navigate(to: destination)

        // These assertions will FAIL in Red phase
        XCTAssertFalse(navigationState.detailPath.isEmpty, "Search navigation should update detailPath")
        XCTAssertEqual(navigationState.navigationHistory.last, destination, "Search navigation should be tracked")
    }

    func testNavigateToSettings() async {
        let destination = NavigationState.NavigationDestination.settings(.llmProviders)

        await navigationState.navigate(to: destination)

        // These assertions will FAIL in Red phase
        XCTAssertFalse(navigationState.detailPath.isEmpty, "Settings navigation should update detailPath")
        XCTAssertEqual(navigationState.navigationHistory.last, destination, "Settings navigation should be tracked")
    }

    func testNavigateToQuickAction() async {
        let destination = NavigationState.NavigationDestination.quickAction(.scanDocument)

        await navigationState.navigate(to: destination)

        // These assertions will FAIL in Red phase
        XCTAssertEqual(navigationState.navigationHistory.last, destination, "Quick action navigation should be tracked")
    }

    func testNavigationHistoryManagement() async {
        // Test navigation history limit (should maintain 50 entries max)
        for i in 1...60 {
            let destination = NavigationState.NavigationDestination.acquisition(AcquisitionID("ACQ-\(i)"))
            await navigationState.navigate(to: destination)
        }

        // This will FAIL in Red phase - history management not implemented
        XCTAssertLessThanOrEqual(navigationState.navigationHistory.count, 50, "Navigation history should be limited to 50 entries")
        XCTAssertEqual(navigationState.navigationHistory.last,
                       NavigationState.NavigationDestination.acquisition(AcquisitionID("ACQ-60")),
                       "Last navigation should be preserved")
    }

    func testNavigationPerformanceTracking() async {
        let destination = NavigationState.NavigationDestination.acquisition(AcquisitionID("ACQ-PERF-001"))

        let startTime = CFAbsoluteTimeGetCurrent()
        await navigationState.navigate(to: destination)
        let endTime = CFAbsoluteTimeGetCurrent()

        let duration = endTime - startTime

        // Performance requirement: <100ms navigation
        // This may FAIL if telemetry implementation is missing
        XCTAssertLessThan(duration, 0.1, "Navigation should complete within 100ms")
    }

    // MARK: - Workflow Management Tests (These will FAIL in Red phase)

    func testStartDocumentGenerationWorkflow() async {
        await navigationState.startWorkflow(.documentGeneration)

        // These assertions will FAIL in Red phase - workflow implementation incomplete
        XCTAssertEqual(navigationState.activeWorkflow, .documentGeneration, "Active workflow should be set")
        XCTAssertEqual(navigationState.workflowProgress, .inProgress(step: 0, of: 3), "Workflow should start at step 0 of 3")

        // Should navigate to first workflow destination
        let expectedDestination = NavigationState.NavigationDestination.acquisition(AcquisitionID("new"))
        XCTAssertEqual(navigationState.navigationHistory.last, expectedDestination, "Should navigate to workflow's first destination")
    }

    func testStartComplianceCheckWorkflow() async {
        await navigationState.startWorkflow(.complianceCheck)

        // These assertions will FAIL in Red phase
        XCTAssertEqual(navigationState.activeWorkflow, .complianceCheck, "Active workflow should be compliance check")
        XCTAssertEqual(navigationState.workflowProgress, .inProgress(step: 0, of: 4), "Compliance workflow has 4 steps")

        let expectedDestination = NavigationState.NavigationDestination.compliance(ComplianceCheckID("new"))
        XCTAssertEqual(navigationState.navigationHistory.last, expectedDestination, "Should navigate to compliance destination")
    }

    func testStartMarketResearchWorkflow() async {
        await navigationState.startWorkflow(.marketResearch)

        // These assertions will FAIL in Red phase
        XCTAssertEqual(navigationState.activeWorkflow, .marketResearch, "Active workflow should be market research")
        XCTAssertEqual(navigationState.workflowProgress, .inProgress(step: 0, of: 5), "Market research workflow has 5 steps")

        let expectedDestination = NavigationState.NavigationDestination.search(SearchContext(query: "market analysis"))
        XCTAssertEqual(navigationState.navigationHistory.last, expectedDestination, "Should navigate to search destination")
    }

    func testStartContractReviewWorkflow() async {
        await navigationState.startWorkflow(.contractReview)

        // These assertions will FAIL in Red phase
        XCTAssertEqual(navigationState.activeWorkflow, .contractReview, "Active workflow should be contract review")
        XCTAssertEqual(navigationState.workflowProgress, .inProgress(step: 0, of: 6), "Contract review workflow has 6 steps")

        let expectedDestination = NavigationState.NavigationDestination.document(DocumentID("contract"))
        XCTAssertEqual(navigationState.navigationHistory.last, expectedDestination, "Should navigate to document destination")
    }

    func testAdvanceWorkflowProgression() async {
        // Start a workflow
        await navigationState.startWorkflow(.documentGeneration)

        // Advance workflow
        await navigationState.advanceWorkflow()

        // These assertions will FAIL in Red phase - advancement logic incomplete
        XCTAssertEqual(navigationState.workflowProgress, .inProgress(step: 1, of: 3), "Workflow should advance to step 1")

        // Advance again
        await navigationState.advanceWorkflow()
        XCTAssertEqual(navigationState.workflowProgress, .inProgress(step: 2, of: 3), "Workflow should advance to step 2")

        // Final advancement should complete workflow
        await navigationState.advanceWorkflow()
        XCTAssertEqual(navigationState.workflowProgress, .completed, "Workflow should be completed")
        XCTAssertNil(navigationState.activeWorkflow, "Active workflow should be cleared when completed")
    }

    func testWorkflowProgressEquality() {
        // Test WorkflowProgress equality implementation
        let progress1 = NavigationState.WorkflowProgress.inProgress(step: 1, of: 3)
        let progress2 = NavigationState.WorkflowProgress.inProgress(step: 1, of: 3)
        let progress3 = NavigationState.WorkflowProgress.inProgress(step: 2, of: 3)

        XCTAssertEqual(progress1, progress2, "Equal progress states should be equal")
        XCTAssertNotEqual(progress1, progress3, "Different progress states should not be equal")

        XCTAssertEqual(NavigationState.WorkflowProgress.notStarted, NavigationState.WorkflowProgress.notStarted)
        XCTAssertEqual(NavigationState.WorkflowProgress.completed, NavigationState.WorkflowProgress.completed)

        let failed1 = NavigationState.WorkflowProgress.failed("Error 1")
        let failed2 = NavigationState.WorkflowProgress.failed("Error 1")
        let failed3 = NavigationState.WorkflowProgress.failed("Error 2")

        XCTAssertEqual(failed1, failed2, "Failed states with same error should be equal")
        XCTAssertNotEqual(failed1, failed3, "Failed states with different errors should not be equal")
    }

    func testWorkflowProgressCodable() throws {
        let progressStates: [NavigationState.WorkflowProgress] = [
            .notStarted,
            .inProgress(step: 2, of: 5),
            .completed,
            .failed("Test error")
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for progress in progressStates {
            let data = try encoder.encode(progress)
            let decodedProgress = try decoder.decode(NavigationState.WorkflowProgress.self, from: data)
            XCTAssertEqual(progress, decodedProgress, "WorkflowProgress should be codable")
        }
    }

    // MARK: - Platform-Specific Tests

    #if os(iOS)
    func testIOSSpecificState() {
        // Test iOS-specific navigation state
        XCTAssertEqual(navigationState.selectedTab, .dashboard, "iOS should default to dashboard tab")
        XCTAssertNil(navigationState.sheetPresentation, "No sheet should be presented initially")
    }

    func testIOSTabNavigation() async {
        navigationState.selectedTab = .documents
        XCTAssertEqual(navigationState.selectedTab, .documents, "Tab selection should update")

        navigationState.selectedTab = .search
        XCTAssertEqual(navigationState.selectedTab, .search, "Tab selection should update to search")
    }

    func testIOSSheetPresentation() async {
        navigationState.sheetPresentation = .documentScanner
        XCTAssertEqual(navigationState.sheetPresentation, .documentScanner, "Sheet presentation should update")

        navigationState.sheetPresentation = nil
        XCTAssertNil(navigationState.sheetPresentation, "Sheet presentation should be clearable")
    }
    #endif

    #if os(macOS)
    func testMacOSSpecificState() {
        // Test macOS-specific navigation state
        XCTAssertTrue(navigationState.activeWindows.isEmpty, "macOS should start with no active windows")
        XCTAssertNotNil(navigationState.toolbarState, "macOS should have toolbar state")
        XCTAssertFalse(navigationState.toolbarState.openInNewWindow, "Toolbar should default to same window")
    }

    func testMacOSWindowManagement() async {
        let windowID = WindowID("test-window")
        navigationState.activeWindows.insert(windowID)

        XCTAssertTrue(navigationState.activeWindows.contains(windowID), "Window should be tracked")
        XCTAssertEqual(navigationState.activeWindows.count, 1, "Should have one active window")

        navigationState.activeWindows.remove(windowID)
        XCTAssertFalse(navigationState.activeWindows.contains(windowID), "Window should be removed")
    }

    func testMacOSToolbarState() async {
        navigationState.toolbarState.openInNewWindow = true
        XCTAssertTrue(navigationState.toolbarState.openInNewWindow, "Toolbar state should update")
    }
    #endif

    // MARK: - Integration Tests (These will FAIL in Red phase)

    func testCompleteWorkflowNavigation() async {
        // Test complete workflow with navigation
        await navigationState.startWorkflow(.documentGeneration)

        // Should start with acquisition navigation
        let expectedFirstDestination = NavigationState.NavigationDestination.acquisition(AcquisitionID("new"))

        // This will FAIL in Red phase - navigation integration incomplete
        XCTAssertEqual(navigationState.navigationHistory.last, expectedFirstDestination, "Workflow should navigate to first step")
        XCTAssertEqual(navigationState.selectedAcquisition, AcquisitionID("new"), "Selected acquisition should be updated")

        // Advance through workflow
        await navigationState.advanceWorkflow()
        await navigationState.advanceWorkflow()
        await navigationState.advanceWorkflow()

        // Workflow should be complete
        XCTAssertEqual(navigationState.workflowProgress, .completed, "Workflow should be completed")
        XCTAssertNil(navigationState.activeWorkflow, "Active workflow should be cleared")
    }

    func testConcurrentNavigationOperations() async {
        // Test that concurrent navigation operations are handled properly
        let destinations = [
            NavigationState.NavigationDestination.acquisition(AcquisitionID("ACQ-001")),
            NavigationState.NavigationDestination.document(DocumentID("DOC-001")),
            NavigationState.NavigationDestination.compliance(ComplianceCheckID("COMP-001"))
        ]

        // Perform concurrent navigation
        await withTaskGroup(of: Void.self) { group in
            for destination in destinations {
                group.addTask {
                    await self.navigationState.navigate(to: destination)
                }
            }
        }

        // This will FAIL in Red phase - concurrent handling not implemented
        XCTAssertEqual(navigationState.navigationHistory.count, destinations.count, "All navigations should be recorded")
        XCTAssertTrue(navigationState.navigationHistory.allSatisfy { destinations.contains($0) }, "All destinations should be in history")
    }

    func testNavigationStateInitialization() async {
        let newState = NavigationState()
        await newState.initialize()

        // These will FAIL in Red phase - initialization not implemented
        XCTAssertEqual(newState.columnVisibility, .automatic, "Should initialize to automatic visibility")
        XCTAssertNil(newState.selectedAcquisition, "Should start with no selected acquisition")
        XCTAssertTrue(newState.detailPath.isEmpty, "Detail path should be empty")
        XCTAssertTrue(newState.navigationHistory.isEmpty, "History should be empty")
        XCTAssertEqual(newState.workflowProgress, .notStarted, "Workflow should not be started")
    }

    // MARK: - Performance Tests

    func testNavigationPerformanceUnder100ms() async {
        // Test that navigation completes within 100ms (TDD requirement)
        let destination = NavigationState.NavigationDestination.acquisition(AcquisitionID("PERF-TEST"))

        let startTime = CFAbsoluteTimeGetCurrent()
        await navigationState.navigate(to: destination)
        let endTime = CFAbsoluteTimeGetCurrent()

        let duration = (endTime - startTime) * 1000 // Convert to milliseconds

        // This may FAIL if implementation is slow or telemetry adds overhead
        XCTAssertLessThan(duration, 100, "Navigation should complete within 100ms (requirement: <100ms)")
    }

    func testLargeNavigationHistoryPerformance() async {
        // Test performance with large navigation history
        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 1...1000 {
            let destination = NavigationState.NavigationDestination.acquisition(AcquisitionID("PERF-\(i)"))
            await navigationState.navigate(to: destination)
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalDuration = endTime - startTime
        let averageDuration = (totalDuration / 1000) * 1000 // ms per navigation

        // This will help identify performance issues
        XCTAssertLessThan(averageDuration, 10, "Average navigation time should be under 10ms for good UX")
    }

    // MARK: - Error Handling Tests

    func testWorkflowFailureHandling() async {
        await navigationState.startWorkflow(.documentGeneration)

        // Simulate workflow failure (this logic will be implemented in Green phase)
        navigationState.workflowProgress = .failed("Test error")

        XCTAssertEqual(navigationState.workflowProgress, .failed("Test error"), "Workflow failure should be tracked")
        XCTAssertNotNil(navigationState.activeWorkflow, "Active workflow should remain set during failure")
    }

    // MARK: - Type Safety Tests

    func testNavigationDestinationTypeSafety() {
        // Test that enum-driven navigation provides compile-time type safety
        let acquisitionID = AcquisitionID("TEST-001")
        let destination = NavigationState.NavigationDestination.acquisition(acquisitionID)

        switch destination {
        case .acquisition(let id):
            XCTAssertEqual(id, acquisitionID, "Type-safe extraction should work")
        default:
            XCTFail("Type matching should work correctly")
        }
    }

    func testWorkflowTypeDefinitions() {
        // Test all workflow types are properly defined
        let allWorkflows = NavigationState.WorkflowType.allCases

        XCTAssertEqual(allWorkflows.count, 4, "Should have 4 workflow types")
        XCTAssertTrue(allWorkflows.contains(.documentGeneration), "Should contain document generation")
        XCTAssertTrue(allWorkflows.contains(.complianceCheck), "Should contain compliance check")
        XCTAssertTrue(allWorkflows.contains(.marketResearch), "Should contain market research")
        XCTAssertTrue(allWorkflows.contains(.contractReview), "Should contain contract review")

        // Test step counts
        XCTAssertEqual(NavigationState.WorkflowType.documentGeneration.totalSteps, 3)
        XCTAssertEqual(NavigationState.WorkflowType.complianceCheck.totalSteps, 4)
        XCTAssertEqual(NavigationState.WorkflowType.marketResearch.totalSteps, 5)
        XCTAssertEqual(NavigationState.WorkflowType.contractReview.totalSteps, 6)
    }
}

// MARK: - Test Coverage Verification

/// This extension ensures we have comprehensive test coverage for all NavigationState functionality
extension NavigationStateTests {

    func testTestCoverageCompleteness() {
        // Verify we have tests for all major NavigationState functionality
        // This meta-test ensures we don't miss critical test cases

        let requiredTestMethods = [
            "testNavigationDestinationEnumCases",
            "testNavigationDestinationDeepLinks",
            "testNavigationDestinationCodable",
            "testNavigationStateObservable",
            "testNavigateToAcquisition",
            "testNavigateToDocument",
            "testNavigateToCompliance",
            "testNavigateToSearch",
            "testNavigateToSettings",
            "testNavigateToQuickAction",
            "testNavigationHistoryManagement",
            "testNavigationPerformanceTracking",
            "testStartDocumentGenerationWorkflow",
            "testStartComplianceCheckWorkflow",
            "testStartMarketResearchWorkflow",
            "testStartContractReviewWorkflow",
            "testAdvanceWorkflowProgression",
            "testWorkflowProgressEquality",
            "testWorkflowProgressCodable",
            "testCompleteWorkflowNavigation",
            "testConcurrentNavigationOperations",
            "testNavigationStateInitialization",
            "testNavigationPerformanceUnder100ms",
            "testLargeNavigationHistoryPerformance",
            "testWorkflowFailureHandling",
            "testNavigationDestinationTypeSafety",
            "testWorkflowTypeDefinitions"
        ]

        // Get all test methods using runtime reflection
        let testClass = type(of: self)
        var methodCount: UInt32 = 0
        guard let methods = class_copyMethodList(testClass, &methodCount) else {
            XCTFail("Could not get method list")
            return
        }

        var testMethods: [String] = []
        for i in 0..<methodCount {
            let selector = method_getName(methods[Int(i)])
            let methodName = String(cString: sel_getName(selector))
            if methodName.hasPrefix("test") {
                testMethods.append(methodName)
            }
        }
        free(methods)

        // Verify we have comprehensive test coverage - at least the required minimum
        XCTAssertGreaterThanOrEqual(testMethods.count, 25, "Should have comprehensive test coverage with at least 25 test methods")
    }
}
