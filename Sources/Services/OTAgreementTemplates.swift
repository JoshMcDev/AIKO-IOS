import Foundation
import ComposableArchitecture

// MARK: - OT Agreement Types

public enum OTAgreementType: String, CaseIterable {
    case research = "Research OT"
    case prototype = "Prototype OT"
    case production = "Production OT"
    case consortium = "Consortium OT"
    case traditionalContractor = "Traditional Contractor OT"
    case nonTraditional = "Non-Traditional Contractor OT"
    case dualUse = "Dual-Use OT"
    case sbirSttr = "SBIR/STTR OT"
    
    var description: String {
        switch self {
        case .research:
            return "Basic or applied research projects with flexible IP arrangements"
        case .prototype:
            return "Prototype development and demonstration projects"
        case .production:
            return "Follow-on production from successful prototypes"
        case .consortium:
            return "Multiple performers working collaboratively"
        case .traditionalContractor:
            return "Traditional defense contractors with cost sharing"
        case .nonTraditional:
            return "Commercial entities with simplified business terms"
        case .dualUse:
            return "Projects with both military and commercial applications"
        case .sbirSttr:
            return "Small business innovation and technology transfer"
        }
    }
}

// MARK: - OT Agreement Templates Service

public struct OTAgreementTemplates {
    public var selectTemplate: (OTAgreementType) async throws -> String
    public var analyzeRequirements: (String) async throws -> OTAgreementType
    public var getTemplateGuidance: (OTAgreementType) async throws -> OTTemplateGuidance
    
    public init(
        selectTemplate: @escaping (OTAgreementType) async throws -> String,
        analyzeRequirements: @escaping (String) async throws -> OTAgreementType,
        getTemplateGuidance: @escaping (OTAgreementType) async throws -> OTTemplateGuidance
    ) {
        self.selectTemplate = selectTemplate
        self.analyzeRequirements = analyzeRequirements
        self.getTemplateGuidance = getTemplateGuidance
    }
}

// MARK: - Template Guidance

public struct OTTemplateGuidance {
    public let type: OTAgreementType
    public let keyProvisions: [String]
    public let commonPitfalls: [String]
    public let negotiationPoints: [String]
    public let requiredAttachments: [String]
    
    public init(
        type: OTAgreementType,
        keyProvisions: [String],
        commonPitfalls: [String],
        negotiationPoints: [String],
        requiredAttachments: [String]
    ) {
        self.type = type
        self.keyProvisions = keyProvisions
        self.commonPitfalls = commonPitfalls
        self.negotiationPoints = negotiationPoints
        self.requiredAttachments = requiredAttachments
    }
}

// MARK: - Live Value

