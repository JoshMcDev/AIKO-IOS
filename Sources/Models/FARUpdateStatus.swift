import Foundation
import SwiftUI

public struct FARUpdateStatus: Codable, Sendable {
    public let id: UUID
    public let lastUpdateCheck: Date
    public let lastUpdateCompleted: Date?
    public let status: UpdateStatus
    public let pendingUpdates: Int
    public let completedUpdates: [FARUpdateItem]

    public enum UpdateStatus: String, Codable, Sendable {
        case upToDate = "up_to_date"
        case updating
        case updateAvailable = "update_available"
        case error

        public var statusLight: Color {
            switch self {
            case .upToDate: .green
            case .updating: .orange
            case .updateAvailable: .yellow
            case .error: .red
            }
        }

        public var statusIcon: String {
            switch self {
            case .upToDate: "checkmark.circle.fill"
            case .updating: "arrow.triangle.2.circlepath"
            case .updateAvailable: "exclamationmark.circle.fill"
            case .error: "xmark.circle.fill"
            }
        }
    }

    public init(
        id: UUID = UUID(),
        lastUpdateCheck: Date = Date(),
        lastUpdateCompleted: Date? = nil,
        status: UpdateStatus = .upToDate,
        pendingUpdates: Int = 0,
        completedUpdates: [FARUpdateItem] = []
    ) {
        self.id = id
        self.lastUpdateCheck = lastUpdateCheck
        self.lastUpdateCompleted = lastUpdateCompleted
        self.status = status
        self.pendingUpdates = pendingUpdates
        self.completedUpdates = completedUpdates
    }
}

public struct FARUpdateItem: Codable, Identifiable, Sendable {
    public let id: UUID
    public let regulation: String
    public let clauseNumber: String
    public let changeType: ChangeType
    public let effectiveDate: Date
    public let federalRegisterCitation: String?
    public let description: String
    public let impact: ImpactLevel
    public let affectedContracts: [String]

    public enum ChangeType: String, Codable, Sendable {
        case added = "Added"
        case modified = "Modified"
        case deleted = "Deleted"

        public var icon: String {
            switch self {
            case .added: "plus.circle.fill"
            case .modified: "pencil.circle.fill"
            case .deleted: "minus.circle.fill"
            }
        }

        public var color: Color {
            switch self {
            case .added: .green
            case .modified: .orange
            case .deleted: .red
            }
        }
    }

    public enum ImpactLevel: String, Codable, Sendable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"

        public var color: Color {
            switch self {
            case .low: .green
            case .medium: .yellow
            case .high: .orange
            case .critical: .red
            }
        }
    }

    public init(
        id: UUID = UUID(),
        regulation: String,
        clauseNumber: String,
        changeType: ChangeType,
        effectiveDate: Date,
        federalRegisterCitation: String? = nil,
        description: String,
        impact: ImpactLevel = .medium,
        affectedContracts: [String] = []
    ) {
        self.id = id
        self.regulation = regulation
        self.clauseNumber = clauseNumber
        self.changeType = changeType
        self.effectiveDate = effectiveDate
        self.federalRegisterCitation = federalRegisterCitation
        self.description = description
        self.impact = impact
        self.affectedContracts = affectedContracts
    }
}

// Service to manage FAR update monitoring
@MainActor
public class FARUpdateService: ObservableObject {
    @Published public var updateStatus: FARUpdateStatus
    private let updateMonitorPath = "/Users/J/aiko/Sources/Resources/Regulations/UpdateMonitor"

    public init() {
        // Initialize with some sample data for demonstration
        let sampleUpdates = [
            FARUpdateItem(
                regulation: "FAR",
                clauseNumber: "52.217-8",
                changeType: .modified,
                effectiveDate: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 7 days ago
                federalRegisterCitation: "90 FR 12345",
                description: "Updated options clause affecting contract extensions and renewal procedures",
                impact: .high
            ),
            FARUpdateItem(
                regulation: "FAR",
                clauseNumber: "52.232-40",
                changeType: .added,
                effectiveDate: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 14 days ago
                federalRegisterCitation: "90 FR 12346",
                description: "Added new electronic payment processing requirements for all contracts",
                impact: .medium
            ),
            FARUpdateItem(
                regulation: "DFARS",
                clauseNumber: "252.225-7001",
                changeType: .modified,
                effectiveDate: Date().addingTimeInterval(-21 * 24 * 60 * 60), // 21 days ago
                federalRegisterCitation: "90 FR 23456",
                description: "Updated Buy American Act requirements for critical supplies",
                impact: .critical
            ),
        ]

        updateStatus = FARUpdateStatus(
            lastUpdateCheck: Date(),
            lastUpdateCompleted: Date().addingTimeInterval(-24 * 60 * 60), // Yesterday
            status: .upToDate,
            pendingUpdates: 0,
            completedUpdates: sampleUpdates
        )
        loadUpdateStatus()
    }

