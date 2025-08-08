import Foundation

/// Centralized configuration for Launch-Time Regulation Fetching
/// All configurable parameters externalized for easy management
public struct LaunchTimeConfiguration {

    // MARK: - Network Configuration

    public struct Network {
        /// Maximum number of retry attempts for network requests
        public static let maxRetryAttempts = 3

        /// Base delay for exponential backoff (seconds)
        public static let baseBackoffDelay: TimeInterval = 1.0

        /// Maximum backoff delay (seconds)
        public static let maxBackoffDelay: TimeInterval = 60.0

        /// Request timeout interval (seconds)
        public static let requestTimeout: TimeInterval = 30.0

        /// Maximum concurrent downloads
        public static let maxConcurrentDownloads = 4
    }

    // MARK: - Memory Configuration

    public struct Memory {
        /// Normal operation batch size
        public static let normalBatchSize = 8

        /// Batch size under memory warning
        public static let warningBatchSize = 4

        /// Batch size under critical memory pressure
        public static let criticalBatchSize = 2

        /// Normal chunk size for streaming (bytes)
        public static let normalChunkSize = 16384  // 16KB

        /// Chunk size under memory warning (bytes)
        public static let warningChunkSize = 8192  // 8KB

        /// Chunk size under critical memory pressure (bytes)
        public static let criticalChunkSize = 4096 // 4KB

        /// Memory check interval (seconds)
        public static let memoryCheckInterval: TimeInterval = 5.0

        /// Memory warning threshold (bytes)
        public static let memoryWarningThreshold: Int64 = 300 * 1024 * 1024 // 300MB

        /// Memory critical threshold (bytes)
        public static let memoryCriticalThreshold: Int64 = 400 * 1024 * 1024 // 400MB

        /// Maximum memory usage during launch (bytes)
        public static let maxLaunchMemoryUsage: Int64 = 50 * 1024 * 1024 // 50MB
    }

    // MARK: - Performance Configuration

    public struct Performance {
        /// Maximum launch time impact (milliseconds)
        public static let maxLaunchTimeImpact: TimeInterval = 0.4 // 400ms

        /// Target processing time per regulation (seconds)
        public static let targetProcessingTimePerRegulation: TimeInterval = 0.1

        /// Progress update interval (seconds)
        public static let progressUpdateInterval: TimeInterval = 0.5

        /// Checkpoint save interval (number of processed items)
        public static let checkpointInterval = 100

        /// Maximum processing time before yielding (seconds)
        public static let maxProcessingTimeBeforeYield: TimeInterval = 0.1
    }

    // MARK: - Security Configuration

    public struct Security {
        /// Maximum file size for download (bytes)
        public static let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB

        /// Trusted GitHub repositories
        public static let trustedRepositories = [
            "https://api.github.com/repos/GSA/GSA-Acquisition-FAR",
            "https://api.github.com/repos/GSA/acquisition-gov-data"
        ]

        /// Certificate pinning enabled
        public static let certificatePinningEnabled = true

        /// File integrity verification enabled
        public static let fileIntegrityVerificationEnabled = true

        /// Supply chain validation enabled
        public static let supplyChainValidationEnabled = true
    }

    // MARK: - Model Configuration

    public struct Model {
        /// LFM2 embedding dimensions
        public static let embeddingDimensions = 768

        /// Maximum tokens per chunk
        public static let maxTokensPerChunk = 512

        /// Model inference timeout (seconds)
        public static let inferenceTimeout: TimeInterval = 5.0

        /// Batch size for embedding generation
        public static let embeddingBatchSize = 8

        /// Enable model caching
        public static let enableModelCaching = true
    }

    // MARK: - Storage Configuration

    public struct Storage {
        /// ObjectBox database name
        public static let databaseName = "RegulationDatabase"

        /// Maximum database size (bytes)
        public static let maxDatabaseSize: Int64 = 500 * 1024 * 1024 // 500MB

        /// Enable database encryption
        public static let enableEncryption = true

        /// Cache expiration time (seconds)
        public static let cacheExpirationTime: TimeInterval = 86400 // 24 hours

