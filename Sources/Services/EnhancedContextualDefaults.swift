import Foundation

// MARK: - Enhanced Contextual Defaults System

/// Enhanced contextual defaults that consider multiple environmental factors
public final class EnhancedContextualDefaultsProvider: @unchecked Sendable {
    // MARK: - Types

    public struct ContextualFactors {
        // Temporal Context
        let currentDate: Date
        let fiscalYear: String
        let fiscalQuarter: String
        let isEndOfFiscalYear: Bool
        let daysUntilFYEnd: Int
        let isEndOfQuarter: Bool
        let daysUntilQuarterEnd: Int
        let timeOfDay: TimeOfDay
        let dayOfWeek: DayOfWeek

        // Organizational Context
        let organizationUnit: String
        let department: String
        let location: String
        let budgetRemaining: Decimal?
        let typicalPurchaseAmount: Decimal?
        let approvalLevels: [ApprovalLevel]

        // Historical Context
        let recentAcquisitions: [RecentAcquisition]
        let vendorPreferences: [VendorPreference]
        let seasonalPatterns: [SeasonalPattern]

        // Environmental Context
        let currentWorkload: WorkloadLevel
        let urgentRequests: Int
        let pendingApprovals: Int
        let teamCapacity: Float

        // Compliance Context
        let requiredClauses: [ComplianceClause]
        let setAsideGoals: SetAsideGoals
        let socioeconomicTargets: [SocioeconomicTarget]
    }

    public enum TimeOfDay: String {
        case earlyMorning = "early_morning" // 6-9 AM
        case lateMorning = "late_morning" // 9-12 PM
        case afternoon // 12-5 PM
        case evening // 5-8 PM
        case night // 8 PM-6 AM
    }

    public enum DayOfWeek: String {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday

        var isWeekend: Bool {
            self == .saturday || self == .sunday
        }

        var isEndOfWeek: Bool {
            self == .thursday || self == .friday
        }
    }

    public enum WorkloadLevel: String {
        case low, normal, high, critical
    }

    public struct ApprovalLevel {
        let threshold: Decimal
        let approver: String
        let typicalTurnaround: Int // days
    }

    public struct RecentAcquisition {
        let date: Date
        let vendor: String
        let amount: Decimal
        let category: String
        let deliveryTime: Int // days
    }

    public struct VendorPreference {
        let vendor: String
        let category: String
        let satisfaction: Float // 0-1
        let averageDeliveryTime: Int
        let priceCompetitiveness: Float // 0-1
    }

    public struct SeasonalPattern {
        let month: Int
        let category: String
        let volumeMultiplier: Float
        let urgencyMultiplier: Float
    }

    public struct ComplianceClause {
        let clauseNumber: String
        let title: String
        let applicability: String
        let mandatory: Bool
    }

    public struct SetAsideGoals {
        let smallBusiness: Float
        let womanOwned: Float
        let veteranOwned: Float
        let hubZone: Float
        let currentProgress: [String: Float]
    }

    public struct SocioeconomicTarget {
        let category: String
        let targetPercentage: Float
        let currentPercentage: Float
        let priority: Int
    }

    // MARK: - Properties

    private let contextAnalyzer: ContextAnalyzer
    private let patternMatcher: PatternMatcher
    private let ruleEvaluator: RuleEvaluator

    // MARK: - Initialization

    public init() {
        contextAnalyzer = ContextAnalyzer()
        patternMatcher = PatternMatcher()
        ruleEvaluator = RuleEvaluator()
    }

    // MARK: - Public Methods

    /// Generate contextual defaults based on comprehensive environmental factors
    public func generateContextualDefaults(
        for fields: [RequirementField],
        factors: ContextualFactors
    ) async -> [RequirementField: ContextualDefault] {
        var defaults: [RequirementField: ContextualDefault] = [:]

        // Analyze context to determine priorities
        let contextPriorities = analyzeContextPriorities(factors)

        // Generate defaults for each field
        for field in fields {
            if let contextualDefault = await generateFieldDefault(
                field: field,
                factors: factors,
                priorities: contextPriorities
            ) {
                defaults[field] = contextualDefault
            }
        }

        // Apply cross-field validation and adjustments
        defaults = applyCrossFieldValidation(defaults, factors: factors)

        return defaults
    }

