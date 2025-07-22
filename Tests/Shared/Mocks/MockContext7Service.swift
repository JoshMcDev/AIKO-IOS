import AppCore
import ComposableArchitecture
import Foundation

/// Mock Context7 Service for testing purposes
///
/// This mock service simulates Context7 MCP Server functionality for:
/// - Federal regulation updates and compliance monitoring
/// - User behavior insights
/// - Security policy updates
/// - Regulation search capabilities
///
/// Note: This is a test mock implementation. In production, the actual Context7
/// MCP server would provide real-time federal regulation data.
///
/// Usage:
/// ```swift
/// // In tests
/// let mockService = MockContext7Service.testValue
///
/// // For integration testing with delayed responses
/// let integrationService = MockContext7Service.integrationValue
/// ```
public struct MockContext7Service {
    // Core Context7 capabilities
    public var getRegulationUpdates: (Context7RegulationCategory) async throws -> [Context7RegulationUpdate]
    public var validateCompliance: (DocumentType, String) async throws -> Context7ComplianceResult
    public var getUserBehaviorInsights: () async throws -> UserBehaviorInsights
    public var getSecurityPolicyUpdates: () async throws -> [SecurityPolicy]
    public var searchRegulations: (String) async throws -> [Context7SearchResult]

    public init(
        getRegulationUpdates: @escaping (Context7RegulationCategory) async throws -> [Context7RegulationUpdate],
        validateCompliance: @escaping (DocumentType, String) async throws -> Context7ComplianceResult,
        getUserBehaviorInsights: @escaping () async throws -> UserBehaviorInsights,
        getSecurityPolicyUpdates: @escaping () async throws -> [SecurityPolicy],
        searchRegulations: @escaping (String) async throws -> [Context7SearchResult]
    ) {
        self.getRegulationUpdates = getRegulationUpdates
        self.validateCompliance = validateCompliance
        self.getUserBehaviorInsights = getUserBehaviorInsights
        self.getSecurityPolicyUpdates = getSecurityPolicyUpdates
        self.searchRegulations = searchRegulations
    }
}

// MARK: - Mock Models (Used only for testing)

public enum Context7RegulationCategory: String, CaseIterable {
    case far = "Federal Acquisition Regulation"
    case dfars = "Defense Federal Acquisition Regulation Supplement"
    case gsam = "General Services Administration Manual"
    case fedramp = "Federal Risk and Authorization Management Program"
    case nist = "NIST Guidelines"
    case all = "All Categories"
}

public struct Context7RegulationUpdate: Identifiable, Equatable {
    public let id = UUID()
    public let category: Context7RegulationCategory
    public let title: String
    public let description: String
    public let effectiveDate: Date
    public let impactLevel: ImpactLevel
    public let affectedDocumentTypes: [DocumentType]
    public let farReference: String
    public let changesSummary: String

    public enum ImpactLevel: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        public var color: String {
            switch self {
            case .critical: "red"
            case .high: "orange"
            case .medium: "yellow"
            case .low: "green"
            }
        }
    }
}

public struct Context7ComplianceResult: Equatable {
    public let isCompliant: Bool
    public let complianceScore: Double // 0.0 to 1.0
    public let regulationMatches: [RegulationMatch]
    public let recommendations: [ComplianceRecommendation]
    public let lastUpdated: Date

    public struct RegulationMatch: Equatable {
        public let regulation: String
        public let clause: String
        public let matchConfidence: Double
        public let explanation: String
    }

    public struct ComplianceRecommendation: Equatable {
        public let priority: Priority
        public let recommendation: String
        public let relatedRegulation: String
        public let estimatedEffort: String

        public enum Priority: String, CaseIterable {
            case immediate = "Immediate"
            case high = "High"
            case medium = "Medium"
            case low = "Low"
        }
    }
}

public struct UserBehaviorInsights: Equatable {
    public let mostUsedDocumentTypes: [DocumentType]
    public let averageCompletionTime: TimeInterval
    public let commonRequirementPatterns: [String]
    public let recommendedWorkflows: [WorkflowRecommendation]
    public let usageStatistics: UsageStats

    public struct WorkflowRecommendation: Equatable {
        public let title: String
        public let description: String
        public let efficiency: Double // Percentage improvement
        public let basedOnPatterns: [String]
    }

    public struct UsageStats: Equatable {
        public let totalDocumentsGenerated: Int
        public let successRate: Double
        public let averageDocumentQuality: Double
        public let peakUsageHours: [Int]
    }
}

public struct SecurityPolicy: Identifiable, Equatable {
    public let id = UUID()
    public let policyName: String
    public let category: SecurityCategory
    public let requirements: [String]
    public let lastUpdated: Date
    public let complianceDeadline: Date?
    public let affectedFeatures: [String]

    public enum SecurityCategory: String, CaseIterable {
        case dataProtection = "Data Protection"
        case accessControl = "Access Control"
        case encryption = "Encryption"
        case auditLogging = "Audit Logging"
        case networkSecurity = "Network Security"
    }
}

// MARK: - Mock Implementations

public extension MockContext7Service {
    /// Test value with immediate responses and minimal data
    static var testValue: MockContext7Service {
        MockContext7Service(
            getRegulationUpdates: { _ in [] },
            validateCompliance: { _, _ in
                Context7ComplianceResult(
                    isCompliant: true,
                    complianceScore: 1.0,
                    regulationMatches: [],
                    recommendations: [],
                    lastUpdated: Date()
                )
            },
            getUserBehaviorInsights: {
                UserBehaviorInsights(
                    mostUsedDocumentTypes: [],
                    averageCompletionTime: 0,
                    commonRequirementPatterns: [],
                    recommendedWorkflows: [],
                    usageStatistics: .init(
                        totalDocumentsGenerated: 0,
                        successRate: 0,
                        averageDocumentQuality: 0,
                        peakUsageHours: []
                    )
                )
            },
            getSecurityPolicyUpdates: { [] },
            searchRegulations: { _ in [] }
        )
    }

