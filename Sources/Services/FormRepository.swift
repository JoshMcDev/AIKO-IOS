import Combine
import Foundation

/// Repository for managing government form definitions and templates
final class FormRepository {
    // MARK: - Properties

    private let baseURL = "https://www.gsa.gov/forms"
    private let cacheManager: FormCacheManager
    private let networkService: NetworkService

    // MARK: - Form Definitions

    private let formDefinitions: [FormDefinition] = [
        // SF 18 - Request for Quotations
        FormDefinition(
            formType: .sf18,
            formNumber: "SF 18",
            title: "Request for Quotations",
            revision: "Rev. 6/2024",
            agency: "GSA",
            description: "Used for simplified acquisitions to request quotations from vendors",
            supportedTemplates: [.requestForQuoteSimplified, .requestForQuote],
            requiredFields: [
                "requisitionNumber", "dateIssued", "deliveryDate",
                "itemDescription", "quantity", "unit", "unitPrice",
            ],
            farReference: "FAR 53.213",
            downloadURL: URL(string: "https://www.gsa.gov/forms/sf18.pdf"),
            threshold: 250_000
        ),

        // SF 1449 - Solicitation/Contract/Order for Commercial Products and Commercial Services
        FormDefinition(
            formType: .sf1449,
            formNumber: "SF 1449",
            title: "Solicitation/Contract/Order for Commercial Products and Commercial Services",
            revision: "Rev. 11/2023",
            agency: "GSA",
            description: "Multi-purpose form for commercial acquisitions",
            supportedTemplates: [.contractScaffold, .requestForProposal, .requestForQuote],
            requiredFields: [
                "contractNumber", "solicitationNumber", "dateIssued",
                "requisitionNumber", "deliveryTerms", "paymentTerms",
                "itemDescription", "quantity", "unitPrice", "totalPrice",
            ],
            farReference: "FAR 53.212",
            downloadURL: URL(string: "https://www.gsa.gov/forms/sf1449.pdf"),
            threshold: 7_000_000
        ),

        // SF 30 - Amendment of Solicitation/Modification of Contract
        FormDefinition(
            formType: .sf30,
            formNumber: "SF 30",
            title: "Amendment of Solicitation/Modification of Contract",
            revision: "Rev. 4/2023",
            agency: "GSA",
            description: "Used to amend solicitations or modify contracts",
            supportedTemplates: [.contractScaffold],
            requiredFields: [
                "amendmentNumber", "effectiveDate", "contractNumber",
                "modificationDescription", "changeAmount",
            ],
            farReference: "FAR 53.243",
            downloadURL: URL(string: "https://www.gsa.gov/forms/sf30.pdf"),
            threshold: nil
        ),

        // SF 26 - Award/Contract
        FormDefinition(
            formType: .sf26,
            formNumber: "SF 26",
            title: "Award/Contract",
            revision: "Rev. 10/2023",
            agency: "GSA",
            description: "Award document for negotiated procurements",
            supportedTemplates: [.contractScaffold],
            requiredFields: [
                "contractNumber", "effectiveDate", "contractor",
                "totalAmount", "performancePeriod",
            ],
            farReference: "FAR 53.214",
            downloadURL: URL(string: "https://www.gsa.gov/forms/sf26.pdf"),
            threshold: nil
        ),

        // SF 36 - Continuation Sheet
        FormDefinition(
            formType: .sf36,
            formNumber: "SF 36",
            title: "Continuation Sheet",
            revision: "Rev. 7/2023",
            agency: "GSA",
            description: "Continuation sheet for standard forms",
            supportedTemplates: DocumentType.allCases, // Can be used with any template
            requiredFields: ["referenceNumber", "pageNumber"],
            farReference: "FAR 53.302",
            downloadURL: URL(string: "https://www.gsa.gov/forms/sf36.pdf"),
            threshold: nil
        ),

        // SF 44 - Purchase Order-Invoice-Voucher
        FormDefinition(
            formType: .sf44,
            formNumber: "SF 44",
            title: "Purchase Order-Invoice-Voucher",
            revision: "Rev. 8/2023",
            agency: "GSA",
            description: "Simplified purchase order for micro-purchases",
            supportedTemplates: [.requestForQuote, .requestForQuoteSimplified],
            requiredFields: [
                "orderNumber", "dateOrdered", "vendor",
                "itemDescription", "quantity", "unitPrice", "totalAmount",
            ],
            farReference: "FAR 53.213",
            downloadURL: URL(string: "https://www.gsa.gov/forms/sf44.pdf"),
            threshold: 10000
        ),

        // SF 252 - Architect-Engineer Contract
        FormDefinition(
            formType: .sf252,
            formNumber: "SF 252",
            title: "Architect-Engineer Contract",
            revision: "Rev. 5/2023",
            agency: "GSA",
            description: "Standard form for architect-engineer services",
            supportedTemplates: [.sow, .pws],
            requiredFields: [
                "projectTitle", "projectLocation", "estimatedCost",
                "performancePeriod", "firmName", "services",
            ],
            farReference: "FAR 53.236-2",
            downloadURL: URL(string: "https://www.gsa.gov/forms/sf252.pdf"),
            threshold: nil
        ),

        // SF 1408 - Pre-Award Survey
        FormDefinition(
            formType: .sf1408,
            formNumber: "SF 1408",
            title: "Pre-Award Survey of Prospective Contractor",
            revision: "Rev. 3/2023",
            agency: "GSA",
            description: "Survey to determine contractor responsibility",
            supportedTemplates: [.evaluationPlan],
            requiredFields: [
                "contractorName", "solicitationNumber", "surveyDate",
                "technicalCapability", "productionCapacity", "qualityAssurance",
                "financialCapability", "performanceRecord",
            ],
            farReference: "FAR 53.209",
            downloadURL: URL(string: "https://www.gsa.gov/forms/sf1408.pdf"),
            threshold: nil
        ),
    ]

