import SwiftUI
import AppCore
import Foundation

// MARK: - Agent Chat Interface

/// Smart agent chat interface that provides intelligent workflow guidance
public struct AgentChatInterface: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentMessage: String = ""
    @State private var messages: [AgentChatMessage] = []
    @State private var isGeneratingResponse: Bool = false
    @State private var currentWorkflowStep: AgentWorkflowStep = .initial
    @FocusState private var isTextFieldFocused: Bool

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with workflow progress
                agentHeaderView

                // Chat messages
                chatMessagesView

                // Input area
                agentInputView
            }
            .background(Color.black)
            .navigationTitle("AIKO Agent")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                #endif
            }
            .onAppear {
                initializeAgentChat()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Agent Header View

    private var agentHeaderView: some View {
        VStack(spacing: 12) {
            // AIKO Agent Identity
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)

                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.white)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AIKO Intelligence Agent")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Government Contracting Specialist")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Workflow Progress Indicator
                WorkflowProgressView(currentStep: currentWorkflowStep)
            }
            .padding(.horizontal)

            // Current Focus Area
            if currentWorkflowStep != .initial {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Text("Focus: \(currentWorkflowStep.description)")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color.black.opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .bottom
        )
    }

    // MARK: - Chat Messages View

    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        AgentChatBubble(message: message, onActionTapped: handleMessageAction)
                            .id(message.id)
                    }

                    if isGeneratingResponse {
                        AgentTypingIndicator()
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Agent Input View

    private var agentInputView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))

            // Quick Action Buttons (contextual based on workflow step)
            if !currentWorkflowStep.quickActions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(currentWorkflowStep.quickActions, id: \.title) { action in
                            QuickActionButton(action: action) {
                                handleQuickAction(action)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }

            // Text Input
            HStack(spacing: 12) {
                TextField("Ask me about your acquisition needs...", text: $currentMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(currentMessage.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .frame(width: 36, height: 36)

                        if isGeneratingResponse {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                }
                .disabled(currentMessage.isEmpty || isGeneratingResponse)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.black.opacity(0.95))
    }

    // MARK: - Actions

    private func initializeAgentChat() {
        let welcomeMessage = AgentChatMessage(
            content: "Hello! I'm your AIKO intelligence agent, specialized in government contracting and acquisition planning. I can see you're working on document generation.\n\nI'm here to help you:",
            isUser: false,
            messageType: .guidance,
            suggestedActions: [
                AgentAction(title: "Refine Requirements", systemImage: "doc.text.magnifyinglassplus", actionType: .refineRequirements),
                AgentAction(title: "Analyze Budget", systemImage: "dollarsign.circle", actionType: .analyzeBudget),
                AgentAction(title: "Research Vendors", systemImage: "building.2", actionType: .researchVendors),
                AgentAction(title: "Check Compliance", systemImage: "checkmark.shield", actionType: .checkCompliance)
            ]
        )

        messages.append(welcomeMessage)
        determineWorkflowStep()
    }

    private func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = AgentChatMessage(
            content: currentMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            isUser: true
        )

        messages.append(userMessage)
        let messageContent = currentMessage
        currentMessage = ""
        isTextFieldFocused = false

        Task {
            await generateAgentResponse(for: messageContent)
        }
    }

    private func generateAgentResponse(for userMessage: String) async {
        isGeneratingResponse = true
        defer { isGeneratingResponse = false }

        // Simulate intelligent analysis
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let response = await analyzeUserNeedsAndRespond(userMessage)

        await MainActor.run {
            messages.append(response)
            updateWorkflowStep(based: response)
        }
    }

    private func analyzeUserNeedsAndRespond(_ userMessage: String) async -> AgentChatMessage {
        let lowerMessage = userMessage.lowercased()

        // Intelligent analysis based on current context
        if lowerMessage.contains("budget") || lowerMessage.contains("cost") {
            return createBudgetGuidanceMessage()
        } else if lowerMessage.contains("requirement") {
            return createRequirementGuidanceMessage()
        } else if lowerMessage.contains("vendor") || lowerMessage.contains("contractor") {
            return createVendorGuidanceMessage()
        } else if lowerMessage.contains("compliance") || lowerMessage.contains("regulation") {
            return createComplianceGuidanceMessage()
        } else if lowerMessage.contains("timeline") || lowerMessage.contains("schedule") {
            return createTimelineGuidanceMessage()
        } else {
            return createContextualGuidanceMessage(userMessage)
        }
    }

    private func createBudgetGuidanceMessage() -> AgentChatMessage {
        return AgentChatMessage(
            content: "I can help you establish a comprehensive budget framework. Based on government contracting best practices, here's what we should consider:\n\n• **Estimated Contract Value**: Determines procurement thresholds\n• **Competition Requirements**: Affects timeline and documentation\n• **Contract Type**: Influences risk and payment structure\n\nWhat's your preliminary cost estimate?",
            isUser: false,
            messageType: .guidance,
            suggestedActions: [
                AgentAction(title: "Under $10K (Micro-purchase)", systemImage: "1.circle", actionType: .setBudgetRange),
                AgentAction(title: "$10K - $250K (Simplified)", systemImage: "2.circle", actionType: .setBudgetRange),
                AgentAction(title: "Over $250K (Full Competition)", systemImage: "3.circle", actionType: .setBudgetRange)
            ]
        )
    }

    private func createRequirementGuidanceMessage() -> AgentChatMessage {
        return AgentChatMessage(
            content: "Excellent! Clear requirements are the foundation of successful acquisitions. I'll help you develop comprehensive performance-based requirements.\n\n**Current Analysis**: Based on your document selections, I see potential gaps in:\n• Performance metrics definition\n• Acceptance criteria\n• Quality assurance standards\n\nShould we start with defining your core performance objectives?",
            isUser: false,
            messageType: .analysis,
            suggestedActions: [
                AgentAction(title: "Define Performance Objectives", systemImage: "target", actionType: .defineObjectives),
                AgentAction(title: "Set Quality Standards", systemImage: "checkmark.diamond", actionType: .setStandards),
                AgentAction(title: "Specify Deliverables", systemImage: "doc.badge.plus", actionType: .specifyDeliverables)
            ]
        )
    }

    private func createVendorGuidanceMessage() -> AgentChatMessage {
        return AgentChatMessage(
            content: "I can help you develop a robust vendor research and evaluation strategy. This includes:\n\n• **Market Research**: Identifying capable contractors\n• **Competitive Analysis**: Understanding pricing trends\n• **Past Performance**: Evaluating contractor history\n• **Capability Assessment**: Matching skills to requirements\n\nWould you like me to start with SAM.gov research or do you have specific vendors in mind?",
            isUser: false,
            messageType: .guidance,
            suggestedActions: [
                AgentAction(title: "Search SAM.gov", systemImage: "magnifyingglass", actionType: .searchSAM),
                AgentAction(title: "Evaluate Known Vendors", systemImage: "person.3", actionType: .evaluateVendors),
                AgentAction(title: "Market Analysis", systemImage: "chart.line.uptrend.xyaxis", actionType: .marketAnalysis)
            ]
        )
    }

    private func createComplianceGuidanceMessage() -> AgentChatMessage {
        return AgentChatMessage(
            content: "Compliance is critical for government contracting success. I'll help ensure your acquisition meets all requirements:\n\n• **FAR/DFARS Compliance**: Core regulations\n• **Agency-specific requirements**: Your organization's policies\n• **Security requirements**: CMMC, FedRAMP, etc.\n• **Socioeconomic programs**: Small business, veteran-owned, etc.\n\nWhat type of acquisition are you planning?",
            isUser: false,
            messageType: .compliance,
            suggestedActions: [
                AgentAction(title: "IT/Cybersecurity", systemImage: "shield.checkerboard", actionType: .checkCompliance),
                AgentAction(title: "Professional Services", systemImage: "person.badge.key", actionType: .checkCompliance),
                AgentAction(title: "Construction", systemImage: "hammer", actionType: .checkCompliance),
                AgentAction(title: "Supplies/Equipment", systemImage: "box", actionType: .checkCompliance)
            ]
        )
    }

    private func createTimelineGuidanceMessage() -> AgentChatMessage {
        return AgentChatMessage(
            content: "Timeline planning is crucial for acquisition success. I'll help you develop a realistic schedule considering:\n\n• **Acquisition planning**: 30-60 days\n• **Market research**: 15-30 days\n• **Solicitation development**: 45-90 days\n• **Procurement process**: 60-120 days\n• **Contract award**: 30-60 days\n\nWhat's your target award date?",
            isUser: false,
            messageType: .planning,
            suggestedActions: [
                AgentAction(title: "Urgent (< 6 months)", systemImage: "clock.badge.exclamationmark", actionType: .setTimeline),
                AgentAction(title: "Standard (6-12 months)", systemImage: "clock", actionType: .setTimeline),
                AgentAction(title: "Strategic (> 12 months)", systemImage: "calendar", actionType: .setTimeline)
            ]
        )
    }

    private func createContextualGuidanceMessage(_ userMessage: String) -> AgentChatMessage {
        return AgentChatMessage(
            content: "I understand you're looking for guidance on '\(userMessage)'. Let me provide some targeted assistance based on your current acquisition planning needs.\n\nI can help you navigate the complexities of government contracting while ensuring compliance and efficiency. What specific aspect would you like to explore first?",
            isUser: false,
            messageType: .guidance,
            suggestedActions: [
                AgentAction(title: "Requirements Analysis", systemImage: "doc.text.magnifyinglassplus", actionType: .refineRequirements),
                AgentAction(title: "Document Strategy", systemImage: "folder.badge.gearshape", actionType: .planDocuments),
                AgentAction(title: "Process Guidance", systemImage: "arrow.triangle.branch", actionType: .processGuidance)
            ]
        )
    }

    private func handleQuickAction(_ action: AgentAction) {
        currentMessage = "I'd like help with: \(action.title)"
        sendMessage()
    }

    private func handleMessageAction(_ action: AgentAction) {
        switch action.actionType {
        case .refineRequirements:
            // Transition to requirements refinement mode
            currentWorkflowStep = .requirementsGathering
            viewModel.showingAcquisitionChat = false
        // Could open requirements refinement dialog here

        case .searchSAM:
            viewModel.showSAMGovLookup(true)

        case .setBudgetRange, .setTimeline:
            // Handle specific parameter setting
            currentMessage = "Set \(action.title.lowercased())"
            sendMessage()

        default:
            currentMessage = "Help me with: \(action.title)"
            sendMessage()
        }
    }

    private func determineWorkflowStep() {
        // Analyze current state to determine workflow step
        if viewModel.hasSelectedDocuments && !viewModel.hasAcquisition {
            currentWorkflowStep = .requirementsGathering
        } else if viewModel.hasAcquisition && viewModel.selectedTypes.isEmpty {
            currentWorkflowStep = .documentSelection
        } else {
            currentWorkflowStep = .initial
        }
    }

    private func updateWorkflowStep(based message: AgentChatMessage) {
        // Update workflow step based on conversation context
        switch message.messageType {
        case .guidance:
            if message.content.contains("budget") { currentWorkflowStep = .budgetPlanning } else if message.content.contains("requirement") { currentWorkflowStep = .requirementsGathering } else if message.content.contains("vendor") { currentWorkflowStep = .vendorResearch }
        case .analysis:
            currentWorkflowStep = .requirementsAnalysis
        case .compliance:
            currentWorkflowStep = .complianceReview
        case .planning:
            currentWorkflowStep = .timelinePlanning
        default:
            break
        }
    }
}

