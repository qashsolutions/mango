import Foundation
import Observation

@MainActor
@Observable
final class GroupsViewModel {
    var accessControl: AccessControl = AccessControl.shared
    var isLoading: Bool = false
    var error: AppError?
    
    private let authManager = FirebaseManager.shared
    private let analyticsManager = AnalyticsManager.shared
    
    // MARK: - Data Loading
    func loadData() async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            try await accessControl.loadCaregiverAccess(for: userId)
            analyticsManager.trackScreenViewed("groups")
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.loadFailed)
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
        
        // Cleanup expired invitations
        if let userId = authManager.currentUser?.id {
            await accessControl.cleanupExpiredInvitations(for: userId)
        }
    }
    
    // MARK: - Caregiver Access Management
    func toggleCaregiverAccess() async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            if accessControl.caregiverAccess.enabled {
                try await accessControl.disableCaregiverAccess(for: userId)
                analyticsManager.trackFeatureUsed("caregiver_access_disabled")
            } else {
                try await accessControl.enableCaregiverAccess(for: userId)
                analyticsManager.trackCaregiverAccessEnabled()
            }
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.saveFailed)
        }
    }
    
    func enableCaregiverAccess() async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            try await accessControl.enableCaregiverAccess(for: userId)
            analyticsManager.trackCaregiverAccessEnabled()
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.saveFailed)
        }
    }
    
    func disableCaregiverAccess() async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            try await accessControl.disableCaregiverAccess(for: userId)
            analyticsManager.trackFeatureUsed("caregiver_access_disabled")
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.saveFailed)
        }
    }
    
    // MARK: - Caregiver Management
    func inviteCaregiver(email: String, name: String, permissions: [Permission]) async {
        guard let user = authManager.currentUser,
              let userId = user.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            try await accessControl.inviteCaregiver(
                userId: userId,
                userName: user.displayName,
                userEmail: user.email,
                caregiverEmail: email,
                permissions: permissions
            )
            
            analyticsManager.trackCaregiverInvited()
            
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.invitationFailed)
        }
    }
    
    func removeCaregiver(_ caregiver: CaregiverInfo) async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            try await accessControl.removeCaregiver(caregiver.caregiverId, for: userId)
            analyticsManager.trackFeatureUsed("caregiver_removed")
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.saveFailed)
        }
    }
    
    func editCaregiverPermissions(_ caregiver: CaregiverInfo) async {
        // This would typically show a permissions editor
        analyticsManager.trackFeatureUsed("caregiver_permissions_edit")
    }
    
    func updateCaregiverPermissions(_ caregiver: CaregiverInfo, permissions: [Permission]) async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            try await accessControl.updateCaregiverPermissions(
                caregiverId: caregiver.caregiverId,
                permissions: permissions,
                for: userId
            )
            
            for permission in permissions {
                analyticsManager.trackCaregiverPermissionChanged(
                    permission: permission.rawValue,
                    granted: true
                )
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.saveFailed)
        }
    }
    
    func toggleCaregiverNotifications(_ caregiver: CaregiverInfo) async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            try await accessControl.toggleCaregiverNotifications(
                caregiverId: caregiver.caregiverId,
                for: userId
            )
            
            analyticsManager.trackFeatureUsed("caregiver_notifications_toggle")
            
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.saveFailed)
        }
    }
    
    func deactivateCaregiver(_ caregiver: CaregiverInfo) async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            try await accessControl.deactivateCaregiver(
                caregiverId: caregiver.caregiverId,
                for: userId
            )
            
            analyticsManager.trackFeatureUsed("caregiver_deactivated")
            
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.saveFailed)
        }
    }
    
    // MARK: - Invitation Management
    func resendInvitation(_ invitation: CaregiverInvitation) async {
        // Create a new invitation to replace the existing one
        guard let user = authManager.currentUser,
              let userId = user.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            // Cancel the old invitation
            try await accessControl.revokeInvitation(invitation)
            
            // Send a new invitation
            try await accessControl.inviteCaregiver(
                userId: userId,
                userName: user.displayName,
                userEmail: user.email,
                caregiverEmail: invitation.caregiverEmail,
                permissions: invitation.permissions
            )
            
            analyticsManager.trackFeatureUsed("invitation_resent")
            
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.invitationFailed)
        }
    }
    
    func cancelInvitation(_ invitation: CaregiverInvitation) async {
        do {
            try await accessControl.revokeInvitation(invitation)
            analyticsManager.trackFeatureUsed("invitation_cancelled")
        } catch {
            self.error = error as? AppError ?? AppError.caregiver(.revokeFailed)
        }
    }
    
    // MARK: - Permission Management
    func getAvailablePermissions() -> [Permission] {
        return Permission.allCases
    }
    
    func getDefaultPermissions() -> [Permission] {
        return Permission.defaultPermissions
    }
    
    func canGrantPermission(_ permission: Permission, to caregiver: CaregiverInfo) -> Bool {
        // All permissions can be granted to caregivers
        return true
    }
    
    func validatePermissions(_ permissions: [Permission]) -> Bool {
        // Validate that at least one permission is selected
        return !permissions.isEmpty
    }
    
    // MARK: - Access Control Information
    func getCaregiverAccessSummary() -> CaregiverAccessSummary {
        return accessControl.getCaregiverSummary()
    }
    
    func getPermissionDescription(_ permission: Permission) -> String {
        return permission.description
    }
    
    func getPermissionIcon(_ permission: Permission) -> String {
        return permission.icon
    }
    
    // MARK: - Statistics and Analytics
    func getCaregiverStatistics() -> CaregiverStatistics {
        return CaregiverStatistics(
            totalCaregivers: accessControl.caregiverAccess.caregivers.count,
            activeCaregivers: accessControl.caregiverAccess.activeCaregivers.count,
            pendingInvitations: accessControl.pendingInvitations.count,
            mostCommonPermissions: getMostCommonPermissions(),
            averagePermissionsPerCaregiver: getAveragePermissionsPerCaregiver(),
            caregiverJoinRate: getCaregiverJoinRate()
        )
    }
    
    private func getMostCommonPermissions() -> [Permission] {
        let allPermissions = accessControl.caregiverAccess.caregivers.flatMap { $0.permissions }
        let permissionCounts = Dictionary(grouping: allPermissions) { $0 }
        return permissionCounts.sorted { $0.value.count > $1.value.count }.map { $0.key }
    }
    
    private func getAveragePermissionsPerCaregiver() -> Double {
        let totalPermissions = accessControl.caregiverAccess.caregivers.reduce(0) { $0 + $1.permissions.count }
        let caregiverCount = accessControl.caregiverAccess.caregivers.count
        return caregiverCount > 0 ? Double(totalPermissions) / Double(caregiverCount) : 0.0
    }
    
    private func getCaregiverJoinRate() -> Double {
        let totalInvited = accessControl.caregiverAccess.caregivers.count + accessControl.pendingInvitations.count
        return totalInvited > 0 ? Double(accessControl.caregiverAccess.caregivers.count) / Double(totalInvited) : 0.0
    }
    
    // MARK: - Privacy and Security
    func getPrivacySettings() -> PrivacySettings {
        return PrivacySettings(
            shareHealthData: true, // TODO: Get from user preferences
            shareContactInfo: true,
            allowEmergencyAccess: false,
            dataRetentionDays: 90
        )
    }
    
    func updatePrivacySettings(_ settings: PrivacySettings) async {
        // TODO: Implement privacy settings update
        analyticsManager.trackFeatureUsed("privacy_settings_updated")
    }
    
    // MARK: - Emergency Access
    func enableEmergencyAccess() async {
        analyticsManager.trackFeatureUsed("emergency_access_enabled")
        // TODO: Implement emergency access
    }
    
    func disableEmergencyAccess() async {
        analyticsManager.trackFeatureUsed("emergency_access_disabled")
        // TODO: Implement emergency access disable
    }
    
    func getEmergencyContacts() -> [CaregiverInfo] {
        // TODO: Filter caregivers with emergency access
        return accessControl.caregiverAccess.activeCaregivers
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
    
    func retryLastAction() async {
        await loadData()
    }
    
    // MARK: - Helper Methods
    func canAddMoreCaregivers() -> Bool {
        return accessControl.caregiverAccess.canAddMoreCaregivers
    }
    
    func getMaxCaregivers() -> Int {
        return accessControl.caregiverAccess.maxCaregivers
    }
    
    func getRemainingInvitations() -> Int {
        return accessControl.caregiverAccess.maxCaregivers - accessControl.caregiverAccess.activeCaregivers.count
    }
    
    func hasActiveManagement() -> Bool {
        return getCaregiverAccessSummary().hasActiveManagement
    }
}

