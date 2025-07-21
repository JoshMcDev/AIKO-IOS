import AppCore
import ComposableArchitecture
import Foundation

// MARK: - Document Dependency Service

public struct DocumentDependencyService: Sendable {
    public var getDependencies: @Sendable (DocumentType) -> [DocumentDependency]
    public var getRequiredDocuments: @Sendable (DocumentType) -> [DocumentType]
    public var getDataFlow: @Sendable (DocumentType, DocumentType) -> [String]
    public var suggestNextDocuments: @Sendable ([DocumentType], CollectedData) -> [DocumentType]
    public var validateDependencies: @Sendable ([GeneratedDocument], DocumentType) -> DependencyValidation
    public var extractDataForDependents: @Sendable (GeneratedDocument) -> CollectedData

    public init(
        getDependencies: @escaping @Sendable (DocumentType) -> [DocumentDependency],
        getRequiredDocuments: @escaping @Sendable (DocumentType) -> [DocumentType],
        getDataFlow: @escaping @Sendable (DocumentType, DocumentType) -> [String],
        suggestNextDocuments: @escaping @Sendable ([DocumentType], CollectedData) -> [DocumentType],
        validateDependencies: @escaping @Sendable ([GeneratedDocument], DocumentType) -> DependencyValidation,
        extractDataForDependents: @escaping @Sendable (GeneratedDocument) -> CollectedData
    ) {
        self.getDependencies = getDependencies
        self.getRequiredDocuments = getRequiredDocuments
        self.getDataFlow = getDataFlow
        self.suggestNextDocuments = suggestNextDocuments
        self.validateDependencies = validateDependencies
        self.extractDataForDependents = extractDataForDependents
    }
}

// MARK: - Dependency Validation

public struct DependencyValidation: Equatable, Sendable {
    public let isValid: Bool
    public let missingDocuments: [DocumentType]
    public let missingFields: [String]
    public let warnings: [String]

    public init(
        isValid: Bool,
        missingDocuments: [DocumentType] = [],
        missingFields: [String] = [],
        warnings: [String] = []
    ) {
        self.isValid = isValid
        self.missingDocuments = missingDocuments
        self.missingFields = missingFields
        self.warnings = warnings
    }
}

// MARK: - Document Dependency Definitions

extension DocumentDependencyService: DependencyKey {
    public nonisolated static var liveValue: DocumentDependencyService {
        // Define the dependency graph
        let dependencyGraph = buildDependencyGraph()

        return DocumentDependencyService(
            getDependencies: { documentType in
                dependencyGraph[documentType] ?? []
            },

            getRequiredDocuments: { documentType in
                dependencyGraph[documentType]?
                    .filter(\.isRequired)
                    .map(\.sourceDocumentType) ?? []
            },

            getDataFlow: { fromDocument, toDocument in
                dependencyGraph[toDocument]?
                    .first { $0.sourceDocumentType == fromDocument }?
                    .dataFields ?? []
            },

            suggestNextDocuments: { existingDocuments, _ in
                // Analyze what documents would benefit from the current data
                var suggestions: [DocumentType] = []
                let existingSet = Set(existingDocuments)

                // Check each document type to see if we have its dependencies
                for (docType, dependencies) in dependencyGraph {
                    guard !existingSet.contains(docType) else { continue }

                    let requiredDeps = dependencies.filter(\.isRequired)
                    let hasAllRequired = requiredDeps.allSatisfy { dep in
                        existingSet.contains(dep.sourceDocumentType)
                    }

                    if hasAllRequired {
                        suggestions.append(docType)
                    }
                }

                // Prioritize based on typical workflow order
                return suggestions.sorted { a, b in
                    workflowOrder(a) < workflowOrder(b)
                }
            },

            validateDependencies: { existingDocuments, targetDocument in
                let dependencies = dependencyGraph[targetDocument] ?? []
                let existingTypes = Set(existingDocuments.compactMap(\.documentType))

                var missingDocuments: [DocumentType] = []
                var missingFields: [String] = []
                var warnings: [String] = []

                for dependency in dependencies {
                    if !existingTypes.contains(dependency.sourceDocumentType) {
                        if dependency.isRequired {
                            missingDocuments.append(dependency.sourceDocumentType)
                        } else {
                            warnings.append("Optional dependency \(dependency.sourceDocumentType.shortName) not found")
                        }
                    } else {
                        // Check if required fields are available
                        if let sourceDoc = existingDocuments.first(where: { $0.documentType == dependency.sourceDocumentType }) {
                            let extractedData = extractDataFromDocument(sourceDoc)
                            for field in dependency.dataFields {
                                if extractedData.data[field] == nil || extractedData.data[field]?.isEmpty == true {
                                    missingFields.append("\(field) from \(dependency.sourceDocumentType.shortName)")
                                }
                            }
                        }
                    }
                }

                let isValid = missingDocuments.isEmpty && missingFields.isEmpty

                return DependencyValidation(
                    isValid: isValid,
                    missingDocuments: missingDocuments,
                    missingFields: missingFields,
                    warnings: warnings
                )
            },

            extractDataForDependents: { document in
                extractDataFromDocument(document)
            }
        )
    }
}

