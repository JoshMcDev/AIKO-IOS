import Foundation
import Combine

/// Service for handling network requests
public final class NetworkService: ObservableObject {
    // MARK: - Singleton
    public static let shared = NetworkService()
    
    // MARK: - Properties
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // MARK: - Initialization
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: configuration)
        
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    /// Download data from a URL
    public func downloadData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return data
    }
    
    /// Fetch and decode JSON from a URL
    public func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let data = try await downloadData(from: url)
        return try decoder.decode(type, from: data)
    }
    
    /// Post data to a URL
    public func post<T: Encodable>(_ body: T, to url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return data
    }
    
    /// Post and decode response
    public func post<T: Encodable, R: Decodable>(_ body: T, to url: URL, responseType: R.Type) async throws -> R {
        let data = try await post(body, to: url)
        return try decoder.decode(responseType, from: data)
    }
}

// MARK: - Network Errors

public enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network connection unavailable"
        }
    }
}