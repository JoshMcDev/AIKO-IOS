import AppCore
import Foundation

// MARK: - Sample Test Data

public enum SampleData {
    // MARK: - Documents

    public static let sampleDocuments: [GeneratedDocument] = [
        GeneratedDocument(
            id: .testUUID("doc-1"),
            documentCategory: .contractingOfficerOrder,
            title: "Sample Contracting Officer Order",
            content: """
            CONTRACTING OFFICER ORDER

            Order Number: CO-2024-001
            Date: January 1, 2024

            This order is issued under the authority of...
            """,
            dateGenerated: .testDate(),
            requirements: "Standard contracting requirements"
        ),

        GeneratedDocument(
            id: .testUUID("doc-2"),
            documentCategory: .independentGovernmentCostEstimate,
            title: "Sample IGCE",
            content: """
            INDEPENDENT GOVERNMENT COST ESTIMATE

            Project: Test Acquisition
            Estimated Total Cost: $50,000

            Line Items:
            1. Hardware: $30,000
            2. Software: $15,000
            3. Installation: $5,000
            """,
            dateGenerated: .testDate(86400), // +1 day
            requirements: "IGCE requirements for test project"
        ),
    ]

    // MARK: - Requirements Data

    public static let sampleRequirements: [RequirementsData] = [
        {
            var data = RequirementsData()
            data.projectTitle = "Office Supply Acquisition"
            data.description = "Procurement of standard office supplies for Q1 2024"
            data.estimatedValue = 25000.0
            data.businessNeed = "Replenish office supply inventory for all departments"
            data.performancePeriod = "3 months"
            data.technicalRequirements = [
                "Eco-friendly materials preferred",
                "Bulk packaging required",
                "Monthly delivery schedule",
            ]
            data.placeOfPerformance = "123 Main St, Anytown, ST 12345"
            data.requiredDate = Calendar.current.date(byAdding: .month, value: 2, to: .testNow)
            data.acquisitionType = "Supplies"
            return data
        }(),

        {
            var data = RequirementsData()
            data.projectTitle = "IT Services Contract"
            data.description = "Professional IT support services for network infrastructure"
            data.estimatedValue = 150_000.0
            data.businessNeed = "Maintain critical IT infrastructure and provide 24/7 support"
            data.performancePeriod = "12 months"
            data.technicalRequirements = [
                "Network monitoring and maintenance",
                "Help desk support during business hours",
                "Security patch management",
                "Backup and disaster recovery services",
            ]
            data.placeOfPerformance = "Government facility, secure environment"
            data.requiredDate = Calendar.current.date(byAdding: .month, value: 1, to: .testNow)
            data.acquisitionType = "Services"
            data.setAsideType = "Small Business"
            return data
        }(),
    ]

    // MARK: - Acquisitions

    public static let sampleAcquisitions: [Acquisition] = [
        Acquisition(
            id: .testUUID("acq-1"),
            title: "Office Supplies Q1",
            description: "Quarterly office supply procurement",
            estimatedValue: 25000.0,
            vendor: "Office Depot Government Solutions",
            status: .planning,
            createdDate: .testDate(),
            lastModified: .testDate(3600), // +1 hour
            requirements: sampleRequirements[0]
        ),

        Acquisition(
            id: .testUUID("acq-2"),
            title: "IT Support Services",
            description: "Annual IT support and maintenance contract",
            estimatedValue: 150_000.0,
            vendor: "TechCorp Solutions",
            status: .inProgress,
            createdDate: .testDate(-86400), // -1 day
            lastModified: .testDate(),
            requirements: sampleRequirements[1]
        ),
    ]

    // MARK: - Chat Messages

    public static let sampleChatMessages: [ChatMessage] = [
        ChatMessage(
            role: .assistant,
            content: "Hello! I'm here to help you with your acquisition. What type of product or service are you looking to procure?"
        ),

        ChatMessage(
            role: .user,
            content: "I need to buy office supplies for our department. We're looking at about $25,000 worth of supplies."
        ),

        ChatMessage(
            role: .assistant,
            content: "Great! Office supplies for $25,000. Can you tell me more about what specific items you need and when you need them delivered?"
        ),

        ChatMessage(
            role: .user,
            content: "We need standard office supplies - paper, pens, folders, etc. We need them delivered by the end of next month."
        ),
    ]

