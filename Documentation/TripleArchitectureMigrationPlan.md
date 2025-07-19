# AIKO Triple Architecture Migration Plan
## Minimizing Platform-Specific Wrapping in TCA

### Executive Summary

This document outlines a comprehensive migration plan to refactor the AIKO iOS/macOS app from its current architecture (with excessive `#if os(iOS)` conditionals) to a clean Triple Architecture approach that maintains The Composable Architecture (TCA) patterns while dramatically improving maintainability, testability, and scalability.

**Key Goals:**
- Eliminate 90%+ of platform-specific conditionals
- Improve code reusability across iOS and macOS
- Maintain TCA architectural principles
- Enable easier addition of new platforms (watchOS, tvOS)
- Improve testability with clean dependency injection

---

## Current State Analysis

### Problems with Current Architecture

1. **Excessive Platform Conditionals**
   - DocumentScanner features riddled with `#if os(iOS)`
   - Platform-specific imports scattered throughout shared code
   - Difficult to test macOS paths when iOS-specific code won't compile

2. **Tight Coupling**
   - Business logic directly dependent on platform frameworks (VisionKit, UIKit)
   - Reducers contain platform-specific implementation details
   - Views mixing business logic with platform concerns

3. **Poor Maintainability**
   - Changes require updating multiple conditional blocks
   - Risk of platform-specific bugs due to code drift
   - Cognitive overhead tracking which code runs on which platform

---

## Triple Architecture Overview

The Triple Architecture separates concerns into three distinct layers:

```
┌─────────────────────────────────────────────────────────────┐
│                     Platform UI Layer                        │
│  ┌─────────────────┐              ┌───────────────────┐    │
│  │   iOS Views     │              │   macOS Views     │    │
│  └────────┬────────┘              └────────┬──────────┘    │
│           │                                 │                │
│           └──────────────┬──────────────────┘               │
│                          │                                   │
├──────────────────────────┼───────────────────────────────────┤
│                          ▼                                   │
│                 Shared Core Layer                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  • TCA Reducers, State, Actions                     │   │
│  │  • Business Logic                                   │   │
│  │  • Dependency Protocols                             │   │
│  │  • Platform-Agnostic Models                         │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                    │
├─────────────────────────┼────────────────────────────────────┤
│                         ▼                                    │
│            Platform Implementation Layer                     │
│  ┌────────────────┐              ┌─────────────────────┐   │
│  │ iOS Impls      │              │ macOS Impls        │   │
│  │ • VisionKit    │              │ • AppKit           │   │
│  │ • UIKit        │              │ • macOS Scanner    │   │
│  └────────────────┘              └─────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Layer 1: Shared Core (Platform-Agnostic)

### Module Structure
```
Sources/
├── AppCore/                    # New shared module
│   ├── Dependencies/           # Protocol definitions
│   │   ├── DocumentScannerClient.swift
│   │   ├── CameraClient.swift
│   │   └── FileSystemClient.swift
│   ├── Features/              # TCA features
│   │   ├── AppFeature.swift
│   │   ├── DocumentScannerFeature.swift
│   │   └── AnalysisFeature.swift
│   └── Models/                # Shared data models
│       ├── Document.swift
│       └── ScannedPage.swift
```

### Example: Platform-Agnostic DocumentScanner

```swift
// AppCore/Dependencies/DocumentScannerClient.swift
import ComposableArchitecture
import Foundation

// Platform-agnostic scanned document model
public struct ScannedDocument: Equatable {
    public let id: UUID
    public let pages: [ScannedPage]
    public let metadata: DocumentMetadata
}

public struct ScannedPage: Equatable {
    public let id: UUID
    public let imageData: Data  // Platform-agnostic
    public let ocrText: String?
    public let pageNumber: Int
}

// Protocol defining scanner capabilities
public protocol DocumentScannerClient {
    func scan() async throws -> ScannedDocument
    func enhanceImage(_ imageData: Data) async throws -> Data
    func performOCR(_ imageData: Data) async throws -> String
}

// TCA Dependency
extension DependencyValues {
    public var documentScanner: any DocumentScannerClient {
        get { self[DocumentScannerClientKey.self] }
        set { self[DocumentScannerClientKey.self] = newValue }
    }
}

