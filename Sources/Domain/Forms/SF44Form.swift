import Foundation

/// SF 44 - Purchase Order - Invoice - Voucher
public final class SF44Form: BaseGovernmentForm {
    // MARK: - Form Sections

    public let purchaseOrder: PurchaseOrderSection
    public let suppliesServices: SuppliesServicesSection
    public let shipping: ShippingSection
    public let invoice: InvoiceSection
    public let voucher: VoucherSection

    // MARK: - Initialization

    public init(
        revision: String = "REV OCT 2023",
        metadata: FormMetadata,
        purchaseOrder: PurchaseOrderSection,
        suppliesServices: SuppliesServicesSection,
        shipping: ShippingSection,
        invoice: InvoiceSection,
        voucher: VoucherSection
    ) {
        self.purchaseOrder = purchaseOrder
        self.suppliesServices = suppliesServices
        self.shipping = shipping
        self.invoice = invoice
        self.voucher = voucher

        super.init(
            formNumber: "SF44",
            formTitle: "Purchase Order - Invoice - Voucher",
            revision: revision,
            effectiveDate: DateComponents(calendar: .current, year: 2023, month: 10, day: 1).date ?? Date(),
            expirationDate: nil,
            isElectronic: true,
            metadata: metadata
        )
    }

    // MARK: - Validation

    override public func validate() throws {
        try super.validate()

        // Validate all sections
        try purchaseOrder.validate()
        try suppliesServices.validate()
        try shipping.validate()
        try invoice.validate()
        try voucher.validate()
    }

    // MARK: - Export

    override public func export() -> [String: Any] {
        var data = super.export()

        data["purchaseOrder"] = purchaseOrder.export()
        data["suppliesServices"] = suppliesServices.export()
        data["shipping"] = shipping.export()
        data["invoice"] = invoice.export()
        data["voucher"] = voucher.export()

        return data
    }
}

// MARK: - SF44 Sections

/// Purchase Order Section
public struct PurchaseOrderSection: ValueObject {
    public let orderNumber: String
    public let orderDate: Date
    public let requisitionNumber: RequisitionNumber?
    public let deliveryOrderNumber: DeliveryOrderNumber?
    public let priorityRating: String?
    public let authorityType: AuthorityType
    public let vendor: VendorDetails

    public enum AuthorityType: String, CaseIterable {
        case microPurchase = "MICRO_PURCHASE"
        case simplifiedAcquisition = "SIMPLIFIED_ACQUISITION"
        case emergency = "EMERGENCY"
        case other = "OTHER"
    }

    public struct VendorDetails: ValueObject {
        public let name: String
        public let address: PostalAddress
        public let phoneNumber: PhoneNumber?
        public let cageCode: CageCode?

        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("vendor name")
            }
        }
    }

    public init(
        orderNumber: String,
        orderDate: Date,
        requisitionNumber: RequisitionNumber? = nil,
        deliveryOrderNumber: DeliveryOrderNumber? = nil,
        priorityRating: String? = nil,
        authorityType: AuthorityType,
        vendor: VendorDetails
    ) {
        self.orderNumber = orderNumber
        self.orderDate = orderDate
        self.requisitionNumber = requisitionNumber
        self.deliveryOrderNumber = deliveryOrderNumber
        self.priorityRating = priorityRating
        self.authorityType = authorityType
        self.vendor = vendor
    }

    public func validate() throws {
        guard !orderNumber.isEmpty else {
            throw FormError.missingRequiredField("order number")
        }

        try vendor.validate()
    }

    func export() -> [String: Any] {
        [
            "orderNumber": orderNumber,
            "orderDate": orderDate.timeIntervalSince1970,
            "requisitionNumber": requisitionNumber?.value as Any,
            "deliveryOrderNumber": deliveryOrderNumber?.value as Any,
            "priorityRating": priorityRating as Any,
            "authorityType": authorityType.rawValue,
            "vendor": [
                "name": vendor.name,
                "address": vendor.address.formatted,
                "phoneNumber": vendor.phoneNumber?.value as Any,
                "cageCode": vendor.cageCode?.value as Any,
            ],
        ]
    }
}

