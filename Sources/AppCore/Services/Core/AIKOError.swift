import Foundation

// MARK: - AIKOError - Unified Error Handling Framework

/// Unified error type for the entire AIKO application
/// Eliminates duplication between NetworkError, ServiceError, SAMGovError, etc.
public enum AIKOError: Error, LocalizedError, Sendable {

    // MARK: - Network Errors

    /// Network connection is unavailable
    case networkUnavailable(underlying: Error? = nil)

    /// Request timed out
    case requestTimeout(underlying: Error? = nil)

    /// Invalid URL or request format
    case invalidRequest(String, underlying: Error? = nil)

    /// Invalid response from server
    case invalidResponse(String, underlying: Error? = nil)

    /// HTTP error with status code
    case httpError(statusCode: Int, message: String, responseData: String? = nil)

    /// General network error
    case networkError(String, underlying: Error? = nil)

    // MARK: - Data Processing Errors

    /// Failed to encode data
    case encodingError(String, underlying: Error? = nil)

    /// Failed to decode data
    case decodingError(String, underlying: Error? = nil)

    /// Data validation failed
    case validationError(String, field: String? = nil)

    /// Data corruption detected
    case dataCorruption(String, underlying: Error? = nil)

    // MARK: - Authentication & Authorization

    /// Invalid or missing API key
    case invalidAPIKey(service: String? = nil)

    /// Authentication failed
    case authenticationFailed(String, underlying: Error? = nil)

    /// Insufficient permissions
    case authorizationFailed(String, requiredPermission: String? = nil)

    /// Rate limit exceeded
    case rateLimitExceeded(service: String? = nil, retryAfter: TimeInterval? = nil)

    // MARK: - Resource Errors

    /// Requested resource not found
    case resourceNotFound(String, resourceType: String? = nil)

    /// Resource already exists
    case resourceExists(String, resourceType: String? = nil)

    /// Resource is locked or busy
    case resourceBusy(String, resourceType: String? = nil)

    /// Insufficient storage space
    case insufficientStorage(required: UInt64? = nil, available: UInt64? = nil)

    // MARK: - Service-Specific Errors

    /// SAM.gov API specific errors
    case samGovError(SAMGovErrorType, underlying: Error? = nil)

    /// Document processing errors
    case documentError(DocumentErrorType, underlying: Error? = nil)

    /// Feature flag errors
    case featureFlagError(FeatureFlagErrorType, underlying: Error? = nil)

    /// Core Data persistence errors
    case persistenceError(String, underlying: Error? = nil)

    // MARK: - System Errors

    /// File system operation failed
    case fileSystemError(String, path: String? = nil, underlying: Error? = nil)

    /// Memory allocation failed
    case memoryError(String)

    /// Configuration error
    case configurationError(String, key: String? = nil)

    /// Service unavailable
    case serviceUnavailable(String, service: String? = nil)

    // MARK: - User Errors

    /// User cancelled operation
    case userCancelled

    /// Invalid user input
    case invalidInput(String, field: String? = nil)

    /// Operation not supported
    case notSupported(String, feature: String? = nil)

    // MARK: - Unknown/Generic

    /// Unknown error occurred
    case unknownError(String, underlying: Error? = nil)

    // MARK: - LocalizedError Implementation

