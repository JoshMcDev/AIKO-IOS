import ComposableArchitecture
import Foundation

/// Main service for regulatory API integration
/// Handles data ingestion from Regulations.gov and GSA DITA toolkit
public struct RegulationService: Sendable {
    // MARK: - Core API Operations

    public var searchDocuments: @Sendable (RegulationSearchQuery) async throws -> RegulationSearchResponse
    public var getDocument: @Sendable (String) async throws -> RegulationDocument
    public var getDocumentComments: @Sendable (String) async throws -> [RegulationComment]
    public var getDocket: @Sendable (String) async throws -> RegulationDocket
    public var downloadAttachment: @Sendable (String, String) async throws -> Data

    // MARK: - FAR/DFARS Operations

    public var getFARContent: @Sendable (FARReference) async throws -> FARContent
    public var getDFARSContent: @Sendable (DFARSReference) async throws -> DFARSContent
    public var parseDITAContent: @Sendable (Data) async throws -> RegulationServiceContent
    public var searchFARClauses: @Sendable (String) async throws -> [FARClause]

    // MARK: - Subscription & Updates

    public var subscribeToUpdates: @Sendable (RegulationSubscription) async throws -> Void
    public var unsubscribeFromUpdates: @Sendable (String) async throws -> Void
    public var checkForUpdates: @Sendable ([RegulationCategory]) async throws -> [RegulationServiceUpdate]

    // MARK: - Batch Operations

    public var batchDownloadDocuments: @Sendable ([String]) async throws -> [RegulationDocument]
    public var batchSearchClauses: @Sendable ([String]) async throws -> [FARClause]

    public init(
        searchDocuments: @escaping @Sendable (RegulationSearchQuery) async throws -> RegulationSearchResponse,
        getDocument: @escaping @Sendable (String) async throws -> RegulationDocument,
        getDocumentComments: @escaping @Sendable (String) async throws -> [RegulationComment],
        getDocket: @escaping @Sendable (String) async throws -> RegulationDocket,
        downloadAttachment: @escaping @Sendable (String, String) async throws -> Data,
        getFARContent: @escaping @Sendable (FARReference) async throws -> FARContent,
        getDFARSContent: @escaping @Sendable (DFARSReference) async throws -> DFARSContent,
        parseDITAContent: @escaping @Sendable (Data) async throws -> RegulationServiceContent,
        searchFARClauses: @escaping @Sendable (String) async throws -> [FARClause],
        subscribeToUpdates: @escaping @Sendable (RegulationSubscription) async throws -> Void,
        unsubscribeFromUpdates: @escaping @Sendable (String) async throws -> Void,
        checkForUpdates: @escaping @Sendable ([RegulationCategory]) async throws -> [RegulationServiceUpdate],
        batchDownloadDocuments: @escaping @Sendable ([String]) async throws -> [RegulationDocument],
        batchSearchClauses: @escaping @Sendable ([String]) async throws -> [FARClause]
    ) {
        self.searchDocuments = searchDocuments
        self.getDocument = getDocument
        self.getDocumentComments = getDocumentComments
        self.getDocket = getDocket
        self.downloadAttachment = downloadAttachment
        self.getFARContent = getFARContent
        self.getDFARSContent = getDFARSContent
        self.parseDITAContent = parseDITAContent
        self.searchFARClauses = searchFARClauses
        self.subscribeToUpdates = subscribeToUpdates
        self.unsubscribeFromUpdates = unsubscribeFromUpdates
        self.checkForUpdates = checkForUpdates
        self.batchDownloadDocuments = batchDownloadDocuments
        self.batchSearchClauses = batchSearchClauses
    }
}

// MARK: - Models

public struct RegulationSearchQuery: Equatable {
    public let searchTerm: String
    public let documentType: RegulationDocumentType?
    public let agency: String?
    public let docketId: String?
    public let postedDate: DateRange?
    public let commentDueDate: DateRange?
    public let sortBy: SortField
    public let sortOrder: SortOrder
    public let pageSize: Int
    public let pageNumber: Int

