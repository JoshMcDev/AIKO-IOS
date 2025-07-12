import ComposableArchitecture
import SwiftUI

// Standalone test view for SAM.gov functionality
struct TestSAMGovView: View {
    @State private var showingSAMGov = false
    @State private var showingSAMReport = false

    var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 40) {
                // Test SAM.gov Search
                Button("Test SAM.gov Search") {
                    showingSAMGov = true
                }
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                // Test SAM Report View
                Button("Test SAM Report View") {
                    showingSAMReport = true
                }
                .font(.title2)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Text("Test Instructions:")
                    .font(.headline)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Card 1 (CAGE): Enter '1F353' (Lockheed Martin)")
                    Text("2. Card 2 (Name): Enter 'BOOZ ALLEN' (Booz Allen Hamilton)")
                    Text("3. Click 'Search All' or individual Search buttons")
                    Text("4. Verify results show company details")
                    Text("5. Check SAM Report formatting")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .navigationTitle("SAM.gov Test")
            .sheet(isPresented: $showingSAMGov) {
                SAMGovLookupView()
            }
            .sheet(isPresented: $showingSAMReport) {
                SAMReportPreview()
            }
        }
    }
}

@main
struct TestSAMGovApp: App {
    var body: some Scene {
        WindowGroup {
            TestSAMGovView()
        }
    }
}
