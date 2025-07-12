import Foundation

/// Service for managing FAR and DFAR references throughout the application
public enum FARReferenceService {
    /// Comprehensive FAR/DFAR reference mappings for all document types
    public static let farReferences: [String: ComprehensiveFARReference] = [
        // Standard Documents
        "Statement of Work": ComprehensiveFARReference(
            primary: "FAR 11.101",
            related: ["FAR 11.102", "FAR 37.602"],
            dfar: ["DFARS 211.101"],
            description: "Describes acquisition of supplies or services"
        ),
        "Statement of Objectives": ComprehensiveFARReference(
            primary: "FAR 11.101",
            related: ["FAR 11.002", "FAR 37.602-4"],
            dfar: ["DFARS 211.101"],
            description: "Performance-based statement of objectives"
        ),
        "Performance Work Statement": ComprehensiveFARReference(
            primary: "FAR 11.101",
            related: ["FAR 37.601", "FAR 37.602"],
            dfar: ["DFARS 237.170", "DFARS 237.172"],
            description: "Performance-based work statement"
        ),
        "QASP": ComprehensiveFARReference(
            primary: "FAR 46.401",
            related: ["FAR 46.103", "FAR 46.407", "FAR 37.604"],
            dfar: ["DFARS 246.401"],
            description: "Quality Assurance Surveillance Plan"
        ),
        "Independent Government Cost Estimate": ComprehensiveFARReference(
            primary: "FAR 7.105(b)(20)(iv)",
            related: ["FAR 15.404-1", "FAR 36.203"],
            dfar: ["DFARS 207.105"],
            description: "Government's estimate of costs"
        ),
        "Market Research Report": ComprehensiveFARReference(
            primary: "FAR 10.001",
            related: ["FAR 10.002", "FAR 11.002", "FAR 7.102(a)(2)"],
            dfar: ["DFARS 210.001"],
            description: "Market research to determine sources"
        ),
        "Acquisition Plan": ComprehensiveFARReference(
            primary: "FAR 7.102",
            related: ["FAR 7.103", "FAR 7.104", "FAR 7.105"],
            dfar: ["DFARS 207.103"],
            description: "Comprehensive acquisition planning"
        ),
        "Evaluation Plan": ComprehensiveFARReference(
            primary: "FAR 15.304",
            related: ["FAR 15.305", "FAR 15.101"],
            dfar: ["DFARS 215.304"],
            description: "Evaluation factors and significant subfactors"
        ),
        "Fiscal Law Review": ComprehensiveFARReference(
            primary: "31 U.S.C. 1341",
            related: ["31 U.S.C. 1301", "31 U.S.C. 1502", "FAR 32.703-2"],
            dfar: ["DFARS 232.703-2"],
            description: "Anti-Deficiency Act compliance"
        ),
        "OPSEC Review": ComprehensiveFARReference(
            primary: "DoD 5205.02",
            related: ["FAR 4.402", "FAR 24.202"],
            dfar: ["DFARS 204.402", "DFARS 239.74"],
            description: "Operations Security assessment"
        ),
        "Industry RFI": ComprehensiveFARReference(
            primary: "FAR 15.201",
            related: ["FAR 15.202", "FAR 10.002(b)(2)"],
            dfar: ["DFARS 215.201"],
            description: "Request for Information"
        ),
        "Sources Sought": ComprehensiveFARReference(
            primary: "FAR 10.002(b)(2)",
            related: ["FAR 5.205", "FAR 10.001"],
            dfar: ["DFARS 210.002"],
            description: "Sources Sought notice"
        ),
        "Justification & Approval": ComprehensiveFARReference(
            primary: "FAR 6.303",
            related: ["FAR 6.304", "FAR 6.302", "FAR 8.405-6"],
            dfar: ["DFARS 206.303"],
            description: "Justification for other than full and open competition"
        ),
        "NAICS & PSC": ComprehensiveFARReference(
            primary: "FAR 19.102",
            related: ["FAR 19.303", "FAR 4.606"],
            dfar: ["DFARS 219.102"],
            description: "NAICS codes and size standards"
        ),
        "Competition Analysis": ComprehensiveFARReference(
            primary: "FAR 6.101",
            related: ["FAR 6.102", "FAR 6.301", "FAR 7.105(b)(2)"],
            dfar: ["DFARS 206.101"],
            description: "Full and open competition analysis"
        ),
        "Recommended Vendors": ComprehensiveFARReference(
            primary: "FAR 9.104",
            related: ["FAR 9.105", "FAR 9.106"],
            dfar: ["DFARS 209.104"],
            description: "Responsibility determination"
        ),
        "Refined Requirement Document": ComprehensiveFARReference(
            primary: "FAR 11.002",
            related: ["FAR 11.101", "FAR 11.103"],
            dfar: ["DFARS 211.002"],
            description: "Requirements development"
        ),
        "Request for Quote_Simplified": ComprehensiveFARReference(
            primary: "FAR 13.106",
            related: ["FAR 13.106-3", "FAR 13.003"],
            dfar: ["DFARS 213.106"],
            description: "Simplified acquisition procedures"
        ),
        "Request for Quote": ComprehensiveFARReference(
            primary: "FAR 13.106",
            related: ["FAR 13.307", "FAR 15.402"],
            dfar: ["DFARS 213.106"],
            description: "Request for Quote procedures"
        ),
        "Request for Proposal": ComprehensiveFARReference(
            primary: "FAR 15.203",
            related: ["FAR 15.204", "FAR 15.205", "FAR 15.209"],
            dfar: ["DFARS 215.203"],
            description: "Request for Proposal preparation"
        ),
        "Contract": ComprehensiveFARReference(
            primary: "FAR 16.103",
            related: ["FAR 16.301", "FAR 16.401", "FAR 16.501"],
            dfar: ["DFARS 216.103"],
            description: "Contract type selection"
        ),
        "COR Appointment": ComprehensiveFARReference(
            primary: "FAR 1.604",
            related: ["FAR 1.602-2", "FAR 42.302"],
            dfar: ["DFARS 201.602-2"],
            description: "Contracting Officer's Representative"
        ),
        "Analytics": ComprehensiveFARReference(
            primary: "FAR 4.606",
            related: ["FAR 4.607", "FAR 4.1501"],
            dfar: ["DFARS 204.606"],
            description: "Federal Procurement Data System"
        ),
        "OT Agreement": ComprehensiveFARReference(
            primary: "10 U.S.C. 2371b",
            related: ["32 C.F.R. 3.8", "DoD OT Guide"],
            dfar: ["DFARS Appendix I"],
            description: "Other Transaction Authority"
        ),

        // Determination & Findings Documents
        "8(a) Sole Source": ComprehensiveFARReference(
            primary: "FAR 19.804-2",
            related: ["FAR 19.805-1", "FAR 19.808", "13 CFR 124.506"],
            dfar: ["DFARS 219.804"],
            description: "8(a) sole source procedures"
        ),
        "Brand Name or Equal": ComprehensiveFARReference(
            primary: "FAR 11.104",
            related: ["FAR 11.107", "FAR 6.302-1(c)"],
            dfar: ["DFARS 211.104"],
            description: "Brand name or equal purchase descriptions"
        ),
        "J&A Other Than Full & Open Competition": ComprehensiveFARReference(
            primary: "FAR 6.303",
            related: ["FAR 6.304", "FAR 6.302", "FAR 6.305"],
            dfar: ["DFARS 206.303"],
            description: "Justification and Approval requirements"
        ),
        "Limited Source Justification": ComprehensiveFARReference(
            primary: "FAR 13.106-1(b)",
            related: ["FAR 13.104", "FAR 13.501"],
            dfar: ["DFARS 213.106-1"],
            description: "Limited source justification under SAP"
        ),
        "Bridge Contract": ComprehensiveFARReference(
            primary: "FAR 16.505(a)(10)",
            related: ["FAR 6.302-1", "FAR 17.207"],
            dfar: ["DFARS 216.505"],
            description: "Bridge contract justification"
        ),
        "Contract Modification": ComprehensiveFARReference(
            primary: "FAR 43.203",
            related: ["FAR 43.204", "FAR 43.205", "FAR 43.103"],
            dfar: ["DFARS 243.203"],
            description: "Contract modifications"
        ),
        "Cost Plus Contract Type": ComprehensiveFARReference(
            primary: "FAR 16.301-3",
            related: ["FAR 16.103", "FAR 16.104", "FAR 16.301-2"],
            dfar: ["DFARS 216.301"],
            description: "Cost-reimbursement contracts"
        ),
        "IDIQ": ComprehensiveFARReference(
            primary: "FAR 16.504",
            related: ["FAR 16.505", "FAR 16.501-2", "FAR 16.503"],
            dfar: ["DFARS 216.504"],
            description: "Indefinite-delivery contracts"
        ),
        "Options Exercise": ComprehensiveFARReference(
            primary: "FAR 17.207",
            related: ["FAR 17.206", "FAR 17.208"],
            dfar: ["DFARS 217.207"],
            description: "Exercise of options"
        ),
        "Time Extension": ComprehensiveFARReference(
            primary: "FAR 43.204",
            related: ["FAR 43.103", "FAR 52.243"],
            dfar: ["DFARS 243.204"],
            description: "Administrative changes"
        ),
        "HUBZone Set-Aside": ComprehensiveFARReference(
            primary: "FAR 19.1305",
            related: ["FAR 19.1306", "FAR 19.1307"],
            dfar: ["DFARS 219.1305"],
            description: "HUBZone set-aside procedures"
        ),
        "Small Business Set-Aside": ComprehensiveFARReference(
            primary: "FAR 19.502",
            related: ["FAR 19.503", "FAR 19.505"],
            dfar: ["DFARS 219.502"],
            description: "Small business set-asides"
        ),
        "Subcontracting Plan": ComprehensiveFARReference(
            primary: "FAR 19.702",
            related: ["FAR 19.704", "FAR 19.705"],
            dfar: ["DFARS 219.702"],
            description: "Subcontracting plan requirements"
        ),
        "Commercial Item Determination": ComprehensiveFARReference(
            primary: "FAR 2.101",
            related: ["FAR 12.102", "FAR 10.002"],
            dfar: ["DFARS 212.102"],
            description: "Commercial item definition"
        ),
        "Cost/Pricing Data Waiver": ComprehensiveFARReference(
            primary: "FAR 15.403-1",
            related: ["FAR 15.403-4", "FAR 15.406-2"],
            dfar: ["DFARS 215.403-1"],
            description: "Certified cost or pricing data"
        ),
        "Emergency/Urgent & Compelling": ComprehensiveFARReference(
            primary: "FAR 6.302-2",
            related: ["FAR 6.303-2", "FAR 18.125"],
            dfar: ["DFARS 206.302-2"],
            description: "Unusual and compelling urgency"
        ),
        "Inherently Governmental Functions": ComprehensiveFARReference(
            primary: "FAR 7.503",
            related: ["FAR 7.500", "FAR 37.104", "OFPP Policy Letter 11-01"],
            dfar: ["DFARS 207.503"],
            description: "Inherently governmental functions"
        ),
        "Interagency Agreement": ComprehensiveFARReference(
            primary: "FAR 17.502-2",
            related: ["FAR 17.503", "FAR 17.504"],
            dfar: ["DFARS 217.502"],
            description: "Economy Act orders"
        ),
        "LPTA Determination": ComprehensiveFARReference(
            primary: "FAR 15.101-2",
            related: ["FAR 15.304", "FAR 15.404"],
            dfar: ["DFARS 215.101-2"],
            description: "Lowest price technically acceptable"
        ),
        "Other Transaction Authority": ComprehensiveFARReference(
            primary: "10 U.S.C. 2371b",
            related: ["10 U.S.C. 2371", "32 C.F.R. Part 3"],
            dfar: ["DFARS Appendix I"],
            description: "Other Transaction Authority"
        ),
        "Simplified Acquisition Procedures": ComprehensiveFARReference(
            primary: "FAR 13.003",
            related: ["FAR 13.106", "FAR 13.201"],
            dfar: ["DFARS 213.003"],
            description: "Simplified acquisition threshold"
        ),
    ]

