#!/usr/bin/env swift

import CoreML
import Foundation

// Import the actual implementation logic from our files
// This replicates the test cases to validate GREEN phase completion

enum LFM2TensorRankFix {
    enum TensorShape {
        static let rank2Shape = [1, 512]
        static let rank4Shape = [1, 512, 768, 1]
        static let rank3Shape = [1, 512, 768]
        static let embeddingDimensions = 768
        static let maxTokenLength = 512
    }
    
    static func createRank4TokenTensor(tokenIds: [Int32], maxLength: Int = TensorShape.maxTokenLength) throws -> MLMultiArray {
        let shape = [
            NSNumber(value: 1),
            NSNumber(value: maxLength),
            NSNumber(value: TensorShape.embeddingDimensions),
            NSNumber(value: 1),
        ]
        
        let tensor = try MLMultiArray(shape: shape, dataType: .int32)
        
        let totalElements = shape.reduce(1) { $0 * $1.intValue }
        for i in 0 ..< totalElements {
            tensor[i] = NSNumber(value: 0)
        }
        
        let tokensToUse = min(tokenIds.count, maxLength)
        for i in 0 ..< tokensToUse {
            let flatIndex = i * TensorShape.embeddingDimensions * 1
            tensor[flatIndex] = NSNumber(value: tokenIds[i])
        }
        
        return tensor
    }
    
    static func createRank3TokenTensor(tokenIds: [Int32], maxLength: Int = TensorShape.maxTokenLength) throws -> MLMultiArray {
        let shape = [
            NSNumber(value: 1),
            NSNumber(value: maxLength),
            NSNumber(value: TensorShape.embeddingDimensions),
        ]
        
        let tensor = try MLMultiArray(shape: shape, dataType: .int32)
        
        let totalElements = shape.reduce(1) { $0 * $1.intValue }
        for i in 0 ..< totalElements {
            tensor[i] = NSNumber(value: 0)
        }
        
        let tokensToUse = min(tokenIds.count, maxLength)
        for i in 0 ..< tokensToUse {
            let flatIndex = i * TensorShape.embeddingDimensions
            tensor[flatIndex] = NSNumber(value: tokenIds[i])
        }
        
        return tensor
    }
    
    static func createRank2TokenTensor(tokenIds: [Int32], maxLength: Int = TensorShape.maxTokenLength) throws -> MLMultiArray {
        let shape = [NSNumber(value: 1), NSNumber(value: maxLength)]
        let tensor = try MLMultiArray(shape: shape, dataType: .int32)
        
        let tokensToUse = min(tokenIds.count, maxLength)
        for i in 0 ..< tokensToUse {
            tensor[i] = NSNumber(value: tokenIds[i])
        }
        
        for i in tokensToUse ..< maxLength {
            tensor[i] = NSNumber(value: 0)
        }
        
        return tensor
    }
    
    enum TensorValidationResult: Equatable {
        case valid(rank: Int, shape: [Int])
        case invalid(TensorValidationError)
        
        var isValid: Bool {
            switch self {
            case .valid: true
            case .invalid: false
            }
        }
    }
    
    enum TensorValidationError: Error, Equatable {
        case insufficientRank(current: Int, minimum: Int)
        case incorrectBatchSize(expected: Int, actual: Int)
        case incorrectSequenceLength(expected: Int, actual: Int)
        case incorrectEmbeddingDimensions(expected: Int, actual: Int)
        case incorrectFeatureDepth(expected: Int, actual: Int)
    }
    
    static func validateTensorRank(_ tensor: MLMultiArray) -> TensorValidationResult {
        let shape = tensor.shape
        let rank = shape.count
        
        guard rank >= 3 else {
            return .invalid(.insufficientRank(current: rank, minimum: 3))
        }
        
        guard shape[0].intValue == 1 else {
            return .invalid(.incorrectBatchSize(expected: 1, actual: shape[0].intValue))
        }
        
        guard shape[1].intValue == TensorShape.maxTokenLength else {
            return .invalid(.incorrectSequenceLength(expected: TensorShape.maxTokenLength, actual: shape[1].intValue))
        }
        
        if rank >= 3 {
            guard shape[2].intValue == TensorShape.embeddingDimensions else {
                return .invalid(.incorrectEmbeddingDimensions(expected: TensorShape.embeddingDimensions, actual: shape[2].intValue))
            }
        }
        
        if rank >= 4 {
            guard shape[3].intValue == 1 else {
                return .invalid(.incorrectFeatureDepth(expected: 1, actual: shape[3].intValue))
            }
        }
        
        return .valid(rank: rank, shape: shape.map(\.intValue))
    }
    
