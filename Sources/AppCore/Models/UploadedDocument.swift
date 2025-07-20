import Foundation

public struct UploadedDocument: Equatable, Identifiable, Sendable {
    public let id = UUID()
    public let fileName: String
    public let data: Data
    public let uploadDate: Date
    public let contentSummary: String?

    public init(fileName: String, data: Data, uploadDate: Date = Date(), contentSummary: String? = nil) {
        self.fileName = fileName
        self.data = data
        self.uploadDate = uploadDate
        self.contentSummary = contentSummary
    }
}
