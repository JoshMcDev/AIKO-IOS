import AppCore
import SwiftUI

#if os(iOS)
import AIKOiOS
#elseif os(macOS)
import AIKOmacOS
#endif

public struct CustomTemplateDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.templateStorageService) var storageService

    let template: CustomTemplate
    @State private var isEditing = false
    @State private var editedContent: String
    @State private var showingSaveConfirmation = false

    public init(template: CustomTemplate) {
        self.template = template
        _editedContent = State(initialValue: template.content)
    }

    public var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                // Template Info Header
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title)
                            .foregroundColor(.purple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(template.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        // Template status
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("Custom Template", systemImage: "person.circle.fill")
                                .font(.caption)
                                .foregroundColor(.purple)

                            Text(template.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("Created: \(template.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Action buttons
                    HStack(spacing: Theme.Spacing.medium) {
                        // Share button
                        if !isEditing {
                            ShareButton(
                                content: generateTemplateShareContent(),
                                fileName: DocumentShareHelper.generateFileName(for: .template),
                                buttonStyle: .icon
                            )
                            .padding(.horizontal, Theme.Spacing.small)
                        }

                        Spacer()

                        Button(action: {
                            if isEditing {
                                saveChanges()
                            } else {
                                startEditing()
                            }
                        }) {
                            Label(isEditing ? "Save Changes" : "Edit Template",
                                  systemImage: isEditing ? "checkmark.circle" : "pencil.circle")
                                .font(.subheadline)
                                .foregroundColor(isEditing ? .green : .purple)
                                .padding(.horizontal, Theme.Spacing.medium)
                                .padding(.vertical, Theme.Spacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                        .fill(isEditing ? Color.green.opacity(0.2) : Theme.Colors.aikoSecondary)
                                )
                        }

                        if isEditing {
                            Button(action: cancelEditing) {
                                Label("Cancel", systemImage: "xmark.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, Theme.Spacing.medium)
                                    .padding(.vertical, Theme.Spacing.small)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                            .fill(Color.red.opacity(0.2))
                                    )
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.large)
                .background(Color.black)

                Divider()

                // Template Content
                ScrollView {
                    if isEditing {
                        TextEditor(text: $editedContent)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(Theme.Spacing.large)
                            .background(Theme.Colors.aikoSecondary)
                            .cornerRadius(Theme.CornerRadius.md)
                            .padding(Theme.Spacing.large)
                    } else {
                        Text(template.content)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(Theme.Spacing.large)
                            .background(Theme.Colors.aikoSecondary)
                            .cornerRadius(Theme.CornerRadius.md)
                            .padding(Theme.Spacing.large)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .background(Theme.Colors.aikoBackground)
            }
            .navigationTitle("Custom Template")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .overlay(
            // Save confirmation overlay
            showingSaveConfirmation ?
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Template saved successfully")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                            .background(
                                Capsule()
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 50)
                }
                .animation(.easeInOut, value: showingSaveConfirmation)
                : nil
        )
    }

    private func startEditing() {
        editedContent = template.content
        isEditing = true
    }

    private func saveChanges() {
        Task {
            do {
                let updatedTemplate = CustomTemplate(
                    id: template.id,
                    name: template.name,
                    category: template.category,
                    description: template.description,
                    content: editedContent,
                    createdAt: template.createdAt,
                    updatedAt: Date()
                )
                try await storageService.saveTemplate(updatedTemplate)
                await MainActor.run {
                    isEditing = false
                    showingSaveConfirmation = true

                    // Hide confirmation after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingSaveConfirmation = false
                    }
                }
            } catch {
                // Handle error - could show alert
                print("Failed to save changes: \(error)")
            }
        }
    }

    private func cancelEditing() {
        editedContent = template.content
        isEditing = false
    }

    private func generateTemplateShareContent() -> String {
        """
        Custom Template: \(template.name)
        Category: \(template.category)
        Generated: \(Date().formatted())

        DESCRIPTION:
        \(template.description)

        CONTENT:
        \(template.content)
        """
    }
}

// MARK: - Preview

#if DEBUG
struct CustomTemplateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTemplateDetailView(
            template: CustomTemplate(
                name: "Sample Template",
                category: "Requirements",
                description: "A sample custom template for testing",
                content: "This is sample template content..."
            )
        )
        .preferredColorScheme(.dark)
    }
}
#endif