    // MARK: - Uploaded Documents

    public static let sampleUploadedDocuments: [UploadedDocument] = [
        UploadedDocument(
            id: .testUUID("upload-1"),
            fileName: "vendor_quote.pdf",
            data: Data("Sample PDF content".utf8),
            uploadDate: .testDate(),
            documentType: .quote
        ),

        UploadedDocument(
            id: .testUUID("upload-2"),
            fileName: "technical_specs.docx",
            data: Data("Sample Word document content".utf8),
            uploadDate: .testDate(1800), // +30 minutes
            documentType: .specification
        ),
    ]

    // MARK: - Vendor Information

    public static let sampleVendors: [VendorInfo] = [
        VendorInfo(
            name: "Office Depot Government Solutions",
            uei: "ABC123456789",
            cage: "12345",
            address: "456 Business Ave, Commerce City, ST 54321",
            email: "gov.sales@officedepot.com",
            phone: "(555) 123-4567"
        ),

        VendorInfo(
            name: "TechCorp Solutions LLC",
            uei: "XYZ987654321",
            cage: "67890",
            address: "789 Technology Blvd, Innovation Park, ST 98765",
            email: "contracts@techcorp.com",
            phone: "(555) 987-6543"
        ),
    ]

    // MARK: - Cache Statistics

    public static let sampleCacheStatistics = CacheStatistics(
        totalCachedDocuments: 15,
        totalCachedAnalyses: 8,
        cacheSize: 2_048_000, // 2MB
        hitRate: 0.75,
        averageRetrievalTime: 0.125,
        lastCleanup: .testDate(-3600), // -1 hour
        mostAccessedDocumentTypes: [.contractingOfficerOrder, .independentGovernmentCostEstimate]
    )

    // MARK: - AI Responses

    public static let sampleAIResponses: [String] = [
        """
        Based on your requirements for office supplies worth $25,000, I recommend the following document types:

        1. Contracting Officer Order (COO)
        2. Independent Government Cost Estimate (IGCE)
        3. Statement of Work (SOW)

        These documents will provide the necessary framework for your procurement.
        """,

        """
        I've analyzed your technical requirements. Here are the key specifications:

        - Eco-friendly materials: EPEAT Gold certified or equivalent
        - Bulk packaging: Minimum 50-unit packages where applicable
        - Delivery schedule: Monthly deliveries on the 15th of each month

        Would you like me to generate the procurement documents with these specifications?
        """,

        """
        Your acquisition appears to be straightforward. The estimated value of $25,000 falls under the simplified acquisition threshold, which will streamline the procurement process.

        I recommend proceeding with the document generation. The process should take approximately 2-3 minutes.
        """,
    ]
}

// MARK: - Sample Data Generators

public extension SampleData {
    static func randomRequirementsData() -> RequirementsData {
        var data = RequirementsData()
        data.projectTitle = "Random Project \(String.random(length: 5))"
        data.description = "Random description for testing purposes"
        data.estimatedValue = Double.random(in: 1000 ... 100_000)
        data.businessNeed = "Testing business need"
        data.performancePeriod = "\(Int.random(in: 1 ... 12)) months"
        data.technicalRequirements = ["Requirement 1", "Requirement 2"]
        return data
    }

    static func randomAcquisition() -> Acquisition {
        Acquisition(
            id: UUID(),
            title: "Random Acquisition \(String.random(length: 5))",
            description: "Random description",
            estimatedValue: Double.random(in: 1000 ... 100_000),
            vendor: "Random Vendor \(String.random(length: 3))",
            status: AcquisitionStatus.allCases.randomElement() ?? .planning,
            createdDate: Date(),
            lastModified: Date(),
            requirements: randomRequirementsData()
        )
    }
}
