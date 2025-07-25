import Foundation

// MARK: - CMMC Compliance Tracker

/// Service for tracking Cybersecurity Maturity Model Certification (CMMC) compliance
public struct CMMCComplianceTracker: Sendable {
    public var loadRequirements: @Sendable (CMMCLevel) async throws -> [CMMCRequirement]
    public var trackRequirement: @Sendable (String, CMMCEvidence) async throws -> Void
    public var generateComplianceReport: @Sendable (CMMCLevel) async throws -> CMMCComplianceReport
    public var calculateComplianceScore: @Sendable (CMMCLevel) async throws -> Double
    public var exportComplianceMatrix: @Sendable (CMMCLevel) async throws -> String

    public init(
        loadRequirements: @escaping @Sendable (CMMCLevel) async throws -> [CMMCRequirement],
        trackRequirement: @escaping @Sendable (String, CMMCEvidence) async throws -> Void,
        generateComplianceReport: @escaping @Sendable (CMMCLevel) async throws -> CMMCComplianceReport,
        calculateComplianceScore: @escaping @Sendable (CMMCLevel) async throws -> Double,
        exportComplianceMatrix: @escaping @Sendable (CMMCLevel) async throws -> String
    ) {
        self.loadRequirements = loadRequirements
        self.trackRequirement = trackRequirement
        self.generateComplianceReport = generateComplianceReport
        self.calculateComplianceScore = calculateComplianceScore
        self.exportComplianceMatrix = exportComplianceMatrix
    }
}

// MARK: - Models

public enum CMMCLevel: Int, CaseIterable, Sendable {
    case level1 = 1
    case level2 = 2
    case level3 = 3

    public var name: String {
        switch self {
        case .level1: "Foundational"
        case .level2: "Advanced"
        case .level3: "Expert"
        }
    }

    public var practiceCount: Int {
        switch self {
        case .level1: 17
        case .level2: 72
        case .level3: 130
        }
    }
}

public struct CMMCRequirement: Identifiable, Equatable, Sendable {
    public let id: String
    public let domain: CMMCDomain
    public let practice: String
    public let level: CMMCLevel
    public let description: String
    public let objective: String
    public let discussion: String
    public let nistMapping: [String]
    public var implemented: Bool
    public var evidence: CMMCEvidence?

    public init(
        id: String,
        domain: CMMCDomain,
        practice: String,
        level: CMMCLevel,
        description: String,
        objective: String,
        discussion: String,
        nistMapping: [String],
        implemented: Bool = false,
        evidence: CMMCEvidence? = nil
    ) {
        self.id = id
        self.domain = domain
        self.practice = practice
        self.level = level
        self.description = description
        self.objective = objective
        self.discussion = discussion
        self.nistMapping = nistMapping
        self.implemented = implemented
        self.evidence = evidence
    }
}

public enum CMMCDomain: String, CaseIterable, Sendable {
    case accessControl = "Access Control"
    case assetManagement = "Asset Management"
    case auditAndAccountability = "Audit and Accountability"
    case awarenessAndTraining = "Awareness and Training"
    case configurationManagement = "Configuration Management"
    case identificationAndAuthentication = "Identification and Authentication"
    case incidentResponse = "Incident Response"
    case maintenance = "Maintenance"
    case mediaProtection = "Media Protection"
    case personnelSecurity = "Personnel Security"
    case physicalProtection = "Physical Protection"
    case recoveryManagement = "Recovery Management"
    case riskManagement = "Risk Management"
    case securityAssessment = "Security Assessment"
    case situationalAwareness = "Situational Awareness"
    case systemAndCommunicationsProtection = "System and Communications Protection"
    case systemAndInformationIntegrity = "System and Information Integrity"
}

public struct CMMCEvidence: Equatable, Sendable {
    public let documentName: String
    public let documentType: String
    public let uploadDate: Date
    public let verifiedBy: String?
    public let notes: String?

    public init(
        documentName: String,
        documentType: String,
        uploadDate: Date = Date(),
        verifiedBy: String? = nil,
        notes: String? = nil
    ) {
        self.documentName = documentName
        self.documentType = documentType
        self.uploadDate = uploadDate
        self.verifiedBy = verifiedBy
        self.notes = notes
    }
}

public struct CMMCComplianceReport: Equatable {
    public let level: CMMCLevel
    public let overallScore: Double
    public let domainScores: [CMMCDomain: Double]
    public let implementedCount: Int
    public let totalCount: Int
    public let gaps: [CMMCRequirement]
    public let recommendations: [String]
    public let generatedDate: Date

    public var isCompliant: Bool {
        overallScore >= 1.0 // 100% implementation required
    }
}

// MARK: - Thread-Safe Storage Actor

private actor CMMCStatusStorage {
    private var requirementStatus: [String: (Bool, CMMCEvidence?)] = [:]

    func updateStatus(_ requirementId: String, isImplemented: Bool, evidence: CMMCEvidence?) {
        requirementStatus[requirementId] = (isImplemented, evidence)
    }

    func getStatus(_ requirementId: String) -> (Bool, CMMCEvidence?)? {
        requirementStatus[requirementId]
    }

    func getAllStatuses() -> [String: (Bool, CMMCEvidence?)] {
        requirementStatus
    }
}

