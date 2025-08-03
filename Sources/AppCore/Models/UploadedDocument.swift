import Foundation

public struct UploadedDocument: Equatable, Identifiable, Sendable, Codable {
    public let id: UUID
    public let fileName: String
    public let data: Data
    public let uploadDate: Date
    public let contentSummary: String?

    public init(id: UUID = UUID(), fileName: String, data: Data, uploadDate: Date = Date(), contentSummary: String? = nil) {
        self.id = id
        self.fileName = fileName
        self.data = data
        self.uploadDate = uploadDate
        self.contentSummary = contentSummary
    }
}
