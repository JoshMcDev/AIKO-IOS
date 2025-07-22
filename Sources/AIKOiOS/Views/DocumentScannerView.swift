#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Perception
    import SwiftUI
    import VisionKit

    /// VisionKit Document Scanner UI Integration for DocumentScannerFeature
    /// Provides platform-specific VisionKit scanning interface with TCA integration
    @MainActor
    public struct DocumentScannerView: View {
        @Perception.Bindable public var store: StoreOf<DocumentScannerFeature>

        public init(store: StoreOf<DocumentScannerFeature>) {
            self.store = store
        }

        public var body: some View {
            WithPerceptionTracking {
                VStack(spacing: 0) {
                    // Main content
                    if store.hasScannedPages {
                        scannedPagesView
                    } else {
                        emptyStateView
                    }
                }
                .navigationTitle("Document Scanner")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: Binding(
                    get: { store.isScannerPresented },
                    set: { store.send(.setScannerPresented($0)) }
                )) {
                    documentCameraView
                }
                .alert("Error", isPresented: Binding(
                    get: { store.showingError },
                    set: { _ in store.send(.dismissError) }
                )) {
                    Button("OK") {
                        store.send(.dismissError)
                    }
                } message: {
                    if let error = store.error {
                        Text(error)
                    }
                }
                .onAppear {
                    // Check camera permissions on appear
                    if !store.cameraPermissionChecked {
                        store.send(.checkCameraPermissions)
                    }
                }
            }
        }

        // MARK: - VisionKit Document Camera View

        @ViewBuilder
        private var documentCameraView: some View {
            if VNDocumentCameraViewController.isSupported {
                VisionKitDocumentCameraView { result in
                    switch result {
                    case let .success(document):
                        store.send(.scannerDidFinish(.success(document)))
                    case .cancelled:
                        store.send(.scannerDidCancel)
                    case let .failed(error):
                        store.send(.scannerDidFinish(.failure(error)))
                    }
                }
                .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Document Scanning Not Available")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Document scanning is not supported on this device.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Dismiss") {
                        store.send(.scannerDidCancel)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }

        // MARK: - Empty State View

        private var emptyStateView: some View {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)

                    Text("Scan Documents")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("Capture high-quality scans with automatic edge detection and enhancement.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    // Main scan button
                    Button {
                        store.send(.scanButtonTapped)
                    } label: {
                        Label("Start Scanning", systemImage: "camera.viewfinder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!store.cameraPermissionGranted)

                    // Quick scan button
                    if store.cameraPermissionGranted {
                        Button {
                            store.send(.startQuickScan)
                        } label: {
                            Label("Quick Scan", systemImage: "bolt.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 40)

                // Permission status
                if !store.cameraPermissionGranted, store.cameraPermissionChecked {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill.badge.ellipsis")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)

                        Text("Camera Permission Required")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("To scan documents, please allow camera access in Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Open Settings") {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                Spacer()
            }
        }

        // MARK: - Scanned Pages View

        private var scannedPagesView: some View {
            VStack(spacing: 0) {
                // Progress view for processing
                if store.isProcessingAllPages || store.isAutoPopulating {
                    processingProgressView
                }

                // Pages list
                List {
                    ForEach(store.scannedPages) { page in
                        DocumentPageRow(
                            page: page,
                            isSelected: store.selectedPages.contains(page.id),
                            isInSelectionMode: store.isInSelectionMode,
                            onTap: {
                                if store.isInSelectionMode {
                                    store.send(.togglePageSelection(page.id))
                                } else {
                                    // Show page detail or enhancement preview
                                    store.send(.showEnhancementPreview(page.id))
                                }
                            },
                            onDelete: {
                                store.send(.deletePage(page.id))
                            },
                            onRetry: {
                                store.send(.retryPageProcessing(page.id))
                            }
                        )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let page = store.scannedPages[index]
                            store.send(.deletePage(page.id))
                        }
                    }
                    .onMove { indices, newOffset in
                        store.send(.reorderPages(indices, newOffset))
                    }
                }
                .listStyle(.plain)

                // Bottom action bar
                if store.hasScannedPages {
                    bottomActionBar
                }
            }
        }

        // MARK: - Processing Progress View

        private var processingProgressView: some View {
            VStack(spacing: 8) {
                if store.isProcessingAllPages {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)

                        Text("Processing \(store.processedPagesCount) of \(store.totalPagesCount) pages...")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }

                if store.isAutoPopulating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)

                        Text("Analyzing document for auto-population...")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
        }

        // MARK: - Bottom Action Bar

        private var bottomActionBar: some View {
            WithPerceptionTracking {
                VStack(spacing: 12) {
                    // Document title input
                    HStack {
                        TextField("Document Title", text: Binding(
                            get: { store.documentTitle },
                            set: { store.send(.updateDocumentTitle($0)) }
                        ))
                        .textFieldStyle(.roundedBorder)

                        Button {
                            store.send(.scanButtonTapped)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        // Selection mode toggle
                        Button {
                            store.send(.toggleSelectionMode)
                        } label: {
                            Label(
                                store.isInSelectionMode ? "Done" : "Select",
                                systemImage: store.isInSelectionMode ? "checkmark.circle" : "checkmark.circle"
                            )
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        // Process all pages
                        if !store.isProcessingAllPages {
                            Button {
                                store.send(.processAllPages)
                            } label: {
                                Label("Enhance All", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(.bordered)
                        }

                        // Save to document pipeline
                        Button {
                            store.send(.saveToDocumentPipeline)
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.canSaveDocument)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color(UIColor.separator)),
                        alignment: .top
                    )
                }
            }
        }

        // MARK: - Toolbar Content

        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                WithPerceptionTracking {
                    Menu {
                        // Scanner mode options
                        Picker("Scanner Mode", selection: Binding(
                            get: { store.scannerMode },
                            set: { store.send(.setScannerMode($0)) }
                        )) {
                            ForEach(ScannerMode.allCases, id: \.self) { mode in
                                Label(mode.title, systemImage: mode.systemImage)
                                    .tag(mode)
                            }
                        }

                        Divider()

                        // Processing options
                        Toggle("Image Enhancement", isOn: Binding(
                            get: { store.enableImageEnhancement },
                            set: { store.send(.toggleImageEnhancement($0)) }
                        ))
                        Toggle("OCR Processing", isOn: Binding(
                            get: { store.enableOCR },
                            set: { store.send(.toggleOCR($0)) }
                        ))
                        Toggle("Enhanced OCR", isOn: Binding(
                            get: { store.useEnhancedOCR },
                            set: { store.send(.toggleEnhancedOCR($0)) }
                        ))

                        Divider()

                        // Quality settings
                        Picker("Scan Quality", selection: Binding(
                            get: { store.scanQuality },
                            set: { store.send(.updateScanQuality($0)) }
                        )) {
                            ForEach(DocumentScannerFeature.ScanQuality.allCases, id: \.self) { quality in
                                Text(quality.title).tag(quality)
                            }
                        }

                        // Processing mode
                        Picker("Processing Mode", selection: Binding(
                            get: { store.processingMode },
                            set: { store.send(.updateProcessingMode($0)) }
                        )) {
                            ForEach(DocumentImageProcessor.ProcessingMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }

                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }

            // Quick scan button in navigation
            ToolbarItem(placement: .topBarLeading) {
                if store.cameraPermissionGranted, !store.isQuickScanning {
                    Button {
                        store.send(.startQuickScan)
                    } label: {
                        Image(systemName: "bolt.circle")
                    }
                }
            }
        }
    }

    // MARK: - Document Page Row

    private struct DocumentPageRow: View {
        let page: ScannedPage
        let isSelected: Bool
        let isInSelectionMode: Bool
        let onTap: () -> Void
        let onDelete: () -> Void
        let onRetry: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                // Selection indicator
                if isInSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .font(.title3)
                }

                // Page thumbnail
                AsyncImage(url: nil) { _ in
                    // Placeholder for page thumbnail
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 80)
                        .overlay {
                            Image(systemName: "doc.text.image")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 80)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                }

                // Page info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Page \(page.pageNumber)")
                            .font(.headline)

                        Spacer()

                        // Processing status
                        switch page.processingState {
                        case .pending:
                            Label("Pending", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.orange)
                        case .processing:
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Processing")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        case .completed:
                            Label("Ready", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        case .failed:
                            Button("Retry") {
                                onRetry()
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                        }
                    }

                    // Quality score
                    if let qualityScore = page.qualityScore {
                        HStack {
                            Text("Quality:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            QualityIndicator(score: qualityScore)
                        }
                    }

                    // OCR status
                    if let ocrResult = page.ocrResult {
                        HStack {
                            Image(systemName: "text.magnifyingglass")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Text("OCR: \(Int(ocrResult.confidence * 100))% confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Delete", role: .destructive) {
                    onDelete()
                }

                if case .failed = page.processingState {
                    Button("Retry") {
                        onRetry()
                    }
                    .tint(.orange)
                }
            }
        }
    }

    // MARK: - Quality Indicator

    private struct QualityIndicator: View {
        let score: Double

        private var color: Color {
            switch score {
            case 0.8...: .green
            case 0.6 ..< 0.8: .orange
            default: .red
            }
        }

        private var label: String {
            switch score {
            case 0.8...: "Excellent"
            case 0.6 ..< 0.8: "Good"
            default: "Poor"
            }
        }

        var body: some View {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 30, height: 4)

                Text(label)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
    }

    // MARK: - VisionKit Document Camera View

    private struct VisionKitDocumentCameraView: UIViewControllerRepresentable {
        let completion: (VisionKitAdapter.ScanResult) -> Void

        func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
            let adapter = VisionKitAdapter()
            let controller = adapter.createDocumentCameraViewController()

            // Set up completion handling through coordinator
            context.coordinator.completion = completion
            context.coordinator.adapter = adapter

            return controller
        }

        func updateUIViewController(_: VNDocumentCameraViewController, context _: Context) {
            // No updates needed
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(completion: completion)
        }

        class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
            var completion: (VisionKitAdapter.ScanResult) -> Void
            var adapter: VisionKitAdapter?

            init(completion: @escaping (VisionKitAdapter.ScanResult) -> Void) {
                self.completion = completion
            }

            func documentCameraViewController(
                _: VNDocumentCameraViewController,
                didFinishWith scan: VNDocumentCameraScan
            ) {
                // Convert VNDocumentCameraScan to ScannedDocument
                var pages: [ScannedPage] = []

                for i in 0 ..< scan.pageCount {
                    let image = scan.imageOfPage(at: i)
                    if let imageData = image.jpegData(compressionQuality: 0.9) {
                        let page = ScannedPage(
                            id: UUID(),
                            imageData: imageData,
                            pageNumber: i + 1
                        )
                        pages.append(page)
                    }
                }

                let document = ScannedDocument(
                    id: UUID(),
                    pages: pages,
                    scannedAt: Date()
                )

                completion(.success(document))
            }

            func documentCameraViewControllerDidCancel(_: VNDocumentCameraViewController) {
                completion(.cancelled)
            }

            func documentCameraViewController(
                _: VNDocumentCameraViewController,
                didFailWithError error: Error
            ) {
                completion(.failed(error))
            }
        }
    }

    // MARK: - Extensions

    private extension ScannerMode {
        var title: String {
            switch self {
            case .fullEdit: "Full Edit"
            case .quickScan: "Quick Scan"
            }
        }

        var systemImage: String {
            switch self {
            case .fullEdit: "doc.text.image"
            case .quickScan: "bolt.circle"
            }
        }
    }

    private extension DocumentScannerFeature.ScanQuality {
        var title: String {
            switch self {
            case .low: "Low"
            case .medium: "Medium"
            case .high: "High"
            }
        }
    }

    private extension DocumentImageProcessor.ProcessingMode {
        var title: String {
            switch self {
            case .basic: "Basic"
            case .enhanced: "Enhanced"
            case .documentScanner: "Document Scanner"
            }
        }
    }

#endif
