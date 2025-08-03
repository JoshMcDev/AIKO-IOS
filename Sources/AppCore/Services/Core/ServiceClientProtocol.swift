import Foundation
import Combine

// MARK: - ServiceClientProtocol - Unified API Client Base

/// Unified protocol for all API service clients to eliminate boilerplate duplication
/// Provides consistent HTTP handling, error management, and networking patterns
public protocol ServiceClientProtocol: Sendable {
    /// Base URL for the service
    var baseURL: URL { get }
    
    /// URLSession for network requests
    var session: URLSession { get }
    
    /// JSON decoder with consistent configuration
    var decoder: JSONDecoder { get }
    
    /// JSON encoder with consistent configuration  
    var encoder: JSONEncoder { get }
    
    /// Default headers to include with all requests
    var defaultHeaders: [String: String] { get }
    
    /// Service-specific error transformer
    func transformError(_ error: Error) -> AIKOError
}

// MARK: - Default Implementation

public extension ServiceClientProtocol {
    
    /// Default JSON decoder with ISO8601 date strategy
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    /// Default JSON encoder with ISO8601 date strategy
    var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    /// Default headers for JSON API requests
    var defaultHeaders: [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "AIKO/1.0"
        ]
    }
    
    /// Default error transformation - can be overridden by services
    func transformError(_ error: Error) -> AIKOError {
        if let aikoError = error as? AIKOError {
            return aikoError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable(underlying: urlError)
            case .timedOut:
                return .requestTimeout(underlying: urlError)
            case .badURL:
                return .invalidRequest("Invalid URL", underlying: urlError)
            default:
                return .networkError(urlError.localizedDescription, underlying: urlError)
            }
        }
        
        return .unknownError(error.localizedDescription, underlying: error)
    }
}

// MARK: - HTTP Request Building

public extension ServiceClientProtocol {
    
    /// Build URLRequest with consistent configuration
    /// - Parameters:
    ///   - path: API endpoint path (relative to baseURL)
    ///   - method: HTTP method
    ///   - headers: Additional headers (merged with defaults)
    ///   - body: Request body data
    ///   - queryItems: URL query parameters
    /// - Returns: Configured URLRequest
    func buildRequest(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URLRequest {
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true) else {
            throw AIKOError.invalidRequest("Cannot build URL from path: \(path)")
        }
        
        // Add query parameters
        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw AIKOError.invalidRequest("Cannot create URL from components")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Apply default headers first
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Apply custom headers (can override defaults)
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    /// Execute URLRequest with consistent error handling and retry logic
    /// - Parameters:
    ///   - request: URLRequest to execute
    ///   - retryCount: Number of retry attempts (default: 3)
    ///   - retryDelay: Base delay between retries in seconds (default: 1.0)
    /// - Returns: Response data and HTTPURLResponse
    func executeRequest(
        _ request: URLRequest,
        retryCount: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) async throws -> (Data, HTTPURLResponse) {
        var lastError: Error?
        
        for attempt in 1...retryCount {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AIKOError.invalidResponse("Non-HTTP response received")
                }
                
                // Check for HTTP errors
                if !httpResponse.isSuccessful {
                    let errorData = String(data: data, encoding: .utf8) ?? "No error data"
                    throw AIKOError.httpError(
                        statusCode: httpResponse.statusCode,
                        message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                        responseData: errorData
                    )
                }
                
                return (data, httpResponse)
                
            } catch {
                lastError = error
                
                // Don't retry client errors (4xx) or specific error types
                if let aikoError = error as? AIKOError,
                   case .httpError(let statusCode, _, _) = aikoError,
                   (400..<500).contains(statusCode) {
                    throw transformError(error)
                }
                
                // Retry with exponential backoff
                if attempt < retryCount {
                    let delay = retryDelay * pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw transformError(lastError ?? AIKOError.unknownError("Request failed after \(retryCount) attempts"))
    }
}

// MARK: - Convenience Methods

public extension ServiceClientProtocol {
    
    /// GET request returning decoded JSON
    func get<T: Decodable>(
        path: String,
        responseType: T.Type,
        headers: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try buildRequest(
            path: path,
            method: .get,
            headers: headers,
            queryItems: queryItems
        )
        
        let (data, _) = try await executeRequest(request)
        
        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            throw AIKOError.decodingError("Failed to decode \(responseType)", underlying: error)
        }
    }
    
    /// POST request with encoded body returning decoded JSON
    func post<T: Decodable, U: Encodable>(
        path: String,
        body: U,
        responseType: T.Type,
        headers: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw AIKOError.encodingError("Failed to encode request body", underlying: error)
        }
        
        let request = try buildRequest(
            path: path,
            method: .post,
            headers: headers,
            body: bodyData,
            queryItems: queryItems
        )
        
        let (data, _) = try await executeRequest(request)
        
        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            throw AIKOError.decodingError("Failed to decode \(responseType)", underlying: error)
        }
    }
    
    /// PUT request with encoded body returning decoded JSON
    func put<T: Decodable, U: Encodable>(
        path: String,
        body: U,
        responseType: T.Type,
        headers: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw AIKOError.encodingError("Failed to encode request body", underlying: error)
        }
        
        let request = try buildRequest(
            path: path,
            method: .put,
            headers: headers,
            body: bodyData,
            queryItems: queryItems
        )
        
        let (data, _) = try await executeRequest(request)
        
        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            throw AIKOError.decodingError("Failed to decode \(responseType)", underlying: error)
        }
    }
    
    /// DELETE request
    func delete(
        path: String,
        headers: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws {
        let request = try buildRequest(
            path: path,
            method: .delete,
            headers: headers,
            queryItems: queryItems
        )
        
        _ = try await executeRequest(request)
    }
    
    /// Generic request for custom HTTP methods
    func request<T: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        responseType: T.Type,
        headers: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try buildRequest(
            path: path,
            method: method,
            headers: headers,
            body: body,
            queryItems: queryItems
        )
        
        let (data, _) = try await executeRequest(request)
        
        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            throw AIKOError.decodingError("Failed to decode \(responseType)", underlying: error)
        }
    }
    
    /// Download raw data
    func downloadData(
        path: String,
        headers: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Data {
        let request = try buildRequest(
            path: path,
            method: .get,
            headers: headers,
            queryItems: queryItems
        )
        
        let (data, _) = try await executeRequest(request)
        return data
    }
}

// MARK: - Supporting Types

/// HTTP methods supported by ServiceClientProtocol
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
}

/// HTTPURLResponse convenience extension
extension HTTPURLResponse {
    /// Check if status code indicates success (200-299)
    var isSuccessful: Bool {
        (200..<300).contains(statusCode)
    }
    
    /// Check if status code indicates client error (400-499)
    var isClientError: Bool {
        (400..<500).contains(statusCode)
    }
    
    /// Check if status code indicates server error (500-599)
    var isServerError: Bool {
        (500..<600).contains(statusCode)
    }
}

// MARK: - Base Service Client Implementation

/// Concrete base implementation of ServiceClientProtocol for common use cases
open class BaseServiceClient: @unchecked Sendable, ServiceClientProtocol {
    public let baseURL: URL
    public let session: URLSession
    
    /// Initialize with base URL and optional custom session
    /// - Parameters:
    ///   - baseURL: Base URL for all requests
    ///   - session: Custom URLSession (uses default if not provided)
    public init(baseURL: URL, session: URLSession? = nil) {
        self.baseURL = baseURL
        
        if let session = session {
            self.session = session
        } else {
            // Create optimized session configuration
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 300
            config.waitsForConnectivity = true
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            
            self.session = URLSession(configuration: config)
        }
    }
}