@testable import AIKO
@testable import AppCore
import Foundation
import Testing

/// TDD Test Suite for DocumentExecutionViewModel
/// PHASE 2: Business Logic Views - Federal Document Generation & Execution
/// Tests cover: Document generation, status tracking, progress monitoring, error handling
@MainActor
final class DocumentExecutionViewModelTests {
    // MARK: - Test Data Setup

    private func createMockAcquisition() -> AppCore.Acquisition {
        AppCore.Acquisition(
            id: UUID(),
            title: "Software Development Services",
            requirements: "Agile development team for enterprise software solutions",
            projectNumber: "ACQ-20250123-1001",
            status: .inProgress,
            createdDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            lastModifiedDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            uploadedFiles: [],
            generatedFiles: []
        )
    }

    private func createMockGeneratedDocuments() -> [GeneratedDocument] {
        [
            GeneratedDocument(
                id: UUID(),
                title: "Statement of Work - Software Development",
                documentType: .sow,
                content: "Comprehensive SOW for software development services...",
                createdAt: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            GeneratedDocument(
                id: UUID(),
                title: "Performance Work Statement - Agile Services",
                documentType: .pws,
                content: "PWS defining performance-based requirements...",
                createdAt: Date().addingTimeInterval(-1800) // 30 minutes ago
            ),
            GeneratedDocument(
                id: UUID(),
                title: "Quality Assurance Surveillance Plan",
                documentType: .qasp,
                content: "QASP monitoring framework for quality standards...",
                createdAt: Date().addingTimeInterval(-900) // 15 minutes ago
            ),
        ]
    }

    private func createMockDocumentService() -> DocumentExecutionService {
        let mockDocuments = createMockGeneratedDocuments()

        return DocumentExecutionService(
            generateDocument: { docType, requirements, _ in
                GeneratedDocument(
                    title: "\(docType.rawValue) - Test Generated",
                    documentType: docType,
                    content: "Generated content for \(docType.rawValue): \(requirements)",
                    createdAt: Date()
                )
            },
            generateDocumentChain: { _ in
                // Simulate document chain generation
                mockDocuments
            },
            findDocumentsByType: { docType in
                mockDocuments.compactMap { doc in
                    doc.documentType == docType ? DocumentExecutionInfo(
                        id: doc.id,
                        title: doc.title,
                        type: docType,
                        createdAt: doc.createdAt,
                        size: doc.content.count
                    ) : nil
                }
            },
            findRecentDocuments: { limit in
                Array(mockDocuments.prefix(limit)).map { doc in
                    DocumentExecutionInfo(
                        id: doc.id,
                        title: doc.title,
                        type: doc.documentType ?? .sow,
                        createdAt: doc.createdAt,
                        size: doc.content.count
                    )
                }
            },
            validateDocument: { _ in
                ValidationResult(
                    isValid: true,
                    errors: [],
                    warnings: []
                )
            }
        )
    }

    private func createErrorDocumentService() -> DocumentExecutionService {
        DocumentExecutionService(
            generateDocument: { _, _, _ in
                throw DocumentExecutionError.generationFailed("Mock generation error")
            },
            generateDocumentChain: { _ in
                throw DocumentExecutionError.generationFailed("Mock chain generation error")
            },
            findDocumentsByType: { _ in
                throw DocumentExecutionError.serviceUnavailable
            },
            findRecentDocuments: { _ in
                throw DocumentExecutionError.serviceUnavailable
            },
            validateDocument: { _ in
                ValidationResult(
                    isValid: false,
                    errors: [DocumentValidationError(code: "TEST_ERROR", message: "Mock validation error", fix: nil)],
                    warnings: []
                )
            }
        )
    }

    // MARK: - Initialization Tests

    @Test("DocumentExecutionViewModel initializes with empty state")
    func initialization() {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        #expect(viewModel.acquisition.id == mockAcquisition.id)
        #expect(viewModel.availableDocumentTypes.isEmpty == false) // Should have default document types
        #expect(viewModel.generatedDocuments.isEmpty)
        #expect(viewModel.isGenerating == false)
        #expect(viewModel.generationProgress == 0.0)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.selectedDocumentType == nil)
        #expect(viewModel.showingDocumentPreview == false)
    }

    // MARK: - Document Type Selection Tests

    @Test("DocumentExecutionViewModel loads available document types")
    func testLoadAvailableDocumentTypes() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        await viewModel.loadAvailableDocumentTypes()

        #expect(!viewModel.availableDocumentTypes.isEmpty)
        #expect(viewModel.availableDocumentTypes.contains(.sow))
        #expect(viewModel.availableDocumentTypes.contains(.pws))
        #expect(viewModel.availableDocumentTypes.contains(.qasp))
    }

