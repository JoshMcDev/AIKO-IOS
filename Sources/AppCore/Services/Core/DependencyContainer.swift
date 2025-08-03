import Foundation
import Combine

// MARK: - DependencyContainer - Platform-Agnostic Dependency Injection

/// Unified dependency injection container that eliminates iOS/macOS service duplication
/// Provides platform-agnostic registration and resolution of services
public final class DependencyContainer: @unchecked Sendable {

    // MARK: - Singleton Access

    /// Shared container instance
    public static let shared = DependencyContainer()

    // MARK: - Properties

    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private let lock = NSRecursiveLock()

    // MARK: - Initialization

    private init() {
        registerPlatformServices()
    }

    // MARK: - Service Registration

    /// Register a singleton service instance
    /// - Parameters:
    ///   - type: Service protocol type
    ///   - instance: Service implementation instance
    public func register<T>(_ type: T.Type, instance: T) {
        lock.withLock {
            let key = String(describing: type)
            singletons[key] = instance
        }
    }

    /// Register a service factory for lazy instantiation
    /// - Parameters:
    ///   - type: Service protocol type
    ///   - factory: Factory closure that creates service instance
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.withLock {
            let key = String(describing: type)
            factories[key] = factory
        }
    }

    /// Register a service factory with dependency injection
    /// - Parameters:
    ///   - type: Service protocol type
    ///   - factory: Factory closure with container access for dependencies
    public func register<T>(_ type: T.Type, factory: @escaping (DependencyContainer) -> T) {
        lock.withLock {
            let key = String(describing: type)
            factories[key] = { [weak self] in
                guard let self = self else {
                    fatalError("DependencyContainer deallocated during factory execution")
                }
                return factory(self)
            }
        }
    }

    // MARK: - Service Resolution

    /// Resolve a service instance
    /// - Parameter type: Service protocol type to resolve
    /// - Returns: Service implementation instance
    /// - Throws: DependencyError if service not registered
    public func resolve<T>(_ type: T.Type) throws -> T {
        try lock.withLock {
            let key = String(describing: type)

            // Check singletons first
            if let singleton = singletons[key] as? T {
                return singleton
            }

            // Check cached services
            if let service = services[key] as? T {
                return service
            }

            // Create from factory
            if let factory = factories[key] {
                let instance = factory()
                guard let typedInstance = instance as? T else {
                    throw DependencyError.typeMismatch(expected: String(describing: type), actual: String(describing: Swift.type(of: instance)))
                }

                // Cache the instance
                services[key] = typedInstance
                return typedInstance
            }

            throw DependencyError.serviceNotRegistered(String(describing: type))
        }
    }

    /// Resolve an optional service instance
    /// - Parameter type: Service protocol type to resolve
    /// - Returns: Service implementation instance or nil if not registered
    public func resolveOptional<T>(_ type: T.Type) -> T? {
        return try? resolve(type)
    }

    /// Check if a service is registered
    /// - Parameter type: Service protocol type to check
    /// - Returns: True if service is registered
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.withLock {
            let key = String(describing: type)
            return singletons[key] != nil || services[key] != nil || factories[key] != nil
        }
    }

    // MARK: - Container Management

    /// Clear all registered services and factories
    public func clear() {
        lock.withLock {
            services.removeAll()
            factories.removeAll()
            singletons.removeAll()
        }
    }

    /// Remove a specific service registration
    /// - Parameter type: Service protocol type to remove
    public func remove<T>(_ type: T.Type) {
        lock.withLock {
            let key = String(describing: type)
            services.removeValue(forKey: key)
            factories.removeValue(forKey: key)
            singletons.removeValue(forKey: key)
        }
    }

    /// Get all registered service types
    /// - Returns: Array of registered service type names
    public func registeredServices() -> [String] {
        lock.withLock {
            let allKeys = Set(services.keys).union(Set(factories.keys)).union(Set(singletons.keys))
            return Array(allKeys).sorted()
        }
    }
}

// MARK: - Platform Service Registration

private extension DependencyContainer {

