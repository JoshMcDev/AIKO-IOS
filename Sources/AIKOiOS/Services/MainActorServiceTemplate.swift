#if os(iOS)
    import Foundation
    import SwiftUI
    import UIKit

    /// Protocol for services that require MainActor isolation for UI operations
    @MainActor
    public protocol MainActorService: AnyObject, Sendable {
        /// Starts the service if needed
        func start() async throws
    }

    /// Base implementation for MainActor-isolated services with UIKit integration
    @MainActor
    open class MainActorServiceBase: NSObject, MainActorService, Sendable {
        /// UIManager handles all MainActor-isolated UI operations
        @MainActor
        public final class UIManager: ObservableObject {
            private var currentCompletion: ((Any) -> Void)?

            public func setCompletion<T>(_ completion: @escaping (T) -> Void) {
                currentCompletion = { result in
                    if let typedResult = result as? T {
                        completion(typedResult)
                    }
                }
            }

            public func invokeCompletion(with result: some Any) {
                currentCompletion?(result)
                currentCompletion = nil
            }

            public func clearCompletion() {
                currentCompletion = nil
            }

            public func dismissViewController(_ controller: UIViewController, completion: @escaping () -> Void) {
                controller.dismiss(animated: true, completion: completion)
            }

            public func presentViewController(_ controller: UIViewController, from presenter: UIViewController) {
                presenter.present(controller, animated: true)
            }
        }

        @MainActor public let uiManager = UIManager()

        override public init() {
            super.init()
        }

        open func start() async throws {
            // Override in subclasses if needed
        }
    }

    /// Template for services with delegate patterns (like MFMailComposeViewController)
    @MainActor
    open class DelegateServiceTemplate<Result>: MainActorServiceBase {
        /// Runs a presented controller and waits for delegate callback
        public func runPresentedController(
            _ controller: some UIViewController,
            from presenter: UIViewController
        ) async -> Result where Self: NSObjectProtocol {
            await withCheckedContinuation { continuation in
                uiManager.setCompletion { (result: Result) in
                    continuation.resume(returning: result)
                }
                uiManager.presentViewController(controller, from: presenter)
            }
        }

        /// Helper for handling delegate results
        public func handleDelegateResult(_ result: Result) {
            uiManager.invokeCompletion(with: result)
        }

        /// Helper for handling delegate dismissal with result
        public func handleDelegateDismissal(
            _ controller: some UIViewController,
            with result: Result
        ) {
            uiManager.dismissViewController(controller) { [weak self] in
                Task { @MainActor in
                    self?.handleDelegateResult(result)
                }
            }
        }
    }

    /// Template for simple services without complex delegate patterns
    @MainActor
    open class SimpleServiceTemplate: MainActorServiceBase {
        /// Execute a simple MainActor operation
        public func executeMainActorOperation<T>(_ operation: @MainActor @escaping () async throws -> T) async rethrows -> T {
            try await operation()
        }

        /// Execute operation with UI context
        public func executeWithUIContext<T>(
            _ operation: @MainActor @escaping (UIManager) async throws -> T
        ) async rethrows -> T {
            try await operation(uiManager)
        }
    }

    /// Service-Concurrency-Guide.md content as documentation
    public enum MainActorServiceGuidelines {
        /// All UI-presenting services must be @MainActor isolated
        /// Do not store Task references in singletons
        /// Use the template patterns for consistency:
        /// - SimpleServiceTemplate for pure async functions
        /// - DelegateServiceTemplate for UIKit delegate callbacks
        /// - UIManager for all UI operations to maintain isolation
    }
#endif
