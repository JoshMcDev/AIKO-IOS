import Foundation

// MARK: - Search Template Models

public struct SearchTemplate: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let category: TemplateCategory
    public let keywords: [String]
    public let content: String

    public init(title: String, description: String, category: TemplateCategory, keywords: [String], content: String) {
        self.title = title
        self.description = description
        self.category = category
        self.keywords = keywords
        self.content = content
    }

    public static let sampleTemplates: [SearchTemplate] = [
        SearchTemplate(
            title: "Software Development RFP",
            description: "Request for Proposal template for custom software development projects",
            category: .technology,
            keywords: ["software", "development", "coding", "programming", "RFP"],
            content: "Standard RFP template for software development services..."
        ),
        SearchTemplate(
            title: "IT Services Statement of Work",
            description: "Comprehensive SOW template for IT service contracts",
            category: .technology,
            keywords: ["IT", "services", "SOW", "technology", "support"],
            content: "IT Services Statement of Work template..."
        ),
        SearchTemplate(
            title: "Professional Services Contract",
            description: "General template for professional services agreements",
            category: .services,
            keywords: ["professional", "services", "consulting", "contract"],
            content: "Professional services contract template..."
        ),
        SearchTemplate(
            title: "Supply Chain Management RFQ",
            description: "Request for Quote template for supply chain services",
            category: .logistics,
            keywords: ["supply", "chain", "logistics", "RFQ", "procurement"],
            content: "Supply chain management RFQ template..."
        ),
        SearchTemplate(
            title: "Security Clearance Requirements",
            description: "Template for specifying security clearance requirements",
            category: .security,
            keywords: ["security", "clearance", "classified", "requirements"],
            content: "Security clearance requirements template..."
        )
    ]
}

public enum TemplateCategory: String, CaseIterable, Sendable {
    case all = "All"
    case technology = "Technology"
    case services = "Services"
    case logistics = "Logistics"
    case security = "Security"
    case construction = "Construction"
    case research = "Research"
}