    public var errorDescription: String? {
        switch self {
        // Network Errors
        case .networkUnavailable:
            return NSLocalizedString("network.unavailable",
                                     comment: "Network connection is not available")
        case .requestTimeout:
            return NSLocalizedString("network.timeout",
                                     comment: "Request timed out")
        case .invalidRequest(let message, _):
            return NSLocalizedString("network.invalid_request",
                                     comment: "Invalid request: \(message)")
        case .invalidResponse(let message, _):
            return NSLocalizedString("network.invalid_response",
                                     comment: "Invalid response: \(message)")
        case .httpError(let statusCode, let message, _):
            return NSLocalizedString("network.http_error",
                                     comment: "HTTP \(statusCode): \(message)")
        case .networkError(let message, _):
            return NSLocalizedString("network.general_error",
                                     comment: "Network error: \(message)")

        // Data Processing
        case .encodingError(let message, _):
            return NSLocalizedString("data.encoding_error",
                                     comment: "Encoding failed: \(message)")
        case .decodingError(let message, _):
            return NSLocalizedString("data.decoding_error",
                                     comment: "Decoding failed: \(message)")
        case .validationError(let message, let field):
            if let field = field {
                return NSLocalizedString("data.validation_field_error",
                                         comment: "Validation error in \(field): \(message)")
            } else {
                return NSLocalizedString("data.validation_error",
                                         comment: "Validation error: \(message)")
            }
        case .dataCorruption(let message, _):
            return NSLocalizedString("data.corruption",
                                     comment: "Data corruption: \(message)")

        // Authentication & Authorization
        case .invalidAPIKey(let service):
            if let service = service {
                return NSLocalizedString("auth.invalid_api_key_service",
                                         comment: "Invalid API key for \(service)")
            } else {
                return NSLocalizedString("auth.invalid_api_key",
                                         comment: "Invalid or missing API key")
            }
        case .authenticationFailed(let message, _):
            return NSLocalizedString("auth.authentication_failed",
                                     comment: "Authentication failed: \(message)")
        case .authorizationFailed(let message, let permission):
            if let permission = permission {
                return NSLocalizedString("auth.authorization_failed_permission",
                                         comment: "Authorization failed - requires \(permission): \(message)")
            } else {
                return NSLocalizedString("auth.authorization_failed",
                                         comment: "Authorization failed: \(message)")
            }
        case .rateLimitExceeded(let service, let retryAfter):
            if let service = service, let retryAfter = retryAfter {
                return NSLocalizedString("auth.rate_limit_service_retry",
                                         comment: "Rate limit exceeded for \(service). Retry after \(Int(retryAfter)) seconds")
            } else if let service = service {
                return NSLocalizedString("auth.rate_limit_service",
                                         comment: "Rate limit exceeded for \(service)")
            } else {
                return NSLocalizedString("auth.rate_limit",
                                         comment: "Rate limit exceeded")
            }

        // Resources
        case .resourceNotFound(let message, let type):
            if let type = type {
                return NSLocalizedString("resource.not_found_type",
                                         comment: "\(type) not found: \(message)")
            } else {
                return NSLocalizedString("resource.not_found",
                                         comment: "Resource not found: \(message)")
            }
        case .resourceExists(let message, let type):
            if let type = type {
                return NSLocalizedString("resource.exists_type",
                                         comment: "\(type) already exists: \(message)")
            } else {
                return NSLocalizedString("resource.exists",
                                         comment: "Resource already exists: \(message)")
            }
        case .resourceBusy(let message, let type):
            if let type = type {
                return NSLocalizedString("resource.busy_type",
                                         comment: "\(type) is busy: \(message)")
            } else {
                return NSLocalizedString("resource.busy",
                                         comment: "Resource is busy: \(message)")
            }
        case .insufficientStorage(let required, let available):
            if let required = required, let available = available {
                return NSLocalizedString("resource.insufficient_storage_details",
                                         comment: "Insufficient storage: need \(ByteCountFormatter.string(fromByteCount: Int64(required), countStyle: .file)), have \(ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .file))")
            } else {
                return NSLocalizedString("resource.insufficient_storage",
                                         comment: "Insufficient storage space")
            }

        // Service-Specific
        case .samGovError(let type, _):
            return type.localizedDescription
        case .documentError(let type, _):
            return type.localizedDescription
        case .featureFlagError(let type, _):
            return type.localizedDescription
        case .persistenceError(let message, _):
            return NSLocalizedString("persistence.error",
                                     comment: "Persistence error: \(message)")

        // System
        case .fileSystemError(let message, let path, _):
            if let path = path {
                return NSLocalizedString("system.filesystem_path_error",
                                         comment: "File system error at \(path): \(message)")
            } else {
                return NSLocalizedString("system.filesystem_error",
                                         comment: "File system error: \(message)")
            }
        case .memoryError(let message):
            return NSLocalizedString("system.memory_error",
                                     comment: "Memory error: \(message)")
        case .configurationError(let message, let key):
            if let key = key {
                return NSLocalizedString("system.config_key_error",
                                         comment: "Configuration error for \(key): \(message)")
            } else {
                return NSLocalizedString("system.config_error",
                                         comment: "Configuration error: \(message)")
            }
        case .serviceUnavailable(let message, let service):
            if let service = service {
                return NSLocalizedString("system.service_unavailable_named",
                                         comment: "\(service) is unavailable: \(message)")
            } else {
                return NSLocalizedString("system.service_unavailable",
                                         comment: "Service unavailable: \(message)")
            }

        // User
        case .userCancelled:
            return NSLocalizedString("user.cancelled",
                                     comment: "Operation cancelled by user")
        case .invalidInput(let message, let field):
            if let field = field {
                return NSLocalizedString("user.invalid_input_field",
                                         comment: "Invalid input for \(field): \(message)")
            } else {
                return NSLocalizedString("user.invalid_input",
                                         comment: "Invalid input: \(message)")
            }
        case .notSupported(let message, let feature):
            if let feature = feature {
                return NSLocalizedString("user.not_supported_feature",
                                         comment: "\(feature) is not supported: \(message)")
            } else {
                return NSLocalizedString("user.not_supported",
                                         comment: "Not supported: \(message)")
            }

        // Unknown
        case .unknownError(let message, _):
            return NSLocalizedString("unknown.error",
                                     comment: "Unknown error: \(message)")
        }
    }

