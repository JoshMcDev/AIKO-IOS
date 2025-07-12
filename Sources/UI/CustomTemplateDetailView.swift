import SwiftUI
import ComposableArchitecture

public struct CustomTemplateDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Dependency(\.templateStorageService) var storageService
    
    let template: CustomTemplate
    @State private var isEditing = false
    @State private var editedContent: String = ""
    @State private var editedName: String = ""
    @State private var editedDescription: String = ""
    @State private var showingSaveConfirmation = false
    @State private var showingDeleteConfirmation = false
    
    public init(template: CustomTemplate) {
        self.template = template
    }
    
    public var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                // Template Info Header
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title)
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if isEditing {
                                TextField("Template Name", text: $editedName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .textFieldStyle(.plain)
                            } else {
                                Text(template.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            if isEditing {
                                TextField("Template Description", text: $editedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .textFieldStyle(.plain)
                            } else {
                                Text(template.description)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Template status
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("Custom Template", systemImage: "person.circle")
                                .font(.caption)
                                .foregroundColor(.purple)
                            
                            Text(template.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: Theme.Spacing.md) {
                        Button(action: { 
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete Template", systemImage: "trash")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(Color.red.opacity(0.2))
                                )
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
                                .foregroundColor(isEditing ? .green : .blue)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(isEditing ? Color.green.opacity(0.2) : Theme.Colors.aikoSecondary)
                                )
                        }
                        
                        if isEditing {
                            Button(action: cancelEditing) {
                                Label("Cancel", systemImage: "xmark.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .padding(.vertical, Theme.Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                            .fill(Color.red.opacity(0.2))
                                    )
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(Color.black)
                
                Divider()
                
                // Template Content
                ScrollView {
                    if isEditing {
                        TextEditor(text: $editedContent)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(Theme.Spacing.lg)
                            .background(Theme.Colors.aikoSecondary)
                            .cornerRadius(Theme.CornerRadius.md)
                            .padding(Theme.Spacing.lg)
                    } else {
                        Text(template.content)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(Theme.Spacing.lg)
                            .background(Theme.Colors.aikoSecondary)
                            .cornerRadius(Theme.CornerRadius.md)
                            .padding(Theme.Spacing.lg)
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
            .onAppear {
                editedContent = template.content
                editedName = template.name
                editedDescription = template.description
            }
            .confirmationDialog(
                "Delete Template",
                isPresented: $showingDeleteConfirmation
            ) {
                Button("Delete", role: .destructive) {
                    deleteTemplate()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this template? This action cannot be undone.")
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
        editedName = template.name
        editedDescription = template.description
        isEditing = true
    }
    
    private func saveChanges() {
        Task {
            do {
                // Delete old template
                try await storageService.deleteTemplate(template.id)
                
                // Save new template with updated content
                let updatedTemplate = CustomTemplate(
                    id: template.id,
                    name: editedName,
                    category: template.category,
                    description: editedDescription,
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
                // Handle error
                print("Failed to save changes: \(error)")
            }
        }
    }
    
    private func cancelEditing() {
        editedContent = template.content
        editedName = template.name
        editedDescription = template.description
        isEditing = false
    }
    
    private func deleteTemplate() {
        Task {
            do {
                try await storageService.deleteTemplate(template.id)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to delete template: \(error)")
            }
        }
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
                description: "A sample custom template",
                content: "Template content goes here..."
            )
        )
        .preferredColorScheme(.dark)
    }
}
#endif