    public enum RegulationDocumentType: String {
        case rule = "Rule"
        case proposedRule = "Proposed Rule"
        case notice = "Notice"
        case publicSubmission = "Public Submission"
        case supportingMaterial = "Supporting & Related Material"
    }

    public enum SortField: String {
        case postedDate
        case title
        case documentId
        case commentDueDate
    }

    public enum SortOrder: String {
        case ascending = "ASC"
        case descending = "DESC"
    }

    public struct DateRange: Equatable {
        public let startDate: Date
        public let endDate: Date
    }

    public init(
        searchTerm: String,
        documentType: RegulationDocumentType? = nil,
        agency: String? = nil,
        docketId: String? = nil,
        postedDate: DateRange? = nil,
        commentDueDate: DateRange? = nil,
        sortBy: SortField = .postedDate,
        sortOrder: SortOrder = .descending,
        pageSize: Int = 25,
        pageNumber: Int = 1
    ) {
        self.searchTerm = searchTerm
        self.documentType = documentType
        self.agency = agency
        self.docketId = docketId
        self.postedDate = postedDate
        self.commentDueDate = commentDueDate
        self.sortBy = sortBy
        self.sortOrder = sortOrder
        self.pageSize = pageSize
        self.pageNumber = pageNumber
    }
}

public struct RegulationSearchResponse: Equatable {
    public let documents: [RegulationDocument]
    public let totalCount: Int
    public let pageNumber: Int
    public let pageSize: Int
    public let hasMoreResults: Bool
}

public struct RegulationDocument: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public let documentId: String
    public let documentType: String
    public let title: String
    public let docketId: String
    public let docketTitle: String?
    public let agency: String
    public let postedDate: Date
    public let commentDueDate: Date?
    public let effectiveDate: Date?
    public let summary: String?
    public let fullTextUrl: String?
    public let attachments: [Attachment]
    public let metadata: [String: String]

    public struct Attachment: Equatable, Codable, Sendable {
        public let fileFormats: [FileFormat]
        public let title: String

        public struct FileFormat: Equatable, Codable, Sendable {
            public let fileUrl: String
            public let format: String
            public let size: Int?
        }
    }
}

public struct RegulationComment: Identifiable, Equatable {
    public let id: String
    public let commentId: String
    public let documentId: String
    public let postedDate: Date
    public let firstName: String?
    public let lastName: String?
    public let organization: String?
    public let comment: String
    public let attachments: [RegulationDocument.Attachment]
}

public struct RegulationDocket: Identifiable, Equatable {
    public let id: String
    public let docketId: String
    public let title: String
    public let agency: String
    public let objectId: String
    public let category: String?
    public let numberOfComments: Int
    public let metadata: [String: String]
}

public struct FARReference: Equatable {
    public let part: String
    public let subpart: String?
    public let section: String?
    public let paragraph: String?

    public var fullReference: String {
        var ref = "FAR \(part)"
        if let subpart {
            ref += ".\(subpart)"
        }
        if let section {
            ref += ".\(section)"
        }
        if let paragraph {
            ref += "(\(paragraph))"
        }
        return ref
    }
}

public struct DFARSReference: Equatable {
    public let part: String
    public let subpart: String?
    public let section: String?
    public let paragraph: String?

    public var fullReference: String {
        var ref = "DFARS \(part)"
        if let subpart {
            ref += ".\(subpart)"
        }
        if let section {
            ref += ".\(section)"
        }
        if let paragraph {
            ref += "(\(paragraph))"
        }
        return ref
    }
}

public struct FARContent: Equatable, Codable {
    public let reference: String
    public let title: String
    public let content: String
    public let effectiveDate: Date
    public let lastRevised: Date
    public let relatedClauses: [String]
    public let prescribedForms: [String]
    public let htmlContent: String?
    public let ditaContent: Data?
}

public struct DFARSContent: Equatable, Codable {
    public let reference: String
    public let title: String
    public let content: String
    public let effectiveDate: Date
    public let lastRevised: Date
    public let relatedClauses: [String]
    public let implementsFAR: [String]
    public let htmlContent: String?
    public let ditaContent: Data?
}

