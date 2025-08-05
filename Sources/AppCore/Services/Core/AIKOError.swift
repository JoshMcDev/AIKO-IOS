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
            NSLocalizedString("network.unavailable",
                              comment: "Network connection is not available")
        case .requestTimeout:
            NSLocalizedString("network.timeout",
                              comment: "Request timed out")
        case let .invalidRequest(message, _):
            NSLocalizedString("network.invalid_request",
                              comment: "Invalid request: \(message)")
        case let .invalidResponse(message, _):
            NSLocalizedString("network.invalid_response",
                              comment: "Invalid response: \(message)")
        case let .httpError(statusCode, message, _):
            NSLocalizedString("network.http_error",
                              comment: "HTTP \(statusCode): \(message)")
        case let .networkError(message, _):
            NSLocalizedString("network.general_error",
                              comment: "Network error: \(message)")
        // Data Processing
        case let .encodingError(message, _):
            NSLocalizedString("data.encoding_error",
                              comment: "Encoding failed: \(message)")
        case let .decodingError(message, _):
            NSLocalizedString("data.decoding_error",
                              comment: "Decoding failed: \(message)")
        case let .validationError(message, field):
            if let field {
                NSLocalizedString("data.validation_field_error",
                                  comment: "Validation error in \(field): \(message)")
            } else {
                NSLocalizedString("data.validation_error",
                                  comment: "Validation error: \(message)")
            }
        case let .dataCorruption(message, _):
            NSLocalizedString("data.corruption",
                              comment: "Data corruption: \(message)")
        // Authentication & Authorization
        case let .invalidAPIKey(service):
            if let service {
                NSLocalizedString("auth.invalid_api_key_service",
                                  comment: "Invalid API key for \(service)")
            } else {
                NSLocalizedString("auth.invalid_api_key",
                                  comment: "Invalid or missing API key")
            }
        case let .authenticationFailed(message, _):
            NSLocalizedString("auth.authentication_failed",
                              comment: "Authentication failed: \(message)")
        case let .authorizationFailed(message, permission):
            if let permission {
                NSLocalizedString("auth.authorization_failed_permission",
                                  comment: "Authorization failed - requires \(permission): \(message)")
            } else {
                NSLocalizedString("auth.authorization_failed",
                                  comment: "Authorization failed: \(message)")
            }
        case let .rateLimitExceeded(service, retryAfter):
            if let service, let retryAfter {
                NSLocalizedString("auth.rate_limit_service_retry",
                                  comment: "Rate limit exceeded for \(service). Retry after \(Int(retryAfter)) seconds")
            } else if let service {
                NSLocalizedString("auth.rate_limit_service",
                                  comment: "Rate limit exceeded for \(service)")
            } else {
                NSLocalizedString("auth.rate_limit",
                                  comment: "Rate limit exceeded")
            }
        // Resources
        case let .resourceNotFound(message, type):
            if let type {
                NSLocalizedString("resource.not_found_type",
                                  comment: "\(type) not found: \(message)")
            } else {
                NSLocalizedString("resource.not_found",
                                  comment: "Resource not found: \(message)")
            }
        case let .resourceExists(message, type):
            if let type {
                NSLocalizedString("resource.exists_type",
                                  comment: "\(type) already exists: \(message)")
            } else {
                NSLocalizedString("resource.exists",
                                  comment: "Resource already exists: \(message)")
            }
        case let .resourceBusy(message, type):
            if let type {
                NSLocalizedString("resource.busy_type",
                                  comment: "\(type) is busy: \(message)")
            } else {
                NSLocalizedString("resource.busy",
                                  comment: "Resource is busy: \(message)")
            }
        case let .insufficientStorage(required, available):
            if let required, let available {
                NSLocalizedString("resource.insufficient_storage_details",
                                  comment: "Insufficient storage: need \(ByteCountFormatter.string(fromByteCount: Int64(required), countStyle: .file)), have \(ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .file))")
            } else {
                NSLocalizedString("resource.insufficient_storage",
                                  comment: "Insufficient storage space")
            }
        // Service-Specific
        case let .samGovError(type, _):
            type.localizedDescription
        case let .documentError(type, _):
            type.localizedDescription
        case let .featureFlagError(type, _):
            type.localizedDescription
        case let .persistenceError(message, _):
            NSLocalizedString("persistence.error",
                              comment: "Persistence error: \(message)")
        // System
        case let .fileSystemError(message, path, _):
            if let path {
                NSLocalizedString("system.filesystem_path_error",
                                  comment: "File system error at \(path): \(message)")
            } else {
                NSLocalizedString("system.filesystem_error",
                                  comment: "File system error: \(message)")
            }
        case let .memoryError(message):
            NSLocalizedString("system.memory_error",
                              comment: "Memory error: \(message)")
        case let .configurationError(message, key):
            if let key {
                NSLocalizedString("system.config_key_error",
                                  comment: "Configuration error for \(key): \(message)")
            } else {
                NSLocalizedString("system.config_error",
                                  comment: "Configuration error: \(message)")
            }
        case let .serviceUnavailable(message, service):
            if let service {
                NSLocalizedString("system.service_unavailable_named",
                                  comment: "\(service) is unavailable: \(message)")
            } else {
                NSLocalizedString("system.service_unavailable",
                                  comment: "Service unavailable: \(message)")
            }
        // User
        case .userCancelled:
            NSLocalizedString("user.cancelled",
                              comment: "Operation cancelled by user")
        case let .invalidInput(message, field):
            if let field {
                NSLocalizedString("user.invalid_input_field",
                                  comment: "Invalid input for \(field): \(message)")
            } else {
                NSLocalizedString("user.invalid_input",
                                  comment: "Invalid input: \(message)")
            }
        case let .notSupported(message, feature):
            if let feature {
                NSLocalizedString("user.not_supported_feature",
                                  comment: "\(feature) is not supported: \(message)")
            } else {
                NSLocalizedString("user.not_supported",
                                  comment: "Not supported: \(message)")
            }
        // Unknown
        case let .unknownError(message, _):
            NSLocalizedString("unknown.error",
                              comment: "Unknown error: \(message)")
        }
    }

    public var failureReason: String? {
        switch self {
        case let .networkUnavailable(underlying),
             let .requestTimeout(underlying),
             let .invalidRequest(_, underlying),
             let .invalidResponse(_, underlying),
             let .networkError(_, underlying),
             let .encodingError(_, underlying),
             let .decodingError(_, underlying),
             let .dataCorruption(_, underlying),
             let .authenticationFailed(_, underlying),
             let .samGovError(_, underlying),
             let .documentError(_, underlying),
             let .featureFlagError(_, underlying),
             let .persistenceError(_, underlying),
             let .fileSystemError(_, _, underlying),
             let .unknownError(_, underlying):
            underlying?.localizedDescription

        case let .httpError(_, _, responseData):
            responseData

        default:
            nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            NSLocalizedString("recovery.check_connection",
                              comment: "Check your internet connection and try again")
        case .requestTimeout:
            NSLocalizedString("recovery.retry_later",
                              comment: "Please try again in a few moments")
        case .invalidAPIKey:
            NSLocalizedString("recovery.check_api_key",
                              comment: "Please check your API key configuration")
        case let .rateLimitExceeded(_, retryAfter):
            if let retryAfter {
                NSLocalizedString("recovery.retry_after_time",
                                  comment: "Please wait \(Int(retryAfter)) seconds before trying again")
            } else {
                NSLocalizedString("recovery.retry_later",
                                  comment: "Please try again later")
            }
        case .insufficientStorage:
            NSLocalizedString("recovery.free_space",
                              comment: "Please free up some storage space and try again")
        case .userCancelled:
            NSLocalizedString("recovery.restart_operation",
                              comment: "You can restart the operation if needed")
        default:
            NSLocalizedString("recovery.try_again",
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
            NSLocalizedString("samgov.invalid_api_key",
                              comment: "Invalid SAM.gov API key")
        case .entityNotFound:
            NSLocalizedString("samgov.entity_not_found",
                              comment: "Entity not found in SAM.gov database")
        case let .networkError(message):
            NSLocalizedString("samgov.network_error",
                              comment: "SAM.gov network error: \(message)")
        case .invalidResponse:
            NSLocalizedString("samgov.invalid_response",
                              comment: "Invalid response from SAM.gov API")
        case .rateLimitExceeded:
            NSLocalizedString("samgov.rate_limit",
                              comment: "SAM.gov API rate limit exceeded")
        case .apiKeyRequired:
            NSLocalizedString("samgov.api_key_required",
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
        case let .invalidFormat(format):
            NSLocalizedString("document.invalid_format",
                              comment: "Invalid document format: \(format)")
        case let .fileTooLarge(size):
            NSLocalizedString("document.file_too_large",
                              comment: "File too large: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
        case let .processingFailed(reason):
            NSLocalizedString("document.processing_failed",
                              comment: "Document processing failed: \(reason)")
        case .permissionDenied:
            NSLocalizedString("document.permission_denied",
                              comment: "Permission denied to access document")
        case let .fileNotFound(path):
            NSLocalizedString("document.file_not_found",
                              comment: "Document not found: \(path)")
        case let .unsupportedType(type):
            NSLocalizedString("document.unsupported_type",
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
        case let .featureNotFound(feature):
            NSLocalizedString("featureflag.not_found",
                              comment: "Feature flag not found: \(feature)")
        case let .invalidConfiguration(config):
            NSLocalizedString("featureflag.invalid_config",
                              comment: "Invalid feature flag configuration: \(config)")
        case let .evaluationFailed(reason):
            NSLocalizedString("featureflag.evaluation_failed",
                              comment: "Feature flag evaluation failed: \(reason)")
        case let .persistenceError(reason):
            NSLocalizedString("featureflag.persistence_error",
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
            .networkUnavailable(underlying: urlError)
        case .timedOut:
            .requestTimeout(underlying: urlError)
        case .badURL:
            .invalidRequest("Invalid URL", underlying: urlError)
        case .cannotFindHost:
            .networkError("Cannot find host", underlying: urlError)
        case .cannotConnectToHost:
            .networkError("Cannot connect to host", underlying: urlError)
        case .userCancelledAuthentication:
            .userCancelled
        default:
            .networkError(urlError.localizedDescription, underlying: urlError)
        }
    }

    /// Convert from DecodingError
    static func from(_ decodingError: DecodingError) -> AIKOError {
        switch decodingError {
        case let .keyNotFound(key, context):
            return .decodingError("Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: decodingError)
        case let .typeMismatch(type, context):
            return .decodingError("Type mismatch for '\(type)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: decodingError)
        case let .valueNotFound(type, context):
            return .decodingError("Value not found for '\(type)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: decodingError)
        case let .dataCorrupted(context):
            return .dataCorruption("Data corrupted at \(context.codingPath.map(\.stringValue).joined(separator: "."))", underlying: decodingError)
        @unknown default:
            return .decodingError("Unknown decoding error", underlying: decodingError)
        }
    }

    /// Convert from EncodingError
    static func from(_ encodingError: EncodingError) -> AIKOError {
        switch encodingError {
        case let .invalidValue(value, context):
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
            "network"
        case .encodingError, .decodingError, .validationError, .dataCorruption:
            "data"
        case .invalidAPIKey, .authenticationFailed, .authorizationFailed, .rateLimitExceeded:
            "authentication"
        case .resourceNotFound, .resourceExists, .resourceBusy, .insufficientStorage:
            "resource"
        case .samGovError:
            "samgov"
        case .documentError:
            "document"
        case .featureFlagError:
            "featureflag"
        case .persistenceError:
            "persistence"
        case .fileSystemError, .memoryError, .configurationError, .serviceUnavailable:
            "system"
        case .userCancelled, .invalidInput, .notSupported:
            "user"
        case .unknownError:
            "unknown"
        }
    }

    /// Severity level for logging and analytics
    var severity: ErrorSeverity {
        switch self {
        case .userCancelled:
            .info
        case .invalidInput, .notSupported, .resourceNotFound:
            .warning
        case .networkUnavailable, .requestTimeout, .rateLimitExceeded, .insufficientStorage:
            .recoverable
        case .invalidAPIKey, .authenticationFailed, .authorizationFailed, .invalidRequest, .validationError:
            .error
        case .dataCorruption, .memoryError, .serviceUnavailable, .configurationError:
            .critical
        default:
            .error
        }
    }

    /// Whether this error should be reported to analytics
    var shouldReport: Bool {
        switch severity {
        case .info:
            false
        case .warning, .recoverable, .error, .critical:
            true
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
        [
            "error_code": code,
            "category": category,
            "severity": severity.rawValue,
            "message": localizedDescription,
            "failure_reason": failureReason ?? "",
            "recovery_suggestion": recoverySuggestion ?? "",
            "should_report": shouldReport,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "underlying_error": (underlyingError?.localizedDescription ?? ""),
        ]
    }

    /// Get the underlying error if available
    private var underlyingError: Error? {
        switch self {
        case let .networkUnavailable(underlying),
             let .requestTimeout(underlying),
             let .invalidRequest(_, underlying),
             let .invalidResponse(_, underlying),
             let .networkError(_, underlying),
             let .encodingError(_, underlying),
             let .decodingError(_, underlying),
             let .dataCorruption(_, underlying),
             let .authenticationFailed(_, underlying),
             let .samGovError(_, underlying),
             let .documentError(_, underlying),
             let .featureFlagError(_, underlying),
             let .persistenceError(_, underlying),
             let .fileSystemError(_, _, underlying),
             let .unknownError(_, underlying):
            underlying
        default:
            nil
        }
    }
}
