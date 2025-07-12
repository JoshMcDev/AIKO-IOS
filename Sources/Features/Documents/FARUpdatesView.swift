import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct FARUpdatesView: View {
    @StateObject private var updateService = FARUpdateService()
    @State private var isChecking = false
    @State private var showingShareSheet = false
    @State private var summaryText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status Card
                statusCard
                    .padding()
                
                // Update Summary
                ScrollView {
                    if updateService.updateStatus.completedUpdates.isEmpty {
                        emptyStateView
                    } else {
                        summaryView
                    }
                }
            }
            .navigationTitle("FAR Updates")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: shareReport) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.aikoPrimary)
                    }
                    .disabled(updateService.updateStatus.completedUpdates.isEmpty)
                }
            }
        }
        .task {
            await checkForUpdates()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [summaryText])
        }
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Status indicator
                HStack(spacing: 8) {
                    Image(systemName: updateService.updateStatus.status.statusIcon)
                        .foregroundColor(updateService.updateStatus.status.statusLight)
                        .font(.title2)
                    
                    Text(statusText)
                        .font(.headline)
                }
                
                Spacer()
                
                // Check button
                Button(action: {
                    Task {
                        await checkForUpdates()
                    }
                }) {
                    HStack(spacing: 4) {
                        if isChecking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.aikoPrimary.opacity(0.1))
                    .foregroundColor(Theme.Colors.aikoPrimary)
                    .cornerRadius(8)
                }
                .disabled(isChecking)
            }
            
            // Last update info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Last Checked:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(updateService.updateStatus.lastUpdateCheck.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if let lastCompleted = updateService.updateStatus.lastUpdateCompleted {
                    HStack {
                        Text("Last Update:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lastCompleted.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                if !updateService.updateStatus.completedUpdates.isEmpty {
                    HStack {
                        Text("Recent Changes:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(updateService.updateStatus.completedUpdates.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.aikoPrimary)
                    }
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.systemBackground))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var statusText: String {
        switch updateService.updateStatus.status {
        case .upToDate:
            return "Regulations Up to Date"
        case .updating:
            return "Checking for Updates..."
        case .updateAvailable:
            return "Updates Available"
        case .error:
            return "Update Check Failed"
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.8))
            
            Text("All Regulations Current")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No recent updates to FAR/DFAR regulations.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("The system automatically monitors acquisition.gov for changes and will notify you when updates are available.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.vertical, 60)
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Generate and display the summary
            let summary = updateService.generateUpdateSummary()
            
            ScrollView {
                Text(summary)
                    .font(.body)
                    .padding()
                    .onAppear {
                        summaryText = summary
                    }
            }
        }
    }
    
    private func checkForUpdates() async {
        isChecking = true
        await updateService.checkForUpdates()
        isChecking = false
        
        // Update summary text if there are updates
        if !updateService.updateStatus.completedUpdates.isEmpty {
            summaryText = updateService.generateUpdateSummary()
        }
    }
    
    private func shareReport() {
        if summaryText.isEmpty {
            summaryText = updateService.generateUpdateSummary()
        }
        showingShareSheet = true
    }
}

// Using existing ShareSheet from ShareFeature

struct FARUpdatesView_Previews: PreviewProvider {
    static var previews: some View {
        FARUpdatesView()
    }
}