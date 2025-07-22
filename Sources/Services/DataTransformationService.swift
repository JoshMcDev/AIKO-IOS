import AppCore
import Foundation

/// Service responsible for transforming template data to form data
final class DataTransformationService: @unchecked Sendable {
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
    ) async throws -> [String: String] {
        let mappingEngine = MappingEngine()

        // Apply basic mapping
        let mappedData = try mappingEngine.applyMapping(
            sourceData: templateData.data,
            rules: mappingRules
        )

        // Convert Any values to String
        var transformedData: [String: String] = [:]
        for (key, value) in mappedData {
            transformedData[key] = String(describing: value)
        }

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
        data: [String: String],
        formType: FormType,
        templateType: DocumentType
    ) throws -> [String: String] {
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

    private func transformForSF18(_ data: [String: String], templateType _: DocumentType) throws -> [String: String] {
        var result = data

        // Generate requisition number if not present
        if result["requisitionNumber"] == nil {
            result["requisitionNumber"] = generateRequisitionNumber()
        }

        // Format delivery instructions
        if let deliveryLocation = data["deliveryLocation"] {
            result["deliveryInstructions"] = "DELIVER TO: \(deliveryLocation.uppercased())"
        }

        // Calculate extended price
        if let quantityStr = data["quantity"],
           let unitPriceStr = data["unitPrice"],
           let quantity = Double(quantityStr),
           let unitPrice = Double(unitPriceStr)
        {
            result["extendedPrice"] = String(quantity * unitPrice)
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

    private func transformForSF1449(_ data: [String: String], templateType: DocumentType) throws -> [String: String] {
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

        // Format line items for SF 1449 - convert to comma-separated string
        if let itemsStr = data["items"] {
            // Assume items are formatted as comma-separated list
            let items = itemsStr.components(separatedBy: ",")
            let scheduleItems = items.enumerated().map { index, item in
                let itemNumber = String(format: "%04d", index + 1)
                let supplyService = item.contains("service") ? "S" : "P"
                return "\(itemNumber):\(item.trimmingCharacters(in: .whitespaces)):\(supplyService)"
            }
            result["scheduleItems"] = scheduleItems.joined(separator: ";")
        }

        // Add required FAR clauses
        var clauses = data["farClauses"]?.components(separatedBy: ",") ?? []
        let requiredClauses = ["52.212-1", "52.212-2", "52.212-3", "52.212-4", "52.212-5"]
        for clause in requiredClauses {
            if !clauses.contains(clause) {
                clauses.append(clause)
            }
        }
        result["farClauses"] = clauses.joined(separator: ",")

        return result
    }

    private func transformForSF30(_ data: [String: String], templateType _: DocumentType) throws -> [String: String] {
        var result = data

        // Generate amendment number if not present
        if result["amendmentNumber"] == nil {
            result["amendmentNumber"] = String(format: "%04d", 1)
        }

        // Set modification code
        result["modificationCode"] = data["isAdministrative"] == "true" ? "A" : "B"

        // Format change description
        if let changesStr = data["changes"] {
            let changes = changesStr.components(separatedBy: ",")
            result["modificationDescription"] = changes.enumerated().map { index, change in
                "\(index + 1). \(change.trimmingCharacters(in: .whitespaces))"
            }.joined(separator: "\n")
        }

        return result
    }

    private func transformForSF44(_ data: [String: String], templateType _: DocumentType) throws -> [String: String] {
        var result = data

        // Validate micro-purchase threshold
        if let totalStr = data["totalAmount"],
           let total = Double(totalStr)
        {
            if total > 10000 {
                throw DataTransformationError.thresholdExceeded(
                    "SF 44 cannot be used for purchases over $10,000"
                )
            }
        }

        // Add purchase card information if available
        if let cardLastFour = data["purchaseCardLastFour"] {
            result["paymentMethod"] = "Government Purchase Card ending in \(cardLastFour)"
        } else {
            result["paymentMethod"] = "Government Purchase Card"
        }

        // Set immediate delivery flag
        result["immediateDelivery"] = "true"

        return result
    }

    private func calculateDerivedFields(
        data: [String: String],
        formType _: FormType
    ) throws -> [String: String] {
        var result = data

        // Calculate total amounts from items string
        if let itemsStr = data["items"] {
            let items = itemsStr.components(separatedBy: ";")
            var totalAmount = 0.0
            for item in items {
                let parts = item.components(separatedBy: ":")
                if parts.count >= 3,
                   let quantity = Double(parts[1]),
                   let unitPrice = Double(parts[2])
                {
                    totalAmount += quantity * unitPrice
                }
            }
            result["totalAmount"] = String(totalAmount)
        }

        // Calculate dates
        if let startDateStr = data["startDate"],
           let performanceDaysStr = data["performanceDays"],
           let performanceDays = Int(performanceDaysStr)
        {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let startDate = formatter.date(from: startDateStr) {
                let endDate = Calendar.current.date(
                    byAdding: .day,
                    value: performanceDays,
                    to: startDate
                )
                if let endDate {
                    result["endDate"] = formatter.string(from: endDate)
                }
            }
        }

        // Format addresses
        if let vendorAddress = data["vendorAddress"] {
            result["vendorFullAddress"] = vendorAddress // Already formatted as string
        }

        return result
    }

    private func applyFARFormatting(
        data: [String: String],
        formType _: FormType
    ) -> [String: String] {
        var result = data

        // Format dates according to FAR standards
        for (key, value) in result {
            if key.hasSuffix("Date") {
                // Try to parse date string and reformat
                let inputFormatter = DateFormatter()
                inputFormatter.dateFormat = "yyyy-MM-dd"
                if let date = inputFormatter.date(from: value) {
                    dateFormatter.dateFormat = "MM/dd/yyyy"
                    result[key] = dateFormatter.string(from: date)
                }
            }
        }

        // Format currency values
        for (key, value) in result {
            if key.contains("Amount") || key.contains("Price") || key.contains("Value"),
               let number = Double(value)
            {
                result[key] = currencyFormatter.string(from: NSNumber(value: number)) ?? "$0.00"
            }
        }

        // Uppercase certain fields
        let uppercaseFields = ["contractorName", "vendorName", "agencyName", "officeCode"]
        for field in uppercaseFields {
            if let stringValue = result[field] {
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
