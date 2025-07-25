@preconcurrency import CoreImage
@preconcurrency import CoreImage.CIFilterBuiltins
import Foundation

// MARK: - Document Image Processor Protocol

/// Advanced image processing service for document enhancement
public struct DocumentImageProcessor: Sendable {
    /// Process image with specified mode
    public var processImage: @Sendable (Data, ProcessingMode, ProcessingOptions) async throws -> ProcessingResult

    /// Estimate processing time for given image and mode
    public var estimateProcessingTime: @Sendable (Data, ProcessingMode) async throws -> TimeInterval

    /// Check if processing mode is available
    public var isProcessingModeAvailable: @Sendable (ProcessingMode) -> Bool = { _ in false }

    /// Extract text from document image using OCR
    public var extractText: @Sendable (Data, OCROptions) async throws -> OCRResult

    /// Extract structured data from document image
    public var extractStructuredData: @Sendable (Data, DocumentType, OCROptions) async throws -> StructuredOCRResult

    /// Check if OCR is available on the current platform
    public var isOCRAvailable: @Sendable () -> Bool = { false }

    // MARK: - Initializer

    public init(
        processImage: @escaping @Sendable (Data, ProcessingMode, ProcessingOptions) async throws -> ProcessingResult,
        estimateProcessingTime: @escaping @Sendable (Data, ProcessingMode) async throws -> TimeInterval,
        isProcessingModeAvailable: @escaping @Sendable (ProcessingMode) -> Bool = { _ in false },
        extractText: @escaping @Sendable (Data, OCROptions) async throws -> OCRResult,
        extractStructuredData: @escaping @Sendable (Data, DocumentType, OCROptions) async throws -> StructuredOCRResult,
        isOCRAvailable: @escaping @Sendable () -> Bool = { false }
    ) {
        self.processImage = processImage
        self.estimateProcessingTime = estimateProcessingTime
        self.isProcessingModeAvailable = isProcessingModeAvailable
        self.extractText = extractText
        self.extractStructuredData = extractStructuredData
        self.isOCRAvailable = isOCRAvailable
    }
}

// MARK: - Processing Types

public extension DocumentImageProcessor {
    /// Processing modes for document enhancement
    enum ProcessingMode: String, CaseIterable, Equatable, Sendable {
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
    struct ProcessingOptions: Sendable {
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
    enum QualityTarget: String, CaseIterable, Equatable, Sendable {
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
    struct ProcessingResult: Equatable, Sendable {
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
    struct QualityMetrics: Equatable, Sendable {
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

    // MARK: - OCR Types

    /// OCR processing options
    struct OCROptions: Equatable, Sendable {
        public let language: OCRLanguage
        public let recognitionLevel: RecognitionLevel
        public let progressCallback: (@Sendable (OCRProgress) -> Void)?
        public let automaticLanguageDetection: Bool
        public let minimumTextHeight: Float
        public let customWords: [String]
        public let revision: Int

        public init(
            language: OCRLanguage = .english,
            recognitionLevel: RecognitionLevel = .accurate,
            progressCallback: (@Sendable (OCRProgress) -> Void)? = nil,
            automaticLanguageDetection: Bool = true,
            minimumTextHeight: Float = 0.0,
            customWords: [String] = [],
            revision: Int = 3
        ) {
            self.language = language
            self.recognitionLevel = recognitionLevel
            self.progressCallback = progressCallback
            self.automaticLanguageDetection = automaticLanguageDetection
            self.minimumTextHeight = minimumTextHeight
            self.customWords = customWords
            self.revision = revision
        }

        public static func == (lhs: OCROptions, rhs: OCROptions) -> Bool {
            lhs.language == rhs.language &&
                lhs.recognitionLevel == rhs.recognitionLevel &&
                lhs.automaticLanguageDetection == rhs.automaticLanguageDetection &&
                lhs.minimumTextHeight == rhs.minimumTextHeight &&
                lhs.customWords == rhs.customWords &&
                lhs.revision == rhs.revision
        }
    }

    /// OCR language options
    enum OCRLanguage: String, CaseIterable, Equatable, Sendable {
        case english = "en-US"
        case spanish = "es-ES"
        case french = "fr-FR"
        case german = "de-DE"
        case italian = "it-IT"
        case portuguese = "pt-BR"
        case chinese = "zh-CN"
        case japanese = "ja-JP"
        case korean = "ko-KR"
        case automatic = "auto"

