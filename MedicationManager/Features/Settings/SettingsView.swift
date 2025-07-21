import SwiftUI
import Observation

@MainActor
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firebaseManager = FirebaseManager.shared
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingTestingView = false
    
    var body: some View {
        NavigationStack {
            Form {
                profileSection
                preferencesSection
                #if DEBUG
                developerSection
                #endif
                supportSection
                aboutSection
                accountSection
            }
            .navigationTitle(AppStrings.Common.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.done) {
                        dismiss()
                    }
                }
            }
            .alert(AppStrings.Authentication.signOut, isPresented: $showingSignOutAlert) {
                Button(AppStrings.Common.cancel, role: .cancel) { }
                Button(AppStrings.Authentication.signOut, role: .destructive) {
                    signOut()
                }
            } message: {
                Text(NSLocalizedString("settings.signOutConfirmation", value: "Are you sure you want to sign out?", comment: "Sign out confirmation"))
            }
            .alert(NSLocalizedString("settings.deleteAccount", value: "Delete Account", comment: "Delete account"), isPresented: $showingDeleteAccountAlert) {
                Button(AppStrings.Common.cancel, role: .cancel) { }
                Button(AppStrings.Common.delete, role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text(NSLocalizedString("settings.deleteAccountConfirmation", value: "This will permanently delete your account and all data. This action cannot be undone.", comment: "Delete account confirmation"))
            }
            .sheet(isPresented: $showingTestingView) {
                NavigationStack {
                    TestingView()
                        .navigationTitle(NSLocalizedString("settings.syncTesting", value: "Sync Testing", comment: "Sync testing title"))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(AppStrings.Common.done) {
                                    showingTestingView = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var profileSection: some View {
        Section {
            HStack {
                Image(systemName: AppIcons.myHealth)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 60, height: 60)
                    .background(AppTheme.Colors.primary.opacity(AppTheme.Opacity.low))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(firebaseManager.currentUser?.displayName ?? NSLocalizedString("settings.user", value: "User", comment: "Default user name"))
                        .font(AppTheme.Typography.headline)
                    Text(firebaseManager.currentUser?.email ?? "")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.small)
            
            Button {
                NavigationManager.shared.presentSheet(.userProfileEdit)
            } label: {
                Label(NSLocalizedString("settings.editProfile", value: "Edit Profile", comment: "Edit profile button"), systemImage: AppIcons.edit)
            }
        }
    }
    
    private var preferencesSection: some View {
        Section {
            NavigationLink {
                Text("Notifications Settings")
            } label: {
                Label(NSLocalizedString("settings.notifications", value: "Notifications", comment: "Notifications settings"), systemImage: AppIcons.notifications)
            }
            
            NavigationLink {
                Text("Privacy Settings")
            } label: {
                Label(NSLocalizedString("settings.privacy", value: "Privacy", comment: "Privacy settings"), systemImage: AppIcons.privacy)
            }
            
            NavigationLink {
                Text("Siri Shortcuts")
            } label: {
                Label(NSLocalizedString("settings.siriShortcuts", value: "Siri Shortcuts", comment: "Siri shortcuts"), systemImage: "mic.circle")
            }
        } header: {
            Text(NSLocalizedString("settings.preferences", value: "Preferences", comment: "Preferences section"))
        }
    }
    
    #if DEBUG
    private var developerSection: some View {
        Section {
            Button {
                showingTestingView = true
            } label: {
                Label(NSLocalizedString("settings.syncTesting", value: "Sync Testing", comment: "Sync testing"), systemImage: "arrow.triangle.2.circlepath")
            }
            
            NavigationLink {
                Text("Debug Logs")
            } label: {
                Label(NSLocalizedString("settings.debugLogs", value: "Debug Logs", comment: "Debug logs"), systemImage: "doc.text.magnifyingglass")
            }
            
            Button {
                // Clear cache action
            } label: {
                Label(NSLocalizedString("settings.clearCache", value: "Clear Cache", comment: "Clear cache"), systemImage: "trash")
                    .foregroundColor(AppTheme.Colors.error)
            }
        } header: {
            Text(NSLocalizedString("settings.developerTools", value: "Developer Tools", comment: "Developer tools section"))
        }
    }
    #endif
    
    private var supportSection: some View {
        Section {
            NavigationLink {
                Text("Help Center")
            } label: {
                Label(NSLocalizedString("settings.help", value: "Help & Support", comment: "Help and support"), systemImage: "questionmark.circle")
            }
            
            Button {
                // Send feedback action
            } label: {
                Label(NSLocalizedString("settings.feedback", value: "Send Feedback", comment: "Send feedback"), systemImage: "envelope")
            }
            
            NavigationLink {
                Text("FAQ")
            } label: {
                Label(NSLocalizedString("settings.faq", value: "FAQ", comment: "FAQ"), systemImage: "info.circle")
            }
        } header: {
            Text(NSLocalizedString("settings.support", value: "Support", comment: "Support section"))
        }
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink {
                Text(AppStrings.Legal.privacyPolicy)
            } label: {
                Label(AppStrings.Legal.privacyPolicy, systemImage: "lock.shield")
            }
            
            NavigationLink {
                Text(AppStrings.Legal.termsOfService)
            } label: {
                Label(AppStrings.Legal.termsOfService, systemImage: "doc.text")
            }
            
            HStack {
                Text(NSLocalizedString("settings.version", value: "Version", comment: "App version"))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        } header: {
            Text(NSLocalizedString("settings.about", value: "About", comment: "About section"))
        }
    }
    
    private var accountSection: some View {
        Section {
            Button {
                showingSignOutAlert = true
            } label: {
                Label(AppStrings.Authentication.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(AppTheme.Colors.error)
            }
            
            Button {
                showingDeleteAccountAlert = true
            } label: {
                Label(NSLocalizedString("settings.deleteAccount", value: "Delete Account", comment: "Delete account"), systemImage: "trash")
                    .foregroundColor(AppTheme.Colors.error)
            }
        } header: {
            Text(NSLocalizedString("settings.account", value: "Account", comment: "Account section"))
        }
    }
    
    // MARK: - Actions
    
    private func signOut() {
        Task {
            do {
                try await firebaseManager.signOut()
                dismiss()
            } catch {
                // Error handled by FirebaseManager
            }
        }
    }
    
    private func deleteAccount() {
        // TODO: Implement account deletion
    }
}

#Preview {
    SettingsView()
}