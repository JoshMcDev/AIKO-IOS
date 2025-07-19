# AppCore Module

## Overview

AppCore is the platform-agnostic shared business logic layer of the AIKO application. This module contains all TCA reducers, state management, dependency protocols, and business logic that is shared between iOS and macOS platforms.

## Architecture Principles

1. **No Platform-Specific Code**: This module must not contain any platform-specific imports (UIKit, AppKit, VisionKit, etc.)
2. **Protocol-Based Dependencies**: All platform capabilities are defined as protocols
3. **Data Over Types**: Use Foundation types (Data, String) instead of platform types (UIImage, NSImage)
4. **Pure Business Logic**: Contains only business rules, state management, and data transformations

## Structure

- **Dependencies/**: Protocol definitions for platform capabilities
- **Features/**: TCA reducers, states, and actions
- **Models/**: Shared data models and domain entities
- **Views/**: Protocol definitions for views (if needed)

## Usage

```swift
import AppCore
import ComposableArchitecture

// All business logic is platform-agnostic
@Reducer
struct MyFeature {
    @Dependency(\.documentScanner) var scanner
    
    // No #if os(iOS) needed!
}
```

## Testing

All business logic can be tested without platform-specific setup:

```swift
let store = TestStore(
    initialState: MyFeature.State(),
    reducer: { MyFeature() }
) {
    $0.documentScanner = MockDocumentScannerClient()
}
```