// MARK: - Supporting Models
struct CaregiverStatistics {
    let totalCaregivers: Int
    let activeCaregivers: Int
    let pendingInvitations: Int
    let mostCommonPermissions: [Permission]
    let averagePermissionsPerCaregiver: Double
    let caregiverJoinRate: Double
    
    var joinRatePercentage: String {
        return "\(Int(caregiverJoinRate * 100))%"
    }
    
    var hasGoodJoinRate: Bool {
        return caregiverJoinRate >= 0.7
    }
}

struct PrivacySettings {
    let shareHealthData: Bool
    let shareContactInfo: Bool
    let allowEmergencyAccess: Bool
    let dataRetentionDays: Int
    
    var isPrivacyOptimal: Bool {
        return !shareHealthData && !shareContactInfo && !allowEmergencyAccess
    }
}

// MARK: - Sample Data Extension
#if DEBUG
extension GroupsViewModel {
    static let sampleViewModel: GroupsViewModel = {
        let viewModel = GroupsViewModel()
        viewModel.accessControl = AccessControl.mockAccessControl
        return viewModel
    }()
}

extension CaregiverStatistics {
    static let sampleStatistics = CaregiverStatistics(
        totalCaregivers: 3,
        activeCaregivers: 2,
        pendingInvitations: 1,
        mostCommonPermissions: [.myhealth, .doctorlist],
        averagePermissionsPerCaregiver: 2.5,
        caregiverJoinRate: 0.8
    )
}

extension PrivacySettings {
    static let sampleSettings = PrivacySettings(
        shareHealthData: true,
        shareContactInfo: false,
        allowEmergencyAccess: true,
        dataRetentionDays: 90
    )
}
#endif
