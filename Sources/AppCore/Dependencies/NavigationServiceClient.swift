import ComposableArchitecture
import Foundation
import SwiftUI

@DependencyClient
public struct NavigationServiceClient: Sendable {
    public var supportsNavigationStack: @Sendable () -> Bool = { false }
    public var defaultNavigationStyle: @Sendable () -> NavigationStyle = { .automatic }
    public var supportsNavigationBarDisplayMode: @Sendable () -> Bool = { false }
}

extension NavigationServiceClient: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        supportsNavigationStack: { true },
        defaultNavigationStyle: { .stack },
        supportsNavigationBarDisplayMode: { true }
    )
}

extension DependencyValues {
    public var navigationService: NavigationServiceClient {
        get { self[NavigationServiceClient.self] }
        set { self[NavigationServiceClient.self] = newValue }
    }
}