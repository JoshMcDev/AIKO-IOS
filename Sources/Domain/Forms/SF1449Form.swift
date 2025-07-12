import Foundation

/// SF 1449 - Solicitation/Contract/Order for Commercial Products and Commercial Services
public final class SF1449Form: BaseGovernmentForm {
    
    // MARK: - Form Sections
    
    public let contractOrder: ContractOrderSection
    public let solicitation: SF1449SolicitationSection
    public let contractor: ContractorSection
    public let schedule: ScheduleSection
    public let delivery: DeliverySection
    public let payment: PaymentSection
    
    // MARK: - Initialization
    
    public init(
        revision: String = "REV NOV 2021",
        metadata: FormMetadata,
        contractOrder: ContractOrderSection,
        solicitation: SF1449SolicitationSection,
        contractor: ContractorSection,
        schedule: ScheduleSection,
        delivery: DeliverySection,
        payment: PaymentSection
    ) {
        self.contractOrder = contractOrder
        self.solicitation = solicitation
        self.contractor = contractor
        self.schedule = schedule
        self.delivery = delivery
        self.payment = payment
        
        super.init(
            formNumber: "SF1449",
            formTitle: "Solicitation/Contract/Order for Commercial Products and Commercial Services",
            revision: revision,
            effectiveDate: DateComponents(calendar: .current, year: 2021, month: 11, day: 1).date!,
            expirationDate: nil,
            isElectronic: true,
            metadata: metadata
        )
    }
    
    // MARK: - Validation
    
    public override func validate() throws {
        try super.validate()
        
        // Validate all sections
        try contractOrder.validate()
        try solicitation.validate()
        try contractor.validate()
        try schedule.validate()
        try delivery.validate()
        try payment.validate()
    }
    
    // MARK: - Export
    
    public override func export() -> [String: Any] {
        var data = super.export()
        
        data["contractOrder"] = contractOrder.export()
        data["solicitation"] = solicitation.export()
        data["contractor"] = contractor.export()
        data["schedule"] = schedule.export()
        data["delivery"] = delivery.export()
        data["payment"] = payment.export()
        
        return data
    }
}

// MARK: - SF1449 Sections

/// Contract/Order section
public struct ContractOrderSection: ValueObject {
    public let requisitionNumber: RequisitionNumber?
    public let contractNumber: ContractNumber?
    public let orderNumber: DeliveryOrderNumber?
    public let effectiveDate: Date
    public let totalAmount: Money?
    
    public init(
        requisitionNumber: RequisitionNumber? = nil,
        contractNumber: ContractNumber? = nil,
        orderNumber: DeliveryOrderNumber? = nil,
        effectiveDate: Date,
        totalAmount: Money? = nil
    ) {
        self.requisitionNumber = requisitionNumber
        self.contractNumber = contractNumber
        self.orderNumber = orderNumber
        self.effectiveDate = effectiveDate
        self.totalAmount = totalAmount
    }
    
    public func validate() throws {
        // At least one identifier must be present
        if requisitionNumber == nil && contractNumber == nil && orderNumber == nil {
            throw FormError.validationFailed("At least one identifier (requisition, contract, or order number) is required")
        }
    }
    
    func export() -> [String: Any] {
        [
            "requisitionNumber": requisitionNumber?.value as Any,
            "contractNumber": contractNumber?.value as Any,
            "orderNumber": orderNumber?.value as Any,
            "effectiveDate": effectiveDate.timeIntervalSince1970,
            "totalAmount": totalAmount?.amount as Any,
            "currency": totalAmount?.currency.rawValue as Any
        ]
    }
}

/// Solicitation section for SF1449
public struct SF1449SolicitationSection: ValueObject {
    public let solicitationNumber: SolicitationNumber?
    public let issueDate: Date?
    public let responseDate: Date?
    public let setAsideType: SetAsideType?
    
    public enum SetAsideType: String, CaseIterable {
        case none = "NONE"
        case smallBusiness = "SMALL_BUSINESS"
        case hubZone = "HUBZONE"
        case serviceDisabledVeteran = "SDVOSB"
        case womenOwned = "WOSB"
        case eight_a = "8A"
    }
    
    public init(
        solicitationNumber: SolicitationNumber? = nil,
        issueDate: Date? = nil,
        responseDate: Date? = nil,
        setAsideType: SetAsideType? = nil
    ) {
        self.solicitationNumber = solicitationNumber
        self.issueDate = issueDate
        self.responseDate = responseDate
        self.setAsideType = setAsideType
    }
    
    public func validate() throws {
        if let issueDate = issueDate,
           let responseDate = responseDate,
           responseDate <= issueDate {
            throw FormError.validationFailed("Response date must be after issue date")
        }
    }
    
    func export() -> [String: Any] {
        [
            "solicitationNumber": solicitationNumber?.value as Any,
            "issueDate": issueDate?.timeIntervalSince1970 as Any,
            "responseDate": responseDate?.timeIntervalSince1970 as Any,
            "setAsideType": setAsideType?.rawValue as Any
        ]
    }
}

