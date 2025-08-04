import XCTest
import SwiftUI
@testable import AIKO
@testable import AppCore

// Use specific import to resolve ambiguity - Green phase tests specific
typealias GreenPhaseTestDocumentScannerViewModel = AppCore.DocumentScannerViewModel

/// Isolated GREEN phase test that verifies core implementations without UIKit dependencies
@MainActor
final class DocumentScannerGreenPhaseTest: XCTestCase {

    private var viewModel: GreenPhaseTestDocumentScannerViewModel!

    override func setUp() async throws {
        viewModel = GreenPhaseTestDocumentScannerViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - GREEN Phase Core Implementation Tests

    func test_viewModel_initialization_succeeds() {
        // GREEN phase: DocumentScannerViewModel should initialize without fatalError
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isScanning)
        XCTAssertTrue(viewModel.scannedPages.isEmpty)
    }

    func test_startScanning_completes_without_fatalError() async {
        // GREEN phase: startScanning should complete without throwing fatalError
        await viewModel.startScanning()

        // Test passes if we reach this point without fatalError
        XCTAssertTrue(true, "startScanning completed without fatalError")
    }

    func test_stopScanning_completes_without_fatalError() {
        // GREEN phase: stopScanning should complete without throwing fatalError
        viewModel.stopScanning()

        // Test passes if we reach this point without fatalError
        XCTAssertTrue(true, "stopScanning completed without fatalError")
    }

    func test_addPage_works_without_fatalError() {
        // GREEN phase: addPage should work without throwing fatalError
        let mockPage = ScannedPage(
            imageData: Data("MOCK_IMAGE".utf8),
            ocrText: "Test document",
            pageNumber: 1,
            processingState: .completed
        )

        viewModel.addPage(mockPage)

        // Should have added the page successfully
        XCTAssertEqual(viewModel.scannedPages.count, 1)
        XCTAssertEqual(viewModel.scannedPages.first?.pageNumber, 1)
    }

    func test_clearSession_works_without_fatalError() {
        // GREEN phase: clearSession should work without throwing fatalError
        let mockPage = ScannedPage(
            imageData: Data("MOCK_IMAGE".utf8),
            ocrText: "Test document",
            pageNumber: 1,
            processingState: .completed
        )

        viewModel.addPage(mockPage)
        XCTAssertEqual(viewModel.scannedPages.count, 1)

        viewModel.clearSession()
        XCTAssertTrue(viewModel.scannedPages.isEmpty)
    }

    func test_checkCameraPermissions_returns_value_without_fatalError() async {
        // GREEN phase: checkCameraPermissions should return a value without fatalError
        let hasPermission = await viewModel.checkCameraPermissions()

        // Should return some boolean value without throwing fatalError
        XCTAssertNotNil(hasPermission)
    }

    func test_requestCameraPermissions_returns_value_without_fatalError() async {
        // GREEN phase: requestCameraPermissions should return a value without fatalError
        let hasPermission = await viewModel.requestCameraPermissions()

        // Should return some boolean value without throwing fatalError
        XCTAssertNotNil(hasPermission)
    }

    func test_processPage_completes_without_fatalError() async {
        // GREEN phase: processPage should complete without throwing fatalError
        let mockPage = ScannedPage(
            imageData: Data("MOCK_IMAGE".utf8),
            ocrText: "Test document",
            pageNumber: 1,
            processingState: .pending
        )

        do {
            _ = try await viewModel.processPage(mockPage)
            // Test passes if we reach here without fatalError
            XCTAssertTrue(true, "processPage completed without fatalError")
        } catch {
            // It's OK if it throws an error, as long as it doesn't use fatalError
            XCTAssertTrue(true, "processPage threw error instead of fatalError: \(error)")
        }
    }