// MARK: - Supporting Views

struct WorkflowProgressView: View {
    let currentStep: AgentWorkflowStep

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                ForEach(AgentWorkflowStep.allSteps.prefix(5), id: \.self) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            Text("Step \(currentStep.rawValue + 1) of \(AgentWorkflowStep.allSteps.count)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

struct AgentChatBubble: View {
    let message: AgentChatMessage
    let onActionTapped: (AgentAction) -> Void

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userMessageView
            } else {
                agentMessageView
                Spacer()
            }
        }
    }

    private var userMessageView: some View {
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
    }

    private var agentMessageView: some View {
        HStack(alignment: .top, spacing: 12) {
            // Agent Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)

                Image(systemName: "brain.head.profile")
                    .foregroundColor(.white)
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Message content
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(18)

                // Suggested actions
                if !message.suggestedActions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(message.suggestedActions, id: \.title) { action in
                            Button(action: { onActionTapped(action) }) {
                                HStack {
                                    Image(systemName: action.systemImage)
                                        .foregroundColor(.blue)
                                        .frame(width: 16)

                                    Text(action.title)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.blue.opacity(0.6))
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                }

                HStack {
                    Text("AIKO")
                        .font(.caption2)
                        .foregroundColor(.blue)

                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Spacer()
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AgentTypingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)

                Image(systemName: "brain.head.profile")
                    .foregroundColor(.white)
                    .font(.caption)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1.0 : 0.6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(18)
            .onAppear {
                startTypingAnimation()
            }

            Spacer()
        }
    }

    private func startTypingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let action: AgentAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: action.systemImage)
                    .foregroundColor(.blue)
                    .font(.caption)

                Text(action.title)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Supporting Types

