import SwiftUI

/// Protocol that defines the interface for creating views in the application.
/// This abstraction allows the Core layer to remain independent of the Features layer
/// by delegating view creation to concrete implementations.
@MainActor
protocol ViewFactoryProtocol {
    /// Creates the appropriate tab view for the given tab
    /// - Parameter tab: The main tab to create a view for
    /// - Returns: The view wrapped in AnyView for type erasure
    func createTabView(for tab: MainTab) -> AnyView
    
    /// Creates the appropriate detail view for the given navigation destination
    /// - Parameter destination: The navigation destination
    /// - Returns: The view wrapped in AnyView for type erasure
    func createDetailView(for destination: NavigationDestination) -> AnyView
    
    /// Creates the appropriate sheet view for the given sheet destination
    /// - Parameter sheet: The sheet destination
    /// - Returns: The view wrapped in AnyView for type erasure
    func createSheetView(for sheet: SheetDestination) -> AnyView
    
    /// Creates the appropriate full screen cover view for the given destination
    /// - Parameter cover: The full screen cover destination
    /// - Returns: The view wrapped in AnyView for type erasure
    func createFullScreenView(for cover: FullScreenDestination) -> AnyView
}