    // MARK: - Private Methods

    private func generateFieldDefault(
        field: RequirementField,
        factors: ContextualFactors,
        priorities: ContextPriorities
    ) async -> ContextualDefault? {
        switch field {
        case .requiredDate:
            generateRequiredDateDefault(factors: factors, priorities: priorities)

        case .fundingSource:
            generateFundingSourceDefault(factors: factors)

        case .contractType:
            generateContractTypeDefault(factors: factors, priorities: priorities)

        case .setAsideType:
            generateSetAsideDefault(factors: factors)

        case .performanceLocation:
            generateLocationDefault(factors: factors)

        case .paymentTerms:
            generatePaymentTermsDefault(factors: factors)

        case .qualityRequirements:
            generateQualityRequirementsDefault(factors: factors)

        case .inspectionRequirements:
            generateInspectionDefault(factors: factors)

        case .deliveryInstructions:
            generateDeliveryInstructionsDefault(factors: factors)

        case .specialConditions:
            generateSpecialConditionsDefault(factors: factors, priorities: priorities)

        default:
            nil
        }
    }

    private func generateRequiredDateDefault(
        factors: ContextualFactors,
        priorities _: ContextPriorities
    ) -> ContextualDefault {
        let calendar = Calendar.current
        var suggestedDate: Date
        var confidence: Float = 0.7
        var reasoning: String

        // Factor 1: Fiscal year considerations
        if factors.isEndOfFiscalYear, factors.daysUntilFYEnd < 60 {
            // Urgent delivery needed before FY end
            let maxDays = max(factors.daysUntilFYEnd - 10, 14) // At least 2 weeks
            suggestedDate = calendar.date(byAdding: .day, value: maxDays, to: Date())!
            confidence = 0.9
            reasoning = "End of fiscal year urgency - must deliver before \(factors.fiscalYear) ends"
        }
        // Factor 2: End of quarter considerations
        else if factors.isEndOfQuarter, factors.daysUntilQuarterEnd < 30 {
            let targetDays = min(factors.daysUntilQuarterEnd - 5, 25)
            suggestedDate = calendar.date(byAdding: .day, value: targetDays, to: Date())!
            confidence = 0.85
            reasoning = "End of quarter - delivery before \(factors.fiscalQuarter) ends"
        }
        // Factor 3: Workload considerations
        else if factors.currentWorkload == .critical {
            // Extended timeline due to high workload
            suggestedDate = calendar.date(byAdding: .day, value: 45, to: Date())!
            confidence = 0.75
            reasoning = "Extended timeline due to critical workload levels"
        }
        // Factor 4: Historical patterns
        else if let avgDelivery = calculateAverageDeliveryTime(from: factors.recentAcquisitions) {
            suggestedDate = calendar.date(byAdding: .day, value: avgDelivery, to: Date())!
            confidence = 0.8
            reasoning = "Based on average delivery time of \(avgDelivery) days"
        }
        // Default: Standard delivery window
        else {
            suggestedDate = calendar.date(byAdding: .day, value: 30, to: Date())!
            confidence = 0.7
            reasoning = "Standard 30-day delivery window"
        }

        // Adjust for weekends
        suggestedDate = adjustForWeekend(date: suggestedDate, calendar: calendar)

        return ContextualDefault(
            field: .requiredDate,
            value: suggestedDate,
            confidence: confidence,
            reasoning: reasoning,
            alternatives: generateDateAlternatives(baseDate: suggestedDate, factors: factors)
        )
    }