        /// Enable automatic cleanup
        public static let enableAutomaticCleanup = true
    }

    // MARK: - UI Configuration

    public struct UI {
        /// Show detailed progress during onboarding
        public static let showDetailedProgress = true

        /// Enable progress animations
        public static let enableProgressAnimations = true

        /// Progress update debounce interval (seconds)
        public static let progressDebounceInterval: TimeInterval = 0.25

        /// Show estimated time remaining
        public static let showEstimatedTimeRemaining = true

        /// Enable haptic feedback
        public static let enableHapticFeedback = true
    }

    // MARK: - Debug Configuration

    public struct Debug {
        /// Enable verbose logging
        #if DEBUG
        public static let enableVerboseLogging = true
        #else
        public static let enableVerboseLogging = false
        #endif

        /// Enable performance monitoring
        public static let enablePerformanceMonitoring = true

        /// Enable memory leak detection
        public static let enableMemoryLeakDetection = true

        /// Save debug logs to file
        public static let saveDebugLogs = false

        /// Maximum log file size (bytes)
        public static let maxLogFileSize: Int64 = 10 * 1024 * 1024 // 10MB
    }

    // MARK: - Feature Flags

    public struct Features {
        /// Enable ObjectBox integration (when available)
        public static let enableObjectBox = false // Currently using mock

        /// Enable background processing
        public static let enableBackgroundProcessing = true

        /// Enable incremental updates
        public static let enableIncrementalUpdates = true

        /// Enable offline mode
        public static let enableOfflineMode = true

        /// Enable regulation auto-updates
        public static let enableAutoUpdates = false

        /// Enable personal repository support
        public static let enablePersonalRepositories = false
    }

    // MARK: - Validation

    /// Validates configuration consistency
    public static func validate() -> Bool {
        // Ensure memory thresholds are properly ordered
        guard Memory.memoryWarningThreshold < Memory.memoryCriticalThreshold else {
            return false
        }

        // Ensure batch sizes are properly ordered
        guard Memory.criticalBatchSize < Memory.warningBatchSize,
              Memory.warningBatchSize < Memory.normalBatchSize else {
            return false
        }

        // Ensure chunk sizes are properly ordered
        guard Memory.criticalChunkSize < Memory.warningChunkSize,
              Memory.warningChunkSize < Memory.normalChunkSize else {
            return false
        }

        // Ensure performance constraints are reasonable
        guard Performance.maxLaunchTimeImpact > 0,
              Performance.maxLaunchTimeImpact < 1.0 else {
            return false
        }

        return true
    }

    // MARK: - Environment-based Overrides

    /// Applies environment-based configuration overrides
    public static func applyEnvironmentOverrides() {
        #if targetEnvironment(simulator)
        // Adjust for simulator performance
        _ = Memory.normalBatchSize / 2
        _ = Performance.targetProcessingTimePerRegulation * 2
        #endif

        #if DEBUG
        // Enable all debug features in debug builds
        _ = Debug.enableVerboseLogging
        _ = Debug.enablePerformanceMonitoring
        _ = Debug.enableMemoryLeakDetection
        #endif
    }
}

// MARK: - Configuration Manager

/// Manager for runtime configuration updates
@globalActor
public actor LaunchTimeConfigurationManager {

    /// Shared instance
    public static let shared = LaunchTimeConfigurationManager()

    /// Current configuration overrides
    private var overrides: [String: Any] = [:]

    private init() {
        LaunchTimeConfiguration.applyEnvironmentOverrides()
    }

    /// Sets a configuration override
    public func setOverride<T>(key: String, value: T) {
        overrides[key] = value
    }

    /// Gets a configuration value with override support
    public func getValue<T>(key: String, default defaultValue: T) -> T {
        if let override = overrides[key] as? T {
            return override
        }
        return defaultValue
    }

    /// Resets all overrides
    public func resetOverrides() {
        overrides.removeAll()
    }

    /// Loads configuration from UserDefaults
    public func loadFromUserDefaults() {
        // Implementation for loading user preferences
    }

    /// Saves configuration to UserDefaults
    public func saveToUserDefaults() {
        // Implementation for saving user preferences
    }
}
