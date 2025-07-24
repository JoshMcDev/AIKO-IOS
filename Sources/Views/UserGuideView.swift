import SwiftUI
import AppCore

public struct UserGuideView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSection: GuideSection = .gettingStarted
    @State private var searchText = ""

    enum GuideSection: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case creatingDocuments = "Creating Documents"
        case understandingDocuments = "Understanding Documents"
        case usingAI = "Using AI Features"
        case managingProfile = "Managing Your Profile"
        case tips = "Tips & Tricks"
        case faq = "Frequently Asked Questions"

        var icon: String {
            switch self {
            case .gettingStarted: "play.circle.fill"
            case .creatingDocuments: "doc.badge.plus"
            case .understandingDocuments: "doc.text.magnifyingglass"
            case .usingAI: "brain"
            case .managingProfile: "person.crop.circle"
            case .tips: "lightbulb.fill"
            case .faq: "questionmark.circle.fill"
            }
        }
    }

    public var body: some View {
        #if os(iOS)
            SwiftUI.NavigationView {
                contentView
                    .navigationTitle("User Guide")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
            }
        #else
            contentView
                .frame(minWidth: 800, minHeight: 600)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        #endif
    }

    private var contentView: some View {
        #if os(iOS)
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // iPad layout with sidebar
                    HStack(spacing: 0) {
                        // Sidebar
                        sidebarView
                            .frame(width: 280)

                        // Content
                        ScrollView {
                            contentForSection(selectedSection)
                                .padding(Theme.Spacing.extraLarge)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.aikoBackground)
                    }
                } else {
                    // iPhone layout with tab view
                    VStack(spacing: 0) {
                        // Section selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.small) {
                                ForEach(GuideSection.allCases, id: \.self) { section in
                                    Button(action: { selectedSection = section }) {
                                        Text(section.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(selectedSection == section ? .semibold : .regular)
                                            .foregroundColor(selectedSection == section ? .white : .secondary)
                                            .padding(.horizontal, Theme.Spacing.medium)
                                            .padding(.vertical, Theme.Spacing.small)
                                            .background(
                                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                                    .fill(selectedSection == section ? Theme.Colors.aikoAccent : Theme.Colors.aikoSecondary)
                                            )
                                    }
                                }
                            }
                            .padding(Theme.Spacing.medium)
                        }
                        .background(Color.black)

                        // Content
                        ScrollView {
                            contentForSection(selectedSection)
                                .padding(Theme.Spacing.extraLarge)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.Colors.aikoBackground)
                    }
                }
            }
        #else
            HSplitView {
                // Sidebar
                sidebarView
                    .frame(minWidth: 250, idealWidth: 280)

                // Content
                ScrollView {
                    contentForSection(selectedSection)
                        .padding(Theme.Spacing.extraLarge)
                }
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.aikoBackground)
            }
        #endif
    }

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search guide...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(Theme.Spacing.medium)
            .background(Theme.Colors.aikoSecondary.opacity(0.5))
            .cornerRadius(Theme.CornerRadius.small)
            .padding(Theme.Spacing.medium)

            // Section list
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    ForEach(GuideSection.allCases, id: \.self) { section in
                        sectionButton(section)
                    }
                }
                .padding(.horizontal, Theme.Spacing.medium)
            }
        }
        .background(Theme.Colors.aikoSecondary)
    }

    private func sectionButton(_ section: GuideSection) -> some View {
        Button(action: { selectedSection = section }) {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: section.icon)
                    .font(.title3)
                    .frame(width: 24)
                    .foregroundColor(selectedSection == section ? .white : .secondary)

                Text(section.rawValue)
                    .font(.subheadline)
                    .fontWeight(selectedSection == section ? .semibold : .regular)
                    .foregroundColor(selectedSection == section ? .white : .primary)

                Spacer()
            }
            .padding(.vertical, Theme.Spacing.small)
            .padding(.horizontal, Theme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(selectedSection == section ? Theme.Colors.aikoAccent : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func contentForSection(_ section: GuideSection) -> some View {
        switch section {
        case .gettingStarted:
            GettingStartedContent()
        case .creatingDocuments:
            CreatingDocumentsContent()
        case .understandingDocuments:
            UnderstandingDocumentsContent()
        case .usingAI:
            UsingAIContent()
        case .managingProfile:
            ManagingProfileContent()
        case .tips:
            TipsAndTricksContent()
        case .faq:
            FAQContent()
        }
    }
}

// MARK: - Getting Started Content

struct GettingStartedContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            Text("Welcome to AIKO")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your AI Contract Intelligence Officer")
                .font(.title2)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                GuideSection(
                    title: "What is AIKO?",
                    content: """
                    AIKO (AI Contract Intelligence Officer) is your intelligent assistant for creating federal acquisition documents. It uses advanced AI to help you generate compliant contracting documents in seconds, saving you hours of work.
                    """
                )

                GuideSection(
                    title: "First Steps",
                    content: """
                    1. **Set up your profile**: Click on "My Profile" in the menu to add your information. This data will automatically populate in all your documents.

                    2. **Describe your requirements**: In the main screen, type or speak your procurement needs in plain language.

                    3. **Select documents**: Choose which documents you need, or let AIKO recommend them based on your requirements.

                    4. **Generate and download**: Click the generate button and download your completed documents.
                    """
                )

                GuideSection(
                    title: "Key Features",
                    bullets: [
                        "AI-powered document generation",
                        "FAR compliance built-in",
                        "Voice input support",
                        "Document upload for analysis",
                        "Smart recommendations",
                        "Automatic data population from your profile",
                    ]
                )
            }
        }
    }
}