    @Test("DocumentExecutionViewModel filters document types by acquisition status")
    func filterDocumentTypesByStatus() async {
        let mockService = createMockDocumentService()
        var mockAcquisition = createMockAcquisition()
        mockAcquisition.status = .draft // Draft status should show different document types

        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        await viewModel.loadAvailableDocumentTypes()

        // Draft status should include planning documents
        #expect(viewModel.availableDocumentTypes.contains(.marketResearch))
        #expect(viewModel.availableDocumentTypes.contains(.acquisitionPlan))
    }

    @Test("DocumentExecutionViewModel selects document type")
    func testSelectDocumentType() {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        viewModel.selectDocumentType(.sow)

        #expect(viewModel.selectedDocumentType == .sow)
    }

    // MARK: - Document Generation Tests

    @Test("DocumentExecutionViewModel generates single document successfully")
    func generateSingleDocument() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        await viewModel.generateDocument(.sow)

        #expect(viewModel.generatedDocuments.count == 1)
        #expect(viewModel.generatedDocuments.first?.documentType == .sow)
        #expect(viewModel.isGenerating == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.generationProgress == 1.0)
    }

    @Test("DocumentExecutionViewModel handles single document generation error")
    func generateSingleDocumentError() async {
        let errorService = createErrorDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: errorService
        )

        await viewModel.generateDocument(.sow)

        #expect(viewModel.generatedDocuments.isEmpty)
        #expect(viewModel.isGenerating == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("generation error") == true)
    }

    @Test("DocumentExecutionViewModel generates document chain successfully")
    func testGenerateDocumentChain() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        await viewModel.generateDocumentChain()

        #expect(viewModel.generatedDocuments.count == 3)
        #expect(viewModel.isGenerating == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.generationProgress == 1.0)
    }

    @Test("DocumentExecutionViewModel handles document chain generation error")
    func generateDocumentChainError() async {
        let errorService = createErrorDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: errorService
        )

        await viewModel.generateDocumentChain()

        #expect(viewModel.generatedDocuments.isEmpty)
        #expect(viewModel.isGenerating == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("chain generation error") == true)
    }

    @Test("DocumentExecutionViewModel tracks generation progress")
    func testGenerationProgress() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Initially no progress
        #expect(viewModel.generationProgress == 0.0)
        #expect(viewModel.isGenerating == false)

        // After generation, should show completion
        await viewModel.generateDocument(.sow)
        #expect(viewModel.generationProgress == 1.0)
        #expect(viewModel.isGenerating == false)
    }

    // MARK: - Document Management Tests

    @Test("DocumentExecutionViewModel loads generated documents")
    func testLoadGeneratedDocuments() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        await viewModel.loadGeneratedDocuments()

        // May be empty initially - this is expected behavior
        #expect(viewModel.errorMessage == nil)
    }

    @Test("DocumentExecutionViewModel removes generated document")
    func testRemoveGeneratedDocument() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Generate a document first
        await viewModel.generateDocument(.sow)
        let initialCount = viewModel.generatedDocuments.count

        // Remove the document
        if let document = viewModel.generatedDocuments.first {
            viewModel.removeGeneratedDocument(document)
            #expect(viewModel.generatedDocuments.count == initialCount - 1)
        }
    }

    @Test("DocumentExecutionViewModel clears all generated documents")
    func testClearAllGeneratedDocuments() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Generate some documents first
        await viewModel.generateDocumentChain()
        #expect(!viewModel.generatedDocuments.isEmpty)

        // Clear all documents
        viewModel.clearAllGeneratedDocuments()
        #expect(viewModel.generatedDocuments.isEmpty)
    }

    // MARK: - Document Validation Tests

    @Test("DocumentExecutionViewModel validates generated document")
    func validateGeneratedDocument() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Generate a document first
        await viewModel.generateDocument(.sow)

        // Validate the document
        if let document = viewModel.generatedDocuments.first {
            let isValid = await viewModel.validateDocument(document)
            #expect(isValid == true)
        }
    }

    @Test("DocumentExecutionViewModel handles document validation error")
    func validateDocumentError() async {
        let errorService = createErrorDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: errorService
        )

        guard let testDocument = createMockGeneratedDocuments().first else {
            Issue.record("No test documents available")
            return
        }
        let isValid = await viewModel.validateDocument(testDocument)

        #expect(isValid == false)
    }

    // MARK: - Navigation and UI Tests

    @Test("DocumentExecutionViewModel shows document preview")
    func testShowDocumentPreview() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Generate a document first
        await viewModel.generateDocument(.sow)

        // Show preview
        if let document = viewModel.generatedDocuments.first {
            viewModel.showDocumentPreview(document)
            #expect(viewModel.showingDocumentPreview == true)
            #expect(viewModel.selectedDocumentForPreview?.id == document.id)
        }
    }

    @Test("DocumentExecutionViewModel hides document preview")
    func testHideDocumentPreview() {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Set up preview state
        viewModel.showingDocumentPreview = true
        viewModel.selectedDocumentForPreview = createMockGeneratedDocuments().first

        // Hide preview
        viewModel.hideDocumentPreview()
        #expect(viewModel.showingDocumentPreview == false)
        #expect(viewModel.selectedDocumentForPreview == nil)
    }

    // MARK: - Computed Properties Tests

    @Test("DocumentExecutionViewModel computes has generated documents")
    func testHasGeneratedDocuments() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Initially no documents
        #expect(viewModel.hasGeneratedDocuments == false)

        // After generation
        await viewModel.generateDocument(.sow)
        #expect(viewModel.hasGeneratedDocuments == true)
    }

    @Test("DocumentExecutionViewModel computes generation status text")
    func testGenerationStatusText() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Initially ready
        #expect(viewModel.generationStatusText.contains("Ready") || viewModel.generationStatusText.contains("idle"))

        // After generation
        await viewModel.generateDocument(.sow)
        #expect(viewModel.generationStatusText.contains("Complete") || viewModel.generationStatusText.contains("document"))
    }

    @Test("DocumentExecutionViewModel computes documents by type")
    func testDocumentsByType() async {
        let mockService = createMockDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: mockService
        )

        // Generate different document types
        await viewModel.generateDocument(.sow)
        await viewModel.generateDocument(.pws)
        await viewModel.generateDocument(.qasp)

        let documentsByType = viewModel.documentsByType
        #expect(documentsByType[.sow]?.count == 1)
        #expect(documentsByType[.pws]?.count == 1)
        #expect(documentsByType[.qasp]?.count == 1)
    }

    // MARK: - Error Handling Tests

    @Test("DocumentExecutionViewModel handles service unavailable error")
    func serviceUnavailableError() async {
        let errorService = createErrorDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: errorService
        )

        await viewModel.loadGeneratedDocuments()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("unavailable") == true)
    }

    @Test("DocumentExecutionViewModel clears error message on retry")
    func clearErrorMessageOnRetry() async {
        let errorService = createErrorDocumentService()
        let mockAcquisition = createMockAcquisition()
        let viewModel = DocumentExecutionViewModel(
            acquisition: mockAcquisition,
            documentService: errorService
        )

        // Generate error
        await viewModel.generateDocument(.sow)
        #expect(viewModel.errorMessage != nil)

        // Clear error
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}

// MARK: - Supporting Types for Tests

/// Test-specific validation result
struct TestDocumentValidationResult {
    let isValid: Bool
    let errors: [TestDocumentValidationError]
    let warnings: [TestDocumentValidationWarning]
}

struct TestDocumentValidationError {
    let code: String
    let message: String
}

struct TestDocumentValidationWarning {
    let code: String
    let message: String
}
