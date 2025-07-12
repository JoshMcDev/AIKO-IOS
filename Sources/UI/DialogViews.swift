import SwiftUI
import ComposableArchitecture

// MARK: - LLM Confirmation Dialog

public struct LLMConfirmationDialog: View {
    let store: StoreOf<DocumentGenerationFeature>
    
    public init(store: StoreOf<DocumentGenerationFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            SwiftUI.NavigationView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("AIKO Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("AI Contract Intelligence Officer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.horizontal, Theme.Spacing.lg)
                    
                    if viewStore.analysis.isAnalyzingRequirements {
                        // Loading state
                        VStack(spacing: Theme.Spacing.lg) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.5)
                            
                            Text("Analyzing your requirements...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Main Content
                        ScrollView {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                                // LLM Response
                                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                    Text("Analysis")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(viewStore.analysis.llmResponse)
                                        .font(.body)
                                        .padding(Theme.Spacing.lg)
                                        .background(Theme.Colors.aikoSecondary)
                                        .cornerRadius(Theme.CornerRadius.md)
                                }
                                
                                // Document Status Summary with grouping
                                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                    Text("Document Status")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    let groupedStatuses = Dictionary(grouping: viewStore.status.documentReadinessStatus.keys) { documentType in
                                        viewStore.status.documentReadinessStatus[documentType] ?? .notReady
                                    }
                                    
                                    // Ready documents
                                    if let readyDocs = groupedStatuses[.ready]?.sorted(by: { $0.rawValue < $1.rawValue }), !readyDocs.isEmpty {
                                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                            Label("Ready to Generate", systemImage: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                            
                                            ForEach(readyDocs, id: \.self) { documentType in
                                                HStack {
                                                    Image(systemName: documentType.icon)
                                                        .foregroundColor(.green)
                                                        .frame(width: 20)
                                                    Text(documentType.shortName)
                                                        .font(.subheadline)
                                                    Spacer()
                                                }
                                            }
                                        }
                                        .padding(.bottom, Theme.Spacing.sm)
                                    }
                                    
                                    // Needs more info documents
                                    if let needsInfoDocs = groupedStatuses[.needsMoreInfo]?.sorted(by: { $0.rawValue < $1.rawValue }), !needsInfoDocs.isEmpty {
                                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                            Label("Needs More Information", systemImage: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                            
                                            ForEach(needsInfoDocs, id: \.self) { documentType in
                                                HStack {
                                                    Image(systemName: documentType.icon)
                                                        .foregroundColor(.yellow)
                                                        .frame(width: 20)
                                                    Text(documentType.shortName)
                                                        .font(.subheadline)
                                                    Spacer()
                                                }
                                            }
                                        }
                                        .padding(.bottom, Theme.Spacing.sm)
                                    }
                                    
                                    // Not ready documents
                                    if let notReadyDocs = groupedStatuses[.notReady]?.sorted(by: { $0.rawValue < $1.rawValue }), !notReadyDocs.isEmpty {
                                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                            Label("Not Ready", systemImage: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                            
                                            ForEach(notReadyDocs, id: \.self) { documentType in
                                                HStack {
                                                    Image(systemName: documentType.icon)
                                                        .foregroundColor(.red.opacity(0.6))
                                                        .frame(width: 20)
                                                    Text(documentType.shortName)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(Theme.Spacing.lg)
                                .background(Theme.Colors.aikoSecondary)
                                .cornerRadius(Theme.CornerRadius.md)
                                
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                        }
                        
                        // Confirm Button
                        if hasReadyDocuments(viewStore.status.documentReadinessStatus) {
                            VStack(spacing: 0) {
                                Divider()
                                
                                Button(action: {
                                    viewStore.send(.analysis(.confirmRequirements(true)))
                                }) {
                                    HStack(spacing: Theme.Spacing.md) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                        
                                        Text("Confirm Requirements")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .foregroundColor(.white)
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(Theme.CornerRadius.lg)
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .padding(.horizontal, Theme.Spacing.lg)
                                .padding(.vertical, Theme.Spacing.lg)
                                .background(Color.black)
                            }
                        }
                    }
                }
                .background(Color.black)
                .modifier(NavigationBarHiddenModifier())
                .preferredColorScheme(.dark)
            }
        }
    }
    
    private func statusColor(for status: DocumentStatusFeature.DocumentStatus) -> Color {
        switch status {
        case .notReady: return .red
        case .needsMoreInfo: return .yellow
        case .ready: return .green
        }
    }
    
    private func statusText(for status: DocumentStatusFeature.DocumentStatus) -> String {
        switch status {
        case .ready: return "Ready"
        case .needsMoreInfo: return "Needs Info"
        case .notReady: return "Not Ready"
        }
    }
    
    private func hasReadyDocuments(_ status: [DocumentType: DocumentStatusFeature.DocumentStatus]) -> Bool {
        status.values.contains { $0 == .ready }
    }
}

// MARK: - Document Recommendation Dialog

public struct DocumentRecommendationDialog: View {
    let store: StoreOf<DocumentGenerationFeature>
    