public struct FARClause: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public let clauseNumber: String
    public let title: String
    public let text: String
    public let alternates: [String]
    public let prescribedIn: String?
    public let lastUpdated: Date
    public let isDeviation: Bool
    public let applicability: [String]
}

public struct RegulationServiceContent: Equatable {
    public let title: String
    public let content: String
    public let structure: DocumentStructure
    public let metadata: [String: String]

    public struct DocumentStructure: Equatable {
        public let sections: [Section]

        public struct Section: Equatable {
            public let id: String
            public let title: String
            public let level: Int
            public let content: String
            public let subsections: [Section]
        }
    }
}

public enum RegulationCategory: String, CaseIterable {
    case far = "Federal Acquisition Regulation"
    case dfars = "Defense FAR Supplement"
    case federalRegister = "Federal Register"
    case executiveOrders = "Executive Orders"
    case policyLetters = "Policy Letters"
    case classDeviations = "Class Deviations"
    case smallBusiness = "Small Business"
    case laborStandards = "Labor Standards"
    case sustainability = "Sustainability"
    case cybersecurity = "Cybersecurity"
}

public struct RegulationServiceUpdate: Equatable {
    public let id = UUID()
    public let type: UpdateType
    public let title: String
    public let description: String
    public let effectiveDate: Date
    public let source: String
    public let documentId: String?

    public enum UpdateType: String {
        case farUpdate = "FAR Update"
        case dfarsUpdate = "DFARS Update"
        case policyChange = "Policy Change"
        case newRegulation = "New Regulation"
        case clarification = "Clarification"
    }
}

public struct RegulationSubscription: Equatable {
    public let id: String
    public let userId: String
    public let category: RegulationCategory
    public let keywords: [String]
    public let agencies: [String]
    public let docketIds: [String]
    public let notificationFrequency: NotificationFrequency
    public let isActive: Bool

    public enum NotificationFrequency: String, CaseIterable {
        case realtime
        case daily
        case weekly
        case monthly
    }
}

// MARK: - API Configuration

public enum RegulationsGovConfig {
    public static let baseURL = "https://api.regulations.gov/v4"
    public static let apiKey = ProcessInfo.processInfo.environment["REGULATIONS_GOV_API_KEY"] ?? ""

    public static var headers: [String: String] {
        [
            "X-Api-Key": apiKey,
            "Content-Type": "application/json",
        ]
    }
}

public enum GSADITAConfig {
    public static let baseURL = "https://www.acquisition.gov"
    public static let farURL = "\(baseURL)/far"
    public static let dfarsURL = "\(baseURL)/dfars"
    public static let ditaToolkitPath = "/dita-ot"
}

// MARK: - Dependency Implementation