    public var failureReason: String? {
        switch self {
        case .networkUnavailable(let underlying),
             .requestTimeout(let underlying),
             .invalidRequest(_, let underlying),
             .invalidResponse(_, let underlying),
             .networkError(_, let underlying),
             .encodingError(_, let underlying),
             .decodingError(_, let underlying),
             .dataCorruption(_, let underlying),
             .authenticationFailed(_, let underlying),
             .samGovError(_, let underlying),
             .documentError(_, let underlying),
             .featureFlagError(_, let underlying),
             .persistenceError(_, let underlying),
             .fileSystemError(_, _, let underlying),
             .unknownError(_, let underlying):
            return underlying?.localizedDescription

        case .httpError(_, _, let responseData):
            return responseData

        default:
            return nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return NSLocalizedString("recovery.check_connection",
                                     comment: "Check your internet connection and try again")
        case .requestTimeout:
            return NSLocalizedString("recovery.retry_later",
                                     comment: "Please try again in a few moments")
        case .invalidAPIKey:
            return NSLocalizedString("recovery.check_api_key",
                                     comment: "Please check your API key configuration")
        case .rateLimitExceeded(_, let retryAfter):
            if let retryAfter = retryAfter {
                return NSLocalizedString("recovery.retry_after_time",
                                         comment: "Please wait \(Int(retryAfter)) seconds before trying again")
            } else {
                return NSLocalizedString("recovery.retry_later",
                                         comment: "Please try again later")
            }
        case .insufficientStorage:
            return NSLocalizedString("recovery.free_space",
                                     comment: "Please free up some storage space and try again")
        case .userCancelled:
            return NSLocalizedString("recovery.restart_operation",
                                     comment: "You can restart the operation if needed")
        default:
            return NSLocalizedString("recovery.try_again",
                                     comment: "Please try again")
        }
    }
}

// MARK: - Service-Specific Error Types

/// SAM.gov service specific error types
public enum SAMGovErrorType: Sendable {
    case invalidAPIKey
    case entityNotFound
    case networkError(String)
    case invalidResponse
    case rateLimitExceeded
    case apiKeyRequired

