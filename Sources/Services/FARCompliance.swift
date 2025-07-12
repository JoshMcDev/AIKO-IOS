import ComposableArchitecture
import Foundation

public struct FARComplianceService {
    public var getRecommendedDocuments: (String, ProjectCategory) async throws -> [DocumentRecommendation]
    public var validateCompliance: (DocumentType, String) async throws -> ComplianceResult

    public init(
        getRecommendedDocuments: @escaping (String, ProjectCategory) async throws -> [DocumentRecommendation],
        validateCompliance: @escaping (DocumentType, String) async throws -> ComplianceResult
    ) {
        self.getRecommendedDocuments = getRecommendedDocuments
        self.validateCompliance = validateCompliance
    }
}

public enum ProjectCategory: String, CaseIterable {
    case softwareDevelopment = "Software Development"
    case consulting = "Consulting Services"
    case research = "Research & Development"
    case construction = "Construction"
    case equipment = "Equipment Procurement"
    case maintenance = "Maintenance Services"
    case training = "Training Services"
    case other = "Other"

    public var farReference: String {
        switch self {
        case .softwareDevelopment:
            "FAR 39.1 - Information Technology"
        case .consulting:
            "FAR 37.2 - Advisory Services"
        case .research:
            "FAR 35 - Research and Development"
        case .construction:
            "FAR 36 - Construction Contracting"
        case .equipment:
            "FAR 11 - Describing Agency Needs"
        case .maintenance:
            "FAR 37.1 - Service Contracting"
        case .training:
            "FAR 37.6 - Performance-Based Service Contracting"
        case .other:
            "FAR General Provisions"
        }
    }
}

public struct DocumentRecommendation {
    public let documentType: DocumentType
    public let priority: Priority
    public let farJustification: String
    public let description: String

    public enum Priority: String, CaseIterable {
        case required = "Required"
        case recommended = "Recommended"
        case optional = "Optional"
    }

    public init(documentType: DocumentType, priority: Priority, farJustification: String, description: String) {
        self.documentType = documentType
        self.priority = priority
        self.farJustification = farJustification
        self.description = description
    }
}

public struct ComplianceResult {
    public let isCompliant: Bool
    public let score: Double // 0.0 to 1.0
    public let issues: [ComplianceIssue]
    public let recommendations: [String]

    public init(isCompliant: Bool, score: Double, issues: [ComplianceIssue], recommendations: [String]) {
        self.isCompliant = isCompliant
        self.score = score
        self.issues = issues
        self.recommendations = recommendations
    }
}

public struct ComplianceIssue {
    public let severity: Severity
    public let description: String
    public let farReference: String
    public let suggestedFix: String

    public enum Severity: String, CaseIterable {
        case critical = "Critical"
        case major = "Major"
        case minor = "Minor"
        case informational = "Informational"
    }

    public init(severity: Severity, description: String, farReference: String, suggestedFix: String) {
        self.severity = severity
        self.description = description
        self.farReference = farReference
        self.suggestedFix = suggestedFix
    }
}

extension FARComplianceService: DependencyKey {
    public static var liveValue: FARComplianceService {
        FARComplianceService(
            getRecommendedDocuments: { requirements, category in
                // Analyze requirements and category to recommend appropriate documents
                let keywords = requirements.lowercased()
                var recommendations: [DocumentRecommendation] = []

                // Always recommend SOW for basic scope definition
                recommendations.append(DocumentRecommendation(
                    documentType: .sow,
                    priority: .required,
                    farJustification: "FAR 11.002(a) - Agencies must describe their needs clearly",
                    description: "Essential for defining project scope and deliverables"
                ))

                // Performance-based contracting recommendations
                if keywords.contains("performance") || keywords.contains("outcome") || category == .softwareDevelopment {
                    recommendations.append(DocumentRecommendation(
                        documentType: .pws,
                        priority: .recommended,
                        farJustification: "FAR 37.6 - Performance-Based Service Contracting",
                        description: "Recommended for outcome-based performance requirements"
                    ))
                }

                // Quality assurance for complex projects
                if keywords.contains("quality") || keywords.contains("testing") || category == .softwareDevelopment {
                    recommendations.append(DocumentRecommendation(
                        documentType: .qasp,
                        priority: .recommended,
                        farJustification: "FAR 46.4 - Government Quality Assurance",
                        description: "Essential for monitoring and ensuring quality deliverables"
                    ))
                }

                // Cost estimation requirements
                if keywords.contains("cost") || keywords.contains("budget") || keywords.contains("price") {
                    recommendations.append(DocumentRecommendation(
                        documentType: .costEstimate,
                        priority: .required,
                        farJustification: "FAR 15.4 - Price and Cost Analysis",
                        description: "Required for independent cost validation and negotiation"
                    ))
                }

                // Contract scaffold for comprehensive acquisition strategy
                if keywords.contains("complex") || keywords.contains("large") || category == .construction {
                    recommendations.append(DocumentRecommendation(
                        documentType: .acquisitionPlan,
                        priority: .recommended,
                        farJustification: "FAR 7.1 - Acquisition Planning",
                        description: "Comprehensive acquisition strategy for complex procurements"
                    ))
                }

                return recommendations
            },
            validateCompliance: { documentType, content in
                // Validate document content against FAR requirements
                let issues = validateDocumentContent(documentType: documentType, content: content)
                let score = calculateComplianceScore(issues: issues)
                let isCompliant = score >= 0.7 && !issues.contains { $0.severity == .critical }

                let recommendations = generateRecommendations(for: documentType, issues: issues)

                return ComplianceResult(
                    isCompliant: isCompliant,
                    score: score,
                    issues: issues,
                    recommendations: recommendations
                )
            }
        )
    }

