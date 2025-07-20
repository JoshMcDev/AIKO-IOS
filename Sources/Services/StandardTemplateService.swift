import AppCore
import ComposableArchitecture
import Foundation

/// Service for loading standard document templates
public struct StandardTemplateService: Sendable {
    public var loadTemplate: @Sendable (DocumentType) async throws -> String
    public var loadQuickReference: @Sendable (DocumentType) async throws -> String?

    public init(
        loadTemplate: @escaping @Sendable (DocumentType) async throws -> String,
        loadQuickReference: @escaping @Sendable (DocumentType) async throws -> String?
    ) {
        self.loadTemplate = loadTemplate
        self.loadQuickReference = loadQuickReference
    }
}

// MARK: - Error Types

public enum StandardTemplateError: Error, LocalizedError {
    case templateNotFound(String)
    case fileReadError(String)
    case unsupportedDocumentType(String)

    public var errorDescription: String? {
        switch self {
        case let .templateNotFound(type):
            "Template not found for document type: \(type)"
        case let .fileReadError(error):
            "Error reading template file: \(error)"
        case let .unsupportedDocumentType(type):
            "Unsupported document type: \(type)"
        }
    }
}

// MARK: - Dependency Implementation

extension StandardTemplateService: DependencyKey {
    public static var liveValue: StandardTemplateService {
        StandardTemplateService(
            loadTemplate: { documentType in
                let templateFileName

                    // Map document type to template file name
                    = switch documentType
                {
                case .sow:
                    "SOW"
                case .pws:
                    "PWS"
                case .soo:
                    "SOO"
                case .qasp:
                    "QASP"
                case .costEstimate:
                    "IGCE"
                case .marketResearch:
                    "MarketResearchReport"
                case .acquisitionPlan:
                    "AcquisitionPlan"
                case .evaluationPlan:
                    "EvaluationPlan"
                case .fiscalLawReview:
                    "FiscalLawReview"
                case .opsecReview:
                    "OPSECReview"
                case .industryRFI:
                    "IndustryRFI"
                case .sourcesSought:
                    "SourcesSought"
                case .justificationApproval:
                    "JustificationApproval"
                case .codes:
                    "Codes"
                case .competitionAnalysis:
                    "CompetitionAnalysis"
                case .procurementSourcing:
                    "ProcurementSourcing"
                case .rrd:
                    "RRD"
                case .requestForQuoteSimplified:
                    "RFQSimplified"
                case .requestForQuote:
                    "RFQ"
                case .requestForProposal:
                    "RFP"
                case .contractScaffold:
                    "Contract"
                case .corAppointment:
                    "CORAppointment"
                case .analytics:
                    "Analytics"
                case .otherTransactionAgreement:
                    "OTAgreement"
                case .farUpdates:
                    "FARUpdates"
                }

                // Load template from bundle
                let bundle = Bundle.module
                guard let templateURL = bundle.url(
                    forResource: templateFileName,
                    withExtension: "md",
                    subdirectory: "Templates"
                ) else {
                    throw StandardTemplateError.templateNotFound(documentType.rawValue)
                }

                do {
                    let templateContent = try String(contentsOf: templateURL, encoding: .utf8)
                    return templateContent
                } catch {
                    throw StandardTemplateError.fileReadError(error.localizedDescription)
                }
            },

            loadQuickReference: { _ in
                // Standard documents don't have separate quick reference guides
                // They may have inline guidance within the templates
                // Return nil for now, but this could be extended in the future
                nil
            }
        )
    }

    public static var testValue: StandardTemplateService {
        StandardTemplateService(
            loadTemplate: { documentType in
                // Return a simple test template
                """
                # TEST TEMPLATE FOR \(documentType.rawValue.uppercased())

                **Project Title:** {{PROJECT_TITLE}}
                **Date:** {{DATE}}

                ## Test Content
                This is a test template for \(documentType.rawValue).
                """
            },

            loadQuickReference: { _ in
                nil
            }
        )
    }
}

// MARK: - DependencyValues Extension

public extension DependencyValues {
    var standardTemplateService: StandardTemplateService {
        get { self[StandardTemplateService.self] }
        set { self[StandardTemplateService.self] = newValue }
    }
}

// MARK: - Helper Methods

public extension StandardTemplateService {
    /// Get the file name for a document type
    static func templateFileName(for documentType: DocumentType) -> String? {
        switch documentType {
        case .sow: "SOW"
        case .pws: "PWS"
        case .soo: "SOO"
        case .qasp: "QASP"
        case .costEstimate: "IGCE"
        case .marketResearch: "MarketResearchReport"
        case .acquisitionPlan: "AcquisitionPlan"
        case .evaluationPlan: "EvaluationPlan"
        case .fiscalLawReview: "FiscalLawReview"
        case .opsecReview: "OPSECReview"
        case .industryRFI: "IndustryRFI"
        case .sourcesSought: "SourcesSought"
        case .justificationApproval: "JustificationApproval"
        case .codes: "Codes"
        case .competitionAnalysis: "CompetitionAnalysis"
        case .procurementSourcing: "ProcurementSourcing"
        case .rrd: "RRD"
        case .requestForQuoteSimplified: "RFQSimplified"
        case .requestForQuote: "RFQ"
        case .requestForProposal: "RFP"
        case .contractScaffold: "Contract"
        case .corAppointment: "CORAppointment"
        case .analytics: "Analytics"
        case .otherTransactionAgreement: "OTAgreement"
        case .farUpdates: "FARUpdates"
        }
    }

    /// Check if a template exists for a document type
    static func hasTemplate(for documentType: DocumentType) -> Bool {
        guard let fileName = templateFileName(for: documentType) else { return false }

        let bundle = Bundle.module
        return bundle.url(
            forResource: fileName,
            withExtension: "md",
            subdirectory: "Templates"
        ) != nil
    }
}