extension OTAgreementTemplates: DependencyKey {
    public static var liveValue: OTAgreementTemplates {
        OTAgreementTemplates(
            selectTemplate: { type in
                switch type {
                case .research:
                    return researchOTTemplate
                case .prototype:
                    return prototypeOTTemplate
                case .production:
                    return productionOTTemplate
                case .consortium:
                    return consortiumOTTemplate
                case .traditionalContractor:
                    return traditionalContractorOTTemplate
                case .nonTraditional:
                    return nonTraditionalOTTemplate
                case .dualUse:
                    return dualUseOTTemplate
                case .sbirSttr:
                    return sbirSttrOTTemplate
                }
            },
            analyzeRequirements: { requirements in
                let lowercased = requirements.lowercased()
                
                // Analyze requirements to determine best OT type
                if lowercased.contains("research") && (lowercased.contains("university") || lowercased.contains("academic")) {
                    return .research
                } else if lowercased.contains("consortium") || lowercased.contains("multiple performers") {
                    return .consortium
                } else if lowercased.contains("production") || lowercased.contains("manufacturing") {
                    return .production
                } else if lowercased.contains("commercial") && lowercased.contains("military") {
                    return .dualUse
                } else if lowercased.contains("sbir") || lowercased.contains("sttr") {
                    return .sbirSttr
                } else if lowercased.contains("non-traditional") || lowercased.contains("commercial company") {
                    return .nonTraditional
                } else if lowercased.contains("traditional contractor") || lowercased.contains("defense contractor") {
                    return .traditionalContractor
                } else {
                    // Default to prototype as most common
                    return .prototype
                }
            },
            getTemplateGuidance: { type in
                switch type {
                case .research:
                    return OTTemplateGuidance(
                        type: .research,
                        keyProvisions: [
                            "Broad publication rights",
                            "5-year government purpose rights",
                            "No deliverable-based payments",
                            "Flexible research pivots allowed"
                        ],
                        commonPitfalls: [
                            "Overly restrictive IP terms",
                            "Fixed deliverables vs research flexibility",
                            "Inadequate publication procedures"
                        ],
                        negotiationPoints: [
                            "Publication embargo periods",
                            "Background IP identification",
                            "Foreign national participation"
                        ],
                        requiredAttachments: [
                            "Research plan",
                            "Key personnel CVs",
                            "Facility capabilities"
                        ]
                    )
                    
                case .prototype:
                    return OTTemplateGuidance(
                        type: .prototype,
                        keyProvisions: [
                            "Clear prototype definition",
                            "Success criteria metrics",
                            "Follow-on production rights",
                            "Cost sharing requirements"
                        ],
                        commonPitfalls: [
                            "Vague success criteria",
                            "Missing follow-on provisions",
                            "Inadequate testing plans"
                        ],
                        negotiationPoints: [
                            "Cost share percentages",
                            "IP rights allocation",
                            "Production transition terms"
                        ],
                        requiredAttachments: [
                            "Technical specification",
                            "Test plan",
                            "Milestone schedule"
                        ]
                    )
                    
                case .production:
                    return OTTemplateGuidance(
                        type: .production,
                        keyProvisions: [
                            "Unit pricing structure",
                            "Quality standards",
                            "Delivery schedule",
                            "Warranty provisions"
                        ],
                        commonPitfalls: [
                            "Inadequate configuration control",
                            "Missing sustainment provisions",
                            "Unclear acceptance criteria"
                        ],
                        negotiationPoints: [
                            "Volume discounts",
                            "Option quantities",
                            "Warranty duration"
                        ],
                        requiredAttachments: [
                            "Production readiness review",
                            "Quality plan",
                            "Supply chain assessment"
                        ]
                    )
                    
                case .consortium:
                    return OTTemplateGuidance(
                        type: .consortium,
                        keyProvisions: [
                            "Consortium governance structure",
                            "Member agreements",
                            "Work share allocation",
                            "Common fund management"
                        ],
                        commonPitfalls: [
                            "Unclear decision rights",
                            "IP allocation conflicts",
                            "Free rider problems"
                        ],
                        negotiationPoints: [
                            "Leadership structure",
                            "New member criteria",
                            "Exit provisions"
                        ],
                        requiredAttachments: [
                            "Consortium agreement",
                            "Member capabilities matrix",
                            "Governance charter"
                        ]
                    )
                    
                case .traditionalContractor:
                    return OTTemplateGuidance(
                        type: .traditionalContractor,
                        keyProvisions: [
                            "1/3 cost share requirement",
                            "Traditional FAR-like terms",
                            "Standard IP provisions",
                            "Audit requirements"
                        ],
                        commonPitfalls: [
                            "Insufficient cost share",
                            "Over-application of FAR",
                            "Rigid milestone structure"
                        ],
                        negotiationPoints: [
                            "In-kind contributions",
                            "IP flexibility",
                            "Milestone adjustments"
                        ],
                        requiredAttachments: [
                            "Cost share commitment",
                            "Past performance",
                            "Technical approach"
                        ]
                    )
                    
                case .nonTraditional:
                    return OTTemplateGuidance(
                        type: .nonTraditional,
                        keyProvisions: [
                            "Commercial terms preference",
                            "Reduced oversight",
                            "Flexible IP arrangements",
                            "No cost accounting standards"
                        ],
                        commonPitfalls: [
                            "Over-bureaucratization",
                            "Excessive reporting",
                            "FAR-like provisions"
                        ],
                        negotiationPoints: [
                            "Commercial pricing",
                            "IP ownership",
                            "Minimal reporting"
                        ],
                        requiredAttachments: [
                            "Commercial capability statement",
                            "Pricing methodology",
                            "Commercial practices description"
                        ]
                    )
                    
                case .dualUse:
                    return OTTemplateGuidance(
                        type: .dualUse,
                        keyProvisions: [
                            "Dual market rights",
                            "Revenue sharing",
                            "Export control compliance",
                            "Commercial milestone tracking"
                        ],
                        commonPitfalls: [
                            "Unclear market boundaries",
                            "Missing export provisions",
                            "Inadequate revenue tracking"
                        ],
                        negotiationPoints: [
                            "Market exclusivity periods",
                            "Revenue share percentages",
                            "Foreign sales rights"
                        ],
                        requiredAttachments: [
                            "Commercialization plan",
                            "Market analysis",
                            "Export compliance plan"
                        ]
                    )
                    
                case .sbirSttr:
                    return OTTemplateGuidance(
                        type: .sbirSttr,
                        keyProvisions: [
                            "SBIR data rights",
                            "Phase III eligibility",
                            "Commercialization requirements",
                            "Success fee structure"
                        ],
                        commonPitfalls: [
                            "Violating SBIR policy",
                            "Inadequate Phase III bridge",
                            "Missing success metrics"
                        ],
                        negotiationPoints: [
                            "Success fee triggers",
                            "Phase III commitment",
                            "Mentorship terms"
                        ],
                        requiredAttachments: [
                            "Commercialization plan",
                            "Phase III strategy",
                            "Company qualifications"
                        ]
                    )
                }
            }
        )
    }
}

