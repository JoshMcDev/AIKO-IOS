import Foundation

public enum DocumentCategory: String, CaseIterable {
    case requirements = "Requirements Studio"
    case marketIntelligence = "Market Intelligence"
    case planning = "Acquisition Planning"
    case determinationFindings = "Determination & Findings"
    case solicitation = "Solicitation"
    case award = "Award"
    case analytics = "Analytics"
    
    public var icon: String {
        switch self {
        case .requirements: return "doc.text"
        case .marketIntelligence: return "magnifyingglass"
        case .planning: return "calendar"
        case .determinationFindings: return "checkmark.shield"
        case .solicitation: return "envelope"
        case .award: return "rosette"
        case .analytics: return "chart.bar"
        }
    }
    
    public var description: String {
        switch self {
        case .requirements: return "Define and refine acquisition requirements"
        case .marketIntelligence: return "Research market and analyze competition"
        case .planning: return "Strategic acquisition planning documents"
        case .determinationFindings: return "Justify acquisition decisions and approvals"
        case .solicitation: return "Request quotes and proposals from vendors"
        case .award: return "Contract award and administration"
        case .analytics: return "Performance metrics and data analysis"
        }
    }
    
    public static func category(for documentType: DocumentType) -> DocumentCategory? {
        switch documentType {
        case .rrd, .soo, .sow, .pws, .qasp:
            return .requirements
        case .marketResearch, .codes, .competitionAnalysis, .industryRFI, .sourcesSought, .costEstimate, .procurementSourcing:
            return .marketIntelligence
        case .acquisitionPlan, .evaluationPlan, .fiscalLawReview, .opsecReview, .justificationApproval:
            return .planning
        case .requestForQuoteSimplified, .requestForQuote, .requestForProposal:
            return .solicitation
        case .contractScaffold, .corAppointment:
            return .award
        case .analytics:
            return .analytics
        case .otherTransactionAgreement:
            return .award
        }
    }
    
    public func contains(_ documentType: DocumentType) -> Bool {
        return DocumentCategory.category(for: documentType) == self
    }
    
    public var documentTypes: [DocumentType] {
        switch self {
        case .requirements:
            return [.rrd, .soo, .sow, .pws, .qasp]
        case .marketIntelligence:
            return [.marketResearch, .codes, .competitionAnalysis, .industryRFI, .sourcesSought, .costEstimate, .procurementSourcing]
        case .planning:
            return [.acquisitionPlan, .evaluationPlan, .fiscalLawReview, .opsecReview, .justificationApproval]
        case .determinationFindings:
            return [] // D&F documents are handled through DFDocumentType
        case .solicitation:
            return [.requestForQuoteSimplified, .requestForQuote, .requestForProposal]
        case .award:
            return [.contractScaffold, .corAppointment, .otherTransactionAgreement]
        case .analytics:
            return [.analytics]
        }
    }
}