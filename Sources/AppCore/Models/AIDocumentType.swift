import Foundation

/// AI-specific document types for Core Engines
/// Maps to government forms in Sources/Resources/Forms/
public enum AIDocumentType: String, CaseIterable, Codable, Sendable {
    case sf1449 = "SF-1449" // Contract
    case sf18 = "SF-18" // Request for Quotations
    case sf26 = "SF-26" // Award/Contract
    case sf30 = "SF-30" // Amendment of Solicitation/Modification
    case sf33 = "SF-33" // Solicitation, Offer and Award
    case sf44 = "SF-44" // Purchase Order-Invoice-Voucher
    case dd1155 = "DD-1155" // Order for Supplies or Services

    public var displayName: String {
        switch self {
        case .sf1449:
            "Contract (SF-1449)"
        case .sf18:
            "Request for Quotations (SF-18)"
        case .sf26:
            "Award/Contract (SF-26)"
        case .sf30:
            "Amendment of Solicitation/Modification (SF-30)"
        case .sf33:
            "Solicitation, Offer and Award (SF-33)"
        case .sf44:
            "Purchase Order-Invoice-Voucher (SF-44)"
        case .dd1155:
            "Order for Supplies or Services (DD-1155)"
        }
    }

    public var formPath: String {
        switch self {
        case .sf1449:
            "Sources/Resources/Forms/SF1449_Form.md"
        case .sf18:
            "Sources/Resources/Forms/SF18_Form.md"
        case .sf26:
            "Sources/Resources/Forms/SF26_Form.md"
        case .sf30:
            "Sources/Resources/Forms/SF30_Form.md"
        case .sf33:
            "Sources/Resources/Forms/SF33_Form.md"
        case .sf44:
            "Sources/Resources/Forms/SF44_Form.md"
        case .dd1155:
            "Sources/Resources/Forms/DD1155_Form.md"
        }
    }
}

/// AI-specific generated document with metadata
public struct AIGeneratedDocument: Sendable {
    public let type: AIDocumentType
    public let content: String
    public let metadata: AIDocumentMetadata?

    public init(type: AIDocumentType, content: String, metadata: AIDocumentMetadata? = nil) {
        self.type = type
        self.content = content
        self.metadata = metadata
    }
}

/// AI document metadata
public struct AIDocumentMetadata: Sendable {
    public let createdAt: Date
    public let generatedBy: String
    public let version: String
    public let tokens: Int?
    public let provider: String?

    public init(createdAt: Date, generatedBy: String, version: String, tokens: Int? = nil, provider: String? = nil) {
        self.createdAt = createdAt
        self.generatedBy = generatedBy
        self.version = version
        self.tokens = tokens
        self.provider = provider
    }
}

// LLMProvider and PromptPattern are defined in LLMProviderProtocol.swift
