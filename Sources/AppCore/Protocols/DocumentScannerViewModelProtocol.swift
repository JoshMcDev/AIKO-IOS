import Foundation
import SwiftUI

/// Protocol defining the interface for document scanner view models
/// This enables platform-agnostic view models that work across iOS and macOS
@MainActor
public protocol DocumentScannerViewModelProtocol: ObservableObject {

    // MARK: - State Properties

    /// Whether scanning is currently active
    var isScanning: Bool { get }

    /// Array of scanned pages
    var scannedPages: [ScannedPage] { get }

    /// Index of the currently selected page
    var currentPage: Int { get }

    /// Current error state, if any
    var error: Error? { get }

    /// Progress of current scanning operation (0.0 to 1.0)
    var scanProgress: Double { get }

    /// Whether pages are currently being processed
    var isProcessing: Bool { get }

    // MARK: - Scanning Methods

    /// Start the document scanning process
    func startScanning() async

    /// Stop the current scanning process
    func stopScanning()

    /// Request camera permissions for scanning
    func requestCameraPermissions() async -> Bool

    /// Check if camera permissions are granted
    func checkCameraPermissions() async -> Bool

    // MARK: - Page Management

    /// Add a new scanned page
    func addPage(_ page: ScannedPage)

    /// Remove a page at the specified index
    func removePage(at index: Int)

    /// Reorder pages by moving from source indices to destination
    func reorderPages(from source: IndexSet, to destination: Int)

    /// Process and enhance a single page
    func processPage(_ page: ScannedPage) async throws -> ScannedPage

    /// Enhance all scanned pages
    func enhanceAllPages() async

    // MARK: - Session Management

    /// Clear the current scan session and all pages
    func clearSession()

    /// Export all pages as a single document
    func exportPages() async throws -> Data
}
