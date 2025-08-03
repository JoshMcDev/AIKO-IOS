import SwiftUI

public struct OnboardingView: View {
    @Bindable public var viewModel: OnboardingViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Keyboard Navigation State
    #if os(macOS)
    @FocusState private var focusedField: OnboardingFocusField?
    #endif

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            GeometryReader { geometry in
                VStack(spacing: platformSpacing) {
                    // Progress Bar
                    OnboardingProgressBar(
                        currentStep: viewModel.currentStep,
                        progress: viewModel.currentStep.progress
                    )

                    // Step Content
                    stepContentView
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                    Spacer()

                    // Navigation Buttons
                    navigationButtonsView
                }
                .padding(.horizontal, horizontalPadding(for: geometry.size))
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: maxContentWidth)
                .frame(width: geometry.size.width)
                .disabled(viewModel.isLoading)
            }
        }
        #if os(macOS)
        .frame(minWidth: 600, idealWidth: 800, maxWidth: 1000, minHeight: 500, idealHeight: 600, maxHeight: 800)
        .onExitCommand {
            // Handle Escape key - go back if possible
            if viewModel.currentStep != .welcome {
                viewModel.previousStep()
            }
        }
        .onKeyPress(keys: [.upArrow]) { _ in
            // Focus previous element
            focusPreviousField()
            return .handled
        }
        .onKeyPress(keys: [.downArrow]) { _ in
            // Focus next element
            focusNextField()
            return .handled
        }
        #endif
    }

    // MARK: - Platform-Specific Layout Properties

    private var platformSpacing: CGFloat {
        #if os(macOS)
        return 32 // More generous spacing for larger screens
        #else
        return 24 // Compact spacing for mobile
        #endif
    }

    private func horizontalPadding(for size: CGSize) -> CGFloat {
        #if os(macOS)
        return max(40, size.width * 0.1) // Responsive padding, minimum 40pt
        #else
        return 24 // Standard mobile padding
        #endif
    }

    private var verticalPadding: CGFloat {
        #if os(macOS)
        return 48 // More generous top/bottom padding
        #else
        return 32 // Standard mobile padding
        #endif
    }

    private var maxContentWidth: CGFloat {
        #if os(macOS)
        return 600 // Constrain content width on large screens
        #else
        return .infinity // Use full width on mobile
        #endif
    }

    // MARK: - Keyboard Navigation Methods
    #if os(macOS)
    private func focusPreviousField() {
        switch focusedField {
        case .apiKey:
            focusedField = nil
        case .biometricToggle:
            if viewModel.currentStep == .permissions {
                focusedField = nil
            }
        case .nextButton:
            if viewModel.currentStep == .apiSetup {
                focusedField = .apiKey
            } else if viewModel.currentStep == .permissions {
                focusedField = .biometricToggle
            }
        case .backButton:
            focusedField = .nextButton
        case .skipButton:
            focusedField = .apiKey
        case .none:
            break
        }
    }

    private func focusNextField() {
        switch focusedField {
        case .apiKey:
            if viewModel.currentStep == .apiSetup {
                focusedField = .skipButton
            }
        case .biometricToggle:
            focusedField = .nextButton
        case .nextButton:
            if viewModel.currentStep != .welcome {
                focusedField = .backButton
            }
        case .backButton, .skipButton:
            focusedField = .nextButton
        case .none:
            if viewModel.currentStep == .apiSetup {
                focusedField = .apiKey
            } else if viewModel.currentStep == .permissions {
                focusedField = .biometricToggle
            } else {
                focusedField = .nextButton
            }
        }
    }
    #endif

    @ViewBuilder
    private var stepContentView: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView()
        case .apiSetup:
            APISetupStepView(viewModel: viewModel)
        case .permissions:
            PermissionsStepView(viewModel: viewModel)
        case .completion:
            CompletionStepView()
        }
    }

    @ViewBuilder
    private var navigationButtonsView: some View {
        HStack(spacing: 16) {
            // Back Button
            if viewModel.currentStep != .welcome {
                Button("Back") {
                    viewModel.previousStep()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
                #if os(macOS)
                .focused($focusedField, equals: .backButton)
                .keyboardShortcut(.leftArrow, modifiers: .command)
                #endif
            }

            Spacer()

            // Skip Button (only for API setup)
            if viewModel.currentStep == .apiSetup {
                Button("Skip") {
                    viewModel.skipStep()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
                #if os(macOS)
                .focused($focusedField, equals: .skipButton)
                .keyboardShortcut("s", modifiers: .command)
                #endif
            }

            // Next/Complete Button
            Button(nextButtonTitle) {
                Task {
                    if viewModel.currentStep == .completion {
                        await viewModel.completeOnboarding()
                    } else {
                        viewModel.nextStep()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canProceed || viewModel.isLoading)
            #if os(macOS)
            .focused($focusedField, equals: .nextButton)
            .keyboardShortcut(.rightArrow, modifiers: .command)
            .keyboardShortcut(.return, modifiers: [])
            #endif
        }
    }

    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .welcome, .apiSetup, .permissions:
            return "Next"
        case .completion:
            return "Complete"
        }
    }
}

// MARK: - Step Views

private struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)

            Text("Welcome to AIKO")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Let's get started with a quick introduction to set up your AI assistant.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}

