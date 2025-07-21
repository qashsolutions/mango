import SwiftUI
import SwiftData

// MARK: - SwiftData View Extensions
/// iOS 18+ SwiftUI extensions for SwiftData integration
extension View {
    
    /// Inject SwiftData model context into the view hierarchy
    /// Use this on root views that need SwiftData access
    func withSwiftDataContext() -> some View {
        if let context = SwiftDataConfiguration.shared.mainContext {
            return AnyView(self.modelContext(context))
        } else {
            // Return the view without SwiftData context if not available
            // The app will still function with fallback storage
            return AnyView(self)
        }
    }
    
    /// Initialize SwiftData and inject context
    /// Use this on the app's root view
    func setupSwiftData() -> some View {
        SwiftDataConfiguration.initialize()
        return self.withSwiftDataContext()
    }
}