/// Supplies/Services Section
public struct SuppliesServicesSection: ValueObject {
    public let items: [OrderItem]
    public let subtotal: Money
    public let tax: Money?
    public let shipping: Money?
    public let total: Money

    public struct OrderItem: ValueObject {
        public let lineNumber: Int
        public let stockNumber: String?
        public let description: String
        public let quantity: Decimal
        public let unit: String
        public let unitPrice: Money
        public let amount: Money

        public init(
            lineNumber: Int,
            stockNumber: String? = nil,
            description: String,
            quantity: Decimal,
            unit: String,
            unitPrice: Money,
            amount: Money
        ) {
            self.lineNumber = lineNumber
            self.stockNumber = stockNumber
            self.description = description
            self.quantity = quantity
            self.unit = unit
            self.unitPrice = unitPrice
            self.amount = amount
        }

        public func validate() throws {
            guard lineNumber > 0 else {
                throw FormError.invalidField("line number - must be positive")
            }

            guard !description.isEmpty else {
                throw FormError.missingRequiredField("item description")
            }

            guard quantity > 0 else {
                throw FormError.invalidField("quantity - must be positive")
            }

            // Validate amount = quantity * unit price
            let calculatedAmount = quantity * unitPrice.amount
            guard abs(calculatedAmount - amount.amount) < 0.01 else {
                throw FormError.validationFailed("Amount does not match quantity × unit price")
            }
        }
    }

    public init(
        items: [OrderItem],
        subtotal: Money,
        tax: Money? = nil,
        shipping: Money? = nil,
        total: Money
    ) {
        self.items = items
        self.subtotal = subtotal
        self.tax = tax
        self.shipping = shipping
        self.total = total
    }

    public func validate() throws {
        guard !items.isEmpty else {
            throw FormError.validationFailed("At least one item is required")
        }

        for item in items {
            try item.validate()
        }

        // Validate totals
        var calculatedSubtotal = Decimal(0)
        for item in items {
            calculatedSubtotal += item.amount.amount
        }

        guard abs(calculatedSubtotal - subtotal.amount) < 0.01 else {
            throw FormError.validationFailed("Subtotal does not match sum of items")
        }

        var calculatedTotal = subtotal.amount
        if let tax {
            calculatedTotal += tax.amount
        }
        if let shipping {
            calculatedTotal += shipping.amount
        }

        guard abs(calculatedTotal - total.amount) < 0.01 else {
            throw FormError.validationFailed("Total does not match subtotal + tax + shipping")
        }
    }

    func export() -> [String: Any] {
        [
            "items": items.map { item in
                [
                    "lineNumber": item.lineNumber,
                    "stockNumber": item.stockNumber as Any,
                    "description": item.description,
                    "quantity": item.quantity,
                    "unit": item.unit,
                    "unitPrice": item.unitPrice.amount,
                    "amount": item.amount.amount,
                ]
            },
            "subtotal": subtotal.amount,
            "tax": tax?.amount as Any,
            "shipping": shipping?.amount as Any,
            "total": total.amount,
            "currency": total.currency.rawValue,
        ]
    }
}

/// Shipping Section
public struct ShippingSection: ValueObject {
    public let shipTo: PostalAddress
    public let dateShipped: Date?
    public let billOfLading: String?
    public let weight: String?
    public let shippingMethod: ShippingMethod?

    public enum ShippingMethod: String, CaseIterable {
        case groundCommercial = "GROUND_COMMERCIAL"
        case groundGovt = "GROUND_GOVT"
        case airCommercial = "AIR_COMMERCIAL"
        case airGovt = "AIR_GOVT"
        case freight = "FREIGHT"
        case parcelPost = "PARCEL_POST"
        case other = "OTHER"
    }

