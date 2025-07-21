import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI
#if os(macOS)
    import AppKit
#endif

@Reducer
public struct DocumentExecutionFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var isExecuting: Bool = false
        public var executionProgress: Double = 0.0
        public var executionStatus: ExecutionStatus = .idle
        public var generatedContent: String = ""
        public var executionError: String?
        public var showingExecutionView: Bool = false
        public var showingInformationGathering: Bool = false
        public var showingFARUpdatesView: Bool = false
        public var informationQuestions: [InformationQuestion] = []
        public var currentQuestionIndex: Int = 0
        public var gatheredInformation: [String: String] = [:]

        // Category being executed
        public var executingCategory: DocumentCategory?
        public var executingDocumentTypes: Set<DocumentType> = []
        public var executingDFDocumentTypes: Set<DFDocumentType> = []

        // Document being executed
        public var currentDocument: GeneratedDocument?
        public var downloadedFileURL: URL?
        public var showingEmailComposer: Bool = false

        public init() {}
    }

    public enum ExecutionStatus: Equatable {
        case idle
        case checkingInformation
        case gatheringInformation
        case generating
        case completed
        case failed(String)
    }

    public struct InformationQuestion: Equatable, Identifiable {
        public let id = UUID()
        public let question: String
        public let fieldType: FieldType
        public let placeholder: String
        public let isRequired: Bool

        public enum FieldType: Equatable {
            case text
            case multilineText
            case number
            case date
            case selection([String])
        }
    }

    public enum Action {
        case executeCategory(DocumentCategory, Set<DocumentType>, Set<DFDocumentType>)
        case checkInformationSufficiency
        case informationCheckCompleted(Bool, [InformationQuestion])
        case showInformationGathering(Bool)
        case answerQuestion(String, String)
        case submitGatheredInformation
        case startGeneration
        case updateProgress(Double)
        case generationCompleted(String)
        case generationFailed(String)
        case copyToClipboard
        case downloadDocument
        case emailDocument
        case showExecutionView(Bool)
        case showFARUpdatesView(Bool)
        case reset
    }

    @Dependency(\.aiDocumentGenerator) var aiDocumentGenerator
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .executeCategory(category, documentTypes, dfDocumentTypes):
                // Special handling for FAR Updates
                if documentTypes.contains(.farUpdates) {
                    state.showingFARUpdatesView = true
                    return .none
                }

                state.executingCategory = category
                state.executingDocumentTypes = documentTypes
                state.executingDFDocumentTypes = dfDocumentTypes
                state.showingExecutionView = true
                state.executionStatus = .checkingInformation

                return .send(.checkInformationSufficiency)

            case .checkInformationSufficiency:
                state.isExecuting = true

                return .run { [documentTypes = state.executingDocumentTypes,
                               dfDocumentTypes = state.executingDFDocumentTypes] send in
                        // Special handling for FAR Updates
                        if documentTypes.contains(.farUpdates) {
                            // FAR Updates doesn't need information gathering
                            await send(.informationCheckCompleted(true, []))
                            return
                        }

                        // Simulate checking if we have enough information
                        // In real implementation, this would call the LLM to check
                        try await clock.sleep(for: .seconds(1))

                        // For demo, let's say we need more info for certain document types
                        let needsMoreInfo = documentTypes.contains(.acquisitionPlan) ||
                            documentTypes.contains(.costEstimate) ||
                            dfDocumentTypes.contains(.jaOtherThanFullOpenCompetition)

                        if needsMoreInfo {
                            let questions = [
                                InformationQuestion(
                                    question: "What is the estimated contract value?",
                                    fieldType: .number,
                                    placeholder: "Enter amount in USD",
                                    isRequired: true
                                ),
                                InformationQuestion(
                                    question: "What is the period of performance?",
                                    fieldType: .text,
                                    placeholder: "e.g., 12 months",
                                    isRequired: true
                                ),
                                InformationQuestion(
                                    question: "Please describe the primary objectives of this acquisition:",
                                    fieldType: .multilineText,
                                    placeholder: "Enter detailed objectives...",
                                    isRequired: true
                                )
                            ]

                            await send(.informationCheckCompleted(false, questions))
                        } else {
                            await send(.informationCheckCompleted(true, []))
                        }
                }

            case let .informationCheckCompleted(hasSufficientInfo, questions):
                state.isExecuting = false

                if hasSufficientInfo {
                    state.executionStatus = .generating
                    return .send(.startGeneration)
                } else {
                    state.informationQuestions = questions
                    state.currentQuestionIndex = 0
                    state.executionStatus = .gatheringInformation
                    state.showingInformationGathering = true
                    return .none
                }

            case let .showInformationGathering(show):
                state.showingInformationGathering = show
                return .none

            case let .answerQuestion(questionId, answer):
                state.gatheredInformation[questionId] = answer

                // Move to next question if available
                if state.currentQuestionIndex < state.informationQuestions.count - 1 {
                    state.currentQuestionIndex += 1
                } else {
                    // All questions answered, submit
                    return .send(.submitGatheredInformation)
                }
                return .none

            case .submitGatheredInformation:
                state.showingInformationGathering = false
                state.executionStatus = .generating
                return .send(.startGeneration)

            case .startGeneration:
                state.isExecuting = true
                state.executionProgress = 0.0

                return .run { [documentTypes = state.executingDocumentTypes,
                               dfDocumentTypes = state.executingDFDocumentTypes] send in
                        // Simulate document generation with progress updates
                        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                            try await clock.sleep(for: .milliseconds(500))
                            await send(.updateProgress(progress))
                        }

                        // Generate mock content based on selected documents
                        var content = "# Generated Documents\n\n"

                        for docType in documentTypes {
                            content += "## \(docType.rawValue)\n\n"
                            content += "This is the generated content for \(docType.rawValue).\n"
                            content += "Based on the requirements and gathered information.\n\n"
                        }

                        for dfDocType in dfDocumentTypes {
                            content += "## \(dfDocType.rawValue)\n\n"
                            content += "This is the generated determination and findings for \(dfDocType.rawValue).\n"
                            content += "FAR Reference: \(dfDocType.farReference)\n\n"
                        }

                        await send(.generationCompleted(content))
                }

            case let .updateProgress(progress):
                state.executionProgress = progress
                return .none

            case let .generationCompleted(content):
                state.isExecuting = false
                state.executionProgress = 1.0
                state.generatedContent = content
                state.executionStatus = .completed
                return .none

            case let .generationFailed(error):
                state.isExecuting = false
                state.executionError = error
                state.executionStatus = .failed(error)
                return .none

            case .copyToClipboard:
                // Convert content to RTF and copy both plain text and RTF
                let (rtfString, _) = RTFFormatter.convertToRTF(state.generatedContent)

                #if os(iOS)
                    UIPasteboard.general.string = state.generatedContent
                    if let rtfData = rtfString.data(using: .utf8) {
                        UIPasteboard.general.setData(rtfData, forPasteboardType: "public.rtf")
                    }
                #else
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(state.generatedContent, forType: .string)
                    if let rtfData = rtfString.data(using: .utf8) {
                        NSPasteboard.general.setData(rtfData, forType: .rtf)
                    }
                #endif
                return .none

            case .downloadDocument:
                guard let document = state.currentDocument else {
                    // If no current document, try to get from generated content
                    guard !state.generatedContent.isEmpty else { return .none }

                    // Create a document from generated content
                    let tempDoc = GeneratedDocument(
                        title: "Generated Document",
                        documentType: .sow,
                        content: state.generatedContent
                    )
                    state.currentDocument = tempDoc
                    return .send(.downloadDocument)
                }

                // Create file name based on document type or title
                let documentName = document.documentType?.rawValue ?? document.title
                let fileName = "\(documentName.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).rtf"

                #if os(iOS)
                    // On iOS, save to Documents directory and show activity controller
                    if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = documentsPath.appendingPathComponent(fileName)

                        do {
                            let (rtfString, _) = RTFFormatter.convertToRTF(document.content)
                            if let rtfData = rtfString.data(using: .utf8) {
                                try rtfData.write(to: fileURL)
                                // File saved successfully - would need to present activity controller in the view
                                state.downloadedFileURL = fileURL
                            }
                        } catch {
                            print("Failed to save file: \(error)")
                            state.executionError = "Failed to save file: \(error.localizedDescription)"
                        }
                    }
                #else
                    // On macOS, use NSSavePanel
                    Task { @MainActor in
                        let savePanel = NSSavePanel()
                        savePanel.allowedContentTypes = [.rtf]
                        savePanel.nameFieldStringValue = fileName
                        savePanel.begin { result in
                            if result == .OK, let url = savePanel.url {
                                let (rtfString, _) = RTFFormatter.convertToRTF(document.content)
                                if let rtfData = rtfString.data(using: .utf8) {
                                    try? rtfData.write(to: url)
                                }
                            }
                        }
                    }
                #endif

                return .none

            case .emailDocument:
                guard let document = state.currentDocument else {
                    // If no current document, try to get from generated content
                    guard !state.generatedContent.isEmpty else { return .none }

                    // Create a document from generated content
                    let tempDoc = GeneratedDocument(
                        title: "Generated Document",
                        documentType: .sow,
                        content: state.generatedContent
                    )
                    state.currentDocument = tempDoc
                    return .send(.emailDocument)
                }

                #if os(iOS)
                    // On iOS, we need to present mail composer in the view
                    // Set a flag that the view can observe
                    state.showingEmailComposer = true
                #else
                    // On macOS, use NSSharingService
                    let documentName = document.documentType?.rawValue ?? document.title

                    let (rtfString, _) = RTFFormatter.convertToRTF(document.content)
                    if let rtfData = rtfString.data(using: .utf8) {
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent("\(documentName.replacingOccurrences(of: " ", with: "_")).rtf")

                        do {
                            try rtfData.write(to: tempURL)

                            let service = NSSharingService(named: .composeEmail)
                            service?.subject = "AIKO Generated Document: \(documentName)"
                            service?.recipients = []
                            service?.perform(withItems: [tempURL])
                        } catch {
                            print("Failed to prepare email: \(error)")
                            state.executionError = "Failed to prepare email: \(error.localizedDescription)"
                        }
                    }
                #endif

                return .none

            case let .showExecutionView(show):
                state.showingExecutionView = show
                if !show {
                    return .send(.reset)
                }
                return .none

            case let .showFARUpdatesView(show):
                state.showingFARUpdatesView = show
                return .none

            case .reset:
                state = State()
                return .none
            }
        }
    }
}
