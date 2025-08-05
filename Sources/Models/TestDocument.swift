import Foundation

/// Test Document type for compliance testing
/// This is used across both test and implementation code for consistency
public struct TestDocument: Sendable {
    public let id: UUID
    public let content: String
    public let complexity: DocumentComplexity
    public let testId: Int

    public init(
        id: UUID = UUID(),
        content: String,
        complexity: DocumentComplexity,
        testId: Int
    ) {
        self.id = id
        self.content = content
        self.complexity = complexity
        self.testId = testId
    }

    public func withIncrementalChange(at location: DocumentLocation) -> TestDocument {
        TestDocument(
            id: id,
            content: content + " [MODIFIED_AT_\(location)]",
            complexity: complexity,
            testId: testId
        )
    }

    public func withModification(at location: DocumentLocation) -> TestDocument {
        withIncrementalChange(at: location)
    }
}

public enum DocumentComplexity: Sendable {
    case low, medium, high, large
}

public enum DocumentLocation: Sendable, Equatable {
    case section(Int)
    case paragraph(Int)
}

// RED PHASE MARKER: This implementation supports the RED phase of TDD
