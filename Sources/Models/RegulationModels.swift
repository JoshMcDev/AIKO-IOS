import AppCore
import Foundation

// MARK: - Shared Regulation Models

// Consolidated models to avoid duplicate definitions

public struct RegulationContent: Equatable {
    public let type: RegulationType
    public let content: String
    public let lastModified: Date
    public let version: String

    public init(type: RegulationType, content: String, lastModified: Date, version: String) {
        self.type = type
        self.content = content
        self.lastModified = lastModified
        self.version = version
    }
}

public struct RegulationUpdate: Equatable {
    public let regulation: RegulationType
    public let changeType: ChangeType
    public let effectiveDate: Date
    public let description: String

    public enum ChangeType: String, Equatable {
        case newRule = "New Rule"
        case amendment = "Amendment"
        case deletion = "Deletion"
        case clarification = "Clarification"
    }

    public init(regulation: RegulationType, changeType: ChangeType, effectiveDate: Date, description: String) {
        self.regulation = regulation
        self.changeType = changeType
        self.effectiveDate = effectiveDate
        self.description = description
    }
}

public struct RegulationSearchResult: Equatable {
    public let regulation: RegulationType
    public let section: String
    public let title: String
    public let snippet: String
    public let relevanceScore: Double

    public init(regulation: RegulationType, section: String, title: String, snippet: String, relevanceScore: Double) {
        self.regulation = regulation
        self.section = section
        self.title = title
        self.snippet = snippet
        self.relevanceScore = relevanceScore
    }
}

// Context7-specific search result for differentiation
public struct Context7SearchResult: Identifiable, Equatable {
    public let id = UUID()
    public let regulation: String
    public let clause: String
    public let title: String
    public let content: String
    public let relevanceScore: Double
    public let lastUpdated: Date
    public let relatedDocumentTypes: [DocumentType]

    public init(regulation: String, clause: String, title: String, content: String, relevanceScore: Double, lastUpdated: Date, relatedDocumentTypes: [DocumentType]) {
        self.regulation = regulation
        self.clause = clause
        self.title = title
        self.content = content
        self.relevanceScore = relevanceScore
        self.lastUpdated = lastUpdated
        self.relatedDocumentTypes = relatedDocumentTypes
    }
}
