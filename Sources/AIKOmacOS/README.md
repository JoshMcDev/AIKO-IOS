# AIKOmacOS Module

## Overview

AIKOmacOS provides macOS-specific implementations of the protocols defined in AppCore. This module bridges macOS frameworks (AppKit, ImageCaptureCore, etc.) with the platform-agnostic business logic.

## Architecture Principles

1. **Implements AppCore Protocols**: Provides concrete macOS implementations
2. **macOS Frameworks Only**: Can freely use AppKit and other macOS-specific frameworks
3. **No Business Logic**: Business logic belongs in AppCore
4. **SwiftUI Views**: macOS-specific UI implementations with AppKit styling

## Structure

- **Dependencies/**: macOS implementations of AppCore dependency protocols
- **Views/**: macOS-specific SwiftUI views
- **UIComponents/**: NSViewRepresentable wrappers and macOS-specific UI components

## Example Implementation

```swift
import AppCore
import AppKit
import ImageCaptureCore

// macOS-specific implementation
struct macOSDocumentScannerClient: DocumentScannerClient {
    func scan() async throws -> ScannedDocument {
        // Use NSOpenPanel for file selection
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        // ... macOS-specific implementation
    }
}
```

## Registration

Implementations are registered via dependency injection:

```swift
extension DocumentScannerClientKey {
    static let liveValue: any DocumentScannerClient = macOSDocumentScannerClient()
}
```