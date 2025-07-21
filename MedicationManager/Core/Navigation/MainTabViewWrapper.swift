import SwiftUI
import SwiftData

// MARK: - Main Tab View Wrapper
/// Wrapper view that initializes SwiftData before presenting MainTabView
/// This ensures SwiftData is available throughout the authenticated app experience
struct MainTabViewWrapper: View {
    let viewFactory: ViewFactoryProtocol
    @State private var firebaseManager = FirebaseManager.shared
    
    // Add convenience initializer for backward compatibility
    init(viewFactory: ViewFactoryProtocol = AppViewFactory()) {
        self.viewFactory = viewFactory
    }
    
    var body: some View {
        MainTabView(viewFactory: viewFactory)
            .setupSwiftData() // Initialize SwiftData and inject context
            .onAppear {
                // Migrate legacy data if needed
                if let userId = firebaseManager.currentUser?.id {
                    Task {
                        await SwiftDataConfiguration.shared.migrateIfNeeded(for: userId)
                    }
                }
            }
    }
}