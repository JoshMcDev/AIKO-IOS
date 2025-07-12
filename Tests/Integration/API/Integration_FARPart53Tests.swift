import XCTest
import CoreData
@testable import AIKO

/// Comprehensive test suite for FAR Part 53 forms integration
/// Tests the new repository architecture and form factories
final class Integration_FARPart53Tests: XCTestCase {
    
    // MARK: - Properties
    
    private var context: NSManagedObjectContext!
    private var formRegistry: FormFactoryRegistry!
    private var documentRepository: DocumentRepository!
    private var acquisitionRepository: AcquisitionRepository!
    private var mockEventStore: InMemoryEventStore!
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack
        let model = CoreDataStack.model
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        
        // Create repositories
        mockEventStore = InMemoryEventStore()
        documentRepository = DocumentRepository(context: context)
        acquisitionRepository = AcquisitionRepository(context: context, eventStore: mockEventStore)
        
        // Setup form registry
        formRegistry = FormFactoryRegistry()
        registerAllFormFactories()
    }
    
    override func tearDown() {
        context = nil
        formRegistry = nil
        documentRepository = nil
        acquisitionRepository = nil
        mockEventStore = nil
        super.tearDown()
    }
    
    // MARK: - Form Factory Registration
    
    private func registerAllFormFactories() {
        formRegistry.register(SF1449Factory(), for: "SF1449")
        formRegistry.register(SF33Factory(), for: "SF33")
        formRegistry.register(SF30Factory(), for: "SF30")
        formRegistry.register(SF18Factory(), for: "SF18")
        formRegistry.register(SF26Factory(), for: "SF26")
        formRegistry.register(SF44Factory(), for: "SF44")
        formRegistry.register(DD1155Factory(), for: "DD1155")
    }
    
    // MARK: - Integration Test: Full Acquisition Flow
    
    func testFullAcquisitionFlowWithForms() async throws {
        // Step 1: Create acquisition
        let acquisition = try await acquisitionRepository.create(
            title: "IT Equipment Purchase FY2025",
            requirements: "Purchase of 50 desktop computers for new office"
        )
        
        XCTAssertNotNil(acquisition)
        XCTAssertEqual(acquisition.status, .draft)
        
        // Step 2: Add requirements document
        let requirementsDoc = try await documentRepository.saveDocument(
            fileName: "requirements.pdf",
            data: Data("Requirements content".utf8),
            contentSummary: "Detailed technical specifications for desktop computers",
            acquisitionId: acquisition.id
        )
        
        try await acquisitionRepository.update(acquisition.id) { acq in
            acq.addDocument(requirementsDoc)
        }
        
        // Step 3: Create and add RFQ form (SF18)
        let rfqData = createRFQFormData()
        let sf18Form = try formRegistry.createForm(type: "SF18", with: rfqData)
        XCTAssertNotNil(sf18Form)
        
        try await acquisitionRepository.update(acquisition.id) { acq in
            acq.addForm(sf18Form!)
        }
        
        // Step 4: Update status to in review
        try await acquisitionRepository.update(acquisition.id) { acq in
            acq.updateStatus(.inReview)
        }
        
        // Step 5: Create solicitation form (SF1449)
        let solicitationData = createSolicitationFormData()
        let sf1449Form = try formRegistry.createForm(type: "SF1449", with: solicitationData)
        XCTAssertNotNil(sf1449Form)
        
        try await acquisitionRepository.update(acquisition.id) { acq in
            acq.addForm(sf1449Form!)
        }
        
        // Step 6: Approve acquisition
        try await acquisitionRepository.update(acquisition.id) { acq in
            acq.updateStatus(.approved)
        }
        
        // Verify final state
        let finalAcquisition = try await acquisitionRepository.findById(acquisition.id)
        XCTAssertNotNil(finalAcquisition)
        XCTAssertEqual(finalAcquisition?.status, .approved)
        XCTAssertEqual(finalAcquisition?.documents.count, 1)
        XCTAssertEqual(finalAcquisition?.forms.count, 2)
        XCTAssertTrue(finalAcquisition?.isValidForSubmission() ?? false)
        
        // Verify domain events
        let events = try await mockEventStore.eventsForAggregate(id: acquisition.id, after: nil)
        XCTAssertGreaterThan(events.count, 5) // Multiple events should be recorded
    }
    
    // MARK: - Integration Test: Form Generation Pipeline
    
    func testFormGenerationPipeline() async throws {
        // Create acquisition with multiple forms
        let acquisition = try await acquisitionRepository.create(
            title: "Multi-Form Acquisition",
            requirements: "Complex acquisition requiring multiple forms"
        )
        
        // Generate all form types
        let formTypes = ["SF18", "SF33", "SF1449", "SF30", "SF26", "SF44", "DD1155"]
        
        for formType in formTypes {
            let formData = createGenericFormData(for: formType)
            let form = try formRegistry.createForm(type: formType, with: formData)
            
            XCTAssertNotNil(form, "Failed to create form: \(formType)")
            
            try await acquisitionRepository.update(acquisition.id) { acq in
                acq.addForm(form!)
            }
        }
        
        // Verify all forms were added
        let updatedAcquisition = try await acquisitionRepository.findById(acquisition.id)
        XCTAssertEqual(updatedAcquisition?.forms.count, formTypes.count)
        
        // Test form retrieval by type
        for formType in formTypes {
            let hasForm = updatedAcquisition?.forms.contains { $0.formNumber == formType } ?? false
            XCTAssertTrue(hasForm, "Missing form: \(formType)")
        }
    }
    
    // MARK: - Integration Test: Error Handling
    
    func testErrorHandlingInFormCreation() async throws {
        // Test missing required fields
        let incompleteData = FormData()
        incompleteData["someField"] = "value"
        
        // Should throw validation error
        XCTAssertThrowsError(try formRegistry.createForm(type: "SF1449", with: incompleteData)) { error in
            XCTAssertTrue(error is FormValidationError)
        }
        
        // Test invalid form type
        let validData = createSolicitationFormData()
        let unknownForm = try formRegistry.createForm(type: "UnknownForm", with: validData)
        XCTAssertNil(unknownForm)
    }
    
    // MARK: - Integration Test: Concurrent Operations
    
    func testConcurrentFormOperations() async throws {
        let acquisition = try await acquisitionRepository.create(
            title: "Concurrent Test",
            requirements: "Testing concurrent form operations"
        )
        
        // Perform concurrent form additions
        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask {
                    let formData = self.createRFQFormData()
                    formData["rfqNumber"] = "RFQ-CONCURRENT-\(i)"
                    
                    if let form = try? self.formRegistry.createForm(type: "SF18", with: formData) {
                        try? await self.acquisitionRepository.update(acquisition.id) { acq in
                            acq.addForm(form)
                        }
                    }
                }
            }
        }
        
        // Verify forms were added (some might fail due to concurrency)
        let finalAcquisition = try await acquisitionRepository.findById(acquisition.id)
        XCTAssertGreaterThan(finalAcquisition?.forms.count ?? 0, 0)
    }
    
    // MARK: - Performance Test
    
    func testPerformance_FormCreation() throws {
        measure {
            let expectation = self.expectation(description: "Form creation")
            
            Task {
                for i in 1...100 {
                    let formData = createSolicitationFormData()
                    formData["solicitationNumber"] = "SOL-PERF-\(i)"
                    _ = try? formRegistry.createForm(type: "SF1449", with: formData)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createRFQFormData() -> FormData {
        let data = FormData()
        data["rfqNumber"] = "RFQ-2025-001"
        data["issueDate"] = "2025-01-15"
        data["dueDate"] = "2025-01-30"
        data["buyerName"] = "John Smith"
        data["buyerPhone"] = "555-0123"
        data["deliveryDate"] = "2025-02-28"
        data["deliveryLocation"] = "Building A, Room 101"
        data["itemDescription"] = "Desktop Computers - High Performance"
        data["quantity"] = 50
        data["vendorName"] = ""
        data["vendorContact"] = ""
        data["quotedPrice"] = 0.0
        data["deliveryTerms"] = "FOB Destination"
        data["revision"] = "06/2016"
        return data
    }
    
    private func createSolicitationFormData() -> FormData {
        let data = FormData()
        data["requisitionNumber"] = "REQ-2025-001"
        data["requisitionDate"] = "2025-01-10"
        data["pageCount"] = 10
        data["solicitationNumber"] = "SOL-2025-001"
        data["solicitationDate"] = "2025-01-20"
        data["contractorName"] = ""
        data["contractorAddress"] = ""
        data["itemDescription"] = "IT Equipment and Services"
        data["quantity"] = 1
        data["unitPrice"] = 0.0
        data["totalAmount"] = 0.0
        data["deliveryDate"] = "2025-03-01"
        data["deliveryLocation"] = "Main Office"
        data["certificationSignature"] = ""
        data["certificationDate"] = ""
        data["revision"] = "04/2024"
        return data
    }
    
    private func createGenericFormData(for formType: String) -> FormData {
        let data = FormData()
        
        switch formType {
        case "SF18":
            return createRFQFormData()
        case "SF1449":
            return createSolicitationFormData()
        case "SF33":
            data["solicitationNumber"] = "SOL-2025-002"
            data["issuedBy"] = "Contracting Office"
            data["issueDate"] = "2025-01-15"
            data["revision"] = "04/2024"
        case "SF30":
            data["modificationNumber"] = "P00001"
            data["contractNumber"] = "W912QR-25-C-0001"
            data["effectiveDate"] = "2025-02-01"
            data["revision"] = "04/2024"
        case "SF26":
            data["contractNumber"] = "W912QR-25-C-0002"
            data["awardDate"] = "2025-01-30"
            data["effectiveDate"] = "2025-02-01"
            data["revision"] = "04/2024"
        case "SF44":
            data["orderNumber"] = "PO-2025-0001"
            data["orderDate"] = "2025-01-15"
            data["revision"] = "10/1983"
        case "DD1155":
            data["orderNumber"] = "SPE7LX-25-D-0001"
            data["requisitionNumber"] = "REQ-DOD-2025-001"
            data["priority"] = "03 - Routine"
            data["issueDate"] = "2025-01-20"
            data["revision"] = "06/2024"
        default:
            break
        }
        
        return data
    }
}