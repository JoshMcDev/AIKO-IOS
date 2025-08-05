import AppCore
import SwiftUI

struct OriginalSAMReportPreview: View {
    let entities: [EntityDetail]
    @Environment(\.dismiss) private var dismiss
    @State private var isGeneratingPDF = false
    @State private var isExporting = false
    @State private var selectedFollowOnOption: FollowOnReportType?
    @State private var showingFollowOnSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Report Header - Clean and Professional
                    reportHeader

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Executive Summary
                    executiveSummary

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Contractor Analysis - The Original Clean Format
                    contractorAnalysis

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Market Intelligence
                    marketIntelligence

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Risk Assessment
                    riskAssessment

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Recommendations
                    recommendations

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Follow-on Options
                    followOnOptions
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("SAM.gov Report")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Export PDF") {
                        exportToPDF()
                    }
                    .foregroundColor(.blue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Export PDF") {
                        exportToPDF()
                    }
                    .foregroundColor(.blue)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #endif
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Report Header

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SAM.gov Contractor Analysis Report")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Comprehensive Market Intelligence & Risk Assessment")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDate(Date()))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("\(entities.count) Contractors Analyzed")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }

            // Report Metadata Grid - Original Clean Design
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(title: "Active Contractors", value: "\(entities.filter { $0.registrationStatus == "Active" }.count)", color: .green)
                MetricCard(title: "Small Businesses", value: "\(entities.filter(\.isSmallBusiness).count)", color: .blue)
                MetricCard(title: "Veteran-Owned", value: "\(entities.filter(\.isVeteranOwned).count)", color: .orange)
                MetricCard(title: "With Exclusions", value: "\(entities.filter(\.hasActiveExclusions).count)", color: .red)
            }
        }
    }

    // MARK: - Executive Summary

    private var executiveSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Executive Summary", icon: "doc.text.magnifyingglass")

            VStack(alignment: .leading, spacing: 8) {
                SummaryPoint(
                    text: "Market Analysis: \(entities.count) contractors identified with \(calculateAveragePerformanceScore())% average capability score"
                )

                SummaryPoint(
                    text: "Competition Level: \(getCompetitionLevel()) based on contractor diversity and geographic distribution"
                )

                SummaryPoint(
                    text: "Risk Profile: \(calculateRiskProfile()) risk exposure with \(entities.filter(\.hasActiveExclusions).count) contractors having active exclusions"
                )

                SummaryPoint(
                    text: "Small Business Participation: \(calculateSmallBusinessPercentage())% of identified contractors qualify as small businesses"
                )
            }
        }
    }

    // MARK: - Contractor Analysis - Original Clean Format

    private var contractorAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Contractor Analysis", icon: "building.2")

            ForEach(entities, id: \.ueiSAM) { entity in
                ContractorCard(entity: entity)
            }
        }
    }

    // MARK: - Market Intelligence

    private var marketIntelligence: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Market Intelligence", icon: "chart.line.uptrend.xyaxis")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                IntelligenceCard(
                    title: "NAICS Diversity",
                    value: "\(calculateNAICSDiversity()) Codes",
                    trend: "↗",
                    description: "Industry coverage breadth"
                )

                IntelligenceCard(
                    title: "Geographic Spread",
                    value: "\(calculateGeographicSpread()) States",
                    trend: "→",
                    description: "Regional distribution"
                )

                IntelligenceCard(
                    title: "Certification Rate",
                    value: "\(calculateCertificationRate())%",
                    trend: "↗",
                    description: "Special certifications held"
                )

                IntelligenceCard(
                    title: "Market Maturity",
                    value: getMarketMaturity(),
                    trend: "→",
                    description: "Overall market stability"
                )
            }
        }
    }

    // MARK: - Risk Assessment

    private var riskAssessment: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Risk Assessment", icon: "exclamationmark.shield")

            VStack(alignment: .leading, spacing: 8) {
                RiskIndicator(
                    level: entities.filter(\.hasActiveExclusions).isEmpty ? .low : .high,
                    title: "Exclusion Risk",
                    description: "\(entities.filter(\.hasActiveExclusions).count) contractors with active exclusions"
                )

                RiskIndicator(
                    level: calculatePerformanceRisk(),
                    title: "Performance Risk",
                    description: "Based on registration status and business type analysis"
                )

                RiskIndicator(
                    level: calculateMarketConcentrationRisk(),
                    title: "Market Concentration",
                    description: "Competitive landscape and supplier diversity assessment"
                )
            }
        }
    }

    // MARK: - Recommendations

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Strategic Recommendations", icon: "lightbulb")

            VStack(alignment: .leading, spacing: 12) {
                RecommendationCard(
                    priority: .high,
                    title: "Market Entry Strategy",
                    recommendation: generateMarketEntryRecommendation()
                )

                RecommendationCard(
                    priority: .medium,
                    title: "Competition Analysis",
                    recommendation: generateCompetitionRecommendation()
                )

                RecommendationCard(
                    priority: .medium,
                    title: "Risk Mitigation",
                    recommendation: generateRiskMitigationRecommendation()
                )
            }
        }
    }

    // MARK: - Follow-on Options

    private var followOnOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Follow-on Analysis Options", icon: "arrow.branch")

            Text("Generate additional specialized reports for deeper vendor analysis:")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(FollowOnReportType.allCases, id: \.self) { reportType in
                    FollowOnOptionCard(
                        reportType: reportType,
                        entities: entities
                    ) {
                        selectedFollowOnOption = reportType
                        showingFollowOnSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingFollowOnSheet) {
            if let selectedOption = selectedFollowOnOption {
                FollowOnReportView(reportType: selectedOption, entities: entities)
            }
        }
    }

    // MARK: - Helper Functions

    private func exportToPDF() {
        isExporting = true
        // Simulate PDF generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func calculateAveragePerformanceScore() -> Int {
        let activeContractors = entities.filter { $0.registrationStatus == "Active" }.count
        let totalContractors = entities.count
        return totalContractors > 0 ? Int((Double(activeContractors) / Double(totalContractors)) * 100) : 0
    }

    private func getCompetitionLevel() -> String {
        let count = entities.count
        switch count {
        case 0 ... 5: return "Low Competition"
        case 6 ... 15: return "Moderate Competition"
        default: return "High Competition"
        }
    }

    private func calculateRiskProfile() -> String {
        let exclusionCount = entities.filter(\.hasActiveExclusions).count
        let riskPercentage = Double(exclusionCount) / Double(max(entities.count, 1))

        switch riskPercentage {
        case 0 ... 0.1: return "Low"
        case 0.1 ... 0.3: return "Moderate"
        default: return "High"
        }
    }

    private func calculateSmallBusinessPercentage() -> Int {
        let smallBusinessCount = entities.filter(\.isSmallBusiness).count
        return !entities.isEmpty ? Int((Double(smallBusinessCount) / Double(entities.count)) * 100) : 0
    }

    private func calculateNAICSDiversity() -> Int {
        let allNAICS = entities.flatMap { $0.naicsCodes.map(\.code) }
        return Set(allNAICS).count
    }

    private func calculateGeographicSpread() -> Int {
        let states = entities.compactMap { $0.address?.state }
        return Set(states).count
    }

    private func calculateCertificationRate() -> Int {
        let certifiedCount = entities.filter { entity in
            entity.isVeteranOwned || entity.isWomanOwned || entity.is8aProgram || entity.isHUBZone
        }.count
        return !entities.isEmpty ? Int((Double(certifiedCount) / Double(entities.count)) * 100) : 0
    }

    private func getMarketMaturity() -> String {
        let avgNAICSPerContractor = !entities.isEmpty ?
            Double(entities.flatMap(\.naicsCodes).count) / Double(entities.count) : 0

        switch avgNAICSPerContractor {
        case 0 ... 2: return "Emerging"
        case 2 ... 5: return "Developing"
        default: return "Mature"
        }
    }

    private func calculatePerformanceRisk() -> RiskLevel {
        let inactiveCount = entities.filter { $0.registrationStatus != "Active" }.count
        let riskRatio = Double(inactiveCount) / Double(max(entities.count, 1))

        switch riskRatio {
        case 0 ... 0.1: return .low
        case 0.1 ... 0.3: return .medium
        default: return .high
        }
    }

    private func calculateMarketConcentrationRisk() -> RiskLevel {
        let count = entities.count
        switch count {
        case 0 ... 3: return .high
        case 4 ... 10: return .medium
        default: return .low
        }
    }

    private func generateMarketEntryRecommendation() -> String {
        let smallBusinessPercentage = calculateSmallBusinessPercentage()
        if smallBusinessPercentage > 60 {
            return "Market shows strong small business participation. Consider leveraging small business partnerships or subcontracting opportunities."
        } else {
            return "Limited small business presence detected. Opportunity exists for small business set-aside competitions."
        }
    }

    private func generateCompetitionRecommendation() -> String {
        let competitionLevel = getCompetitionLevel()
        switch competitionLevel {
        case "Low Competition":
            return "Limited competition detected. Focus on capability demonstration and past performance differentiation."
        case "Moderate Competition":
            return "Balanced competitive environment. Emphasize unique value propositions and competitive pricing strategies."
        default:
            return "Highly competitive market. Consider niche specialization or teaming arrangements to strengthen position."
        }
    }

    private func generateRiskMitigationRecommendation() -> String {
        let exclusionCount = entities.filter(\.hasActiveExclusions).count
        if exclusionCount > 0 {
            return "Active exclusions detected in \(exclusionCount) contractors. Implement enhanced due diligence and exclusion screening procedures."
        } else {
            return "No active exclusions identified. Maintain standard compliance monitoring and due diligence processes."
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.bottom, 4)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SummaryPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ContractorCard: View {
    let entity: EntityDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with status indicator
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entity.entityName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text("UEI: \(entity.ueiSAM)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                StatusBadge(status: entity.registrationStatus, hasExclusions: entity.hasActiveExclusions)
            }

            // Business characteristics
            HStack {
                if entity.isSmallBusiness {
                    CharacteristicBadge(text: "Small Business", color: .blue)
                }
                if entity.isVeteranOwned {
                    CharacteristicBadge(text: "Veteran-Owned", color: .green)
                }
                if entity.is8aProgram {
                    CharacteristicBadge(text: "8(a)", color: .purple)
                }
                if entity.isHUBZone {
                    CharacteristicBadge(text: "HUBZone", color: .orange)
                }
                Spacer()
            }

            // Key metrics
            if !entity.naicsCodes.isEmpty {
                Text("Primary NAICS: \(entity.naicsCodes.first?.code ?? "N/A") - \(entity.naicsCodes.first?.description ?? "N/A")")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatusBadge: View {
    let status: String
    let hasExclusions: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)

            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(6)
    }

    private var statusIcon: String {
        if hasExclusions {
            "exclamationmark.triangle.fill"
        } else if status == "Active" {
            "checkmark.circle.fill"
        } else {
            "exclamationmark.circle.fill"
        }
    }

    private var statusColor: Color {
        if hasExclusions {
            .red
        } else if status == "Active" {
            .green
        } else {
            .orange
        }
    }
}

struct CharacteristicBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }
}

