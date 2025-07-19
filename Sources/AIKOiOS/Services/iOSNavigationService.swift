import Foundation
import SwiftUI
import AppCore

/// iOS implementation of NavigationServiceProtocol
public final class iOSNavigationService: NavigationServiceProtocol {
    public init() {}
    
    public var supportsNavigationStack: Bool {
        if #available(iOS 16.0, *) {
            return true
        } else {
            return false
        }
    }
    
    public var defaultNavigationStyle: NavigationStyle {
        .stack
    }
    
    public var supportsNavigationBarDisplayMode: Bool {
        true
    }
}