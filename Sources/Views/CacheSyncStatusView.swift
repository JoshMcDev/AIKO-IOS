//
//  CacheSyncStatusView.swift
//  AIKO
//
//  Created for cache synchronization UI
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// View displaying cache sync status and controls
struct CacheSyncStatusView: View {
    @StateObject private var viewModel = CacheSyncViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sync status header
            HStack {
                Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.icloud")
                    .foregroundColor(viewModel.isSyncing ? .orange : .blue)
                    .rotationEffect(.degrees(viewModel.isSyncing ? 360 : 0))
                    .animation(viewModel.isSyncing ? Animation.linear(duration: 2).repeatForever(autoreverses: false) : .default, value: viewModel.isSyncing)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.syncStatusMessage)
                        .font(.headline)

                    if viewModel.lastSyncDate != nil {
                        Text("Last sync: \(viewModel.formattedLastSync)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Sync button
                Button(action: viewModel.triggerSync) {
                    HStack(spacing: 6) {
                        if viewModel.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.syncButtonLabel)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.isSyncDisabled ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isSyncDisabled)
            }

            // Network status indicator
            if !viewModel.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.red)
                    Text("No network connection")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
            }

            // Pending changes details
            if viewModel.pendingChanges > 0, !viewModel.isSyncing {
                HStack {
                    Text("\(viewModel.pendingChanges) changes waiting to sync")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Clear") {
                        viewModel.clearPendingChanges()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }

            // Sync errors
            if !viewModel.syncErrors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync Errors:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    ForEach(viewModel.syncErrors, id: \.self) { error in
                        Text("• \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .alert("Sync Error", isPresented: $viewModel.showSyncError) {
            Button("OK") {
                viewModel.showSyncError = false
            }
        } message: {
            Text(viewModel.syncErrors.first ?? "An error occurred during synchronization")
        }
    }
}

/// Compact sync indicator for navigation bar
struct CacheSyncIndicator: View {
    @StateObject private var viewModel = CacheSyncViewModel()

    var body: some View {
        HStack(spacing: 4) {
            if viewModel.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
            } else if viewModel.pendingChanges > 0 {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                Text("\(viewModel.pendingChanges)")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(.green)
            }
        }
        .onTapGesture {
            if !viewModel.isSyncing, viewModel.pendingChanges > 0 {
                viewModel.triggerSync()
            }
        }
    }
}

// Previews are not used in this project