    var localizedDescription: String {
        switch self {
        case .invalidAPIKey:
            return NSLocalizedString("samgov.invalid_api_key",
                                     comment: "Invalid SAM.gov API key")
        case .entityNotFound:
            return NSLocalizedString("samgov.entity_not_found",
                                     comment: "Entity not found in SAM.gov database")
        case .networkError(let message):
            return NSLocalizedString("samgov.network_error",
                                     comment: "SAM.gov network error: \(message)")
        case .invalidResponse:
            return NSLocalizedString("samgov.invalid_response",
                                     comment: "Invalid response from SAM.gov API")
        case .rateLimitExceeded:
            return NSLocalizedString("samgov.rate_limit",
                                     comment: "SAM.gov API rate limit exceeded")
        case .apiKeyRequired:
            return NSLocalizedString("samgov.api_key_required",
                                     comment: "SAM.gov API key is required")
        }
    }
}

/// Document processing specific error types
public enum DocumentErrorType: Sendable {
    case invalidFormat(String)
    case fileTooLarge(UInt64)
    case processingFailed(String)
    case permissionDenied
    case fileNotFound(String)
    case unsupportedType(String)

    var localizedDescription: String {
        switch self {
        case .invalidFormat(let format):
            return NSLocalizedString("document.invalid_format",
                                     comment: "Invalid document format: \(format)")
        case .fileTooLarge(let size):
            return NSLocalizedString("document.file_too_large",
                                     comment: "File too large: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
        case .processingFailed(let reason):
            return NSLocalizedString("document.processing_failed",
                                     comment: "Document processing failed: \(reason)")
        case .permissionDenied:
            return NSLocalizedString("document.permission_denied",
                                     comment: "Permission denied to access document")
        case .fileNotFound(let path):
            return NSLocalizedString("document.file_not_found",
                                     comment: "Document not found: \(path)")
        case .unsupportedType(let type):
            return NSLocalizedString("document.unsupported_type",
                                     comment: "Unsupported document type: \(type)")
        }
    }
}

/// Feature flag specific error types
public enum FeatureFlagErrorType: Sendable {
    case featureNotFound(String)
    case invalidConfiguration(String)
    case evaluationFailed(String)
    case persistenceError(String)

    var localizedDescription: String {
        switch self {
        case .featureNotFound(let feature):
            return NSLocalizedString("featureflag.not_found",
                                     comment: "Feature flag not found: \(feature)")
        case .invalidConfiguration(let config):
            return NSLocalizedString("featureflag.invalid_config",
                                     comment: "Invalid feature flag configuration: \(config)")
        case .evaluationFailed(let reason):
            return NSLocalizedString("featureflag.evaluation_failed",
                                     comment: "Feature flag evaluation failed: \(reason)")
        case .persistenceError(let reason):
            return NSLocalizedString("featureflag.persistence_error",
                                     comment: "Feature flag persistence error: \(reason)")
        }
    }
}

// MARK: - Error Conversion Extensions

public extension AIKOError {