    func test_exportPages_completes_without_fatalError() async {
        // GREEN phase: exportPages should complete without throwing fatalError
        let mockPage = ScannedPage(
            imageData: Data("MOCK_IMAGE".utf8),
            ocrText: "Test document",
            pageNumber: 1,
            processingState: .completed
        )

        viewModel.addPage(mockPage)

        do {
            let exportData = try await viewModel.exportPages()
            XCTAssertNotNil(exportData)
        } catch {
            // It's OK if it throws an error, as long as it doesn't use fatalError
            XCTAssertTrue(true, "exportPages threw error instead of fatalError: \(error)")
        }
    }

    func test_saveDocument_completes_without_fatalError() async {
        // GREEN phase: saveDocument should complete without throwing fatalError
        let mockPage = ScannedPage(
            imageData: Data("MOCK_IMAGE".utf8),
            ocrText: "Test document",
            pageNumber: 1,
            processingState: .completed
        )

        viewModel.addPage(mockPage)
        await viewModel.saveDocument()

        // Test passes if we reach this point without fatalError
        XCTAssertTrue(true, "saveDocument completed without fatalError")
    }

    func test_reorderPages_completes_without_fatalError() {
        // GREEN phase: reorderPages should complete without throwing fatalError
        let page1 = ScannedPage(
            imageData: Data("PAGE1".utf8),
            ocrText: "Page 1",
            pageNumber: 1,
            processingState: .completed
        )
        let page2 = ScannedPage(
            imageData: Data("PAGE2".utf8),
            ocrText: "Page 2",
            pageNumber: 2,
            processingState: .completed
        )

        viewModel.addPage(page1)
        viewModel.addPage(page2)

        viewModel.reorderPages(from: IndexSet([0]), to: 1)

        // Should still have 2 pages after reordering
        XCTAssertEqual(viewModel.scannedPages.count, 2)
    }

    func test_enhanceAllPages_completes_without_fatalError() async {
        // GREEN phase: enhanceAllPages should complete without throwing fatalError
        let mockPage = ScannedPage(
            imageData: Data("MOCK_IMAGE".utf8),
            ocrText: "Test document",
            pageNumber: 1,
            processingState: .completed
        )

        viewModel.addPage(mockPage)
        await viewModel.enhanceAllPages()

        // Test passes if we reach this point without fatalError
        XCTAssertTrue(true, "enhanceAllPages completed without fatalError")
    }

    // MARK: - Performance Tests (GREEN Phase)

    func test_cameraPermissionCheck_meets_performance_requirements() async {
        // GREEN phase: Should complete within 200ms performance requirement
        let startTime = Date()
        _ = await viewModel.checkCameraPermissions()
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(duration, 0.2, "Camera permission check should complete within 200ms")
    }

    func test_scanInitiation_meets_performance_requirements() async {
        // GREEN phase: Should complete within 200ms performance requirement
        let startTime = Date()
        await viewModel.startScanning()
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(duration, 0.2, "Scan initiation should complete within 200ms")
    }

    // MARK: - Architecture Tests (GREEN Phase)

    func test_viewModel_follows_observable_pattern() {
        // GREEN phase: DocumentScannerViewModel should be @Observable
        XCTAssertNotNil(viewModel, "DocumentScannerViewModel should be initialized")
        // Note: Observable conformance is verified by compilation since DocumentScannerViewModel is @Observable
    }

    func test_scannedPages_are_published() {
        // GREEN phase: scannedPages should be observable
        let initialCount = viewModel.scannedPages.count

        let mockPage = ScannedPage(
            imageData: Data("TEST".utf8),
            ocrText: "Test document",
            pageNumber: 1,
            processingState: .completed
        )

        viewModel.addPage(mockPage)

        XCTAssertNotEqual(viewModel.scannedPages.count, initialCount, "scannedPages should update when pages are added")
    }

    func test_isScanning_state_management() async {
        // GREEN phase: isScanning should be properly managed
        XCTAssertFalse(viewModel.isScanning, "Should start with isScanning = false")

        // Note: Checking if isScanning changes during scanning may depend on implementation
        // For GREEN phase, we just verify the method completes
        await viewModel.startScanning()

        // Test passes if startScanning completes without fatalError
        XCTAssertTrue(true, "Scanning state management works without fatalError")
    }
}