    public init(
        shipTo: PostalAddress,
        dateShipped: Date? = nil,
        billOfLading: String? = nil,
        weight: String? = nil,
        shippingMethod: ShippingMethod? = nil
    ) {
        self.shipTo = shipTo
        self.dateShipped = dateShipped
        self.billOfLading = billOfLading
        self.weight = weight
        self.shippingMethod = shippingMethod
    }

    public func validate() throws {
        // No required validation for shipping section
    }

    func export() -> [String: Any] {
        [
            "shipTo": shipTo.formatted,
            "dateShipped": dateShipped?.timeIntervalSince1970 as Any,
            "billOfLading": billOfLading as Any,
            "weight": weight as Any,
            "shippingMethod": shippingMethod?.rawValue as Any,
        ]
    }
}

/// Invoice Section
public struct InvoiceSection: ValueObject {
    public let invoiceNumber: String?
    public let invoiceDate: Date?
    public let discountTerms: String?
    public let remitTo: PostalAddress?

    public init(
        invoiceNumber: String? = nil,
        invoiceDate: Date? = nil,
        discountTerms: String? = nil,
        remitTo: PostalAddress? = nil
    ) {
        self.invoiceNumber = invoiceNumber
        self.invoiceDate = invoiceDate
        self.discountTerms = discountTerms
        self.remitTo = remitTo
    }

    public func validate() throws {
        // Invoice section is optional
    }

    func export() -> [String: Any] {
        [
            "invoiceNumber": invoiceNumber as Any,
            "invoiceDate": invoiceDate?.timeIntervalSince1970 as Any,
            "discountTerms": discountTerms as Any,
            "remitTo": remitTo?.formatted as Any,
        ]
    }
}

/// Voucher Section
public struct VoucherSection: ValueObject {
    public let voucherNumber: String?
    public let scheduleNumber: String?
    public let paymentComplete: Bool
    public let paymentPartial: PaymentPartial?
    public let checkNumber: String?
    public let checkDate: Date?
    public let billTo: PostalAddress?
    public let payee: PayeeInfo?

    public struct PaymentPartial: ValueObject {
        public let amountPaid: Money
        public let balanceDue: Money

        public func validate() throws {
            // No additional validation needed
        }
    }

    public struct PayeeInfo: ValueObject {
        public let name: String
        public let address: PostalAddress?
        public let accountNumber: String?

        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("payee name")
            }
        }
    }

    public init(
        voucherNumber: String? = nil,
        scheduleNumber: String? = nil,
        paymentComplete: Bool = false,
        paymentPartial: PaymentPartial? = nil,
        checkNumber: String? = nil,
        checkDate: Date? = nil,
        billTo: PostalAddress? = nil,
        payee: PayeeInfo? = nil
    ) {
        self.voucherNumber = voucherNumber
        self.scheduleNumber = scheduleNumber
        self.paymentComplete = paymentComplete
        self.paymentPartial = paymentPartial
        self.checkNumber = checkNumber
        self.checkDate = checkDate
        self.billTo = billTo
        self.payee = payee
    }

    public func validate() throws {
        if let payee {
            try payee.validate()
        }
    }

    func export() -> [String: Any] {
        [
            "voucherNumber": voucherNumber as Any,
            "scheduleNumber": scheduleNumber as Any,
            "paymentComplete": paymentComplete,
            "paymentPartial": paymentPartial.map { partial in
                [
                    "amountPaid": partial.amountPaid.amount,
                    "balanceDue": partial.balanceDue.amount,
                    "currency": partial.amountPaid.currency.rawValue,
                ]
            } as Any,
            "checkNumber": checkNumber as Any,
            "checkDate": checkDate?.timeIntervalSince1970 as Any,
            "billTo": billTo?.formatted as Any,
            "payee": payee.map { p in
                [
                    "name": p.name,
                    "address": p.address?.formatted as Any,
                    "accountNumber": p.accountNumber as Any,
                ]
            } as Any,
        ]
    }
}

