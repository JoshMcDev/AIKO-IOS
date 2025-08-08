import Foundation

/// Array extensions for batch processing support across the Regulation Processing Pipeline
extension Array {
    /// Splits the array into chunks of specified size
    /// Used by multiple components including LFM2Service, GraphRAGRegulationStorage, and batch processors
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

/// Collection extension for chunking support
extension Collection {
    /// Splits the collection into chunks of specified size
    /// Provides chunking functionality for any Collection type
    func chunked(into size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        var currentChunk: [Element] = []

        for element in self {
            currentChunk.append(element)

            if currentChunk.count == size {
                chunks.append(currentChunk)
                currentChunk = []
            }
        }

        // Add remaining elements if any
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks
    }
}
