import Foundation
import PDFKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Manager for exporting analytics data in various formats
@MainActor
public final class ExportManager: ObservableObject {
    // MARK: - Published Properties

    @Published public var isExporting = false
    @Published public var exportProgress: Double = 0.0
    @Published public var lastExportError: ExportError?

    // MARK: - Private Properties

    private let analyticsRepository: any AnalyticsRepositoryProtocol
    private let fileManager = FileManager.default

    // MARK: - Initialization

    public init(analyticsRepository: any AnalyticsRepositoryProtocol) {
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - Public Methods

    /// Export analytics data in specified format
    public func exportAnalytics(format: ExportFormat, includeCharts: Bool = true) async throws -> ExportResult {
        guard let dashboardData = analyticsRepository.dashboardData else {
            throw ExportError.noDataAvailable
        }

        isExporting = true
        exportProgress = 0.0
        lastExportError = nil

        defer {
            isExporting = false
            exportProgress = 0.0
        }

        do {
            let exportData = try await generateExportData(
                data: dashboardData,
                format: format,
                includeCharts: includeCharts
            )

            let fileURL = try await saveExportData(exportData, format: format)

            return ExportResult(
                format: format,
                fileURL: fileURL,
                fileSize: exportData.count,
                generatedAt: Date()
            )
        } catch {
            let exportError = error as? ExportError ?? ExportError.exportFailed(error)
            lastExportError = exportError
            throw exportError
        }
    }

    /// Export specific time range data
    public func exportTimeRangeData(
        timeRange: TimeRange,
        format: ExportFormat,
        metricTypes: [ChartMetricType] = ChartMetricType.allCases
    ) async throws -> ExportResult {
        isExporting = true
        exportProgress = 0.0

        defer {
            isExporting = false
            exportProgress = 0.0
        }

        let timeRangeData = try await generateTimeRangeData(
            timeRange: timeRange,
            metricTypes: metricTypes
        )

        let exportData = try await generateTimeRangeExport(
            data: timeRangeData,
            format: format,
            timeRange: timeRange
        )

        let fileURL = try await saveExportData(exportData, format: format)

        return ExportResult(
            format: format,
            fileURL: fileURL,
            fileSize: exportData.count,
            generatedAt: Date()
        )
    }

    /// Get available export formats
    public func getAvailableFormats() -> [ExportFormat] {
        ExportFormat.allCases
    }

    /// Get export history
    public func getExportHistory() -> [ExportResult] {
        // In a real implementation, this would load from persistent storage
        []
    }

    /// Clear export history
    public func clearExportHistory() {
        // In a real implementation, this would clear persistent storage
    }

    // MARK: - Private Methods

    private func generateExportData(
        data: AnalyticsDashboardData,
        format: ExportFormat,
        includeCharts: Bool
    ) async throws -> Data {
        await updateProgress(0.2)

        switch format {
        case .json:
            return try await generateJSONExport(data: data)
        case .csv:
            return try await generateCSVExport(data: data)
        case .pdf:
            return try await generatePDFExport(data: data, includeCharts: includeCharts)
        }
    }

    private func generateJSONExport(data: AnalyticsDashboardData) async throws -> Data {
        await updateProgress(0.5)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportWrapper = JSONExportWrapper(
            metadata: ExportMetadata(
                exportedAt: Date(),
                version: "1.0",
                dataRange: "All Time"
            ),
            analytics: data
        )

        await updateProgress(0.8)

        return try encoder.encode(exportWrapper)
    }

    private func generateCSVExport(data: AnalyticsDashboardData) async throws -> Data {
        await updateProgress(0.3)

        var csv = "Metric Category,Metric Name,Value,Unit,Date\n"

        // Overview metrics
        csv += "Overview,Total Time Saved,\(data.overview.totalTimeSaved),seconds,\(formatDate(data.lastUpdated))\n"
        csv += "Overview,Learning Progress,\(data.overview.learningProgress * 100),percent,\(formatDate(data.lastUpdated))\n"
        csv += "Overview,Personalization Level,\(data.overview.personalizationLevel * 100),percent,\(formatDate(data.lastUpdated))\n"
        csv += "Overview,Automation Success,\(data.overview.automationSuccess * 100),percent,\(formatDate(data.lastUpdated))\n"

        await updateProgress(0.5)

        // Learning metrics
        csv += "Learning,Prediction Success Rate,\(data.learningEffectiveness.predictionSuccessRate * 100),percent,\(formatDate(data.lastUpdated))\n"
        csv += "Learning,Confidence Level,\(data.learningEffectiveness.confidenceLevel * 100),percent,\(formatDate(data.lastUpdated))\n"

        await updateProgress(0.7)

        // Time saved by category
        for (category, timeSaved) in data.timeSaved.timeSavedByCategory {
            csv += "Time Saved,\(category),\(timeSaved),seconds,\(formatDate(data.lastUpdated))\n"
        }

        await updateProgress(0.9)

        return csv.data(using: .utf8) ?? Data()
    }

    private func generatePDFExport(data: AnalyticsDashboardData, includeCharts _: Bool) async throws -> Data {
        await updateProgress(0.2)

        // For minimal GREEN phase implementation, return simple PDF content
        #if canImport(UIKit)
        return try await generateUIKitPDF(data: data)
        #else
        return try await generateSimplePDF(data: data)
        #endif
    }

    #if canImport(UIKit)
    private func generateUIKitPDF(data: AnalyticsDashboardData) async throws -> Data {
        let pdfMetaData: [String: Any] = [
            kCGPDFContextCreator as String: "AIKO Behavioral Analytics",
            kCGPDFContextTitle as String: "Analytics Report",
            kCGPDFContextSubject as String: "Behavioral Analytics Dashboard Export",
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792), format: format)

        await updateProgress(0.4)

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            var currentY: CGFloat = 50

            // Title
            let titleAttributes = [
                NSAttributedString.Key.font: fontFor(size: 24, weight: .bold),
                NSAttributedString.Key.foregroundColor: colorBlack(),
            ]
            let title = "Behavioral Analytics Report"
            title.draw(at: CGPoint(x: 50, y: currentY), withAttributes: titleAttributes)
            currentY += 40

            // Date
            let dateAttributes = [
                NSAttributedString.Key.font: fontFor(size: 12, weight: .regular),
                NSAttributedString.Key.foregroundColor: colorGray(),
            ]
            let dateString = "Generated: \(formatDate(data.lastUpdated))"
            dateString.draw(at: CGPoint(x: 50, y: currentY), withAttributes: dateAttributes)
            currentY += 30

            // Overview section
            currentY = drawUIKitSection(title: "Overview", startY: currentY, context: context)
            currentY = drawMetric("Total Time Saved", value: formatTime(data.overview.totalTimeSaved), startY: currentY)
            currentY = drawMetric("Learning Progress", value: "\(Int(data.overview.learningProgress * 100))%", startY: currentY)
            currentY = drawMetric("Personalization Level", value: "\(Int(data.overview.personalizationLevel * 100))%", startY: currentY)
            currentY = drawMetric("Automation Success", value: "\(Int(data.overview.automationSuccess * 100))%", startY: currentY)
        }