// MARK: - SF44 Factory

public final class SF44Factory: BaseFormFactory<SF44Form> {
    override public func createBlank() -> SF44Form {
        let metadata = FormMetadata(
            createdBy: "System",
            agency: "GSA",
            purpose: "Purchase order and payment"
        )

        let emptyAddress = try! PostalAddress(
            street: "TBD",
            city: "TBD",
            state: "TBD",
            zipCode: "00000",
            country: "USA"
        )

        return SF44Form(
            metadata: metadata,
            purchaseOrder: PurchaseOrderSection(
                orderNumber: "PO-00000",
                orderDate: Date(),
                authorityType: .simplifiedAcquisition,
                vendor: PurchaseOrderSection.VendorDetails(
                    name: "",
                    address: emptyAddress,
                    phoneNumber: nil,
                    cageCode: nil
                )
            ),
            suppliesServices: SuppliesServicesSection(
                items: [],
                subtotal: try! Money(amount: 0, currency: .usd),
                total: try! Money(amount: 0, currency: .usd)
            ),
            shipping: ShippingSection(shipTo: emptyAddress),
            invoice: InvoiceSection(),
            voucher: VoucherSection()
        )
    }

    override public func createForm(with data: FormData) throws -> SF44Form {
        let metadata = data.metadata

        // Extract and validate fields
        let purchaseOrder = try createPurchaseOrderSection(from: data.fields)
        let suppliesServices = try createSuppliesServicesSection(from: data.fields)
        let shipping = try createShippingSection(from: data.fields)
        let invoice = try createInvoiceSection(from: data.fields)
        let voucher = try createVoucherSection(from: data.fields)

        return SF44Form(
            revision: data.revision ?? "REV OCT 2023",
            metadata: metadata,
            purchaseOrder: purchaseOrder,
            suppliesServices: suppliesServices,
            shipping: shipping,
            invoice: invoice,
            voucher: voucher
        )
    }

    // Helper methods for creating sections
    private func createPurchaseOrderSection(from fields: [String: Any]) throws -> PurchaseOrderSection {
        let vendorAddress = try PostalAddress(
            street: fields["vendorStreet"] as? String ?? "TBD",
            city: fields["vendorCity"] as? String ?? "TBD",
            state: fields["vendorState"] as? String ?? "TBD",
            zipCode: fields["vendorZip"] as? String ?? "00000"
        )

        let vendor = PurchaseOrderSection.VendorDetails(
            name: fields["vendorName"] as? String ?? "",
            address: vendorAddress,
            phoneNumber: nil,
            cageCode: nil
        )

        return PurchaseOrderSection(
            orderNumber: fields["orderNumber"] as? String ?? "PO-00000",
            orderDate: fields["orderDate"] as? Date ?? Date(),
            authorityType: .simplifiedAcquisition,
            vendor: vendor
        )
    }

    private func createSuppliesServicesSection(from fields: [String: Any]) throws -> SuppliesServicesSection {
        let total = try Money(
            amount: fields["totalAmount"] as? Decimal ?? 0,
            currency: .usd
        )

        return SuppliesServicesSection(
            items: [],
            subtotal: total,
            total: total
        )
    }

    private func createShippingSection(from fields: [String: Any]) throws -> ShippingSection {
        let shipTo = try PostalAddress(
            street: fields["shipToStreet"] as? String ?? "TBD",
            city: fields["shipToCity"] as? String ?? "TBD",
            state: fields["shipToState"] as? String ?? "TBD",
            zipCode: fields["shipToZip"] as? String ?? "00000"
        )

        return ShippingSection(shipTo: shipTo)
    }

    private func createInvoiceSection(from _: [String: Any]) throws -> InvoiceSection {
        InvoiceSection()
    }

    private func createVoucherSection(from _: [String: Any]) throws -> VoucherSection {
        VoucherSection()
    }
}
