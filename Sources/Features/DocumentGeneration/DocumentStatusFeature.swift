import Foundation
import ComposableArchitecture

@Reducer
public struct DocumentStatusFeature {
    @ObservableState
    public struct State: Equatable {
        public var documentReadinessStatus: [DocumentType: DocumentStatus] = [:]
        public var selectedDocumentTypes: Set<DocumentType> = []
        public var selectedDFDocumentTypes: Set<DFDocumentType> = []
        public var recommendedDocuments: [DocumentType] = []
        
        public init() {
            // Initialize all document types as not ready
            for documentType in DocumentType.allCases {
                documentReadinessStatus[documentType] = .notReady
            }
        }
        
        // Computed properties for status overview
        public var readyDocuments: [DocumentType] {
            documentReadinessStatus.compactMap { key, value in
                value == .ready ? key : nil
            }
        }
        
        public var documentsNeedingInfo: [DocumentType] {
            documentReadinessStatus.compactMap { key, value in
                value == .needsMoreInfo ? key : nil
            }
        }
        
        public var notReadyDocuments: [DocumentType] {
            documentReadinessStatus.compactMap { key, value in
                value == .notReady ? key : nil
            }
        }
        
        public var canGenerateDocuments: Bool {
            let hasSelection = !selectedDocumentTypes.isEmpty || !selectedDFDocumentTypes.isEmpty
            let standardDocsReady = selectedDocumentTypes.allSatisfy { documentType in
                if let status = documentReadinessStatus[documentType] {
                    return status == .ready
                }
                return false
            }
            // D&F documents are always ready since they have their own templates
            return hasSelection && standardDocsReady
        }
    }
    
    public enum DocumentStatus: Equatable, CaseIterable {
        case notReady
        case needsMoreInfo
        case ready
        
        public var description: String {
            switch self {
            case .notReady:
                return "Not Ready"
            case .needsMoreInfo:
                return "Needs More Information"
            case .ready:
                return "Ready to Generate"
            }
        }
        
        public var icon: String {
            switch self {
            case .notReady:
                return "xmark.circle"
            case .needsMoreInfo:
                return "exclamationmark.circle"
            case .ready:
                return "checkmark.circle"
            }
        }
        
        public var color: String {
            switch self {
            case .notReady:
                return "red"
            case .needsMoreInfo:
                return "orange"
            case .ready:
                return "green"
            }
        }
    }
    
    public enum Action {
        case updateDocumentStatus(DocumentType, DocumentStatus)
        case updateMultipleStatuses([DocumentType: DocumentStatus])
        case documentTypeToggled(DocumentType)
        case dfDocumentTypeToggled(DFDocumentType)
        case setRecommendedDocuments([DocumentType])
        case selectRecommendedDocuments
        case clearAllSelections
        case updateStatusFromCompletenessScore(String, [DocumentType])
        case updateStatusFromGeneratedDocuments([GeneratedFile])
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .updateDocumentStatus(documentType, status):
                state.documentReadinessStatus[documentType] = status
                return .none
                
            case let .updateMultipleStatuses(statuses):
                for (documentType, status) in statuses {
                    state.documentReadinessStatus[documentType] = status
                }
                return .none
                
            case let .documentTypeToggled(documentType):
                // All features are unlocked - no tier checking needed
                if state.selectedDocumentTypes.contains(documentType) {
                    state.selectedDocumentTypes.remove(documentType)
                } else {
                    state.selectedDocumentTypes.insert(documentType)
                }
                return .none
                
            case let .dfDocumentTypeToggled(dfDocumentType):
                // All features are unlocked - no tier checking needed
                if state.selectedDFDocumentTypes.contains(dfDocumentType) {
                    state.selectedDFDocumentTypes.remove(dfDocumentType)
                } else {
                    state.selectedDFDocumentTypes.insert(dfDocumentType)
                }
                return .none
                
            case let .setRecommendedDocuments(documents):
                state.recommendedDocuments = documents
                
                // Update status for recommended documents
                for docType in DocumentType.allCases {
                    if documents.contains(docType) {
                        state.documentReadinessStatus[docType] = .ready
                    } else if state.documentReadinessStatus[docType] == .ready {
                        // Downgrade previously ready documents if not in new recommendations
                        state.documentReadinessStatus[docType] = .needsMoreInfo
                    }
                }
                return .none
                
            case .selectRecommendedDocuments:
                // Select all recommended documents - all features unlocked
                state.selectedDocumentTypes = Set(state.recommendedDocuments)
                return .none
                
            case .clearAllSelections:
                state.selectedDocumentTypes.removeAll()
                state.selectedDFDocumentTypes.removeAll()
                return .none
                
            case let .updateStatusFromCompletenessScore(response, recommendedDocs):
                let completenessScore = extractCompletenessScore(from: response)
                
                for docType in DocumentType.allCases {
                    if recommendedDocs.contains(docType) {
                        state.documentReadinessStatus[docType] = completenessScore >= 5 ? .ready : .needsMoreInfo
                    } else {
                        state.documentReadinessStatus[docType] = .notReady
                    }
                }
                
                state.recommendedDocuments = recommendedDocs
                return .none
                
            case let .updateStatusFromGeneratedDocuments(generatedFiles):
                // Mark document types as ready if they have generated files
                for file in generatedFiles {
                    if let fileType = file.fileType,
                       let docType = DocumentType(rawValue: fileType) {
                        state.documentReadinessStatus[docType] = .ready
                    }
                }
                return .none
            }
        }
    }
    
    // Helper function to extract completeness score from LLM response
    private func extractCompletenessScore(from response: String) -> Int {
        let patterns = [
            "COMPLETENESS ASSESSMENT: (\\d+)",
            "completeness.*?(\\d+)",
            "score.*?(\\d+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: response, options: [], range: NSRange(location: 0, length: response.count)),
               let scoreRange = Range(match.range(at: 1), in: response) {
                if let score = Int(response[scoreRange]) {
                    return score
                }
            }
        }
        
        return 5 // Default moderate score if not found
    }
}