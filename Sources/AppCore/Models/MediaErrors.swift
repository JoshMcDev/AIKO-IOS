import Foundation

// MARK: - Media Error Types

/// Comprehensive error types for media operations
public enum MediaError: Error, Sendable, LocalizedError {
    case invalidInput(String)
    case fileNotFound(String)
    case unsupportedFormat(String)
    case processingFailed(String)
    case networkError(String)
    case permissionDenied(String)
    case storageError(String)
    case corruptedData(String)
    case timeout(String)
    case unsupportedOperation(String)
    case configurationError(String)
    case resourceUnavailable(String)
    case authenticationRequired(String)
    case quotaExceeded(String)
    case versionMismatch(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidInput(message):
            return "Invalid input: \(message)"
        case let .fileNotFound(message):
            return "File not found: \(message)"
        case let .unsupportedFormat(message):
            return "Unsupported format: \(message)"
        case let .processingFailed(message):
            return "Processing failed: \(message)"
        case let .networkError(message):
            return "Network error: \(message)"
        case let .permissionDenied(message):
            return "Permission denied: \(message)"
        case let .storageError(message):
            return "Storage error: \(message)"
        case let .corruptedData(message):
            return "Corrupted data: \(message)"
        case let .timeout(message):
            return "Operation timed out: \(message)"
        case let .unsupportedOperation(message):
            return "Unsupported operation: \(message)"
        case let .configurationError(message):
            return "Configuration error: \(message)"
        case let .resourceUnavailable(message):
            return "Resource unavailable: \(message)"
        case let .authenticationRequired(message):
            return "Authentication required: \(message)"
        case let .quotaExceeded(message):
            return "Quota exceeded: \(message)"
        case let .versionMismatch(message):
            return "Version mismatch: \(message)"
        case let .unknown(message):
            return "Unknown error: \(message)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidInput:
            return "The provided input data is invalid or malformed"
        case .fileNotFound:
            return "The requested file could not be located"
        case .unsupportedFormat:
            return "The file format is not supported by this operation"
        case .processingFailed:
            return "The media processing operation failed to complete"
        case .networkError:
            return "A network connectivity issue occurred"
        case .permissionDenied:
            return "Insufficient permissions to perform this operation"
        case .storageError:
            return "An error occurred while accessing storage"
        case .corruptedData:
            return "The data appears to be corrupted or incomplete"
        case .timeout:
            return "The operation took too long to complete"
        case .unsupportedOperation:
            return "This operation is not supported in the current context"
        case .configurationError:
            return "The system configuration is invalid or incomplete"
        case .resourceUnavailable:
            return "The required resource is temporarily unavailable"
        case .authenticationRequired:
            return "Authentication is required to access this resource"
        case .quotaExceeded:
            return "The operation would exceed available quota limits"
        case .versionMismatch:
            return "The data version is incompatible with the current system"
        case .unknown:
            return "An unexpected error occurred"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "Please verify the input data and try again"
        case .fileNotFound:
            return "Check the file path and ensure the file exists"
        case .unsupportedFormat:
            return "Convert the file to a supported format"
        case .processingFailed:
            return "Try the operation again or check system resources"
        case .networkError:
            return "Check your network connection and retry"
        case .permissionDenied:
            return "Grant the necessary permissions and try again"
        case .storageError:
            return "Check available storage space and file permissions"
        case .corruptedData:
            return "Try using a backup or re-downloading the data"
        case .timeout:
            return "Try the operation again or increase timeout settings"
        case .unsupportedOperation:
            return "Use an alternative method or update the application"
        case .configurationError:
            return "Check system settings and configuration"
        case .resourceUnavailable:
            return "Wait a moment and try again"
        case .authenticationRequired:
            return "Please authenticate and try again"
        case .quotaExceeded:
            return "Free up space or upgrade your plan"
        case .versionMismatch:
            return "Update the application or convert the data"
        case .unknown:
            return "Contact support if the problem persists"
        }
    }
}
