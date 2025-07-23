#if os(iOS)
    import AIKOiOS
    import AppCore
    import ComposableArchitecture
    import SwiftUI
    import UIKit

    /// iOS-specific implementation of Document Scanner View
    public struct DocumentScannerView: View {
        let store: StoreOf<DocumentScannerFeature>
        @ObservedObject var viewStore: ViewStoreOf<DocumentScannerFeature>
        let mode: ScannerMode

        public init(store: StoreOf<DocumentScannerFeature>, mode: ScannerMode = .fullEdit) {
            self.store = store
            viewStore = ViewStore(store, observe: { $0 })
            self.mode = mode
        }

        public var body: some View {
            SwiftUI.NavigationView {
                Group {
                    if mode == .quickScan, viewStore.isQuickScanning {
                        QuickScanProgressView(store: store)
                    } else if viewStore.hasScannedPages {
                        ScannedPagesListView(store: store, mode: mode)
                    } else {
                        EmptyScannerView(store: store, mode: mode)
                    }
                }
                .navigationTitle("Document Scanner")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            viewStore.send(.dismissScanner)
                        }
                    }

                    if viewStore.hasScannedPages {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button {
                                    viewStore.send(.scanButtonTapped)
                                } label: {
                                    Label("Scan More Pages", systemImage: "doc.badge.plus")
                                }

                                Button {
                                    viewStore.send(.toggleSelectionMode)
                                } label: {
                                    Label(
                                        viewStore.isInSelectionMode ? "Done" : "Select",
                                        systemImage: viewStore.isInSelectionMode ? "checkmark.circle" : "checkmark.circle"
                                    )
                                }

                                if viewStore.canSaveDocument {
                                    Button {
                                        viewStore.send(.saveToDocumentPipeline)
                                    } label: {
                                        Label("Save Document", systemImage: "square.and.arrow.down")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
                .sheet(isPresented: .init(
                    get: { viewStore.isScannerPresented },
                    set: { viewStore.send(.setScannerPresented($0)) }
                )) {
                    DocumentCameraView { result in
                        viewStore.send(.scannerDidFinish(result))
                    }
                    .ignoresSafeArea()
                }
                .overlay(
                    // Processing Progress Overlay
                    Group {
                        if viewStore.showProcessingProgress,
                           let progress = viewStore.pageProcessingProgress
                        {
                            ProcessingProgressOverlay(progress: progress)
                        }
                    }
                )
                .sheet(isPresented: .init(
                    get: { viewStore.showEnhancementPreview },
                    set: { _ in viewStore.send(.hideEnhancementPreview) }
                )) {
                    if let pageId = viewStore.enhancementPreviewPageId,
                       let page = viewStore.scannedPages[id: pageId]
                    {
                        EnhancementPreviewView(page: page)
                    }
                }
                .alert(
                    "Error",
                    isPresented: .init(
                        get: { viewStore.showingError },
                        set: { _ in viewStore.send(.dismissError) }
                    ),
                    actions: {
                        Button("OK") {
                            viewStore.send(.dismissError)
                        }
                    },
                    message: {
                        if let error = viewStore.error {
                            Text(error)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Empty Scanner View

    struct EmptyScannerView: View {
        let store: StoreOf<DocumentScannerFeature>
        @ObservedObject var viewStore: ViewStoreOf<DocumentScannerFeature>
        let mode: ScannerMode

        init(store: StoreOf<DocumentScannerFeature>, mode: ScannerMode = .fullEdit) {
            self.store = store
            viewStore = ViewStore(store, observe: { $0 })
            self.mode = mode
        }

        var body: some View {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)

                Text("No Documents Scanned")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Tap the button below to start scanning documents")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: {
                    viewStore.send(.scanButtonTapped)
                }) {
                    Label("Scan Document", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.top, 20)

                Spacer()
            }
        }
    }

    // MARK: - Scanned Pages List View

    struct ScannedPagesListView: View {
        let store: StoreOf<DocumentScannerFeature>
        @ObservedObject var viewStore: ViewStoreOf<DocumentScannerFeature>
        let mode: ScannerMode

        init(store: StoreOf<DocumentScannerFeature>, mode: ScannerMode = .fullEdit) {
            self.store = store
            viewStore = ViewStore(store, observe: { $0 })
            self.mode = mode
        }

        var body: some View {
            List {
                // Document Info Section
                Section("Document Information") {
                    TextField("Document Title", text: .init(
                        get: { viewStore.documentTitle },
                        set: { viewStore.send(.updateDocumentTitle($0)) }
                    ))

                    Picker("Document Type", selection: .init(
                        get: { viewStore.documentType },
                        set: { if let type = $0 { viewStore.send(.selectDocumentType(type)) } }
                    )) {
                        Text("Select Type").tag(nil as DocumentType?)
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Text(type.shortName).tag(type as DocumentType?)
                        }
                    }
                }

                // Processing Quality Section
                Section("Processing Quality") {
                    Picker("Processing Mode", selection: .init(
                        get: { viewStore.processingMode },
                        set: { viewStore.send(.updateProcessingMode($0)) }
                    )) {
                        ForEach(DocumentImageProcessor.ProcessingMode.allCases, id: \.self) { mode in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.headline)
                                Text(mode == .basic ? "Fast processing with standard quality" : "Advanced processing with superior quality")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if viewStore.estimatedProcessingTime > 0 {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Estimated time: \(Int(viewStore.estimatedProcessingTime))s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if viewStore.averageQualityScore > 0 {
                                Text("Avg Quality: \(Int(viewStore.averageQualityScore * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Settings Section
                Section("Processing Options") {
                    Toggle("Enhance Images", isOn: .init(
                        get: { viewStore.enableImageEnhancement },
                        set: { viewStore.send(.toggleImageEnhancement($0)) }
                    ))

                    Toggle("Extract Text (OCR)", isOn: .init(
                        get: { viewStore.enableOCR },
                        set: { viewStore.send(.toggleOCR($0)) }
                    ))

                    Picker("Scan Quality", selection: .init(
                        get: { viewStore.scanQuality },
                        set: { viewStore.send(.updateScanQuality($0)) }
                    )) {
                        ForEach(DocumentScannerFeature.ScanQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Scanned Pages Section
                Section(header: HStack {
                    Text("Scanned Pages")
                    Spacer()
                    Text("\(viewStore.processedPagesCount) of \(viewStore.totalPagesCount) processed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }) {
                    ForEach(viewStore.scannedPages) { page in
                        ScannedPageRow(
                            page: page,
                            isSelected: viewStore.selectedPages.contains(page.id),
                            isSelectionMode: viewStore.isInSelectionMode,
                            onTap: {
                                if viewStore.isInSelectionMode {
                                    viewStore.send(.togglePageSelection(page.id))
                                }
                            },
                            onDelete: {
                                viewStore.send(.deletePage(page.id))
                            },
                            onRetry: {
                                viewStore.send(.retryPageProcessing(page.id))
                            },
                            onPreview: {
                                viewStore.send(.showEnhancementPreview(page.id))
                            }
                        )
                    }
                    .onMove { indices, newOffset in
                        viewStore.send(.reorderPages(indices, newOffset))
                    }
                    .onDelete { indices in
                        for index in indices {
                            if index >= 0, index < viewStore.scannedPages.count {
                                let page = viewStore.scannedPages[index]
                                viewStore.send(.deletePage(page.id))
                            }
                        }
                    }
                }

                // Enhanced Processing Section
                if viewStore.canReprocessWithEnhanced {
                    Section("Enhanced Processing") {
                        Button {
                            viewStore.send(.reprocessAllWithEnhanced)
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reprocess All with Enhanced Mode")
                                        .font(.headline)
                                    Text("Upgrade all pages to enhanced quality")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .disabled(viewStore.isProcessingAllPages)
                    }
                }

                // Actions Section
                if viewStore.hasScannedPages {
                    Section {
                        if viewStore.isInSelectionMode {
                            HStack {
                                Button("Select All") {
                                    viewStore.send(.selectAllPages)
                                }

                                Spacer()

                                Button("Delete Selected") {
                                    viewStore.send(.deleteSelectedPages)
                                }
                                .foregroundColor(.red)
                                .disabled(viewStore.selectedPages.isEmpty)

                                if viewStore.processingMode == .basic, !viewStore.selectedPages.isEmpty {
                                    Button("Enhance Selected") {
                                        viewStore.send(.reprocessWithEnhanced(Array(viewStore.selectedPages)))
                                    }
                                    .disabled(viewStore.isProcessingAllPages)
                                }
                            }
                        }

                        if viewStore.processedPagesCount < viewStore.totalPagesCount {
                            Button {
                                viewStore.send(.processAllPages)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Process All Pages")
                                }
                            }
                            .disabled(viewStore.isProcessingAllPages)
                        }

                        Button {
                            viewStore.send(.saveToDocumentPipeline)
                        } label: {
                            HStack {
                                Spacer()
                                if viewStore.isSavingToDocumentPipeline {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                }
                                Text("Save to Documents")
                                Spacer()
                            }
                            .foregroundColor(.white)
                        }
                        .listRowBackground(Color.accentColor)
                        .disabled(!viewStore.canSaveDocument)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .environment(\.editMode, .constant(viewStore.isInSelectionMode ? .active : .inactive))
        }
    }

    // MARK: - Scanned Page Row

    struct ScannedPageRow: View {
        let page: ScannedPage
        let isSelected: Bool
        let isSelectionMode: Bool
        let onTap: () -> Void
        let onDelete: () -> Void
        let onRetry: () -> Void
        let onPreview: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                // Selection indicator
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .onTapGesture {
                            onTap()
                        }
                }

                // Thumbnail
                let imageData = page.thumbnailData ?? page.imageData
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 60, height: 80)
                        .overlay(
                            Image(systemName: "doc")
                                .foregroundColor(.secondary)
                        )
                }

                // Page info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Page \(page.pageNumber)")
                            .font(.headline)

                        Spacer()

                        // Quality indicators
                        if let qualityScore = page.qualityScore {
                            QualityBadge(score: qualityScore)
                        }

                        if page.enhancementApplied {
                            Image(systemName: "wand.and.stars.inverse")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                    }

                    if case .processing = page.processingState {
                        HStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                            Text("Processing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if case let .failed(error) = page.processingState {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    } else if case .completed = page.processingState {
                        HStack(spacing: 8) {
                            if page.ocrText != nil {
                                HStack(spacing: 2) {
                                    Image(systemName: "text.viewfinder")
                                        .font(.caption)
                                    Text("OCR")
                                        .font(.caption)
                                    if let confidence = page.qualityScore {
                                        Text("\(Int(confidence * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .foregroundColor(.green)
                            }

                            if let processingMode = page.processingMode {
                                Text(processingMode.rawValue.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(processingMode == .enhanced ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: 8) {
                    if case .failed = page.processingState {
                        Button(action: onRetry) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }

                    if page.enhancementApplied, page.enhancedImageData != nil {
                        Button(action: onPreview) {
                            Image(systemName: "eye")
                                .foregroundColor(.purple)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isSelectionMode {
                    onTap()
                }
            }
        }
    }

    // MARK: - Document Camera View

    struct DocumentCameraView: UIViewControllerRepresentable {
        let completion: (Result<ScannedDocument, Error>) -> Void

        func makeUIViewController(context _: Context) -> UIViewController {
            let adapter = VisionKitAdapter()

            // Set completion handler
            adapter.uiManager.setCompletion { (result: VisionKitAdapter.ScanResult) in
                switch result {
                case let .success(document):
                    completion(.success(document))
                case .cancelled:
                    completion(.failure(DocumentScannerError.userCancelled))
                case let .failed(error):
                    completion(.failure(error))
                }
            }

            // Return the actual UIViewController
            return adapter.createDocumentCameraViewController()
        }

        func updateUIViewController(_: UIViewController, context _: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator: NSObject {
            // Minimal coordinator for compatibility with VisionKitAdapter
        }
    }

    // MARK: - Phase 4.1 Enhanced UI Components

    // MARK: - Quality Badge

    struct QualityBadge: View {
        let score: Double

        var body: some View {
            let percentage = Int(score * 100)
            let color: Color = switch score {
            case 0.8...: .green
            case 0.6...: .orange
            default: .red
            }

            Text("\(percentage)%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .cornerRadius(8)
        }
    }

    // MARK: - Processing Progress Overlay

    struct ProcessingProgressOverlay: View {
        let progress: DocumentScannerFeature.PageProcessingProgress

        var body: some View {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Progress indicator
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Processing Page \(getPageNumber())")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(progress.processingProgress.currentStep.displayName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)

                    // Progress details
                    VStack(spacing: 8) {
                        ProgressView(value: progress.processingProgress.overallProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .scaleEffect(x: 1, y: 2, anchor: .center)

                        HStack {
                            Text("Progress: \(Int(progress.processingProgress.overallProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            if let remainingTime = progress.processingProgress.estimatedTimeRemaining,
                               remainingTime > 0
                            {
                                Text("~\(Int(remainingTime))s remaining")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }

        private func getPageNumber() -> Int {
            // In a real implementation, you'd get this from the page data
            1
        }
    }

    // MARK: - Enhancement Preview View

    struct EnhancementPreviewView: View {
        let page: ScannedPage
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            SwiftUI.NavigationView {
                VStack(spacing: 16) {
                    // Before/After comparison
                    if let enhancedData = page.enhancedImageData,
                       let originalImage = UIImage(data: page.imageData),
                       let enhancedImage = UIImage(data: enhancedData)
                    {
                        ScrollView {
                            VStack(spacing: 20) {
                                // Original image
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Original")
                                        .font(.headline)
                                        .foregroundColor(.secondary)

                                    Image(uiImage: originalImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                }

                                // Enhanced image
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Enhanced")
                                            .font(.headline)
                                            .foregroundColor(.purple)

                                        Spacer()

                                        if let qualityScore = page.qualityScore {
                                            QualityBadge(score: qualityScore)
                                        }
                                    }

                                    Image(uiImage: enhancedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                                        )
                                }

                                // Quality metrics
                                if let qualityScore = page.qualityScore {
                                    QualityMetricsView(score: qualityScore)
                                }
                            }
                            .padding()
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)

                            Text("Enhancement preview not available")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("The enhanced version of this page is not ready yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    Spacer()
                }
                .navigationTitle("Enhancement Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quality Metrics View

    struct QualityMetricsView: View {
        let score: Double

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quality Analysis")
                    .font(.headline)

                VStack(spacing: 8) {
                    QualityMetricRow(title: "Overall Quality", score: score)
                    QualityMetricRow(title: "Sharpness", score: min(1.0, score + 0.1))
                    QualityMetricRow(title: "Contrast", score: min(1.0, score + 0.05))
                    QualityMetricRow(title: "Text Clarity", score: max(0.0, score - 0.05))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Quality Metric Row

    struct QualityMetricRow: View {
        let title: String
        let score: Double

        var body: some View {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                ProgressView(value: score, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 80)

                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 35, alignment: .trailing)
            }
        }
    }

    // MARK: - Quick Scan Progress View

    struct QuickScanProgressView: View {
        let store: StoreOf<DocumentScannerFeature>
        @ObservedObject var viewStore: ViewStoreOf<DocumentScannerFeature>

        init(store: StoreOf<DocumentScannerFeature>) {
            self.store = store
            viewStore = ViewStore(store, observe: { $0 })
        }

        var body: some View {
            VStack(spacing: 32) {
                Spacer()

                // Progress Circle with Camera Icon
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(viewStore.quickScanProgress?.overallProgress ?? 0))
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.aikoPrimary, Theme.Colors.aikoAccent],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: viewStore.quickScanProgress?.overallProgress)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.aikoPrimary)
                }

                // Status Text
                VStack(spacing: 8) {
                    if let progress = viewStore.quickScanProgress {
                        Text(progress.step.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("\(Int(progress.overallProgress * 100))% Complete")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let timeRemaining = progress.estimatedTimeRemaining, timeRemaining > 0 {
                            Text("~\(Int(timeRemaining))s remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Initializing Scanner...")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }

                // Scanning Instructions
                if viewStore.quickScanProgress?.step == .scanning {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(Theme.Colors.aikoPrimary)
                            Text("Position your document in the camera view")
                                .font(.body)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(Theme.Colors.aikoPrimary)
                            Text("Tap the shutter button to capture")
                                .font(.body)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(Theme.Colors.aikoPrimary)
                            Text("Tap 'Save' to finish scanning")
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer()

                // Cancel Button
                Button("Cancel") {
                    viewStore.send(.dismissScanner)
                }
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
            }
            .padding()
            .onAppear {
                // Set scanner mode when view appears
                viewStore.send(.setScannerMode(.quickScan))
            }
        }
    }

#endif
