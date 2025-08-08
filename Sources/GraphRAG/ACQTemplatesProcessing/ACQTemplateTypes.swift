import Foundation

// MARK: - ProcessedTemplate

struct ProcessedTemplate: Codable {
    enum ProcessingMode: Codable {
        case normal
        case memoryConstrained
        case streaming
    }

    let chunks: [TemplateChunk]
    let category: TemplateCategory
    let metadata: TemplateMetadata
    let processingMode: ProcessingMode
}

// MARK: - TemplateChunk

struct TemplateChunk: Codable {
    let content: String
    let chunkIndex: Int
    let overlap: String
    let metadata: ChunkMetadata
    let isMemoryMapped: Bool
}

// MARK: - ChunkMetadata

struct ChunkMetadata: Codable {
    let startOffset: Int
    let endOffset: Int
    let tokens: Int
}

// MARK: - TemplateMetadata

struct TemplateMetadata: Sendable, Codable {
    let templateID: String
    let fileName: String
    let fileType: String
    let category: TemplateCategory?
    let agency: String?
    let effectiveDate: Date?
    let lastModified: Date
    let fileSize: Int64
    let checksum: String
}

// MARK: - TemplateCategory

enum TemplateCategory: String, CaseIterable, Codable {
    case contract = "Contract"
    case statementOfWork = "SOW"
    case form = "Form"
    case clause = "Clause"
    case guide = "Guide"
}

// MARK: - TemplateSearchResult

struct TemplateSearchResult: Identifiable {
    let id: UUID = .init()
    let template: TemplateMetadata
    let score: Float
    let snippet: String
    let category: TemplateCategory
    let crossReferences: [RegulationReference]
    let searchLatency: TimeInterval?
}

// MARK: - LexicalCandidate

struct LexicalCandidate {
    let templateID: String
    let score: Float
    let metadata: TemplateMetadata
    let snippet: String
    let category: TemplateCategory
}

// MARK: - RegulationReference

struct RegulationReference {
    let regulationID: String
    let section: String
    let confidence: Float
}

// MARK: - CategoryFilter

enum CategoryFilter {
    case category(TemplateCategory)

    // MARK: Internal

    func matches(_ category: TemplateCategory?) -> Bool {
        switch self {
        case let .category(filterCategory):
            category == filterCategory
        }
    }
}

// MARK: - SearchPerformanceMonitor

class SearchPerformanceMonitor {
    // MARK: Internal

    func recordLatencyMetrics(_ latencies: [TimeInterval]) async {
        metrics["latencies"] = latencies
    }

    // MARK: Private

    private var metrics: [String: [TimeInterval]] = [:]
}

// MARK: - ACQPerformanceMonitor

class ACQPerformanceMonitor {
    // MARK: Internal

    func startBenchmark(_ name: String) async {
        benchmarks[name] = BenchmarkSession(name: name, startTime: Date())
    }

    func stopBenchmark(_ name: String) async -> [String: Any] {
        guard let session = benchmarks.removeValue(forKey: name) else {
            return [:]
        }

        let duration = Date().timeIntervalSince(session.startTime)
        return [
            "name": name,
            "duration": duration,
            "endTime": Date(),
        ] as [String: Any]
    }

    func recordMetrics(_ newMetrics: [String: Any]) async {
        for (key, value) in newMetrics {
            metrics[key] = value
        }
    }

    // MARK: Private

    private struct BenchmarkSession {
        let name: String
        let startTime: Date
    }

    private var benchmarks: [String: BenchmarkSession] = [:]
    private var metrics: [String: Any] = [:]
}

// MARK: - Test Helper Functions

func unwrapService<T>(_ service: T?) throws -> T {
    guard let service else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Service is nil"])
    }

    return service
}

func randomCategory() -> TemplateCategory? {
    TemplateCategory.allCases.randomElement()
}
