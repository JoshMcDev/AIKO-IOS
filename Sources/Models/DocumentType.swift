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
        case .sow: return "Statement of Work"
        case .soo: return "Statement of Objectives"
        case .pws: return "Performance Work Statement"
        case .qasp: return "QASP"
        case .costEstimate: return "Independent Government Cost Estimate"
        case .marketResearch: return "Market Research Report"
        case .acquisitionPlan: return "Acquisition Plan"
        case .evaluationPlan: return "Evaluation Plan"
        case .fiscalLawReview: return "Fiscal Law Review"
        case .opsecReview: return "OPSEC Review"
        case .industryRFI: return "Industry RFI"
        case .sourcesSought: return "Sources Sought"
        case .justificationApproval: return "Justification & Approval"
        case .codes: return "NAICS & PSC"
        case .competitionAnalysis: return "Competition Analysis"
        case .procurementSourcing: return "Recommended Vendors"
        case .rrd: return "Refined Requirement Document"
        case .requestForQuoteSimplified: return "Request for Quote_Simplified"
        case .requestForQuote: return "Request for Quote_Expanded"
        case .requestForProposal: return "Request for Proposal"
        case .contractScaffold: return "Contract"
        case .corAppointment: return "COR Appointment"
        case .analytics: return "Analytics"
        case .otherTransactionAgreement: return "OT Agreement"
        }
    }
    
    public var description: String {
        switch self {
        case .sow: return "Detailed scope, deliverables, and timeline"
        case .soo: return "High-level objectives for contractor innovation"
        case .pws: return "Performance-based requirements and metrics"
        case .qasp: return "QASP monitoring and quality standards"
        case .costEstimate: return "IGCE with detailed cost breakdown"
        case .marketResearch: return "Market analysis and vendor capability assessment"
        case .acquisitionPlan: return "Comprehensive acquisition strategy and milestones"
        case .evaluationPlan: return "Evaluation criteria and methodology for commercial items"
        case .fiscalLawReview: return "Legal review for fiscal compliance"
        case .opsecReview: return "Operations security assessment and requirements"
        case .industryRFI: return "Request for Information from industry partners"
        case .sourcesSought: return "Notice seeking capable sources for requirement"
        case .justificationApproval: return "Justification for other than full and open competition"
        case .codes: return "NAICS, PSC codes and small business size standards"
        case .competitionAnalysis: return "Analysis of competition strategy and acquisition approach"
        case .procurementSourcing: return "Recommended vendors with contact information and capabilities"
        case .rrd: return "Interactive requirements definition and refinement process"
        case .requestForQuoteSimplified: return "Simplified oral RFQ for quick procurement"
        case .requestForQuote: return "Request for Quote for commercial items or services"
        case .requestForProposal: return "Request for Proposal for complex requirements"
        case .contractScaffold: return "Contract framework and structure for award documents"
        case .corAppointment: return "Contracting Officer's Representative appointment letter"
        case .analytics: return "Procurement analytics and performance metrics dashboard"
        case .otherTransactionAgreement: return "Other Transaction Agreement for prototype projects under 10 U.S.C. § 2371b"
        }
    }
    
    public var icon: String {
        switch self {
        case .sow: return "doc.text"
        case .soo: return "lightbulb"
        case .pws: return "chart.line.uptrend.xyaxis"
        case .qasp: return "checkmark.shield"
        case .costEstimate: return "dollarsign.circle"
        case .marketResearch: return "magnifyingglass.circle"
        case .acquisitionPlan: return "calendar.badge.plus"
        case .evaluationPlan: return "checklist"
        case .fiscalLawReview: return "scalemass"
        case .opsecReview: return "lock.shield"
        case .industryRFI: return "questionmark.bubble"
        case .sourcesSought: return "person.3.sequence"
        case .justificationApproval: return "doc.badge.ellipsis"
        case .codes: return "number.square"
        case .competitionAnalysis: return "chart.pie"
        case .procurementSourcing: return "person.crop.square.filled.and.at.rectangle"
        case .rrd: return "questionmark.app"
        case .requestForQuoteSimplified: return "envelope.badge"
        case .requestForQuote: return "envelope.badge.fill"
        case .requestForProposal: return "envelope.open.fill"
        case .contractScaffold: return "doc.on.doc.fill"
        case .corAppointment: return "person.crop.circle.badge.checkmark"
        case .analytics: return "chart.bar.xaxis"
        case .otherTransactionAgreement: return "sparkles.rectangle.stack"
        }
    }
    
    public var isProFeature: Bool {
        return false // All features unlocked
    }
    
    /// Get comprehensive FAR reference information
    public var comprehensiveFARReference: ComprehensiveFARReference? {
        return FARReferenceService.getFARReference(for: self.rawValue)
    }
    
    /// Get formatted FAR/DFAR references for display
    public var formattedFARReferences: String {
        return FARReferenceService.formatFARReferences(for: self.rawValue)
    }
    
    public var farReference: String {
        switch self {
        case .sow: return "FAR 11.101, 11.102, 37.602"
        case .soo: return "FAR 11.101, 11.002, 37.602-4"
        case .pws: return "FAR 11.101, 37.601, 37.602"
        case .qasp: return "FAR 46.401, 46.103, 46.407, 37.604"
        case .costEstimate: return "FAR 7.105(b)(20)(iv), 15.404-1, 36.203"
        case .marketResearch: return "FAR 10.001, 10.002, 11.002"
        case .acquisitionPlan: return "FAR 7.102, 7.103, 7.104, 7.105"
        case .evaluationPlan: return "FAR 15.304, 15.305, 15.101"
        case .fiscalLawReview: return "31 U.S.C. 1341, 1301, 1502"
        case .opsecReview: return "DoD 5205.02, FAR 4.402, 24.202"
        case .industryRFI: return "FAR 15.201, 15.202, 10.002(b)(2)"
        case .sourcesSought: return "FAR 10.002(b)(2), 5.205"
        case .justificationApproval: return "FAR 6.303, 6.304, 6.302"
        case .codes: return "FAR 19.102, 19.303, 4.606"
        case .competitionAnalysis: return "FAR 6.101, 6.102, 6.301"
        case .procurementSourcing: return "FAR 9.104, 9.105, 9.106"
        case .rrd: return "FAR 11.002, 11.101, 11.103"
        case .requestForQuoteSimplified: return "FAR 13.106, 13.106-3, 13.003"
        case .requestForQuote: return "FAR 13.106, 13.307, 15.402"
        case .requestForProposal: return "FAR 15.203, 15.204, 15.205"
        case .contractScaffold: return "FAR 16.103, 16.301, 16.401"
        case .corAppointment: return "FAR 1.604, 1.602-2, 42.302"
        case .analytics: return "FAR 4.606, 4.607, 4.1501"
        case .otherTransactionAgreement: return "10 U.S.C. 2371b, 32 C.F.R. 3.8"
        }
    }
}

