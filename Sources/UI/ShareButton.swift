import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Reusable share button component for all reports and documents
struct ShareButton: View {
    let content: String
    let fileName: String
    var fileExtension: String = "txt"
    var buttonStyle: ShareButtonStyle = .icon
    
    @State private var showShareSheet = false
    
    enum ShareButtonStyle {
        case icon
        case text
        case iconWithText
    }
    
    var body: some View {
        Button(action: { showShareSheet = true }) {
            switch buttonStyle {
            case .icon:
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.aikoPrimary)
            case .text:
                Text("Share")
                    .foregroundColor(Theme.Colors.aikoPrimary)
            case .iconWithText:
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .foregroundColor(Theme.Colors.aikoPrimary)
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: generateShareItems())
        }
        #else
        .sheet(isPresented: $showShareSheet) {
            ShareSheetMacOS(
                content: content,
                fileName: fileName,
                fileExtension: fileExtension,
                isPresented: $showShareSheet
            )
        }
        #endif
    }
    
    private func generateShareItems() -> [Any] {
        // Create a temporary file with the content
        let fullFileName = "\(fileName).\(fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fullFileName)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            // Return both the text and the file URL for maximum compatibility
            return [content, tempURL]
        } catch {
            // If file creation fails, just return the text
            return [content]
        }
    }
}

// Share Sheet for iOS
#if os(iOS)
public struct ShareSheet: UIViewControllerRepresentable {
    public let items: [Any]
    
    public init(items: [Any]) {
        self.items = items
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Force dark mode for consistency
        controller.overrideUserInterfaceStyle = .dark
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        uiViewController.overrideUserInterfaceStyle = .dark
    }
}
#else
// ShareSheet for macOS to match iOS API
public struct ShareSheet: View {
    public let items: [Any]
    
    public init(items: [Any]) {
        self.items = items
    }
    
    public var body: some View {
        // For macOS, we'll just show a placeholder
        Text("Sharing is not implemented for macOS")
            .padding()
    }
}
#endif

// Share Sheet for macOS
#if os(macOS)
struct ShareSheetMacOS: View {
    let content: String
    let fileName: String
    let fileExtension: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share Document")
                .font(.headline)
            
            Text("Choose how to share this document:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                    isPresented = false
                }
                
                Button("Save to File") {
                    saveToFile()
                }
                
                Button("Cancel") {
                    isPresented = false
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 400, height: 150)
    }
    
    private func saveToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(fileName).\(fileExtension)"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                isPresented = false
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
}
#endif

// Preview
struct ShareButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShareButton(
                content: "Sample report content",
                fileName: "Report_\(Date().formatted(.dateTime.year().month().day()))",
                buttonStyle: .icon
            )
            
            ShareButton(
                content: "Sample document content",
                fileName: "Document",
                buttonStyle: .iconWithText
            )
        }
        .padding()
    }
}