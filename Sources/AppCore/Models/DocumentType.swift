import Foundation

// NSAttributedString already conforms to Equatable in Foundation

public enum DocumentType: String, CaseIterable, Identifiable, Codable, Sendable {
    case sow = "Statement of Work"
    case soo = "Statement of Objectives"
    case pws = "Performance Work Statement"
    case qasp = "Quality Assurance Surveillance Plan"
    case costEstimate = "Independent Government Cost Estimate"
    case marketResearch = "Market Research Report"
    case acquisitionPlan = "Acquisition Plan"
    case evaluationPlan = "Evaluation Plan"
    case fiscalLawReview = "Fiscal Law Review"
    case opsecReview = "OPSEC Review"
    case industryRFI = "Industry RFI"
    case sourcesSought = "Sources Sought"
    case justificationApproval = "Justification & Approval"
    case codes = "NAICS & PSC"
    case competitionAnalysis = "Competition Analysis"
    case procurementSourcing = "Recommended Vendors"
    case rrd = "Refined Requirement Document"
    case requestForQuoteSimplified = "Request for Quote_Simplified"
    case requestForQuote = "Request for Quote"
    case requestForProposal = "Request for Proposal"
    case contractScaffold = "Contract"
    case corAppointment = "COR Appointment"
    case analytics = "Analytics"
    case otherTransactionAgreement = "Other Transaction Agreement"
    case farUpdates = "FAR Updates"

    public var id: String { rawValue }

    public var shortName: String {
        switch self {
        case .sow: "Statement of Work"
        case .soo: "Statement of Objectives"
        case .pws: "Performance Work Statement"
        case .qasp: "QASP"
        case .costEstimate: "Independent Government Cost Estimate"
        case .marketResearch: "Market Research Report"
        case .acquisitionPlan: "Acquisition Plan"
        case .evaluationPlan: "Evaluation Plan"
        case .fiscalLawReview: "Fiscal Law Review"
        case .opsecReview: "OPSEC Review"
        case .industryRFI: "Industry RFI"
        case .sourcesSought: "Sources Sought"
        case .justificationApproval: "Justification & Approval"
        case .codes: "NAICS & PSC"
        case .competitionAnalysis: "Competition Analysis"
        case .procurementSourcing: "Recommended Vendors"
        case .rrd: "Refined Requirement Document"
        case .requestForQuoteSimplified: "Request for Quote_Simplified"
        case .requestForQuote: "Request for Quote_Expanded"
        case .requestForProposal: "Request for Proposal"
        case .contractScaffold: "Contract"
        case .corAppointment: "COR Appointment"
        case .analytics: "Analytics"
        case .otherTransactionAgreement: "OT Agreement"
        case .farUpdates: "FAR Updates"
        }
    }

    public var description: String {
        switch self {
        case .sow: "Detailed scope, deliverables, and timeline"
        case .soo: "High-level objectives for contractor innovation"
        case .pws: "Performance-based requirements and metrics"
        case .qasp: "QASP monitoring and quality standards"
        case .costEstimate: "IGCE with detailed cost breakdown"
        case .marketResearch: "Market analysis and vendor capability assessment"
        case .acquisitionPlan: "Comprehensive acquisition strategy and milestones"
        case .evaluationPlan: "Evaluation criteria and methodology for commercial items"
        case .fiscalLawReview: "Legal review for fiscal compliance"
        case .opsecReview: "Operations security assessment and requirements"
        case .industryRFI: "Request for Information from industry partners"
        case .sourcesSought: "Notice seeking capable sources for requirement"
        case .justificationApproval: "Justification for other than full and open competition"
        case .codes: "NAICS, PSC codes and small business size standards"
        case .competitionAnalysis: "Analysis of competition strategy and acquisition approach"
        case .procurementSourcing: "Recommended vendors with contact information and capabilities"
        case .rrd: "Interactive requirements definition and refinement process"
        case .requestForQuoteSimplified: "Simplified oral RFQ for quick procurement"
        case .requestForQuote: "Request for Quote for commercial items or services"
        case .requestForProposal: "Request for Proposal for complex requirements"
        case .contractScaffold: "Contract framework and structure for award documents"
        case .corAppointment: "Contracting Officer's Representative appointment letter"
        case .analytics: "Procurement analytics and performance metrics dashboard"
        case .otherTransactionAgreement: "Other Transaction Agreement for prototype projects under 10 U.S.C. § 2371b"
        case .farUpdates: "Federal Acquisition Regulation updates and their impacts"
        }
    }

    public var icon: String {
        switch self {
        case .sow: "doc.text"
        case .soo: "lightbulb"
        case .pws: "chart.line.uptrend.xyaxis"
        case .qasp: "checkmark.shield"
        case .costEstimate: "dollarsign.circle"
        case .marketResearch: "magnifyingglass.circle"
        case .acquisitionPlan: "calendar.badge.plus"
        case .evaluationPlan: "checklist"
        case .fiscalLawReview: "scalemass"
        case .opsecReview: "lock.shield"
        case .industryRFI: "questionmark.bubble"
        case .sourcesSought: "person.3.sequence"
        case .justificationApproval: "doc.badge.ellipsis"
        case .codes: "number.square"
        case .competitionAnalysis: "chart.pie"
        case .procurementSourcing: "person.crop.square.filled.and.at.rectangle"
        case .rrd: "questionmark.app"
        case .requestForQuoteSimplified: "envelope.badge"
        case .requestForQuote: "envelope.badge.fill"
        case .requestForProposal: "envelope.open.fill"
        case .contractScaffold: "doc.on.doc.fill"
        case .corAppointment: "person.crop.circle.badge.checkmark"
        case .analytics: "chart.bar.xaxis"
        case .otherTransactionAgreement: "sparkles.rectangle.stack"
        case .farUpdates: "arrow.triangle.2.circlepath.circle.fill"
        }
    }

