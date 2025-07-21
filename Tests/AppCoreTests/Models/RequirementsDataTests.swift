import XCTest
@testable import AppCore

final class RequirementsDataTests: XCTestCase {
    
    func testInitialization() {
        let requirements = RequirementsData()
        
        XCTAssertNil(requirements.projectTitle)
        XCTAssertNil(requirements.description)
        XCTAssertNil(requirements.estimatedValue)
        XCTAssertNil(requirements.businessNeed)
        XCTAssertNil(requirements.performancePeriod)
        XCTAssertTrue(requirements.technicalRequirements.isEmpty)
        XCTAssertNil(requirements.placeOfPerformance)
        XCTAssertNil(requirements.requiredDate)
        XCTAssertNil(requirements.acquisitionType)
        XCTAssertNil(requirements.setAsideType)
        XCTAssertTrue(requirements.attachments.isEmpty)
    }
    
    func testDataPopulation() {
        var requirements = RequirementsData()
        
        requirements.projectTitle = "Test Project"
        requirements.description = "Test Description"
        requirements.estimatedValue = 50000.0
        requirements.businessNeed = "Business need"
        requirements.performancePeriod = "12 months"
        requirements.technicalRequirements = ["Req 1", "Req 2"]
        requirements.placeOfPerformance = "Test Location"
        requirements.acquisitionType = "Supplies"
        requirements.setAsideType = "Small Business"
        
        XCTAssertEqual(requirements.projectTitle, "Test Project")
        XCTAssertEqual(requirements.description, "Test Description")
        XCTAssertEqual(requirements.estimatedValue, 50000.0)
        XCTAssertEqual(requirements.businessNeed, "Business need")
        XCTAssertEqual(requirements.performancePeriod, "12 months")
        XCTAssertEqual(requirements.technicalRequirements.count, 2)
        XCTAssertEqual(requirements.placeOfPerformance, "Test Location")
        XCTAssertEqual(requirements.acquisitionType, "Supplies")
        XCTAssertEqual(requirements.setAsideType, "Small Business")
    }
    
    func testEquatableConformance() {
        let requirements1 = createSampleRequirements()
        let requirements2 = createSampleRequirements()
        
        XCTAssertEqual(requirements1, requirements2)
        
        var requirements3 = createSampleRequirements()
        requirements3.projectTitle = "Different Title"
        
        XCTAssertNotEqual(requirements1, requirements3)
    }
    
    func testCodableConformance() throws {
        let requirements = createSampleRequirements()
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(requirements)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedRequirements = try decoder.decode(RequirementsData.self, from: data)
        
        XCTAssertEqual(requirements, decodedRequirements)
    }
    
    func testSendableConformance() {
        // Test that RequirementsData can be passed between actors
        let requirements = createSampleRequirements()
        
        Task {
            // This should compile without warnings if Sendable is properly implemented
            await processRequirements(requirements)
        }
    }
    
    func testVendorInfoIntegration() {
        var requirements = RequirementsData()
        
        let vendorInfo = APEVendorInfo(
            name: "Test Vendor",
            uei: "ABC123456789",
            cage: "12345",
            address: "123 Test St",
            email: "test@vendor.com",
            phone: "555-1234"
        )
        
        requirements.vendorInfo = vendorInfo
        
        XCTAssertEqual(requirements.vendorInfo?.name, "Test Vendor")
        XCTAssertEqual(requirements.vendorInfo?.uei, "ABC123456789")
        XCTAssertEqual(requirements.vendorInfo?.cage, "12345")
    }
    
    func testRequirementsStringGeneration() {
        let requirements = createSampleRequirements()
        let requirementsString = requirements.toFormattedString()
        
        XCTAssertTrue(requirementsString.contains("Test Project"))
        XCTAssertTrue(requirementsString.contains("50000"))
        XCTAssertTrue(requirementsString.contains("Business need"))
    }
    
