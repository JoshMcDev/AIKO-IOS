import Foundation
import os.log
#if canImport(CoreML)
    import CoreML
#endif
import AppCore

/// Actor-based service for LFM2 embedding generation with hybrid architecture
/// Provides thread-safe access to embeddings for dual-domain GraphRAG (regulations + user records)
/// Uses lazy loading and environment-based switching between mock and real models
@globalActor
actor LFM2Service {
    // MARK: - Shared Instance

    static let shared = LFM2Service()

    // MARK: - Properties

    private var isInitialized = false
    private let logger = Logger(subsystem: "com.aiko.graphrag", category: "LFM2Service")

    // Model specifications for LFM2-700M-Unsloth-XL
    private let modelName = "LFM2-700M-Unsloth-XL-GraphRAG"
    private let embeddingDimensions = 768
    private let maxTokenLength = 512

    // Hybrid Architecture Control
    private let deploymentMode: DeploymentMode
    private var modelLoadTime: Date?
    private let modelUnloadDelay: TimeInterval = 300 // 5 minutes
    private var unloadTimer: Timer?

    #if canImport(CoreML)
        private var model: MLModel?
        private var isModelLoaded = false
    #endif

    // MARK: - Initialization

    private init() {
        // Environment-based deployment mode selection
        let mode = Self.determineDeploymentMode()
        deploymentMode = mode
        logger.info("🚀 LFM2Service initializing in \(mode.rawValue) mode...")
        // Initialize as ready for mock embeddings
        isInitialized = true
    }
    
    /// Determine deployment mode based on build configuration and model availability
    private static func determineDeploymentMode() -> DeploymentMode {
        // Validate build configuration
        BuildConfiguration.validateConfiguration()
        
        // Use build configuration to determine strategy
        switch BuildConfiguration.lfm2ModelStrategy {
        case .disabled, .developmentMock:
            return .mockOnly
            
        case .productionHybrid, .fullProduction:
            // Check if Core ML model files are actually available
            let possibleModelNames = [
                "LFM2-700M-Unsloth-XL-GraphRAG",
                "LFM2-700M-Q6K", 
                "LFM2-700M"
            ]
            
            for modelName in possibleModelNames {
                if Bundle.main.url(forResource: modelName, withExtension: "mlmodel") != nil {
                    return .hybridLazy
                }
            }
            
            // If build config says to use models but they're not found, warn and fallback
            let logger = Logger(subsystem: "com.aiko.graphrag", category: "LFM2Service")
            logger.warning("⚠️ Build configuration expects model files but none found - using mock fallback")
            return .mockOnly
        }
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
        #if canImport(CoreML)
            if let coreMLModel = try? await loadCoreMLModel() {
                model = coreMLModel
                logger.info("✅ Core ML model loaded successfully")
            } else {
                // Fallback to GGUF model handling
                logger.info("⚠️ Core ML model not found, using GGUF fallback")
                try await loadGGUFModel()
            }
        #endif

        isInitialized = true
        logger.info("🎉 LFM2Service initialization complete")
    }

    // MARK: - Core ML Model Loading

    #if canImport(CoreML)
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
    #endif

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
    
    // MARK: - Lazy Loading Implementation
    
    /// Lazy load the Core ML model on first use
    private func lazyLoadModel() async throws {
        #if canImport(CoreML)
            guard model == nil else {
                logger.info("✅ Model already loaded")
                return
            }
            
            logger.info("🔄 Lazy loading LFM2 Core ML model...")
            modelLoadTime = Date()
            
            // Try to load Core ML model
            if let coreMLModel = try? await loadCoreMLModel() {
                model = coreMLModel
                isModelLoaded = true
                logger.info("✅ LFM2 model lazy loaded successfully")
            } else {
                logger.warning("⚠️ Failed to lazy load Core ML model, will use mock fallback")
                throw LFM2Error.modelNotFound
            }
        #else
            throw LFM2Error.modelNotFound
        #endif
    }
    
    /// Generate real embedding using Core ML model
    private func generateRealEmbedding(text: String, domain: EmbeddingDomain, model: MLModel) async throws -> [Float] {
        // TODO: Implement actual Core ML model inference
        // For now, use enhanced mock that simulates real model behavior
        logger.debug("🚧 Real Core ML inference not yet implemented, using enhanced mock")
        
        // This would be the actual implementation:
        // 1. Preprocess text using preprocessTextWithTensorRankFix
        // 2. Run model.prediction(from: input)
        // 3. Extract embedding from output using extractEmbedding
        // 4. Return float array
        
        return generateMockEmbedding(text: text, domain: domain)
    }
    
    /// Schedule automatic model unload for memory management
    private func scheduleModelUnload() {
        #if canImport(CoreML)
            guard deploymentMode == .hybridLazy, model != nil else { return }
            
            // Cancel existing timer
            unloadTimer?.invalidate()
            
            // Schedule new unload timer
            unloadTimer = Timer.scheduledTimer(withTimeInterval: modelUnloadDelay, repeats: false) { [weak self] _ in
                Task { [weak self] in
                    await self?.unloadModel()
                }
            }
        #endif
    }
    
    /// Unload model to free memory when not in use
    private func unloadModel() async {
        #if canImport(CoreML)
            guard model != nil else { return }
            
            logger.info("🔄 Unloading LFM2 model to free memory")
            model = nil
            isModelLoaded = false
            modelLoadTime = nil
            logger.info("✅ LFM2 model unloaded")
        #endif
    }

    // MARK: - Embedding Generation

    /// Generate embeddings for text input
    /// Supports both regulation content and user workflow data
    /// - Parameters:
    ///   - text: Input text to embed (max 512 tokens)
    ///   - domain: Source domain (regulations or user_records) for optimization
    /// - Returns: 768-dimensional embedding vector
    func generateEmbedding(text: String, domain: EmbeddingDomain = .regulations) async throws -> [Float] {
        logger.debug("🔄 Generating embedding for \(domain.rawValue) text (length: \(text.count))")

        let startTime = CFAbsoluteTimeGetCurrent()
        let embedding: [Float]

        switch deploymentMode {
        case .mockOnly:
            // Always use mock embeddings
            logger.debug("📝 Using mock embedding (mock-only mode)")
            embedding = generateMockEmbedding(text: text, domain: domain)
            
        case .hybridLazy:
            // Try to use real model with lazy loading, fallback to mock
            #if canImport(CoreML)
                do {
                    if model == nil && !isModelLoaded {
                        // Lazy load the model on first use
                        logger.info("🔄 Lazy loading LFM2 model on first use...")
                        try await lazyLoadModel()
                    }
                    
                    if let coreMLModel = model {
                        // Use real Core ML model (TODO: implement actual prediction)
                        logger.debug("📝 Using Core ML model (hybrid-lazy mode)")
                        embedding = try await generateRealEmbedding(text: text, domain: domain, model: coreMLModel)
                    } else {
                        // Fallback to mock
                        logger.info("⚠️ Falling back to mock embedding (model unavailable)")
                        embedding = generateMockEmbedding(text: text, domain: domain)
                    }
                } catch {
                    logger.error("❌ Core ML model failed, using mock fallback: \(error.localizedDescription)")
                    embedding = generateMockEmbedding(text: text, domain: domain)
                }
            #else
                // CoreML not available, use mock
                logger.info("📝 CoreML not available, using mock embedding")
                embedding = generateMockEmbedding(text: text, domain: domain)
            #endif
            
        case .realOnly:
            // Always use real model (future implementation)
            #if canImport(CoreML)
                guard let coreMLModel = model else {
                    throw LFM2Error.modelNotInitialized
                }
                logger.debug("📝 Using Core ML model (real-only mode)")
                embedding = try await generateRealEmbedding(text: text, domain: domain, model: coreMLModel)
            #else
                throw LFM2Error.modelNotFound
            #endif
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.debug("✅ Embedding generated in \(String(format: "%.2f", duration))s")

        // Validate embedding dimensions
        guard embedding.count == embeddingDimensions else {
            throw LFM2Error.invalidEmbeddingDimensions(expected: embeddingDimensions, actual: embedding.count)
        }

        // Schedule model unload timer for memory management
        scheduleModelUnload()

        return embedding
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

    /// DEPRECATED: Original rank-2 tensor implementation (kept for backward compatibility)
    /// Use preprocessTextWithTensorRankFix() instead for proper LFM2 model compatibility
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

    nonisolated func createPlaceholderTokenIds(from text: String) -> [Int32] {
        // Simple hash-based tokenization placeholder
        // TODO: Replace with proper LFM2 tokenizer
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.prefix(LFM2TensorRankFix.TensorShape.maxTokenLength).map { word in
            Int32(abs(word.hashValue) % 50000 + 1) // Ensure non-zero
        }
    }

    nonisolated func createImprovedTokenIds(from text: String) -> [Int32] {
        // Enhanced tokenization for better performance and compatibility
        let cleanText = text.lowercased()
        let words = cleanText.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty }

        var tokenIds: [Int32] = []

        for word in words.prefix(LFM2TensorRankFix.TensorShape.maxTokenLength) {
            // Create more stable token IDs based on word content - safe conversion
            let wordHash = word.djb2hash
            let safeHash = Int(wordHash % 50000) + 1 // Ensure value fits in Int32 range
            let tokenId = Int32(clamping: safeHash) // Safe conversion
            tokenIds.append(tokenId)
        }

        return tokenIds
    }

    /// Generate mock embedding for testing purposes
    private func generateMockEmbedding(text: String, domain: EmbeddingDomain) -> [Float] {
        // Create deterministic but realistic embedding based on text content
        _ = createImprovedTokenIds(from: text)
        var embedding = [Float](repeating: 0.0, count: embeddingDimensions)

        // Use text hash and domain to create consistent embeddings - safe conversion
        let textHash = text.djb2hash
        let domainSeed: UInt = domain == .regulations ? 1000 : 2000
        let safeSeed = textHash &+ domainSeed // Use wrapping addition to prevent overflow
        var seed = UInt64(safeSeed)

        // Generate pseudo-random but deterministic values
        for i in 0 ..< embeddingDimensions {
            seed = seed &* 1_103_515_245 &+ 12345 // Linear congruential generator
            let value = Float(Int32(bitPattern: UInt32(seed >> 16))) / Float(Int32.max)
            embedding[i] = value
        }

        // Normalize the embedding vector
        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        // Add domain-specific bias for differentiation
        let domainBias: Float = domain == .regulations ? 0.1 : -0.1
        for i in 0 ..< min(10, embeddingDimensions) {
            embedding[i] += domainBias
        }

        // Re-normalize after bias addition
        let finalMagnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if finalMagnitude > 0 {
            embedding = embedding.map { $0 / finalMagnitude }
        }

        return embedding
    }

    /// Enhanced text preprocessing with tensor rank fixes for LFM2 model compatibility
    func preprocessTextWithTensorRankFix(_ text: String) throws -> MLFeatureProvider {
        // Clean and truncate text to model limits
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let truncatedText = String(cleanText.prefix(LFM2TensorRankFix.TensorShape.maxTokenLength * 4))

        // Convert to token IDs using improved tokenization
        let tokenIds = createImprovedTokenIds(from: truncatedText)

        // Create properly shaped MLMultiArray for LFM2 model
        let inputArray = try MLMultiArray(
            shape: [
                NSNumber(value: LFM2TensorRankFix.TensorShape.batchSize),
                NSNumber(value: LFM2TensorRankFix.TensorShape.maxTokenLength),
            ],
            dataType: .int32
        )

        // Fill array with token IDs, pad with zeros
        for i in 0 ..< LFM2TensorRankFix.TensorShape.maxTokenLength {
            let tokenId = i < tokenIds.count ? tokenIds[i] : 0
            inputArray[i] = NSNumber(value: tokenId)
        }

        // Create feature provider with correct input key
        let inputFeatures: [String: Any] = ["input_ids": inputArray]
        return try MLDictionaryFeatureProvider(dictionary: inputFeatures)
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

/// Deployment mode for LFM2 service operation
enum DeploymentMode: String, CaseIterable {
    case mockOnly = "mock-only"           // Always use mock embeddings
    case hybridLazy = "hybrid-lazy"       // Lazy-load real model, fallback to mock
    case realOnly = "real-only"           // Always use real model (future)
    
    var description: String {
        switch self {
        case .mockOnly:
            return "Mock embeddings only (no Core ML model)"
        case .hybridLazy:
            return "Lazy-loaded Core ML model with mock fallback"
        case .realOnly:
            return "Core ML model only (no mock fallback)"
        }
    }
    
    var shouldLoadModel: Bool {
        switch self {
        case .mockOnly:
            return false
        case .hybridLazy, .realOnly:
            return true
        }
    }
}

/// Embedding domain for optimization and tracking
enum EmbeddingDomain: String, CaseIterable {
    case regulations
    case userRecords = "user_records"

    var displayName: String {
        switch self {
        case .regulations:
            "Government Regulations"
        case .userRecords:
            "User Acquisition Records"
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
            "LFM2 model has not been initialized. Call initializeModel() first."
        case .modelNotFound:
            "LFM2 model file not found in app bundle. Ensure model is included in Resources."
        case .ggufNotSupported:
            "GGUF model format not yet supported. Core ML conversion required."
        case let .invalidEmbeddingDimensions(expected, actual):
            "Invalid embedding dimensions. Expected \(expected), got \(actual)."
        case let .embeddingGenerationFailed(error):
            "Embedding generation failed: \(error.localizedDescription)"
        case .invalidModelOutput:
            "Model output format is not recognized or compatible."
        case .tokenizationFailed:
            "Text tokenization failed. Check input text format."
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
            modelType: model != nil ? .coreML : .gguf,
            deploymentMode: deploymentMode,
            isModelLoaded: model != nil,
            modelLoadTime: modelLoadTime
        )
    }
}

struct ModelInfo {
    let name: String
    let embeddingDimensions: Int
    let maxTokenLength: Int
    let isInitialized: Bool
    let modelType: ModelType
    let deploymentMode: DeploymentMode
    let isModelLoaded: Bool
    let modelLoadTime: Date?

    enum ModelType {
        case coreML
        case gguf
        case placeholder
    }
    
    var description: String {
        let loadStatus = isModelLoaded ? "loaded" : "unloaded"
        let loadTimeStr = modelLoadTime?.formatted() ?? "never"
        return "\(name) (\(deploymentMode.rawValue), \(loadStatus), loaded: \(loadTimeStr))"
    }
}

// MARK: - Tensor Rank Compatibility

/// Tensor rank compatibility fixes for LFM2 model integration
enum LFM2TensorRankFix {
    /// Tensor shape configuration for LFM2 model compatibility
    enum TensorShape {
        static let maxTokenLength = 512
        static let embeddingDimensions = 768
        static let batchSize = 1
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
        PerformanceMetrics(
            averageEmbeddingTime: 1.5,
            totalEmbeddingsGenerated: 0,
            peakMemoryUsage: 800 * 1024 * 1024, // 800MB estimate
            modelLoadTime: 2.0
        )
    }
}

// MARK: - String Extensions

extension String {
    var djb2hash: UInt {
        // Simple, overflow-safe hash using built-in hashValue
        return UInt(abs(self.hashValue))
    }
}
