import Foundation
import Combine

/// Base service class providing common functionality for all services
open class BaseService {
    
    // MARK: - Properties
    
    internal let queue = DispatchQueue(label: "com.aiko.service", attributes: .concurrent)
    internal var cancellables = Set<AnyCancellable>()
    
    // MARK: - Error Handling
    
    internal func executeWithRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(attempt) * 1_000_000_000))
                }
            }
        }
        
        throw ServiceError.retriesExhausted(lastError: lastError)
    }
    
    // MARK: - Logging
    
    internal func log(_ message: String, level: LogLevel = .info) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(level.rawValue.uppercased())] [\(String(describing: type(of: self)))] \(message)")
    }
    
    // MARK: - Performance Monitoring
    
    internal func measurePerformance<T>(
        operation: String,
        block: () async throws -> T
    ) async throws -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try await block()
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log("Operation '\(operation)' completed in \(String(format: "%.3f", elapsedTime))s", level: .debug)
            return result
        } catch {
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log("Operation '\(operation)' failed after \(String(format: "%.3f", elapsedTime))s: \(error)", level: .error)
            throw error
        }
    }
}

// MARK: - CRUD Service Base

public class CRUDServiceBase<Model: Identifiable, Repository: RepositoryProtocol>: BaseService where Repository.Model == Model {
    
    internal let repository: Repository
    
    public init(repository: Repository) {
        self.repository = repository
        super.init()
    }
    
    // MARK: - CRUD Operations
    
    open func create(_ model: Model) async throws -> Model {
        try await measurePerformance(operation: "create") {
            try await repository.create(model)
        }
    }
    
    open func read(id: Model.ID) async throws -> Model? {
        try await measurePerformance(operation: "read") {
            try await repository.read(id: id)
        }
    }
    
    open func update(_ model: Model) async throws -> Model {
        try await measurePerformance(operation: "update") {
            try await repository.update(model)
        }
    }
    
    open func delete(id: Model.ID) async throws {
        try await measurePerformance(operation: "delete") {
            try await repository.delete(id: id)
        }
    }
    
    open func list() async throws -> [Model] {
        try await measurePerformance(operation: "list") {
            try await repository.list()
        }
    }
    
    // MARK: - Batch Operations
    
    open func batchCreate(_ models: [Model]) async throws -> [Model] {
        try await measurePerformance(operation: "batchCreate(\(models.count) items)") {
            try await withThrowingTaskGroup(of: Model.self) { group in
                for model in models {
                    group.addTask {
                        try await self.repository.create(model)
                    }
                }
                
                var results: [Model] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }
        }
    }
    
    open func batchDelete(ids: [Model.ID]) async throws {
        try await measurePerformance(operation: "batchDelete(\(ids.count) items)") {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for id in ids {
                    group.addTask {
                        try await self.repository.delete(id: id)
                    }
                }
                try await group.waitForAll()
            }
        }
    }
}

// MARK: - API Service Base

open class APIServiceBase: BaseService {
    
    internal let baseURL: URL
    internal let session: URLSession
    internal let decoder = JSONDecoder()
    internal let encoder = JSONEncoder()
    
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        super.init()
        
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Request Building
    
    internal func buildRequest(
        path: String,
        method: HTTPRequestMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw ServiceError.invalidURL(path)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    // MARK: - Request Execution
    
    internal func execute<T: Decodable>(
        request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        try await executeWithRetry {
            let (data, response) = try await self.session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ServiceError.httpError(statusCode: httpResponse.statusCode, data: data)
            }
            
            return try self.decoder.decode(T.self, from: data)
        }
    }
    
    // MARK: - Convenience Methods
    
    internal func get<T: Decodable>(
        path: String,
        responseType: T.Type,
        headers: [String: String]? = nil
    ) async throws -> T {
        let request = try buildRequest(path: path, method: .get, headers: headers)
        return try await execute(request: request, responseType: responseType)
    }
    
    internal func post<T: Decodable, U: Encodable>(
        path: String,
        body: U,
        responseType: T.Type,
        headers: [String: String]? = nil
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        let request = try buildRequest(path: path, method: .post, headers: headers, body: bodyData)
        return try await execute(request: request, responseType: responseType)
    }
}

// MARK: - Supporting Types

public enum ServiceError: LocalizedError {
    case retriesExhausted(lastError: Error?)
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .retriesExhausted(let lastError):
            return "Operation failed after maximum retry attempts: \(lastError?.localizedDescription ?? "Unknown error")"
        case .invalidURL(let path):
            return "Invalid URL path: \(path)"
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

public enum LogLevel: String {
    case debug, info, warning, error
}

public enum HTTPRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Protocol Conformance Helper

public protocol RepositoryProtocol {
    associatedtype Model: Identifiable
    
    func create(_ model: Model) async throws -> Model
    func read(id: Model.ID) async throws -> Model?
    func update(_ model: Model) async throws -> Model
    func delete(id: Model.ID) async throws
    func list() async throws -> [Model]
}