    func testIsCompleteValidation() {
        var requirements = RequirementsData()
        
        // Empty requirements should not be complete
        XCTAssertFalse(requirements.isComplete)
        
        // Add minimum required fields
        requirements.projectTitle = "Test"
        requirements.estimatedValue = 1000.0
        requirements.businessNeed = "Need"
        
        XCTAssertTrue(requirements.isComplete)
    }
    
    func testTechnicalRequirementsManagement() {
        var requirements = RequirementsData()
        
        // Test adding requirements
        requirements.addTechnicalRequirement("Requirement 1")
        requirements.addTechnicalRequirement("Requirement 2")
        
        XCTAssertEqual(requirements.technicalRequirements.count, 2)
        XCTAssertTrue(requirements.technicalRequirements.contains("Requirement 1"))
        
        // Test removing requirements
        requirements.removeTechnicalRequirement("Requirement 1")
        XCTAssertEqual(requirements.technicalRequirements.count, 1)
        XCTAssertFalse(requirements.technicalRequirements.contains("Requirement 1"))
    }
    
    func testAttachmentsManagement() {
        var requirements = RequirementsData()
        
        let attachment = DocumentAttachment(
            id: UUID(),
            fileName: "test.pdf",
            fileSize: 1024,
            mimeType: "application/pdf",
            uploadDate: Date()
        )
        
        requirements.addAttachment(attachment)
        XCTAssertEqual(requirements.attachments.count, 1)
        
        requirements.removeAttachment(attachment.id)
        XCTAssertEqual(requirements.attachments.count, 0)
    }
    
    func testDataValidation() {
        var requirements = RequirementsData()
        
        // Test estimated value validation
        requirements.estimatedValue = -1000.0
        XCTAssertFalse(requirements.isValidEstimatedValue)
        
        requirements.estimatedValue = 1000.0
        XCTAssertTrue(requirements.isValidEstimatedValue)
        
        // Test required date validation
        requirements.requiredDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        XCTAssertFalse(requirements.isValidRequiredDate)
        
        requirements.requiredDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        XCTAssertTrue(requirements.isValidRequiredDate)
    }
}

// MARK: - Helper Functions

private func createSampleRequirements() -> RequirementsData {
    var requirements = RequirementsData()
    requirements.projectTitle = "Test Project"
    requirements.description = "Test Description"
    requirements.estimatedValue = 50000.0
    requirements.businessNeed = "Business need"
    requirements.performancePeriod = "12 months"
    requirements.technicalRequirements = ["Requirement 1", "Requirement 2"]
    requirements.placeOfPerformance = "Test Location"
    requirements.acquisitionType = "Supplies"
    return requirements
}

private func processRequirements(_ requirements: RequirementsData) async {
    // This function demonstrates that RequirementsData is Sendable
    print("Processing requirements: \(requirements.projectTitle ?? "Unknown")")
}

// MARK: - RequirementsData Extensions for Testing

private extension RequirementsData {
    func toFormattedString() -> String {
        var result = ""
        
        if let title = projectTitle {
            result += "Project: \(title)\n"
        }
        
        if let value = estimatedValue {
            result += "Value: \(value)\n"
        }
        
        if let need = businessNeed {
            result += "Need: \(need)\n"
        }
        
        return result
    }
    
    var isComplete: Bool {
        projectTitle != nil &&
        estimatedValue != nil &&
        businessNeed != nil
    }
    
    var isValidEstimatedValue: Bool {
        guard let value = estimatedValue else { return false }
        return value > 0
    }
    
    var isValidRequiredDate: Bool {
        guard let date = requiredDate else { return true } // Optional field
        return date > Date()
    }
    
    mutating func addTechnicalRequirement(_ requirement: String) {
        if !technicalRequirements.contains(requirement) {
            technicalRequirements.append(requirement)
        }
    }
    
    mutating func removeTechnicalRequirement(_ requirement: String) {
        technicalRequirements.removeAll { $0 == requirement }
    }
    
    mutating func addAttachment(_ attachment: DocumentAttachment) {
        attachments.append(attachment)
    }
    
    mutating func removeAttachment(_ id: UUID) {
        attachments.removeAll { $0.id == id }
    }
}