    private func generateFundingSourceDefault(factors: ContextualFactors) -> ContextualDefault {
        var fundingSource: String
        var confidence: Float
        var reasoning: String

        // Check remaining budget
        if let budgetRemaining = factors.budgetRemaining {
            if budgetRemaining < 10000 {
                // Low budget - suggest alternative funding
                fundingSource = "O&M \(factors.fiscalYear) - Reserve"
                confidence = 0.6
                reasoning = "Limited remaining budget in primary fund"
            } else {
                // Sufficient budget
                fundingSource = "O&M \(factors.fiscalYear) - \(factors.department)"
                confidence = 0.85
                reasoning = "Department budget available"
            }
        } else {
            // Default based on organization
            fundingSource = "O&M \(factors.fiscalYear) - \(factors.organizationUnit)"
            confidence = 0.75
            reasoning = "Standard organizational funding source"
        }

        return ContextualDefault(
            field: .fundingSource,
            value: fundingSource,
            confidence: confidence,
            reasoning: reasoning,
            alternatives: [
                ContextualDefaultAlternative(
                    value: "Working Capital Fund \(factors.fiscalYear)",
                    confidence: 0.5,
                    reasoning: "Alternative for inter-agency purchases"
                )
            ]
        )
    }

    private func generateContractTypeDefault(
        factors: ContextualFactors,
        priorities: ContextPriorities
    ) -> ContextualDefault {
        var contractType: String
        var confidence: Float
        var reasoning: String

        // Analyze recent patterns
        let recentTypes = factors.recentAcquisitions.map(\.category)
        _ = findMostCommonElement(recentTypes)

        if priorities.speedPriority > 0.8 {
            contractType = "Purchase Order"
            confidence = 0.9
            reasoning = "Simplified acquisition for speed"
        } else if let typical = factors.typicalPurchaseAmount {
            if typical > 250_000 {
                contractType = "Fixed Price Contract"
                confidence = 0.85
                reasoning = "Standard for high-value acquisitions"
            } else if typical > 25000 {
                contractType = "Purchase Order"
                confidence = 0.8
                reasoning = "Simplified acquisition threshold"
            } else {
                contractType = "Micro-Purchase"
                confidence = 0.9
                reasoning = "Below micro-purchase threshold"
            }
        } else {
            contractType = "Purchase Order"
            confidence = 0.7
            reasoning = "Default contract vehicle"
        }

        return ContextualDefault(
            field: .contractType,
            value: contractType,
            confidence: confidence,
            reasoning: reasoning,
            alternatives: []
        )
    }

    private func generateSetAsideDefault(factors: ContextualFactors) -> ContextualDefault? {
        // Check socioeconomic goals
        let goals = factors.setAsideGoals
        var setAsideType: String?
        var confidence: Float = 0.0
        var reasoning = ""

        // Find category most behind target
        var maxGap: Float = 0

        if let progress = goals.currentProgress["smallBusiness"] {
            let gap = goals.smallBusiness - progress
            if gap > maxGap {
                maxGap = gap
                setAsideType = "Small Business Set-Aside"
                confidence = min(0.9, 0.6 + gap)
                reasoning = "Small business goal at \(Int(progress * 100))% of \(Int(goals.smallBusiness * 100))% target"
            }
        }

        if let progress = goals.currentProgress["womanOwned"] {
            let gap = goals.womanOwned - progress
            if gap > maxGap {
                maxGap = gap
                setAsideType = "WOSB Set-Aside"
                confidence = min(0.9, 0.6 + gap)
                reasoning = "Woman-owned goal at \(Int(progress * 100))% of \(Int(goals.womanOwned * 100))% target"
            }
        }

        if let progress = goals.currentProgress["veteranOwned"] {
            let gap = goals.veteranOwned - progress
            if gap > maxGap {
                maxGap = gap
                setAsideType = "SDVOSB Set-Aside"
                confidence = min(0.9, 0.6 + gap)
                reasoning = "Veteran-owned goal at \(Int(progress * 100))% of \(Int(goals.veteranOwned * 100))% target"
            }
        }

        guard let selectedType = setAsideType else { return nil }

        return ContextualDefault(
            field: .setAsideType,
            value: selectedType,
            confidence: confidence,
            reasoning: reasoning,
            alternatives: []
        )
    }

