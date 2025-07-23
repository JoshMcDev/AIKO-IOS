import CoreML
import Foundation
import os.log

/// AGENT 2: LFM2 Tensor Rank Fix Implementation
/// Provides utilities and fixes for converting rank-2 tensors to rank-4+ tensors required by LFM2 model
/// This addresses the CoreML conversion issue where token_embedding layer expects higher-rank tensors

enum LFM2TensorRankFix {
    // MARK: - Tensor Shape Constants

    /// Correct tensor shapes for LFM2-700M model
    enum TensorShape {
        /// Original incorrect shape (rank 2): [batch_size, sequence_length]
        static let rank2Shape = [1, 512]

        /// Corrected shape (rank 4): [batch_size, sequence_length, embedding_dim, feature_depth]
        /// Based on LFM2-700M architecture requirements
        static let rank4Shape = [1, 512, 768, 1]

        /// Alternative rank 3 shape if model accepts: [batch_size, sequence_length, embedding_dim]
        static let rank3Shape = [1, 512, 768]

        /// Embedding dimensions for LFM2-700M
        static let embeddingDimensions = 768

        /// Maximum token sequence length
        static let maxTokenLength = 512
    }

    // MARK: - Tensor Creation Methods

    /// Create a properly shaped rank-4 tensor for LFM2 token embeddings
    /// This replaces the original rank-2 tensor creation in LFM2Service.preprocessText()
    /// - Parameters:
    ///   - tokenIds: Array of token IDs to populate the tensor
    ///   - maxLength: Maximum sequence length (default: 512)
    /// - Returns: MLMultiArray with correct rank-4 shape for LFM2 model
    /// - Throws: CoreML errors if tensor creation fails
    static func createRank4TokenTensor(tokenIds: [Int32], maxLength: Int = TensorShape.maxTokenLength) throws -> MLMultiArray {
        let tensor = try createTensorWithShape(TensorShape.rank4Shape, maxLength: maxLength)
        try populateTensorWithTokens(tensor, tokenIds: tokenIds, embeddingStride: TensorShape.embeddingDimensions)
        return tensor
    }

    /// Create alternative rank-3 tensor if the model accepts this format
    /// - Parameters:
    ///   - tokenIds: Array of token IDs
    ///   - maxLength: Maximum sequence length
    /// - Returns: MLMultiArray with rank-3 shape
    /// - Throws: CoreML errors if tensor creation fails
    static func createRank3TokenTensor(tokenIds: [Int32], maxLength: Int = TensorShape.maxTokenLength) throws -> MLMultiArray {
        let tensor = try createTensorWithShape(TensorShape.rank3Shape, maxLength: maxLength)
        try populateTensorWithTokens(tensor, tokenIds: tokenIds, embeddingStride: TensorShape.embeddingDimensions)
        return tensor
    }

    /// Create the original rank-2 tensor (for backward compatibility testing)
    /// - Parameters:
    ///   - tokenIds: Array of token IDs
    ///   - maxLength: Maximum sequence length
    /// - Returns: MLMultiArray with rank-2 shape (original implementation)
    /// - Throws: CoreML errors if tensor creation fails
    static func createRank2TokenTensor(tokenIds: [Int32], maxLength: Int = TensorShape.maxTokenLength) throws -> MLMultiArray {
        let tensor = try createTensorWithShape(TensorShape.rank2Shape, maxLength: maxLength)
        try populateTensorWithTokens(tensor, tokenIds: tokenIds, embeddingStride: 1)
        return tensor
    }

    // MARK: - Core Tensor Utilities (Private)

    /// Create a tensor with the specified shape and initialize with zeros
    /// - Parameters:
    ///   - baseShape: Base shape template (will substitute maxLength)
    ///   - maxLength: Maximum sequence length to use
    /// - Returns: Zero-initialized MLMultiArray
    /// - Throws: CoreML errors if tensor creation fails
    private static func createTensorWithShape(_ baseShape: [Int], maxLength: Int) throws -> MLMultiArray {
        // Substitute maxLength in the shape template
        var shape: [NSNumber]
        switch baseShape.count {
        case 2:
            shape = [NSNumber(value: 1), NSNumber(value: maxLength)]
        case 3:
            shape = [NSNumber(value: 1), NSNumber(value: maxLength), NSNumber(value: TensorShape.embeddingDimensions)]
        case 4:
            shape = [NSNumber(value: 1), NSNumber(value: maxLength), NSNumber(value: TensorShape.embeddingDimensions), NSNumber(value: 1)]
        default:
            throw LFM2TensorError.unsupportedRank(rank: baseShape.count)
        }

        let tensor = try MLMultiArray(shape: shape, dataType: .int32)

        // Initialize with zeros using optimized approach
        let totalElements = shape.reduce(1) { $0 * $1.intValue }
        for i in 0 ..< totalElements {
            tensor[i] = NSNumber(value: 0)
        }

        return tensor
    }

