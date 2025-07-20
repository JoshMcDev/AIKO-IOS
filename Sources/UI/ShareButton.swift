import AppCore
import ComposableArchitecture
import SwiftUI

// Reusable share button component for all reports and documents
struct ShareButton: View {
    let content: String
    let fileName: String
    var fileExtension: String = "txt"
    var buttonStyle: ShareButtonStyle = .icon

    @State private var showShareSheet = false
    @Dependency(\.shareService) var shareService

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
        .task(id: showShareSheet) {
            if showShareSheet {
                await shareContent()
                showShareSheet = false
            }
        }
    }

    private func shareContent() async {
        let fullFileName = "\(fileName).\(fileExtension)"
        await shareService.shareContent(content, fullFileName)
    }
}

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
