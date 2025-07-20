# iOS MainActor Service Patterns - Concurrency Guide

## Overview
This guide documents the standardized patterns for iOS services under Swift 6 concurrency.

## Core Rules

1. **All UI-presenting services must be @MainActor isolated**
2. **Do not store Task references in singletons**
3. **Use the template patterns for consistency**

## Templates

### SimpleServiceTemplate
For services with pure async functions (no UIKit delegates):

```swift
class MyAccessibilityService: SimpleServiceTemplate {
    func announceMessage(_ message: String) async {
        await executeMainActorOperation {
            // UI operations here
        }
    }
}
```

### DelegateServiceTemplate
For services with UIKit delegate callbacks:

```swift
class MyEmailService: DelegateServiceTemplate<EmailResult>, EmailServiceProtocol {
    // Use handleDelegateDismissal for delegate callbacks
    func mailComposeController(_ controller: MFMailComposeViewController, 
                              didFinishWith result: MFMailComposeResult, 
                              error: Error?) {
        Task { @MainActor in
            let emailResult = convertToEmailResult(result, error)
            self.handleDelegateDismissal(controller, with: emailResult)
        }
    }
}
```

## Key Patterns

### UIManager Usage
- All templates include a MainActor-isolated UIManager
- Use `uiManager.setCompletion()` for async results
- Use `uiManager.presentViewController()` for UI presentation

### Delegate Bridge Pattern
```swift
// In delegate method:
nonisolated func delegateMethod(_ controller: UIViewController) {
    Task { @MainActor in
        self.handleDelegateDismissal(controller, with: result)
    }
}
```

### Continuation Pattern
```swift
// For async/await integration:
func presentController() async -> Result {
    return await withCheckedContinuation { continuation in
        Task { @MainActor in
            self.uiManager.setCompletion { result in
                continuation.resume(returning: result)
            }
            // Present controller
        }
    }
}
```

## Examples

- **VisionKitAdapter**: Document scanning with delegate pattern
- **iOSEmailService**: Mail composition with MFMailComposeViewController
- **iOSAccessibilityServiceClient**: Simple async wrapper

## Error Handling

- Always handle MainActor isolation violations
- Use `handleDelegateDismissal` for clean delegate dismissal
- Wrap delegate callbacks in `Task { @MainActor }`

## Testing

Each pattern requires unit tests verifying MainActor context:

```swift
func testMainActorIsolation() async {
    let service = MyService()
    await MainActor.run {
        // Verify service operates on MainActor
        XCTAssertTrue(Thread.isMainThread)
    }
}
```