    enum LFM2TensorError: Error {
        case invalidInputRank(expected: Int, actual: Int)
        case unsupportedRank(rank: Int)
    }
    
    static func convertRank2ToRank4(_ rank2Tensor: MLMultiArray) throws -> MLMultiArray {
        guard rank2Tensor.shape.count == 2 else {
            throw LFM2TensorError.invalidInputRank(expected: 2, actual: rank2Tensor.shape.count)
        }
        
        let sequenceLength = rank2Tensor.shape[1].intValue
        var tokenIds: [Int32] = []
        
        for i in 0 ..< sequenceLength {
            let value = rank2Tensor[[0, NSNumber(value: i)]].int32Value
            tokenIds.append(value)
        }
        
        return try createRank4TokenTensor(tokenIds: tokenIds, maxLength: sequenceLength)
    }
    
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
        
        let inputFeatures: [String: Any] = ["input_ids": inputTensor]
        return try MLDictionaryFeatureProvider(dictionary: inputFeatures)
    }
}

// Run all the test scenarios from the test files
print("🟢 GREEN PHASE VALIDATION - Making Tests Pass")
print(String(repeating: "=", count: 60))

var testsPassed = 0
var testsTotal = 0

func runTest(_ testName: String, _ testBlock: () throws -> Void) {
    testsTotal += 1
    do {
        try testBlock()
        print("✅ \(testName)")
        testsPassed += 1
    } catch {
        print("❌ \(testName): \(error)")
    }
}

// Test: testCreateRank4TokenTensor_withValidInput_returnsCorrectShape
runTest("testCreateRank4TokenTensor_withValidInput_returnsCorrectShape") {
    let tokenIds: [Int32] = [1, 2, 3, 4, 5]
    let maxTokenLength = 512
    let embeddingDimensions = 768
    
    let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: tokenIds)
    
    guard tensor.shape.count == 4 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tensor should have rank 4"]) }
    guard tensor.shape[0].intValue == 1 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Batch size should be 1"]) }
    guard tensor.shape[1].intValue == maxTokenLength else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sequence length should be 512"]) }
    guard tensor.shape[2].intValue == embeddingDimensions else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Embedding dimensions should be 768"]) }
    guard tensor.shape[3].intValue == 1 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Feature depth should be 1"]) }
    guard tensor.dataType == .int32 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tensor should use int32 data type"]) }
    guard tensor[0].int32Value == tokenIds[0] else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "First token should be correctly placed"]) }
}

// Test: testCreateRank4TokenTensor_withEmptyTokens_returnsZeroTensor
runTest("testCreateRank4TokenTensor_withEmptyTokens_returnsZeroTensor") {
    let emptyTokenIds: [Int32] = []
    let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: emptyTokenIds)
    
    guard tensor.shape.count == 4 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tensor should have rank 4"]) }
    guard tensor[0].int32Value == 0 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Empty tokens should result in zero values"]) }
}

// Test: testCreateRank4TokenTensor_withOversizedTokens_truncatesCorrectly  
runTest("testCreateRank4TokenTensor_withOversizedTokens_truncatesCorrectly") {
    let maxTokenLength = 512
    let oversizedTokenIds = Array(1...(maxTokenLength + 100)).map(Int32.init)
    let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: oversizedTokenIds)
    
    guard tensor.shape[1].intValue == maxTokenLength else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Should truncate to max length"]) }
    guard tensor[0].int32Value == 1 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Should contain first token"]) }
}