    public func checkForUpdates() async {
        // In production, this would trigger the Node.js monitor
        // For now, we'll simulate the check

        // Capture current values to avoid data races
        let currentLastUpdateCompleted = updateStatus.lastUpdateCompleted
        let currentCompletedUpdates = updateStatus.completedUpdates

        updateStatus = FARUpdateStatus(
            lastUpdateCheck: Date(),
            lastUpdateCompleted: currentLastUpdateCompleted,
            status: .updating,
            pendingUpdates: 0,
            completedUpdates: currentCompletedUpdates
        )

        // Simulate update check delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Check if there are any updates from the monitor
        let hasUpdates = await checkMonitorForUpdates()
        let completedUpdates = hasUpdates ? await loadCompletedUpdates() : currentCompletedUpdates

        if hasUpdates {
            updateStatus = FARUpdateStatus(
                lastUpdateCheck: Date(),
                lastUpdateCompleted: Date(),
                status: .upToDate,
                pendingUpdates: 0,
                completedUpdates: completedUpdates
            )
        } else {
            updateStatus = FARUpdateStatus(
                lastUpdateCheck: Date(),
                lastUpdateCompleted: currentLastUpdateCompleted,
                status: .upToDate,
                pendingUpdates: 0,
                completedUpdates: currentCompletedUpdates
            )
        }
        saveUpdateStatus()
    }

    private func checkMonitorForUpdates() async -> Bool {
        // Check the update monitor's history file
        let historyPath = "\(updateMonitorPath)/../.update-history.json"

        // Capture the last check date to avoid accessing self in async context
        let lastCheck = updateStatus.lastUpdateCheck

        return await Task.detached {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: historyPath)),
                  let history = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            else {
                return false
            }

