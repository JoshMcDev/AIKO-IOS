import Foundation

/// Service responsible for validating FAR Part 53 compliance
final class FARValidationService {
    // MARK: - FAR Rules

    private let farRules: [FormType: [FARRule]] = [
        .sf18: [
            FARRule(
                ruleId: "FAR-53.213-1",
                description: "SF 18 shall be used for simplified acquisitions up to $250,000",
                validation: { data in
                    guard let amount = data["totalAmount"] as? Double else { return .failed("Total amount not specified") }
                    return amount <= 250_000 ? .passed : .failed("Amount exceeds $250,000 threshold for SF 18")
                }
            ),
            FARRule(
                ruleId: "FAR-53.213-2",
                description: "Delivery date must be specified",
                validation: { data in
                    data["deliveryDate"] != nil ? .passed : .failed("Delivery date is required")
                }
            ),
        ],

        .sf1449: [
            FARRule(
                ruleId: "FAR-53.212-1",
                description: "SF 1449 is for commercial items/services up to $7M",
                validation: { data in
                    guard let amount = data["totalAmount"] as? Double else { return .failed("Total amount not specified") }
                    return amount <= 7_000_000 ? .passed : .warning("Amount exceeds typical threshold for SF 1449")
                }
            ),
            FARRule(
                ruleId: "FAR-53.212-2",
                description: "Must include FAR 52.212-1 through 52.212-5 clauses",
                validation: { data in
                    let requiredClauses = ["52.212-1", "52.212-2", "52.212-3", "52.212-4", "52.212-5"]
                    guard let clauses = data["farClauses"] as? [String] else {
                        return .failed("FAR clauses not specified")
                    }
                    let missingClauses = requiredClauses.filter { !clauses.contains($0) }
                    return missingClauses.isEmpty ? .passed : .failed("Missing required clauses: \(missingClauses.joined(separator: ", "))")
                }
            ),
        ],

        .sf44: [
            FARRule(
                ruleId: "FAR-53.213-3",
                description: "SF 44 is for micro-purchases up to $10,000",
                validation: { data in
                    guard let amount = data["totalAmount"] as? Double else { return .failed("Total amount not specified") }
                    return amount <= 10000 ? .passed : .failed("Amount exceeds $10,000 micro-purchase threshold")
                }
            ),
            FARRule(
                ruleId: "FAR-53.213-4",
                description: "Payment must be made at time of purchase",
                validation: { data in
                    guard let paymentMethod = data["paymentMethod"] as? String else {
                        return .failed("Payment method not specified")
                    }
                    let validMethods = ["Government Purchase Card", "Cash", "Check"]
                    return validMethods.contains(paymentMethod) ? .passed : .failed("Invalid payment method for micro-purchase")
                }
            ),
        ],
    ]

    // MARK: - Public Methods

    /// Validate template data before mapping
    func validateTemplateData(_ templateData: TemplateData) async throws {
        var errors: [ValidationError] = []

        // Check required fields
        if templateData.data.isEmpty {
            errors.append(ValidationError(field: "data", message: "Template data cannot be empty"))
        }

        // Validate specific document types
        switch templateData.documentType {
        case .requestForQuoteSimplified, .requestForQuote:
            validateRFQData(templateData.data, errors: &errors)
        case .contractScaffold:
            validateContractData(templateData.data, errors: &errors)
        case .requestForProposal:
            validateRFPData(templateData.data, errors: &errors)
        default:
            break
        }

        if !errors.isEmpty {
            throw FormMappingError.validationFailed(errors)
        }
    }

    /// Validate FAR compliance for form data
    func validateFARCompliance(
        formData: [String: Any],
        formType: FormType
    ) async throws -> FormComplianceResult {
        let rules = farRules[formType] ?? []
        var results: [RuleResult] = []

        for rule in rules {
            let result = rule.validation(formData)
            results.append(RuleResult(
                ruleId: rule.ruleId,
                description: rule.description,
                status: result
            ))
        }

        // Additional cross-form validations
        results.append(contentsOf: performCrossFormValidations(formData, formType: formType))

        let failedRules = results.filter(\.status.isFailed)
        let warnings = results.filter(\.status.isWarning)

        return FormComplianceResult(
            formType: formType,
            ruleResults: results,
            overallCompliance: failedRules.isEmpty,
            failedRules: failedRules.count,
            warnings: warnings.count,
            validatedAt: Date()
        )
    }

