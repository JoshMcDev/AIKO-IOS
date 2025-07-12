import Foundation
import Combine

/// Service responsible for mapping AIKO templates to official government forms
public final class FormMappingService: ObservableObject {
    // MARK: - Singleton
    public static let shared = FormMappingService()
    
    // MARK: - Published Properties
    @Published public private(set) var availableForms: [FormDefinition] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: FormMappingError?
    
    // MARK: - Private Properties
    private let formRepository: FormRepository
    private let mappingEngine: MappingEngine
    private let validationService: FARValidationService
    private let transformationService: DataTransformationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        self.formRepository = FormRepository()
        self.mappingEngine = MappingEngine()
        self.validationService = FARValidationService()
        self.transformationService = DataTransformationService()
        
        loadAvailableForms()
    }
    
    // MARK: - Public Methods
    
    /// Get available forms for a specific template type
    public func getFormsForTemplate(_ templateType: DocumentType) -> [FormDefinition] {
        return availableForms.filter { form in
            form.supportedTemplates.contains(templateType)
        }
    }
    
    /// Map template data to a specific form
    public func mapTemplateToForm(
        templateData: TemplateData,
        formType: FormType,
        options: MappingOptions = MappingOptions()
    ) async throws -> FormOutput {
        isLoading = true
        error = nil
        
        do {
            // 1. Validate template data
            try await validationService.validateTemplateData(templateData)
            
            // 2. Get form definition
            guard let formDefinition = availableForms.first(where: { $0.formType == formType }) else {
                throw FormMappingError.formNotFound(formType)
            }
            
            // 3. Perform mapping
            let mappingRules = try await mappingEngine.getMappingRules(
                from: templateData.documentType,
                to: formType
            )
            
            // 4. Transform data
            let transformedData = try await transformationService.transform(
                templateData: templateData,
                using: mappingRules,
                targetForm: formDefinition
            )
            
            // 5. Validate FAR compliance
            let complianceResult = try await validationService.validateFARCompliance(
                formData: transformedData,
                formType: formType
            )
            
            // 6. Generate output
            let output = FormOutput(
                formType: formType,
                formData: transformedData,
                complianceStatus: complianceResult,
                generatedAt: Date()
            )
            
            isLoading = false
            return output
            
        } catch let mappingError as FormMappingError {
            error = mappingError
            isLoading = false
            throw mappingError
        } catch {
            let mappingError = FormMappingError.unknown(error)
            self.error = mappingError
            isLoading = false
            throw mappingError
        }
    }
    
    /// Generate a blank form for download
    public func generateBlankForm(_ formType: FormType) async throws -> Data {
        guard let formDefinition = availableForms.first(where: { $0.formType == formType }) else {
            throw FormMappingError.formNotFound(formType)
        }
        
        return try await formRepository.generateBlankForm(formDefinition)
    }
    
    /// Get form preview URL
    public func getFormPreviewURL(_ formType: FormType) -> URL? {
        return formRepository.getPreviewURL(for: formType)
    }
    
    // MARK: - Private Methods
    
    private func loadAvailableForms() {
        Task {
            do {
                availableForms = try await formRepository.loadFormDefinitions()
            } catch {
                self.error = FormMappingError.loadingFailed(error)
            }
        }
    }
}

// MARK: - Supporting Types

public enum FormMappingError: LocalizedError {
    case formNotFound(FormType)
    case invalidTemplateData(String)
    case mappingFailed(String)
    case validationFailed([ValidationError])
    case loadingFailed(Error)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .formNotFound(let formType):
            return "Form type \(formType.rawValue) not found"
        case .invalidTemplateData(let reason):
            return "Invalid template data: \(reason)"
        case .mappingFailed(let reason):
            return "Mapping failed: \(reason)"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.map { $0.description }.joined(separator: ", "))"
        case .loadingFailed(let error):
            return "Failed to load forms: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

public struct MappingOptions {
    public var includeOptionalFields: Bool = true
    public var strictValidation: Bool = true
    public var autoFillDefaults: Bool = true
    public var preserveOriginalData: Bool = false
    
    public init() {}
}

public struct FormOutput {
    public let formType: FormType
    public let formData: [String: Any]
    public let complianceStatus: FormComplianceResult
    public let generatedAt: Date
    
    public var isCompliant: Bool {
        complianceStatus.overallCompliance
    }
}