    /// Integration test value with simulated delays and realistic mock data
    static var integrationValue: MockContext7Service {
        MockContext7Service(
            getRegulationUpdates: { category in
                // Simulate network delay
                try await Task.sleep(nanoseconds: 500_000_000)

                return [
                    Context7RegulationUpdate(
                        category: category,
                        title: "FAR 52.204-27 Update",
                        description: "Prohibition on TikTok and Covered Applications",
                        effectiveDate: Date(),
                        impactLevel: .critical,
                        affectedDocumentTypes: [.sow, .pws],
                        farReference: "FAR 52.204-27",
                        changesSummary: "New clause required in all solicitations and contracts"
                    ),
                    Context7RegulationUpdate(
                        category: category,
                        title: "DFARS 252.204-7012 Revision",
                        description: "Safeguarding Covered Defense Information",
                        effectiveDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                        impactLevel: .high,
                        affectedDocumentTypes: [.qasp, .acquisitionPlan],
                        farReference: "DFARS 252.204-7012",
                        changesSummary: "Enhanced cybersecurity requirements for contractors"
                    )
                ]
            },

            validateCompliance: { _, _ in
                // Simulate analysis delay
                try await Task.sleep(nanoseconds: 750_000_000)

                return Context7ComplianceResult(
                    isCompliant: true,
                    complianceScore: 0.92,
                    regulationMatches: [
                        .init(
                            regulation: "FAR 52.215-2",
                            clause: "Audit and Records",
                            matchConfidence: 0.95,
                            explanation: "Document includes required audit provisions"
                        )
                    ],
                    recommendations: [
                        .init(
                            priority: .medium,
                            recommendation: "Include specific data retention period",
                            relatedRegulation: "FAR 52.215-2",
                            estimatedEffort: "15 minutes"
                        )
                    ],
                    lastUpdated: Date()
                )
            },

            getUserBehaviorInsights: {
                try await Task.sleep(nanoseconds: 500_000_000)

                return UserBehaviorInsights(
                    mostUsedDocumentTypes: [.sow, .pws],
                    averageCompletionTime: 1800, // 30 minutes
                    commonRequirementPatterns: [
                        "software development",
                        "cloud services",
                        "cybersecurity assessment"
                    ],
                    recommendedWorkflows: [
                        .init(
                            title: "Template-based Generation",
                            description: "Use templates for common requirement patterns",
                            efficiency: 0.45,
                            basedOnPatterns: ["software development"]
                        )
                    ],
                    usageStatistics: .init(
                        totalDocumentsGenerated: 156,
                        successRate: 0.94,
                        averageDocumentQuality: 0.88,
                        peakUsageHours: [10, 11, 14, 15]
                    )
                )
            },

            getSecurityPolicyUpdates: {
                try await Task.sleep(nanoseconds: 300_000_000)

                return [
                    SecurityPolicy(
                        policyName: "Zero Trust Architecture",
                        category: .accessControl,
                        requirements: [
                            "Implement multi-factor authentication",
                            "Verify all access requests",
                            "Encrypt data in transit"
                        ],
                        lastUpdated: Date(),
                        complianceDeadline: Date().addingTimeInterval(90 * 24 * 60 * 60),
                        affectedFeatures: ["API Authentication", "Document Access"]
                    )
                ]
            },

            searchRegulations: { _ in
                try await Task.sleep(nanoseconds: 600_000_000)

                return [
                    Context7SearchResult(
                        regulation: "FAR",
                        clause: "52.227-14",
                        title: "Rights in Data—General",
                        content: "The Government shall have unlimited rights in data...",
                        relevanceScore: 0.95,
                        lastUpdated: Date(),
                        relatedDocumentTypes: [.sow, .acquisitionPlan]
                    )
                ]
            }
        )
    }

    /// Failing test value for error handling tests
    static var failingValue: MockContext7Service {
        MockContext7Service(
            getRegulationUpdates: { _ in
                throw MockError.networkError
            },
            validateCompliance: { _, _ in
                throw MockError.validationError
            },
            getUserBehaviorInsights: {
                throw MockError.dataError
            },
            getSecurityPolicyUpdates: {
                throw MockError.authenticationError
            },
            searchRegulations: { _ in
                throw MockError.searchError
            }
        )
    }
}

// MARK: - Mock Errors

public enum MockError: LocalizedError {
    case networkError
    case validationError
    case dataError
    case authenticationError
    case searchError

    public var errorDescription: String? {
        switch self {
        case .networkError:
            "Mock network connection error"
        case .validationError:
            "Mock validation failed"
        case .dataError:
            "Mock data retrieval error"
        case .authenticationError:
            "Mock authentication failed"
        case .searchError:
            "Mock search error"
        }
    }
}

// MARK: - Dependency Support (Optional - for TCA integration in tests)

extension MockContext7Service: DependencyKey {
    public static var liveValue: MockContext7Service {
        // For tests, use the integration value as "live"
        integrationValue
    }
}

public extension DependencyValues {
    var mockContext7Service: MockContext7Service {
        get { self[MockContext7Service.self] }
        set { self[MockContext7Service.self] = newValue }
    }
}