struct IntelligenceCard: View {
    let title: String
    let value: String
    let trend: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Text(trend)
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(description)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RiskIndicator: View {
    let level: RiskLevel
    let title: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            RiskLevelBadge(level: level)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct RiskLevelBadge: View {
    let level: RiskLevel

    var body: some View {
        Text(level.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(level.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(level.color.opacity(0.1))
            .cornerRadius(6)
    }
}

struct RecommendationCard: View {
    let priority: RecommendationPriority
    let title: String
    let recommendation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()

                PriorityBadge(priority: priority)
            }

            Text(recommendation)
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(priority.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PriorityBadge: View {
    let priority: RecommendationPriority

    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(priority.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color.opacity(0.1))
            .cornerRadius(4)
    }
}

// MARK: - Supporting Types

enum RiskLevel {
    case low, medium, high

    var displayName: String {
        switch self {
        case .low: "Low Risk"
        case .medium: "Medium Risk"
        case .high: "High Risk"
        }
    }

    var color: Color {
        switch self {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}

enum RecommendationPriority {
    case low, medium, high

    var displayName: String {
        switch self {
        case .low: "Low Priority"
        case .medium: "Medium Priority"
        case .high: "High Priority"
        }
    }

    var color: Color {
        switch self {
        case .low: .gray
        case .medium: .orange
        case .high: .red
        }
    }
}

enum FollowOnReportType: String, CaseIterable {
    case marketAnalysis = "Market Analysis Reports"
    case vendorCapabilities = "Vendor Capabilities Assessment"
    case competitiveAnalysis = "Competitive Analysis"
    case pastPerformance = "Past Performance Evaluation"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .marketAnalysis: "chart.line.uptrend.xyaxis"
        case .vendorCapabilities: "building.2"
        case .competitiveAnalysis: "scale.3d"
        case .pastPerformance: "clock.arrow.circlepath"
        }
    }

    var description: String {
        switch self {
        case .marketAnalysis:
            "Deep market trends, pricing analysis, and opportunity assessment"
        case .vendorCapabilities:
            "Technical capabilities, certifications, and capacity evaluation"
        case .competitiveAnalysis:
            "Competitive positioning, strengths, weaknesses, and market share"
        case .pastPerformance:
            "Historical performance, contract success rates, and reliability metrics"
        }
    }

    var estimatedTime: String {
        switch self {
        case .marketAnalysis: "15-20 minutes"
        case .vendorCapabilities: "10-15 minutes"
        case .competitiveAnalysis: "20-25 minutes"
        case .pastPerformance: "12-18 minutes"
        }
    }
}

// MARK: - Follow-on Option Card

struct FollowOnOptionCard: View {
    let reportType: FollowOnReportType
    let entities: [EntityDetail]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and title
                HStack {
                    Image(systemName: reportType.icon)
                        .foregroundColor(.blue)
                        .font(.title2)

                    Spacer()

                    Text(reportType.estimatedTime)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }

                Text(reportType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Text(reportType.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Action indicator
                HStack {
                    Text("Generate Report")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .padding()
            .frame(height: 140)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Follow-on Report View

struct FollowOnReportView: View {
    let reportType: FollowOnReportType
    let entities: [EntityDetail]
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var reportGenerated = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isGenerating {
                    // Generation in progress
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)

                        Text("Generating \(reportType.displayName)")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Analyzing \(entities.count) contractor(s) for comprehensive insights...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Text("Estimated completion: \(reportType.estimatedTime)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()

                } else if reportGenerated {
                    // Report preview
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(reportType.displayName) - Complete")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Your specialized report has been generated successfully.")
                                .font(.body)
                                .foregroundColor(.gray)

                            // Mock report content
                            VStack(alignment: .leading, spacing: 12) {
                                ReportSection(title: "Executive Summary", content: generateMockContent(for: reportType))
                                ReportSection(title: "Key Findings", content: "Analysis of \(entities.count) contractor(s) reveals significant insights for procurement decision-making.")
                                ReportSection(title: "Recommendations", content: "Strategic recommendations based on comprehensive vendor analysis and market intelligence.")
                            }
                        }
                        .padding()
                    }

                } else {
                    // Initial state
                    VStack(spacing: 16) {
                        Image(systemName: reportType.icon)
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text(reportType.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(reportType.description)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Generate Report") {
                            startReportGeneration()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Follow-on Analysis")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                #endif
            }
        }
        .preferredColorScheme(.dark)
    }

    private func startReportGeneration() {
        isGenerating = true

        // Simulate report generation time
        let delay = Double.random(in: 2.0 ... 5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isGenerating = false
            reportGenerated = true
        }
    }

    private func generateMockContent(for reportType: FollowOnReportType) -> String {
        switch reportType {
        case .marketAnalysis:
            "Market analysis reveals strong competition with \(entities.count) qualified vendors. Current market trends indicate increasing demand for specialized capabilities."
        case .vendorCapabilities:
            "Vendor capability assessment shows diverse technical competencies across \(entities.count) contractors, with varying levels of certification and capacity."
        case .competitiveAnalysis:
            "Competitive landscape analysis identifies key market players, pricing strategies, and competitive advantages among \(entities.count) evaluated vendors."
        case .pastPerformance:
            "Past performance evaluation demonstrates strong track record with average performance ratings above industry standards for \(entities.count) contractors."
        }
    }
}

struct ReportSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(content)
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
