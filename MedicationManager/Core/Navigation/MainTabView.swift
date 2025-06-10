import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var authManager = FirebaseManager.shared
    @StateObject private var dataSync = DataSyncManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            MyHealthTabView()
                .tabItem {
                    Label(
                        MainTab.myHealth.displayName,
                        systemImage: navigationManager.selectedTab == .myHealth ? 
                            MainTab.myHealth.selectedIcon : MainTab.myHealth.icon
                    )
                }
                .tag(MainTab.myHealth)
            
            DoctorListTabView()
                .tabItem {
                    Label(
                        MainTab.doctorList.displayName,
                        systemImage: navigationManager.selectedTab == .doctorList ? 
                            MainTab.doctorList.selectedIcon : MainTab.doctorList.icon
                    )
                }
                .tag(MainTab.doctorList)
            
            GroupsTabView()
                .tabItem {
                    Label(
                        MainTab.groups.displayName,
                        systemImage: navigationManager.selectedTab == .groups ? 
                            MainTab.groups.selectedIcon : MainTab.groups.icon
                    )
                }
                .tag(MainTab.groups)
            
            ConflictsTabView()
                .tabItem {
                    Label(
                        MainTab.conflicts.displayName,
                        systemImage: navigationManager.selectedTab == .conflicts ? 
                            MainTab.conflicts.selectedIcon : MainTab.conflicts.icon
                    )
                }
                .tag(MainTab.conflicts)
        }
        .accentColor(AppTheme.Colors.primary)
        .sheet(item: $navigationManager.presentedSheet) { destination in
            NavigationSheetView(destination: destination)
        }
        .fullScreenCover(item: $navigationManager.presentedFullScreenCover) { destination in
            FullScreenCoverView(destination: destination)
        }
        .alert(item: $navigationManager.showingAlert) { alertItem in
            createAlert(from: alertItem)
        }
        .onChange(of: navigationManager.selectedTab) { _, newTab in
            navigationManager.selectTab(newTab)
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onOpenURL { url in
            navigationManager.handleDeepLink(url)
        }
        .task {
            await initializeApp()
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func MyHealthTabView() -> some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            MyHealthView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    NavigationDestinationView(destination: destination)
                }
        }
    }
    
    @ViewBuilder
    private func DoctorListTabView() -> some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            DoctorListView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    NavigationDestinationView(destination: destination)
                }
        }
    }
    
    @ViewBuilder
    private func GroupsTabView() -> some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            GroupsView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    NavigationDestinationView(destination: destination)
                }
        }
    }
    
    @ViewBuilder
    private func ConflictsTabView() -> some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            ConflictsView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    NavigationDestinationView(destination: destination)
                }
        }
    }
    
    // MARK: - Helper Methods
    private func createAlert(from alertItem: AlertItem) -> Alert {
        if let secondaryButton = alertItem.secondaryButton {
            return Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                primaryButton: .default(Text(alertItem.primaryButton?.title ?? AppStrings.Common.ok)) {
                    alertItem.primaryButton?.action()
                },
                secondaryButton: .cancel(Text(secondaryButton.title)) {
                    secondaryButton.action()
                }
            )
        } else {
            return Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text(alertItem.primaryButton?.title ?? AppStrings.Common.ok)) {
                    alertItem.primaryButton?.action()
                }
            )
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            Task {
                if authManager.isAuthenticated {
                    await dataSync.syncPendingChanges()
                }
            }
        case .background:
            // Save any pending data
            break
        case .inactive:
            break
        @unknown default:
            break
        }
    }
    
    private func initializeApp() async {
        // Track app launch
        let startTime = Date()
        
        // Initialize managers if needed
        if authManager.isAuthenticated {
            await dataSync.syncPendingChanges()
        }
        
        let launchTime = Date().timeIntervalSince(startTime)
        AnalyticsManager.shared.trackAppLaunchTime(launchTime)
    }
}

// MARK: - Navigation Destination View
struct NavigationDestinationView: View {
    let destination: NavigationDestination
    
    var body: some View {
        switch destination {
        case .medicationDetail(let id):
            MedicationDetailView(medicationId: id)
            
        case .supplementDetail(let id):
            SupplementDetailView(supplementId: id)
            
        case .dietEntryDetail(let id):
            DietEntryDetailView(entryId: id)
            
        case .doctorDetail(let id):
            DoctorDetailView(doctorId: id)
            
        case .conflictDetail(let id):
            ConflictDetailView(conflictId: id)
            
        case .caregiverSettings:
            CaregiverSettingsView()
            
        case .userProfile:
            UserProfileView()
            
        case .appSettings:
            AppSettingsView()
            
        case .privacySettings:
            PrivacySettingsView()
            
        case .notificationSettings:
            NotificationSettingsView()
            
        case .syncSettings:
            SyncSettingsView()
            
        case .aboutApp:
            AboutAppView()
        }
    }
}

