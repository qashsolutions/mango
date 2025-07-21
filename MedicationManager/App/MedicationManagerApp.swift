import SwiftUI
import Firebase

@main
struct MedicationManagerApp: App {
    @State private var firebaseManager = FirebaseManager.shared
    
    init() {
        // Configure Firebase before any Firebase services are used
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if firebaseManager.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .onAppear {
                // FirebaseManager automatically handles auth state
            }
        }
    }
}