extension RegulationService: DependencyKey {
    public static var liveValue: RegulationService {
        let urlSession = URLSession.shared
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return RegulationService(
            searchDocuments: { query in
                guard var components = URLComponents(string: "\(RegulationsGovConfig.baseURL)/documents") else {
                    throw RegulationServiceError.apiError("Invalid base URL")
                }
                var queryItems: [URLQueryItem] = [
                    URLQueryItem(name: "filter[searchTerm]", value: query.searchTerm),
                    URLQueryItem(name: "sort", value: "\(query.sortOrder.rawValue == "ASC" ? "" : "-")\(query.sortBy.rawValue)"),
                    URLQueryItem(name: "page[size]", value: String(query.pageSize)),
                    URLQueryItem(name: "page[number]", value: String(query.pageNumber)),
                ]

                if let documentType = query.documentType {
                    queryItems.append(URLQueryItem(name: "filter[documentType]", value: documentType.rawValue))
                }
                if let agency = query.agency {
                    queryItems.append(URLQueryItem(name: "filter[agencyId]", value: agency))
                }
                if let docketId = query.docketId {
                    queryItems.append(URLQueryItem(name: "filter[docketId]", value: docketId))
                }

                components.queryItems = queryItems

                guard let url = components.url else {
                    throw RegulationServiceError.apiError("Failed to construct URL")
                }
                var request = URLRequest(url: url)
                RegulationsGovConfig.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

                let (data, response) = try await urlSession.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200 ... 299).contains(httpResponse.statusCode)
                else {
                    throw RegulationServiceError.apiError("Invalid response")
                }

                // Parse the response
                let apiResponse = try decoder.decode(RegulationsGovAPIResponse.self, from: data)

                return RegulationSearchResponse(
                    documents: apiResponse.data.map { $0.toRegulationDocument() },
                    totalCount: apiResponse.meta.totalCount,
                    pageNumber: query.pageNumber,
                    pageSize: query.pageSize,
                    hasMoreResults: apiResponse.meta.hasNextPage
                )
            },

            getDocument: { documentId in
                guard let url = URL(string: "\(RegulationsGovConfig.baseURL)/documents/\(documentId)") else {
                    throw RegulationServiceError.apiError("Invalid document URL")
                }
                var request = URLRequest(url: url)
                RegulationsGovConfig.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

                let (data, _) = try await urlSession.data(for: request)
                let apiDocument = try decoder.decode(RegulationsGovDocument.self, from: data)

                return apiDocument.data.toRegulationDocument()
            },

            getDocumentComments: { documentId in
                guard let url = URL(string: "\(RegulationsGovConfig.baseURL)/comments?filter[commentOnId]=\(documentId)") else {
                    throw RegulationServiceError.apiError("Invalid comments URL")
                }
                var request = URLRequest(url: url)
                RegulationsGovConfig.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

                let (data, _) = try await urlSession.data(for: request)
                let apiResponse = try decoder.decode(RegulationsGovCommentsResponse.self, from: data)

                return apiResponse.data.map { $0.toRegulationComment() }
            },

            getDocket: { docketId in
                guard let url = URL(string: "\(RegulationsGovConfig.baseURL)/dockets/\(docketId)") else {
                    throw RegulationServiceError.apiError("Invalid docket URL")
                }
                var request = URLRequest(url: url)
                RegulationsGovConfig.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

                let (data, _) = try await urlSession.data(for: request)
                let apiDocket = try decoder.decode(RegulationsGovDocket.self, from: data)

                return apiDocket.data.toRegulationDocket()
            },

            downloadAttachment: { _, attachmentUrl in
                guard let url = URL(string: attachmentUrl) else {
                    throw RegulationServiceError.apiError("Invalid attachment URL")
                }
                var request = URLRequest(url: url)
                RegulationsGovConfig.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

                let (data, _) = try await urlSession.data(for: request)
                return data
            },

            getFARContent: { reference in
                // Construct URL based on FAR reference
                let urlPath = reference.fullReference.replacingOccurrences(of: " ", with: "_")
                guard let url = URL(string: "\(GSADITAConfig.farURL)/\(urlPath).dita") else {
                    throw RegulationServiceError.apiError("Invalid FAR URL")
                }

                let (data, _) = try await urlSession.data(from: url)

                // Parse DITA content
                let content = try parseDITAData(data)

                return FARContent(
                    reference: reference.fullReference,
                    title: content.title,
                    content: content.content,
                    effectiveDate: Date(), // Would parse from DITA metadata
                    lastRevised: Date(),
                    relatedClauses: extractRelatedClauses(from: content.content),
                    prescribedForms: extractPrescribedForms(from: content.content),
                    htmlContent: nil,
                    ditaContent: data
                )
            },

            getDFARSContent: { reference in
                let urlPath = reference.fullReference.replacingOccurrences(of: " ", with: "_")
                guard let url = URL(string: "\(GSADITAConfig.dfarsURL)/\(urlPath).dita") else {
                    throw RegulationServiceError.apiError("Invalid DFARS URL")
                }

                let (data, _) = try await urlSession.data(from: url)

                let content = try parseDITAData(data)

                return DFARSContent(
                    reference: reference.fullReference,
                    title: content.title,
                    content: content.content,
                    effectiveDate: Date(),
                    lastRevised: Date(),
                    relatedClauses: extractRelatedClauses(from: content.content),
                    implementsFAR: extractImplementsFAR(from: content.content),
                    htmlContent: nil,
                    ditaContent: data
                )
            },

            parseDITAContent: { data in
                try parseDITAData(data)
            },

            searchFARClauses: { _ in
                // This would search through indexed FAR clauses
                // For now, return mock data
                [
                    FARClause(
                        id: "52.204-25",
                        clauseNumber: "52.204-25",
                        title: "Prohibition on Contracting for Certain Telecommunications",
                        text: "The Contractor shall not provide...",
                        alternates: [],
                        prescribedIn: "4.2102",
                        lastUpdated: Date(),
                        isDeviation: false,
                        applicability: ["All contracts"]
                    ),
                ]
            },

            subscribeToUpdates: { subscription in
                // Store subscription in user defaults or persistent storage
                var subscriptions = loadSubscriptions()
                subscriptions.append(subscription)
                saveSubscriptions(subscriptions)
            },

            unsubscribeFromUpdates: { subscriptionId in
                var subscriptions = loadSubscriptions()
                subscriptions.removeAll { $0.id == subscriptionId }
                saveSubscriptions(subscriptions)
            },

            checkForUpdates: { categories in
                // Check for updates in specified categories
                var updates: [RegulationServiceUpdate] = []

                for category in categories {
                    // Make API calls to check for updates
                    let categoryUpdates = try await fetchUpdatesForCategory(category)
                    updates.append(contentsOf: categoryUpdates)
                }

                return updates
            },

            batchDownloadDocuments: { documentIds in
                try await withThrowingTaskGroup(of: RegulationDocument.self) { group in
                    for documentId in documentIds {
                        group.addTask {
                            try await RegulationService.liveValue.getDocument(documentId)
                        }
                    }

                    var documents: [RegulationDocument] = []
                    for try await document in group {
                        documents.append(document)
                    }
                    return documents
                }
            },

            batchSearchClauses: { clauseNumbers in
                try await withThrowingTaskGroup(of: [FARClause].self) { group in
                    for clauseNumber in clauseNumbers {
                        group.addTask {
                            try await RegulationService.liveValue.searchFARClauses(clauseNumber)
                        }
                    }

                    var allClauses: [FARClause] = []
                    for try await clauses in group {
                        allClauses.append(contentsOf: clauses)
                    }
                    return allClauses
                }
            }
        )
    }
}

