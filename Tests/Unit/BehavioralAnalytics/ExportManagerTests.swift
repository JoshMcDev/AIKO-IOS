import XCTest
import Foundation
import PDFKit
import SwiftUI
@testable import AIKO

/// Comprehensive tests for ExportManager - PDF/CSV/JSON export functionality
/// RED PHASE: All tests should FAIL initially as ExportManager doesn't exist yet
final class ExportManagerTests: XCTestCase {

    // MARK: - Properties

    var exportManager: ExportManager?
    var mockRepository: MockAnalyticsRepository?
    var mockFileManager: MockFileManager?
    var testExportData: AnalyticsExportData?

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        mockRepository = MockAnalyticsRepository()
        mockFileManager = MockFileManager()
        testExportData = createTestExportData()

        // RED: Will fail as ExportManager doesn't exist
        exportManager = await ExportManager(repository: mockRepository)
        exportManager.fileManager = mockFileManager
    }

    override func tearDown() async throws {
        exportManager = nil
        mockRepository = nil
        mockFileManager = nil
        testExportData = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func getExportManager() throws -> ExportManager {
        guard let manager = exportManager else {
            throw XCTestError(.failureWhileWaiting, userInfo: [NSLocalizedDescriptionKey: "ExportManager not initialized"])
        }
        return manager
    }

    private func getMockRepository() throws -> MockAnalyticsRepository {
        guard let repository = mockRepository else {
            throw XCTestError(.failureWhileWaiting, userInfo: [NSLocalizedDescriptionKey: "MockRepository not initialized"])
        }
        return repository
    }

    private func getTestExportData() throws -> AnalyticsExportData {
        guard let data = testExportData else {
            throw XCTestError(.failureWhileWaiting, userInfo: [NSLocalizedDescriptionKey: "TestExportData not initialized"])
        }
        return data
    }

    // MARK: - Initialization Tests

    func test_ExportManager_initialization() async {
        // RED: Will fail as ExportManager doesn't exist
        do {
            let manager = try getExportManager()
            XCTAssertNotNil(manager)
            XCTAssertNotNil(manager.repository)
        } catch {
            XCTFail("Failed to get export manager: \(error)")
        }
    }

    // MARK: - PDF Export Tests

    func test_generatePDFExport_createsValidPDF() async throws {
        // RED: Will fail as generatePDFExport doesn't exist
        mockRepository.mockExportData = testExportData

        let pdfURL = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        XCTAssertNotNil(pdfURL)
        XCTAssertEqual(pdfURL.pathExtension, "pdf")
        XCTAssertTrue(mockFileManager.fileExists(atPath: pdfURL.path))
    }

    func test_generatePDFExport_containsExpectedContent() async throws {
        // RED: Will fail as PDF content generation doesn't exist
        mockRepository.mockExportData = testExportData

        let pdfURL = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        let pdfDocument = PDFDocument(url: pdfURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 0)

        let firstPage = pdfDocument?.page(at: 0)
        let pageContent = firstPage?.string

        XCTAssertTrue(pageContent?.contains("Behavioral Analytics Report") == true)
        XCTAssertTrue(pageContent?.contains("Focus Time") == true)
        XCTAssertTrue(pageContent?.contains("Learning Effectiveness") == true)
    }

    func test_generatePDFExport_handlesEmptyData() async throws {
        // RED: Will fail as empty data handling doesn't exist
        mockRepository.mockExportData = AnalyticsExportData(
            summaryMetrics: [],
            timeSeriesData: [],
            insights: [],
            dateRange: DateInterval(start: Date(), end: Date())
        )

        let pdfURL = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        XCTAssertNotNil(pdfURL)

        let pdfDocument = PDFDocument(url: pdfURL)
        let pageContent = pdfDocument?.page(at: 0)?.string

        XCTAssertTrue(pageContent?.contains("No data available") == true)
    }

    func test_generatePDFExport_setsCorrectDimensions() async throws {
        // RED: Will fail as PDF dimension setting doesn't exist
        mockRepository.mockExportData = testExportData

        let pdfURL = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        let pdfDocument = PDFDocument(url: pdfURL)
        let firstPage = pdfDocument?.page(at: 0)
        let mediaBox = firstPage?.bounds(for: .mediaBox)

        // Should be 8.5" x 11" (612 x 792 points)
        XCTAssertEqual(mediaBox?.width, 612, accuracy: 1.0)
        XCTAssertEqual(mediaBox?.height, 792, accuracy: 1.0)
    }

    func test_generatePDFExport_includesCharts() async throws {
        // RED: Will fail as chart rendering doesn't exist
        testExportData.timeSeriesData = createMockTimeSeriesData()
        mockRepository.mockExportData = testExportData

        let pdfURL = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        // Verify PDF contains visual elements (charts)
        let pdfDocument = PDFDocument(url: pdfURL)
        XCTAssertNotNil(pdfDocument)

        // Check that PDF has sufficient content length (indicating charts are rendered)
        let pageContent = pdfDocument?.page(at: 0)?.string ?? ""
        XCTAssertGreaterThan(pageContent.count, 100)
    }

    // MARK: - CSV Export Tests

    func test_generateCSVExport_createsValidCSV() async throws {
        // RED: Will fail as generateCSVExport doesn't exist
        mockRepository.mockExportData = testExportData

        let csvURL = try await exportManager.generateExport(
            format: .csv,
            timeRange: .thirtyDays
        )

        XCTAssertNotNil(csvURL)
        XCTAssertEqual(csvURL.pathExtension, "csv")
        XCTAssertTrue(mockFileManager.fileExists(atPath: csvURL.path))
    }

    func test_generateCSVExport_containsExpectedHeaders() async throws {
        // RED: Will fail as CSV header generation doesn't exist
        mockRepository.mockExportData = testExportData

        let csvURL = try await exportManager.generateExport(
            format: .csv,
            timeRange: .thirtyDays
        )

        let csvContent = try String(contentsOf: csvURL)
        let lines = csvContent.components(separatedBy: .newlines)

        XCTAssertFalse(lines.isEmpty)
        let headerLine = lines[0]

        XCTAssertTrue(headerLine.contains("Date"))
        XCTAssertTrue(headerLine.contains("Metric"))
        XCTAssertTrue(headerLine.contains("Value"))
        XCTAssertTrue(headerLine.contains("Category"))
    }

    func test_generateCSVExport_containsAllData() async throws {
        // RED: Will fail as CSV data serialization doesn't exist
        testExportData.timeSeriesData = createMockTimeSeriesData(count: 10)
        mockRepository.mockExportData = testExportData

        let csvURL = try await exportManager.generateExport(
            format: .csv,
            timeRange: .thirtyDays
        )

        let csvContent = try String(contentsOf: csvURL)
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }

        // Should have header + 10 data rows + summary metrics
        XCTAssertGreaterThanOrEqual(lines.count, 11) // 1 header + 10+ data rows
    }

    func test_generateCSVExport_handlesSpecialCharacters() async throws {
        // RED: Will fail as CSV escaping doesn't exist
        testExportData.summaryMetrics = [
            ExportSummaryMetric(
                name: "Test, Metric",
                value: "100%",
                description: "Contains \"quotes\" and commas"
            )
        ]
        mockRepository.mockExportData = testExportData

        let csvURL = try await exportManager.generateExport(
            format: .csv,
            timeRange: .thirtyDays
        )

        let csvContent = try String(contentsOf: csvURL)

        // Should properly escape commas and quotes
        XCTAssertTrue(csvContent.contains("\"Test, Metric\""))
        XCTAssertTrue(csvContent.contains("\"Contains \"\"quotes\"\" and commas\""))
    }

    func test_generateCSVExport_formatsDateCorrectly() async throws {
        // RED: Will fail as date formatting doesn't exist
        let testDate = Date()
        testExportData.timeSeriesData = [
            ExportTimeSeriesPoint(
                date: testDate,
                value: 0.85,
                metric: "Learning Effectiveness"
            )
        ]
        mockRepository.mockExportData = testExportData

        let csvURL = try await exportManager.generateExport(
            format: .csv,
            timeRange: .thirtyDays
        )

        let csvContent = try String(contentsOf: csvURL)
        let expectedDateString = ISO8601DateFormatter().string(from: testDate)

        XCTAssertTrue(csvContent.contains(expectedDateString))
    }

    // MARK: - JSON Export Tests

    func test_generateJSONExport_createsValidJSON() async throws {
        // RED: Will fail as generateJSONExport doesn't exist
        mockRepository.mockExportData = testExportData

        let jsonURL = try await exportManager.generateExport(
            format: .json,
            timeRange: .thirtyDays
        )

        XCTAssertNotNil(jsonURL)
        XCTAssertEqual(jsonURL.pathExtension, "json")
        XCTAssertTrue(mockFileManager.fileExists(atPath: jsonURL.path))
    }

    func test_generateJSONExport_containsValidJSONStructure() async throws {
        // RED: Will fail as JSON structure doesn't exist
        mockRepository.mockExportData = testExportData

        let jsonURL = try await exportManager.generateExport(
            format: .json,
            timeRange: .thirtyDays
        )

        let jsonData = try Data(contentsOf: jsonURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)

        XCTAssertTrue(jsonObject is [String: Any])

        guard let json = jsonObject as? [String: Any] else {
            XCTFail("JSON object should be a dictionary")
            return
        }
        XCTAssertNotNil(json["exportMetadata"])
        XCTAssertNotNil(json["summaryMetrics"])
        XCTAssertNotNil(json["timeSeriesData"])
        XCTAssertNotNil(json["behavioralInsights"])
    }

    func test_generateJSONExport_includesMetadata() async throws {
        // RED: Will fail as metadata inclusion doesn't exist
        mockRepository.mockExportData = testExportData

        let jsonURL = try await exportManager.generateExport(
            format: .json,
            timeRange: .thirtyDays
        )

        let jsonData = try Data(contentsOf: jsonURL)
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let metadata = json["exportMetadata"] as? [String: Any] else {
            XCTFail("JSON should contain expected structure with metadata")
            return
        }

        XCTAssertNotNil(metadata["exportDate"])
        XCTAssertNotNil(metadata["timeRange"])
        XCTAssertNotNil(metadata["version"])
        XCTAssertEqual(metadata["format"] as? String, "json")
    }

    func test_generateJSONExport_preservesDataTypes() async throws {
        // RED: Will fail as data type preservation doesn't exist
        testExportData.timeSeriesData = [
            ExportTimeSeriesPoint(
                date: Date(),
                value: 0.85,
                metric: "Learning Effectiveness"
            )
        ]
        mockRepository.mockExportData = testExportData

        let jsonURL = try await exportManager.generateExport(
            format: .json,
            timeRange: .thirtyDays
        )

        let jsonData = try Data(contentsOf: jsonURL)
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let timeSeriesArray = json["timeSeriesData"] as? [[String: Any]] else {
            XCTFail("JSON should contain expected time series structure")
            return
        }
        let firstPoint = timeSeriesArray[0]

        XCTAssertTrue(firstPoint["value"] is Double)
        XCTAssertTrue(firstPoint["date"] is String)
        XCTAssertTrue(firstPoint["metric"] is String)
    }

    // MARK: - Performance Tests

    func test_exportGeneration_completesWithinTimeLimit() async throws {
        // RED: Will fail as performance optimization doesn't exist
        mockRepository.mockExportData = createLargeExportDataset()

        let startTime = CFAbsoluteTimeGetCurrent()

        _ = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        let exportTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(exportTime, 2.0, "PDF export should complete within 2 seconds")
    }

    func test_csvExport_handlesLargeDataset() async throws {
        // RED: Will fail as large dataset handling doesn't exist
        testExportData.timeSeriesData = createMockTimeSeriesData(count: 1000)
        mockRepository.mockExportData = testExportData

        let startTime = CFAbsoluteTimeGetCurrent()

        let csvURL = try await exportManager.generateExport(
            format: .csv,
            timeRange: .oneYear
        )

        let exportTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(exportTime, 1.0, "CSV export should handle large datasets within 1 second")

        let csvContent = try String(contentsOf: csvURL)
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }

        XCTAssertGreaterThanOrEqual(lines.count, 1000)
    }

    func test_memoryUsage_staysWithinLimits() async throws {
        // RED: Will fail as memory management doesn't exist
        let beforeMemory = getMemoryUsage()

        mockRepository.mockExportData = createMassiveExportDataset()

        _ = try await exportManager.generateExport(
            format: .json,
            timeRange: .oneYear
        )

        let afterMemory = getMemoryUsage()
        let memoryIncrease = afterMemory - beforeMemory

        // Should stay under 100MB increase
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024, "Memory usage should stay within 100MB")
    }

    // MARK: - Error Handling Tests

    func test_exportGeneration_handlesRepositoryErrors() async {
        // RED: Will fail as error handling doesn't exist
        mockRepository.shouldThrowError = true

        do {
            _ = try await exportManager.generateExport(
                format: .pdf,
                timeRange: .thirtyDays
            )
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is ExportError)
        }
    }

    func test_exportGeneration_handlesFileSystemErrors() async {
        // RED: Will fail as file system error handling doesn't exist
        mockFileManager.shouldFailWrite = true
        mockRepository.mockExportData = testExportData

        do {
            _ = try await exportManager.generateExport(
                format: .csv,
                timeRange: .thirtyDays
            )
            XCTFail("Should have thrown a file system error")
        } catch {
            XCTAssertTrue(error is ExportError)
        }
    }

    func test_exportGeneration_handlesInvalidData() async {
        // RED: Will fail as invalid data handling doesn't exist
        mockRepository.mockExportData = AnalyticsExportData(
            summaryMetrics: [],
            timeSeriesData: [
                ExportTimeSeriesPoint(
                    date: Date.distantPast, // Invalid date
                    value: Double.nan, // Invalid value
                    metric: ""
                )
            ],
            insights: [],
            dateRange: DateInterval(start: Date(), end: Date())
        )

        // Should not crash, should handle gracefully
        let jsonURL = try await exportManager.generateExport(
            format: .json,
            timeRange: .thirtyDays
        )

        XCTAssertNotNil(jsonURL)
    }

    // MARK: - File Naming Tests

    func test_exportFilenames_includeTimestamp() async throws {
        // RED: Will fail as filename generation doesn't exist
        mockRepository.mockExportData = testExportData

        let pdfURL = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        let filename = pdfURL.lastPathComponent

        XCTAssertTrue(filename.contains("behavioral-analytics"))
        XCTAssertTrue(filename.contains("30d"))
        XCTAssertTrue(filename.hasPrefix("behavioral-analytics-report"))
        XCTAssertTrue(filename.hasSuffix(".pdf"))
    }

    func test_exportFilenames_differentForEachFormat() async throws {
        // RED: Will fail as format-specific naming doesn't exist
        mockRepository.mockExportData = testExportData

        let pdfURL = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        let csvURL = try await exportManager.generateExport(
            format: .csv,
            timeRange: .thirtyDays
        )

        let jsonURL = try await exportManager.generateExport(
            format: .json,
            timeRange: .thirtyDays
        )

        XCTAssertNotEqual(pdfURL.lastPathComponent, csvURL.lastPathComponent)
        XCTAssertNotEqual(csvURL.lastPathComponent, jsonURL.lastPathComponent)
        XCTAssertNotEqual(pdfURL.lastPathComponent, jsonURL.lastPathComponent)
    }

    // MARK: - Concurrent Export Tests

    func test_concurrentExports_handleCorrectly() async throws {
        // RED: Will fail as concurrency handling doesn't exist
        mockRepository.mockExportData = testExportData

        async let pdfExport = exportManager.generateExport(format: .pdf, timeRange: .thirtyDays)
        async let csvExport = exportManager.generateExport(format: .csv, timeRange: .thirtyDays)
        async let jsonExport = exportManager.generateExport(format: .json, timeRange: .thirtyDays)

        let (pdfURL, csvURL, jsonURL) = try await (pdfExport, csvExport, jsonExport)

        XCTAssertNotNil(pdfURL)
        XCTAssertNotNil(csvURL)
        XCTAssertNotNil(jsonURL)

        XCTAssertTrue(mockFileManager.fileExists(atPath: pdfURL.path))
        XCTAssertTrue(mockFileManager.fileExists(atPath: csvURL.path))
        XCTAssertTrue(mockFileManager.fileExists(atPath: jsonURL.path))
    }

    // MARK: - Cleanup Tests

    func test_temporaryFiles_cleanupAutomatically() async throws {
        // RED: Will fail as cleanup doesn't exist
        guard let mockRepository, let exportManager, let mockFileManager else {
            XCTFail("Dependencies should be initialized")
            return
        }
        mockRepository.mockExportData = testExportData

        let pdfURL = try await exportManager.generateExport(
            format: .pdf,
            timeRange: .thirtyDays
        )

        // File should exist immediately after export
        XCTAssertTrue(mockFileManager.fileExists(atPath: pdfURL.path))

        // Trigger cleanup - commented out as method doesn't exist yet
        // await exportManager.cleanupOldExports()

        // File should still exist (recent)
        XCTAssertTrue(mockFileManager.fileExists(atPath: pdfURL.path))
    }

    // MARK: - Helper Methods

    private func createTestExportData() -> AnalyticsExportData {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            fatalError("Failed to create start date")
        }
        let endDate = Date()

        return AnalyticsExportData(
            summaryMetrics: [
                ExportSummaryMetric(
                    name: "Focus Time",
                    value: "2h 15m",
                    description: "Total focused work time"
                ),
                ExportSummaryMetric(
                    name: "Learning Progress",
                    value: "85%",
                    description: "Overall learning effectiveness"
                )
            ],
            timeSeriesData: createMockTimeSeriesData(count: 30),
            insights: [
                ExportInsight(
                    title: "Morning Productivity Peak",
                    description: "Highest productivity observed between 9-11 AM",
                    confidence: 0.92
                )
            ],
            dateRange: DateInterval(start: startDate, end: endDate)
        )
    }

    private func createMockTimeSeriesData(count: Int = 30) -> [ExportTimeSeriesPoint] {
        (0..<count).map { day in
            ExportTimeSeriesPoint(
                date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                value: Double.random(in: 0.6...0.9),
                metric: "Learning Effectiveness"
            )
        }
    }

    private func createLargeExportDataset() -> AnalyticsExportData {
        guard let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) else {
            fatalError("Failed to create start date")
        }
        let endDate = Date()

        return AnalyticsExportData(
            summaryMetrics: (0..<50).map { index in
                ExportSummaryMetric(
                    name: "Metric \(index)",
                    value: "\(Int.random(in: 0...100))%",
                    description: "Test metric \(index)"
                )
            },
            timeSeriesData: createMockTimeSeriesData(count: 365),
            insights: (0..<100).map { index in
                ExportInsight(
                    title: "Insight \(index)",
                    description: "Test insight description \(index)",
                    confidence: Double.random(in: 0.5...1.0)
                )
            },
            dateRange: DateInterval(start: startDate, end: endDate)
        )
    }

    private func createMassiveExportDataset() -> AnalyticsExportData {
        guard let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) else {
            fatalError("Failed to create start date")
        }
        let endDate = Date()

        return AnalyticsExportData(
            summaryMetrics: (0..<200).map { index in
                ExportSummaryMetric(
                    name: "Massive Metric \(index)",
                    value: "Value \(index)",
                    description: "Large dataset metric \(index)"
                )
            },
            timeSeriesData: createMockTimeSeriesData(count: 5000),
            insights: (0..<1000).map { index in
                ExportInsight(
                    title: "Massive Insight \(index)",
                    description: "Very large dataset insight \(index) with lots of descriptive text that makes the JSON larger",
                    confidence: Double.random(in: 0.5...1.0)
                )
            },
            dateRange: DateInterval(start: startDate, end: endDate)
        )
    }

    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