    public static var testValue: FARComplianceService {
        FARComplianceService(
            getRecommendedDocuments: { _, _ in
                [
                    DocumentRecommendation(
                        documentType: .sow,
                        priority: .required,
                        farJustification: "FAR 11.002(a) - Mock justification",
                        description: "Mock SOW recommendation"
                    ),
                    DocumentRecommendation(
                        documentType: .pws,
                        priority: .recommended,
                        farJustification: "FAR 37.6 - Mock justification",
                        description: "Mock PWS recommendation"
                    ),
                ]
            },
            validateCompliance: { _, _ in
                ComplianceResult(
                    isCompliant: true,
                    score: 0.85,
                    issues: [],
                    recommendations: ["Mock recommendation"]
                )
            }
        )
    }
}

private func validateDocumentContent(documentType: DocumentType, content: String) -> [ComplianceIssue] {
    var issues: [ComplianceIssue] = []
    let lowercaseContent = content.lowercased()

    switch documentType {
    case .sow:
        // SOW validation
        if !lowercaseContent.contains("scope"), !lowercaseContent.contains("objective") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "SOW must clearly define scope and objectives",
                farReference: "FAR 11.002(a)",
                suggestedFix: "Add clear scope and objective statements"
            ))
        }

    case .soo:
        // SOO validation
        if !lowercaseContent.contains("objective"), !lowercaseContent.contains("outcome") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "SOO must define objectives and desired outcomes",
                farReference: "FAR 37.602",
                suggestedFix: "Add clear objectives and desired end states"
            ))
        }

        if !lowercaseContent.contains("deliverable") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "SOW should specify deliverables",
                farReference: "FAR 11.002(b)",
                suggestedFix: "Include detailed deliverable descriptions"
            ))
        }

    case .pws:
        // PWS validation
        if !lowercaseContent.contains("performance"), !lowercaseContent.contains("outcome") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "PWS must focus on performance outcomes",
                farReference: "FAR 37.6",
                suggestedFix: "Define clear performance standards and outcomes"
            ))
        }

    case .qasp:
        // QASP validation
        if !lowercaseContent.contains("quality"), !lowercaseContent.contains("surveillance") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "QASP must define quality surveillance methods",
                farReference: "FAR 46.4",
                suggestedFix: "Include quality surveillance procedures"
            ))
        }

    case .costEstimate:
        // IGCE validation
        if !lowercaseContent.contains("cost"), !lowercaseContent.contains("estimate") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Cost estimate must include detailed cost breakdown",
                farReference: "FAR 15.4",
                suggestedFix: "Provide comprehensive cost analysis"
            ))
        }

    case .marketResearch:
        // Market Research validation
        if !lowercaseContent.contains("market"), !lowercaseContent.contains("industry") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Market research must include industry analysis",
                farReference: "FAR 10.001",
                suggestedFix: "Add market analysis and industry assessment"
            ))
        }

    case .acquisitionPlan:
        // Acquisition Plan validation
        if !lowercaseContent.contains("strategy"), !lowercaseContent.contains("approach") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Acquisition plan must define acquisition strategy",
                farReference: "FAR 7.102",
                suggestedFix: "Include clear acquisition strategy and approach"
            ))
        }

    case .evaluationPlan:
        // Evaluation Plan validation
        if !lowercaseContent.contains("evaluation") || !lowercaseContent.contains("criteria") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Evaluation plan must define evaluation criteria",
                farReference: "FAR 52.212-2",
                suggestedFix: "Include detailed evaluation factors and methodology"
            ))
        }
        if !lowercaseContent.contains("technical") || !lowercaseContent.contains("price") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Must address both technical and price evaluation",
                farReference: "FAR 15.304",
                suggestedFix: "Include both technical and price evaluation criteria"
            ))
        }
        if !lowercaseContent.contains("past performance") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Should include past performance evaluation",
                farReference: "FAR 15.305(a)(2)",
                suggestedFix: "Add past performance evaluation methodology"
            ))
        }

    case .fiscalLawReview:
        // Fiscal Law Review validation
        if !lowercaseContent.contains("fund"), !lowercaseContent.contains("appropriation") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Fiscal law review must address funding sources",
                farReference: "31 U.S.C. 1341",
                suggestedFix: "Include funding source and appropriation analysis"
            ))
        }

    case .opsecReview:
        // OPSEC Review validation
        if !lowercaseContent.contains("security"), !lowercaseContent.contains("opsec") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "OPSEC review must address security concerns",
                farReference: "FAR 4.4",
                suggestedFix: "Include security assessment and OPSEC measures"
            ))
        }

    case .industryRFI:
        // Industry RFI validation
        if !lowercaseContent.contains("information"), !lowercaseContent.contains("request") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "RFI must clearly state information being requested",
                farReference: "FAR 15.201",
                suggestedFix: "Clearly define the information requested from industry"
            ))
        }

    case .sourcesSought:
        // Sources Sought validation
        if !lowercaseContent.contains("sources"), !lowercaseContent.contains("capability") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Sources sought must describe capability requirements",
                farReference: "FAR 5.205",
                suggestedFix: "Include clear capability requirements and qualifications"
            ))
        }

    case .justificationApproval:
        // J&A validation
        if !lowercaseContent.contains("competition"), !lowercaseContent.contains("justification") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "J&A must justify limited competition",
                farReference: "FAR 6.303",
                suggestedFix: "Include justification for other than full and open competition"
            ))
        }

    case .codes:
        // Codes validation
        if !lowercaseContent.contains("naics") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Must identify appropriate NAICS code",
                farReference: "FAR 19.102",
                suggestedFix: "Include NAICS code determination with justification"
            ))
        }
        if !lowercaseContent.contains("psc"), !lowercaseContent.contains("product service code") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Must identify Product Service Code",
                farReference: "FAR 4.1005",
                suggestedFix: "Include PSC code for proper categorization"
            ))
        }
        if !lowercaseContent.contains("size standard") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Must identify small business size standard",
                farReference: "FAR 19.202",
                suggestedFix: "Include applicable size standard for the NAICS code"
            ))
        }

    case .competitionAnalysis:
        // Competition Analysis validation
        if !lowercaseContent.contains("market research") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Must reference market research findings",
                farReference: "FAR 10.002",
                suggestedFix: "Include market research data to support competition analysis"
            ))
        }
        if !lowercaseContent.contains("rule of two") && !lowercaseContent.contains("small business") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Must evaluate small business capability",
                farReference: "FAR 19.502-2",
                suggestedFix: "Include Rule of Two analysis for small business set-aside determination"
            ))
        }
        if !lowercaseContent.contains("competition") || !lowercaseContent.contains("recommendation") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Must provide clear competition strategy recommendation",
                farReference: "FAR 6.101",
                suggestedFix: "Include specific recommendation for competition approach"
            ))
        }

    case .procurementSourcing:
        // Procurement Sourcing validation
        if !lowercaseContent.contains("sam.gov") && !lowercaseContent.contains("sam") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Must verify vendors in SAM.gov",
                farReference: "FAR 4.1102",
                suggestedFix: "Include SAM.gov registration verification for all vendors"
            ))
        }
        if !lowercaseContent.contains("contact") || !lowercaseContent.contains("email") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Must provide vendor contact information",
                farReference: "FAR 5.207",
                suggestedFix: "Include complete contact information for recommended vendors"
            ))
        }
        if !lowercaseContent.contains("cage") || !lowercaseContent.contains("uei") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Must include vendor identifiers",
                farReference: "FAR 4.1102",
                suggestedFix: "Include CAGE codes and UEI numbers for all vendors"
            ))
        }

    case .rrd:
        // RRD validation
        if !lowercaseContent.contains("requirement") || !lowercaseContent.contains("statement") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Must produce a clear Statement of Requirements",
                farReference: "FAR 11.002",
                suggestedFix: "Include a comprehensive Statement of Requirements section"
            ))
        }
        if !lowercaseContent.contains("objective") || !lowercaseContent.contains("deliverable") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Must define clear objectives and deliverables",
                farReference: "FAR 11.101",
                suggestedFix: "Include specific objectives and measurable deliverables"
            ))
        }
        if !lowercaseContent.contains("timeline") || !lowercaseContent.contains("budget") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Must address timeline and budget considerations",
                farReference: "FAR 11.002(a)",
                suggestedFix: "Include timeline requirements and budget constraints"
            ))
        }

    case .requestForQuoteSimplified:
        // Simplified RFQ validation
        if !lowercaseContent.contains("quote"), !lowercaseContent.contains("price") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "RFQ must request pricing information",
                farReference: "FAR 13.106",
                suggestedFix: "Include clear request for price quotes"
            ))
        }
        if !lowercaseContent.contains("delivery"), !lowercaseContent.contains("when") {
            issues.append(ComplianceIssue(
                severity: .minor,
                description: "RFQ should specify delivery timeframe",
                farReference: "FAR 12.303",
                suggestedFix: "Add delivery timeframe or 'as soon as possible'"
            ))
        }

    case .requestForQuote:
        // RFQ validation
        if !lowercaseContent.contains("quote") || !lowercaseContent.contains("price") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "RFQ must request pricing information",
                farReference: "FAR 13.106",
                suggestedFix: "Include clear request for price quotes"
            ))
        }
        if !lowercaseContent.contains("delivery") || !lowercaseContent.contains("schedule") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "RFQ must specify delivery requirements",
                farReference: "FAR 12.303",
                suggestedFix: "Add delivery schedule and location requirements"
            ))
        }

    case .requestForProposal:
        // RFP validation
        if !lowercaseContent.contains("evaluation") || !lowercaseContent.contains("criteria") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "RFP must include evaluation criteria",
                farReference: "FAR 15.304",
                suggestedFix: "Add Section M - Evaluation Factors"
            ))
        }
        if !lowercaseContent.contains("proposal") || !lowercaseContent.contains("submission") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "RFP must include proposal submission instructions",
                farReference: "FAR 15.209",
                suggestedFix: "Add Section L - Instructions to Offerors"
            ))
        }
        if !lowercaseContent.contains("technical"), !lowercaseContent.contains("requirement") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "RFP must include technical requirements",
                farReference: "FAR 15.203",
                suggestedFix: "Add detailed technical requirements and specifications"
            ))
        }

    case .contractScaffold:
        // Contract Scaffold validation
        if !lowercaseContent.contains("section") || !lowercaseContent.contains("contract") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Contract must include standard section structure",
                farReference: "FAR 15.204",
                suggestedFix: "Include all required contract sections (A through M)"
            ))
        }
        if !lowercaseContent.contains("clause") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "Contract must include required FAR clauses",
                farReference: "FAR 52.2",
                suggestedFix: "Add Section I with all applicable FAR clauses"
            ))
        }

    case .corAppointment:
        // COR Appointment validation
        if !lowercaseContent.contains("authority") || !lowercaseContent.contains("limitation") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "COR appointment must define authorities and limitations",
                farReference: "FAR 1.604",
                suggestedFix: "Clearly define delegated authorities and limitations"
            ))
        }
        if !lowercaseContent.contains("responsibilit") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "COR appointment must specify responsibilities",
                farReference: "FAR 1.604",
                suggestedFix: "Include specific technical and administrative responsibilities"
            ))
        }

    case .analytics:
        // Analytics validation
        if !lowercaseContent.contains("metric") && !lowercaseContent.contains("kpi") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Analytics should include key performance metrics",
                farReference: "FAR 7.103",
                suggestedFix: "Add procurement KPIs and performance metrics"
            ))
        }
        if !lowercaseContent.contains("spend") || !lowercaseContent.contains("analysis") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "Analytics should include spend analysis",
                farReference: "FAR 7.102",
                suggestedFix: "Include spend analysis by category and vendor"
            ))
        }

    case .otherTransactionAgreement:
        // OT Agreement validation
        if !lowercaseContent.contains("10 u.s.c"), !lowercaseContent.contains("2371b") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "OT Agreement must cite statutory authority",
                farReference: "10 U.S.C. § 2371b",
                suggestedFix: "Include reference to 10 U.S.C. § 2371b authority"
            ))
        }
        if !lowercaseContent.contains("prototype") {
            issues.append(ComplianceIssue(
                severity: .critical,
                description: "OT Agreement must describe prototype project",
                farReference: "10 U.S.C. § 2371b(a)",
                suggestedFix: "Include clear prototype project description"
            ))
        }
        if !lowercaseContent.contains("milestone") {
            issues.append(ComplianceIssue(
                severity: .major,
                description: "OT Agreement should include milestone payment structure",
                farReference: "DoD OT Guide 3.3",
                suggestedFix: "Add milestone-based payment schedule"
            ))
        }
        if !lowercaseContent.contains("cost shar") {
            issues.append(ComplianceIssue(
                severity: .minor,
                description: "Consider cost sharing arrangements",
                farReference: "10 U.S.C. § 2371(e)(2)",
                suggestedFix: "Include cost sharing percentages if applicable"
            ))
        }
        
    case .farUpdates:
        // FAR Updates don't require specific compliance validation
        // They are informational documents
        break
    }

    return issues
}