// MARK: - Creating Documents Content

struct CreatingDocumentsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            Text("Creating Documents")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                GuideSection(
                    title: "Step 1: Describe Your Requirements",
                    content: """
                    Start by describing what you need to procure. You can:
                    - Type your requirements in plain language
                    - Upload existing requirement documents
                    - Use voice input (tap the microphone icon)

                    Example: "I need to procure cloud computing services for data analytics, estimated value $500,000, performance period 2 years"
                    """
                )

                GuideSection(
                    title: "Step 2: Review AI Analysis",
                    content: """
                    AIKO will analyze your requirements and:
                    - Identify the type of procurement
                    - Determine applicable regulations
                    - Recommend appropriate documents
                    - Check for compliance requirements

                    You can refine your requirements if needed or proceed with the recommendations.
                    """
                )

                GuideSection(
                    title: "Step 3: Select Documents",
                    content: """
                    Documents are organized by category:
                    - **Requirements Studio**: Define your needs (SOW, PWS, etc.)
                    - **Market Intelligence**: Research and analysis
                    - **Acquisition Planning**: Strategic planning documents
                    - **Solicitation**: RFQs and RFPs
                    - **Award**: Contract documents

                    Select individual documents or use AIKO's recommendations.
                    """
                )

                GuideSection(
                    title: "Step 4: Generate and Download",
                    content: """
                    Once you've selected documents:
                    1. Click the generate button
                    2. AIKO will create all documents with your data
                    3. Choose delivery method (download, email, or view)
                    4. All documents are FAR-compliant and ready to use
                    """
                )
            }
        }
    }
}

// MARK: - Understanding Documents Content

