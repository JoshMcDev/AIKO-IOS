import SwiftUI
import ComposableArchitecture

// Test app with mocked dependencies
@main
struct TestSAMGovApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @State private var showingSAMGov = false
    @State private var showingSAMReport = false
    
    var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 40) {
                Text("SAM.gov Test Harness")
                    .font(.largeTitle)
                    .bold()
                
                // Test SAM.gov Search
                Button(action: {
                    showingSAMGov = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Test SAM.gov Search")
                    }
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Test SAM Report View
                Button(action: {
                    showingSAMReport = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Test SAM Report View")
                    }
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Instructions
                VStack(alignment: .leading, spacing: 15) {
                    Text("Test Instructions:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Card 1: Enter CAGE '1F353' (Lockheed Martin)", systemImage: "1.circle")
                        Label("Card 2: Enter 'BOOZ ALLEN' for company name", systemImage: "2.circle")
                        Label("Card 3: Optional - Enter UEI or delete", systemImage: "3.circle")
                        Label("Click 'Search All' or individual Search buttons", systemImage: "magnifyingglass.circle")
                        Label("Verify green magnifying glass when text entered", systemImage: "checkmark.circle")
                        Label("Check results display company details", systemImage: "doc.text.magnifyingglass")
                    }
                    .font(.callout)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSAMGov) {
                SAMGovLookupView()
                    .withDependencies {
                        // Override with mock service
                        $0.samGovService = .mockValue
                        $0.settingsManager = .mockValue
                    }
            }
            .sheet(isPresented: $showingSAMReport) {
                SwiftUI.NavigationView {
                    SAMReportPreview()
                }
            }
        }
    }
}

// Required imports and extensions
extension View {
    func withDependencies(_ updateDependencies: (inout DependencyValues) -> Void) -> some View {
        WithPerceptionTracking {
            self
        }
    }
}