        await updateProgress(1.0)
        return pdfData
    }

    private func drawUIKitSection(title: String, startY: CGFloat, context _: UIGraphicsPDFRendererContext) -> CGFloat {
        let sectionAttributes = [
            NSAttributedString.Key.font: fontFor(size: 18, weight: .bold),
            NSAttributedString.Key.foregroundColor: colorBlack(),
        ]
        title.draw(at: CGPoint(x: 50, y: startY), withAttributes: sectionAttributes)
        return startY + 25
    }
    #endif

    private func generateSimplePDF(data: AnalyticsDashboardData) async throws -> Data {
        // Simplified PDF generation for macOS/other platforms
        let content = """
        Behavioral Analytics Report
        Generated: \(formatDate(data.lastUpdated))

        Overview:
        - Total Time Saved: \(formatTime(data.overview.totalTimeSaved))
        - Learning Progress: \(Int(data.overview.learningProgress * 100))%
        - Personalization Level: \(Int(data.overview.personalizationLevel * 100))%
        - Automation Success: \(Int(data.overview.automationSuccess * 100))%

        Learning Effectiveness:
        - Prediction Success Rate: \(Int(data.learningEffectiveness.predictionSuccessRate * 100))%
        - Confidence Level: \(Int(data.learningEffectiveness.confidenceLevel * 100))%
        """

        await updateProgress(1.0)
        return content.data(using: .utf8) ?? Data()
    }

    private func drawMetric(_ name: String, value: String, startY: CGFloat) -> CGFloat {
        let nameAttributes = [
            NSAttributedString.Key.font: fontFor(size: 14, weight: .regular),
            NSAttributedString.Key.foregroundColor: colorBlack(),
        ]
        let valueAttributes = [
            NSAttributedString.Key.font: fontFor(size: 14, weight: .bold),
            NSAttributedString.Key.foregroundColor: colorBlue(),
        ]

        name.draw(at: CGPoint(x: 70, y: startY), withAttributes: nameAttributes)
        value.draw(at: CGPoint(x: 300, y: startY), withAttributes: valueAttributes)

        return startY + 18
    }

    private func generateTimeRangeData(timeRange: TimeRange, metricTypes _: [ChartMetricType]) async throws -> TimeRangeExportData {
        // Generate time range specific data
        TimeRangeExportData(
            timeRange: timeRange,
            startDate: Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date(),
            endDate: Date(),
            metricData: [:] // Simplified for now
        )
    }

    private func generateTimeRangeExport(data: TimeRangeExportData, format: ExportFormat, timeRange _: TimeRange) async throws -> Data {
        // Generate export for time range data based on format
        switch format {
        case .json:
            try JSONEncoder().encode(data)
        case .csv:
            Data("Time Range Export\n\(data.timeRange.displayName)".utf8)
        case .pdf:
            Data() // Simplified PDF generation
        }
    }

    private func saveExportData(_ data: Data, format: ExportFormat) async throws -> URL {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ExportError.fileSystemError
        }
        let fileName = "analytics_export_\(Date().timeIntervalSince1970).\(format.fileExtension)"
        let fileURL = documentsPath.appendingPathComponent(fileName)

        try data.write(to: fileURL)
        return fileURL
    }

    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.exportProgress = progress
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Platform-specific Helper Functions

    private func fontFor(size: CGFloat, weight: FontWeight) -> Any {
        #if canImport(UIKit)
        switch weight {
        case .bold:
            return UIFont.boldSystemFont(ofSize: size)
        case .regular:
            return UIFont.systemFont(ofSize: size)
        }
        #elseif canImport(AppKit)
        switch weight {
        case .bold:
            return NSFont.boldSystemFont(ofSize: size)
        case .regular:
            return NSFont.systemFont(ofSize: size)
        }
        #else
        return NSFont.systemFont(ofSize: size)
        #endif
    }

    private func colorBlack() -> Any {
        #if canImport(UIKit)
        return UIColor.black
        #elseif canImport(AppKit)
        return NSColor.black
        #else
        return NSColor.black
        #endif
    }

    private func colorGray() -> Any {
        #if canImport(UIKit)
        return UIColor.gray
        #elseif canImport(AppKit)
        return NSColor.gray
        #else
        return NSColor.gray
        #endif
    }

    private func colorBlue() -> Any {
        #if canImport(UIKit)
        return UIColor.blue
        #elseif canImport(AppKit)
        return NSColor.blue
        #else
        return NSColor.blue
        #endif
    }
}

