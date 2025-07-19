import Foundation
import AppCore

/// Service responsible for transforming template data to form data
final class DataTransformationService {
    // MARK: - Properties

    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter
    private let currencyFormatter: NumberFormatter

    // MARK: - Initialization

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale(identifier: "en_US")
    }

    // MARK: - Public Methods

    /// Transform template data using mapping rules
    func transform(
        templateData: TemplateData,
        using mappingRules: MappingRuleSet,
        targetForm: FormDefinition
    ) async throws -> [String: Any] {
        let mappingEngine = MappingEngine()

        // Apply basic mapping
        var transformedData = try mappingEngine.applyMapping(
            sourceData: templateData.data,
            rules: mappingRules
        )

        // Apply form-specific transformations
        transformedData = try applyFormSpecificTransformations(
            data: transformedData,
            formType: targetForm.formType,
            templateType: templateData.documentType
        )

        // Fill in calculated fields
        transformedData = try calculateDerivedFields(
            data: transformedData,
            formType: targetForm.formType
        )

        // Apply FAR-specific formatting
        transformedData = applyFARFormatting(
            data: transformedData,
            formType: targetForm.formType
        )

        // Validate all required fields are present
        try mappingEngine.validateRequiredFields(
            data: transformedData,
            requiredFields: targetForm.requiredFields
        )

        return transformedData
    }

    // MARK: - Private Methods

    private func applyFormSpecificTransformations(
        data: [String: Any],
        formType: FormType,
        templateType: DocumentType
    ) throws -> [String: Any] {
        var result = data

        switch formType {
        case .sf18:
            result = try transformForSF18(data, templateType: templateType)
        case .sf1449:
            result = try transformForSF1449(data, templateType: templateType)
        case .sf30:
            result = try transformForSF30(data, templateType: templateType)
        case .sf44:
            result = try transformForSF44(data, templateType: templateType)
        default:
            break
        }

        return result
    }

    private func transformForSF18(_ data: [String: Any], templateType _: DocumentType) throws -> [String: Any] {
        var result = data

        // Generate requisition number if not present
        if result["requisitionNumber"] == nil {
            result["requisitionNumber"] = generateRequisitionNumber()
        }

        // Format delivery instructions
        if let deliveryLocation = data["deliveryLocation"] as? String {
            result["deliveryInstructions"] = "DELIVER TO: \(deliveryLocation.uppercased())"
        }

        // Calculate extended price
        if let quantity = data["quantity"] as? Double,
           let unitPrice = data["unitPrice"] as? Double
        {
            result["extendedPrice"] = quantity * unitPrice
        }

        // Add standard RFQ terms
        result["terms"] = """
        1. QUOTES MUST BE RECEIVED BY DATE/TIME SPECIFIED
        2. DELIVERY REQUIRED BY DATE SHOWN
        3. SUBMIT QUOTES TO CONTRACTING OFFICER
        4. INCLUDE ALL APPLICABLE TAXES
        """

        return result
    }

    private func transformForSF1449(_ data: [String: Any], templateType: DocumentType) throws -> [String: Any] {
        var result = data

        // Add contract type code
        switch templateType {
        case .contractScaffold:
            result["contractTypeCode"] = "C" // Delivery Order
        case .requestForProposal:
            result["contractTypeCode"] = "A" // Solicitation
        case .requestForQuote, .requestForQuoteSimplified:
            result["contractTypeCode"] = "B" // Purchase Order
        default:
            result["contractTypeCode"] = "J" // Indefinite Delivery
        }

        // Format line items for SF 1449
        if let items = data["items"] as? [[String: Any]] {
            result["scheduleItems"] = items.enumerated().map { index, item in
                var scheduleItem = item
                scheduleItem["itemNumber"] = String(format: "%04d", index + 1)
                scheduleItem["supplyService"] = item["isService"] as? Bool == true ? "S" : "P"
                return scheduleItem
            }
        }

        // Add required FAR clauses
        var clauses = data["farClauses"] as? [String] ?? []
        let requiredClauses = ["52.212-1", "52.212-2", "52.212-3", "52.212-4", "52.212-5"]
        for clause in requiredClauses {
            if !clauses.contains(clause) {
                clauses.append(clause)
            }
        }
        result["farClauses"] = clauses

        return result
    }

    private func transformForSF30(_ data: [String: Any], templateType _: DocumentType) throws -> [String: Any] {
        var result = data

        // Generate amendment number if not present
        if result["amendmentNumber"] == nil {
            result["amendmentNumber"] = String(format: "%04d", 1)
        }

        // Set modification code
        result["modificationCode"] = data["isAdministrative"] as? Bool == true ? "A" : "B"

        // Format change description
        if let changes = data["changes"] as? [String] {
            result["modificationDescription"] = changes.enumerated().map { index, change in
                "\(index + 1). \(change)"
            }.joined(separator: "\n")
        }

        return result
    }

    private func transformForSF44(_ data: [String: Any], templateType _: DocumentType) throws -> [String: Any] {
        var result = data

        // Validate micro-purchase threshold
        if let total = data["totalAmount"] as? Double {
            if total > 10000 {
                throw DataTransformationError.thresholdExceeded(
                    "SF 44 cannot be used for purchases over $10,000"
                )
            }
        }

        // Add purchase card information if available
        if let cardLastFour = data["purchaseCardLastFour"] as? String {
            result["paymentMethod"] = "Government Purchase Card ending in \(cardLastFour)"
        } else {
            result["paymentMethod"] = "Government Purchase Card"
        }

        // Set immediate delivery flag
        result["immediateDelivery"] = true

        return result
    }

    private func calculateDerivedFields(
        data: [String: Any],
        formType _: FormType
    ) throws -> [String: Any] {
        var result = data

        // Calculate total amounts
        if let items = data["items"] as? [[String: Any]] {
            let totalAmount = items.reduce(0.0) { sum, item in
                let quantity = item["quantity"] as? Double ?? 0
                let unitPrice = item["unitPrice"] as? Double ?? 0
                return sum + (quantity * unitPrice)
            }
            result["totalAmount"] = totalAmount
        }

        // Calculate dates
        if let startDate = data["startDate"] as? Date,
           let performanceDays = data["performanceDays"] as? Int
        {
            let endDate = Calendar.current.date(
                byAdding: .day,
                value: performanceDays,
                to: startDate
            )
            result["endDate"] = endDate
        }

        // Format addresses
        if let vendor = data["vendor"] as? [String: Any] {
            result["vendorFullAddress"] = formatAddress(vendor)
        }

        return result
    }

    private func applyFARFormatting(
        data: [String: Any],
        formType _: FormType
    ) -> [String: Any] {
        var result = data

        // Format dates according to FAR standards
        for (key, value) in result {
            if key.hasSuffix("Date"), let date = value as? Date {
                dateFormatter.dateFormat = "MM/dd/yyyy"
                result[key] = dateFormatter.string(from: date)
            }
        }

        // Format currency values
        for (key, value) in result {
            if key.contains("Amount") || key.contains("Price") || key.contains("Value"),
               let number = value as? Double
            {
                result[key] = currencyFormatter.string(from: NSNumber(value: number)) ?? "$0.00"
            }
        }

        // Uppercase certain fields
        let uppercaseFields = ["contractorName", "vendorName", "agencyName", "officeCode"]
        for field in uppercaseFields {
            if let stringValue = result[field] as? String {
                result[field] = stringValue.uppercased()
            }
        }

        return result
    }

    private func generateRequisitionNumber() -> String {
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let randomSuffix = String(format: "%04d", Int.random(in: 0 ... 9999))
        return "REQ-\(year)-\(randomSuffix)"
    }

    private func formatAddress(_ address: [String: Any]) -> String {
        let name = address["name"] as? String ?? ""
        let street1 = address["street1"] as? String ?? ""
        let street2 = address["street2"] as? String ?? ""
        let city = address["city"] as? String ?? ""
        let state = address["state"] as? String ?? ""
        let zip = address["zip"] as? String ?? ""

        var lines = [name, street1]
        if !street2.isEmpty {
            lines.append(street2)
        }
        lines.append("\(city), \(state) \(zip)")

        return lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: "\n")
    }
}

// MARK: - Supporting Types

enum DataTransformationError: LocalizedError {
    case thresholdExceeded(String)
    case invalidDataFormat(String)
    case missingRequiredData(String)

    var errorDescription: String? {
        switch self {
        case let .thresholdExceeded(message):
            "Threshold exceeded: \(message)"
        case let .invalidDataFormat(message):
            "Invalid data format: \(message)"
        case let .missingRequiredData(message):
            "Missing required data: \(message)"
        }
    }
}
