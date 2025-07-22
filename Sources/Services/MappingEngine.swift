import AppCore
import Foundation

/// Engine responsible for mapping template fields to form fields
final class MappingEngine: @unchecked Sendable {
    // MARK: - Mapping Rules

    private let mappingRules: [DocumentType: [FormType: MappingRuleSet]] = [
        // RFQ Simplified to SF 18
        .requestForQuoteSimplified: [
            .sf18: MappingRuleSet(
                rules: [
                    MappingRule(
                        sourceField: "projectTitle",
                        targetField: "itemDescription",
                        transformation: .direct
                    ),
                    MappingRule(
                        sourceField: "deliveryDate",
                        targetField: "deliveryDate",
                        transformation: .dateFormat("MM/dd/yyyy")
                    ),
                    MappingRule(
                        sourceField: "quantity",
                        targetField: "quantity",
                        transformation: .direct
                    ),
                    MappingRule(
                        sourceField: "estimatedValue",
                        targetField: "unitPrice",
                        transformation: .currency
                    ),
                    MappingRule(
                        sourceField: "requisitionNumber",
                        targetField: "requisitionNumber",
                        transformation: .direct
                    ),
                ],
                defaultValues: [
                    "unit": "EA",
                    "fob": "Destination",
                    "discountTerms": "NET 30",
                ]
            ),
        ],

        // Contract to SF 1449
        .contractScaffold: [
            .sf1449: MappingRuleSet(
                rules: [
                    MappingRule(
                        sourceField: "contractNumber",
                        targetField: "contractNumber",
                        transformation: .direct
                    ),
                    MappingRule(
                        sourceField: "solicitationNumber",
                        targetField: "solicitationNumber",
                        transformation: .direct
                    ),
                    MappingRule(
                        sourceField: "contractor.name",
                        targetField: "contractorName",
                        transformation: .direct
                    ),
                    MappingRule(
                        sourceField: "contractor.address",
                        targetField: "contractorAddress",
                        transformation: .addressFormat
                    ),
                    MappingRule(
                        sourceField: "totalValue",
                        targetField: "totalPrice",
                        transformation: .currency
                    ),
                    MappingRule(
                        sourceField: "items",
                        targetField: "lineItems",
                        transformation: .array { item in
                            [
                                "itemNumber": item["number"] ?? "",
                                "description": item["description"] ?? "",
                                "quantity": item["quantity"] ?? 0,
                                "unitPrice": item["unitPrice"] ?? 0,
                                "totalPrice": item["totalPrice"] ?? 0,
                            ]
                        }
                    ),
                ],
                defaultValues: [
                    "deliveryTerms": "F.O.B. DESTINATION",
                    "paymentTerms": "NET 30 DAYS",
                    "inspectionTerms": "DESTINATION",
                ]
            ),
        ],

        // RFP to SF 1449
        .requestForProposal: [
            .sf1449: MappingRuleSet(
                rules: [
                    MappingRule(
                        sourceField: "solicitationNumber",
                        targetField: "solicitationNumber",
                        transformation: .direct
                    ),
                    MappingRule(
                        sourceField: "title",
                        targetField: "itemDescription",
                        transformation: .direct
                    ),
                    MappingRule(
                        sourceField: "dueDate",
                        targetField: "offerDueDate",
                        transformation: .dateFormat("MM/dd/yyyy HH:mm")
                    ),
                    MappingRule(
                        sourceField: "setAsideType",
                        targetField: "setAside",
                        transformation: .mapping([
                            "small_business": "SMALL BUSINESS SET-ASIDE",
                            "8a": "8(A) SET-ASIDE",
                            "wosb": "WOSB SET-ASIDE",
                            "hubzone": "HUBZONE SET-ASIDE",
                            "sdvosb": "SDVOSB SET-ASIDE",
                        ])
                    ),
                ],
                defaultValues: [
                    "acquisitionType": "COMMERCIAL",
                    "evaluationType": "LPTA",
                ]
            ),
        ],
    ]

    // MARK: - Public Methods