private func calculateComplianceScore(issues: [ComplianceIssue]) -> Double {
    if issues.isEmpty { return 1.0 }

    let totalDeductions = issues.reduce(0.0) { total, issue in
        switch issue.severity {
        case .critical: total + 0.4
        case .major: total + 0.2
        case .minor: total + 0.1
        case .informational: total + 0.05
        }
    }

    return max(0.0, 1.0 - totalDeductions)
}

private func generateRecommendations(for documentType: DocumentType, issues: [ComplianceIssue]) -> [String] {
    var recommendations: [String] = []

    if issues.isEmpty {
        recommendations.append("Document meets FAR compliance requirements")
    } else {
        recommendations.append("Address \(issues.count) compliance issues identified")

        let criticalIssues = issues.filter { $0.severity == .critical }
        if !criticalIssues.isEmpty {
            recommendations.append("Prioritize \(criticalIssues.count) critical compliance issues")
        }

        // Add specific recommendations based on document type
        switch documentType {
        case .sow:
            recommendations.append("Ensure clear scope definition and deliverable specifications")
        case .soo:
            recommendations.append("Define clear objectives while allowing contractor innovation")
        case .pws:
            recommendations.append("Focus on measurable performance outcomes")
        case .qasp:
            recommendations.append("Define specific quality surveillance procedures")
        case .costEstimate:
            recommendations.append("Provide detailed cost breakdown and analysis")
        case .marketResearch:
            recommendations.append("Conduct thorough market analysis per FAR Part 10")
        case .acquisitionPlan:
            recommendations.append("Develop comprehensive acquisition strategy per FAR Part 7")
        case .evaluationPlan:
            recommendations.append("Create objective evaluation criteria per FAR 52.212-2 and FAR 15.304")
        case .fiscalLawReview:
            recommendations.append("Ensure fiscal law compliance and proper funding alignment")
        case .opsecReview:
            recommendations.append("Address all security requirements and OPSEC considerations")
        case .industryRFI:
            recommendations.append("Clearly articulate information needs per FAR 15.201")
        case .sourcesSought:
            recommendations.append("Provide comprehensive capability requirements per FAR 5.205")
        case .justificationApproval:
            recommendations.append("Thoroughly justify limited competition per FAR 6.303")
        case .codes:
            recommendations.append("Ensure accurate NAICS/PSC codes and size standards per FAR 19.102")
        case .competitionAnalysis:
            recommendations.append("Provide data-driven competition strategy per FAR Parts 6 and 19")
        case .procurementSourcing:
            recommendations.append("Verify all vendors in SAM.gov and provide complete contact information per FAR 4.1102")
        case .rrd:
            recommendations.append("Develop comprehensive Statement of Requirements per FAR 11.002")
        case .requestForQuoteSimplified:
            recommendations.append("Keep RFQ simple and focused for micro-purchases under FAR 13.201")
        case .requestForQuote:
            recommendations.append("Ensure clear pricing structure and delivery requirements per FAR 13.106")
        case .requestForProposal:
            recommendations.append("Include comprehensive evaluation criteria and proposal instructions per FAR 15.2")
        case .contractScaffold:
            recommendations.append("Ensure complete contract structure with all required sections per FAR 15.204")
        case .corAppointment:
            recommendations.append("Clearly define COR authorities and limitations per FAR 1.604")
        case .analytics:
            recommendations.append("Include comprehensive procurement metrics and spend analysis per FAR 7.102")
        case .otherTransactionAgreement:
            recommendations.append("Structure agreement to maximize innovation and non-traditional participation per 10 U.S.C. § 2371b")
        case .farUpdates:
            recommendations.append("Review recent FAR/DFAR updates for impact on current contracts")
        }
    }

    return recommendations
}

public extension DependencyValues {
    var farComplianceService: FARComplianceService {
        get { self[FARComplianceService.self] }
        set { self[FARComplianceService.self] = newValue }
    }
}