    /// Get applicable FAR rules for a form type
    func getApplicableRules(for formType: FormType) -> [FARRule] {
        farRules[formType] ?? []
    }

    // MARK: - Private Methods

    private func validateRFQData(_ data: [String: Any], errors: inout [ValidationError]) {
        if data["projectTitle"] == nil {
            errors.append(ValidationError(field: "projectTitle", message: "Project title is required for RFQ"))
        }

        if let deliveryDate = data["deliveryDate"] as? Date {
            if deliveryDate < Date() {
                errors.append(ValidationError(field: "deliveryDate", message: "Delivery date cannot be in the past"))
            }
        } else {
            errors.append(ValidationError(field: "deliveryDate", message: "Delivery date is required"))
        }

        if let quantity = data["quantity"] as? Int, quantity <= 0 {
            errors.append(ValidationError(field: "quantity", message: "Quantity must be greater than zero"))
        }
    }

    private func validateContractData(_ data: [String: Any], errors: inout [ValidationError]) {
        if data["contractNumber"] == nil {
            errors.append(ValidationError(field: "contractNumber", message: "Contract number is required"))
        }

        if data["contractor"] == nil {
            errors.append(ValidationError(field: "contractor", message: "Contractor information is required"))
        }

        if let totalValue = data["totalValue"] as? Double, totalValue <= 0 {
            errors.append(ValidationError(field: "totalValue", message: "Total value must be greater than zero"))
        }
    }

    private func validateRFPData(_ data: [String: Any], errors: inout [ValidationError]) {
        if data["solicitationNumber"] == nil {
            errors.append(ValidationError(field: "solicitationNumber", message: "Solicitation number is required"))
        }

        if let dueDate = data["dueDate"] as? Date {
            let minimumLeadTime = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
            if dueDate < minimumLeadTime {
                errors.append(ValidationError(field: "dueDate", message: "RFP due date must be at least 15 days from today"))
            }
        }
    }

    private func performCrossFormValidations(_ data: [String: Any], formType _: FormType) -> [RuleResult] {
        var results: [RuleResult] = []

        // Validate NAICS code if present
        if let naicsCode = data["naicsCode"] as? String {
            let validNAICS = validateNAICSCode(naicsCode)
            results.append(RuleResult(
                ruleId: "CROSS-1",
                description: "Valid NAICS code",
                status: validNAICS ? .passed : .failed("Invalid NAICS code format")
            ))
        }

        // Validate DUNS/UEI if present
        if let uei = data["uei"] as? String {
            let validUEI = validateUEI(uei)
            results.append(RuleResult(
                ruleId: "CROSS-2",
                description: "Valid UEI",
                status: validUEI ? .passed : .failed("Invalid UEI format")
            ))
        }

        return results
    }

    private func validateNAICSCode(_ code: String) -> Bool {
        // NAICS codes are 6 digits
        let pattern = "^\\d{6}$"
        return code.range(of: pattern, options: .regularExpression) != nil
    }

    private func validateUEI(_ uei: String) -> Bool {
        // UEI is 12 alphanumeric characters
        let pattern = "^[A-Z0-9]{12}$"
        return uei.uppercased().range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Supporting Types

struct FARRule {
    let ruleId: String
    let description: String
    let validation: ([String: Any]) -> ValidationStatus
}

public enum ValidationStatus {
    case passed
    case warning(String)
    case failed(String)

    public var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    public var isWarning: Bool {
        if case .warning = self { return true }
        return false
    }
}

public struct RuleResult {
    public let ruleId: String
    public let description: String
    public let status: ValidationStatus
}

public struct FormComplianceResult {
    public let formType: FormType
    public let ruleResults: [RuleResult]
    public let overallCompliance: Bool
    public let failedRules: Int
    public let warnings: Int
    public let validatedAt: Date
}

public struct ValidationError: Error {
    public let field: String
    public let message: String

    public var description: String {
        "\(field): \(message)"
    }
}