/// Contractor information section
public struct ContractorSection: ValueObject {
    public let name: String
    public let address: PostalAddress
    public let cageCode: CageCode?
    public let dunsNumber: DUNSNumber?
    public let taxId: String?
    public let remittanceAddress: PostalAddress?
    
    public init(
        name: String,
        address: PostalAddress,
        cageCode: CageCode? = nil,
        dunsNumber: DUNSNumber? = nil,
        taxId: String? = nil,
        remittanceAddress: PostalAddress? = nil
    ) {
        self.name = name
        self.address = address
        self.cageCode = cageCode
        self.dunsNumber = dunsNumber
        self.taxId = taxId
        self.remittanceAddress = remittanceAddress
    }
    
    public func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FormError.missingRequiredField("contractor name")
        }
    }
    
    func export() -> [String: Any] {
        [
            "name": name,
            "address": address.formatted,
            "cageCode": cageCode?.value as Any,
            "dunsNumber": dunsNumber?.value as Any,
            "taxId": taxId as Any,
            "remittanceAddress": remittanceAddress?.formatted as Any
        ]
    }
}

/// Schedule/Items section
public struct ScheduleSection: ValueObject {
    public let items: [LineItem]
    public let totalPrice: Money
    
    public struct LineItem: ValueObject {
        public let itemNumber: String
        public let description: String
        public let quantity: Decimal
        public let unit: String
        public let unitPrice: Money
        public let totalPrice: Money
        
        public init(
            itemNumber: String,
            description: String,
            quantity: Decimal,
            unit: String,
            unitPrice: Money,
            totalPrice: Money
        ) {
            self.itemNumber = itemNumber
            self.description = description
            self.quantity = quantity
            self.unit = unit
            self.unitPrice = unitPrice
            self.totalPrice = totalPrice
        }
        
        public func validate() throws {
            guard !itemNumber.isEmpty else {
                throw FormError.missingRequiredField("itemNumber")
            }
            guard !description.isEmpty else {
                throw FormError.missingRequiredField("description")
            }
            guard quantity > 0 else {
                throw FormError.invalidField("quantity - must be greater than 0")
            }
        }
    }
    
    public init(items: [LineItem], totalPrice: Money) {
        self.items = items
        self.totalPrice = totalPrice
    }
    
    public func validate() throws {
        guard !items.isEmpty else {
            throw FormError.validationFailed("At least one line item is required")
        }
        
        for item in items {
            try item.validate()
        }
        
        // Validate total matches sum of items
        let calculatedTotal = items.reduce(Decimal(0)) { $0 + $1.totalPrice.amount }
        guard abs(calculatedTotal - totalPrice.amount) < 0.01 else {
            throw FormError.validationFailed("Total price does not match sum of line items")
        }
    }
    
    func export() -> [String: Any] {
        [
            "items": items.map { item in
                [
                    "itemNumber": item.itemNumber,
                    "description": item.description,
                    "quantity": item.quantity,
                    "unit": item.unit,
                    "unitPrice": item.unitPrice.amount,
                    "totalPrice": item.totalPrice.amount
                ]
            },
            "totalPrice": totalPrice.amount,
            "currency": totalPrice.currency.rawValue
        ]
    }
}

/// Delivery information section
public struct DeliverySection: ValueObject {
    public let deliveryDate: Date?
    public let deliveryDays: Int?
    public let deliveryAddress: PostalAddress
    public let fobPoint: FOBPoint?
    
    public enum FOBPoint: String, CaseIterable {
        case destination = "DESTINATION"
        case origin = "ORIGIN"
        case other = "OTHER"
    }
    
    public init(
        deliveryDate: Date? = nil,
        deliveryDays: Int? = nil,
        deliveryAddress: PostalAddress,
        fobPoint: FOBPoint? = nil
    ) {
        self.deliveryDate = deliveryDate
        self.deliveryDays = deliveryDays
        self.deliveryAddress = deliveryAddress
        self.fobPoint = fobPoint
    }
    
    public func validate() throws {
        // Either delivery date or days must be specified
        if deliveryDate == nil && deliveryDays == nil {
            throw FormError.validationFailed("Either delivery date or delivery days must be specified")
        }
    }
    
    func export() -> [String: Any] {
        [
            "deliveryDate": deliveryDate?.timeIntervalSince1970 as Any,
            "deliveryDays": deliveryDays as Any,
            "deliveryAddress": deliveryAddress.formatted,
            "fobPoint": fobPoint?.rawValue as Any
        ]
    }
}

/// Payment information section
public struct PaymentSection: ValueObject {
    public let paymentTerms: PaymentTerms
    public let paymentAddress: PostalAddress
    public let invoiceAddress: PostalAddress?
    
