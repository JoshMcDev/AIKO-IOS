#if os(macOS)
import AppCore
import AppKit

/// macOS implementation of keyboard service
/// Note: macOS doesn't have keyboard types like iOS, so this is a placeholder implementation
public final class macOSKeyboardService: KeyboardServiceProtocol, @unchecked Sendable {
    public typealias KeyboardType = String
    
    public var defaultKeyboardType: String {
        "default"
    }
    
    public var emailKeyboardType: String {
        "email"
    }
    
    public var numberKeyboardType: String {
        "number"
    }
    
    public var phoneKeyboardType: String {
        "phone"
    }
    
    public var urlKeyboardType: String {
        "url"
    }
    
    public var supportsKeyboardTypes: Bool {
        false // macOS doesn't support keyboard types
    }
    
    public init() {}
}#endif
