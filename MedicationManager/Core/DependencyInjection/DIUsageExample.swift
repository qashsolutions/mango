import SwiftUI
import Observation

/// Example view showing how to use dependency injection
/// Swift 6 compliant - Uses standard @EnvironmentObject pattern
struct DIExampleView: View {
    // MARK: - Environment Dependencies
    
    @EnvironmentObject private var diContainer: DIContainer
    
    // MARK: - View State
    
    @State private var isLoading = false
    @State private var medications: [MedicationModel] = []
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Text(AppStrings.Medications.medications)
                .font(AppTheme.Typography.largeTitle)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                List(medications) { medication in
                    MedicationCard(medication: medication) {
                        // Using injected navigation manager
                        diContainer.navigationManager.navigate(to: .medicationDetail(id: medication.id))
                    }
                }
            }
            
            Button(action: {
                Task {
                    await loadMedications()
                }
            }) {
                Text(AppStrings.Common.refresh)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.onPrimary)
                    .padding()
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        .padding()
        .task {
            await loadMedications()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadMedications() async {
        isLoading = true
        defer { isLoading = false }
        
        // Using injected dependencies
        guard let userId = diContainer.authManager.currentUser?.id else {
            diContainer.analyticsManager.trackError(
                AppError.authentication(.notAuthenticated),
                context: "DIExampleView.loadMedications"
            )
            return
        }
        
        do {
            // Using injected core data manager
            medications = try await diContainer.coreDataManager.fetchMedications(for: userId)
            
            // Using injected analytics
            diContainer.analyticsManager.trackEvent(
                "medications_loaded",
                parameters: ["count": medications.count]
            )
        } catch {
            // Using injected analytics for error tracking
            diContainer.analyticsManager.trackError(error, context: "DIExampleView.loadMedications")
        }
    }
}

/// Example of creating a view model with dependencies
struct DIViewModelExampleView: View {
    @EnvironmentObject private var diContainer: DIContainer
    @State private var viewModel: ExampleViewModel
    
    init() {
        // This is a workaround since we can't access @Environment in init
        // In a real app, the view model would be created by the parent view
        _viewModel = State(wrappedValue: ExampleViewModel())
    }
    
    var body: some View {
        VStack {
            Text("Example with ViewModel")
                .font(AppTheme.Typography.title)
            
            // View content using viewModel
        }
        .onAppear {
            // Pass dependencies to view model after view appears
            viewModel.configure(with: diContainer)
        }
    }
}

/// Example view model that accepts dependencies
@MainActor
@Observable
class ExampleViewModel {
    var data: [String] = []
    
    private var authManager: AuthenticationManagerProtocol?
    private var analyticsManager: AnalyticsManagerProtocol?
    
    func configure(with container: DIContainer) {
        self.authManager = container.authManager
        self.analyticsManager = container.analyticsManager
        
        // Now the view model can use injected dependenciesz
        loadData()
    }
    
    private func loadData() {
        guard authManager?.currentUser?.id != nil else {
            analyticsManager?.trackError(
                AppError.authentication(.notAuthenticated),
                context: "ExampleViewModel"
            )
            return
        }
        
        // Load data using dependencies
        analyticsManager?.trackScreenViewed("example_screen")
    }
}

// MARK: - Testing Example

#if DEBUG
struct DITestingExampleView: View {
    // Create a mock container for testing
    // In a real app, you would create mock implementations and inject them
    @StateObject private var mockContainer = DIContainer()
    
    var body: some View {
        DIExampleView()
            .withDependencies(mockContainer)
    }
}

// Disabled: These previews cause crashes because DIExampleView accesses
// @Environment(\.diContainer) before it's injected
/*
#Preview("DI Example - Production") {
    DIExampleView()
        .withDependencies(DIContainer())
}

#Preview("DI Example - Mock") {
    DITestingExampleView()
}
*/
#endif

// MARK: - Usage Guidelines

/*
 Dependency Injection Usage Guidelines:
 
 1. Access the container from environment:
    @EnvironmentObject private var diContainer: DIContainer
 
 2. Use injected dependencies instead of singletons:
    // ❌ Wrong
    FirebaseManager.shared.currentUser
    
    // ✅ Correct
    diContainer.authManager.currentUser
 
 3. For ViewModels, pass dependencies in init or configure method:
    @Observable class MyViewModel {
        private let authManager: AuthenticationManagerProtocol
        
        init(authManager: AuthenticationManagerProtocol) {
            self.authManager = authManager
        }
    }
 
 4. For testing, use mock implementations:
    let mockContainer = DIContainer(
        authManager: MockAuthManager(),
        navigationManager: MockNavigationManager(),
        // ... other mock dependencies
    )
    MyView().withDependencies(mockContainer)
 
 5. Benefits:
    - Easier testing with mock implementations
    - Clear dependencies for each component
    - No hidden singleton dependencies
    - Better separation of concerns
    - Ability to swap implementations
 */