private enum DocumentScannerClientKey: DependencyKey {
    static let liveValue: any DocumentScannerClient = UnimplementedDocumentScannerClient()
    static let testValue: any DocumentScannerClient = MockDocumentScannerClient()
}
```

### Refactored Feature (No Platform Code!)

```swift
// AppCore/Features/DocumentScannerFeature.swift
import ComposableArchitecture

@Reducer
public struct DocumentScannerFeature {
    @ObservableState
    public struct State: Equatable {
        public var scannedDocument: ScannedDocument?
        public var isScanning: Bool = false
        public var error: String?
    }
    
    public enum Action: Equatable {
        case scanButtonTapped
        case scanResponse(Result<ScannedDocument, Error>)
        case enhancePages
        case dismiss
    }
    
    @Dependency(\.documentScanner) var scanner
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .scanButtonTapped:
                state.isScanning = true
                return .run { send in
                    await send(.scanResponse(
                        await Result { try await scanner.scan() }
                    ))
                }
                
            case let .scanResponse(.success(document)):
                state.isScanning = false
                state.scannedDocument = document
                return .send(.enhancePages)
                
            case let .scanResponse(.failure(error)):
                state.isScanning = false
                state.error = error.localizedDescription
                return .none
                
            case .enhancePages:
                // Enhancement logic using the protocol
                return .none
                
            case .dismiss:
                return .run { _ in await dismiss() }
            }
        }
    }
}
```

---

## Layer 2: Platform Implementation

### iOS Implementation Module

```
Sources/
├── AIKOiOS/                   # iOS-specific module
│   ├── Dependencies/
│   │   └── DocumentScannerClient+Live.swift
│   └── UIComponents/
│       └── DocumentCameraView.swift
```

```swift
// AIKOiOS/Dependencies/DocumentScannerClient+Live.swift
import AppCore
import VisionKit
import UIKit

struct iOSDocumentScannerClient: DocumentScannerClient {
    func scan() async throws -> ScannedDocument {
        // Use VisionKit here
        let controller = VNDocumentCameraViewController()
        // ... implementation
    }
    
    func enhanceImage(_ imageData: Data) async throws -> Data {
        guard let uiImage = UIImage(data: imageData) else {
            throw ScannerError.invalidImageData
        }
        // Use Core Image filters
        // ... implementation
    }
    
    func performOCR(_ imageData: Data) async throws -> String {
        // Use Vision framework
        // ... implementation
    }
}

// Register the implementation
extension DocumentScannerClientKey {
    static let liveValue: any DocumentScannerClient = iOSDocumentScannerClient()
}
```

### macOS Implementation Module

```
Sources/
├── AIKOmacOS/                 # macOS-specific module
│   ├── Dependencies/
│   │   └── DocumentScannerClient+Live.swift
│   └── UIComponents/
│       └── MacScannerView.swift
```

```swift
// AIKOmacOS/Dependencies/DocumentScannerClient+Live.swift
import AppCore
import AppKit
import ImageCaptureCore

struct macOSDocumentScannerClient: DocumentScannerClient {
    func scan() async throws -> ScannedDocument {
        // Use ImageCaptureCore or file picker
        let openPanel = NSOpenPanel()
        // ... implementation
    }
    
    func enhanceImage(_ imageData: Data) async throws -> Data {
        guard let nsImage = NSImage(data: imageData) else {
            throw ScannerError.invalidImageData
        }
        // Use Core Image filters
        // ... implementation
    }
    
    func performOCR(_ imageData: Data) async throws -> String {
        // Use Vision framework (available on macOS too)
        // ... implementation
    }
}

// Register the implementation
extension DocumentScannerClientKey {
    static let liveValue: any DocumentScannerClient = macOSDocumentScannerClient()
}
```

---

## Layer 3: Platform UI

### Shared View Interface

```swift
// AppCore/Views/DocumentScannerViewProtocol.swift
import SwiftUI
import ComposableArchitecture

public protocol DocumentScannerViewProtocol: View {
    init(store: StoreOf<DocumentScannerFeature>)
}
```

### iOS View Implementation

```swift
// AIKOiOS/Views/DocumentScannerView.swift
import SwiftUI
import AppCore
import ComposableArchitecture