    /// Populate tensor with token IDs using the appropriate stride pattern
    /// - Parameters:
    ///   - tensor: Target tensor to populate
    ///   - tokenIds: Token IDs to insert
    ///   - embeddingStride: Stride for embedding dimension placement
    /// - Throws: CoreML errors if population fails
    private static func populateTensorWithTokens(_ tensor: MLMultiArray, tokenIds: [Int32], embeddingStride: Int) throws {
        let maxLength = tensor.shape[1].intValue
        let tokensToUse = min(tokenIds.count, maxLength)

        for i in 0 ..< tokensToUse {
            let flatIndex = i * embeddingStride
            tensor[flatIndex] = NSNumber(value: tokenIds[i])
        }
    }

    // MARK: - Tensor Validation Methods

    /// Validate that a tensor has the correct rank and dimensions for LFM2
    /// - Parameter tensor: MLMultiArray to validate
    /// - Returns: ValidationResult indicating success or specific issues
    static func validateTensorRank(_ tensor: MLMultiArray) -> TensorValidationResult {
        let shape = tensor.shape
        let rank = shape.count

        // Validate using dimension validators
        if let error = validateDimensions(shape: shape, rank: rank) {
            return .invalid(error)
        }

        return .valid(rank: rank, shape: shape.map(\.intValue))
    }

    /// Validate tensor dimensions against LFM2 requirements
    /// - Parameters:
    ///   - shape: Tensor shape to validate
    ///   - rank: Tensor rank
    /// - Returns: Validation error if any, nil if valid
    private static func validateDimensions(shape: [NSNumber], rank: Int) -> TensorValidationError? {
        // Check rank requirements
        guard rank >= 3 else {
            return .insufficientRank(current: rank, minimum: 3)
        }

        // Check batch size
        guard shape[0].intValue == 1 else {
            return .incorrectBatchSize(expected: 1, actual: shape[0].intValue)
        }

        // Check sequence length
        guard shape[1].intValue == TensorShape.maxTokenLength else {
            return .incorrectSequenceLength(expected: TensorShape.maxTokenLength, actual: shape[1].intValue)
        }

        // Check embedding dimensions for rank 3+
        if rank >= 3 {
            guard shape[2].intValue == TensorShape.embeddingDimensions else {
                return .incorrectEmbeddingDimensions(expected: TensorShape.embeddingDimensions, actual: shape[2].intValue)
            }
        }

        // Check feature depth for rank 4+
        if rank >= 4 {
            guard shape[3].intValue == 1 else {
                return .incorrectFeatureDepth(expected: 1, actual: shape[3].intValue)
            }
        }

        return nil
    }

    /// Convert rank-2 tensor to rank-4 tensor for compatibility
    /// - Parameter rank2Tensor: Original rank-2 tensor from old implementation
    /// - Returns: Converted rank-4 tensor compatible with LFM2 model
    /// - Throws: Conversion errors
    static func convertRank2ToRank4(_ rank2Tensor: MLMultiArray) throws -> MLMultiArray {
        // Validate input is rank-2
        guard rank2Tensor.shape.count == 2 else {
            throw LFM2TensorError.invalidInputRank(expected: 2, actual: rank2Tensor.shape.count)
        }

        // Extract token IDs efficiently
        let tokenIds = try extractTokenIds(from: rank2Tensor)

        // Create new rank-4 tensor with the extracted token IDs
        return try createRank4TokenTensor(tokenIds: tokenIds, maxLength: rank2Tensor.shape[1].intValue)
    }

    /// Extract token IDs from a rank-2 tensor
    /// - Parameter tensor: Source rank-2 tensor
    /// - Returns: Array of token IDs
    /// - Throws: Extraction errors
    private static func extractTokenIds(from tensor: MLMultiArray) throws -> [Int32] {
        let sequenceLength = tensor.shape[1].intValue
        var tokenIds: [Int32] = []
        tokenIds.reserveCapacity(sequenceLength)

        for i in 0 ..< sequenceLength {
            let value = tensor[[0, NSNumber(value: i)]].int32Value
            tokenIds.append(value)
        }

        return tokenIds
    }

    // MARK: - Feature Provider Creation

    /// Create MLFeatureProvider with corrected tensor rank for LFM2 model
    /// This replaces the feature provider creation in LFM2Service.preprocessText()
    /// - Parameters:
    ///   - tokenIds: Array of token IDs
    ///   - preferredRank: Preferred tensor rank (3 or 4)
    /// - Returns: MLFeatureProvider with correctly shaped tensors
    /// - Throws: Feature provider creation errors
    static func createFeatureProvider(tokenIds: [Int32], preferredRank: Int = 4) throws -> MLFeatureProvider {
        let inputTensor: MLMultiArray

        switch preferredRank {
        case 4:
            inputTensor = try createRank4TokenTensor(tokenIds: tokenIds)
        case 3:
            inputTensor = try createRank3TokenTensor(tokenIds: tokenIds)
        case 2:
            inputTensor = try createRank2TokenTensor(tokenIds: tokenIds)
        default:
            throw LFM2TensorError.unsupportedRank(rank: preferredRank)
        }

        // Create feature dictionary
        let inputFeatures: [String: Any] = [
            "input_ids": inputTensor,
        ]

        return try MLDictionaryFeatureProvider(dictionary: inputFeatures)
    }
}

