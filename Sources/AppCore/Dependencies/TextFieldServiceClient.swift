import ComposableArchitecture
import Foundation

/// Dependency client for text field configuration
@DependencyClient
public struct TextFieldServiceClient: Sendable {
    public var supportsAutocapitalization: @Sendable () -> Bool = { false }
    public var supportsKeyboardTypes: @Sendable () -> Bool = { false }
}

extension TextFieldServiceClient: TestDependencyKey {
    public static let testValue = Self()
}

public extension DependencyValues {
    var textFieldService: TextFieldServiceClient {
        get { self[TextFieldServiceClient.self] }
        set { self[TextFieldServiceClient.self] = newValue }
    }
}
