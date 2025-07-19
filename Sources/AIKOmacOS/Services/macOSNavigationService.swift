#if os(macOS)
import Foundation
import SwiftUI
import AppCore

/// macOS implementation of NavigationServiceProtocol
public final class macOSNavigationService: NavigationServiceProtocol {
    public init() {}
    
    public var supportsNavigationStack: Bool {
        // macOS doesn't support NavigationStack
        false
    }
    
    public var defaultNavigationStyle: NavigationStyle {
        .column
    }
    
    public var supportsNavigationBarDisplayMode: Bool {
        false
    }
}#endif