    public enum PaymentTerms: String, CaseIterable {
        case net30 = "NET_30"
        case net60 = "NET_60"
        case net90 = "NET_90"
        case uponReceipt = "UPON_RECEIPT"
        case other = "OTHER"
    }
    
    public init(
        paymentTerms: PaymentTerms,
        paymentAddress: PostalAddress,
        invoiceAddress: PostalAddress? = nil
    ) {
        self.paymentTerms = paymentTerms
        self.paymentAddress = paymentAddress
        self.invoiceAddress = invoiceAddress
    }
    
    public func validate() throws {
        // No additional validation needed
    }
    
    func export() -> [String: Any] {
        [
            "paymentTerms": paymentTerms.rawValue,
            "paymentAddress": paymentAddress.formatted,
            "invoiceAddress": invoiceAddress?.formatted as Any
        ]
    }
}

// MARK: - SF1449 Factory

public final class SF1449Factory: BaseFormFactory<SF1449Form> {
    
    public override func createBlank() -> SF1449Form {
        let metadata = FormMetadata(
            createdBy: "System",
            agency: "GSA",
            purpose: "Commercial acquisition"
        )
        
        let emptyAddress = try! PostalAddress(
            street: "TBD",
            city: "TBD",
            state: "TBD",
            zipCode: "00000",
            country: "USA"
        )
        
        return SF1449Form(
            metadata: metadata,
            contractOrder: ContractOrderSection(
                effectiveDate: Date()
            ),
            solicitation: SF1449SolicitationSection(),
            contractor: ContractorSection(
                name: "",
                address: emptyAddress
            ),
            schedule: ScheduleSection(
                items: [],
                totalPrice: try! Money(amount: 0, currency: .usd)
            ),
            delivery: DeliverySection(
                deliveryAddress: emptyAddress
            ),
            payment: PaymentSection(
                paymentTerms: .net30,
                paymentAddress: emptyAddress
            )
        )
    }
    
    public override func createForm(with data: FormData) throws -> SF1449Form {
        let metadata = data.metadata
        
        // Extract and validate fields
        let contractOrder = try createContractOrderSection(from: data.fields)
        let solicitation = try createSolicitationSection(from: data.fields)
        let contractor = try createContractorSection(from: data.fields)
        let schedule = try createScheduleSection(from: data.fields)
        let delivery = try createDeliverySection(from: data.fields)
        let payment = try createPaymentSection(from: data.fields)
        
        return SF1449Form(
            revision: data.revision ?? "REV NOV 2021",
            metadata: metadata,
            contractOrder: contractOrder,
            solicitation: solicitation,
            contractor: contractor,
            schedule: schedule,
            delivery: delivery,
            payment: payment
        )
    }
    
    // Helper methods for creating sections
    private func createContractOrderSection(from fields: [String: Any]) throws -> ContractOrderSection {
        // Implementation details for extracting contract order data
        ContractOrderSection(effectiveDate: Date())
    }
    
    private func createSolicitationSection(from fields: [String: Any]) throws -> SF1449SolicitationSection {
        // Implementation details for extracting solicitation data
        SF1449SolicitationSection()
    }
    
    private func createContractorSection(from fields: [String: Any]) throws -> ContractorSection {
        // Implementation details for extracting contractor data
        let address = try PostalAddress(
            street: fields["contractorStreet"] as? String ?? "TBD",
            city: fields["contractorCity"] as? String ?? "TBD",
            state: fields["contractorState"] as? String ?? "TBD",
            zipCode: fields["contractorZip"] as? String ?? "00000"
        )
        
        return ContractorSection(
            name: fields["contractorName"] as? String ?? "",
            address: address
        )
    }
    
    private func createScheduleSection(from fields: [String: Any]) throws -> ScheduleSection {
        // Implementation details for extracting schedule data
        ScheduleSection(
            items: [],
            totalPrice: try Money(amount: 0, currency: .usd)
        )
    }
    
    private func createDeliverySection(from fields: [String: Any]) throws -> DeliverySection {
        // Implementation details for extracting delivery data
        let address = try PostalAddress(
            street: fields["deliveryStreet"] as? String ?? "TBD",
            city: fields["deliveryCity"] as? String ?? "TBD",
            state: fields["deliveryState"] as? String ?? "TBD",
            zipCode: fields["deliveryZip"] as? String ?? "00000"
        )
        
        return DeliverySection(deliveryAddress: address)
    }
    
    private func createPaymentSection(from fields: [String: Any]) throws -> PaymentSection {
        // Implementation details for extracting payment data
        let address = try PostalAddress(
            street: fields["paymentStreet"] as? String ?? "TBD",
            city: fields["paymentCity"] as? String ?? "TBD",
            state: fields["paymentState"] as? String ?? "TBD",
            zipCode: fields["paymentZip"] as? String ?? "00000"
        )
        
        return PaymentSection(
            paymentTerms: .net30,
            paymentAddress: address
        )
    }
}