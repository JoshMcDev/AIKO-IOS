import Foundation

/// Protocol for form factories
public protocol FormFactory {
    associatedtype FormType: GovernmentForm
    
    /// Create a new form instance
    func create(with data: FormData) throws -> FormType
    
    /// Create a blank form
    func createBlank() -> FormType
    
    /// Validate form data before creation
    func validate(_ data: FormData) throws
}

/// Base factory implementation
open class BaseFormFactory<T: GovernmentForm>: FormFactory {
    public typealias FormType = T
    
    public init() {}
    
    open func create(with data: FormData) throws -> T {
        try validate(data)
        return try createForm(with: data)
    }
    
    open func createBlank() -> T {
        fatalError("Subclasses must implement createBlank()")
    }
    
    open func validate(_ data: FormData) throws {
        // Base validation - subclasses can override for specific validation
        guard !data.formNumber.isEmpty else {
            throw FormError.missingFormNumber
        }
    }
    
    /// Template method for subclasses to implement
    open func createForm(with data: FormData) throws -> T {
        fatalError("Subclasses must implement createForm(with:)")
    }
}

/// Form data container
public struct FormData: Codable {
    public let formNumber: String
    public let revision: String?
    public let fields: [String: String] // Changed from Any to String for Codable conformance
    public let metadata: FormMetadata
    
    public init(
        formNumber: String,
        revision: String? = nil,
        fields: [String: String] = [:],
        metadata: FormMetadata
    ) {
        self.formNumber = formNumber
        self.revision = revision
        self.fields = fields
        self.metadata = metadata
    }
}

/// Form metadata
public struct FormMetadata: Codable {
    public let createdBy: String
    public let createdDate: Date
    public let agency: String
    public let purpose: String
    public let authority: String?
    
    public init(
        createdBy: String,
        createdDate: Date = Date(),
        agency: String,
        purpose: String,
        authority: String? = nil
    ) {
        self.createdBy = createdBy
        self.createdDate = createdDate
        self.agency = agency
        self.purpose = purpose
        self.authority = authority
    }
}

/// Form errors
public enum FormError: LocalizedError {
    case missingFormNumber
    case invalidField(String)
    case missingRequiredField(String)
    case validationFailed(String)
    case unsupportedFormType
    
    public var errorDescription: String? {
        switch self {
        case .missingFormNumber:
            return "Form number is required"
        case .invalidField(let field):
            return "Invalid field: \(field)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .unsupportedFormType:
            return "Unsupported form type"
        }
    }
}

/// Factory registry for all form types
public final class FormFactoryRegistry {
    public static let shared = FormFactoryRegistry()
    
    private var factories: [String: any FormFactory] = [:]
    
    private init() {
        registerDefaultFactories()
    }
    
    /// Register a factory for a form type
    public func register<F: FormFactory>(_ factory: F, for formNumber: String) {
        factories[formNumber] = factory
    }
    
    /// Get factory for a form number
    public func factory(for formNumber: String) -> (any FormFactory)? {
        factories[formNumber]
    }
    
    /// Create a form using the appropriate factory
    public func createForm(with data: FormData) throws -> any GovernmentForm {
        guard let factory = factories[data.formNumber] else {
            throw FormError.unsupportedFormType
        }
        
        // Type-erased creation
        if let sf1449Factory = factory as? SF1449Factory {
            return try sf1449Factory.create(with: data)
        } else if let sf33Factory = factory as? SF33Factory {
            return try sf33Factory.create(with: data)
        } else if let sf30Factory = factory as? SF30Factory {
            return try sf30Factory.create(with: data)
        } else if let sf18Factory = factory as? SF18Factory {
            return try sf18Factory.create(with: data)
        } else if let sf26Factory = factory as? SF26Factory {
            return try sf26Factory.create(with: data)
        } else if let sf44Factory = factory as? SF44Factory {
            return try sf44Factory.create(with: data)
        } else if let dd1155Factory = factory as? DD1155Factory {
            return try dd1155Factory.create(with: data)
        }
        
        throw FormError.unsupportedFormType
    }
    
    private func registerDefaultFactories() {
        // Register standard form factories
        register(SF1449Factory(), for: "SF1449")
        register(SF33Factory(), for: "SF33")
        register(SF30Factory(), for: "SF30")
        register(SF18Factory(), for: "SF18")
        register(SF26Factory(), for: "SF26")
        register(SF44Factory(), for: "SF44")
        register(DD1155Factory(), for: "DD1155")
    }
}