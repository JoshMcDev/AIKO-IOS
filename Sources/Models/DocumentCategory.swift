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
        case .requirements: "doc.text"
        case .marketIntelligence: "magnifyingglass"
        case .planning: "calendar"
        case .determinationFindings: "checkmark.shield"
        case .solicitation: "envelope"
        case .award: "rosette"
        case .analytics: "chart.bar"
        }
    }

    public var description: String {
        switch self {
        case .requirements: "Define and refine acquisition requirements"
        case .marketIntelligence: "Research market and analyze competition"
        case .planning: "Strategic acquisition planning documents"
        case .determinationFindings: "Justify acquisition decisions and approvals"
        case .solicitation: "Request quotes and proposals from vendors"
        case .award: "Contract award and administration"
        case .analytics: "Performance metrics and data analysis"
        }
    }

    public static func category(for documentType: DocumentType) -> DocumentCategory? {
        switch documentType {
        case .rrd, .soo, .sow, .pws, .qasp:
            .requirements
        case .marketResearch, .codes, .competitionAnalysis, .industryRFI, .sourcesSought, .costEstimate, .procurementSourcing:
            .marketIntelligence
        case .acquisitionPlan, .evaluationPlan, .fiscalLawReview, .opsecReview, .justificationApproval:
            .planning
        case .requestForQuoteSimplified, .requestForQuote, .requestForProposal:
            .solicitation
        case .contractScaffold, .corAppointment:
            .award
        case .analytics:
            .analytics
        case .otherTransactionAgreement:
            .award
        }
    }

    public func contains(_ documentType: DocumentType) -> Bool {
        DocumentCategory.category(for: documentType) == self
    }

    public var documentTypes: [DocumentType] {
        switch self {
        case .requirements:
            [.rrd, .soo, .sow, .pws, .qasp]
        case .marketIntelligence:
            [.marketResearch, .codes, .competitionAnalysis, .industryRFI, .sourcesSought, .costEstimate, .procurementSourcing]
        case .planning:
            [.acquisitionPlan, .evaluationPlan, .fiscalLawReview, .opsecReview, .justificationApproval]
        case .determinationFindings:
            [] // D&F documents are handled through DFDocumentType
        case .solicitation:
            [.requestForQuoteSimplified, .requestForQuote, .requestForProposal]
        case .award:
            [.contractScaffold, .corAppointment, .otherTransactionAgreement]
        case .analytics:
            [.analytics]
        }
    }
}
