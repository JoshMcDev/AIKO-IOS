import ComposableArchitecture
import Foundation

// MARK: - CMMC Requirement Templates Service

public struct CMMCRequirementTemplates: Sendable {
    public var loadTemplate: @Sendable (CMMCDomain, CMMCLevel) async throws -> CMMCDomainTemplate
    public var generateImplementationGuide: @Sendable (CMMCRequirement) async throws -> ImplementationGuide
    public var createAssessmentChecklist: @Sendable (CMMCLevel) async throws -> AssessmentChecklist
    public var exportSSP: @Sendable (CMMCLevel, [CMMCRequirement]) async throws -> String

    public init(
        loadTemplate: @escaping @Sendable (CMMCDomain, CMMCLevel) async throws -> CMMCDomainTemplate,
        generateImplementationGuide: @escaping @Sendable (CMMCRequirement) async throws -> ImplementationGuide,
        createAssessmentChecklist: @escaping @Sendable (CMMCLevel) async throws -> AssessmentChecklist,
        exportSSP: @escaping @Sendable (CMMCLevel, [CMMCRequirement]) async throws -> String
    ) {
        self.loadTemplate = loadTemplate
        self.generateImplementationGuide = generateImplementationGuide
        self.createAssessmentChecklist = createAssessmentChecklist
        self.exportSSP = exportSSP
    }
}

// MARK: - Template Models

public struct CMMCDomainTemplate: Sendable {
    public let domain: CMMCDomain
    public let level: CMMCLevel
    public let description: String
    public let requirements: [CMMCRequirementTemplate]
    public let commonImplementations: [String]
    public let documentationNeeded: [String]

    public init(
        domain: CMMCDomain,
        level: CMMCLevel,
        description: String,
        requirements: [CMMCRequirementTemplate],
        commonImplementations: [String],
        documentationNeeded: [String]
    ) {
        self.domain = domain
        self.level = level
        self.description = description
        self.requirements = requirements
        self.commonImplementations = commonImplementations
        self.documentationNeeded = documentationNeeded
    }
}

public struct CMMCRequirementTemplate: Sendable {
    public let requirementId: String
    public let description: String
    public let implementationSteps: [String]
    public let evidenceRequired: [String]
    public let commonTools: [String]
    public let estimatedEffort: String
    public let dependencies: [String]

    public init(
        requirementId: String,
        description: String,
        implementationSteps: [String],
        evidenceRequired: [String],
        commonTools: [String],
        estimatedEffort: String,
        dependencies: [String]
    ) {
        self.requirementId = requirementId
        self.description = description
        self.implementationSteps = implementationSteps
        self.evidenceRequired = evidenceRequired
        self.commonTools = commonTools
        self.estimatedEffort = estimatedEffort
        self.dependencies = dependencies
    }
}

public struct ImplementationGuide: Sendable {
    public let requirement: CMMCRequirement
    public let quickStart: String
    public let detailedSteps: [ImplementationStep]
    public let templateDocuments: [String]
    public let validationChecklist: [String]

    public init(
        requirement: CMMCRequirement,
        quickStart: String,
        detailedSteps: [ImplementationStep],
        templateDocuments: [String],
        validationChecklist: [String]
    ) {
        self.requirement = requirement
        self.quickStart = quickStart
        self.detailedSteps = detailedSteps
        self.templateDocuments = templateDocuments
        self.validationChecklist = validationChecklist
    }
}

public struct ImplementationStep: Sendable {
    public let stepNumber: Int
    public let title: String
    public let description: String
    public let expectedOutcome: String
    public let timeEstimate: String

    public init(
        stepNumber: Int,
        title: String,
        description: String,
        expectedOutcome: String,
        timeEstimate: String
    ) {
        self.stepNumber = stepNumber
        self.title = title
        self.description = description
        self.expectedOutcome = expectedOutcome
        self.timeEstimate = timeEstimate
    }
}

public struct AssessmentChecklist: Sendable {
    public let level: CMMCLevel
    public let domains: [DomainChecklist]
    public let totalRequirements: Int
    public let assessmentInstructions: String

