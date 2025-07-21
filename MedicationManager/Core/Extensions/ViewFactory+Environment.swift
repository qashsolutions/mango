import SwiftUI

// MARK: - ViewFactory Environment Key
/// Environment key for injecting ViewFactory throughout the view hierarchy
private struct ViewFactoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: ViewFactoryProtocol = AppViewFactory()
}

// MARK: - Environment Values Extension
extension EnvironmentValues {
    /// Access to the ViewFactory instance from the environment
    var viewFactory: ViewFactoryProtocol {
        get { self[ViewFactoryKey.self] }
        set { self[ViewFactoryKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    /// Injects a ViewFactory instance into the environment
    /// - Parameter factory: The ViewFactory to inject (defaults to AppViewFactory)
    /// - Returns: A view with the ViewFactory available in the environment
    func withViewFactory(_ factory: ViewFactoryProtocol = AppViewFactory()) -> some View {
        environment(\.viewFactory, factory)
    }
}