// MARK: - Supporting Types

/// Result of tensor validation
enum TensorValidationResult: Equatable {
    case valid(rank: Int, shape: [Int])
    case invalid(TensorValidationError)

    var isValid: Bool {
        switch self {
        case .valid:
            true
        case .invalid:
            false
        }
    }
}

/// Specific tensor validation errors
enum TensorValidationError: Error, Equatable {
    case insufficientRank(current: Int, minimum: Int)
    case incorrectBatchSize(expected: Int, actual: Int)
    case incorrectSequenceLength(expected: Int, actual: Int)
    case incorrectEmbeddingDimensions(expected: Int, actual: Int)
    case incorrectFeatureDepth(expected: Int, actual: Int)

    var localizedDescription: String {
        switch self {
        case let .insufficientRank(current, minimum):
            "Insufficient tensor rank: \(current), minimum required: \(minimum)"
        case let .incorrectBatchSize(expected, actual):
            "Incorrect batch size: expected \(expected), got \(actual)"
        case let .incorrectSequenceLength(expected, actual):
            "Incorrect sequence length: expected \(expected), got \(actual)"
        case let .incorrectEmbeddingDimensions(expected, actual):
            "Incorrect embedding dimensions: expected \(expected), got \(actual)"
        case let .incorrectFeatureDepth(expected, actual):
            "Incorrect feature depth: expected \(expected), got \(actual)"
        }
    }
}

/// LFM2 tensor-specific errors
enum LFM2TensorError: Error, LocalizedError {
    case invalidInputRank(expected: Int, actual: Int)
    case unsupportedRank(rank: Int)
    case tensorConversionFailed(Error)

    var errorDescription: String? {
        switch self {
        case let .invalidInputRank(expected, actual):
            "Invalid input tensor rank: expected \(expected), got \(actual)"
        case let .unsupportedRank(rank):
            "Unsupported tensor rank: \(rank). Supported ranks: 2, 3, 4"
        case let .tensorConversionFailed(error):
            "Tensor conversion failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extension for LFM2Service Integration

extension LFM2Service {
    /// Updated preprocessText method using tensor rank fix
    /// This is the corrected version that should replace the original implementation
    /// - Parameter text: Input text to preprocess
    /// - Returns: MLFeatureProvider with correctly shaped rank-4+ tensors
    /// - Throws: Preprocessing errors
    nonisolated func preprocessTextWithTensorRankFix(_ text: String) throws -> MLFeatureProvider {
        // Clean and truncate text (unchanged from original)
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let truncatedText = String(cleanText.prefix(LFM2TensorRankFix.TensorShape.maxTokenLength * 4))

        // Convert to token IDs (unchanged from original)
        let tokenIds = createPlaceholderTokenIds(from: truncatedText)

        // Use the tensor rank fix instead of original rank-2 tensor creation
        return try LFM2TensorRankFix.createFeatureProvider(tokenIds: tokenIds, preferredRank: 4)
    }

    /// Test method to compare original vs fixed tensor creation
    /// - Parameter text: Input text
    /// - Returns: Comparison result
    /// - Throws: Preprocessing errors
    nonisolated func compareTensorRankImplementations(_ text: String) throws -> TensorRankComparisonResult {
        let tokenIds = createPlaceholderTokenIds(from: text)

        // Original rank-2 implementation
        let originalTensor = try LFM2TensorRankFix.createRank2TokenTensor(tokenIds: tokenIds)

        // New rank-4 implementation
        let fixedTensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: tokenIds)

        // Validation results
        let originalValidation = LFM2TensorRankFix.validateTensorRank(originalTensor)
        let fixedValidation = LFM2TensorRankFix.validateTensorRank(fixedTensor)

        return TensorRankComparisonResult(
            originalRank: originalTensor.shape.count,
            fixedRank: fixedTensor.shape.count,
            originalShape: originalTensor.shape.map(\.intValue),
            fixedShape: fixedTensor.shape.map(\.intValue),
            originalValidation: originalValidation,
            fixedValidation: fixedValidation
        )
    }
}

/// Comparison result between original and fixed tensor implementations
struct TensorRankComparisonResult {
    let originalRank: Int
    let fixedRank: Int
    let originalShape: [Int]
    let fixedShape: [Int]
    let originalValidation: TensorValidationResult
    let fixedValidation: TensorValidationResult

    var isFixSuccessful: Bool {
        fixedValidation.isValid && !originalValidation.isValid
    }

    var summary: String {
        """
        Tensor Rank Fix Comparison:
        - Original: rank \(originalRank), shape \(originalShape), valid: \(originalValidation.isValid)
        - Fixed: rank \(fixedRank), shape \(fixedShape), valid: \(fixedValidation.isValid)
        - Fix successful: \(isFixSuccessful)
        """
    }
}