    /// Convert from URLError
    static func from(_ urlError: URLError) -> AIKOError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable(underlying: urlError)
        case .timedOut:
            return .requestTimeout(underlying: urlError)
        case .badURL:
            return .invalidRequest("Invalid URL", underlying: urlError)
        case .cannotFindHost:
            return .networkError("Cannot find host", underlying: urlError)
        case .cannotConnectToHost:
            return .networkError("Cannot connect to host", underlying: urlError)
        case .userCancelledAuthentication:
            return .userCancelled
        default:
            return .networkError(urlError.localizedDescription, underlying: urlError)
        }
    }

    /// Convert from DecodingError
    static func from(_ decodingError: DecodingError) -> AIKOError {
        switch decodingError {
        case .keyNotFound(let key, let context):
            return .decodingError("Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: decodingError)
        case .typeMismatch(let type, let context):
            return .decodingError("Type mismatch for '\(type)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: decodingError)
        case .valueNotFound(let type, let context):
            return .decodingError("Value not found for '\(type)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: decodingError)
        case .dataCorrupted(let context):
            return .dataCorruption("Data corrupted at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: decodingError)
        @unknown default:
            return .decodingError("Unknown decoding error", underlying: decodingError)
        }
    }

    /// Convert from EncodingError
    static func from(_ encodingError: EncodingError) -> AIKOError {
        switch encodingError {
        case .invalidValue(let value, let context):
            return .encodingError("Invalid value '\(value)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: encodingError)
        @unknown default:
            return .encodingError("Unknown encoding error", underlying: encodingError)
        }
    }
}

// MARK: - Error Analytics & Reporting

public extension AIKOError {

    /// Category for error analytics
    var category: String {
        switch self {
        case .networkUnavailable, .requestTimeout, .invalidRequest, .invalidResponse, .httpError, .networkError:
            return "network"
        case .encodingError, .decodingError, .validationError, .dataCorruption:
            return "data"
        case .invalidAPIKey, .authenticationFailed, .authorizationFailed, .rateLimitExceeded:
            return "authentication"
        case .resourceNotFound, .resourceExists, .resourceBusy, .insufficientStorage:
            return "resource"
        case .samGovError:
            return "samgov"
        case .documentError:
            return "document"
        case .featureFlagError:
            return "featureflag"
        case .persistenceError:
            return "persistence"
        case .fileSystemError, .memoryError, .configurationError, .serviceUnavailable:
            return "system"
        case .userCancelled, .invalidInput, .notSupported:
            return "user"
        case .unknownError:
            return "unknown"
        }
    }

    /// Severity level for logging and analytics
    var severity: ErrorSeverity {
        switch self {
        case .userCancelled:
            return .info
        case .invalidInput, .notSupported, .resourceNotFound:
            return .warning
        case .networkUnavailable, .requestTimeout, .rateLimitExceeded, .insufficientStorage:
            return .recoverable
        case .invalidAPIKey, .authenticationFailed, .authorizationFailed, .invalidRequest, .validationError:
            return .error
        case .dataCorruption, .memoryError, .serviceUnavailable, .configurationError:
            return .critical
        default:
            return .error
        }
    }

    /// Whether this error should be reported to analytics
    var shouldReport: Bool {
        switch severity {
        case .info:
            return false
        case .warning, .recoverable, .error, .critical:
            return true
        }
    }

    /// User-facing error code for support purposes
    var code: String {
        let categoryPrefix = category.prefix(3).uppercased()
        let typeHash = String(String(describing: self).hash, radix: 16).prefix(4).uppercased()
        return "\(categoryPrefix)-\(typeHash)"
    }
}

/// Error severity levels
public enum ErrorSeverity: String, CaseIterable, Sendable {
    case info
    case warning
    case recoverable
    case error
    case critical
}

// MARK: - Error Logging Integration

public extension AIKOError {

    /// Create structured log entry for this error
    func logEntry() -> [String: Any] {
        return [
            "error_code": code,
            "category": category,
            "severity": severity.rawValue,
            "message": localizedDescription,
            "failure_reason": failureReason ?? "",
            "recovery_suggestion": recoverySuggestion ?? "",
            "should_report": shouldReport,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "underlying_error": (self.underlyingError?.localizedDescription ?? "")
        ]
    }

    /// Get the underlying error if available
    private var underlyingError: Error? {
        switch self {
        case .networkUnavailable(let underlying),
             .requestTimeout(let underlying),
             .invalidRequest(_, let underlying),
             .invalidResponse(_, let underlying),
             .networkError(_, let underlying),
             .encodingError(_, let underlying),
             .decodingError(_, let underlying),
             .dataCorruption(_, let underlying),
             .authenticationFailed(_, let underlying),
             .samGovError(_, let underlying),
             .documentError(_, let underlying),
             .featureFlagError(_, let underlying),
             .persistenceError(_, let underlying),
             .fileSystemError(_, _, let underlying),
             .unknownError(_, let underlying):
            return underlying
        default:
            return nil
        }
    }
}
