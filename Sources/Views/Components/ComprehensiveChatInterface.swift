import AppCore
import Foundation
import SwiftUI
#if os(iOS)
import AVFoundation
import Speech
import UIKit
#endif

// MARK: - Comprehensive Chat Interface

/// Bottom chat interface with LLM integration, voice recording, and file upload
public struct ComprehensiveChatInterface: View {
    @Bindable var viewModel: AppViewModel
    @State private var currentMessage: String = ""
    @State private var isRecording: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var showingCamera: Bool = false
    @State private var messages: [ChatMessage] = []
    @State private var isGeneratingResponse: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Chat History (when messages exist)
            if !messages.isEmpty {
                chatHistoryView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Input Area
            inputAreaView
                .background(Color.black.opacity(0.95))
        }
        .animation(.easeInOut(duration: 0.3), value: messages.isEmpty)
    }

    // MARK: - Chat History View

    private var chatHistoryView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatMessageBubble(message: message)
                            .id(message.id)
                    }

                    if isGeneratingResponse {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                                .font(.caption)

                            Text("AIKO is thinking...")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .frame(maxHeight: 300)
            .background(Color.black.opacity(0.8))
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input Area View

    private var inputAreaView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))

            HStack(spacing: 12) {
                // Voice Recording Button
                VoiceRecordingButton(
                    isRecording: $isRecording,
                    onRecordingResult: handleVoiceRecordingResult
                )

                // Text Input Field
                HStack(spacing: 8) {
                    TextField("Ask AIKO about your acquisition requirements...", text: $currentMessage, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            sendMessage()
                        }

                    if !currentMessage.isEmpty {
                        Button(action: { currentMessage = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(20)

                // File Upload Button
                FileUploadButton(onFileSelected: handleFileUpload)

                // Camera Button
                #if os(iOS)
                CameraButton(onImageCaptured: handleImageCapture)
                #else
                CameraButton(onImageCaptured: { _ in })
                #endif

                // Send Button
                SendButton(
                    isEnabled: !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    isGenerating: isGeneratingResponse,
                    action: sendMessage
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(
            content: currentMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            isUser: true
        )

        messages.append(userMessage)
        let messageContent = currentMessage
        currentMessage = ""
        isTextFieldFocused = false

        // Generate AI response
        Task {
            await generateAIResponse(for: messageContent)
        }
    }

    private func generateAIResponse(for userMessage: String) async {
        isGeneratingResponse = true
        defer { isGeneratingResponse = false }

        // Simulate AI processing with context about acquisition requirements
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        let response = generateContextualResponse(for: userMessage)

        await MainActor.run {
            let aiMessage = ChatMessage(content: response, isUser: false)
            messages.append(aiMessage)
        }
    }

    private func generateContextualResponse(for userMessage: String) -> String {
        let lowerMessage = userMessage.lowercased()

        if lowerMessage.contains("requirement") {
            return "I can help you refine your acquisition requirements. Based on your current selection, I notice you may need to specify budget constraints, timeline, and compliance requirements. Would you like me to walk you through these?"
        } else if lowerMessage.contains("sam") || lowerMessage.contains("vendor") {
            return "I can help you with SAM.gov lookups and vendor research. Do you have specific vendors in mind, or would you like me to help you identify potential contractors for your acquisition?"
        } else if lowerMessage.contains("document") {
            return "I see you're working with document generation. Based on your selections, I can help determine which documents are ready to generate and which need more information. What specific documents are you most interested in?"
        } else if lowerMessage.contains("budget") || lowerMessage.contains("cost") {
            return "Budget planning is crucial for acquisition success. I can help you estimate costs, determine appropriate procurement thresholds, and identify required approval levels. What's your estimated budget range?"
        } else {
            return "I'm here to help with your acquisition planning. I can assist with requirements gathering, document generation, vendor research, and compliance guidance. What specific area would you like to focus on?"
        }
    }

    private func handleVoiceRecordingResult(_ text: String) {
        currentMessage = text
        sendMessage()
    }

    private func handleFileUpload(_ url: URL) {
        let fileName = url.lastPathComponent
        let fileMessage = ChatMessage(
            content: "📄 Uploaded file: \(fileName)",
            isUser: true
        )
        messages.append(fileMessage)

        // Process file content
        Task {
            await generateAIResponse(for: "I uploaded a file: \(fileName). Please analyze it for acquisition requirements.")
        }
    }

    #if os(iOS)
    private func handleImageCapture(_: UIImage) {
        let imageMessage = ChatMessage(
            content: "📸 Captured image for analysis",
            isUser: true
        )
        messages.append(imageMessage)

        Task {
            await generateAIResponse(for: "I captured an image that may contain acquisition-related information. Please analyze it.")
        }
    }
    #endif
}

// MARK: - Chat Message Bubble

struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(18)

                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .font(.caption)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.content)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(18)

                        Text("AIKO • \(formatTime(message.timestamp))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Voice Recording Button

struct VoiceRecordingButton: View {
    @Binding var isRecording: Bool
    let onRecordingResult: (String) -> Void

    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0

    var body: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .foregroundColor(isRecording ? .white : .white)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .scaleEffect(isRecording ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isRecording)
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        recordingDuration = 0

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                recordingDuration += 0.1

                // Auto-stop after 60 seconds
                if recordingDuration >= 60 {
                    stopRecording()
                }
            }
        }

        // Simulate voice recording
        // In real implementation, use AVAudioRecorder and Speech framework
    }

    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Simulate transcription result
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onRecordingResult("This is a simulated voice transcription for acquisition requirements discussion.")
        }
    }
}

// MARK: - File Upload Button

struct FileUploadButton: View {
    let onFileSelected: (URL) -> Void
    @State private var showingFilePicker = false

    var body: some View {
        Button(action: { showingFilePicker = true }) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                Image(systemName: "paperclip")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .text, .image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let url = urls.first {
                    onFileSelected(url)
                }
            case .failure:
                break
            }
        }
    }
}

// MARK: - Camera Button

#if os(iOS)
struct CameraButton: View {
    let onImageCaptured: (UIImage) -> Void
    @State private var showingImagePicker = false

    var body: some View {
        Button(action: { showingImagePicker = true }) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                Image(systemName: "camera.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(onImageSelected: onImageCaptured)
        }
    }
}
#else
struct CameraButton: View {
    let onImageCaptured: (Any) -> Void

    var body: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                Image(systemName: "camera.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .disabled(true)
    }
}
#endif

// MARK: - Send Button

struct SendButton: View {
    let isEnabled: Bool
    let isGenerating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isEnabled ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                if isGenerating {
                    SwiftUI.ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .disabled(!isEnabled || isGenerating)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Image Picker

#if os(iOS)
struct ImagePickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
#endif
