import Foundation
import os.log

/// Build-time configuration for AIKO application
/// Controls feature flags, model inclusion, and development vs production settings
public enum BuildConfiguration {

    // MARK: - Model Configuration

    /// LFM2 model inclusion strategy
    public enum LFM2ModelStrategy {
        case disabled           // No model files included (fastest builds, Xcode indexing friendly)
        case developmentMock    // Mock-only mode for development
        case productionHybrid   // Include model files for production builds
        case fullProduction     // All model variants included
    }

    /// Current LFM2 model strategy based on build configuration
    public static var lfm2ModelStrategy: LFM2ModelStrategy {
        #if DEBUG
            // Development builds: Check environment variable for override
            if let strategyOverride = ProcessInfo.processInfo.environment["AIKO_LFM2_STRATEGY"] {
                switch strategyOverride.lowercased() {
                case "disabled":
                    return .disabled
                case "mock":
                    return .developmentMock
                case "hybrid":
                    return .productionHybrid
                case "full":
                    return .fullProduction
                default:
                    break
                }
            }

            // Default for debug builds: mock only to prevent indexing issues
            return .developmentMock
        #else
            // Release builds: hybrid mode (Core ML with mock fallback)
            return .productionHybrid
        #endif
    }

    // MARK: - Build Environment Detection

    /// Detect if running in Xcode development environment
    public static var isXcodeDevelopment: Bool {
        // Check if we're running in Xcode (vs command line builds)
        return ProcessInfo.processInfo.environment["XCODE_VERSION_ACTUAL"] != nil
    }

    /// Detect if this is a CI/CD build
    public static var isContinuousIntegration: Bool {
        return ProcessInfo.processInfo.environment["CI"] == "true" ||
               ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true" ||
               ProcessInfo.processInfo.environment["XCODE_CLOUD"] == "1"
    }

    /// Check if large model files should be excluded from build
    public static var shouldExcludeLargeModels: Bool {
        switch lfm2ModelStrategy {
        case .disabled, .developmentMock:
            return true
        case .productionHybrid, .fullProduction:
            return false
        }
    }

    // MARK: - Performance Configuration

    /// Maximum model file size to include in development builds (in bytes)
    public static let maxDevelopmentModelSize: Int64 = 50 * 1024 * 1024 // 50MB

    /// LFM2-700M model estimated size
    public static let lfm2ModelSize: Int64 = 149 * 1024 * 1024 // 149MB

    /// Check if model size exceeds development limits
    public static func isModelTooLargeForDevelopment(_ modelSize: Int64) -> Bool {
        return isXcodeDevelopment && modelSize > maxDevelopmentModelSize
    }

    // MARK: - Logging Configuration

    /// Enable verbose logging for model loading
    public static var enableModelLoadingLogging: Bool {
        #if DEBUG
            return true
        #else
            return ProcessInfo.processInfo.environment["AIKO_VERBOSE_LOGGING"] == "true"
        #endif
    }

    // MARK: - Build Information

    /// Get build configuration summary
    public static var configurationSummary: String {
        let buildType = isXcodeDevelopment ? "Xcode Development" : (isContinuousIntegration ? "CI/CD" : "Command Line")
        let modelStrategy = lfm2ModelStrategy
        let excludeModels = shouldExcludeLargeModels ? "Yes" : "No"

        return """
        AIKO Build Configuration:
        - Build Environment: \(buildType)
        - LFM2 Strategy: \(modelStrategy)
        - Exclude Large Models: \(excludeModels)
        - Model Size Limit: \(maxDevelopmentModelSize / 1024 / 1024)MB
        - Verbose Logging: \(enableModelLoadingLogging)
        """
    }
}

// MARK: - Configuration Validation

extension BuildConfiguration {

    /// Validate current build configuration and log warnings if needed
    public static func validateConfiguration() {
        let logger = Logger(subsystem: "com.aiko.core", category: "BuildConfiguration")

        // Log configuration summary
        logger.info("📋 \(configurationSummary)")

        // Warn about large model files in development
        if isXcodeDevelopment && !shouldExcludeLargeModels {
            logger.warning("⚠️ Large model files included in Xcode build - may cause indexing issues")
            logger.info("💡 Set AIKO_LFM2_STRATEGY=mock to disable model files for development")
        }

        // Validate model strategy consistency
        if lfm2ModelStrategy == .fullProduction && isXcodeDevelopment {
            logger.warning("⚠️ Full production model strategy in development environment")
        }

        // Check for environment variable overrides
        if let override = ProcessInfo.processInfo.environment["AIKO_LFM2_STRATEGY"] {
            logger.info("🔧 LFM2 strategy overridden via environment: \(override)")
        }
    }
}

// MARK: - Environment Variable Guide

/*
 Environment Variables for LFM2 Model Configuration:

 AIKO_LFM2_STRATEGY:
 - "disabled"  : No model loading attempted
 - "mock"      : Mock embeddings only (default for DEBUG)
 - "hybrid"    : Load Core ML if available, fallback to mock (default for RELEASE)
 - "full"      : Include all model variants

 AIKO_VERBOSE_LOGGING:
 - "true"      : Enable detailed model loading logs
 - "false"     : Standard logging only

 Usage Examples:
 
 # Development with mock models only (fastest, Xcode-friendly)
 AIKO_LFM2_STRATEGY=mock xcodebuild -scheme AIKO build
 
 # Development with hybrid models (test real model loading)
 AIKO_LFM2_STRATEGY=hybrid xcodebuild -scheme AIKO build
 
 # CI/CD with verbose logging
 AIKO_VERBOSE_LOGGING=true xcodebuild -scheme AIKO test
*/
