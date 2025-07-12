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
        case let .networkError(message),
             let .authenticationError(message),
             let .dataError(message),
             let .validationError(message),
             let .fileSystemError(message),
             let .apiError(message),
             let .unknown(message):
            message
        }
    }

    public var message: String {
        switch self {
        case let .networkError(message):
            "Network Error: \(message)"
        case let .authenticationError(message):
            "Authentication Error: \(message)"
        case let .dataError(message):
            "Data Error: \(message)"
        case let .validationError(message):
            "Validation Error: \(message)"
        case let .fileSystemError(message):
            "File System Error: \(message)"
        case let .apiError(message):
            "API Error: \(message)"
        case let .unknown(message):
            "Error: \(message)"
        }
    }
}
