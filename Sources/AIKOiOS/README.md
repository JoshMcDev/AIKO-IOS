# AIKOiOS Module

## Overview

AIKOiOS provides iOS-specific implementations of the protocols defined in AppCore. This module bridges iOS frameworks (UIKit, VisionKit, etc.) with the platform-agnostic business logic.

## Architecture Principles

1. **Implements AppCore Protocols**: Provides concrete iOS implementations
2. **iOS Frameworks Only**: Can freely use UIKit, VisionKit, and other iOS-specific frameworks
3. **No Business Logic**: Business logic belongs in AppCore
4. **SwiftUI Views**: iOS-specific UI implementations

## Structure

- **Dependencies/**: iOS implementations of AppCore dependency protocols
- **Views/**: iOS-specific SwiftUI views
- **UIComponents/**: UIViewRepresentable wrappers and iOS-specific UI components

## Example Implementation

```swift
import AppCore
import VisionKit
import UIKit

// iOS-specific implementation
struct iOSDocumentScannerClient: DocumentScannerClient {
    func scan() async throws -> ScannedDocument {
        // Use VisionKit here
        let scanner = VNDocumentCameraViewController()
        // ... iOS-specific implementation
    }
}
```

## Registration

Implementations are registered via dependency injection:

```swift
extension DocumentScannerClientKey {
    static let liveValue: any DocumentScannerClient = iOSDocumentScannerClient()
}
```