    public init(
        level: CMMCLevel,
        domains: [DomainChecklist],
        totalRequirements: Int,
        assessmentInstructions: String
    ) {
        self.level = level
        self.domains = domains
        self.totalRequirements = totalRequirements
        self.assessmentInstructions = assessmentInstructions
    }
}

public struct DomainChecklist: Sendable {
    public let domain: CMMCDomain
    public let checklistItems: [ChecklistItem]

    public init(domain: CMMCDomain, checklistItems: [ChecklistItem]) {
        self.domain = domain
        self.checklistItems = checklistItems
    }
}

public struct ChecklistItem: Sendable {
    public let requirementId: String
    public let checkDescription: String
    public let evidenceToReview: [String]
    public let interviewQuestions: [String]
    public let testProcedures: [String]

    public init(
        requirementId: String,
        checkDescription: String,
        evidenceToReview: [String],
        interviewQuestions: [String],
        testProcedures: [String]
    ) {
        self.requirementId = requirementId
        self.checkDescription = checkDescription
        self.evidenceToReview = evidenceToReview
        self.interviewQuestions = interviewQuestions
        self.testProcedures = testProcedures
    }
}

// MARK: - Live Value

extension CMMCRequirementTemplates: DependencyKey {
    public static var liveValue: CMMCRequirementTemplates {
        CMMCRequirementTemplates(
            loadTemplate: { domain, level in
                switch (domain, level) {
                case (.accessControl, .level1):
                    accessControlLevel1Template
                case (.accessControl, .level2):
                    accessControlLevel2Template
                case (.accessControl, .level3):
                    accessControlLevel3Template
                case (.identificationAndAuthentication, .level1):
                    identificationAuthLevel1Template
                case (.identificationAndAuthentication, .level2):
                    identificationAuthLevel2Template
                case (.auditAndAccountability, .level2):
                    auditLevel2Template
                case (.systemAndCommunicationsProtection, .level1):
                    systemProtectionLevel1Template
                default:
                    createGenericTemplate(for: domain, level: level)
                }
            },

            generateImplementationGuide: { requirement in
                ImplementationGuide(
                    requirement: requirement,
                    quickStart: generateQuickStart(for: requirement),
                    detailedSteps: generateDetailedSteps(for: requirement),
                    templateDocuments: getTemplateDocuments(for: requirement),
                    validationChecklist: generateValidationChecklist(for: requirement)
                )
            },

            createAssessmentChecklist: { level in
                let domains = CMMCDomain.allCases
                var domainChecklists: [DomainChecklist] = []
                var totalRequirements = 0

                for domain in domains {
                    let items = generateChecklistItems(for: domain, level: level)
                    if !items.isEmpty {
                        domainChecklists.append(DomainChecklist(domain: domain, checklistItems: items))
                        totalRequirements += items.count
                    }
                }

                return AssessmentChecklist(
                    level: level,
                    domains: domainChecklists,
                    totalRequirements: totalRequirements,
                    assessmentInstructions: getAssessmentInstructions(for: level)
                )
            },

            exportSSP: { level, requirements in
                generateSystemSecurityPlan(for: level, requirements: requirements)
            }
        )
    }
}

// MARK: - Domain Templates

private let accessControlLevel1Template = CMMCDomainTemplate(
    domain: .accessControl,
    level: .level1,
    description: "Basic safeguarding requirements for access control",
    requirements: [
        CMMCRequirementTemplate(
            requirementId: "AC.L1-3.1.1",
            description: "Limit system access to authorized users",
            implementationSteps: [
                "Create user account management procedures",
                "Document authorized user list",
                "Implement account request/approval process",
                "Configure system access controls",
                "Remove default accounts"
            ],
            evidenceRequired: [
                "User account list",
                "Account management procedures",
                "Access approval forms",
                "System configuration screenshots"
            ],
            commonTools: ["Active Directory", "LDAP", "Local user management"],
            estimatedEffort: "4-8 hours",
            dependencies: []
        ),
        CMMCRequirementTemplate(
            requirementId: "AC.L1-3.1.2",
            description: "Limit system access to the types of transactions and functions that authorized users are permitted to execute",
            implementationSteps: [
                "Define user roles and permissions",
                "Implement role-based access control",
                "Configure least privilege access",
                "Document permission matrix",
                "Test access restrictions"
            ],
            evidenceRequired: [
                "Role definitions",
                "Permission matrix",
                "RBAC configuration",
                "Test results"
            ],
            commonTools: ["Group Policy", "ACLs", "Application permissions"],
            estimatedEffort: "8-16 hours",
            dependencies: ["AC.L1-3.1.1"]
        )
    ],
    commonImplementations: [
        "Active Directory Group Policy",
        "Role-Based Access Control (RBAC)",
        "Principle of Least Privilege",
        "Access Control Lists (ACLs)"
    ],
    documentationNeeded: [
        "Access Control Policy",
        "User Account Management Procedures",
        "Authorization Matrix",
        "Account Request Forms"
    ]
)