// MARK: - Helper Functions

private func parseDITAData(_ data: Data) throws -> RegulationServiceContent {
    // Parse DITA XML content
    // This is a simplified implementation
    let content = String(data: data, encoding: .utf8) ?? ""

    return RegulationServiceContent(
        title: "Parsed DITA Content",
        content: content,
        structure: RegulationServiceContent.DocumentStructure(sections: []),
        metadata: [:]
    )
}

private func extractRelatedClauses(from content: String) -> [String] {
    // Extract FAR/DFARS references from content
    let pattern = #"(FAR|DFARS)\s+\d+\.\d+(-\d+)?"#
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let matches = regex?.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content)) ?? []

    return matches.compactMap { match in
        guard let range = Range(match.range, in: content) else { return nil }
        return String(content[range])
    }
}

private func extractPrescribedForms(from content: String) -> [String] {
    // Extract form references
    let pattern = #"(SF|DD|OF)\s*\d+"#
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let matches = regex?.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content)) ?? []

    return matches.compactMap { match in
        guard let range = Range(match.range, in: content) else { return nil }
        return String(content[range])
    }
}

private func extractImplementsFAR(from content: String) -> [String] {
    // Extract FAR implementations from DFARS content
    let pattern = #"implements\s+FAR\s+\d+\.\d+(-\d+)?"#
    let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    let matches = regex?.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content)) ?? []

    return matches.compactMap { match in
        guard let range = Range(match.range, in: content) else { return nil }
        let text = String(content[range])
        return text.replacingOccurrences(of: "implements ", with: "", options: .caseInsensitive)
    }
}