struct UnderstandingDocumentsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            Text("Understanding Documents")
                .font(.largeTitle)
                .fontWeight(.bold)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                GuideSection(
                    title: "Document Types",
                    content: """
                    AIKO can generate over 20 different document types, each serving a specific purpose in the acquisition process:
                    """
                )

                DocumentTypeGuide(
                    category: "Requirements Documents",
                    documents: [
                        ("SOW", "Statement of Work - Defines specific tasks and deliverables"),
                        ("PWS", "Performance Work Statement - Defines outcomes and standards"),
                        ("SOO", "Statement of Objectives - High-level objectives for contractor to propose solutions"),
                        ("RRD", "Requirements Review Document - Comprehensive requirements analysis"),
                        ("QASP", "Quality Assurance Surveillance Plan - How to monitor contractor performance"),
                    ]
                )

                DocumentTypeGuide(
                    category: "Market Research",
                    documents: [
                        ("Market Research Report", "Analysis of available solutions and vendors"),
                        ("Sources Sought", "Notice to find potential vendors"),
                        ("RFI", "Request for Information from industry"),
                        ("Cost Estimate", "Independent government cost estimate"),
                    ]
                )

                DocumentTypeGuide(
                    category: "Solicitation Documents",
                    documents: [
                        ("RFQ", "Request for Quote - For simple purchases"),
                        ("RFP", "Request for Proposal - For complex requirements"),
                        ("Evaluation Plan", "How proposals will be evaluated"),
                    ]
                )
            }
        }
    }
}

// MARK: - Using AI Features Content

struct UsingAIContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            Text("Using AI Features")
                .font(.largeTitle)
                .fontWeight(.bold)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                GuideSection(
                    title: "Natural Language Processing",
                    content: """
                    AIKO understands plain English. Just describe your needs naturally:
                    - "I need office supplies for the next fiscal year"
                    - "We're looking for a contractor to develop a mobile app"
                    - "Cloud hosting services with 99.9% uptime requirement"

                    AIKO will extract key information and suggest appropriate documents.
                    """
                )

                GuideSection(
                    title: "Smart Recommendations",
                    content: """
                    Based on your requirements, AIKO recommends:
                    - Which documents you need
                    - Compliance requirements (CMMC, Section 508, etc.)
                    - Appropriate contract types
                    - Evaluation criteria

                    These recommendations follow FAR guidelines and best practices.
                    """
                )

                GuideSection(
                    title: "Document Analysis",
                    content: """
                    Upload existing documents and AIKO will:
                    - Extract requirements
                    - Identify missing information
                    - Suggest improvements
                    - Check for compliance issues

                    Supported formats: PDF, Word, Excel, and images
                    """
                )

                GuideSection(
                    title: "Adaptive Learning",
                    content: """
                    AIKO learns from your usage patterns:
                    - Remembers your preferences
                    - Adapts to your agency's needs
                    - Improves recommendations over time
                    - All learning happens on your device for privacy
                    """
                )
            }
        }
    }
}

// MARK: - Managing Profile Content

struct ManagingProfileContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            Text("Managing Your Profile")
                .font(.largeTitle)
                .fontWeight(.bold)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                GuideSection(
                    title: "Why Complete Your Profile?",
                    content: """
                    Your profile information automatically populates in all generated documents:
                    - Contracting officer information
                    - Organization details
                    - Default addresses
                    - Contact information

                    A complete profile saves time and ensures consistency.
                    """
                )

                GuideSection(
                    title: "Profile Sections",
                    bullets: [
                        "**Personal Information**: Name, title, and position",
                        "**Contact Details**: Email and phone numbers",
                        "**Organization**: Agency name and DODAAC",
                        "**Addresses**: Default administered by, payment, and delivery addresses",
                        "**Images**: Profile photo and organization logo (optional)",
                    ]
                )

                GuideSection(
                    title: "Updating Your Profile",
                    content: """
                    1. Click "My Profile" in the menu
                    2. Tap "Edit" to modify information
                    3. Update any fields as needed
                    4. Changes save automatically

                    Your profile data never leaves your device unless you explicitly share documents.
                    """
                )
            }
        }
    }
}

// MARK: - Tips and Tricks Content

