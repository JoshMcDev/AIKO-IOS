import Foundation

// NSAttributedString already conforms to Equatable in Foundation

public enum DocumentType: String, CaseIterable, Identifiable, Codable {
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
        }
    }

    public var isProFeature: Bool {
        false // All features unlocked
    }

    /// Get comprehensive FAR reference information
    public var comprehensiveFARReference: ComprehensiveFARReference? {
        FARReferenceService.getFARReference(for: rawValue)
    }

    /// Get formatted FAR/DFAR references for display
    public var formattedFARReferences: String {
        FARReferenceService.formatFARReferences(for: rawValue)
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
        }
    }
}

public enum DocumentCategoryType: Equatable, Hashable, Codable {
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

public struct GeneratedDocument: Identifiable, Equatable, Codable {
    public let id: UUID
    public let title: String
    public let documentCategory: DocumentCategoryType
    public let content: String
    public let rtfContent: String
    public let attributedContent: NSAttributedString
    public let createdAt: Date

    // Custom Codable implementation
    private enum CodingKeys: String, CodingKey {
        case id, title, documentCategory, content, rtfContent, createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        documentCategory = try container.decode(DocumentCategoryType.self, forKey: .documentCategory)
        content = try container.decode(String.self, forKey: .content)
        rtfContent = try container.decode(String.self, forKey: .rtfContent)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        // Recreate NSAttributedString from RTF content
        let (_, attributed) = RTFFormatter.convertToRTF(content)
        attributedContent = attributed
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(documentCategory, forKey: .documentCategory)
        try container.encode(content, forKey: .content)
        try container.encode(rtfContent, forKey: .rtfContent)
        try container.encode(createdAt, forKey: .createdAt)
    }

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

    public init(id: UUID = UUID(), title: String, documentType: DocumentType, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        documentCategory = .standard(documentType)
        self.content = content

        // Generate RTF content
        let (rtf, attributed) = RTFFormatter.convertToRTF(content)
        rtfContent = rtf
        attributedContent = attributed

        self.createdAt = createdAt
    }

    public init(id: UUID = UUID(), title: String, dfDocumentType: DFDocumentType, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        documentCategory = .determinationFinding(dfDocumentType)
        self.content = content

        // Generate RTF content
        let (rtf, attributed) = RTFFormatter.convertToRTF(content)
        rtfContent = rtf
        attributedContent = attributed

        self.createdAt = createdAt
    }
}
