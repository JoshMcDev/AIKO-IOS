@testable import AIKO
import XCTest

final class Unit_AcquisitionAggregateTests: XCTestCase {
    // MARK: - Properties

    private var sut: AcquisitionAggregate!
    private var mockEventPublisher: MockDomainEventPublisher!

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()

        mockEventPublisher = MockDomainEventPublisher()

        sut = AcquisitionAggregate(
            id: UUID(),
            title: "Test Acquisition",
            requirements: "Test requirements",
            status: .draft,
            createdAt: Date(),
            updatedAt: Date(),
            documents: [],
            forms: [],
            eventPublisher: mockEventPublisher
        )
    }

    override func tearDown() {
        sut = nil
        mockEventPublisher = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_SetsPropertiesCorrectly() {
        // Given
        let id = UUID()
        let title = "New Acquisition"
        let requirements = "Requirements text"
        let status = AcquisitionStatus.draft
        let createdAt = Date()
        let updatedAt = Date()

        // When
        let acquisition = AcquisitionAggregate(
            id: id,
            title: title,
            requirements: requirements,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            documents: [],
            forms: [],
            eventPublisher: mockEventPublisher
        )

        // Then
        XCTAssertEqual(acquisition.id, id)
        XCTAssertEqual(acquisition.title, title)
        XCTAssertEqual(acquisition.requirements, requirements)
        XCTAssertEqual(acquisition.status, status)
        XCTAssertEqual(acquisition.createdAt, createdAt)
        XCTAssertEqual(acquisition.updatedAt, updatedAt)
        XCTAssertEqual(acquisition.documents.count, 0)
        XCTAssertEqual(acquisition.forms.count, 0)
    }

    // MARK: - Update Tests

    func testUpdateTitle_Success() {
        // Given
        let newTitle = "Updated Title"
        let originalUpdatedAt = sut.updatedAt

        // When
        sut.updateTitle(newTitle)

        // Then
        XCTAssertEqual(sut.title, newTitle)
        XCTAssertGreaterThan(sut.updatedAt, originalUpdatedAt)

        // Verify event published
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 1)
        if let event = mockEventPublisher.publishedEvents.first as? AcquisitionUpdatedEvent {
            XCTAssertEqual(event.aggregateId, sut.id)
            XCTAssertEqual(event.field, "title")
            XCTAssertEqual(event.newValue as? String, newTitle)
        } else {
            XCTFail("Expected AcquisitionUpdatedEvent")
        }
    }

    func testUpdateRequirements_Success() {
        // Given
        let newRequirements = "Updated requirements"
        let originalUpdatedAt = sut.updatedAt

        // When
        sut.updateRequirements(newRequirements)

        // Then
        XCTAssertEqual(sut.requirements, newRequirements)
        XCTAssertGreaterThan(sut.updatedAt, originalUpdatedAt)

        // Verify event published
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 1)
        if let event = mockEventPublisher.publishedEvents.first as? AcquisitionUpdatedEvent {
            XCTAssertEqual(event.field, "requirements")
            XCTAssertEqual(event.newValue as? String, newRequirements)
        }
    }

    func testUpdateStatus_ValidTransition_Success() {
        // Given
        XCTAssertEqual(sut.status, .draft)

        // When - Draft to In Review
        sut.updateStatus(.inReview)

        // Then
        XCTAssertEqual(sut.status, .inReview)
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 1)
        if let event = mockEventPublisher.publishedEvents.first as? AcquisitionStatusChangedEvent {
            XCTAssertEqual(event.oldStatus, .draft)
            XCTAssertEqual(event.newStatus, .inReview)
        }
    }

    func testUpdateStatus_InvalidTransition_DoesNotUpdate() {
        // Given
        sut.updateStatus(.completed) // Set to completed
        mockEventPublisher.reset()

        // When - Try to go back to draft (invalid)
        sut.updateStatus(.draft)

        // Then
        XCTAssertEqual(sut.status, .completed) // Should remain completed
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 0) // No event published
    }

    // MARK: - Document Management Tests

    func testAddDocument_Success() {
        // Given
        let document = Document(
            id: UUID(),
            fileName: "test.pdf",
            data: Data("test".utf8),
            contentSummary: "Test document",
            createdAt: Date()
        )

        // When
        sut.addDocument(document)

        // Then
        XCTAssertEqual(sut.documents.count, 1)
        XCTAssertEqual(sut.documents.first?.id, document.id)

        // Verify event published
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 1)
        if let event = mockEventPublisher.publishedEvents.first as? DocumentAddedEvent {
            XCTAssertEqual(event.aggregateId, sut.id)
            XCTAssertEqual(event.documentId, document.id)
            XCTAssertEqual(event.fileName, document.fileName)
        }
    }

    func testAddDocument_Duplicate_DoesNotAdd() {
        // Given
        let document = Document(
            id: UUID(),
            fileName: "test.pdf",
            data: Data("test".utf8),
            contentSummary: nil,
            createdAt: Date()
        )
        sut.addDocument(document)
        mockEventPublisher.reset()

        // When - Try to add same document again
        sut.addDocument(document)

        // Then
        XCTAssertEqual(sut.documents.count, 1) // Still only one
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 0) // No new event
    }

    func testRemoveDocument_Success() {
        // Given
        let document = Document(
            id: UUID(),
            fileName: "test.pdf",
            data: Data("test".utf8),
            contentSummary: nil,
            createdAt: Date()
        )
        sut.addDocument(document)
        mockEventPublisher.reset()

        // When
        sut.removeDocument(withId: document.id)

        // Then
        XCTAssertEqual(sut.documents.count, 0)

        // Verify event published
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 1)
        if let event = mockEventPublisher.publishedEvents.first as? DocumentRemovedEvent {
            XCTAssertEqual(event.aggregateId, sut.id)
            XCTAssertEqual(event.documentId, document.id)
        }
    }

    func testRemoveDocument_NonExistent_NoChange() {
        // Given
        let nonExistentId = UUID()

        // When
        sut.removeDocument(withId: nonExistentId)

        // Then
        XCTAssertEqual(sut.documents.count, 0)
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 0)
    }

    // MARK: - Form Management Tests

    func testAddForm_Success() {
        // Given
        let form = createTestForm()

        // When
        sut.addForm(form)

        // Then
        XCTAssertEqual(sut.forms.count, 1)
        XCTAssertTrue(sut.forms.contains { $0.formNumber == form.formNumber })

        // Verify event published
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 1)
        if let event = mockEventPublisher.publishedEvents.first as? FormAddedEvent {
            XCTAssertEqual(event.aggregateId, sut.id)
            XCTAssertEqual(event.formNumber, form.formNumber)
            XCTAssertEqual(event.formType, String(describing: type(of: form)))
        }
    }

    func testRemoveForm_Success() {
        // Given
        let form = createTestForm()
        sut.addForm(form)
        mockEventPublisher.reset()

        // When
        sut.removeForm(withNumber: form.formNumber)

        // Then
        XCTAssertEqual(sut.forms.count, 0)

        // Verify event published
        XCTAssertEqual(mockEventPublisher.publishedEvents.count, 1)
        if let event = mockEventPublisher.publishedEvents.first as? FormRemovedEvent {
            XCTAssertEqual(event.aggregateId, sut.id)
            XCTAssertEqual(event.formNumber, form.formNumber)
        }
    }

    // MARK: - Validation Tests

    func testIsValidForSubmission_AllRequirementsMet_ReturnsTrue() {
        // Given
        sut.updateStatus(.approved)
        sut.addDocument(Document(
            id: UUID(),
            fileName: "requirements.pdf",
            data: Data("content".utf8),
            contentSummary: nil,
            createdAt: Date()
        ))
        sut.addForm(createTestForm())

        // When
        let isValid = sut.isValidForSubmission()

        // Then
        XCTAssertTrue(isValid)
    }

    func testIsValidForSubmission_WrongStatus_ReturnsFalse() {
        // Given - In draft status
        sut.addDocument(Document(
            id: UUID(),
            fileName: "requirements.pdf",
            data: Data("content".utf8),
            contentSummary: nil,
            createdAt: Date()
        ))
        sut.addForm(createTestForm())

        // When
        let isValid = sut.isValidForSubmission()

        // Then
        XCTAssertFalse(isValid)
    }

    func testIsValidForSubmission_NoDocuments_ReturnsFalse() {
        // Given
        sut.updateStatus(.approved)
        sut.addForm(createTestForm())

        // When
        let isValid = sut.isValidForSubmission()

        // Then
        XCTAssertFalse(isValid)
    }

    func testIsValidForSubmission_NoForms_ReturnsFalse() {
        // Given
        sut.updateStatus(.approved)
        sut.addDocument(Document(
            id: UUID(),
            fileName: "requirements.pdf",
            data: Data("content".utf8),
            contentSummary: nil,
            createdAt: Date()
        ))

        // When
        let isValid = sut.isValidForSubmission()

        // Then
        XCTAssertFalse(isValid)
    }

    // MARK: - Event Recording Tests

    func testGetDomainEvents_ReturnsAllEvents() {
        // Given
        sut.updateTitle("New Title")
        sut.updateStatus(.inReview)
        sut.addDocument(Document(
            id: UUID(),
            fileName: "test.pdf",
            data: Data("test".utf8),
            contentSummary: nil,
            createdAt: Date()
        ))

        // When
        let events = sut.getDomainEvents()

        // Then
        XCTAssertEqual(events.count, 3)
        XCTAssertTrue(events[0] is AcquisitionUpdatedEvent)
        XCTAssertTrue(events[1] is AcquisitionStatusChangedEvent)
        XCTAssertTrue(events[2] is DocumentAddedEvent)
    }

    func testClearDomainEvents_RemovesAllEvents() {
        // Given
        sut.updateTitle("New Title")
        sut.updateStatus(.inReview)

        // When
        sut.clearDomainEvents()
        let events = sut.getDomainEvents()

        // Then
        XCTAssertEqual(events.count, 0)
    }

    // MARK: - Helper Methods

    private func createTestForm() -> GovernmentForm {
        let formData = FormData()
        formData["formNumber"] = "SF1449"
        formData["title"] = "Test Form"
        formData["revision"] = "10/2023"

        let factory = SF1449Factory()
        return try! factory.create(with: formData)
    }
}

// MARK: - Mock Event Publisher

private class MockDomainEventPublisher: DomainEventPublisher {
    var publishedEvents: [DomainEvent] = []

    func publish(_ event: DomainEvent) {
        publishedEvents.append(event)
    }

    func reset() {
        publishedEvents.removeAll()
    }
}