            // Check if there are new updates since last check
            let newUpdates = history.filter { update in
                if let dateString = update["effectiveDate"] as? String,
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    return date > lastCheck
                }
                return false
            }

            return !newUpdates.isEmpty
        }.value
    }

    private func loadCompletedUpdates() async -> [FARUpdateItem] {
        // Load from the monitor's update history
        let historyPath = "\(updateMonitorPath)/../.update-history.json"

        return await Task.detached {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: historyPath)),
                  let history = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            else {
                return []
            }

            // Convert to FARUpdateItem objects (last 20 updates)
            return history.suffix(20).compactMap { update in
                guard let regulation = update["regulation"] as? String,
                      let clauseNumber = update["clauseNumber"] as? String,
                      let changeTypeString = update["changeType"] as? String,
                      let dateString = update["effectiveDate"] as? String,
                      let date = ISO8601DateFormatter().date(from: dateString)
                else {
                    return nil
                }

                let changeType: FARUpdateItem.ChangeType = switch changeTypeString {
                case "added": .added
                case "deleted": .deleted
                default: .modified
                }

                let impact = Self.analyzeImpact(for: clauseNumber, changeType: changeType)
                let description = Self.generateDescription(for: clauseNumber, changeType: changeType, regulation: regulation)

                return FARUpdateItem(
                    regulation: regulation,
                    clauseNumber: clauseNumber,
                    changeType: changeType,
                    effectiveDate: date,
                    federalRegisterCitation: update["federalRegisterCitation"] as? String,
                    description: description,
                    impact: impact
                )
            }
        }.value
    }

    private nonisolated static func analyzeImpact(for clauseNumber: String, changeType: FARUpdateItem.ChangeType) -> FARUpdateItem.ImpactLevel {
        // Analyze impact based on clause number patterns
        if clauseNumber.hasPrefix("52.2") { // Contract clauses
            return changeType == .deleted ? .high : .medium
        } else if clauseNumber.hasPrefix("52.3") { // Provision and clause matrix
            return .high
        } else if clauseNumber.hasPrefix("52.1") { // Instructions
            return .low
        }
        return .medium
    }

    private nonisolated static func generateDescription(for clauseNumber: String, changeType: FARUpdateItem.ChangeType, regulation: String) -> String {
        let action = changeType == .added ? "Added new" : changeType == .modified ? "Updated" : "Removed"

        // Generate meaningful descriptions based on clause patterns
        if clauseNumber.hasPrefix("52.217") {
            return "\(action) options clause affecting contract extensions"
        } else if clauseNumber.hasPrefix("52.232") {
            return "\(action) payment clause affecting invoice processing"
        } else if clauseNumber.hasPrefix("52.225") {
            return "\(action) Buy American Act requirements"
        } else if clauseNumber.hasPrefix("52.204") {
            return "\(action) administrative and information requirements"
        } else if clauseNumber.hasPrefix("252.225") {
            return "\(action) DFARS foreign acquisition requirements"
        } else if clauseNumber.hasPrefix("252.204") {
            return "\(action) DFARS safeguarding requirements"
        }

        return "\(action) \(regulation) clause \(clauseNumber)"
    }

    public func generateUpdateSummary() -> String {
        let updates = updateStatus.completedUpdates

        guard !updates.isEmpty else {
            return "No recent regulation updates. All FAR/DFAR clauses are current."
        }

        var summary = "# Federal Acquisition Regulation Updates\n\n"
        summary += "**Last Updated:** \(updateStatus.lastUpdateCompleted?.formatted() ?? "N/A")\n"
        summary += "**Total Updates:** \(updates.count)\n\n"

        // Group by regulation
        let grouped = Dictionary(grouping: updates) { $0.regulation }

        for (regulation, regulationUpdates) in grouped.sorted(by: { $0.key < $1.key }) {
            summary += "## \(regulation) Updates\n\n"

            // Group by impact level
            let byImpact = Dictionary(grouping: regulationUpdates) { $0.impact }

            if let critical = byImpact[.critical], !critical.isEmpty {
                summary += "### 🔴 Critical Impact\n"
                for update in critical {
                    summary += formatUpdate(update)
                }
            }

            if let high = byImpact[.high], !high.isEmpty {
                summary += "### 🟠 High Impact\n"
                for update in high {
                    summary += formatUpdate(update)
                }
            }

            if let medium = byImpact[.medium], !medium.isEmpty {
                summary += "### 🟡 Medium Impact\n"
                for update in medium {
                    summary += formatUpdate(update)
                }
            }

            if let low = byImpact[.low], !low.isEmpty {
                summary += "### 🟢 Low Impact\n"
                for update in low {
                    summary += formatUpdate(update)
                }
            }
        }

        summary += "\n## Impact on Your Contracts\n\n"
        summary += generateImpactAnalysis(updates)

        summary += "\n## Recommended Actions\n\n"
        summary += generateRecommendations(updates)

        return summary
    }

    private func formatUpdate(_ update: FARUpdateItem) -> String {
        var text = "- **\(update.clauseNumber)** (\(update.changeType.rawValue))"
        text += " - \(update.description)\n"
        text += "  - Effective: \(update.effectiveDate.formatted(date: .abbreviated, time: .omitted))"
        if let citation = update.federalRegisterCitation {
            text += " | FR: \(citation)"
        }
        text += "\n\n"
        return text
    }

    private func generateImpactAnalysis(_ updates: [FARUpdateItem]) -> String {
        var analysis = ""

        // Analyze contract types affected
        let hasPaymentChanges = updates.contains { $0.clauseNumber.hasPrefix("52.232") }
        let hasOptionsChanges = updates.contains { $0.clauseNumber.hasPrefix("52.217") }
        let hasBuyAmericanChanges = updates.contains { $0.clauseNumber.hasPrefix("52.225") || $0.clauseNumber.hasPrefix("252.225") }
        let hasSecurityChanges = updates.contains { $0.clauseNumber.hasPrefix("252.204") }

        if hasPaymentChanges {
            analysis += "- **Payment Processing**: Review invoice and payment procedures for compliance\n"
        }

        if hasOptionsChanges {
            analysis += "- **Contract Options**: Verify option exercise procedures align with updated requirements\n"
        }

        if hasBuyAmericanChanges {
            analysis += "- **Domestic Preferences**: Ensure compliance with updated Buy American requirements\n"
        }

        if hasSecurityChanges {
            analysis += "- **Cybersecurity**: Update security controls to meet new DFARS requirements\n"
        }

        if analysis.isEmpty {
            analysis = "- No significant impact on active contracts identified\n"
        }

        return analysis
    }

    private func generateRecommendations(_ updates: [FARUpdateItem]) -> String {
        var recommendations = "1. Review all active contracts for affected clauses\n"
        recommendations += "2. Update contract templates with new clause language\n"
        recommendations += "3. Notify contracting officers of critical changes\n"

        let criticalCount = updates.count(where: { $0.impact == .critical })
        if criticalCount > 0 {
            recommendations += "4. **Immediate Action Required**: \(criticalCount) critical updates require immediate attention\n"
        }

        return recommendations
    }

    private func saveUpdateStatus() {
        // Save to UserDefaults or local storage
        if let encoded = try? JSONEncoder().encode(updateStatus) {
            UserDefaults.standard.set(encoded, forKey: "FARUpdateStatus")
        }
    }

    private func loadUpdateStatus() {
        // Load from UserDefaults or local storage
        if let data = UserDefaults.standard.data(forKey: "FARUpdateStatus"),
           let status = try? JSONDecoder().decode(FARUpdateStatus.self, from: data) {
            updateStatus = status
        }
    }
}