        public var displayName: String {
            switch self {
            case .english: "English"
            case .spanish: "Spanish"
            case .french: "French"
            case .german: "German"
            case .italian: "Italian"
            case .portuguese: "Portuguese"
            case .chinese: "Chinese"
            case .japanese: "Japanese"
            case .korean: "Korean"
            case .automatic: "Automatic Detection"
            }
        }
    }

    /// OCR recognition level
    enum RecognitionLevel: String, CaseIterable, Equatable, Sendable {
        case fast
        case accurate

        public var displayName: String {
            switch self {
            case .fast: "Fast"
            case .accurate: "Accurate"
            }
        }
    }

    /// Document types for structured OCR
    enum DocumentType: String, CaseIterable, Equatable, Sendable {
        case generic
        case invoice
        case receipt
        case businessCard = "business_card"
        case form
        case idDocument = "id_document"
        case contract

        public var displayName: String {
            switch self {
            case .generic: "Generic Document"
            case .invoice: "Invoice"
            case .receipt: "Receipt"
            case .businessCard: "Business Card"
            case .form: "Form"
            case .idDocument: "ID Document"
            case .contract: "Contract"
            }
        }
    }

    /// OCR result with extracted text and metadata
    struct OCRResult: Equatable, Sendable {
        public let extractedText: [ExtractedText]
        public let fullText: String
        public let confidence: Double
        public let detectedLanguages: [OCRLanguage]
        public let processingTime: TimeInterval
        public let imageSize: CGSize

        public init(
            extractedText: [ExtractedText],
            fullText: String,
            confidence: Double,
            detectedLanguages: [OCRLanguage],
            processingTime: TimeInterval,
            imageSize: CGSize
        ) {
            self.extractedText = extractedText
            self.fullText = fullText
            self.confidence = confidence
            self.detectedLanguages = detectedLanguages
            self.processingTime = processingTime
            self.imageSize = imageSize
        }
    }

    /// Individual extracted text element with positioning and confidence
    struct ExtractedText: Equatable, Sendable {
        public let text: String
        public let confidence: Double
        public let boundingBox: CGRect
        public let characterBoxes: [CGRect]
        public let detectedLanguage: OCRLanguage?

        public init(
            text: String,
            confidence: Double,
            boundingBox: CGRect,
            characterBoxes: [CGRect] = [],
            detectedLanguage: OCRLanguage? = nil
        ) {
            self.text = text
            self.confidence = confidence
            self.boundingBox = boundingBox
            self.characterBoxes = characterBoxes
            self.detectedLanguage = detectedLanguage
        }
    }

    /// Structured field value that is Sendable
    enum StructuredFieldValue: Equatable, Sendable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case array([String])
        case dictionary([String: String])

        public var stringValue: String? {
            if case let .string(value) = self { return value }
            return nil
        }

        public var numberValue: Double? {
            if case let .number(value) = self { return value }
            return nil
        }

        public var boolValue: Bool? {
            if case let .bool(value) = self { return value }
            return nil
        }

        public var arrayValue: [String]? {
            if case let .array(value) = self { return value }
            return nil
        }

        public var dictionaryValue: [String: String]? {
            if case let .dictionary(value) = self { return value }
            return nil
        }
    }

    /// Structured OCR result for specific document types
    struct StructuredOCRResult: Equatable, Sendable {
        public let documentType: DocumentType
        public let extractedFields: [String: StructuredFieldValue]
        public let ocrResult: OCRResult
        public let structureConfidence: Double

        public init(
            documentType: DocumentType,
            extractedFields: [String: StructuredFieldValue],
            ocrResult: OCRResult,
            structureConfidence: Double
        ) {
            self.documentType = documentType
            self.extractedFields = extractedFields
            self.ocrResult = ocrResult
            self.structureConfidence = structureConfidence
        }
    }
}

/// OCR progress information
public struct OCRProgress: Equatable, Sendable {
    public let currentStep: OCRStep
    public let stepProgress: Double // 0.0 to 1.0
    public let overallProgress: Double // 0.0 to 1.0
    public let estimatedTimeRemaining: TimeInterval?
    public let recognizedTextCount: Int

    public init(
        currentStep: OCRStep,
        stepProgress: Double,
        overallProgress: Double,
        estimatedTimeRemaining: TimeInterval? = nil,
        recognizedTextCount: Int = 0
    ) {
        self.currentStep = currentStep
        self.stepProgress = stepProgress
        self.overallProgress = overallProgress
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.recognizedTextCount = recognizedTextCount
    }
}

/// OCR processing steps
public enum OCRStep: String, CaseIterable, Equatable, Sendable {
    case preprocessing
    case textDetection = "text_detection"
    case textRecognition = "text_recognition"
    case languageDetection = "language_detection"
    case structureAnalysis = "structure_analysis"
    case postprocessing