private let accessControlLevel2Template = CMMCDomainTemplate(
    domain: .accessControl,
    level: .level2,
    description: "Intermediate cyber hygiene practices for access control",
    requirements: [
        CMMCRequirementTemplate(
            requirementId: "AC.L2-3.1.3",
            description: "Control the flow of CUI in accordance with approved authorizations",
            implementationSteps: [
                "Identify all CUI data flows",
                "Map data flow diagrams",
                "Implement data loss prevention",
                "Configure boundary protections",
                "Monitor unauthorized transfers"
            ],
            evidenceRequired: [
                "Data flow diagrams",
                "DLP policies",
                "Firewall rules",
                "Monitoring logs"
            ],
            commonTools: ["DLP solutions", "Firewalls", "CASB", "Email gateways"],
            estimatedEffort: "40-80 hours",
            dependencies: ["AC.L1-3.1.1", "AC.L1-3.1.2"]
        ),
        CMMCRequirementTemplate(
            requirementId: "AC.L2-3.1.4",
            description: "Separate the duties of individuals to reduce the risk of malevolent activity",
            implementationSteps: [
                "Identify critical functions",
                "Define separation requirements",
                "Redistribute responsibilities",
                "Implement approval workflows",
                "Document duty matrices"
            ],
            evidenceRequired: [
                "Separation of duties matrix",
                "Workflow documentation",
                "Approval processes",
                "Role assignments"
            ],
            commonTools: ["Workflow systems", "Ticketing systems", "Change management"],
            estimatedEffort: "16-32 hours",
            dependencies: ["AC.L1-3.1.2"]
        )
    ],
    commonImplementations: [
        "Data Loss Prevention (DLP)",
        "Network segmentation",
        "Separation of duties matrix",
        "Workflow automation"
    ],
    documentationNeeded: [
        "Data Flow Diagrams",
        "CUI Handling Procedures",
        "Separation of Duties Policy",
        "Information Flow Enforcement Rules"
    ]
)

private let accessControlLevel3Template = CMMCDomainTemplate(
    domain: .accessControl,
    level: .level3,
    description: "Advanced/progressive cyber hygiene practices for access control",
    requirements: [
        CMMCRequirementTemplate(
            requirementId: "AC.L3-3.1.12e",
            description: "Employ cryptographic mechanisms to protect the confidentiality of remote access sessions",
            implementationSteps: [
                "Implement VPN with strong encryption",
                "Configure TLS 1.2 or higher",
                "Deploy certificate-based authentication",
                "Enable perfect forward secrecy",
                "Monitor encryption strength"
            ],
            evidenceRequired: [
                "VPN configuration",
                "Encryption policies",
                "Certificate management",
                "Cipher suite configuration"
            ],
            commonTools: ["VPN solutions", "PKI infrastructure", "SSL/TLS certificates"],
            estimatedEffort: "24-48 hours",
            dependencies: ["SC.L2-3.13.8", "IA.L2-3.5.3"]
        )
    ],
    commonImplementations: [
        "Enterprise VPN solutions",
        "PKI infrastructure",
        "Certificate-based authentication",
        "Advanced encryption standards"
    ],
    documentationNeeded: [
        "Cryptographic Policy",
        "Remote Access Procedures",
        "Certificate Management Plan",
        "Encryption Standards"
    ]
)

