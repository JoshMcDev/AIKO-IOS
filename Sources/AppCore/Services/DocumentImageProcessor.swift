import ComposableArchitecture
@preconcurrency import CoreImage
@preconcurrency import CoreImage.CIFilterBuiltins
import Foundation

// MARK: - Document Image Processor Protocol

/// Advanced image processing service for document enhancement
@DependencyClient
public struct DocumentImageProcessor: Sendable {
    /// Process image with specified mode
    public var processImage: @Sendable (Data, ProcessingMode, ProcessingOptions) async throws -> ProcessingResult

    /// Estimate processing time for given image and mode
    public var estimateProcessingTime: @Sendable (Data, ProcessingMode) async throws -> TimeInterval

    /// Check if processing mode is available
    public var isProcessingModeAvailable: @Sendable (ProcessingMode) -> Bool = { _ in false }
}

// MARK: - Processing Types

extension DocumentImageProcessor {
    /// Processing modes for document enhancement
    public enum ProcessingMode: String, CaseIterable, Equatable, Sendable {
        case basic
        case enhanced
        case documentScanner = "document_scanner"

        public var displayName: String {
            switch self {
            case .basic: "Basic Enhancement"
            case .enhanced: "Advanced Enhancement"
            case .documentScanner: "Document Scanner"
            }
        }
    }

    /// Processing options and configuration
    public struct ProcessingOptions: Sendable {
        public let progressCallback: (@Sendable (ProcessingProgress) -> Void)?
        public let qualityTarget: QualityTarget
        public let preserveColors: Bool
        public let optimizeForOCR: Bool

        public init(
            progressCallback: (@Sendable (ProcessingProgress) -> Void)? = nil,
            qualityTarget: QualityTarget = .balanced,
            preserveColors: Bool = true,
            optimizeForOCR: Bool = true
        ) {
            self.progressCallback = progressCallback
            self.qualityTarget = qualityTarget
            self.preserveColors = preserveColors
            self.optimizeForOCR = optimizeForOCR
        }
    }

    /// Quality targets for processing
    public enum QualityTarget: String, CaseIterable, Equatable, Sendable {
        case speed
        case balanced
        case quality

        public var displayName: String {
            switch self {
            case .speed: "Fast"
            case .balanced: "Balanced"
            case .quality: "High Quality"
            }
        }
    }

    /// Processing result with quality metrics
    public struct ProcessingResult: Equatable, Sendable {
        public let processedImageData: Data
        public let qualityMetrics: QualityMetrics
        public let processingTime: TimeInterval
        public let appliedFilters: [String]

        public init(
            processedImageData: Data,
            qualityMetrics: QualityMetrics,
            processingTime: TimeInterval,
            appliedFilters: [String]
        ) {
            self.processedImageData = processedImageData
            self.qualityMetrics = qualityMetrics
            self.processingTime = processingTime
            self.appliedFilters = appliedFilters
        }
    }

    /// Quality assessment metrics
    public struct QualityMetrics: Equatable, Sendable {
        public let overallConfidence: Double // 0.0 to 1.0
        public let sharpnessScore: Double // 0.0 to 1.0
        public let contrastScore: Double // 0.0 to 1.0
        public let noiseLevel: Double // 0.0 to 1.0
        public let textClarity: Double // 0.0 to 1.0
        public let edgeDetectionConfidence: Double? // 0.0 to 1.0, nil if not performed
        public let perspectiveCorrectionAccuracy: Double? // 0.0 to 1.0, nil if not performed
        public let recommendedForOCR: Bool

        public init(
            overallConfidence: Double,
            sharpnessScore: Double,
            contrastScore: Double,
            noiseLevel: Double,
            textClarity: Double,
            edgeDetectionConfidence: Double? = nil,
            perspectiveCorrectionAccuracy: Double? = nil,
            recommendedForOCR: Bool
        ) {
            self.overallConfidence = overallConfidence
            self.sharpnessScore = sharpnessScore
            self.contrastScore = contrastScore
            self.noiseLevel = noiseLevel
            self.textClarity = textClarity
            self.edgeDetectionConfidence = edgeDetectionConfidence
            self.perspectiveCorrectionAccuracy = perspectiveCorrectionAccuracy
            self.recommendedForOCR = recommendedForOCR
        }
    }
}

