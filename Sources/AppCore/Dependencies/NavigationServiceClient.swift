import Foundation
import SwiftUI

public struct NavigationServiceClient: Sendable {
    public var supportsNavigationStack: @Sendable () -> Bool = { false }
    public var defaultNavigationStyle: @Sendable () -> NavigationStyle = { .automatic }
    public var supportsNavigationBarDisplayMode: @Sendable () -> Bool = { false }

    public init(
        supportsNavigationStack: @escaping @Sendable () -> Bool = { false },
        defaultNavigationStyle: @escaping @Sendable () -> NavigationStyle = { .automatic },
        supportsNavigationBarDisplayMode: @escaping @Sendable () -> Bool = { false }
    ) {
        self.supportsNavigationStack = supportsNavigationStack
        self.defaultNavigationStyle = defaultNavigationStyle
        self.supportsNavigationBarDisplayMode = supportsNavigationBarDisplayMode
    }
}

extension NavigationServiceClient {
    public static let testValue = Self()
    public static let previewValue = Self(
        supportsNavigationStack: { true },
        defaultNavigationStyle: { .stack },
        supportsNavigationBarDisplayMode: { true }
    )
}
