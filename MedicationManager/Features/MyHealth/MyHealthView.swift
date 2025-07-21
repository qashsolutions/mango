import SwiftUI

// MARK: - MyHealthView
/// Main health dashboard view for iOS 18+ using modern Swift 6 patterns
/// Uses @State with @Observable ViewModel for optimal performance
struct MyHealthView: View {
    // MARK: - Properties
    // Use @State with @Observable class (iOS 17+ pattern)
    @State private var viewModel = MyHealthViewModel()
    
    // Singletons don't need property wrappers - they manage their own lifecycle
    private let navigationManager = NavigationManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    // UI State - these are value types, so @State is correct
    @State private var showingAddMenu: Bool = false
    @State private var showingLogoutAlert: Bool = false
    @State private var showingVoiceEntry: Bool = false
    @State private var voiceEntryContext: VoiceInteractionContext = .general
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                MyHealthMainContent(
                    viewModel: viewModel,
                    navigationManager: navigationManager
                )
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .navigationTitle(AppStrings.Tabs.myHealth)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .confirmationDialog(AppStrings.MyHealth.addNewItem, isPresented: $showingAddMenu) {
                addMenuButtons
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .debugAlert(showingLogoutAlert: $showingLogoutAlert, firebaseManager: firebaseManager)
        .task(priority: .userInitiated) {
            // Load data when view appears
            // No try-catch needed as ViewModel handles errors internally
            await viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh data when app comes to foreground
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if DEBUG
        ToolbarItem(placement: .navigationBarLeading) {
            debugLogoutButton
        }
        #endif
        
        ToolbarItem(placement: .navigationBarTrailing) {
            toolbarButtons
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
        }
    }
    
    // MARK: - Debug Logout Button
    @ViewBuilder
    private var debugLogoutButton: some View {
        Button(action: { showingLogoutAlert = true }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundStyle(AppTheme.Colors.error)
        }
    }
    
    // MARK: - Toolbar Buttons
    @ViewBuilder
    private var toolbarButtons: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            // Voice Input Button
            VoiceInputButton(context: .general) { voiceText in
                handleVoiceInput(voiceText)
            }
            .scaleEffect(0.85)
            
            SyncActionButton()
            
            Button(action: { showingAddMenu.toggle() }) {
                Image(systemName: AppIcons.plus)
                    .font(AppTheme.Typography.callout)
            }
        }
    }
    
    // MARK: - Add Menu Buttons
    @ViewBuilder
    private var addMenuButtons: some View {
        Button(AppStrings.Medications.addMedication) {
            navigationManager.presentSheet(.addMedication(voiceText: nil))
        }
        
        Button(AppStrings.Supplements.addSupplement) {
            navigationManager.presentSheet(.addSupplement(voiceText: nil))
        }
        
        Button(AppStrings.Diet.addDietEntry) {
            navigationManager.presentSheet(.addDietEntry(voiceText: nil))
        }
        
        Button(AppStrings.Common.cancel, role: .cancel) {}
    }
}

// MARK: - Debug Alert Modifier
extension View {
    @ViewBuilder
    func debugAlert(showingLogoutAlert: Binding<Bool>, firebaseManager: FirebaseManager) -> some View {
        #if DEBUG
        self.alert("Sign Out", isPresented: showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    do {
                        try await firebaseManager.signOut()
                    } catch {
                        // Error is handled by FirebaseManager
                        print("Sign out failed: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        #else
        self
        #endif
    }
}

// MARK: - Voice Input Handling
extension MyHealthView {
    private func handleVoiceInput(_ text: String) {
        let keywords = text.lowercased()
        
        // Enhanced keyword matching for elderly users - more forgiving and comprehensive
        let medicationKeywords = ["medication", "medicine", "pill", "drug", "take", "dose", "tablet", "capsule", "prescription"]
        let supplementKeywords = ["supplement", "vitamin", "nutrient", "minerals", "omega", "calcium", "d3", "b12"]
        let foodKeywords = ["meal", "food", "eat", "diet", "breakfast", "lunch", "dinner", "snack", "hungry", "nutrition"]
        let conflictKeywords = ["conflict", "interaction", "warning", "safe", "together", "mix", "combine"]
        
        // Parse voice input to determine action with better keyword matching
        switch true {
        case medicationKeywords.contains(where: keywords.contains):
            navigationManager.presentSheet(.addMedication(voiceText: text))
        case supplementKeywords.contains(where: keywords.contains):
            navigationManager.presentSheet(.addSupplement(voiceText: text))
        case foodKeywords.contains(where: keywords.contains):
            navigationManager.presentSheet(.addDietEntry(voiceText: text))
        case conflictKeywords.contains(where: keywords.contains):
            navigationManager.selectTab(.conflicts)
        default:
            // Default to medication (most common for elderly users)
            navigationManager.presentSheet(.addMedication(voiceText: text))
        }
        
        // Track voice usage for analytics
        Task {
            await viewModel.performVoiceEntry()
        }
    }
}

#Preview {
    MyHealthView()
}