public struct DocumentScannerView: DocumentScannerViewProtocol {
    @Bindable var store: StoreOf<DocumentScannerFeature>
    
    public init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            // iOS-specific UI implementation
            VStack {
                if store.isScanning {
                    DocumentCameraViewRepresentable()
                } else if let document = store.scannedDocument {
                    // Show scanned pages
                }
            }
            .navigationTitle("Scan Document")
            .toolbar {
                // iOS-specific toolbar
            }
        }
    }
}
```

### macOS View Implementation

```swift
// AIKOmacOS/Views/DocumentScannerView.swift
import SwiftUI
import AppCore
import ComposableArchitecture

public struct DocumentScannerView: DocumentScannerViewProtocol {
    @Bindable var store: StoreOf<DocumentScannerFeature>
    
    public init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            // macOS-specific UI implementation
            if store.isScanning {
                MacScannerSheet()
            } else if let document = store.scannedDocument {
                // Show scanned pages with AppKit styling
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
```

---

## Migration Strategy

### Phase 1: Setup Module Structure (Week 1)

1. **Create New Modules**
   ```bash
   AppCore/        # Shared business logic
   AIKOiOS/       # iOS implementations
   AIKOmacOS/     # macOS implementations
   ```

2. **Update Package.swift**
   ```swift
   targets: [
       .target(name: "AppCore", dependencies: ["ComposableArchitecture"]),
       .target(name: "AIKOiOS", dependencies: ["AppCore"]),
       .target(name: "AIKOmacOS", dependencies: ["AppCore"]),
       .target(name: "AIKO", dependencies: ["AppCore", "AIKOiOS", "AIKOmacOS"])
   ]
   ```

3. **Setup Dependency Injection**

### Phase 2: Migrate Core Features (Week 2-3)

1. **Extract Protocols**
   - DocumentScannerClient
   - CameraClient
   - FileSystemClient
   - NetworkClient

2. **Move Business Logic**
   - Extract TCA reducers to AppCore
   - Remove all platform conditionals
   - Convert platform types to Data/String

3. **Create Platform Implementations**

### Phase 3: Refactor Views (Week 4)

1. **Create View Protocols**
2. **Implement Platform-Specific Views**
3. **Update Navigation**

### Phase 4: Testing & Validation (Week 5)

1. **Unit Tests for AppCore**
2. **Integration Tests for Platform Modules**
3. **UI Tests for Each Platform**

---

## Key Benefits

### 1. Eliminated Conditionals
- From: 200+ `#if os(iOS)` blocks
- To: 0 conditionals in business logic

### 2. Improved Testability
```swift
// Easy to test with mock implementations
func testDocumentScanning() async {
    let store = TestStore(
        initialState: DocumentScannerFeature.State(),
        reducer: { DocumentScannerFeature() }
    ) {
        $0.documentScanner = MockDocumentScannerClient()
    }
    
    await store.send(.scanButtonTapped)
    // Test works on all platforms!
}
```

### 3. Scalability
- Adding watchOS: Create `AIKOwatchOS` module
- Adding tvOS: Create `AIKOtvOS` module
- No changes to AppCore needed!

### 4. Type Safety
- Platform-specific types never leak into shared code
- Compile-time guarantees of platform compatibility

---

## Implementation Checklist

- [ ] Create AppCore module structure
- [ ] Define dependency protocols
- [ ] Extract DocumentScannerFeature to AppCore
- [ ] Create iOS DocumentScannerClient implementation
- [ ] Create macOS DocumentScannerClient implementation
- [ ] Refactor DocumentScannerView for each platform
- [ ] Update AppFeature to use new architecture
- [ ] Migrate remaining features
- [ ] Update tests
- [ ] Document new architecture

---

## Conclusion

This Triple Architecture approach provides a clean, maintainable solution that:
- Preserves TCA patterns and benefits
- Eliminates platform conditionals from business logic
- Improves testability and modularity
- Enables easy platform expansion
- Reduces cognitive load for developers

The migration effort is significant but will pay dividends in reduced maintenance costs and improved developer experience.