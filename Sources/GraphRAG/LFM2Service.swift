import CoreML
import Foundation
import os.log

/// Actor-based service for LFM2-700M embedding generation
/// Provides thread-safe access to the LFM2 model for dual-domain GraphRAG (regulations + user records)
@globalActor
actor LFM2Service {
    // MARK: - Shared Instance

    static let shared = LFM2Service()

    // MARK: - Properties

    private var model: MLModel?
    private var isInitialized = false
    private let logger = Logger(subsystem: "com.aiko.graphrag", category: "LFM2Service")

    // Model specifications for LFM2-700M-Unsloth-XL
    private let modelName = "LFM2-700M-Unsloth-XL-GraphRAG"
    private let embeddingDimensions = 768
    private let maxTokenLength = 512

    // MARK: - Initialization

    private init() {
        logger.info("🚀 LFM2Service initializing...")
    }

    /// Load the LFM2 model from the app bundle
    /// This handles both Core ML (.mlmodel) and GGUF formats
    func initializeModel() async throws {
        guard !isInitialized else {
            logger.info("✅ LFM2 model already initialized")
            return
        }

        logger.info("🔄 Loading LFM2-700M model...")

        // First try to load Core ML model
        if let coreMLModel = try? await loadCoreMLModel() {
            model = coreMLModel
            logger.info("✅ Core ML model loaded successfully")
        } else {
            // Fallback to GGUF model handling
            logger.info("⚠️ Core ML model not found, using GGUF fallback")
            try await loadGGUFModel()
        }

        isInitialized = true
        logger.info("🎉 LFM2Service initialization complete")
    }

    // MARK: - Core ML Model Loading

    private func loadCoreMLModel() async throws -> MLModel? {
        // Try different possible model names
        let possibleNames = [
            "LFM2-700M-Unsloth-XL-GraphRAG",
            "LFM2-700M-Q6K",
            "LFM2-700M-Q6K-Placeholder",
            "LFM2-700M",
        ]

        for modelName in possibleNames {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
                logger.info("📄 Found Core ML model: \(modelName).mlmodel")

                do {
                    let model = try MLModel(contentsOf: modelURL)
                    logger.info("✅ Core ML model loaded: \(modelName)")
                    return model
                } catch {
                    logger.error("❌ Failed to load Core ML model \(modelName): \(error.localizedDescription)")
                    continue
                }
            }
        }

        return nil
    }

    // MARK: - GGUF Model Loading (Future Implementation)

    private func loadGGUFModel() async throws {
        // For now, create a placeholder that indicates GGUF processing is needed
        logger.info("🚧 GGUF model handling not yet implemented")
        logger.info("📄 GGUF file should be at: Sources/Resources/LFM2-700M-Q6_K.gguf")

        // TODO: Implement GGUF to Core ML conversion or direct GGUF processing
        // This could involve:
        // 1. Using llama.cpp Swift bindings
        // 2. Converting GGUF to ONNX then to Core ML
        // 3. Using a custom GGUF processor

        throw LFM2Error.ggufNotSupported
    }

    // MARK: - Embedding Generation

    /// Generate embeddings for text input
    /// Supports both regulation content and user workflow data
    /// - Parameters:
    ///   - text: Input text to embed (max 512 tokens)
    ///   - domain: Source domain (regulations or user_records) for optimization
    /// - Returns: 768-dimensional embedding vector
    func generateEmbedding(text: String, domain: EmbeddingDomain = .regulations) async throws -> [Float] {
        guard isInitialized, let model = model else {
            throw LFM2Error.modelNotInitialized
        }

        logger.debug("🔄 Generating embedding for \(domain.rawValue) text (length: \(text.count))")

        // Preprocess text (tokenization, truncation, etc.)
        let processedInput = try preprocessText(text)

        // Generate embedding using Core ML model
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let prediction = try model.prediction(from: processedInput)
            let embedding = try extractEmbedding(from: prediction)

            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.debug("✅ Embedding generated in \(String(format: "%.2f", duration))s")

            // Validate embedding dimensions
            guard embedding.count == embeddingDimensions else {
                throw LFM2Error.invalidEmbeddingDimensions(expected: embeddingDimensions, actual: embedding.count)
            }

            return embedding

        } catch {
            logger.error("❌ Embedding generation failed: \(error.localizedDescription)")
            throw LFM2Error.embeddingGenerationFailed(error)
        }
    }

    /// Generate embeddings for multiple text chunks in batch
    /// Optimized for processing regulation documents or user workflow batches
    func generateBatchEmbeddings(texts: [String], domain: EmbeddingDomain = .regulations) async throws -> [[Float]] {
        logger.info("🔄 Batch processing \(texts.count) texts for \(domain.rawValue)")

        var embeddings: [[Float]] = []
        let startTime = CFAbsoluteTimeGetCurrent()

        for (index, text) in texts.enumerated() {
            do {
                let embedding = try await generateEmbedding(text: text, domain: domain)
                embeddings.append(embedding)

                if (index + 1) % 10 == 0 {
                    logger.info("📊 Processed \(index + 1)/\(texts.count) embeddings")
                }

            } catch {
                logger.error("❌ Failed to generate embedding for text \(index): \(error.localizedDescription)")
                throw error
            }
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("✅ Batch processing complete: \(texts.count) embeddings in \(String(format: "%.1f", duration))s")

        return embeddings
    }

    // MARK: - Text Preprocessing

    private func preprocessText(_ text: String) throws -> MLFeatureProvider {
        // TODO: Implement proper tokenization for LFM2
        // For now, create a basic input structure

        // Clean and truncate text
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let truncatedText = String(cleanText.prefix(maxTokenLength * 4)) // Rough character estimate

        // Convert to token IDs (placeholder implementation)
        let tokenIds = createPlaceholderTokenIds(from: truncatedText)

        // Create MLMultiArray for input
        let inputArray = try MLMultiArray(shape: [1, NSNumber(value: maxTokenLength)], dataType: .int32)

        for i in 0 ..< min(tokenIds.count, maxTokenLength) {
            inputArray[i] = NSNumber(value: tokenIds[i])
        }

        // Pad remaining positions with zeros
        for i in tokenIds.count ..< maxTokenLength {
            inputArray[i] = NSNumber(value: 0)
        }

        // Create feature provider
        let inputFeatures: [String: Any] = ["input_ids": inputArray]
        return try MLDictionaryFeatureProvider(dictionary: inputFeatures)
    }

    private func createPlaceholderTokenIds(from text: String) -> [Int32] {
        // Simple hash-based tokenization placeholder
        // TODO: Replace with proper LFM2 tokenizer
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.prefix(maxTokenLength).map { word in
            Int32(abs(word.hashValue) % 50000 + 1) // Ensure non-zero
        }
    }

    private func extractEmbedding(from prediction: MLFeatureProvider) throws -> [Float] {
        // Extract embedding from model output
        // The exact key depends on the model's output specification
        let possibleKeys = ["embeddings", "last_hidden_state", "output", "embedding_output"]

        for key in possibleKeys {
            if let output = prediction.featureValue(for: key)?.multiArrayValue {
                return try convertMultiArrayToFloatArray(output)
            }
        }

        throw LFM2Error.invalidModelOutput
    }

    private func convertMultiArrayToFloatArray(_ multiArray: MLMultiArray) throws -> [Float] {
        guard multiArray.dataType == .float32 else {
            throw LFM2Error.invalidModelOutput
        }

        let count = multiArray.count
        let pointer = multiArray.dataPointer.bindMemory(to: Float.self, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}

// MARK: - Supporting Types

/// Embedding domain for optimization and tracking
enum EmbeddingDomain: String, CaseIterable {
    case regulations
    case userRecords = "user_records"

    var displayName: String {
        switch self {
        case .regulations:
            return "Government Regulations"
        case .userRecords:
            return "User Acquisition Records"
        }
    }
}

/// LFM2Service specific errors
enum LFM2Error: Error, LocalizedError {
    case modelNotInitialized
    case modelNotFound
    case ggufNotSupported
    case invalidEmbeddingDimensions(expected: Int, actual: Int)
    case embeddingGenerationFailed(Error)
    case invalidModelOutput
    case tokenizationFailed

    var errorDescription: String? {
        switch self {
        case .modelNotInitialized:
            return "LFM2 model has not been initialized. Call initializeModel() first."
        case .modelNotFound:
            return "LFM2 model file not found in app bundle. Ensure model is included in Resources."
        case .ggufNotSupported:
            return "GGUF model format not yet supported. Core ML conversion required."
        case let .invalidEmbeddingDimensions(expected, actual):
            return "Invalid embedding dimensions. Expected \(expected), got \(actual)."
        case let .embeddingGenerationFailed(error):
            return "Embedding generation failed: \(error.localizedDescription)"
        case .invalidModelOutput:
            return "Model output format is not recognized or compatible."
        case .tokenizationFailed:
            return "Text tokenization failed. Check input text format."
        }
    }
}

// MARK: - Model Information

extension LFM2Service {
    /// Get information about the loaded model
    func getModelInfo() async -> ModelInfo? {
        guard isInitialized else { return nil }

        return ModelInfo(
            name: modelName,
            embeddingDimensions: embeddingDimensions,
            maxTokenLength: maxTokenLength,
            isInitialized: isInitialized,
            modelType: model != nil ? .coreML : .gguf
        )
    }
}

struct ModelInfo {
    let name: String
    let embeddingDimensions: Int
    let maxTokenLength: Int
    let isInitialized: Bool
    let modelType: ModelType

    enum ModelType {
        case coreML
        case gguf
        case placeholder
    }
}

// MARK: - Performance Monitoring

extension LFM2Service {
    /// Performance metrics for monitoring embedding generation
    struct PerformanceMetrics {
        let averageEmbeddingTime: TimeInterval
        let totalEmbeddingsGenerated: Int
        let peakMemoryUsage: Int64
        let modelLoadTime: TimeInterval

        var embeddingsPerSecond: Double {
            guard averageEmbeddingTime > 0 else { return 0 }
            return 1.0 / averageEmbeddingTime
        }
    }

    /// Get performance metrics (placeholder for future implementation)
    func getPerformanceMetrics() async -> PerformanceMetrics {
        // TODO: Implement actual performance tracking
        return PerformanceMetrics(
            averageEmbeddingTime: 1.5,
            totalEmbeddingsGenerated: 0,
            peakMemoryUsage: 800 * 1024 * 1024, // 800MB estimate
            modelLoadTime: 2.0
        )
    }
}
