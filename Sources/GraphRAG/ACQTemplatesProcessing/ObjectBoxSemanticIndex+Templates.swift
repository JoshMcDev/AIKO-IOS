import Foundation
import os.log

// Type alias for ObjectBox ID when ObjectBox is not available
#if !canImport(ObjectBox)
typealias ObjectBoxID = Int64
#endif

/// Extensions to ObjectBoxSemanticIndex for template processing support
extension ObjectBoxSemanticIndex {
    /// Store template embedding with memory-mapped storage support
    func storeTemplateEmbedding(content: String, embedding: [Float], metadata: TemplateMetadata) async throws {
        let logger = Logger(subsystem: "com.aiko.graphrag", category: "ObjectBoxSemanticIndex+Templates")

        guard embedding.count == 384 else {
            throw NSError(domain: "ObjectBoxSemanticIndexError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Embedding must be 384-dimensional for templates"])
        }

        logger.debug("Storing template embedding: \(metadata.templateID), content length: \(content.count)")

        #if canImport(ObjectBox)
            try await withCheckedThrowingContinuation { continuation in
                Task {
                    do {
                        // Convert to template-specific embedding format
                        let templateEmbedding = TemplateEmbedding()
                        templateEmbedding.content = content
                        templateEmbedding.embedding = embedding.withUnsafeBytes { Data($0) }
                        templateEmbedding.templateID = metadata.templateID
                        templateEmbedding.fileName = metadata.fileName
                        templateEmbedding.fileType = metadata.fileType
                        templateEmbedding.category = metadata.category?.rawValue ?? "Unknown"
                        templateEmbedding.agency = metadata.agency ?? ""
                        templateEmbedding.effectiveDate = metadata.effectiveDate ?? Date()
                        templateEmbedding.lastModified = metadata.lastModified
                        templateEmbedding.fileSize = metadata.fileSize
                        templateEmbedding.checksum = metadata.checksum
                        templateEmbedding.timestamp = Date()

                        // Store using existing ObjectBox infrastructure
                        if let store = self.store {
                            let box = store.box(for: TemplateEmbedding.self)
                            _ = try box.put(templateEmbedding)
                        }

                        continuation.resume()

                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        #else
            // Mock implementation for testing
            logger.debug("Mock implementation - template embedding stored")
        #endif
    }

    /// Get stored embedding for template
    func getStoredEmbedding(for templateID: String) async throws -> [Float]? {
        _ = Logger(subsystem: "com.aiko.graphrag", category: "ObjectBoxSemanticIndex+Templates")

        #if canImport(ObjectBox)
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    do {
                        if let store = self.store {
                            let box = store.box(for: TemplateEmbedding.self)
                            let query = box.query { TemplateEmbedding.templateID == templateID }
                            let results = try query.find()

                            if let result = results.first {
                                let embedding = result.getEmbeddingVector()
                                continuation.resume(returning: embedding)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        } else {
                            continuation.resume(returning: nil)
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        #else
            // Mock implementation returns nil to trigger generation
            return nil
        #endif
    }

    /// Memory-mapped storage for large template embeddings
    func storeMemoryMappedEmbedding(templateID: String, embedding: [Float], filePath: String) async throws {
        let logger = Logger(subsystem: "com.aiko.graphrag", category: "ObjectBoxSemanticIndex+Templates")

        logger.debug("Storing memory-mapped embedding for template: \(templateID)")

        // Write embedding to memory-mapped file
        let embeddingData = embedding.withUnsafeBytes { Data($0) }
        let url = URL(fileURLWithPath: filePath)

        try embeddingData.write(to: url)

        // Store reference in ObjectBox
        try await storeEmbeddingReference(templateID: templateID, filePath: filePath)

        logger.debug("Memory-mapped embedding stored at: \(filePath)")
    }

    private func storeEmbeddingReference(templateID: String, filePath: String) async throws {
        #if canImport(ObjectBox)
            if let store {
                let reference = TemplateEmbeddingReference()
                reference.templateID = templateID
                reference.filePath = filePath
                reference.timestamp = Date()

                let box = store.box(for: TemplateEmbeddingReference.self)
                _ = try box.put(reference)
            }
        #endif
    }
}

// MARK: - Template-Specific Entity Models

#if canImport(ObjectBox)
    // objectbox:Entity
    class TemplateEmbedding {
        // MARK: Lifecycle

        required init() {
            id = 0
            content = ""
            embedding = Data()
            templateID = ""
            fileName = ""
            fileType = ""
            category = ""
            agency = ""
            effectiveDate = Date()
            lastModified = Date()
            fileSize = 0
            checksum = ""
            timestamp = Date()
        }

        // MARK: Internal

        var id: ID
        var content: String
        var embedding: Data
        var templateID: String
        var fileName: String
        var fileType: String
        var category: String
        var agency: String
        var effectiveDate: Date
        var lastModified: Date
        var fileSize: Int64
        var checksum: String
        var timestamp: Date

        func getEmbeddingVector() -> [Float] {
            embedding.withUnsafeBytes { bytes in
                let floatBuffer = bytes.bindMemory(to: Float.self)
                return Array(floatBuffer)
            }
        }
    }

    // objectbox:Entity
    class TemplateEmbeddingReference {
        // MARK: Lifecycle

        required init() {
            id = 0
            templateID = ""
            filePath = ""
            timestamp = Date()
        }

        // MARK: Internal

        var id: ID
        var templateID: String
        var filePath: String
        var timestamp: Date
    }

#else
    /// Mock implementations for testing
    class TemplateEmbedding {
        // MARK: Lifecycle

        required init() {}

        // MARK: Internal

        var id: ObjectBoxID = 0
        var content: String = ""
        var embedding: Data = .init()
        var templateID: String = ""
        var fileName: String = ""
        var fileType: String = ""
        var category: String = ""
        var agency: String = ""
        var effectiveDate: Date = .init()
        var lastModified: Date = .init()
        var fileSize: Int64 = 0
        var checksum: String = ""
        var timestamp: Date = .init()

        func getEmbeddingVector() -> [Float] {
            embedding.withUnsafeBytes { bytes in
                let floatBuffer = bytes.bindMemory(to: Float.self)
                return Array(floatBuffer)
            }
        }
    }

    class TemplateEmbeddingReference {
        // MARK: Lifecycle

        required init() {}

        // MARK: Internal

        var id: ObjectBoxID = 0
        var templateID: String = ""
        var filePath: String = ""
        var timestamp: Date = .init()
    }
#endif
