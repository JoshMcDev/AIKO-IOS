import SwiftUI
import ComposableArchitecture
#if os(iOS)
import VisionKit
#endif

// MARK: - Document Scanner View

#if os(iOS)
public struct DocumentScannerView: View {
    @Bindable var store: StoreOf<DocumentScannerFeature>
    
    public init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
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
            .sheet(isPresented: $store.isScannerPresented) {
                DocumentCameraView(store: store)
                    .ignoresSafeArea()
            }
            .alert("Error", isPresented: $store.showingError) {
                Button("OK") {
                    store.send(.dismissError)
                }
            } message: {
                if let error = store.error {
                    Text(error)
                }
            }
            .overlay {
                if store.isSavingToDocumentPipeline {
                    savingOverlay
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Documents Scanned")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the button below to scan your first document")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                store.send(.scanButtonTapped)
            }) {
                Label("Scan Document", systemImage: "camera.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
    }
    
    // MARK: - Scanned Pages View
    
    private var scannedPagesView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Document Info Section
                documentInfoSection
                
                // Pages Grid
                pagesGrid
                
                // Processing Status
                if store.isProcessingAllPages {
                    processingStatusView
                }
                
                // Action Buttons
                actionButtonsSection
            }
            .padding()
        }
    }
    
    // MARK: - Document Info Section
    
    private var documentInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Document Title", text: $store.documentTitle)
                .textFieldStyle(.roundedBorder)
                .font(.headline)
            
            HStack {
                Text("Document Type:")
                    .foregroundColor(.secondary)
                
                Menu {
                    ForEach(DocumentType.allCases, id: \.self) { type in
                        Button(action: {
                            store.send(.selectDocumentType(type))
                        }) {
                            Label(type.displayName, systemImage: type.iconName)
                        }
                    }
                } label: {
                    HStack {
                        if let docType = store.documentType {
                            Label(docType.displayName, systemImage: docType.iconName)
                        } else {
                            Text("Select Type")
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                }
            }
            
            // Settings
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Image Enhancement", isOn: $store.enableImageEnhancement)
                Toggle("Text Recognition (OCR)", isOn: $store.enableOCR)
            }
            .font(.footnote)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Pages Grid
    
    private var pagesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
            ForEach(store.scannedPages) { page in
                ScannedPageThumbnail(
                    page: page,
                    isSelected: store.selectedPages.contains(page.id),
                    isSelectionMode: store.isInSelectionMode,
                    onTap: {
                        if store.isInSelectionMode {
                            store.send(.togglePageSelection(page.id))
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
            
            // Add more pages button
            Button(action: {
                store.send(.scanButtonTapped)
            }) {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                    Text("Add Pages")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.secondary)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Processing Status View
    
    private var processingStatusView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Processing \(store.processedPagesCount) of \(store.totalPagesCount) pages...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !store.isProcessingAllPages && store.scannedPages.contains(where: { $0.processingError != nil }) {
                Button(action: {
                    store.send(.processAllPages)
                }) {
                    Label("Retry Failed Processing", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            Button(action: {
                store.send(.saveToDocumentPipeline)
            }) {
                Label("Save Document", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!store.canSaveDocument)
        }
    }
    
    // MARK: - Toolbar Content
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                store.send(.dismissScanner)
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if store.hasScannedPages {
                if store.isInSelectionMode {
                    Button("Done") {
                        store.send(.toggleSelectionMode)
                    }
                } else {
                    Menu {
                        Button(action: {
                            store.send(.toggleSelectionMode)
                        }) {
                            Label("Select Pages", systemImage: "checkmark.circle")
                        }
                        
                        Menu("Scan Quality") {
                            ForEach(DocumentScannerFeature.ScanQuality.allCases, id: \.self) { quality in
                                Button(action: {
                                    store.send(.updateScanQuality(quality))
                                }) {
                                    HStack {
                                        Text(quality.rawValue)
                                        if store.scanQuality == quality {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Saving Overlay
    
    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Saving Document...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Scanned Page Thumbnail

struct ScannedPageThumbnail: View {
    let page: ScannedPage
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Page image
                Image(uiImage: page.enhancedImage ?? page.originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    .shadow(radius: 2)
                
                // Selection indicator
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .background(Circle().fill(Color(.systemBackground)))
                        .padding(8)
                }
                
                // Processing indicator
                if page.isProcessing {
                    ZStack {
                        Color.black.opacity(0.5)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .cornerRadius(8)
                }
                
                // Error indicator
                if page.processingError != nil {
                    ZStack {
                        Color.black.opacity(0.5)
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                            Button("Retry") {
                                onRetry()
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(4)
                        }
                    }
                    .cornerRadius(8)
                }
            }
            
            // Page info
            HStack {
                Text("Page \(page.pageNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !isSelectionMode && !page.isProcessing {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // OCR text preview
            if let ocrText = page.ocrText, !ocrText.isEmpty {
                Text(ocrText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Document Type Extension

extension DocumentType {
    var iconName: String {
        switch self {
        case .sow, .soo, .pws: return "doc.text"
        case .qasp: return "checkmark.shield"
        case .costEstimate: return "dollarsign.square"
        case .marketResearch: return "chart.bar.doc.horizontal"
        case .acquisitionPlan: return "doc.text.fill"
        case .evaluationPlan: return "doc.badge.gearshape"
        case .fiscalLawReview: return "building.columns"
        case .opsecReview: return "lock.shield"
        case .smallBusinessReview: return "building.2"
        case .farDeviation: return "exclamationmark.triangle"
        case .determinationFindings: return "checkmark.seal"
        case .rrd: return "doc.richtext"
        case .igce: return "dollarsign.circle"
        case .requestorChecklist: return "checklist"
        default: return "doc"
        }
    }
}

// MARK: - Scan Quality Extension

extension DocumentScannerFeature.ScanQuality: CaseIterable {}
#endif // os(iOS)