// MARK: - Helper Functions

private func buildDependencyGraph() -> [DocumentType: [DocumentDependency]] {
    var graph: [DocumentType: [DocumentDependency]] = [:]

    // Market Research Report dependencies
    graph[.marketResearch] = []

    // Acquisition Plan dependencies
    graph[.acquisitionPlan] = [
        DocumentDependency(
            sourceDocumentType: .marketResearch,
            targetDocumentType: .acquisitionPlan,
            dataFields: ["market_analysis", "vendor_capabilities", "cost_estimates"],
            isRequired: false
        )
    ]

    // SOW/SOO/PWS dependencies
    graph[.sow] = [
        DocumentDependency(
            sourceDocumentType: .marketResearch,
            targetDocumentType: .sow,
            dataFields: ["technical_requirements", "industry_standards"],
            isRequired: false
        ),
        DocumentDependency(
            sourceDocumentType: .acquisitionPlan,
            targetDocumentType: .sow,
            dataFields: ["acquisition_strategy", "timeline", "deliverables"],
            isRequired: false
        )
    ]

    graph[.soo] = [
        DocumentDependency(
            sourceDocumentType: .acquisitionPlan,
            targetDocumentType: .soo,
            dataFields: ["objectives", "desired_outcomes"],
            isRequired: false
        )
    ]

    graph[.pws] = [
        DocumentDependency(
            sourceDocumentType: .acquisitionPlan,
            targetDocumentType: .pws,
            dataFields: ["performance_standards", "metrics"],
            isRequired: false
        )
    ]

    // QASP dependencies
    graph[.qasp] = [
        DocumentDependency(
            sourceDocumentType: .pws,
            targetDocumentType: .qasp,
            dataFields: ["performance_standards", "quality_metrics", "surveillance_methods"],
            isRequired: true
        ),
        DocumentDependency(
            sourceDocumentType: .sow,
            targetDocumentType: .qasp,
            dataFields: ["deliverables", "acceptance_criteria"],
            isRequired: false
        )
    ]

    // Cost Estimate dependencies
    graph[.costEstimate] = [
        DocumentDependency(
            sourceDocumentType: .sow,
            targetDocumentType: .costEstimate,
            dataFields: ["deliverables", "timeline", "labor_categories"],
            isRequired: true
        ),
        DocumentDependency(
            sourceDocumentType: .marketResearch,
            targetDocumentType: .costEstimate,
            dataFields: ["market_rates", "vendor_pricing"],
            isRequired: false
        )
    ]

    // Evaluation Plan dependencies
    graph[.evaluationPlan] = [
        DocumentDependency(
            sourceDocumentType: .sow,
            targetDocumentType: .evaluationPlan,
            dataFields: ["technical_requirements", "evaluation_factors"],
            isRequired: true
        ),
        DocumentDependency(
            sourceDocumentType: .acquisitionPlan,
            targetDocumentType: .evaluationPlan,
            dataFields: ["acquisition_strategy", "source_selection_method"],
            isRequired: false
        )
    ]

    // RFQ/RFP dependencies
    graph[.requestForQuote] = [
        DocumentDependency(
            sourceDocumentType: .sow,
            targetDocumentType: .requestForQuote,
            dataFields: ["deliverables", "timeline", "requirements"],
            isRequired: true
        ),
        DocumentDependency(
            sourceDocumentType: .costEstimate,
            targetDocumentType: .requestForQuote,
            dataFields: ["estimated_value", "pricing_structure"],
            isRequired: false
        ),
        DocumentDependency(
            sourceDocumentType: .evaluationPlan,
            targetDocumentType: .requestForQuote,
            dataFields: ["evaluation_criteria", "submission_requirements"],
            isRequired: true
        )
    ]

    graph[.requestForProposal] = [
        DocumentDependency(
            sourceDocumentType: .sow,
            targetDocumentType: .requestForProposal,
            dataFields: ["statement_of_work", "technical_requirements"],
            isRequired: true
        ),
        DocumentDependency(
            sourceDocumentType: .evaluationPlan,
            targetDocumentType: .requestForProposal,
            dataFields: ["evaluation_criteria", "technical_factors", "past_performance"],
            isRequired: true
        ),
        DocumentDependency(
            sourceDocumentType: .costEstimate,
            targetDocumentType: .requestForProposal,
            dataFields: ["budget_range", "cost_evaluation_factors"],
            isRequired: false
        )
    ]

    // Contract dependencies
    graph[.contractScaffold] = [
        DocumentDependency(
            sourceDocumentType: .requestForQuote,
            targetDocumentType: .contractScaffold,
            dataFields: ["terms_conditions", "pricing", "delivery_schedule"],
            isRequired: false
        ),
        DocumentDependency(
            sourceDocumentType: .requestForProposal,
            targetDocumentType: .contractScaffold,
            dataFields: ["contract_type", "terms", "clauses"],
            isRequired: false
        ),
        DocumentDependency(
            sourceDocumentType: .sow,
            targetDocumentType: .contractScaffold,
            dataFields: ["performance_requirements", "deliverables"],
            isRequired: true
        )
    ]

    // COR Appointment dependencies
    graph[.corAppointment] = [
        DocumentDependency(
            sourceDocumentType: .contractScaffold,
            targetDocumentType: .corAppointment,
            dataFields: ["contract_number", "contractor_name", "period_of_performance"],
            isRequired: true
        ),
        DocumentDependency(
            sourceDocumentType: .qasp,
            targetDocumentType: .corAppointment,
            dataFields: ["surveillance_duties", "reporting_requirements"],
            isRequired: false
        )
    ]

    return graph
}