// MARK: - Template Strings

private let researchOTTemplate = """
RESEARCH OTHER TRANSACTION AGREEMENT
Agreement No: {{AGREEMENT_NUMBER}}

This Research Other Transaction Agreement is entered into between {{GOVERNMENT_AGENCY}} and {{PERFORMER_NAME}} under the authority of 10 U.S.C. § 2371b.

ARTICLE I - SCOPE
The Performer shall conduct basic/applied research in {{RESEARCH_AREA}} with the following objectives:
{{RESEARCH_OBJECTIVES}}

ARTICLE II - TERM
Period of Performance: {{START_DATE}} through {{END_DATE}}

ARTICLE III - FUNDING
Total Government Funding: ${{TOTAL_FUNDING}}
Payment Structure: Cost reimbursement based on actual costs incurred

ARTICLE IV - INTELLECTUAL PROPERTY
- Government Purpose Rights for 5 years from project completion
- Unlimited rights to research data funded solely by the Government
- Performer retains rights to background IP
- Publication rights with 30-day government review

ARTICLE V - KEY PERSONNEL
Principal Investigator: {{PI_NAME}}
Research Team: As identified in Attachment A
"""

private let prototypeOTTemplate = """
PROTOTYPE OTHER TRANSACTION AGREEMENT
Agreement No: {{AGREEMENT_NUMBER}}

This Prototype Other Transaction Agreement is entered into under 10 U.S.C. § 2371b between {{GOVERNMENT_AGENCY}} and {{PERFORMER_NAME}}.

ARTICLE I - PROTOTYPE PROJECT
The Performer shall develop and demonstrate a prototype {{PROTOTYPE_DESCRIPTION}} meeting the specifications in Attachment A.

ARTICLE II - MILESTONES AND PAYMENTS
Total Agreement Value: ${{TOTAL_VALUE}}
Cost Share: Government {{GOV_PERCENT}}% / Performer {{PERFORMER_PERCENT}}%

Milestone Schedule:
1. {{MILESTONE_1}}: ${{PAYMENT_1}}
2. {{MILESTONE_2}}: ${{PAYMENT_2}}
3. {{MILESTONE_3}}: ${{PAYMENT_3}}

ARTICLE III - SUCCESS CRITERIA
The prototype shall demonstrate:
{{SUCCESS_CRITERIA}}

ARTICLE IV - FOLLOW-ON PRODUCTION
Upon successful prototype completion, the Government may award a follow-on production contract without competition.
"""

private let productionOTTemplate = """
PRODUCTION OTHER TRANSACTION AGREEMENT
Agreement No: {{AGREEMENT_NUMBER}}

This Production Other Transaction Agreement follows successful completion of Prototype Agreement {{PROTOTYPE_AGREEMENT_NUMBER}}.

ARTICLE I - PRODUCTION REQUIREMENTS
The Performer shall produce and deliver:
- Quantity: {{QUANTITY}} units
- Delivery Schedule: {{DELIVERY_SCHEDULE}}
- Specifications: As demonstrated in prototype phase

ARTICLE II - PRICING
Unit Price: ${{UNIT_PRICE}}
Total Production Value: ${{TOTAL_VALUE}}
Option Quantities: Up to {{OPTION_QUANTITY}} additional units

ARTICLE III - QUALITY ASSURANCE
- First Article Testing required
- Quality standards per Attachment B
- Government quality assurance at performer facility

ARTICLE IV - WARRANTY
Commercial warranty: {{WARRANTY_PERIOD}} from delivery
"""

private let consortiumOTTemplate = """
CONSORTIUM OTHER TRANSACTION AGREEMENT
Agreement No: {{AGREEMENT_NUMBER}}

This Consortium OT Agreement is between {{GOVERNMENT_AGENCY}} and {{CONSORTIUM_NAME}} Consortium.

ARTICLE I - CONSORTIUM STRUCTURE
Lead Organization: {{LEAD_ORG}}
Members: As listed in Attachment A
Governance: Per Consortium Charter (Attachment B)

ARTICLE II - WORK ALLOCATION
Work share distribution per Consortium Management Plan
IP allocation per Member Agreement

ARTICLE III - COMMON FUND
Total Government Funding: ${{TOTAL_FUNDING}}
Consortium Management Fee: {{MGMT_FEE}}%
Distribution methodology: Per Article V

ARTICLE IV - NEW MEMBERS
Admission criteria and process defined in Consortium Charter
Government approval required for members performing >${{THRESHOLD}}
"""