// MARK: - Implementation

public extension CMMCComplianceTracker {
    static var liveValue: CMMCComplianceTracker {
        // Thread-safe storage for requirement status
        let storage = CMMCStatusStorage()

        return CMMCComplianceTracker(
            loadRequirements: { level in
                getCMMCRequirements(for: level)
            },

            trackRequirement: { @Sendable requirementId, evidence in
                await storage.updateStatus(requirementId, isImplemented: true, evidence: evidence)
            },

            generateComplianceReport: { @Sendable level in
                let requirements = getCMMCRequirements(for: level)
                var domainCounts: [CMMCDomain: (implemented: Int, total: Int)] = [:]
                var gaps: [CMMCRequirement] = []

                let allStatuses = await storage.getAllStatuses()

                for requirement in requirements {
                    let status = allStatuses[requirement.id]
                    let isImplemented = status?.0 ?? false

                    var counts = domainCounts[requirement.domain] ?? (0, 0)
                    counts.total += 1
                    if isImplemented {
                        counts.implemented += 1
                    } else {
                        gaps.append(requirement)
                    }
                    domainCounts[requirement.domain] = counts
                }

                var domainScores: [CMMCDomain: Double] = [:]
                for (domain, counts) in domainCounts {
                    domainScores[domain] = Double(counts.implemented) / Double(counts.total)
                }

                let implementedCount = domainCounts.values.reduce(0) { $0 + $1.implemented }
                let totalCount = requirements.count
                let overallScore = Double(implementedCount) / Double(totalCount)

                let recommendations = generateRecommendations(for: gaps, level: level)

                return CMMCComplianceReport(
                    level: level,
                    overallScore: overallScore,
                    domainScores: domainScores,
                    implementedCount: implementedCount,
                    totalCount: totalCount,
                    gaps: gaps,
                    recommendations: recommendations,
                    generatedDate: Date()
                )
            },

            calculateComplianceScore: { @Sendable level in
                let requirements = getCMMCRequirements(for: level)
                let allStatuses = await storage.getAllStatuses()
                let implementedCount = requirements.count(where: { allStatuses[$0.id]?.0 ?? false })
                return Double(implementedCount) / Double(requirements.count)
            },

            exportComplianceMatrix: { @Sendable level in
                let requirements = getCMMCRequirements(for: level)
                var csv = "Requirement ID,Domain,Practice,Level,Description,Implemented,Evidence\n"

                let allStatuses = await storage.getAllStatuses()

                for requirement in requirements {
                    let status = allStatuses[requirement.id]
                    let implemented = status?.0 ?? false
                    let evidence = status?.1?.documentName ?? "N/A"

                    csv += "\"\(requirement.id)\",\"\(requirement.domain.rawValue)\",\"\(requirement.practice)\","
                    csv += "\(requirement.level.rawValue),\"\(requirement.description)\","
                    csv += "\(implemented ? "Yes" : "No"),\"\(evidence)\"\n"
                }

                return csv
            }
        )
    }
}

// MARK: - CMMC Requirements Database