    private func generateLocationDefault(factors: ContextualFactors) -> ContextualDefault {
        // Default to organizational location
        ContextualDefault(
            field: .performanceLocation,
            value: factors.location,
            confidence: 0.95,
            reasoning: "Default organizational location",
            alternatives: factors.recentAcquisitions
                .map(\.vendor)
                .unique()
                .prefix(2)
                .map { vendor in
                    ContextualDefaultAlternative(
                        value: vendor,
                        confidence: 0.6,
                        reasoning: "Recent delivery location"
                    )
                }
        )
    }

    private func generatePaymentTermsDefault(factors: ContextualFactors) -> ContextualDefault {
        var terms: String
        var confidence: Float
        var reasoning: String

        if factors.currentWorkload == .critical || factors.urgentRequests > 5 {
            terms = "Net 45"
            confidence = 0.8
            reasoning = "Extended terms due to processing workload"
        } else if factors.vendorPreferences.contains(where: { $0.priceCompetitiveness > 0.8 }) {
            terms = "2/10 Net 30"
            confidence = 0.85
            reasoning = "Discount terms for competitive vendors"
        } else {
            terms = "Net 30"
            confidence = 0.9
            reasoning = "Standard payment terms"
        }

        return ContextualDefault(
            field: .paymentTerms,
            value: terms,
            confidence: confidence,
            reasoning: reasoning,
            alternatives: []
        )
    }

    private func generateQualityRequirementsDefault(factors: ContextualFactors) -> ContextualDefault {
        let requirements = [
            "ISO 9001:2015 certified quality management system",
            "100% inspection for critical components",
            "Certificate of Conformance required with each shipment",
            "Right of inspection at vendor facility"
        ]

        return ContextualDefault(
            field: .qualityRequirements,
            value: requirements,
            confidence: 0.75,
            reasoning: "Standard quality requirements for \(factors.department)",
            alternatives: []
        )
    }

    private func generateInspectionDefault(factors: ContextualFactors) -> ContextualDefault {
        var inspection: String
        var confidence: Float

        if factors.vendorPreferences.contains(where: { $0.satisfaction > 0.9 }) {
            inspection = "Destination inspection only"
            confidence = 0.85
        } else {
            inspection = "Source and destination inspection"
            confidence = 0.8
        }

        return ContextualDefault(
            field: .inspectionRequirements,
            value: inspection,
            confidence: confidence,
            reasoning: "Based on vendor performance history",
            alternatives: []
        )
    }

    private func generateDeliveryInstructionsDefault(factors: ContextualFactors) -> ContextualDefault {
        let instructions = """
        Delivery Location: \(factors.location)
        Hours: Monday-Friday, 0800-1600
        Contact: \(factors.department) Receiving
        Special Instructions: Call 24 hours before delivery
        """

        return ContextualDefault(
            field: .deliveryInstructions,
            value: instructions,
            confidence: 0.9,
            reasoning: "Standard delivery instructions for facility",
            alternatives: []
        )
    }

    private func generateSpecialConditionsDefault(
        factors: ContextualFactors,
        priorities _: ContextPriorities
    ) -> ContextualDefault? {
        var conditions: [String] = []

        // Add time-based conditions
        if factors.isEndOfFiscalYear {
            conditions.append("Delivery must be completed before end of fiscal year \(factors.fiscalYear)")
        }

        // Add workload-based conditions
        if factors.currentWorkload == .critical {
            conditions.append("Vendor must provide weekly status updates")
        }

        // Add compliance conditions
        for clause in factors.requiredClauses where clause.mandatory {
            conditions.append("Compliance with \(clause.clauseNumber) - \(clause.title) is mandatory")
        }

        guard !conditions.isEmpty else { return nil }

        return ContextualDefault(
            field: .specialConditions,
            value: conditions,
            confidence: 0.85,
            reasoning: "Contextually required conditions",
            alternatives: []
        )
    }

    // MARK: - Helper Methods

