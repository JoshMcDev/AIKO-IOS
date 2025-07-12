import Foundation
import ComposableArchitecture

public enum DFTemplateError: Error {
    case bundleNotFound
    case templateNotFound(String)
    case guideNotFound(String)
}

public struct DFTemplate {
    public let type: DFDocumentType
    public let template: String
    public let quickReferenceGuide: String
    
    public init(type: DFDocumentType, template: String, quickReferenceGuide: String) {
        self.type = type
        self.template = template
        self.quickReferenceGuide = quickReferenceGuide
    }
}

public struct DFTemplateService {
    public var loadTemplate: (DFDocumentType) async throws -> DFTemplate
    public var loadAllTemplates: () async throws -> [DFTemplate]
    
    public init(
        loadTemplate: @escaping (DFDocumentType) async throws -> DFTemplate,
        loadAllTemplates: @escaping () async throws -> [DFTemplate]
    ) {
        self.loadTemplate = loadTemplate
        self.loadAllTemplates = loadAllTemplates
    }
}

extension DFTemplateService: DependencyKey {
    public static var liveValue: DFTemplateService {
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
                let guideFileName: String
                switch documentType {
                case .lptaDetermination:
                    guideFileName = "LPTA_Quick_Reference_Guide"
                    
                case .emergencyUrgentCompelling:
                    guideFileName = "Emergency_Urgent_Quick_Reference_Guide"
                    
                case .jaOtherThanFullOpenCompetition:
                    guideFileName = "JA_Quick_Reference_Guide"
                    
                default:
                    guideFileName = "\(documentType.fileName)_Quick_Reference_Guide"
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
    
    public static var testValue: DFTemplateService {
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

public extension DependencyValues {
    var dfTemplateService: DFTemplateService {
        get { self[DFTemplateService.self] }
        set { self[DFTemplateService.self] = newValue }
    }
}