private func getCMMCRequirements(for level: CMMCLevel) -> [CMMCRequirement] {
    var requirements: [CMMCRequirement] = []

    // Add Level 1 requirements
    if level.rawValue >= 1 {
        requirements.append(contentsOf: [
            CMMCRequirement(
                id: "AC.L1-b.1.i",
                domain: .accessControl,
                practice: "Limit information system access",
                level: .level1,
                description: "Limit information system access to authorized users, processes acting on behalf of authorized users, or devices (including other information systems).",
                objective: "Control system access to prevent unauthorized use.",
                discussion: "Access control policies and procedures are established to ensure only authorized individuals can access systems.",
                nistMapping: ["AC-2", "AC-3"]
            ),
            CMMCRequirement(
                id: "AC.L1-b.1.ii",
                domain: .accessControl,
                practice: "Limit transaction functions",
                level: .level1,
                description: "Limit information system access to the types of transactions and functions that authorized users are permitted to execute.",
                objective: "Control user permissions based on roles and responsibilities.",
                discussion: "Users should only have access to functions necessary for their job duties.",
                nistMapping: ["AC-2", "AC-3"]
            ),
            CMMCRequirement(
                id: "IA.L1-b.1.v",
                domain: .identificationAndAuthentication,
                practice: "Identify users and devices",
                level: .level1,
                description: "Identify information system users, processes acting on behalf of users, or devices.",
                objective: "Ensure all users and devices are uniquely identified.",
                discussion: "Every user and device must have a unique identifier for accountability.",
                nistMapping: ["IA-2", "IA-3"]
            ),
            CMMCRequirement(
                id: "IA.L1-b.1.vi",
                domain: .identificationAndAuthentication,
                practice: "Authenticate users and devices",
                level: .level1,
                description: "Authenticate (or verify) the identities of those users, processes, or devices, as a prerequisite to allowing access to organizational information systems.",
                objective: "Verify identity before granting access.",
                discussion: "Authentication mechanisms must be in place to verify claimed identities.",
                nistMapping: ["IA-2", "IA-3"]
            ),
            // Add remaining Level 1 requirements...
        ])
    }

    // Add Level 2 requirements
    if level.rawValue >= 2 {
        requirements.append(contentsOf: [
            CMMCRequirement(
                id: "AC.L2-3.1.1",
                domain: .accessControl,
                practice: "Limit system access to authorized users",
                level: .level2,
                description: "Limit information system access to authorized users, processes acting on behalf of authorized users, or devices (including other information systems).",
                objective: "Ensure that only authorized users can access organizational systems.",
                discussion: "Organizations must identify authorized users and processes, and control their access.",
                nistMapping: ["AC-2"]
            ),
            CMMCRequirement(
                id: "AC.L2-3.1.2",
                domain: .accessControl,
                practice: "Limit system access to authorized functions",
                level: .level2,
                description: "Limit information system access to the types of transactions and functions that authorized users are permitted to execute.",
                objective: "Restrict users to only the functions necessary for their roles.",
                discussion: "Implement least privilege principles to minimize potential damage from errors or malicious activity.",
                nistMapping: ["AC-3"]
            ),
            CMMCRequirement(
                id: "AU.L2-3.3.1",
                domain: .auditAndAccountability,
                practice: "Create audit logs",
                level: .level2,
                description: "Create and retain system audit logs and records to the extent needed to enable the monitoring, analysis, investigation, and reporting of unlawful or unauthorized system activity.",
                objective: "Maintain audit logs for security monitoring and incident response.",
                discussion: "Audit logs must capture sufficient detail to reconstruct events and identify responsible parties.",
                nistMapping: ["AU-2", "AU-3", "AU-12"]
            ),
            // Add remaining Level 2 requirements...
        ])
    }

    // Add Level 3 requirements
    if level.rawValue >= 3 {
        requirements.append(contentsOf: [
            CMMCRequirement(
                id: "AC.L3-3.1.12",
                domain: .accessControl,
                practice: "Monitor and control remote access",
                level: .level3,
                description: "Monitor and control remote access sessions.",
                objective: "Actively monitor remote access to detect suspicious activity.",
                discussion: "Organizations must implement real-time monitoring of remote access sessions.",
                nistMapping: ["AC-17(1)"]
            ),
            CMMCRequirement(
                id: "AU.L3-3.3.5",
                domain: .auditAndAccountability,
                practice: "Correlate audit information",
                level: .level3,
                description: "Correlate audit record review, analysis, and reporting processes for investigation and response to indications of unlawful, unauthorized, suspicious, or unusual activity.",
                objective: "Integrate audit data from multiple sources for comprehensive analysis.",
                discussion: "Use automated tools to correlate events across systems and identify patterns.",
                nistMapping: ["AU-6(3)", "AU-12(3)"]
            ),
            CMMCRequirement(
                id: "IR.L3-3.6.2",
                domain: .incidentResponse,
                practice: "Track and document incidents",
                level: .level3,
                description: "Track, document, and report incidents to designated officials and/or authorities both internal and external to the organization.",
                objective: "Maintain comprehensive incident records and ensure proper reporting.",
                discussion: "Document all aspects of incident response including timeline, impact, and remediation.",
                nistMapping: ["IR-4", "IR-5", "IR-6"]
            ),
            // Add remaining Level 3 requirements...
        ])
    }

    return requirements.sorted { $0.id < $1.id }
}

// MARK: - Helper Functions

private func generateRecommendations(for gaps: [CMMCRequirement], level: CMMCLevel) -> [String] {
    var recommendations: [String] = []

    // Group gaps by domain
    let gapsByDomain = Dictionary(grouping: gaps, by: { $0.domain })

    // Priority recommendations based on domain
    if let acGaps = gapsByDomain[.accessControl], !acGaps.isEmpty {
        recommendations.append("Priority 1: Address \(acGaps.count) Access Control gaps - these are fundamental to security")
    }

    if let iaGaps = gapsByDomain[.identificationAndAuthentication], !iaGaps.isEmpty {
        recommendations.append("Priority 2: Implement \(iaGaps.count) Identification & Authentication controls")
    }

    if let auGaps = gapsByDomain[.auditAndAccountability], !auGaps.isEmpty {
        recommendations.append("Priority 3: Establish \(auGaps.count) Audit & Accountability mechanisms")
    }

    // General recommendations
    if gaps.count > 20 {
        recommendations.append("Consider phased implementation approach due to large number of gaps")
    }

    if level == .level3, gaps.contains(where: { $0.level == .level1 }) {
        recommendations.append("Critical: Address all Level 1 basic requirements immediately")
    }

    recommendations.append("Develop Plan of Action & Milestones (POA&M) for all identified gaps")
    recommendations.append("Assign responsible parties and target completion dates")
    recommendations.append("Consider third-party assessment to validate implementation")

    return recommendations
}

// MARK: - Dependency