private let identificationAuthLevel1Template = CMMCDomainTemplate(
    domain: .identificationAndAuthentication,
    level: .level1,
    description: "Basic identification and authentication requirements",
    requirements: [
        CMMCRequirementTemplate(
            requirementId: "IA.L1-3.5.1",
            description: "Identify system users, processes acting on behalf of users, and devices",
            implementationSteps: [
                "Implement unique user identification",
                "Assign unique device identifiers",
                "Document service accounts",
                "Create identification standards",
                "Maintain identifier inventory"
            ],
            evidenceRequired: [
                "User ID standards",
                "Device inventory",
                "Service account list",
                "Naming conventions"
            ],
            commonTools: ["Identity management systems", "Asset management tools"],
            estimatedEffort: "8-16 hours",
            dependencies: []
        ),
        CMMCRequirementTemplate(
            requirementId: "IA.L1-3.5.2",
            description: "Authenticate the identities of users, processes, or devices as a prerequisite to allowing access",
            implementationSteps: [
                "Implement authentication mechanisms",
                "Configure password policies",
                "Deploy authentication servers",
                "Enable device authentication",
                "Test authentication flows"
            ],
            evidenceRequired: [
                "Authentication configuration",
                "Password policy",
                "Authentication logs",
                "Test documentation"
            ],
            commonTools: ["Active Directory", "RADIUS", "LDAP", "802.1X"],
            estimatedEffort: "16-32 hours",
            dependencies: ["IA.L1-3.5.1"]
        )
    ],
    commonImplementations: [
        "Active Directory authentication",
        "Password complexity requirements",
        "Account lockout policies",
        "Device certificates"
    ],
    documentationNeeded: [
        "Identification and Authentication Policy",
        "Password Standards",
        "Account Management Procedures",
        "Device Registration Process"
    ]
)

private let identificationAuthLevel2Template = CMMCDomainTemplate(
    domain: .identificationAndAuthentication,
    level: .level2,
    description: "Enhanced identification and authentication practices",
    requirements: [
        CMMCRequirementTemplate(
            requirementId: "IA.L2-3.5.3",
            description: "Use multifactor authentication for local and network access to privileged accounts",
            implementationSteps: [
                "Identify all privileged accounts",
                "Deploy MFA solution",
                "Configure MFA policies",
                "Enroll privileged users",
                "Test MFA scenarios"
            ],
            evidenceRequired: [
                "Privileged account inventory",
                "MFA configuration",
                "Enrollment records",
                "MFA policy documentation"
            ],
            commonTools: ["Microsoft Authenticator", "Duo", "RSA SecurID", "YubiKey"],
            estimatedEffort: "24-48 hours",
            dependencies: ["IA.L1-3.5.1", "IA.L1-3.5.2"]
        )
    ],
    commonImplementations: [
        "Time-based OTP (TOTP)",
        "SMS-based MFA",
        "Hardware tokens",
        "Biometric authentication"
    ],
    documentationNeeded: [
        "MFA Policy",
        "Privileged Account Inventory",
        "MFA Enrollment Procedures",
        "Backup Authentication Methods"
    ]
)