// Test: testValidateTensorRank_withValidRank4Tensor_returnsValid
runTest("testValidateTensorRank_withValidRank4Tensor_returnsValid") {
    let validTokenIds: [Int32] = [1, 2, 3, 4, 5]
    let maxTokenLength = 512
    let embeddingDimensions = 768
    
    let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: validTokenIds)
    let validation = LFM2TensorRankFix.validateTensorRank(tensor)
    
    guard validation.isValid else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Valid rank-4 tensor should pass validation"]) }
    
    if case let .valid(rank, shape) = validation {
        guard rank == 4 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected rank 4"]) }
        guard shape == [1, maxTokenLength, embeddingDimensions, 1] else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected correct shape"]) }
    } else {
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected valid result"])
    }
}

// Test: testValidateTensorRank_withRank2Tensor_returnsInvalidRank
runTest("testValidateTensorRank_withRank2Tensor_returnsInvalidRank") {
    let validTokenIds: [Int32] = [1, 2, 3, 4, 5]
    let rank2Tensor = try LFM2TensorRankFix.createRank2TokenTensor(tokenIds: validTokenIds)
    let validation = LFM2TensorRankFix.validateTensorRank(rank2Tensor)
    
    guard !validation.isValid else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Rank-2 tensor should fail validation"]) }
    
    if case let .invalid(error) = validation {
        if case let .insufficientRank(current, minimum) = error {
            guard current == 2 && minimum == 3 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected insufficient rank error"]) }
        } else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected insufficient rank error"])
        }
    } else {
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected invalid result"])
    }
}

// Test: testConvertRank2ToRank4_withValidInput_maintainsDataIntegrity
runTest("testConvertRank2ToRank4_withValidInput_maintainsDataIntegrity") {
    let validTokenIds: [Int32] = [1, 2, 3, 4, 5]
    let embeddingDimensions = 768
    
    let originalTensor = try LFM2TensorRankFix.createRank2TokenTensor(tokenIds: validTokenIds)
    let convertedTensor = try LFM2TensorRankFix.convertRank2ToRank4(originalTensor)
    
    guard convertedTensor.shape.count == 4 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Converted tensor should have rank 4"]) }
    
    for i in 0..<min(validTokenIds.count, 5) {
        let flatIndex = i * embeddingDimensions
        guard convertedTensor[flatIndex].int32Value == validTokenIds[i] else { 
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Token data should be preserved during conversion"]) 
        }
    }
}

// Test: testCreateFeatureProvider_withRank4Preference_returnsValidProvider
runTest("testCreateFeatureProvider_withRank4Preference_returnsValidProvider") {
    let validTokenIds: [Int32] = [1, 2, 3, 4, 5]
    let provider = try LFM2TensorRankFix.createFeatureProvider(tokenIds: validTokenIds, preferredRank: 4)
    
    guard provider.featureValue(for: "input_ids") != nil else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Feature provider should contain input_ids"]) }
    
    let inputTensor = provider.featureValue(for: "input_ids")?.multiArrayValue
    guard inputTensor != nil else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "input_ids should be MLMultiArray"]) }
    guard inputTensor?.shape.count == 4 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "MLMultiArray should have rank 4"]) }
}

// Test: testCreateFeatureProvider_withUnsupportedRank_throwsError
runTest("testCreateFeatureProvider_withUnsupportedRank_throwsError") {
    let validTokenIds: [Int32] = [1, 2, 3, 4, 5]
    
    do {
        _ = try LFM2TensorRankFix.createFeatureProvider(tokenIds: validTokenIds, preferredRank: 5)
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Should have thrown error"])
    } catch let error as LFM2TensorRankFix.LFM2TensorError {
        if case let .unsupportedRank(rank) = error {
            guard rank == 5 else { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected unsupported rank 5"]) }
        } else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected unsupportedRank error"])
        }
    } catch {
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected LFM2TensorError"])
    }
}

print(String(repeating: "=", count: 60))
print("🎯 GREEN PHASE RESULTS:")
print("✅ Tests Passed: \(testsPassed)/\(testsTotal)")
print("📊 Success Rate: \(Int(Double(testsPassed)/Double(testsTotal) * 100))%")

if testsPassed == testsTotal {
    print("🟢 ALL TESTS PASSING - GREEN PHASE COMPLETE!")
    print("🚀 Ready to proceed to /refactor phase")
} else {
    print("❌ Some tests still failing - GREEN phase incomplete")
    exit(1)
}