public struct AgentChatMessage: Identifiable, Sendable {
    public let id = UUID()
    public let content: String
    public let isUser: Bool
    public let timestamp: Date
    public let messageType: MessageType
    public let suggestedActions: [AgentAction]

    public enum MessageType: Sendable {
        case user, guidance, analysis, compliance, planning, warning, success
    }

    public init(
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        messageType: MessageType = .user,
        suggestedActions: [AgentAction] = []
    ) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.messageType = messageType
        self.suggestedActions = suggestedActions
    }
}

public struct AgentAction: Sendable {
    public let title: String
    public let systemImage: String
    public let actionType: ActionType

    public enum ActionType: Sendable {
        case refineRequirements, analyzeBudget, researchVendors, checkCompliance
        case searchSAM, evaluateVendors, marketAnalysis
        case setBudgetRange, setTimeline, defineObjectives, setStandards, specifyDeliverables
        case planDocuments, processGuidance
    }

    public init(title: String, systemImage: String, actionType: ActionType) {
        self.title = title
        self.systemImage = systemImage
        self.actionType = actionType
    }
}

public enum AgentWorkflowStep: Int, CaseIterable, Sendable {
    case initial = 0
    case requirementsGathering = 1
    case requirementsAnalysis = 2
    case budgetPlanning = 3
    case vendorResearch = 4
    case documentSelection = 5
    case complianceReview = 6
    case timelinePlanning = 7
    case finalReview = 8