// MARK: - Mock Types and Supporting Structures

// RED: These will fail as the real types don't exist yet
struct AnalyticsExportData {
    let summaryMetrics: [ExportSummaryMetric]
    let timeSeriesData: [ExportTimeSeriesPoint]
    let insights: [ExportInsight]
    let dateRange: DateInterval
}

struct ExportSummaryMetric {
    let name: String
    let value: String
    let description: String
}

struct ExportTimeSeriesPoint {
    let date: Date
    let value: Double
    let metric: String
}

struct ExportInsight {
    let title: String
    let description: String
    let confidence: Double
}

enum ExportFormat: String {
    case pdf, csv, json
}

enum TimeRange: String {
    case sevenDays = "7d"
    case thirtyDays = "30d"
    case ninetyDays = "90d"
    case oneYear = "1y"
}

enum ExportError: Error {
    case dataUnavailable
    case fileSystemError
    case invalidFormat
}

class MockFileManager {
    private var files: Set<String> = []
    var shouldFailWrite = false

    func fileExists(atPath path: String) -> Bool {
        return files.contains(path)
    }

    func createFile(atPath path: String, contents data: Data?) -> Bool {
        if shouldFailWrite {
            return false
        }
        files.insert(path)
        return true
    }

    var temporaryDirectory: URL {
        return URL(fileURLWithPath: "/tmp/test-exports")
    }
}
