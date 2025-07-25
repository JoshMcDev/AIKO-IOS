import AppCore
import Foundation

public enum DFTemplateError: Error {
    case bundleNotFound
    case templateNotFound(String)
    case guideNotFound(String)
}

public struct DFTemplate: Sendable {
    public let type: DFDocumentType
    public let template: String
    public let quickReferenceGuide: String

    public init(type: DFDocumentType, template: String, quickReferenceGuide: String) {
        self.type = type
        self.template = template
        self.quickReferenceGuide = quickReferenceGuide
    }
}

public struct DFTemplateService: Sendable {
    public var loadTemplate: @Sendable (DFDocumentType) async throws -> DFTemplate
    public var loadAllTemplates: @Sendable () async throws -> [DFTemplate]

    public init(
        loadTemplate: @escaping @Sendable (DFDocumentType) async throws -> DFTemplate,
        loadAllTemplates: @escaping @Sendable () async throws -> [DFTemplate]
    ) {
        self.loadTemplate = loadTemplate
        self.loadAllTemplates = loadAllTemplates
    }
}

public extension DFTemplateService {
    static var liveValue: DFTemplateService {
        DFTemplateService(
            loadTemplate: { documentType in
                // Load from app bundle
                let bundle = Bundle.module

                // Load template
                let templateFileName = "\(documentType.fileName)"
                guard let templateURL = bundle.url(forResource: templateFileName, withExtension: "md", subdirectory: "DFTemplates") else {
                    throw DFTemplateError.templateNotFound(documentType.rawValue)
                }
                let templateContent = try String(contentsOf: templateURL, encoding: .utf8)

                // Load quick reference guide
                let guideContent: String

                // Handle special cases for different naming conventions
                let guideFileName = switch documentType {
                case .lptaDetermination:
                    "LPTA_Quick_Reference_Guide"

                case .emergencyUrgentCompelling:
                    "Emergency_Urgent_Quick_Reference_Guide"

                case .jaOtherThanFullOpenCompetition:
                    "JA_Quick_Reference_Guide"

                default:
                    "\(documentType.fileName)_Quick_Reference_Guide"
                }

                guard let guideURL = bundle.url(forResource: guideFileName, withExtension: "md", subdirectory: "DFTemplates") else {
                    throw DFTemplateError.guideNotFound(documentType.rawValue)
                }
                guideContent = try String(contentsOf: guideURL, encoding: .utf8)

                return DFTemplate(
                    type: documentType,
                    template: templateContent,
                    quickReferenceGuide: guideContent
                )
            },
            loadAllTemplates: {
                var templates: [DFTemplate] = []

                for documentType in DFDocumentType.allCases {
                    do {
                        let template = try await DFTemplateService.liveValue.loadTemplate(documentType)
                        templates.append(template)
                    } catch {
                        print("Failed to load template for \(documentType.rawValue): \(error)")
                    }
                }

                return templates
            }
        )
    }

    static var testValue: DFTemplateService {
        DFTemplateService(
            loadTemplate: { documentType in
                DFTemplate(
                    type: documentType,
                    template: "Test template content for \(documentType.rawValue)",
                    quickReferenceGuide: "Test guide content for \(documentType.rawValue)"
                )
            },
            loadAllTemplates: {
                DFDocumentType.allCases.map { type in
                    DFTemplate(
                        type: type,
                        template: "Test template content for \(type.rawValue)",
                        quickReferenceGuide: "Test guide content for \(type.rawValue)"
                    )
                }
            }
        )
    }
}