    /// Register platform-specific service implementations
    func registerPlatformServices() {
        // TODO: Register clipboard service with platform-specific implementation
        // #if os(iOS)
        // register(ClipboardServiceProtocol.self) { _ in
        //     IOSClipboardService()
        // }
        // #elseif os(macOS)
        // register(ClipboardServiceProtocol.self) { _ in
        //     MacOSClipboardService()
        // }
        // #endif

        // TODO: Register document manager with platform-specific implementation
        // #if os(iOS)
        // register(DocumentManagerProtocol.self) { container in
        //     IOSDocumentManager(
        //         networkService: try! container.resolve(NetworkServiceProtocol.self)
        //     )
        // }
        // #elseif os(macOS)
        // register(DocumentManagerProtocol.self) { container in
        //     MacOSDocumentManager(
        //         networkService: try! container.resolve(NetworkServiceProtocol.self)
        //     )
        // }
        // #endif

        // TODO: Register network service singleton
        // register(NetworkServiceProtocol.self, instance: NetworkService.shared)

        // TODO: Register SAM.gov service
        // register(SAMGovServiceProtocol.self, instance: SAMGovService.live)

        // Register feature flags service singleton
        register(FeatureFlagsServiceProtocol.self) { _ in
            FeatureFlags.shared
        }
    }
}

// MARK: - Convenience Extensions

public extension DependencyContainer {

    /// Property wrapper for automatic dependency injection
    @propertyWrapper
    struct Injected<T> {
        private let keyPath: KeyPath<DependencyContainer, T>?
        private let type: T.Type

        public var wrappedValue: T {
            do {
                return try DependencyContainer.shared.resolve(type)
            } catch {
                fatalError("Failed to resolve dependency \(type): \(error)")
            }
        }

        public init(_ type: T.Type) {
            self.type = type
            self.keyPath = nil
        }
    }

    /// Property wrapper for optional dependency injection
    @propertyWrapper
    struct OptionalInjected<T> {
        private let type: T.Type

        public var wrappedValue: T? {
            return DependencyContainer.shared.resolveOptional(type)
        }

        public init(_ type: T.Type) {
            self.type = type
        }
    }
}

// MARK: - Service Protocol Definitions

// TODO: Protocol for network service to enable dependency injection
// public protocol NetworkServiceProtocol: Sendable {
//     func downloadData(from url: URL) async throws -> Data
//     func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T
//     func post(_ body: some Encodable, to url: URL) async throws -> Data
//     func post<R: Decodable>(_ body: some Encodable, to url: URL, responseType: R.Type) async throws -> R
// }

// TODO: Protocol for SAM.gov service dependency injection
// public protocol SAMGovServiceProtocol: Sendable {
//     var searchEntity: @Sendable (String) async throws -> EntitySearchResult { get }
//     var getEntityByCAGE: @Sendable (String) async throws -> EntityDetail { get }
//     var getEntityByUEI: @Sendable (String) async throws -> EntityDetail { get }
// }

/// Protocol for feature flags service dependency injection
public protocol FeatureFlagsServiceProtocol: Sendable {
    func isEnabled(_ feature: Feature, userId: String) async -> Bool
    func setRolloutPercentage(feature: Feature, percentage: Int) async
    func logFeatureUsage(_ feature: Feature, userId: String, action: FeatureFlagAction) async
    func canaryRollout(feature: Feature, percentage: Int) async throws
    func isFeatureEnabledForUser(_ feature: Feature, userId: String) async -> Bool
    func emergencyRollback(features: [Feature]) async
    func rollbackToKnownGoodState() async
    func resetToDefaults() async
    func getUsageMetrics() async -> FeatureFlagMetrics
    func getAuditLog() async -> [FeatureFlagAuditEntry]
}

// MARK: - Error Types

/// Dependency injection errors
public enum DependencyError: Error, LocalizedError, Sendable {
    case serviceNotRegistered(String)
    case typeMismatch(expected: String, actual: String)
    case circularDependency(String)
    case containerNotInitialized

    public var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let service):
            return "Service not registered: \(service)"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch - expected: \(expected), actual: \(actual)"
        case .circularDependency(let service):
            return "Circular dependency detected for service: \(service)"
        case .containerNotInitialized:
            return "Dependency container not initialized"
        }
    }
}

// MARK: - Thread Safety Extension

extension NSRecursiveLock {
    /// Execute closure with lock protection
    /// - Parameter closure: Closure to execute
    /// - Returns: Result of closure execution
    func withLock<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
}

// MARK: - Service Conformance Extensions

// TODO: NetworkService conformance to protocol for dependency injection
// extension NetworkService: NetworkServiceProtocol {}

// TODO: SAMGovService conformance to protocol for dependency injection
// extension SAMGovService: SAMGovServiceProtocol {}

/// FeatureFlags conformance to protocol for dependency injection
extension FeatureFlags: FeatureFlagsServiceProtocol {}