    /// Get mapping rules for a specific template to form conversion
    func getMappingRules(from documentType: DocumentType, to formType: FormType) async throws -> MappingRuleSet {
        guard let rulesForDocument = mappingRules[documentType],
              let ruleSet = rulesForDocument[formType]
        else {
            throw MappingEngineError.noMappingAvailable(from: documentType, to: formType)
        }

        return ruleSet
    }

    /// Apply mapping rules to transform data
    func applyMapping(
        sourceData: [String: Any],
        rules: MappingRuleSet
    ) throws -> [String: Any] {
        var result: [String: Any] = [:]

        // Apply default values first
        for (key, value) in rules.defaultValues {
            result[key] = value
        }

        // Apply mapping rules
        for rule in rules.rules {
            let sourceValue = getNestedValue(from: sourceData, path: rule.sourceField)

            if let value = sourceValue {
                let transformedValue = try applyTransformation(
                    value: value,
                    transformation: rule.transformation
                )
                result[rule.targetField] = transformedValue
            } else if rule.isRequired {
                throw MappingEngineError.requiredFieldMissing(rule.sourceField)
            }
        }

        return result
    }

    /// Validate that all required fields are present
    func validateRequiredFields(
        data: [String: Any],
        requiredFields: [String]
    ) throws {
        let missingFields = requiredFields.filter { field in
            getNestedValue(from: data, path: field) == nil
        }

        if !missingFields.isEmpty {
            throw MappingEngineError.missingRequiredFields(missingFields)
        }
    }

    // MARK: - Private Methods

    private func getNestedValue(from data: [String: Any], path: String) -> Any? {
        let components = path.split(separator: ".").map(String.init)
        var current: Any? = data

        for component in components {
            if let dict = current as? [String: Any] {
                current = dict[component]
            } else {
                return nil
            }
        }

        return current
    }

    private func applyTransformation(
        value: Any,
        transformation: FieldTransformation
    ) throws -> Any {
        switch transformation {
        case .direct:
            return value

        case let .dateFormat(format):
            guard let date = value as? Date else {
                throw MappingEngineError.invalidTransformation("Expected Date, got \(type(of: value))")
            }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: date)

        case .currency:
            guard let number = value as? NSNumber else {
                throw MappingEngineError.invalidTransformation("Expected Number for currency, got \(type(of: value))")
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: number) ?? "$0.00"

        case .addressFormat:
            guard let address = value as? [String: Any] else {
                throw MappingEngineError.invalidTransformation("Expected address dictionary")
            }
            let street = address["street"] as? String ?? ""
            let city = address["city"] as? String ?? ""
            let state = address["state"] as? String ?? ""
            let zip = address["zip"] as? String ?? ""
            return "\(street)\n\(city), \(state) \(zip)"

        case let .mapping(map):
            guard let key = value as? String,
                  let mappedValue = map[key]
            else {
                return value
            }
            return mappedValue

        case let .array(transform):
            guard let array = value as? [[String: Any]] else {
                throw MappingEngineError.invalidTransformation("Expected array")
            }
            return try array.map { try transform($0) }

        case let .custom(transform):
            return try transform(value)
        }
    }
}

// MARK: - Supporting Types

struct MappingRuleSet: Sendable {
    let rules: [MappingRule]
    let defaultValues: [String: String] // Changed from [String: Any] to make it Sendable
}

struct MappingRule: Sendable {
    let sourceField: String
    let targetField: String
    let transformation: FieldTransformation
    let isRequired: Bool = true
}

enum FieldTransformation: @unchecked Sendable {
    case direct
    case dateFormat(String)
    case currency
    case addressFormat
    case mapping([String: String])
    case array(([String: Any]) throws -> [String: Any])
    case custom((Any) throws -> Any)
}

enum MappingEngineError: LocalizedError {
    case noMappingAvailable(from: DocumentType, to: FormType)
    case requiredFieldMissing(String)
    case missingRequiredFields([String])
    case invalidTransformation(String)

    var errorDescription: String? {
        switch self {
        case let .noMappingAvailable(from, to):
            "No mapping available from \(from) to \(to)"
        case let .requiredFieldMissing(field):
            "Required field missing: \(field)"
        case let .missingRequiredFields(fields):
            "Missing required fields: \(fields.joined(separator: ", "))"
        case let .invalidTransformation(reason):
            "Invalid transformation: \(reason)"
        }
    }
}
