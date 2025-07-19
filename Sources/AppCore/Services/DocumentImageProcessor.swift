import ComposableArchitecture
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

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

/// Processing modes for document enhancement
public enum ProcessingMode: String, CaseIterable, Equatable, Sendable {
    case basic = "basic"
    case enhanced = "enhanced"
    
    public var displayName: String {
        switch self {
        case .basic: return "Basic Enhancement"
        case .enhanced: return "Advanced Enhancement"
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
    case preprocessing = "preprocessing"
    case enhancement = "enhancement"
    case denoising = "denoising"
    case sharpening = "sharpening"
    case optimization = "optimization"
    case qualityAnalysis = "quality_analysis"
    
    public var displayName: String {
        switch self {
        case .preprocessing: return "Preprocessing"
        case .enhancement: return "Enhancing"
        case .denoising: return "Removing Noise"
        case .sharpening: return "Sharpening"
        case .optimization: return "Optimizing"
        case .qualityAnalysis: return "Analyzing Quality"
        }
    }
}

/// Quality targets for processing
public enum QualityTarget: String, CaseIterable, Equatable, Sendable {
    case speed = "speed"
    case balanced = "balanced"
    case quality = "quality"
    
    public var displayName: String {
        switch self {
        case .speed: return "Fast"
        case .balanced: return "Balanced"
        case .quality: return "High Quality"
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
    public let recommendedForOCR: Bool
    
    public init(
        overallConfidence: Double,
        sharpnessScore: Double,
        contrastScore: Double,
        noiseLevel: Double,
        textClarity: Double,
        recommendedForOCR: Bool
    ) {
        self.overallConfidence = overallConfidence
        self.sharpnessScore = sharpnessScore
        self.contrastScore = contrastScore
        self.noiseLevel = noiseLevel
        self.textClarity = textClarity
        self.recommendedForOCR = recommendedForOCR
    }
}

// MARK: - Dependency Registration

extension DocumentImageProcessor: DependencyKey {
    public static var liveValue: Self = Self()
    
    public static var testValue: Self = Self(
        processImage: { data, mode, options in
            // Simulate processing delay
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Simulate progress updates
            options.progressCallback?(ProcessingProgress(
                currentStep: .enhancement,
                stepProgress: 0.5,
                overallProgress: 0.5
            ))
            
            return ProcessingResult(
                processedImageData: data,
                qualityMetrics: QualityMetrics(
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

extension DependencyValues {
    public var documentImageProcessor: DocumentImageProcessor {
        get { self[DocumentImageProcessor.self] }
        set { self[DocumentImageProcessor.self] = newValue }
    }
}

// MARK: - Processing Errors

public enum ProcessingError: LocalizedError, Equatable {
    case invalidImageData
    case processingFailed(String)
    case unsupportedMode
    case cancelled
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data provided"
        case .processingFailed(let reason):
            return "Image processing failed: \(reason)"
        case .unsupportedMode:
            return "Processing mode not supported"
        case .cancelled:
            return "Processing was cancelled"
        case .timeout:
            return "Processing timed out"
        }
    }
}