import SwiftUI

// MARK: - Settings Section Enum for macOS Navigation

#if os(macOS)
enum SettingsSection: String, CaseIterable {
    case app = "App"
    case api = "API"
    case documents = "Documents"
    case notifications = "Notifications"
    case privacy = "Privacy"
    case advanced = "Advanced"

    var title: String {
        return rawValue
    }

    var icon: String {
        switch self {
        case .app: return "gearshape"
        case .api: return "key"
        case .documents: return "doc.text"
        case .notifications: return "bell"
        case .privacy: return "lock.shield"
        case .advanced: return "wrench.and.screwdriver"
        }
    }

    var iconColor: Color {
        switch self {
        case .app: return .blue
        case .api: return .orange
        case .documents: return .green
        case .notifications: return .purple
        case .privacy: return .red
        case .advanced: return .gray
        }
    }
}
#endif

public struct SettingsView: View {
    @Bindable public var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var showingValidationError = false
    @State private var exportURL: URL?

    // MARK: - macOS Navigation State
    #if os(macOS)
    @State private var selectedSection: SettingsSection = .app
    #endif

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        #if os(macOS)
        macOSSettingsView
        #else
        iOSSettingsView
        #endif
    }

    // MARK: - Platform-Specific Views

    #if os(macOS)
    @ViewBuilder
    private var macOSSettingsView: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsSection.allCases, id: \.self, selection: $selectedSection) { section in
                Label {
                    Text(section.title)
                } icon: {
                    Image(systemName: section.icon)
                        .foregroundStyle(section.iconColor)
                }
                .tag(section)
            }
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // Detail View
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    selectedSectionView
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(selectedSection.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 8) {
                        Button("Reset") {
                            showingResetAlert = true
                        }
                        .keyboardShortcut("r", modifiers: .command)

                        Button("Save") {
                            Task {
                                await viewModel.saveSettings()
                            }
                        }
                        .keyboardShortcut("s", modifiers: .command)

                        saveStatusView
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .disabled(viewModel.isLoading)
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    await viewModel.resetToDefaults()
                }
            }
        } message: {
            Text("Are you sure you want to reset all settings to their default values? This action cannot be undone.")
        }
        .sheet(isPresented: $showingExportSheet) {
            exportSheet
        }
    }

    @ViewBuilder
    private var selectedSectionView: some View {
        switch selectedSection {
        case .app:
            appSettingsSection
        case .api:
            apiSettingsSection
        case .documents:
            documentSettingsSection
        case .notifications:
            notificationSettingsSection
        case .privacy:
            privacySettingsSection
        case .advanced:
            advancedSettingsSection
        }
    }
    #endif

    @ViewBuilder
    private var iOSSettingsView: some View {
        NavigationStack {
            Form {
                // App Settings Section
                appSettingsSection

                // API Settings Section
                apiSettingsSection

                // Document Settings Section
                documentSettingsSection

                // Notification Settings Section
                notificationSettingsSection

                // Privacy Settings Section
                privacySettingsSection

                // Advanced Settings Section
                advancedSettingsSection
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    saveStatusView
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    saveStatusView
                }
                #endif
            }
            .disabled(viewModel.isLoading)
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task {
                        await viewModel.resetToDefaults()
                    }
                }
            } message: {
                Text("Are you sure you want to reset all settings to their default values? This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSheet
            }
        }
    }

    // MARK: - App Settings Section

    @ViewBuilder
    private var appSettingsSection: some View {
        Section("App Settings") {
            Picker("Theme", selection: Binding(
                get: { viewModel.settingsData.appSettings.theme },
                set: { newValue in
                    Task {
                        await viewModel.updateAppSetting(\.theme, value: newValue)
                    }
                }
            )) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }

            Picker("Accent Color", selection: Binding(
                get: { viewModel.settingsData.appSettings.accentColor },
                set: { newValue in
                    Task {
                        await viewModel.updateAppSetting(\.accentColor, value: newValue)
                    }
                }
            )) {
                Text("Blue").tag("blue")
                Text("Red").tag("red")
                Text("Green").tag("green")
                Text("Orange").tag("orange")
                Text("Purple").tag("purple")
            }

            Picker("Font Size", selection: Binding(
                get: { viewModel.settingsData.appSettings.fontSize },
                set: { newValue in
                    Task {
                        await viewModel.updateAppSetting(\.fontSize, value: newValue)
                    }
                }
            )) {
                Text("Small").tag("small")
                Text("Medium").tag("medium")
                Text("Large").tag("large")
            }

            Toggle("Auto Save", isOn: Binding(
                get: { viewModel.settingsData.appSettings.autoSaveEnabled },
                set: { newValue in
                    Task {
                        await viewModel.updateAppSetting(\.autoSaveEnabled, value: newValue)
                    }
                }
            ))

            if viewModel.settingsData.appSettings.autoSaveEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Auto Save Interval")
                        Spacer()
                        Text("\(viewModel.settingsData.appSettings.autoSaveInterval)s")
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(viewModel.settingsData.appSettings.autoSaveInterval) },
                            set: { newValue in
                                Task {
                                    await viewModel.updateAppSetting(\.autoSaveInterval, value: Int(newValue))
                                }
                            }
                        ),
                        in: 10...300,
                        step: 10
                    )

                    HStack {
                        Text("10s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("300s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - API Settings Section

    @ViewBuilder
    private var apiSettingsSection: some View {
        Section("API Settings") {
            Picker("Model", selection: Binding(
                get: { viewModel.settingsData.apiSettings.selectedModel },
                set: { newValue in
                    Task {
                        await viewModel.updateAPISetting(\.selectedModel, value: newValue)
                    }
                }
            )) {
                Text("Claude 3 Opus").tag("Claude 3 Opus")
                Text("Claude 3 Sonnet").tag("Claude 3 Sonnet")
                Text("Claude 3 Haiku").tag("Claude 3 Haiku")
                Text("GPT-4").tag("GPT-4")
                Text("GPT-3.5").tag("GPT-3.5")
            }

            NavigationLink("Manage API Keys (\(viewModel.settingsData.apiSettings.apiKeys.count))") {
                apiKeyManagementView
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Max Retries")
                    Spacer()
                    Text("\(viewModel.settingsData.apiSettings.maxRetries)")
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.settingsData.apiSettings.maxRetries) },
                        set: { newValue in
                            Task {
                                await viewModel.updateAPISetting(\.maxRetries, value: Int(newValue))
                            }
                        }
                    ),
                    in: 1...10,
                    step: 1
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Timeout")
                    Spacer()
                    Text("\(Int(viewModel.settingsData.apiSettings.timeoutInterval))s")
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { viewModel.settingsData.apiSettings.timeoutInterval },
                        set: { newValue in
                            Task {
                                await viewModel.updateAPISetting(\.timeoutInterval, value: newValue)
                            }
                        }
                    ),
                    in: 5...120,
                    step: 5
                )
            }
        }
    }

    // MARK: - Document Settings Section

    @ViewBuilder
    private var documentSettingsSection: some View {
        Section("Document Settings") {
            Toggle("Include Metadata", isOn: Binding(
                get: { viewModel.settingsData.documentSettings.includeMetadata },
                set: { newValue in
                    Task {
                        await viewModel.updateDocumentSetting(\.includeMetadata, value: newValue)
                    }
                }
            ))

            Toggle("Include Version History", isOn: Binding(
                get: { viewModel.settingsData.documentSettings.includeVersionHistory },
                set: { newValue in
                    Task {
                        await viewModel.updateDocumentSetting(\.includeVersionHistory, value: newValue)
                    }
                }
            ))

            Toggle("Auto Generate Table of Contents", isOn: Binding(
                get: { viewModel.settingsData.documentSettings.autoGenerateTableOfContents },
                set: { newValue in
                    Task {
                        await viewModel.updateDocumentSetting(\.autoGenerateTableOfContents, value: newValue)
                    }
                }
            ))

            Toggle("Page Numbering", isOn: Binding(
                get: { viewModel.settingsData.documentSettings.pageNumbering },
                set: { newValue in
                    Task {
                        await viewModel.updateDocumentSetting(\.pageNumbering, value: newValue)
                    }
                }
            ))
        }
    }

    // MARK: - Notification Settings Section

    @ViewBuilder
    private var notificationSettingsSection: some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: Binding(
                get: { viewModel.settingsData.notificationSettings.enableNotifications },
                set: { newValue in
                    Task {
                        await viewModel.updateNotificationSetting(\.enableNotifications, value: newValue)
                    }
                }
            ))

            if viewModel.settingsData.notificationSettings.enableNotifications {
                Toggle("Document Generation Complete", isOn: Binding(
                    get: { viewModel.settingsData.notificationSettings.documentGenerationComplete },
                    set: { newValue in
                        Task {
                            await viewModel.updateNotificationSetting(\.documentGenerationComplete, value: newValue)
                        }
                    }
                ))

                Toggle("Acquisition Reminders", isOn: Binding(
                    get: { viewModel.settingsData.notificationSettings.acquisitionReminders },
                    set: { newValue in
                        Task {
                            await viewModel.updateNotificationSetting(\.acquisitionReminders, value: newValue)
                        }
                    }
                ))

                Toggle("Update Available", isOn: Binding(
                    get: { viewModel.settingsData.notificationSettings.updateAvailable },
                    set: { newValue in
                        Task {
                            await viewModel.updateNotificationSetting(\.updateAvailable, value: newValue)
                        }
                    }
                ))

                Toggle("Sound Enabled", isOn: Binding(
                    get: { viewModel.settingsData.notificationSettings.soundEnabled },
                    set: { newValue in
                        Task {
                            await viewModel.updateNotificationSetting(\.soundEnabled, value: newValue)
                        }
                    }
                ))
            }
        }
    }

    // MARK: - Privacy Settings Section

    @ViewBuilder
    private var privacySettingsSection: some View {
        Section("Privacy & Data") {
            Toggle("Analytics", isOn: Binding(
                get: { viewModel.settingsData.dataPrivacySettings.analyticsEnabled },
                set: { newValue in
                    Task {
                        await viewModel.updatePrivacySetting(\.analyticsEnabled, value: newValue)
                    }
                }
            ))

            Toggle("Crash Reporting", isOn: Binding(
                get: { viewModel.settingsData.dataPrivacySettings.crashReportingEnabled },
                set: { newValue in
                    Task {
                        await viewModel.updatePrivacySetting(\.crashReportingEnabled, value: newValue)
                    }
                }
            ))

            Toggle("Encrypt Local Data", isOn: Binding(
                get: { viewModel.settingsData.dataPrivacySettings.encryptLocalData },
                set: { newValue in
                    Task {
                        await viewModel.updatePrivacySetting(\.encryptLocalData, value: newValue)
                    }
                }
            ))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Data Retention")
                    Spacer()
                    Text("\(viewModel.settingsData.dataPrivacySettings.dataRetentionDays) days")
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.settingsData.dataPrivacySettings.dataRetentionDays) },
                        set: { newValue in
                            Task {
                                await viewModel.updatePrivacySetting(\.dataRetentionDays, value: Int(newValue))
                            }
                        }
                    ),
                    in: 1...365,
                    step: 1
                )

                HStack {
                    Text("1 day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("365 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Advanced Settings Section

    @ViewBuilder
    private var advancedSettingsSection: some View {
        Section("Advanced") {
            Toggle("Debug Mode", isOn: Binding(
                get: { viewModel.settingsData.advancedSettings.debugModeEnabled },
                set: { newValue in
                    Task {
                        await viewModel.updateAdvancedSetting(\.debugModeEnabled, value: newValue)
                    }
                }
            ))

            Toggle("Show Detailed Errors", isOn: Binding(
                get: { viewModel.settingsData.advancedSettings.showDetailedErrors },
                set: { newValue in
                    Task {
                        await viewModel.updateAdvancedSetting(\.showDetailedErrors, value: newValue)
                    }
                }
            ))

            Toggle("Enable Beta Features", isOn: Binding(
                get: { viewModel.settingsData.advancedSettings.enableBetaFeatures },
                set: { newValue in
                    Task {
                        await viewModel.updateAdvancedSetting(\.enableBetaFeatures, value: newValue)
                    }
                }
            ))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Cache Size")
                    Spacer()
                    Text("\(viewModel.settingsData.advancedSettings.cacheSizeMB) MB")
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.settingsData.advancedSettings.cacheSizeMB) },
                        set: { newValue in
                            Task {
                                await viewModel.updateAdvancedSetting(\.cacheSizeMB, value: Int(newValue))
                            }
                        }
                    ),
                    in: 50...2000,
                    step: 50
                )

                HStack {
                    Text("50 MB")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("2 GB")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Max Concurrent Generations")
                    Spacer()
                    Text("\(viewModel.settingsData.advancedSettings.maxConcurrentGenerations)")
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.settingsData.advancedSettings.maxConcurrentGenerations) },
                        set: { newValue in
                            Task {
                                await viewModel.updateAdvancedSetting(\.maxConcurrentGenerations, value: Int(newValue))
                            }
                        }
                    ),
                    in: 1...10,
                    step: 1
                )
            }

            Button("Export Settings") {
                Task {
                    let exportData = await viewModel.exportSettings()
                    exportURL = saveExportData(exportData)
                    showingExportSheet = true
                }
            }

            Button("Reset to Defaults") {
                showingResetAlert = true
            }
            .foregroundStyle(.red)
        }
    }

    // MARK: - Save Status View

    @ViewBuilder
    private var saveStatusView: some View {
        switch viewModel.saveStatus {
        case .none:
            EmptyView()
        case .saving:
            ProgressView()
                .scaleEffect(0.8)
        case .saved:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    // MARK: - API Key Management View

    @ViewBuilder
    private var apiKeyManagementView: some View {
        NavigationStack {
            List {
                ForEach(viewModel.settingsData.apiSettings.apiKeys, id: \.id) { apiKey in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(apiKey.name)
                                .font(.headline)
                            Spacer()
                            if apiKey.isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }

                        Text("\(apiKey.key.prefix(10))...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        Task {
                            await viewModel.selectAPIKey(apiKey.id)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let apiKey = viewModel.settingsData.apiSettings.apiKeys[index]
                        Task {
                            await viewModel.removeAPIKey(apiKey.id)
                        }
                    }
                }
            }
            .navigationTitle("API Keys")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Export Sheet

    @ViewBuilder
    private var exportSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Settings Exported")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Your settings have been exported successfully. You can share this file or import it on another device.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("Share Settings File", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Export Complete")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func saveExportData(_ data: Data) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let exportURL = documentsPath?.appendingPathComponent("AIKO_Settings_\(Date().timeIntervalSince1970).json")

        guard let url = exportURL else { return nil }

        do {
            try data.write(to: url)
            return url
        } catch {
            print("Failed to save export data: \(error)")
            return nil
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