private let auditLevel2Template = CMMCDomainTemplate(
    domain: .auditAndAccountability,
    level: .level2,
    description: "Audit and accountability requirements for Level 2",
    requirements: [
        CMMCRequirementTemplate(
            requirementId: "AU.L2-3.3.1",
            description: "Create and retain system audit logs and records",
            implementationSteps: [
                "Enable system logging",
                "Configure log retention",
                "Centralize log collection",
                "Protect log integrity",
                "Document retention periods"
            ],
            evidenceRequired: [
                "Logging configuration",
                "Retention policies",
                "Log samples",
                "Storage capacity planning"
            ],
            commonTools: ["Syslog", "Windows Event Log", "SIEM", "Log management"],
            estimatedEffort: "16-32 hours",
            dependencies: []
        ),
        CMMCRequirementTemplate(
            requirementId: "AU.L2-3.3.2",
            description: "Ensure that the actions of individual system users can be uniquely traced",
            implementationSteps: [
                "Enable user activity logging",
                "Correlate user sessions",
                "Implement log analysis",
                "Create audit trails",
                "Test traceability"
            ],
            evidenceRequired: [
                "User activity logs",
                "Correlation rules",
                "Audit trail samples",
                "Traceability testing"
            ],
            commonTools: ["SIEM solutions", "Log analyzers", "User behavior analytics"],
            estimatedEffort: "24-48 hours",
            dependencies: ["AU.L2-3.3.1", "IA.L1-3.5.1"]
        )
    ],
    commonImplementations: [
        "Centralized logging",
        "SIEM deployment",
        "Log correlation rules",
        "Automated alerting"
    ],
    documentationNeeded: [
        "Audit and Logging Policy",
        "Log Retention Schedule",
        "Audit Review Procedures",
        "Incident Investigation Guide"
    ]
)

private let systemProtectionLevel1Template = CMMCDomainTemplate(
    domain: .systemAndCommunicationsProtection,
    level: .level1,
    description: "Basic system and communications protection",
    requirements: [
        CMMCRequirementTemplate(
            requirementId: "SC.L1-3.13.1",
            description: "Monitor, control, and protect communications at external boundaries",
            implementationSteps: [
                "Deploy boundary firewalls",
                "Configure access rules",
                "Enable traffic monitoring",
                "Implement IDS/IPS",
                "Document network diagram"
            ],
            evidenceRequired: [
                "Network diagrams",
                "Firewall rules",
                "IDS/IPS configuration",
                "Traffic logs"
            ],
            commonTools: ["Firewalls", "IDS/IPS", "Network monitors", "UTM devices"],
            estimatedEffort: "32-64 hours",
            dependencies: []
        )
    ],
    commonImplementations: [
        "Next-gen firewalls",
        "Intrusion detection systems",
        "Network segmentation",
        "DMZ implementation"
    ],
    documentationNeeded: [
        "Network Security Policy",
        "Firewall Rule Matrix",
        "Network Diagrams",
        "Boundary Protection Plan"
    ]
)

// MARK: - Helper Functions

private func createGenericTemplate(for domain: CMMCDomain, level: CMMCLevel) -> CMMCDomainTemplate {
    CMMCDomainTemplate(
        domain: domain,
        level: level,
        description: "Requirements for \(domain.rawValue) at \(level.rawValue)",
        requirements: [],
        commonImplementations: ["Consult CMMC assessment guide"],
        documentationNeeded: ["Policy documentation", "Procedures", "Evidence collection"]
    )
}

private func generateQuickStart(for requirement: CMMCRequirement) -> String {
    """
    Quick Start Guide for \(requirement.id):
    1. Review the requirement: \(requirement.description)
    2. Assess current implementation status
    3. Identify gaps and required resources
    4. Follow implementation steps
    5. Collect required evidence
    6. Validate implementation
    """
}

private func generateDetailedSteps(for _: CMMCRequirement) -> [ImplementationStep] {
    [
        ImplementationStep(
            stepNumber: 1,
            title: "Current State Assessment",
            description: "Evaluate existing controls and identify gaps",
            expectedOutcome: "Gap analysis document",
            timeEstimate: "2-4 hours"
        ),
        ImplementationStep(
            stepNumber: 2,
            title: "Planning and Design",
            description: "Design implementation approach and timeline",
            expectedOutcome: "Implementation plan",
            timeEstimate: "4-8 hours"
        ),
        ImplementationStep(
            stepNumber: 3,
            title: "Implementation",
            description: "Execute the implementation plan",
            expectedOutcome: "Implemented control",
            timeEstimate: "Varies"
        ),
        ImplementationStep(
            stepNumber: 4,
            title: "Testing and Validation",
            description: "Test control effectiveness",
            expectedOutcome: "Test results and evidence",
            timeEstimate: "2-4 hours"
        ),
        ImplementationStep(
            stepNumber: 5,
            title: "Documentation",
            description: "Document procedures and collect evidence",
            expectedOutcome: "Complete documentation package",
            timeEstimate: "2-4 hours"
        )
    ]
}