struct TipsAndTricksContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            Text("Tips & Tricks")
                .font(.largeTitle)
                .fontWeight(.bold)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                GuideSection(
                    title: "Power User Tips",
                    bullets: [
                        "**Use voice input** for faster requirement entry",
                        "**Upload multiple documents** at once for comprehensive analysis",
                        "**Save frequently used requirements** in My Acquisitions",
                        "**Use keyboard shortcuts** (Cmd+N for new, Cmd+G to generate)",
                        "**Batch generate** multiple document types at once",
                    ]
                )

                GuideSection(
                    title: "Best Practices",
                    bullets: [
                        "Be specific with dollar amounts and timelines",
                        "Include performance metrics in your requirements",
                        "Review AI recommendations before generating",
                        "Use the appropriate document type for your procurement",
                        "Keep your profile information up to date",
                    ]
                )

                GuideSection(
                    title: "Common Shortcuts",
                    content: """
                    **Quick Actions:**
                    - Press Enter to analyze requirements
                    - Drag and drop files to upload
                    - Double-click documents to preview
                    - Swipe left on uploaded documents to remove

                    **Document Selection:**
                    - Click category headers to expand/collapse
                    - Use "Select All Recommended" for quick setup
                    - Hold Shift to select multiple documents
                    """
                )
            }
        }
    }
}

// MARK: - FAQ Content

struct FAQContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            Text("Frequently Asked Questions")
                .font(.largeTitle)
                .fontWeight(.bold)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                FAQItem(
                    question: "Is AIKO FAR-compliant?",
                    answer: "Yes, all documents generated by AIKO follow Federal Acquisition Regulation (FAR) guidelines and include required clauses and provisions."
                )

                FAQItem(
                    question: "Where is my data stored?",
                    answer: "All your data is stored locally on your device. Nothing is sent to external servers unless you explicitly choose to email documents."
                )

                FAQItem(
                    question: "Can I edit generated documents?",
                    answer: "Yes, all documents are provided in editable formats (Word/PDF). You can modify them as needed after generation."
                )

                FAQItem(
                    question: "What file types can I upload?",
                    answer: "AIKO accepts PDF, Word (.doc, .docx), Excel (.xls, .xlsx), text files, and images (for OCR scanning)."
                )

                FAQItem(
                    question: "How does AIKO determine which documents I need?",
                    answer: "AIKO analyzes your requirements against FAR thresholds, procurement type, and complexity to recommend appropriate documents."
                )

                FAQItem(
                    question: "Can I use AIKO offline?",
                    answer: "Basic features work offline, but AI analysis and document generation require an internet connection."
                )

                FAQItem(
                    question: "Is there a limit to how many documents I can generate?",
                    answer: "No, there are no limits on document generation. Create as many as you need."
                )

                FAQItem(
                    question: "How often is AIKO updated?",
                    answer: "AIKO is regularly updated with the latest FAR changes and improvements. Updates install automatically."
                )
            }
        }
    }
}

// MARK: - Helper Views

struct GuideSection: View {
    let title: String
    var content: String = ""
    var bullets: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            if !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
            }

            if !bullets.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: Theme.Spacing.small) {
                            Text("•")
                                .font(.body)
                            Text(bullet)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }
        }
    }
}

struct DocumentTypeGuide: View {
    let category: String
    let documents: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(category)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                ForEach(documents, id: \.0) { doc in
                    HStack(alignment: .top, spacing: Theme.Spacing.medium) {
                        Text(doc.0)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)

                        Text("-")
                            .foregroundColor(.secondary)

                        Text(doc.1)
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.9))
                    }
                }
            }
            .padding(.leading, Theme.Spacing.medium)
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(question)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.primary.opacity(0.9))
                    .padding(.leading, Theme.Spacing.medium)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.aikoSecondary.opacity(0.5))
        .cornerRadius(Theme.CornerRadius.small)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Platform Specific

#if os(macOS)
    struct HSplitView<Content: View>: View {
        let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        var body: some View {
            HStack(spacing: 0) {
                content
            }
        }
    }
#else
    struct HSplitView<Content: View>: View {
        let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        var body: some View {
            if UIDevice.current.userInterfaceIdiom == .pad {
                HStack(spacing: 0) {
                    content
                }
            } else {
                // On iPhone, show as navigation
                content
            }
        }
    }
#endif