/// Font weight enum for cross-platform compatibility
public enum FontWeight {
    case regular
    case bold
}

// MARK: - Supporting Types

/// Export result
public struct ExportResult: Codable, Equatable, Sendable {
    public let format: ExportFormat
    public let fileURL: URL
    public let fileSize: Int
    public let generatedAt: Date

    public init(format: ExportFormat, fileURL: URL, fileSize: Int, generatedAt: Date) {
        self.format = format
        self.fileURL = fileURL
        self.fileSize = fileSize
        self.generatedAt = generatedAt
    }
}

/// Export metadata
public struct ExportMetadata: Codable, Equatable, Sendable {
    public let exportedAt: Date
    public let version: String
    public let dataRange: String

    public init(exportedAt: Date, version: String, dataRange: String) {
        self.exportedAt = exportedAt
        self.version = version
        self.dataRange = dataRange
    }
}

/// JSON export wrapper
public struct JSONExportWrapper: Codable, Equatable, Sendable {
    public let metadata: ExportMetadata
    public let analytics: AnalyticsDashboardData

    public init(metadata: ExportMetadata, analytics: AnalyticsDashboardData) {
        self.metadata = metadata
        self.analytics = analytics
    }
}

/// Time range export data
public struct TimeRangeExportData: Codable, Equatable, Sendable {
    public let timeRange: TimeRange
    public let startDate: Date
    public let endDate: Date
    public let metricData: [String: Double]

    public init(timeRange: TimeRange, startDate: Date, endDate: Date, metricData: [String: Double]) {
        self.timeRange = timeRange
        self.startDate = startDate
        self.endDate = endDate
        self.metricData = metricData
    }
}

/// Export errors
public enum ExportError: Error, Equatable {
    case noDataAvailable
    case exportFailed(Error)
    case invalidFormat
    case fileSystemError
    case insufficientStorage

    public static func == (lhs: ExportError, rhs: ExportError) -> Bool {
        switch (lhs, rhs) {
        case (.noDataAvailable, .noDataAvailable),
             (.invalidFormat, .invalidFormat),
             (.fileSystemError, .fileSystemError),
             (.insufficientStorage, .insufficientStorage):
            true
        case (.exportFailed, .exportFailed):
            true
        default:
            false
        }
    }
}

extension ExportError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noDataAvailable:
            "No analytics data available for export"
        case .exportFailed:
            "Export operation failed"
        case .invalidFormat:
            "Invalid export format selected"
        case .fileSystemError:
            "File system error occurred during export"
        case .insufficientStorage:
            "Insufficient storage space for export"
        }
    }
}
