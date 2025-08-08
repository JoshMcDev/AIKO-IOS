@testable import AppCore
import XCTest

/// Basic functionality test to verify core components compile and work
final class BasicFunctionalityTest: XCTestCase {
    func testBasicDocumentTypeEnum() {
        // Test that DocumentType enum is accessible and works
        let docType = DocumentType.sow
        XCTAssertEqual(docType.rawValue, "Statement of Work")
        XCTAssertNotNil(docType.id)
    }

    func testBasicAcquisitionStatusEnum() {
        // Test that AcquisitionStatus enum is accessible and works
        let status = AcquisitionStatus.draft
        XCTAssertEqual(status.rawValue, "draft")
        XCTAssertTrue(AcquisitionStatus.allCases.contains(status))
    }

    func testBasicMediaTypeEnum() {
        // Test that MediaType enum is accessible and works
        let mediaType = MediaType.image
        XCTAssertEqual(mediaType.rawValue, "image")
        XCTAssertTrue(MediaType.allCases.contains(mediaType))
    }

    func testBasicAcquisitionModel() {
        // Test that Acquisition model can be created
        let acquisition = Acquisition(
            title: "Test Acquisition",
            requirements: "Test requirements"
        )

        XCTAssertEqual(acquisition.title, "Test Acquisition")
        XCTAssertEqual(acquisition.requirements, "Test requirements")
        XCTAssertEqual(acquisition.status, .draft)
        XCTAssertNotNil(acquisition.id)
    }

    func testBasicGeneratedDocumentModel() {
        // Test that GeneratedDocument model can be created
        let document = GeneratedDocument(
            title: "Test Document",
            documentType: .sow,
            content: "Test content"
        )

        XCTAssertEqual(document.title, "Test Document")
        XCTAssertEqual(document.content, "Test content")
        XCTAssertEqual(document.documentType, .sow)
        XCTAssertNotNil(document.id)
    }
}