private func workflowOrder(_ documentType: DocumentType) -> Int {
    switch documentType {
    case .marketResearch: 1
    case .acquisitionPlan: 2
    case .sow, .soo, .pws: 3
    case .qasp: 4
    case .costEstimate: 5
    case .evaluationPlan: 6
    case .fiscalLawReview, .opsecReview: 7
    case .industryRFI, .sourcesSought: 8
    case .justificationApproval: 9
    case .codes: 10
    case .competitionAnalysis: 11
    case .procurementSourcing: 12
    case .rrd: 13
    case .requestForQuoteSimplified, .requestForQuote, .requestForProposal: 14
    case .contractScaffold: 15
    case .corAppointment: 16
    case .analytics: 17
    case .otherTransactionAgreement: 18
    case .farUpdates: 19
    }
}

private func extractDataFromDocument(_ document: GeneratedDocument) -> CollectedData {
    var extractedData = CollectedData()

    // Extract key data based on document type
    // This would be enhanced with actual parsing logic
    switch document.documentType {
    case .marketResearch:
        extractedData["market_analysis"] = "Market analysis from \(document.title)"
        extractedData["vendor_capabilities"] = "Vendor capabilities identified"
        extractedData["cost_estimates"] = "Preliminary cost estimates"

    case .sow:
        extractedData["deliverables"] = "Extracted deliverables"
        extractedData["timeline"] = "Project timeline"
        extractedData["requirements"] = "Technical requirements"
        extractedData["labor_categories"] = "Labor categories"

    case .costEstimate:
        extractedData["estimated_value"] = "Total estimated cost"
        extractedData["pricing_structure"] = "Pricing breakdown"
        extractedData["budget_range"] = "Budget range"

    case .evaluationPlan:
        extractedData["evaluation_criteria"] = "Technical evaluation criteria"
        extractedData["submission_requirements"] = "Proposal submission requirements"
        extractedData["technical_factors"] = "Technical evaluation factors"

    default:
        // Extract generic data
        extractedData["document_type"] = document.documentType?.rawValue ?? "Unknown"
        extractedData["created_date"] = document.createdAt.description
    }

    return extractedData
}

public extension DependencyValues {
    var documentDependencyService: DocumentDependencyService {
        get { self[DocumentDependencyService.self] }
        set { self[DocumentDependencyService.self] = newValue }
    }
}