    public var displayName: String {
        switch self {
        case .preprocessing: "Preprocessing Image"
        case .textDetection: "Detecting Text Regions"
        case .textRecognition: "Recognizing Text"
        case .languageDetection: "Detecting Languages"
        case .structureAnalysis: "Analyzing Document Structure"
        case .postprocessing: "Post-processing Results"
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

public extension DocumentImageProcessor {
    static let liveValue: Self = .init(
        processImage: { data, _, _ in
            ProcessingResult(
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
                appliedFilters: ["live"]
            )
        },
        estimateProcessingTime: { _, _ in 1.0 },
        extractText: { _, _ in
            OCRResult(
                extractedText: [],
                fullText: "Live OCR Result",
                confidence: 0.85,
                detectedLanguages: [],
                processingTime: 0.1,
                imageSize: CGSize(width: 100, height: 100)
            )
        },
        extractStructuredData: { _, _, _ in
            StructuredOCRResult(
                documentType: .generic,
                extractedFields: [:],
                ocrResult: OCRResult(
                    extractedText: [],
                    fullText: "Live Structured OCR",
                    confidence: 0.85,
                    detectedLanguages: [],
                    processingTime: 0.1,
                    imageSize: CGSize(width: 100, height: 100)
                ),
                structureConfidence: 0.85
            )
        }
    )

    static let testValue: Self = .init(
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
        isProcessingModeAvailable: { _ in true },
        extractText: { _, options in
            // Simulate OCR processing delay
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

            // Simulate progress updates
            options.progressCallback?(OCRProgress(
                currentStep: .textRecognition,
                stepProgress: 0.5,
                overallProgress: 0.5,
                recognizedTextCount: 10
            ))

            // Mock extracted text
            let extractedText = [
                DocumentImageProcessor.ExtractedText(
                    text: "Sample extracted text from test image",
                    confidence: 0.92,
                    boundingBox: CGRect(x: 10, y: 10, width: 200, height: 20),
                    characterBoxes: [],
                    detectedLanguage: .english
                ),
                DocumentImageProcessor.ExtractedText(
                    text: "Second line of text",
                    confidence: 0.88,
                    boundingBox: CGRect(x: 10, y: 35, width: 150, height: 20),
                    characterBoxes: [],
                    detectedLanguage: .english
                ),
            ]

            return DocumentImageProcessor.OCRResult(
                extractedText: extractedText,
                fullText: "Sample extracted text from test image\nSecond line of text",
                confidence: 0.90,
                detectedLanguages: [.english],
                processingTime: 0.2,
                imageSize: CGSize(width: 400, height: 300)
            )
        },
        extractStructuredData: { data, documentType, options in
            // First extract text
            let ocrResult = try await Self.testValue.extractText(data, options)

            // Mock structured fields based on document type
            var extractedFields: [String: DocumentImageProcessor.StructuredFieldValue] = [:]

            switch documentType {
            case .invoice:
                extractedFields = [
                    "invoice_number": .string("INV-001"),
                    "total_amount": .string("$123.45"),
                    "date": .string("2024-01-15"),
                ]
            case .receipt:
                extractedFields = [
                    "store_name": .string("Test Store"),
                    "total": .string("$45.67"),
                    "items": .array(["Item 1", "Item 2"]),
                ]
            case .businessCard:
                extractedFields = [
                    "name": .string("John Doe"),
                    "company": .string("Test Company"),
                    "phone": .string("+1-555-0123"),
                ]
            default:
                extractedFields = ["content": .string(ocrResult.fullText)]
            }

            return DocumentImageProcessor.StructuredOCRResult(
                documentType: documentType,
                extractedFields: extractedFields,
                ocrResult: ocrResult,
                structureConfidence: 0.85
            )
        },
        isOCRAvailable: { true }
    )
}

// MARK: - Processing Errors

public enum ProcessingError: LocalizedError, Equatable, Sendable {
    case invalidImageData
    case processingFailed(String)
    case unsupportedMode
    case cancelled
    case timeout
    case ocrNotAvailable
    case ocrFailed(String)
    case textDetectionFailed
    case languageDetectionFailed
    case unsupportedLanguage(String)

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
        case .ocrNotAvailable:
            "OCR functionality is not available on this platform"
        case let .ocrFailed(reason):
            "OCR processing failed: \(reason)"
        case .textDetectionFailed:
            "Failed to detect text in the image"
        case .languageDetectionFailed:
            "Failed to detect the language of the text"
        case let .unsupportedLanguage(language):
            "Language '\(language)' is not supported for OCR"
        }
    }
}
