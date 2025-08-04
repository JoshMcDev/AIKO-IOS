import SwiftUI

/// Modern SwiftUI implementation of LLMProviderSettingsView
/// Replaces TCA patterns with protocol-based @ObservedObject ViewModel
/// Following DocumentScannerView architectural success pattern
@MainActor
public struct LLMProviderSettingsView<ViewModel: LLMProviderSettingsViewModelProtocol>: View {
    @ObservedObject private var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            List {
                activeProviderSection
                availableProvidersSection
                providerPrioritySection
                securitySection
            }
            .navigationTitle("LLM Providers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadConfigurations()
            }
            .sheet(isPresented: $viewModel.isProviderConfigSheetPresented) {
                if let provider = viewModel.selectedProvider {
                    ProviderConfigurationSheet(
                        viewModel: viewModel,
                        provider: provider
                    )
                }
            }
            .alert(
                viewModel.alert?.title ?? "",
                isPresented: .constant(viewModel.alert != nil),
                presenting: viewModel.alert
            ) { alert in
                alertActions(for: alert)
            } message: { alert in
                Text(alert.message)
            }
        }
    }

    // MARK: - View Sections

    private var activeProviderSection: some View {
        Section("Active Provider") {
            if let activeProvider = viewModel.activeProvider {
                HStack {
                    Image(systemName: activeProvider.provider.iconName)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)

                    VStack(alignment: .leading) {
                        Text(activeProvider.provider.name)
                            .font(.headline)
                        Text(activeProvider.model.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else {
                Text("No active provider configured")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var availableProvidersSection: some View {
        Section(
            header: Text("Available Providers"),
            footer: Text("Tap a provider to configure or manage its API key")
        ) {
            ForEach(LLMProvider.allCases) { provider in
                ProviderRow(
                    provider: provider,
                    isConfigured: viewModel.configuredProviders.contains(provider),
                    isActive: viewModel.activeProvider?.provider == provider
                ) {
                    viewModel.selectProvider(provider)
                }
            }
        }
    }

    private var providerPrioritySection: some View {
        Section("Provider Settings") {
            NavigationLink(destination: ProviderPrioritySheet(viewModel: viewModel)) {
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Fallback Priority")
                    Spacer()
                    Text(viewModel.providerPriority.fallbackBehavior.displayName)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var securitySection: some View {
        Section(
            header: Text("Security"),
            footer: Text("This will remove all stored API keys and require reconfiguration")
        ) {
            Button(action: {
                viewModel.showClearConfirmation()
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Clear All API Keys")
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Alert Actions

    @ViewBuilder
    private func alertActions(for alert: ViewModel.AlertType) -> some View {
        // Implementation will be completed in GREEN phase
        // Based on the alert type, provide appropriate actions
        Button("OK") {
            viewModel.dismissAlert()
        }
    }
}

// MARK: - Provider Row Component

struct ProviderRow: View {
    let provider: LLMProvider
    let isConfigured: Bool
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: provider.iconName)
                    .foregroundColor(isConfigured ? .accentColor : .secondary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.name)
                        .foregroundColor(.primary)

                    if isConfigured {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.caption2)
                            Text("API Key Configured")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Provider Configuration Sheet

struct ProviderConfigurationSheet<ViewModel: LLMProviderSettingsViewModelProtocol>: View {
    @ObservedObject private var viewModel: ViewModel
    let provider: LLMProvider
    @Environment(\.dismiss) private var dismiss

    @State private var showAPIKey: Bool = false

    init(viewModel: ViewModel, provider: LLMProvider) {
        self.viewModel = viewModel
        self.provider = provider
    }

    var body: some View {
        NavigationStack {
            Form {
                providerInfoSection
                apiKeySection
                modelSelectionSection
                advancedSettingsSection
                actionsSection
            }
            .navigationTitle("\(provider.name) Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var providerInfoSection: some View {
        Section {
            HStack {
                Image(systemName: provider.iconName)
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading) {
                    Text(provider.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Configure API access")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var apiKeySection: some View {
        Section(
            header: Text("API Key"),
            footer: Text(getAPIKeyHelperText())
        ) {
            HStack {
                if showAPIKey {
                    TextField("API Key", text: $viewModel.providerConfigState?.apiKey ?? .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("API Key", text: $viewModel.providerConfigState?.apiKey ?? .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Button(action: {
                    showAPIKey.toggle()
                }) {
                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.providerConfigState?.hasExistingKey == true {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("API key already configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var modelSelectionSection: some View {
        Section("Model Selection") {
            if let configState = viewModel.providerConfigState {
                Picker("Model", selection: .constant(configState.selectedModel)) {
                    ForEach(provider.availableModels) { model in
                        VStack(alignment: .leading) {
                            Text(model.name)
                            Text("\(model.contextWindow / 1000)K context")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }

    private var advancedSettingsSection: some View {
        Section("Advanced Settings") {
            if let configState = viewModel.providerConfigState {
                HStack {
                    Text("Temperature")
                    Slider(
                        value: .constant(configState.temperature),
                        in: 0 ... 1,
                        step: 0.1
                    )
                    Text("\(configState.temperature, specifier: "%.1f")")
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }

                if provider == .custom {
                    TextField(
                        "Custom Endpoint URL",
                        text: .constant(configState.customEndpoint)
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button(action: {
                Task {
                    await viewModel.authenticateAndSave()
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(viewModel.providerConfigState?.hasExistingKey == true ?
                                "Update Configuration" : "Save Configuration")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.providerConfigState?.apiKey.isEmpty == true || viewModel.isAuthenticating)

            if viewModel.providerConfigState?.hasExistingKey == true {
                Button(action: {
                    Task {
                        await viewModel.removeProviderConfiguration()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Remove Configuration")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
    }

    private func getAPIKeyHelperText() -> String {
        switch provider {
        case .claude:
            "Get your API key from console.anthropic.com"
        case .openAI, .chatGPT:
            "Get your API key from platform.openai.com"
        case .gemini:
            "Get your API key from makersuite.google.com"
        case .custom:
            "Enter your custom provider's API key"
        }
    }
}

// MARK: - Provider Priority Sheet

struct ProviderPrioritySheet<ViewModel: LLMProviderSettingsViewModelProtocol>: View {
    @ObservedObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Section(
                header: Text("Fallback Strategy"),
                footer: Text(viewModel.providerPriority.fallbackBehavior.description)
            ) {
                // Picker implementation will be completed in GREEN phase
                Text("Fallback behavior picker placeholder")
            }

            Section(
                header: Text("Priority Order"),
                footer: Text("Drag to reorder provider priority")
            ) {
                ForEach(viewModel.providerPriority.providers) { provider in
                    HStack {
                        Image(systemName: provider.iconName)
                        Text(provider.name)
                        Spacer()
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.secondary)
                    }
                }
                .onMove { source, destination in
                    Task {
                        await viewModel.moveProvider(from: source, to: destination)
                    }
                }
            }
        }
        .navigationTitle("Provider Priority")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
    }
}

// MARK: - Extensions for Protocol Requirements

extension LLMProviderSettingsViewModel.AlertType {
    var title: String {
        switch self {
        case .clearConfirmation:
            return "Clear All API Keys?"
        case .error:
            return "Error"
        case .success:
            return "Success"
        }
    }

    var message: String {
        switch self {
        case .clearConfirmation:
            return "This action cannot be undone. All provider configurations will be removed."
        case .error(let message):
            return message
        case .success(let message):
            return message
        }
    }
}

extension LLMProviderSettingsViewModel.ProviderPriority.FallbackBehavior {
    var displayName: String {
        switch self {
        case .sequential:
            "Sequential"
        case .loadBalanced:
            "Load Balanced"
        case .costOptimized:
            "Cost Optimized"
        case .performanceOptimized:
            "Performance"
        }
    }

    var description: String {
        switch self {
        case .sequential:
            "Try providers in order until one succeeds"
        case .loadBalanced:
            "Distribute requests across available providers"
        case .costOptimized:
            "Choose the most cost-effective provider"
        case .performanceOptimized:
            "Choose the fastest responding provider"
        }
    }
}