// MARK: - Navigation Sheet View
struct NavigationSheetView: View {
    let destination: SheetDestination
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            switch destination {
            case .addMedication(let voiceText):
                AddMedicationView(initialVoiceText: voiceText)
                
            case .editMedication(let id):
                EditMedicationView(medicationId: id)
                
            case .addSupplement(let voiceText):
                AddSupplementView(initialVoiceText: voiceText)
                
            case .editSupplement(let id):
                EditSupplementView(supplementId: id)
                
            case .addDietEntry(let voiceText):
                AddDietEntryView(initialVoiceText: voiceText)
                
            case .editDietEntry(let id):
                EditDietEntryView(entryId: id)
                
            case .addDoctor(let contact):
                AddDoctorView(initialContact: contact)
                
            case .editDoctor(let id):
                EditDoctorView(doctorId: id)
                
            case .caregiverInvitation(let code):
                CaregiverInvitationView(invitationCode: code)
                
            case .inviteCaregiver:
                InviteCaregiverView()
                
            case .voiceInput(let context):
                VoiceInputView(context: context)
                
            case .medicationConflictCheck:
                ConflictCheckView()
                
            case .userProfileEdit:
                EditUserProfileView()
            }
        }
        .interactiveDismissDisabled(false)
    }
}

// MARK: - Full Screen Cover View
struct FullScreenCoverView: View {
    let destination: FullScreenDestination
    
    var body: some View {
        switch destination {
        case .authentication:
            AuthenticationView()
            
        case .onboarding:
            OnboardingView()
            
        case .caregiverOnboarding:
            CaregiverOnboardingView()
        }
    }
}

// MARK: - Feature Views are now implemented in their respective feature folders

// MARK: - Placeholder Detail Views
struct MedicationDetailView: View {
    let medicationId: String
    
    var body: some View {
        Text("Medication Detail: \(medicationId)")
            .navigationTitle("Medication")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupplementDetailView: View {
    let supplementId: String
    
    var body: some View {
        Text("Supplement Detail: \(supplementId)")
            .navigationTitle("Supplement")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct DietEntryDetailView: View {
    let entryId: String
    
    var body: some View {
        Text("Diet Entry Detail: \(entryId)")
            .navigationTitle("Diet Entry")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct DoctorDetailView: View {
    let doctorId: String
    
    var body: some View {
        Text("Doctor Detail: \(doctorId)")
            .navigationTitle("Doctor")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConflictDetailView: View {
    let conflictId: String
    
    var body: some View {
        Text("Conflict Detail: \(conflictId)")
            .navigationTitle("Conflict")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Placeholder Add/Edit Views
struct AddMedicationView: View {
    let initialVoiceText: String?
    
    var body: some View {
        Text("Add Medication")
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditMedicationView: View {
    let medicationId: String
    
    var body: some View {
        Text("Edit Medication: \(medicationId)")
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddSupplementView: View {
    let initialVoiceText: String?
    
    var body: some View {
        Text("Add Supplement")
            .navigationTitle("Add Supplement")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditSupplementView: View {
    let supplementId: String
    
    var body: some View {
        Text("Edit Supplement: \(supplementId)")
            .navigationTitle("Edit Supplement")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddDietEntryView: View {
    let initialVoiceText: String?
    
    var body: some View {
        Text("Add Diet Entry")
            .navigationTitle("Add Diet Entry")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditDietEntryView: View {
    let entryId: String
    
    var body: some View {
        Text("Edit Diet Entry: \(entryId)")
            .navigationTitle("Edit Diet Entry")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddDoctorView: View {
    let initialContact: Contact?
    
    var body: some View {
        Text("Add Doctor")
            .navigationTitle("Add Doctor")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditDoctorView: View {
    let doctorId: String
    
    var body: some View {
        Text("Edit Doctor: \(doctorId)")
            .navigationTitle("Edit Doctor")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Placeholder Settings Views
struct CaregiverSettingsView: View {
    var body: some View {
        Text("Caregiver Settings")
            .navigationTitle("Caregiver Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct UserProfileView: View {
    var body: some View {
        Text("User Profile")
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppSettingsView: View {
    var body: some View {
        Text("App Settings")
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct SyncSettingsView: View {
    var body: some View {
        Text("Sync Settings")
            .navigationTitle("Sync")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutAppView: View {
    var body: some View {
        Text("About App")
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Placeholder Additional Views
struct CaregiverInvitationView: View {
    let invitationCode: String
    
    var body: some View {
        Text("Caregiver Invitation: \(invitationCode)")
            .navigationTitle("Invitation")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct InviteCaregiverView: View {
    var body: some View {
        Text("Invite Caregiver")
            .navigationTitle("Invite Caregiver")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct VoiceInputView: View {
    let context: VoiceInputContext
    
    var body: some View {
        Text("Voice Input: \(context.promptText)")
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConflictCheckView: View {
    var body: some View {
        Text("Conflict Check")
            .navigationTitle("Check Conflicts")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditUserProfileView: View {
    var body: some View {
        Text("Edit User Profile")
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AuthenticationView: View {
    var body: some View {
        Text("Authentication")
    }
}

struct OnboardingView: View {
    var body: some View {
        Text("Onboarding")
    }
}

struct CaregiverOnboardingView: View {
    var body: some View {
        Text("Caregiver Onboarding")
    }
}

#Preview {
    MainTabView()
}