public enum DocumentCategoryType: Equatable, Hashable, Codable {
    case standard(DocumentType)
    case determinationFinding(DFDocumentType)
    
    public var displayName: String {
        switch self {
        case .standard(let type):
            return type.rawValue
        case .determinationFinding(let type):
            return type.rawValue
        }
    }
    
    public var shortName: String {
        switch self {
        case .standard(let type):
            return type.shortName
        case .determinationFinding(let type):
            return type.shortName
        }
    }
    
    public var icon: String {
        switch self {
        case .standard(let type):
            return type.icon
        case .determinationFinding(let type):
            return type.icon
        }
    }
    
    public var isProFeature: Bool {
        switch self {
        case .standard(let type):
            return type.isProFeature
        case .determinationFinding(let type):
            return type.isProFeature
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
        self.attributedContent = attributed
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
        if case .standard(let type) = documentCategory {
            return type
        }
        return nil
    }
    
    public var dfDocumentType: DFDocumentType? {
        if case .determinationFinding(let type) = documentCategory {
            return type
        }
        return nil
    }
    
    public init(id: UUID = UUID(), title: String, documentType: DocumentType, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.documentCategory = .standard(documentType)
        self.content = content
        
        // Generate RTF content
        let (rtf, attributed) = RTFFormatter.convertToRTF(content)
        self.rtfContent = rtf
        self.attributedContent = attributed
        
        self.createdAt = createdAt
    }
    
    public init(id: UUID = UUID(), title: String, dfDocumentType: DFDocumentType, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.documentCategory = .determinationFinding(dfDocumentType)
        self.content = content
        
        // Generate RTF content
        let (rtf, attributed) = RTFFormatter.convertToRTF(content)
        self.rtfContent = rtf
        self.attributedContent = attributed
        
        self.createdAt = createdAt
    }
}