private func getTemplateDocuments(for requirement: CMMCRequirement) -> [String] {
    var templates: [String] = ["Policy Template", "Procedure Template", "Evidence Log"]

    if requirement.domain == .accessControl {
        templates.append("Access Control Matrix Template")
    } else if requirement.domain == .auditAndAccountability {
        templates.append("Audit Log Review Checklist")
    } else if requirement.domain == .incidentResponse {
        templates.append("Incident Response Plan Template")
    }

    return templates
}

private func generateValidationChecklist(for _: CMMCRequirement) -> [String] {
    [
        "Control is fully implemented",
        "Documentation is complete and current",
        "Evidence demonstrates effectiveness",
        "Personnel are trained on procedures",
        "Control is integrated with other practices",
        "Monitoring and metrics are in place"
    ]
}

private func generateChecklistItems(for _: CMMCDomain, level _: CMMCLevel) -> [ChecklistItem] {
    // This would normally pull from a comprehensive database
    // For now, returning sample items
    []
}

private func getAssessmentInstructions(for level: CMMCLevel) -> String {
    """
    CMMC \(level.rawValue) Assessment Instructions:

    1. Review all applicable practices for this level
    2. Gather evidence for each practice
    3. Interview relevant personnel
    4. Observe control implementation
    5. Test control effectiveness
    6. Document findings and gaps
    7. Calculate domain scores
    8. Determine overall compliance status

    Note: All practices must be fully implemented to achieve certification.
    """
}

private func generateSystemSecurityPlan(for level: CMMCLevel, requirements: [CMMCRequirement]) -> String {
    """
    SYSTEM SECURITY PLAN (SSP)
    CMMC \(level.rawValue) Implementation

    1. SYSTEM INFORMATION
    Organization: {{ORGANIZATION}}
    System Name: {{SYSTEM_NAME}}
    System Type: {{SYSTEM_TYPE}}

    2. SYSTEM BOUNDARIES
    {{BOUNDARY_DESCRIPTION}}

    3. IMPLEMENTED CONTROLS
    \(requirements.map { "- \($0.id): \($0.description)" }.joined(separator: "\n"))

    4. CONTROL IMPLEMENTATION DETAILS
    [Detailed implementation for each control]

    5. ROLES AND RESPONSIBILITIES
    - System Owner: {{OWNER}}
    - Security Officer: {{SECURITY_OFFICER}}
    - System Administrator: {{ADMIN}}

    6. SYSTEM INTERCONNECTIONS
    {{INTERCONNECTIONS}}

    7. LAWS AND REGULATIONS
    - CMMC Level \(level.rawValue) Requirements
    - NIST SP 800-171
    - FAR 52.204-21
    - DFARS 252.204-7012

    8. APPENDICES
    A. Network Diagrams
    B. Hardware/Software Inventory
    C. Control Evidence
    D. POA&M
    """
}

// MARK: - Test Value

public extension CMMCRequirementTemplates {
    static var testValue: CMMCRequirementTemplates {
        CMMCRequirementTemplates(
            loadTemplate: { _, _ in
                CMMCDomainTemplate(
                    domain: .accessControl,
                    level: .level1,
                    description: "Test template",
                    requirements: [],
                    commonImplementations: [],
                    documentationNeeded: []
                )
            },
            generateImplementationGuide: { requirement in
                ImplementationGuide(
                    requirement: requirement,
                    quickStart: "Test quick start",
                    detailedSteps: [],
                    templateDocuments: [],
                    validationChecklist: []
                )
            },
            createAssessmentChecklist: { level in
                AssessmentChecklist(
                    level: level,
                    domains: [],
                    totalRequirements: 0,
                    assessmentInstructions: "Test instructions"
                )
            },
            exportSSP: { _, _ in "Test SSP" }
        )
    }
}

// MARK: - Dependency Registration

public extension DependencyValues {
    var cmmcRequirementTemplates: CMMCRequirementTemplates {
        get { self[CMMCRequirementTemplates.self] }
        set { self[CMMCRequirementTemplates.self] = newValue }
    }
}