    public init(store: StoreOf<DocumentGenerationFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            SwiftUI.NavigationView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Document Recommendations")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Based on your requirements, I recommend these documents:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.lg)
                    
                    // Recommended Documents with categories
                    ScrollView {
                        VStack(spacing: Theme.Spacing.md) {
                            let documentsByCategory = Dictionary(grouping: viewStore.analysis.recommendedDocuments) { documentType in
                                if [.sow, .soo, .pws, .qasp, .rrd].contains(documentType) {
                                    return "Requirements & Planning"
                                } else if [.marketResearch, .codes, .competitionAnalysis, .procurementSourcing].contains(documentType) {
                                    return "Procurement & Analysis"
                                } else if [.fiscalLawReview, .opsecReview, .justificationApproval].contains(documentType) {
                                    return "Compliance & Review"
                                } else {
                                    return "Advanced Documents"
                                }
                            }
                            
                            ForEach(documentsByCategory.keys.sorted(), id: \.self) { category in
                                if let documents = documentsByCategory[category] {
                                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                        Text(category)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, Theme.Spacing.sm)
                                        
                                        ForEach(documents.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { documentType in
                                            HStack(spacing: Theme.Spacing.lg) {
                                                Image(systemName: documentType.icon)
                                                    .font(.title2)
                                                    .foregroundColor(.blue)
                                                    .frame(width: 32, height: 32)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text(documentType.rawValue)
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                        
                                                        if documentType.isProFeature {
                                                            Text("PRO")
                                                                .font(.caption2)
                                                                .fontWeight(.bold)
                                                                .foregroundColor(.white)
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(Color.orange)
                                                                .cornerRadius(6)
                                                        }
                                                    }
                                                    
                                                    Text(documentType.description)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(2)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                    .font(.title3)
                                            }
                                            .aikoCard()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: Theme.Spacing.md) {
                        Button(action: {
                            viewStore.send(.generateRecommendedDocuments)
                        }) {
                            Text("Auto-Generate Recommended Documents")
                        }
                        .aikoButton(variant: .primary, size: .large)
                        
                        Button(action: {
                            viewStore.send(.analysis(.showDocumentRecommendation(false)))
                        }) {
                            Text("Let Me Select Manually")
                        }
                        .aikoButton(variant: .secondary, size: .medium)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .background(Theme.Colors.aikoBackground)
                .modifier(NavigationBarHiddenModifier())
            }
        }
    }
}

// MARK: - Delivery Options Dialog

public struct DeliveryOptionsDialog: View {
    let store: StoreOf<DocumentGenerationFeature>
    
    public init(store: StoreOf<DocumentGenerationFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            SwiftUI.NavigationView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Delivery Options")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("How would you like to receive your documents?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.lg)
                    
                    // Generated Documents Summary
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        let documents = viewStore.delivery.generatedDocuments
                        let documentCount = documents.count
                        Text("Generated Documents (\(documentCount))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(documents.prefix(3), id: \.id) { document in
                            HStack {
                                Image(systemName: document.documentCategory.icon)
                                    .foregroundColor(.blue)
                                Text(document.title)
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                        
                        if documents.count > 3 {
                            let moreCount = documents.count - 3
                            Text("+ \(moreCount) more documents")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .aikoCard()
                    
                    Spacer()
                    
                    // Delivery Options
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(DocumentDeliveryFeature.DeliveryOption.allCases, id: \.self) { option in
                            Button(action: {
                                viewStore.send(.delivery(.deliverDocuments(option)))
                            }) {
                                HStack(spacing: Theme.Spacing.lg) {
                                    Image(systemName: option.icon)
                                        .font(.title2)
                                        .frame(width: 32, height: 32)
                                    
                                    Text(option.title)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(Theme.Spacing.lg)
                                .background(Theme.Colors.aikoCard)
                                .cornerRadius(Theme.CornerRadius.lg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .background(Theme.Colors.aikoBackground)
                .modifier(NavigationBarHiddenModifier())
            }
        }
    }
}

// MARK: - Email Confirmation Dialog

public struct EmailConfirmationDialog: View {
    let store: StoreOf<DocumentGenerationFeature>
    
    public init(store: StoreOf<DocumentGenerationFeature>) {
        self.store = store
    }
    
    public var body: some View {
        SwiftUI.NavigationView {
            WithViewStore(store, observe: { $0 }) { viewStore in
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "envelope.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Email Confirmation")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Choose an email address to send your documents")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.lg)
                    
                    // Email Options
                    VStack(spacing: Theme.Spacing.md) {
                        // Profile Email Option (if available)
                        if !viewStore.delivery.userProfileEmail.isEmpty {
                            EmailOptionButton(
                                title: "Use Profile Email",
                                subtitle: viewStore.delivery.userProfileEmail,
                                isSelected: viewStore.delivery.selectedEmailOption == .profile,
                                action: { viewStore.send(.delivery(.updateEmailOption(.profile))) }
                            )
                        }
                        
                        // Different Email Option
                        EmailOptionButton(
                            title: viewStore.delivery.userProfileEmail.isEmpty ? "Enter Email Address" : "Different Email Address",
                            subtitle: "Specify a different email address",
                            isSelected: viewStore.delivery.selectedEmailOption == (viewStore.delivery.userProfileEmail.isEmpty ? .noProfile : .different),
                            action: { 
                                viewStore.send(.delivery(.updateEmailOption(viewStore.delivery.userProfileEmail.isEmpty ? .noProfile : .different)))
                            }
                        )
                        
                        // Custom Email Input
                        if viewStore.delivery.selectedEmailOption == .different || viewStore.delivery.selectedEmailOption == .noProfile {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Email Address")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                TextField("Enter email address", text: .init(
                                    get: { viewStore.delivery.customEmailAddress },
                                    set: { viewStore.send(.delivery(.updateCustomEmail($0))) }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                #endif
                            }
                            .aikoCard()
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: Theme.Spacing.md) {
                        Button(action: {
                            viewStore.send(.delivery(.sendDocumentsViaEmail))
                        }) {
                            Text("Send Documents")
                        }
                        .aikoButton(variant: .primary, size: .large)
                        .disabled(!canSendEmail(viewStore))
                        
                        Button(action: {
                            viewStore.send(.delivery(.showEmailConfirmation(false)))
                        }) {
                            Text("Cancel")
                        }
                        .aikoButton(variant: .ghost, size: .medium)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .background(Theme.Colors.aikoBackground)
                .modifier(NavigationBarHiddenModifier())
            }
        }
    }
    
    private func canSendEmail(_ viewStore: ViewStore<DocumentGenerationFeature.State, DocumentGenerationFeature.Action>) -> Bool {
        switch viewStore.delivery.selectedEmailOption {
        case .profile:
            return !viewStore.delivery.userProfileEmail.isEmpty
        case .different, .noProfile:
            return !viewStore.delivery.customEmailAddress.isEmpty && viewStore.delivery.customEmailAddress.contains("@")
        }
    }
}

struct EmailOptionButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.aikoCard)
            .cornerRadius(Theme.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}