    public var description: String {
        switch self {
        case .initial: return "Getting Started"
        case .requirementsGathering: return "Requirements Gathering"
        case .requirementsAnalysis: return "Requirements Analysis"
        case .budgetPlanning: return "Budget Planning"
        case .vendorResearch: return "Vendor Research"
        case .documentSelection: return "Document Selection"
        case .complianceReview: return "Compliance Review"
        case .timelinePlanning: return "Timeline Planning"
        case .finalReview: return "Final Review"
        }
    }

    public var quickActions: [AgentAction] {
        switch self {
        case .initial:
            return [
                AgentAction(title: "Start Requirements", systemImage: "doc.text.magnifyinglassplus", actionType: .refineRequirements),
                AgentAction(title: "Set Budget", systemImage: "dollarsign.circle", actionType: .analyzeBudget),
                AgentAction(title: "Research Market", systemImage: "magnifyingglass", actionType: .researchVendors)
            ]
        case .requirementsGathering:
            return [
                AgentAction(title: "Define Objectives", systemImage: "target", actionType: .defineObjectives),
                AgentAction(title: "Set Standards", systemImage: "checkmark.diamond", actionType: .setStandards)
            ]
        case .budgetPlanning:
            return [
                AgentAction(title: "Micro-purchase", systemImage: "1.circle", actionType: .setBudgetRange),
                AgentAction(title: "Simplified", systemImage: "2.circle", actionType: .setBudgetRange),
                AgentAction(title: "Full Competition", systemImage: "3.circle", actionType: .setBudgetRange)
            ]
        case .vendorResearch:
            return [
                AgentAction(title: "Search SAM.gov", systemImage: "magnifyingglass", actionType: .searchSAM),
                AgentAction(title: "Market Analysis", systemImage: "chart.line.uptrend.xyaxis", actionType: .marketAnalysis)
            ]
        default:
            return []
        }
    }

    public static let allSteps: [AgentWorkflowStep] = AgentWorkflowStep.allCases
}
