import SwiftUI
import Firebase

@main
struct MedicationManagerApp: App {
    @State private var firebaseManager = FirebaseManager.shared
    
    init() {
        // Firebase is configured in FirebaseManager
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