    /// Get FAR reference for a document type
    public static func getFARReference(for documentType: String) -> ComprehensiveFARReference? {
        farReferences[documentType]
    }

    /// Get all relevant FAR/DFAR citations for a document
    public static func getAllCitations(for documentType: String) -> [String] {
        guard let reference = farReferences[documentType] else { return [] }

        var citations = [reference.primary]
        citations.append(contentsOf: reference.related)
        citations.append(contentsOf: reference.dfar)

        return citations
    }

    /// Format FAR references for display in templates
    public static func formatFARReferences(for documentType: String) -> String {
        guard let reference = farReferences[documentType] else {
            return "No FAR reference available"
        }

        var formatted = "**Primary Reference:** \(reference.primary)\n\n"

        if !reference.related.isEmpty {
            formatted += "**Related FAR References:**\n"
            for ref in reference.related {
                formatted += "- \(ref)\n"
            }
            formatted += "\n"
        }

        if !reference.dfar.isEmpty {
            formatted += "**DFAR References:**\n"
            for ref in reference.dfar {
                formatted += "- \(ref)\n"
            }
            formatted += "\n"
        }

        formatted += "**Description:** \(reference.description)"

        return formatted
    }
}

/// Structure to hold comprehensive FAR/DFAR reference information
public struct ComprehensiveFARReference {
    public let primary: String
    public let related: [String]
    public let dfar: [String]
    public let description: String

    public init(primary: String, related: [String] = [], dfar: [String] = [], description: String) {
        self.primary = primary
        self.related = related
        self.dfar = dfar
        self.description = description
    }
}