private struct APISetupStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    #if os(macOS)
    @FocusState private var isAPIKeyFocused: Bool
    #endif

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange.gradient)

            Text("API Configuration")
                .font(.title)
                .fontWeight(.semibold)

            Text("Configure your API keys to connect with AI services for enhanced functionality.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.headline)

                SecureField("Enter your API key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    #if os(macOS)
                    .focused($isAPIKeyFocused)
                    #endif
                    .onSubmit {
                        Task {
                            await viewModel.validateAPIKey()
                        }
                    }

                if let validationError = viewModel.validationError {
                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if viewModel.isAPIKeyValidated {
                    Label("API key validated", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            if viewModel.isLoading {
                ProgressView("Validating...")
                    .font(.caption)
            }
        }
        .onAppear {
            if !viewModel.apiKey.isEmpty {
                Task {
                    await viewModel.validateAPIKey()
                }
            }
        }
    }
}

private struct PermissionsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    #if os(macOS)
    @FocusState private var isToggleFocused: Bool
    #endif

    private var biometricAuthenticationTitle: String {
        #if os(macOS)
        return "Touch ID"
        #else
        return "Face ID / Touch ID"
        #endif
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundStyle(.green.gradient)

            Text("Permissions")
                .font(.title)
                .fontWeight(.semibold)

            Text("Grant necessary permissions for optimal security and user experience.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(biometricAuthenticationTitle)
                            .font(.headline)
                        Text("Secure access to your API keys and sensitive data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.faceIDEnabled)
                        #if os(macOS)
                        .focused($isToggleFocused)
                        .keyboardShortcut(.space, modifiers: [])
                        #endif
                        .onChange(of: viewModel.faceIDEnabled) { _, newValue in
                            Task {
                                await viewModel.toggleFaceID(newValue)
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            if viewModel.isLoading {
                ProgressView("Configuring...")
                    .font(.caption)
            }
        }
    }
}

private struct CompletionStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green.gradient)

            Text("Setup Complete")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your setup is now complete! You're ready to start using AIKO.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Label("API Configuration", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("Permissions Configured", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("Ready to Use", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .font(.subheadline)
        }
    }
}

// MARK: - Progress Bar

private struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Step \(currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.blue)

            Text(currentStep.title)
                .font(.headline)
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}

// MARK: - Keyboard Navigation Support

#if os(macOS)
/// Enum to manage keyboard focus state in OnboardingView for macOS
private enum OnboardingFocusField: Hashable {
    case apiKey
    case biometricToggle
    case nextButton
    case backButton
    case skipButton
}
#endif
