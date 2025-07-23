import ComposableArchitecture
import Perception
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Enhanced Acquisition Chat View

public struct AcquisitionChatViewEnhanced: View {
    @Perception.Bindable var store: StoreOf<AcquisitionChatFeatureEnhanced>
    @FocusState private var isInputFocused: Bool

    public init(store: StoreOf<AcquisitionChatFeatureEnhanced>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                if let session = store.conversationSession {
                    ProgressIndicator(session: session)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }

                // Chat messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(store.messages) { message in
                                EnhancedMessageView(message: message)
                                    .id(message.id)
                            }

                            if store.isProcessing {
                                ProcessingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: store.messages.count) { _ in
                        withAnimation {
                            scrollProxy.scrollTo(store.messages.last?.id, anchor: .bottom)
                        }
                    }
                }

                Divider()

                // Smart suggestions
                if !(store.conversationSession?.remainingQuestions.isEmpty ?? true) {
                    SmartSuggestionsView(
                        question: store.currentQuestion,
                        onSelect: { suggestion in
                            store.send(.updateInput(suggestion))
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Input area
                EnhancedInputArea(
                    text: Binding(
                        get: { store.currentInput },
                        set: { store.send(.updateInput($0)) }
                    ),
                    placeholder: store.inputPlaceholder,
                    isProcessing: store.isProcessing,
                    onSend: {
                        store.send(.sendMessage)
                    },
                    onAttach: {
                        store.send(.showDocumentPicker)
                    }
                )
                .focused($isInputFocused)
                .padding()
            }
            .navigationTitle("New Acquisition")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Close") {
                        store.send(.closeChat)
                    },
                    trailing: Group {
                        if store.confidence != .low, !store.recommendedDocuments.isEmpty {
                            Button("Generate") {
                                store.send(.generateDocuments)
                            }
                            .foregroundColor(Theme.Colors.aikoPrimary)
                            .fontWeight(.semibold)
                        }
                    }
                )
            #else
                .toolbar {
                        ToolbarItem(placement: .navigation) {
                            Button("Close") {
                                store.send(.closeChat)
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            if store.confidence != .low, !store.recommendedDocuments.isEmpty {
                                Button("Generate") {
                                    store.send(.generateDocuments)
                                }
                                .foregroundColor(Theme.Colors.aikoPrimary)
                                .fontWeight(.semibold)
                            }
                        }
                    }
            #endif
        }
        .fileImporter(
            isPresented: Binding(
                get: { store.showingDocumentPicker },
                set: { _ in }
            ),
            allowedContentTypes: [.pdf, .plainText, .image, .data],
            allowsMultipleSelection: true
        ) { result in
            store.send(.dismissDocumentPicker)
            switch result {
            case let .success(urls):
                for url in urls {
                    if let data = try? Data(contentsOf: url) {
                        let document = EnhancedUploadedDocument(
                            fileName: url.lastPathComponent,
                            data: data
                        )
                        store.send(.documentPicked(document))
                    }
                }
            case let .failure(error):
                print("File picker error: \(error)")
            }
        }
        .alert(
            "Close Acquisition Assistant?",
            isPresented: Binding(
                get: { store.showingCloseConfirmation },
                set: { _ in }
            )
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Save & Close", role: .destructive) {
                store.send(.confirmClose)
            }
        } message: {
            Text("Your progress will be saved and you can continue later from My Acquisitions.")
        }
        .onAppear {
            store.send(.onAppear)
            isInputFocused = true
        }
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let session: ConversationSession

    var progress: Double {
        let total = session.questionHistory.count + session.remainingQuestions.count
        guard total > 0 else { return 0 }
        return Double(session.questionHistory.count) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(session.questionHistory.count) of \(session.questionHistory.count + session.remainingQuestions.count) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: confidenceIcon)
                        .font(.caption)
                    Text(session.confidence.description)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(confidenceColor)
            }

            ProgressView(value: progress)
                .tint(Theme.Colors.aikoPrimary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Theme.Colors.aikoCard)
        .cornerRadius(8)
    }

    var confidenceIcon: String {
        switch session.confidence {
        case .low: "circle"
        case .medium: "circle.lefthalf.filled"
        case .high: "circle.fill"
        case .veryHigh: "checkmark.circle.fill"
        }
    }

    var confidenceColor: Color {
        switch session.confidence {
        case .low: .red
        case .medium: .orange
        case .high: Theme.Colors.aikoPrimary
        case .veryHigh: .green
        }
    }
}

