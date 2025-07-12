import Foundation

public enum AppError: Error, Equatable, Identifiable {
    case networkError(String)
    case authenticationError(String)
    case dataError(String)
    case validationError(String)
    case fileSystemError(String)
    case apiError(String)
    case unknown(String)
    
    public var id: String {
        switch self {
        case .networkError(let message),
             .authenticationError(let message),
             .dataError(let message),
             .validationError(let message),
             .fileSystemError(let message),
             .apiError(let message),
             .unknown(let message):
            return message
        }
    }
    
    public var message: String {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .fileSystemError(let message):
            return "File System Error: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .unknown(let message):
            return "Error: \(message)"
        }
    }
}