private func loadSubscriptions() -> [RegulationSubscription] {
    // Load from persistent storage
    []
}

private func saveSubscriptions(_: [RegulationSubscription]) {
    // Save to persistent storage
}

private func fetchUpdatesForCategory(_: RegulationCategory) async throws -> [RegulationServiceUpdate] {
    // Fetch updates for specific category
    []
}

// MARK: - API Response Models

private struct RegulationsGovAPIResponse: Decodable {
    let data: [RegulationsGovDocumentData]
    let meta: Meta

    struct Meta: Decodable {
        let totalCount: Int
        let pageCount: Int
        let hasNextPage: Bool
    }
}

private struct RegulationsGovDocument: Decodable {
    let data: RegulationsGovDocumentData
}

private struct RegulationsGovDocumentData: Decodable {
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable {
        let documentId: String
        let documentType: String
        let title: String
        let docketId: String?
        let agencyId: String
        let postedDate: String
        let commentDueDate: String?
        let effectiveDate: String?
        let summary: String?
    }

    func toRegulationDocument() -> RegulationDocument {
        let dateFormatter = ISO8601DateFormatter()

        return RegulationDocument(
            id: id,
            documentId: attributes.documentId,
            documentType: attributes.documentType,
            title: attributes.title,
            docketId: attributes.docketId ?? "",
            docketTitle: nil,
            agency: attributes.agencyId,
            postedDate: dateFormatter.date(from: attributes.postedDate) ?? Date(),
            commentDueDate: attributes.commentDueDate.flatMap { dateFormatter.date(from: $0) },
            effectiveDate: attributes.effectiveDate.flatMap { dateFormatter.date(from: $0) },
            summary: attributes.summary,
            fullTextUrl: nil,
            attachments: [],
            metadata: [:]
        )
    }
}

private struct RegulationsGovCommentsResponse: Decodable {
    let data: [RegulationsGovCommentData]
}

private struct RegulationsGovCommentData: Decodable {
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable {
        let commentId: String
        let documentId: String
        let postedDate: String
        let firstName: String?
        let lastName: String?
        let organization: String?
        let comment: String
    }

    func toRegulationComment() -> RegulationComment {
        let dateFormatter = ISO8601DateFormatter()

        return RegulationComment(
            id: id,
            commentId: attributes.commentId,
            documentId: attributes.documentId,
            postedDate: dateFormatter.date(from: attributes.postedDate) ?? Date(),
            firstName: attributes.firstName,
            lastName: attributes.lastName,
            organization: attributes.organization,
            comment: attributes.comment,
            attachments: []
        )
    }
}

private struct RegulationsGovDocket: Decodable {
    let data: RegulationsGovDocketData
}

private struct RegulationsGovDocketData: Decodable {
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable {
        let docketId: String
        let title: String
        let agencyId: String
        let objectId: String
        let category: String?
    }

    func toRegulationDocket() -> RegulationDocket {
        RegulationDocket(
            id: id,
            docketId: attributes.docketId,
            title: attributes.title,
            agency: attributes.agencyId,
            objectId: attributes.objectId,
            category: attributes.category,
            numberOfComments: 0,
            metadata: [:]
        )
    }
}

// MARK: - Errors

public enum RegulationServiceError: LocalizedError {
    case apiError(String)
    case networkError(Error)
    case parsingError(String)
    case invalidAPIKey
    case rateLimitExceeded

    public var errorDescription: String? {
        switch self {
        case let .apiError(message):
            "API Error: \(message)"
        case let .networkError(error):
            "Network Error: \(error.localizedDescription)"
        case let .parsingError(message):
            "Parsing Error: \(message)"
        case .invalidAPIKey:
            "Invalid API Key"
        case .rateLimitExceeded:
            "API Rate Limit Exceeded"
        }
    }
}

public extension DependencyValues {
    var regulationService: RegulationService {
        get { self[RegulationService.self] }
        set { self[RegulationService.self] = newValue }
    }
}