// MARK: - Message View

struct EnhancedMessageView: View {
    let message: EnhancedChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                Image(systemName: "brain")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.aikoPrimary)
                    .frame(width: 32, height: 32)
                    .background(Theme.Colors.aikoPrimary.opacity(0.1))
                    .clipShape(Circle())
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .user {
                    Text(message.content)
                        .padding(12)
                        .background(Theme.Colors.aikoPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    // Use markdown rendering for assistant messages
                    MarkdownText(content: message.content)
                        .padding(12)
                        .background(Theme.Colors.aikoCard)
                        .cornerRadius(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: message.role == .user ? 280 : .infinity)

            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

// MARK: - Processing Indicator

struct ProcessingIndicator: View {
    @State private var dots = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain")
                .font(.caption)
                .foregroundColor(Theme.Colors.aikoPrimary)

            Text("Thinking" + String(repeating: ".", count: dots))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.Colors.aikoCard)
        .cornerRadius(12)
        .onReceive(timer) { _ in
            dots = (dots + 1) % 4
        }
    }
}

// MARK: - Smart Suggestions View

struct SmartSuggestionsView: View {
    let question: DynamicQuestion?
    let onSelect: (String) -> Void

    var body: some View {
        if let question, let options = question.options, !options.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { suggestion in
                        Button(action: { onSelect(suggestion) }, label: {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.Colors.aikoPrimary.opacity(0.1))
                                .foregroundColor(Theme.Colors.aikoPrimary)
                                .cornerRadius(12)
                        })
                    }
                }
            }
        }
    }
}

// MARK: - Input Area

struct EnhancedInputArea: View {
    @Binding var text: String
    let placeholder: String
    let isProcessing: Bool
    let onSend: () -> Void
    let onAttach: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onAttach) {
                Image(systemName: "paperclip")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.aikoPrimary)
            }
            .disabled(isProcessing)

            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .disabled(isProcessing)
                .onSubmit {
                    if !text.isEmpty, !isProcessing {
                        onSend()
                    }
                }

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.isEmpty || isProcessing ? .gray : Theme.Colors.aikoPrimary)
            }
            .disabled(text.isEmpty || isProcessing)
        }
        .padding()
        .background(Theme.Colors.aikoCard)
        .cornerRadius(20)
    }
}

// MARK: - Markdown Text View

struct MarkdownText: View {
    let content: String

    var body: some View {
        // Simple markdown rendering - in production, use a proper markdown library
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMarkdown(content), id: \.self) { element in
                renderElement(element)
            }
        }
    }

    func parseMarkdown(_ text: String) -> [String] {
        text.components(separatedBy: "\n")
    }

    @ViewBuilder
    func renderElement(_ text: String) -> some View {
        if text.hasPrefix("# ") {
            Text(text.dropFirst(2))
                .font(.headline)
                .fontWeight(.bold)
        } else if text.hasPrefix("### ") {
            Text(text.dropFirst(4))
                .font(.subheadline)
                .fontWeight(.semibold)
        } else if text.hasPrefix("**"), text.hasSuffix("**"), text.count > 4 {
            let content = text.dropFirst(2).dropLast(2)
            Text(String(content))
                .fontWeight(.semibold)
        } else if text.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 4) {
                Text("•")
                Text(text.dropFirst(2))
            }
        } else if text.hasPrefix("*"), text.hasSuffix("*"), text.count > 2 {
            let content = text.dropFirst(1).dropLast(1)
            Text(String(content))
                .italic()
                .foregroundColor(.secondary)
        } else if !text.isEmpty {
            Text(text)
        }
    }
}

// MARK: - Preview

struct AcquisitionChatViewEnhanced_Previews: PreviewProvider {
    static var previews: some View {
        AcquisitionChatViewEnhanced(
            store: Store(initialState: AcquisitionChatFeatureEnhanced.State()) {
                AcquisitionChatFeatureEnhanced()
            }
        )
    }
}
