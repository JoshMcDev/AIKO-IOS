import AppCore
import Combine
import Foundation

/// Service responsible for mapping AIKO templates to official government forms
public actor FormMappingService {
    // MARK: - Singleton

    public static let shared = FormMappingService()

    // MARK: - Properties

    private var availableForms: [FormDefinition] = []
    private var isLoading = false
    private var error: FormMappingError?

    // MARK: - Private Properties

    private let formRepository: FormRepository
    private let mappingEngine: MappingEngine
    private let validationService: FARValidationService
    private let transformationService: DataTransformationService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        formRepository = FormRepository()
        mappingEngine = MappingEngine()
        validationService = FARValidationService()
        transformationService = DataTransformationService()

        // Load forms asynchronously
        Task {
            await loadAvailableForms()
        }
    }

    // MARK: - Public Methods

    /// Get available forms for a specific template type
    public func getFormsForTemplate(_ templateType: DocumentType) -> [FormDefinition] {
        availableForms.filter { form in
            form.supportedTemplates.contains(templateType)
        }
    }

    /// Map template data to a specific form
    public func mapTemplateToForm(
        templateData: TemplateData,
        formType: FormType,
        options _: MappingOptions = MappingOptions()
    ) async throws -> FormOutput {
        isLoading = true
        error = nil

        do {
            // 1. Validate template data
            nonisolated(unsafe) let validator = validationService
            nonisolated(unsafe) let data = templateData
            try await validator.validateTemplateData(data)

            // 2. Get form definition
            guard let formDefinition = availableForms.first(where: { $0.formType == formType }) else {
                throw FormMappingError.formNotFound(formType)
            }

            // 3. Perform mapping
            nonisolated(unsafe) let engine = mappingEngine
            let mappingRules = try await engine.getMappingRules(
                from: data.documentType,
                to: formType
            )

            // 4. Transform data
            nonisolated(unsafe) let transformer = transformationService
            let transformedData = try await transformer.transform(
                templateData: data,
                using: mappingRules,
                targetForm: formDefinition
            )

            // 5. Validate FAR compliance
            let complianceResult = try await validator.validateFARCompliance(
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

        nonisolated(unsafe) let repository = formRepository
        return try await repository.generateBlankForm(formDefinition)
    }

    /// Get form preview URL
    public func getFormPreviewURL(_ formType: FormType) -> URL? {
        formRepository.getPreviewURL(for: formType)
    }

    // MARK: - Private Methods

    private func loadAvailableForms() async {
        do {
            nonisolated(unsafe) let repository = formRepository
            availableForms = try await repository.loadFormDefinitions()
        } catch {
            self.error = FormMappingError.loadingFailed(error)
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
        case let .formNotFound(formType):
            "Form type \(formType.rawValue) not found"
        case let .invalidTemplateData(reason):
            "Invalid template data: \(reason)"
        case let .mappingFailed(reason):
            "Mapping failed: \(reason)"
        case let .validationFailed(errors):
            "Validation failed: \(errors.map(\.description).joined(separator: ", "))"
        case let .loadingFailed(error):
            "Failed to load forms: \(error.localizedDescription)"
        case let .unknown(error):
            "Unknown error: \(error.localizedDescription)"
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
    public let formData: [String: String]
    public let complianceStatus: FormComplianceResult
    public let generatedAt: Date

    public var isCompliant: Bool {
        complianceStatus.overallCompliance
    }
}
