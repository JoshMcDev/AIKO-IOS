import Foundation
import ComposableArchitecture

/// Service for loading standard document templates
public struct StandardTemplateService {
    public var loadTemplate: (DocumentType) async throws -> String
    public var loadQuickReference: (DocumentType) async throws -> String?
    
    public init(
        loadTemplate: @escaping (DocumentType) async throws -> String,
        loadQuickReference: @escaping (DocumentType) async throws -> String?
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
        case .templateNotFound(let type):
            return "Template not found for document type: \(type)"
        case .fileReadError(let error):
            return "Error reading template file: \(error)"
        case .unsupportedDocumentType(let type):
            return "Unsupported document type: \(type)"
        }
    }
}

// MARK: - Dependency Implementation
extension StandardTemplateService: DependencyKey {
    public static var liveValue: StandardTemplateService {
        StandardTemplateService(
            loadTemplate: { documentType in
                let templateFileName: String
                
                // Map document type to template file name
                switch documentType {
                case .sow:
                    templateFileName = "SOW"
                case .pws:
                    templateFileName = "PWS"
                case .soo:
                    templateFileName = "SOO"
                case .qasp:
                    templateFileName = "QASP"
                case .costEstimate:
                    templateFileName = "IGCE"
                case .marketResearch:
                    templateFileName = "MarketResearchReport"
                case .acquisitionPlan:
                    templateFileName = "AcquisitionPlan"
                case .evaluationPlan:
                    templateFileName = "EvaluationPlan"
                case .fiscalLawReview:
                    templateFileName = "FiscalLawReview"
                case .opsecReview:
                    templateFileName = "OPSECReview"
                case .industryRFI:
                    templateFileName = "IndustryRFI"
                case .sourcesSought:
                    templateFileName = "SourcesSought"
                case .justificationApproval:
                    templateFileName = "JustificationApproval"
                case .codes:
                    templateFileName = "Codes"
                case .competitionAnalysis:
                    templateFileName = "CompetitionAnalysis"
                case .procurementSourcing:
                    templateFileName = "ProcurementSourcing"
                case .rrd:
                    templateFileName = "RRD"
                case .requestForQuoteSimplified:
                    templateFileName = "RFQSimplified"
                case .requestForQuote:
                    templateFileName = "RFQ"
                case .requestForProposal:
                    templateFileName = "RFP"
                case .contractScaffold:
                    templateFileName = "Contract"
                case .corAppointment:
                    templateFileName = "CORAppointment"
                case .analytics:
                    templateFileName = "Analytics"
                case .otherTransactionAgreement:
                    templateFileName = "OTAgreement"
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
            
            loadQuickReference: { documentType in
                // Standard documents don't have separate quick reference guides
                // They may have inline guidance within the templates
                // Return nil for now, but this could be extended in the future
                return nil
            }
        )
    }
    
    public static var testValue: StandardTemplateService {
        StandardTemplateService(
            loadTemplate: { documentType in
                // Return a simple test template
                return """
                # TEST TEMPLATE FOR \(documentType.rawValue.uppercased())
                
                **Project Title:** {{PROJECT_TITLE}}
                **Date:** {{DATE}}
                
                ## Test Content
                This is a test template for \(documentType.rawValue).
                """
            },
            
            loadQuickReference: { _ in
                return nil
            }
        )
    }
}

// MARK: - DependencyValues Extension
extension DependencyValues {
    public var standardTemplateService: StandardTemplateService {
        get { self[StandardTemplateService.self] }
        set { self[StandardTemplateService.self] = newValue }
    }
}

// MARK: - Helper Methods
extension StandardTemplateService {
    /// Get the file name for a document type
    public static func templateFileName(for documentType: DocumentType) -> String? {
        switch documentType {
        case .sow: return "SOW"
        case .pws: return "PWS"
        case .soo: return "SOO"
        case .qasp: return "QASP"
        case .costEstimate: return "IGCE"
        case .marketResearch: return "MarketResearchReport"
        case .acquisitionPlan: return "AcquisitionPlan"
        case .evaluationPlan: return "EvaluationPlan"
        case .fiscalLawReview: return "FiscalLawReview"
        case .opsecReview: return "OPSECReview"
        case .industryRFI: return "IndustryRFI"
        case .sourcesSought: return "SourcesSought"
        case .justificationApproval: return "JustificationApproval"
        case .codes: return "Codes"
        case .competitionAnalysis: return "CompetitionAnalysis"
        case .procurementSourcing: return "ProcurementSourcing"
        case .rrd: return "RRD"
        case .requestForQuoteSimplified: return "RFQSimplified"
        case .requestForQuote: return "RFQ"
        case .requestForProposal: return "RFP"
        case .contractScaffold: return "Contract"
        case .corAppointment: return "CORAppointment"
        case .analytics: return "Analytics"
        case .otherTransactionAgreement: return "OTAgreement"
        }
    }
    
    /// Check if a template exists for a document type
    public static func hasTemplate(for documentType: DocumentType) -> Bool {
        guard let fileName = templateFileName(for: documentType) else { return false }
        
        let bundle = Bundle.module
        return bundle.url(
            forResource: fileName,
            withExtension: "md",
            subdirectory: "Templates"
        ) != nil
    }
}