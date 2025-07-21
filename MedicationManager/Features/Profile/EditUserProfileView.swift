import SwiftUI
import SwiftData
@preconcurrency import FirebaseAuth

// MARK: - Edit User Profile View
/// iOS 18+ SwiftUI view for editing user profile with SwiftData persistence
/// Manages user preferences, display name, and emergency contacts
/// HIPAA compliant: Emergency contacts stored locally by default
@MainActor
struct EditUserProfileView: View {
    // MARK: - Environment & State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var firebaseManager = FirebaseManager.shared
    
    // MARK: - SwiftData Query
    /// Query for user profiles matching current user ID
    @Query private var profiles: [UserProfile]
    
    // MARK: - Form State
    @State private var displayName = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    @State private var shareEmergencyWithCaregivers = false
    
    // MARK: - Preferences State
    @State private var notificationsEnabled = true
    @State private var conflictAlertsEnabled = true
    @State private var voiceShortcutsEnabled = true
    
    // MARK: - UI State
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Computed Properties
    /// Get current user's profile from SwiftData
    private var currentProfile: UserProfile? {
        profiles.first { $0.userId == firebaseManager.currentUser?.id }
    }
    
    /// Get login identifier (phone or email) from Firebase Auth
    private var loginIdentifier: String {
        // Check Firebase Auth current user first
        if let authUser = Auth.auth().currentUser {
            // Phone number takes precedence if available
            if let phone = authUser.phoneNumber, !phone.isEmpty {
                return phone
            }
            // Fall back to email
            if let email = authUser.email, !email.isEmpty {
                return email
            }
        }
        
        // Check local Firebase manager user
        // Note: phoneNumber is not stored in User model, only available from Firebase Auth
        if let email = firebaseManager.currentUser?.email, !email.isEmpty {
            return email
        }
        
        return AppStrings.Common.notAvailable
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                accountInfoSection
                personalInfoSection
                emergencyContactSection
                preferencesSection
            }
            .navigationTitle(AppStrings.Profile.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.save) {
                        saveProfile()
                    }
                    .disabled(isSaving || displayName.isEmpty)
                }
            }
            // MARK: - Alerts
            .alert(AppStrings.Common.error, isPresented: $showingError) {
                Button(AppStrings.Common.ok) { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                AppStrings.Profile.deleteDataTitle,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(AppStrings.Common.delete, role: .destructive) {
                    deleteProfile()
                }
                Button(AppStrings.Common.cancel, role: .cancel) { }
            } message: {
                Text(AppStrings.Profile.deleteDataMessage)
            }
            .onAppear {
                loadUserData()
            }
        }
    }
    
    // MARK: - Sections
    
    /// Account information section (read-only)
    private var accountInfoSection: some View {
        Section {
            // Login method
            HStack {
                Text(AppStrings.Profile.loginMethod)
                Spacer()
                Text(loginIdentifier)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            // Account type
            HStack {
                Text(AppStrings.Profile.accountTypeLabel)
                Spacer()
                Text(firebaseManager.currentUser?.userType.displayName ?? UserType.primary.displayName)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        } header: {
            Text(AppStrings.Profile.accountInfo)
        } footer: {
            Text(accountTypeDescription)
                .font(AppTheme.Typography.caption2)
        }
    }
    
    /// Get account type description based on user type
    private var accountTypeDescription: String {
        switch firebaseManager.currentUser?.userType ?? .primary {
        case .primary:
            return AppStrings.Profile.primaryAccountDesc
        case .caregiver:
            return AppStrings.Profile.caregiverAccountDesc
        case .family:
            return AppStrings.Profile.familyAccountDesc
        }
    }
    
    /// Personal information section
    private var personalInfoSection: some View {
        Section {
            // Display Name (Required)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Profile.displayName)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(AppStrings.Profile.namePlaceholder, text: $displayName)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(personalInfoSectionHeader)
        }
    }
    
    /// Dynamic header for personal info based on user type
    private var personalInfoSectionHeader: String {
        switch firebaseManager.currentUser?.userType ?? .primary {
        case .primary:
            return AppStrings.Profile.yourInfo
        case .caregiver:
            return AppStrings.Profile.caregiverInfo
        case .family:
            return AppStrings.Profile.familyMemberInfo
        }
    }
    
    /// Emergency contact section with privacy options
    private var emergencyContactSection: some View {
        Section {
            // Emergency Contact Name
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Profile.emergencyName)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(AppStrings.Profile.emergencyNamePlaceholder, text: $emergencyContactName)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // Emergency Contact Phone
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Profile.emergencyPhone)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(AppStrings.Profile.phonePlaceholder, text: $emergencyContactPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // HIPAA Compliance: Share with caregivers toggle
            Toggle(isOn: $shareEmergencyWithCaregivers) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(AppStrings.Profile.shareWithCaregivers)
                        .font(AppTheme.Typography.footnote)
                    Text(AppStrings.Profile.shareWithCaregiversDescription)
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            .padding(.vertical, AppTheme.Spacing.small)
            
        } header: {
            Text(emergencyContactSectionHeader)
        } footer: {
            Text(emergencyContactFooterText)
                .font(AppTheme.Typography.caption2)
        }
    }
    
    /// Dynamic header for emergency contact based on user type
    private var emergencyContactSectionHeader: String {
        switch firebaseManager.currentUser?.userType ?? .primary {
        case .primary:
            return AppStrings.Profile.yourEmergencyContact
        case .caregiver, .family:
            return AppStrings.Profile.patientEmergencyContact
        }
    }
    
    /// Dynamic footer text for emergency contact
    private var emergencyContactFooterText: String {
        let userType = firebaseManager.currentUser?.userType ?? .primary
        
        // Caregivers and family members see patient's emergency contact
        if userType == .caregiver || userType == .family {
            return AppStrings.Profile.patientEmergencyFooter
        }
        
        // Primary users see sharing options
        return shareEmergencyWithCaregivers ? 
            AppStrings.Profile.emergencySharedFooter : 
            AppStrings.Profile.emergencyLocalFooter
    }
    
    /// User preferences section
    private var preferencesSection: some View {
        Section {
            // Notifications toggle
            Toggle(AppStrings.Profile.notifications, isOn: $notificationsEnabled)
            
            // Conflict alerts toggle (new feature)
            Toggle(AppStrings.Profile.conflictAlerts, isOn: $conflictAlertsEnabled)
            
            // Voice shortcuts toggle (maps to voiceInputEnabled)
            Toggle(AppStrings.Profile.voiceShortcuts, isOn: $voiceShortcutsEnabled)
            
        } header: {
            Text(AppStrings.Profile.preferences)
        } footer: {
            Text(AppStrings.Profile.preferencesFooter)
                .font(AppTheme.Typography.caption2)
        }
    }
    
    // MARK: - Actions
    
    /// Load existing user data from SwiftData
    private func loadUserData() {
        // Load from Firebase Auth/Manager
        displayName = firebaseManager.currentUser?.displayName ?? ""
        
        // Load from SwiftData profile if exists
        if let profile = currentProfile {
            displayName = profile.displayName.isEmpty ? displayName : profile.displayName
            emergencyContactName = profile.emergencyContactName ?? ""
            emergencyContactPhone = profile.emergencyContactPhone ?? ""
            shareEmergencyWithCaregivers = profile.shareEmergencyWithCaregivers
            notificationsEnabled = profile.notificationsEnabled
            conflictAlertsEnabled = profile.conflictAlertsEnabled
            voiceShortcutsEnabled = profile.voiceShortcutsEnabled
        } else {
            // Load preferences from Firebase if no local profile
            if let preferences = firebaseManager.currentUser?.preferences {
                notificationsEnabled = preferences.notificationsEnabled
                conflictAlertsEnabled = preferences.conflictAlertsEnabled
                voiceShortcutsEnabled = preferences.voiceInputEnabled
            }
        }
    }
    
    /// Save profile to SwiftData and sync preferences to Firebase
    private func saveProfile() {
        isSaving = true
        
        Task {
            do {
                // Get or create profile
                let profile: UserProfile
                if let existingProfile = currentProfile {
                    profile = existingProfile
                } else {
                    // Create new profile
                    guard let userId = firebaseManager.currentUser?.id else {
                        throw AppError.authentication(.userNotFound)
                    }
                    profile = UserProfile(userId: userId)
                    modelContext.insert(profile)
                }
                
                // Update profile data
                profile.displayName = displayName
                profile.emergencyContactName = emergencyContactName.isEmpty ? nil : emergencyContactName
                profile.emergencyContactPhone = emergencyContactPhone.isEmpty ? nil : emergencyContactPhone
                profile.shareEmergencyWithCaregivers = shareEmergencyWithCaregivers
                profile.notificationsEnabled = notificationsEnabled
                profile.conflictAlertsEnabled = conflictAlertsEnabled
                profile.voiceShortcutsEnabled = voiceShortcutsEnabled
                profile.lastModified = Date()
                
                // Save to SwiftData
                try modelContext.save()
                
                // Update Firebase Auth display name if changed
                if displayName != firebaseManager.currentUser?.displayName,
                   let authUser = Auth.auth().currentUser {
                    try await authUser.updateDisplayName(to: displayName)
                }
                
                // Sync preferences to Firebase for cross-device consistency
                await syncPreferencesToFirebase(profile: profile)
                
                // Track analytics (no PII)
                AnalyticsManager.shared.trackEvent("profile_updated", parameters: [
                    "has_emergency_contact": profile.hasEmergencyContact,
                    "emergency_shared": shareEmergencyWithCaregivers,
                    "notifications": notificationsEnabled,
                    "conflict_alerts": conflictAlertsEnabled,
                    "voice_shortcuts": voiceShortcutsEnabled
                ])
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isSaving = false
        }
    }
    
    /// Sync non-sensitive preferences to Firebase
    private func syncPreferencesToFirebase(profile: UserProfile) async {
        // Update local Firebase user preferences
        guard var currentUser = firebaseManager.currentUser else { return }
        
        // Update preferences
        currentUser.preferences.notificationsEnabled = profile.notificationsEnabled
        currentUser.preferences.conflictAlertsEnabled = profile.conflictAlertsEnabled
        currentUser.preferences.voiceInputEnabled = profile.voiceShortcutsEnabled
        
        // Note: Display name cannot be updated after account creation
        // It's set from the authentication provider (Google, Apple, etc.)
        
        // Update local state
        firebaseManager.currentUser = currentUser
        
        // Note: Preferences are stored locally on this iPhone only.
        // This is intentional for an iPhone-only app where each device
        // maintains its own preference settings.
    }
    
    /// Delete profile data with confirmation
    private func deleteProfile() {
        guard let profile = currentProfile else { return }
        
        modelContext.delete(profile)
        
        do {
            try modelContext.save()
            
            // Track deletion
            AnalyticsManager.shared.trackEvent("profile_deleted")
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Preview
#Preview {
    EditUserProfileView()
        .withSwiftDataContext()
}
