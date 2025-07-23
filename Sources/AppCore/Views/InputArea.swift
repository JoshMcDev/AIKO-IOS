import ComposableArchitecture
import SwiftUI

public struct InputArea: View {
    let requirements: String
    let isGenerating: Bool
    let uploadedDocuments: [UploadedDocument]
    let isChatMode: Bool
    let isRecording: Bool
    let onRequirementsChanged: (String) -> Void
    let onAnalyzeRequirements: () -> Void
    let onEnhancePrompt: () -> Void
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onShowDocumentPicker: () -> Void
    let onShowImagePicker: () -> Void
    let onRemoveDocument: (UploadedDocument.ID) -> Void

    @State private var showingUploadOptions = false
    @State private var chatMessages: [ChatMessage] = []

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date = .init()
    }

    public init(
        requirements: String,
        isGenerating: Bool,
        uploadedDocuments: [UploadedDocument],
        isChatMode: Bool,
        isRecording: Bool,
        onRequirementsChanged: @escaping (String) -> Void,
        onAnalyzeRequirements: @escaping () -> Void,
        onEnhancePrompt: @escaping () -> Void,
        onStartRecording: @escaping () -> Void,
        onStopRecording: @escaping () -> Void,
        onShowDocumentPicker: @escaping () -> Void,
        onShowImagePicker: @escaping () -> Void,
        onRemoveDocument: @escaping (UploadedDocument.ID) -> Void
    ) {
        self.requirements = requirements
        self.isGenerating = isGenerating
        self.uploadedDocuments = uploadedDocuments
        self.isChatMode = isChatMode
        self.isRecording = isRecording
        self.onRequirementsChanged = onRequirementsChanged
        self.onAnalyzeRequirements = onAnalyzeRequirements
        self.onEnhancePrompt = onEnhancePrompt
        self.onStartRecording = onStartRecording
        self.onStopRecording = onStopRecording
        self.onShowDocumentPicker = onShowDocumentPicker
        self.onShowImagePicker = onShowImagePicker
        self.onRemoveDocument = onRemoveDocument
    }

    public var body: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: Theme.Spacing.medium) {
                // Uploaded Documents
                if !uploadedDocuments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.small) {
                            ForEach(uploadedDocuments) { document in
                                UploadedDocumentCard(
                                    document: document,
                                    onRemove: { onRemoveDocument(document.id) }
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.large)
                    }
                    .frame(height: 60)
                }
                // Input container
                HStack(spacing: 0) {
                    // Text input field with custom placeholder
                    ZStack(alignment: .leading) {
                        TextField("", text: .init(
                            get: { requirements },
                            set: { @Sendable (value: String) in onRequirementsChanged(value) }
                        ), prompt: Text("...").foregroundColor(.gray), axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding(.leading, Theme.Spacing.large)
                            .padding(.vertical, Theme.Spacing.medium)
                            .padding(.trailing, Theme.Spacing.small)
                            .lineLimit(1 ... 4)
                    }

                    // Action buttons
                    HStack(spacing: Theme.Spacing.small) {
                        // Enhance prompt button
                        Button(action: {
                            if !requirements.isEmpty {
                                onEnhancePrompt()
                            }
                        }, label: {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundColor(!requirements.isEmpty ? .yellow : .secondary)
                                .frame(width: 32, height: 32)
                                .scaleEffect(!requirements.isEmpty ? 1.0 : 0.9)
                                .animation(.easeInOut(duration: 0.2), value: requirements.isEmpty)
                        })
                        .disabled(requirements.isEmpty || isGenerating)

                        // Upload options
                        Button(action: { showingUploadOptions.toggle() }, label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                        })
                        .confirmationDialog("Add Content", isPresented: $showingUploadOptions) {
                            Button("📄 Upload Documents") {
                                onShowDocumentPicker()
                            }
                            #if os(iOS)
                                Button("📷 Scan Document") {
                                    onShowImagePicker()
                                }
                            #endif
                            Button("Cancel", role: .cancel) {}
                        }

                        // Voice input
                        Button(action: {
                            if isRecording {
                                onStopRecording()
                            } else {
                                onStartRecording()
                            }
                        }, label: {
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .font(.title3)
                                .foregroundColor(isRecording ? .red : .secondary)
                                .frame(width: 32, height: 32)
                                .scaleEffect(isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isRecording)
                        })
                        .disabled(isGenerating && !isRecording)

                        // Analyze button
                        Button(action: onAnalyzeRequirements) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: requirements.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(requirements.isEmpty ? .secondary : .white)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .background(
                            Group {
                                if !requirements.isEmpty || !uploadedDocuments.isEmpty, !isGenerating {
                                    Circle()
                                        .fill(Theme.Colors.aikoPrimary)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                }
                            }
                        )
                        .disabled((requirements.isEmpty && uploadedDocuments.isEmpty) || isGenerating)
                        .scaleEffect(requirements.isEmpty ? 1.0 : 1.1)
                        .animation(.easeInOut(duration: 0.2), value: requirements.isEmpty)
                    }
                    .padding(.trailing, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.small)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Theme.Colors.aikoSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.large)
            .background(Color.black)
        }
    }
}

public struct UploadedDocumentCard: View {
    let document: UploadedDocument
    let onRemove: () -> Void

    public var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: fileIcon(for: document.fileName))
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.fileName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(formattedFileSize(document.data.count))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(Theme.Colors.aikoSecondary)
        )
    }

    func fileIcon(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "doc", "docx": return "doc.text.fill"
        case "jpg", "jpeg", "png": return "photo.fill"
        default: return "doc.fill"
        }
    }

    func formattedFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