// MARK: - ProcessingOptions Equatable Conformance

extension DocumentImageProcessor.ProcessingOptions: Equatable {
    public static func == (lhs: DocumentImageProcessor.ProcessingOptions, rhs: DocumentImageProcessor.ProcessingOptions) -> Bool {
        // Compare all fields except progressCallback (functions can't be compared)
        lhs.qualityTarget == rhs.qualityTarget &&
            lhs.preserveColors == rhs.preserveColors &&
            lhs.optimizeForOCR == rhs.optimizeForOCR
    }
}

/// Processing progress information
public struct ProcessingProgress: Equatable, Sendable {
    public let currentStep: ProcessingStep
    public let stepProgress: Double // 0.0 to 1.0
    public let overallProgress: Double // 0.0 to 1.0
    public let estimatedTimeRemaining: TimeInterval?

    public init(
        currentStep: ProcessingStep,
        stepProgress: Double,
        overallProgress: Double,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.currentStep = currentStep
        self.stepProgress = stepProgress
        self.overallProgress = overallProgress
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

/// Processing steps for progress tracking
public enum ProcessingStep: String, CaseIterable, Equatable, Sendable {
    case preprocessing
    case edgeDetection = "edge_detection"
    case perspectiveCorrection = "perspective_correction"
    case enhancement
    case denoising
    case sharpening
    case optimization
    case qualityAnalysis = "quality_analysis"

    public var displayName: String {
        switch self {
        case .preprocessing: "Preprocessing"
        case .edgeDetection: "Detecting Edges"
        case .perspectiveCorrection: "Correcting Perspective"
        case .enhancement: "Enhancing"
        case .denoising: "Removing Noise"
        case .sharpening: "Sharpening"
        case .optimization: "Optimizing"
        case .qualityAnalysis: "Analyzing Quality"
        }
    }
}

// MARK: - Dependency Registration

extension DocumentImageProcessor: DependencyKey {
    public static let liveValue: Self = .init()

    public static let testValue: Self = .init(
        processImage: { data, _, options in
            // Simulate processing delay
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // Simulate progress updates
            options.progressCallback?(ProcessingProgress(
                currentStep: .enhancement,
                stepProgress: 0.5,
                overallProgress: 0.5
            ))

            return DocumentImageProcessor.ProcessingResult(
                processedImageData: data,
                qualityMetrics: DocumentImageProcessor.QualityMetrics(
                    overallConfidence: 0.85,
                    sharpnessScore: 0.8,
                    contrastScore: 0.9,
                    noiseLevel: 0.2,
                    textClarity: 0.85,
                    recommendedForOCR: true
                ),
                processingTime: 0.1,
                appliedFilters: ["contrast", "sharpness"]
            )
        },
        estimateProcessingTime: { data, mode in
            // Simple estimation based on data size and mode
            let baseTime: TimeInterval = mode == .enhanced ? 2.0 : 0.5
            let sizeMultiplier = Double(data.count) / 1_000_000.0 // MB
            return baseTime * max(1.0, sizeMultiplier)
        },
        isProcessingModeAvailable: { _ in true }
    )
}

public extension DependencyValues {
    var documentImageProcessor: DocumentImageProcessor {
        get { self[DocumentImageProcessor.self] }
        set { self[DocumentImageProcessor.self] = newValue }
    }
}

// MARK: - Processing Errors

public enum ProcessingError: LocalizedError, Equatable, Sendable {
    case invalidImageData
    case processingFailed(String)
    case unsupportedMode
    case cancelled
    case timeout

    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            "Invalid image data provided"
        case let .processingFailed(reason):
            "Image processing failed: \(reason)"
        case .unsupportedMode:
            "Processing mode not supported"
        case .cancelled:
            "Processing was cancelled"
        case .timeout:
            "Processing timed out"
        }
    }
}