    private func analyzeContextPriorities(_ factors: ContextualFactors) -> ContextPriorities {
        var priorities = ContextPriorities()

        // Speed priority based on fiscal calendar
        if factors.isEndOfFiscalYear, factors.daysUntilFYEnd < 30 {
            priorities.speedPriority = 0.95
        } else if factors.isEndOfQuarter, factors.daysUntilQuarterEnd < 15 {
            priorities.speedPriority = 0.85
        } else {
            priorities.speedPriority = 0.5
        }

        // Cost priority based on budget
        if let budget = factors.budgetRemaining {
            priorities.costPriority = budget < 50000 ? 0.9 : 0.6
        }

        // Compliance priority
        priorities.compliancePriority = factors.requiredClauses.isEmpty ? 0.5 : 0.8

        return priorities
    }

    private func calculateAverageDeliveryTime(from acquisitions: [RecentAcquisition]) -> Int? {
        guard !acquisitions.isEmpty else { return nil }
        let total = acquisitions.reduce(0) { $0 + $1.deliveryTime }
        return total / acquisitions.count
    }

    private func adjustForWeekend(date: Date, calendar: Calendar) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 { // Sunday
            return calendar.date(byAdding: .day, value: 1, to: date)!
        } else if weekday == 7 { // Saturday
            return calendar.date(byAdding: .day, value: 2, to: date)!
        }
        return date
    }

    private func generateDateAlternatives(
        baseDate: Date,
        factors _: ContextualFactors
    ) -> [ContextualDefaultAlternative] {
        let calendar = Calendar.current
        var alternatives: [ContextualDefaultAlternative] = []

        // Earlier option
        if let earlier = calendar.date(byAdding: .day, value: -7, to: baseDate) {
            alternatives.append(ContextualDefaultAlternative(
                value: earlier,
                confidence: 0.6,
                reasoning: "Expedited delivery option"
            ))
        }

        // Later option
        if let later = calendar.date(byAdding: .day, value: 14, to: baseDate) {
            alternatives.append(ContextualDefaultAlternative(
                value: later,
                confidence: 0.7,
                reasoning: "Extended timeline option"
            ))
        }

        return alternatives
    }

    private func findMostCommonElement<T: Hashable>(_ array: [T]) -> T? {
        let counts = array.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func applyCrossFieldValidation(
        _ defaults: [RequirementField: ContextualDefault],
        factors _: ContextualFactors
    ) -> [RequirementField: ContextualDefault] {
        let validated = defaults

        // Validation 1: Payment terms should align with vendor preferences
        if let _ = validated[.paymentTerms],
           let _ = validated[.vendorName] {
            // Adjust payment terms based on vendor history
            // Implementation would check vendor payment history
        }

        // Validation 2: Delivery date should consider inspection requirements
        if let _ = validated[.requiredDate],
           let _ = validated[.inspectionRequirements] {
            // Add buffer for inspection time if needed
            // Implementation would adjust dates accordingly
        }

        return validated
    }
}

// MARK: - Supporting Types

public struct ContextualDefault {
    public let field: RequirementField
    public let value: Any
    public let confidence: Float
    public let reasoning: String
    public let alternatives: [ContextualDefaultAlternative]
}

public struct ContextualDefaultAlternative {
    public let value: Any
    public let confidence: Float
    public let reasoning: String
}

private struct ContextPriorities {
    var speedPriority: Float = 0.5
    var costPriority: Float = 0.5
    var compliancePriority: Float = 0.5
}

// MARK: - Helper Services

private class ContextAnalyzer {
    func analyzeContext(_: EnhancedContextualDefaultsProvider.ContextualFactors) -> ContextInsights {
        // Analyze various context factors to provide insights
        ContextInsights()
    }
}

private class PatternMatcher {
    func findPatterns(in _: [Any]) -> [ContextPattern] {
        // Find patterns in historical data
        []
    }
}

private class RuleEvaluator {
    func evaluateRules(_: [Rule], context _: Any) -> [ContextRuleResult] {
        // Evaluate business rules
        []
    }
}

private struct ContextInsights {
    // Insights from context analysis
}

private struct ContextPattern {
    // Pattern representation
}

private struct Rule {
    // Business rule representation
}

private struct ContextRuleResult {
    // Rule evaluation result
}

// MARK: - Array Extension

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