    public var isProFeature: Bool {
        false // All features unlocked
    }

    /// Get comprehensive FAR reference information
    public var comprehensiveFARReference: ComprehensiveFARReference? {
        // Platform implementations will provide actual FAR reference service
        // For now, return nil - this will be overridden in platform-specific code
        nil
    }

    /// Get formatted FAR/DFAR references for display
    public var formattedFARReferences: String {
        // Platform implementations will provide actual FAR reference formatting
        // For now, return the basic farReference
        farReference
    }

    public var farReference: String {
        switch self {
        case .sow: "FAR 11.101, 11.102, 37.602"
        case .soo: "FAR 11.101, 11.002, 37.602-4"
        case .pws: "FAR 11.101, 37.601, 37.602"
        case .qasp: "FAR 46.401, 46.103, 46.407, 37.604"
        case .costEstimate: "FAR 7.105(b)(20)(iv), 15.404-1, 36.203"
        case .marketResearch: "FAR 10.001, 10.002, 11.002"
        case .acquisitionPlan: "FAR 7.102, 7.103, 7.104, 7.105"
        case .evaluationPlan: "FAR 15.304, 15.305, 15.101"
        case .fiscalLawReview: "31 U.S.C. 1341, 1301, 1502"
        case .opsecReview: "DoD 5205.02, FAR 4.402, 24.202"
        case .industryRFI: "FAR 15.201, 15.202, 10.002(b)(2)"
        case .sourcesSought: "FAR 10.002(b)(2), 5.205"
        case .justificationApproval: "FAR 6.303, 6.304, 6.302"
        case .codes: "FAR 19.102, 19.303, 4.606"
        case .competitionAnalysis: "FAR 6.101, 6.102, 6.301"
        case .procurementSourcing: "FAR 9.104, 9.105, 9.106"
        case .rrd: "FAR 11.002, 11.101, 11.103"
        case .requestForQuoteSimplified: "FAR 13.106, 13.106-3, 13.003"
        case .requestForQuote: "FAR 13.106, 13.307, 15.402"
        case .requestForProposal: "FAR 15.203, 15.204, 15.205"
        case .contractScaffold: "FAR 16.103, 16.301, 16.401"
        case .corAppointment: "FAR 1.604, 1.602-2, 42.302"
        case .analytics: "FAR 4.606, 4.607, 4.1501"
        case .otherTransactionAgreement: "10 U.S.C. 2371b, 32 C.F.R. 3.8"
        case .farUpdates: "FAR 1.101, 1.102, 52.101"
        }
    }

    /// File extension for document export
    public var fileExtension: String {
        switch self {
        case .sow, .soo, .pws, .qasp, .costEstimate, .marketResearch, .acquisitionPlan,
             .evaluationPlan, .fiscalLawReview, .opsecReview, .industryRFI, .sourcesSought,
             .justificationApproval, .codes, .competitionAnalysis, .procurementSourcing,
             .rrd, .requestForQuoteSimplified, .requestForQuote, .requestForProposal,
             .contractScaffold, .corAppointment, .otherTransactionAgreement, .farUpdates:
            return "rtf"  // Rich Text Format for formatted documents
        case .analytics:
            return "pdf"  // PDF for analytics reports
        }
    }
}

public enum DocumentCategoryType: Equatable, Hashable, Codable, Sendable {
    case standard(DocumentType)
    case determinationFinding(DFDocumentType)

    public var displayName: String {
        switch self {
        case let .standard(type):
            type.rawValue
        case let .determinationFinding(type):
            type.rawValue
        }
    }

    public var shortName: String {
        switch self {
        case let .standard(type):
            type.shortName
        case let .determinationFinding(type):
            type.shortName
        }
    }

    public var icon: String {
        switch self {
        case let .standard(type):
            type.icon
        case let .determinationFinding(type):
            type.icon
        }
    }

    public var isProFeature: Bool {
        switch self {
        case let .standard(type):
            type.isProFeature
        case let .determinationFinding(type):
            type.isProFeature
        }
    }
}

// GeneratedDocument - Platform-agnostic version for AppCore
// Platform-specific RTF formatting is handled in platform implementations
public struct GeneratedDocument: Identifiable, Equatable, Codable, Sendable, Hashable {
    public let id: UUID
    public let title: String
    public let documentCategory: DocumentCategoryType
    public let content: String
    public let createdAt: Date

    // Keep backward compatibility
    public var documentType: DocumentType? {
        if case let .standard(type) = documentCategory {
            return type
        }
        return nil
    }

    public var dfDocumentType: DFDocumentType? {
        if case let .determinationFinding(type) = documentCategory {
            return type
        }
        return nil
    }

    /// File type string representation for compatibility with existing code
    public var fileType: String {
        switch documentCategory {
        case let .standard(docType):
            docType.rawValue
        case let .determinationFinding(dfType):
            dfType.rawValue
        }
    }

    public init(id: UUID = UUID(), title: String, documentType: DocumentType, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        documentCategory = .standard(documentType)
        self.content = content
        self.createdAt = createdAt
    }

    public init(id: UUID = UUID(), title: String, dfDocumentType: DFDocumentType, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        documentCategory = .determinationFinding(dfDocumentType)
        self.content = content
        self.createdAt = createdAt
    }
}
