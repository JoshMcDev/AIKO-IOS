import Foundation
import Combine

/// Secure Network Service with certificate pinning and enhanced security
public final class SecureNetworkService: ObservableObject {
    // MARK: - Singleton
    public static let shared = SecureNetworkService()
    
    // MARK: - Properties
    private let pinnedSession: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let requestLogger = RequestLogger()
    
    // Request retry configuration
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    
    // MARK: - Initialization
    private init() {
        // Create session with certificate pinning
        self.pinnedSession = URLSession.pinnedSession()
        
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    /// Perform a secure API request
    public func secureRequest<T: Decodable>(
        to url: URL,
        method: HTTPMethod = .get,
        body: Data? = nil,
        service: APIService,
        responseType: T.Type
    ) async throws -> T {
        // Get headers with API key
        let headers = try await EnhancedAPIConfiguration.headers(for: service)
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Add headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add security headers
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-Nonce")
        request.setValue(generateRequestSignature(request), forHTTPHeaderField: "X-Request-Signature")
        
        // Log request (sanitized)
        requestLogger.logRequest(request, service: service)
        
        // Perform request with retry logic
        let data = try await performRequestWithRetry(request, retries: maxRetries)
        
        // Decode response
        do {
            let response = try decoder.decode(responseType, from: data)
            requestLogger.logSuccess(request, service: service)
            return response
        } catch {
            requestLogger.logError(request, service: service, error: error)
            throw SecureNetworkError.decodingError(error)
        }
    }
    
    /// Download data securely
    public func secureDownload(from url: URL, service: APIService) async throws -> Data {
        let headers = try await EnhancedAPIConfiguration.headers(for: service)
        
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await performRequestWithRetry(request, retries: maxRetries)
    }
    
    // MARK: - Private Methods
    
    private func performRequestWithRetry(_ request: URLRequest, retries: Int) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0..<retries {
            do {
                let (data, response) = try await pinnedSession.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SecureNetworkError.invalidResponse
                }
                
                // Check for rate limiting
                if httpResponse.statusCode == 429 {
                    if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                       let retrySeconds = Double(retryAfter) {
                        try await Task.sleep(nanoseconds: UInt64(retrySeconds * 1_000_000_000))
                        continue
                    }
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw SecureNetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
                }
                
                return data
                
            } catch {
                lastError = error
                
                // Don't retry on certificate pinning failures
                if case SecureNetworkError.certificatePinningFailed = error {
                    throw error
                }
                
                // Exponential backoff
                if attempt < retries - 1 {
                    let delay = retryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? SecureNetworkError.unknownError
    }
    
    private func generateRequestSignature(_ request: URLRequest) -> String {
        // In production, implement HMAC-SHA256 signature
        // This is a simplified version
        let components = [
            request.httpMethod ?? "",
            request.url?.absoluteString ?? "",
            String(Date().timeIntervalSince1970)
        ]
        return components.joined(separator: ":").data(using: .utf8)?.base64EncodedString() ?? ""
    }
}

// MARK: - Supporting Types

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum SecureNetworkError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case certificatePinningFailed
    case rateLimited(retryAfter: TimeInterval?)
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .certificatePinningFailed:
            return "Certificate validation failed"
        case .rateLimited(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limited. Retry after \(Int(retryAfter)) seconds"
            }
            return "Rate limited"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Request Logger

private final class RequestLogger {
    private let logQueue = DispatchQueue(label: "com.aiko.request-logger")
    
    func logRequest(_ request: URLRequest, service: APIService) {
        logQueue.async {
            var sanitizedHeaders = request.allHTTPHeaderFields ?? [:]
            // Remove sensitive headers from logs
            sanitizedHeaders["x-api-key"] = "[REDACTED]"
            sanitizedHeaders["Authorization"] = "[REDACTED]"
            sanitizedHeaders["X-API-Key"] = "[REDACTED]"
            
            print("""
            🔒 Secure Request:
            Service: \(service.rawValue)
            URL: \(request.url?.absoluteString ?? "Unknown")
            Method: \(request.httpMethod ?? "Unknown")
            Headers: \(sanitizedHeaders)
            """)
        }
    }
    
    func logSuccess(_ request: URLRequest, service: APIService) {
        logQueue.async {
            print("✅ Request successful: \(request.url?.absoluteString ?? "Unknown")")
        }
    }
    
    func logError(_ request: URLRequest, service: APIService, error: Error) {
        logQueue.async {
            print("""
            ❌ Request failed:
            URL: \(request.url?.absoluteString ?? "Unknown")
            Error: \(error.localizedDescription)
            """)
        }
    }
}

// MARK: - Anthropic Service Helper

public struct SecureAnthropicServiceHelper {
    /// Create an Anthropic service with enhanced security
    public static func createSecureService() async throws -> String {
        return try await EnhancedAPIConfiguration.getAnthropicKey()
    }
}