private let traditionalContractorOTTemplate = """
TRADITIONAL CONTRACTOR OTHER TRANSACTION AGREEMENT
Agreement No: {{AGREEMENT_NUMBER}}

This OT Agreement leverages traditional defense contractor capabilities under 10 U.S.C. § 2371b.

ARTICLE I - PROJECT SCOPE
{{PROJECT_DESCRIPTION}}

ARTICLE II - COST SHARING
Total Project Cost: ${{TOTAL_COST}}
Government Share: ${{GOV_SHARE}} ({{GOV_PERCENT}}%)
Contractor Share: ${{CONTRACTOR_SHARE}} ({{CONTRACTOR_PERCENT}}%)
Note: Contractor share must be at least 1/3 of total cost

ARTICLE III - PAYMENTS
Milestone-based payments upon completion of:
{{MILESTONE_SCHEDULE}}

ARTICLE IV - TRADITIONAL TERMS
While maintaining OT flexibility, this agreement incorporates:
- Cost accounting per contractor's disclosed practices
- Standard IP provisions similar to FAR 52.227-14
- Audit rights for cost verification
"""

private let nonTraditionalOTTemplate = """
NON-TRADITIONAL CONTRACTOR OTHER TRANSACTION AGREEMENT
Agreement No: {{AGREEMENT_NUMBER}}

This streamlined OT Agreement enables participation by {{COMPANY_NAME}}, a non-traditional defense contractor.

ARTICLE I - COMMERCIAL APPROACH
The Performer shall provide {{DELIVERABLE}} using commercial practices and pricing.

ARTICLE II - SIMPLIFIED TERMS
- Fixed-price milestones based on commercial pricing
- Commercial warranties apply
- Minimal reporting (monthly status only)
- No cost accounting standards required

ARTICLE III - INTELLECTUAL PROPERTY
- Performer retains commercial IP rights
- Government receives license for government purpose
- No technical data package requirements

ARTICLE IV - PAYMENT TERMS
Net 30 days from invoice
Commercial payment practices apply
"""

private let dualUseOTTemplate = """
DUAL-USE OTHER TRANSACTION AGREEMENT
Agreement No: {{AGREEMENT_NUMBER}}

This Dual-Use OT develops technology for both defense and commercial markets.

ARTICLE I - DUAL-USE TECHNOLOGY
Development of {{TECHNOLOGY}} for:
- Military Application: {{MIL_APPLICATION}}
- Commercial Application: {{COMM_APPLICATION}}

ARTICLE II - MARKET RIGHTS
- Government: Unlimited use for government purposes
- Performer: Unrestricted commercial sales rights
- Export restrictions per ITAR/EAR

ARTICLE III - REVENUE SHARING
For commercial sales incorporating government-funded technology:
- Years 1-3: {{YEAR1_3_PERCENT}}% to Government
- Years 4-5: {{YEAR4_5_PERCENT}}% to Government
- After Year 5: No revenue sharing

ARTICLE IV - REPORTING
Quarterly commercial sales reports required for 5 years
"""

private let sbirSttrOTTemplate = """
SBIR/STTR OTHER TRANSACTION AGREEMENT
Agreement No: {{AGREEMENT_NUMBER}}

This SBIR/STTR Phase {{PHASE}} OT Agreement supports small business innovation.

ARTICLE I - SBIR/STTR PROJECT
Title: {{PROJECT_TITLE}}
Phase {{PHASE}} Objectives: {{OBJECTIVES}}

ARTICLE II - FUNDING
Base Funding: ${{BASE_FUNDING}}
Success Fee: Up to ${{SUCCESS_FEE}} based on:
{{SUCCESS_METRICS}}

ARTICLE III - SBIR DATA RIGHTS
Standard SBIR data rights apply (5-year protection period)
No additional technical data deliverables required

ARTICLE IV - PHASE III ELIGIBILITY
Successful completion establishes eligibility for:
- Sole source Phase III awards
- Subcontracting opportunities
- Direct sales to government

ARTICLE V - COMMERCIALIZATION
Commercialization plan updates required quarterly
Mentorship available through {{MENTOR_PROGRAM}}
"""

// MARK: - Dependency Registration

extension DependencyValues {
    public var otAgreementTemplates: OTAgreementTemplates {
        get { self[OTAgreementTemplates.self] }
        set { self[OTAgreementTemplates.self] = newValue }
    }
}