    // MARK: - Initialization

    init() {
        cacheManager = FormCacheManager()
        networkService = NetworkService.shared
    }

    // MARK: - Public Methods

    /// Load all form definitions
    func loadFormDefinitions() async throws -> [FormDefinition] {
        // Check cache first
        if let cachedForms = cacheManager.getCachedFormDefinitions() {
            return cachedForms
        }

        // Return hardcoded definitions for now
        // In production, this would fetch from the API
        cacheManager.cacheFormDefinitions(formDefinitions)
        return formDefinitions
    }

    /// Generate a blank form as PDF data
    func generateBlankForm(_ formDefinition: FormDefinition) async throws -> Data {
        // Check cache first
        if let cachedForm = cacheManager.getCachedBlankForm(formDefinition.formType) {
            return cachedForm
        }

        // In production, this would download the actual PDF
        // For now, generate a placeholder
        guard let url = formDefinition.downloadURL else {
            throw FormRepositoryError.downloadURLNotAvailable
        }

        // Simulate network request
        let data = try await networkService.downloadData(from: url)

        // Cache the result
        cacheManager.cacheBlankForm(data, for: formDefinition.formType)

        return data
    }

    /// Get preview URL for a form
    func getPreviewURL(for formType: FormType) -> URL? {
        formDefinitions.first { $0.formType == formType }?.downloadURL
    }

    /// Search forms by criteria
    func searchForms(query: String) -> [FormDefinition] {
        let lowercasedQuery = query.lowercased()
        return formDefinitions.filter { form in
            form.title.lowercased().contains(lowercasedQuery) ||
                form.formNumber.lowercased().contains(lowercasedQuery) ||
                form.description.lowercased().contains(lowercasedQuery)
        }
    }

    /// Get forms by threshold
    func getFormsByThreshold(_ amount: Double) -> [FormDefinition] {
        formDefinitions.filter { form in
            guard let threshold = form.threshold else { return true }
            return amount <= threshold
        }
    }
}

// MARK: - Supporting Types

enum FormRepositoryError: LocalizedError {
    case downloadURLNotAvailable
    case networkError(Error)
    case invalidFormData

    var errorDescription: String? {
        switch self {
        case .downloadURLNotAvailable:
            "Download URL not available for this form"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case .invalidFormData:
            "Invalid form data received"
        }
    }
}

// MARK: - Form Cache Manager

final class FormCacheManager {
    private let cache = NSCache<NSString, NSData>()
    private let definitionsKey = "form_definitions"

    func getCachedFormDefinitions() -> [FormDefinition]? {
        // Implementation would retrieve from persistent storage
        nil
    }

    func cacheFormDefinitions(_: [FormDefinition]) {
        // Implementation would persist to storage
    }

    func getCachedBlankForm(_ formType: FormType) -> Data? {
        cache.object(forKey: formType.rawValue as NSString) as Data?
    }

    func cacheBlankForm(_ data: Data, for formType: FormType) {
        cache.setObject(data as NSData, forKey: formType.rawValue as NSString)
    }
}
