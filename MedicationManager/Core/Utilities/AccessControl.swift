import Foundation
import Observation
// MARK: - Swift 6 Compatibility
// @preconcurrency is used for Firebase SDK compatibility with Swift 6's strict concurrency
// Firebase SDK types don't yet conform to Sendable protocol
// Remove @preconcurrency when Firebase SDK is updated with Sendable conformance
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
final class AccessControl {
    static let shared = AccessControl()
    
    var caregiverAccess: CaregiverAccess = CaregiverAccess.create()
    var pendingInvitations: [CaregiverInvitation] = []
    var isLoading: Bool = false
    var accessError: AppError?
    
    private let firestore = Firestore.firestore()
    private let authManager = FirebaseManager.shared
    
    private init() {}
    
    // MARK: - Caregiver Management
    func loadCaregiverAccess(for userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let document = try await firestore.collection("users").document(userId).getDocument()
            
            if let data = document.data(),
               let accessData = data["caregiverAccess"] as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: accessData)
                caregiverAccess = try JSONDecoder().decode(CaregiverAccess.self, from: jsonData)
            } else {
                caregiverAccess = CaregiverAccess.create()
            }
            
            // Load pending invitations
            try await loadPendingInvitations(for: userId)
            
        } catch {
            accessError = AppError.caregiverAccessError(.loadFailed)
            throw error
        }
    }
    
    func saveCaregiverAccess(for userId: String) async throws {
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    // Create a wrapper object for the caregiverAccess field
                    let updateData = CaregiverAccessWrapper(caregiverAccess: self.caregiverAccess)
                    try self.firestore.collection("users").document(userId).setData(from: updateData, merge: true) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            accessError = AppError.caregiverAccessError(.saveFailed)
            throw error
        }
    }
    
    func enableCaregiverAccess(for userId: String) async throws {
        caregiverAccess.enabled = true
        try await saveCaregiverAccess(for: userId)
    }
    
    func disableCaregiverAccess(for userId: String) async throws {
        caregiverAccess.enabled = false
        caregiverAccess.caregivers.removeAll()
        try await saveCaregiverAccess(for: userId)
    }
    
    // MARK: - Caregiver Invitations
    func inviteCaregiver(
        userId: String,
        userName: String,
        userEmail: String,
        caregiverEmail: String,
        permissions: [Permission] = Permission.defaultPermissions
    ) async throws {
        guard caregiverAccess.canAddMoreCaregivers else {
            throw AppError.caregiverAccessError(.maxCaregiversReached)
        }
        
        // Check if caregiver is already invited or added
        if caregiverAccess.caregivers.contains(where: { $0.caregiverEmail == caregiverEmail }) {
            throw AppError.caregiverAccessError(.alreadyInvited)
        }
        
        if pendingInvitations.contains(where: { $0.caregiverEmail == caregiverEmail && $0.isValid }) {
            throw AppError.caregiverAccessError(.alreadyInvited)
        }
        
        let invitation = CaregiverInvitation.create(
            inviterId: userId,
            inviterName: userName,
            inviterEmail: userEmail,
            caregiverEmail: caregiverEmail,
            permissions: permissions
        )
        
        do {
            // Save invitation to Firestore
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try self.firestore.collection("caregiverInvitations").document(invitation.id).setData(from: invitation) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Add to pending invitations
            pendingInvitations.append(invitation)
            
            // Send invitation email (placeholder for now)
            try await sendInvitationEmail(invitation)
            
        } catch {
            accessError = AppError.caregiverAccessError(.invitationFailed)
            throw error
        }
    }
    
    func acceptInvitation(_ invitation: CaregiverInvitation, caregiverId: String, caregiverName: String) async throws {
        guard invitation.isValid else {
            throw AppError.caregiverAccessError(.invitationExpired)
        }
        
        // Create caregiver info
        let caregiverInfo = CaregiverInfo.create(
            caregiverId: caregiverId,
            caregiverEmail: invitation.caregiverEmail,
            caregiverName: caregiverName,
            permissions: invitation.permissions
        )
        
        do {
            // Add caregiver to user's access list
            var updatedAccess = caregiverAccess
            try updatedAccess.addCaregiver(caregiverInfo)
            
            // Update user document
            try await saveCaregiverAccessDirectly(for: invitation.inviterId, access: updatedAccess)
            
            // Mark invitation as accepted
            var acceptedInvitation = invitation
            acceptedInvitation.isAccepted = true
            acceptedInvitation.acceptedAt = Date()
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try self.firestore.collection("caregiverInvitations").document(invitation.id).setData(from: acceptedInvitation, merge: true) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Remove from pending invitations
            pendingInvitations.removeAll { $0.id == invitation.id }
            
        } catch {
            accessError = AppError.caregiverAccessError(.acceptFailed)
            throw error
        }
    }
    
    func declineInvitation(_ invitation: CaregiverInvitation) async throws {
        do {
            // Delete invitation from Firestore
            try await firestore.collection("caregiverInvitations").document(invitation.id).delete()
            
            // Remove from pending invitations
            pendingInvitations.removeAll { $0.id == invitation.id }
            
        } catch {
            accessError = AppError.caregiverAccessError(.declineFailed)
            throw error
        }
    }
    
    func revokeInvitation(_ invitation: CaregiverInvitation) async throws {
        do {
            try await firestore.collection("caregiverInvitations").document(invitation.id).delete()
            pendingInvitations.removeAll { $0.id == invitation.id }
            
        } catch {
            accessError = AppError.caregiverAccessError(.revokeFailed)
            throw error
        }
    }
    
    private func loadPendingInvitations(for userId: String) async throws {
        let query = firestore.collection("caregiverInvitations")
            .whereField("inviterId", isEqualTo: userId)
            .whereField("isAccepted", isEqualTo: false)
        
        let snapshot = try await query.getDocuments()
        
        pendingInvitations = snapshot.documents.compactMap { document in
            do {
                let data = document.data()
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                return try JSONDecoder().decode(CaregiverInvitation.self, from: jsonData)
            } catch {
                return nil
            }
        }.filter { $0.isValid }
    }
    
    private func saveCaregiverAccessDirectly(for userId: String, access: CaregiverAccess) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                // Create a wrapper object for the caregiverAccess field
                let updateData = CaregiverAccessWrapper(caregiverAccess: access)
                try self.firestore.collection("users").document(userId).setData(from: updateData, merge: true) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func sendInvitationEmail(_ invitation: CaregiverInvitation) async throws {
        // Placeholder for email service integration
        // In a real app, this would integrate with SendGrid, AWS SES, or similar
        print("📧 Invitation email sent to \(invitation.caregiverEmail)")
        print("📧 Invitation code: \(invitation.invitationCode)")
    }
    
    // MARK: - Caregiver Management
    func removeCaregiver(_ caregiverId: String, for userId: String) async throws {
        caregiverAccess.removeCaregiver(withId: caregiverId)
        try await saveCaregiverAccess(for: userId)
    }
    
    func updateCaregiverPermissions(
        caregiverId: String,
        permissions: [Permission],
        for userId: String
    ) async throws {
        caregiverAccess.updateCaregiverPermissions(caregiverId: caregiverId, permissions: permissions)
        try await saveCaregiverAccess(for: userId)
    }
    
    func toggleCaregiverNotifications(caregiverId: String, for userId: String) async throws {
        caregiverAccess.toggleCaregiverNotifications(caregiverId: caregiverId)
        try await saveCaregiverAccess(for: userId)
    }
    
    func deactivateCaregiver(caregiverId: String, for userId: String) async throws {
        caregiverAccess.deactivateCaregiver(caregiverId: caregiverId)
        try await saveCaregiverAccess(for: userId)
    }
    
    // MARK: - Permission Checking
    func hasPermission(_ permission: Permission, caregiverId: String) -> Bool {
        guard caregiverAccess.enabled else { return false }
        
        return caregiverAccess.caregivers.first { caregiver in
            caregiver.caregiverId == caregiverId && caregiver.isActive
        }?.hasPermission(permission) ?? false
    }
    
    func canAccessSection(_ permission: Permission, as caregiverId: String? = nil) -> Bool {
        // If no caregiver ID provided, assume it's the user themselves
        guard let caregiverId = caregiverId else { return true }
        
        return hasPermission(permission, caregiverId: caregiverId)
    }
    
    func getAccessibleSections(for caregiverId: String) -> [Permission] {
        guard caregiverAccess.enabled,
              let caregiver = caregiverAccess.caregivers.first(where: { $0.caregiverId == caregiverId && $0.isActive }) else {
            return []
        }
        
        return caregiver.permissions
    }
    
    // MARK: - Invitation Code Validation
    func validateInvitationCode(_ code: String, for caregiverEmail: String) async throws -> CaregiverInvitation {
        let query = firestore.collection("caregiverInvitations")
            .whereField("invitationCode", isEqualTo: code)
            .whereField("caregiverEmail", isEqualTo: caregiverEmail)
            .whereField("isAccepted", isEqualTo: false)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw AppError.caregiverAccessError(.invalidInvitationCode)
        }
        
        do {
            let data = document.data()
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let invitation = try JSONDecoder().decode(CaregiverInvitation.self, from: jsonData)
            
            guard invitation.isValid else {
                throw AppError.caregiverAccessError(.invitationExpired)
            }
            
            return invitation
            
        } catch {
            throw AppError.caregiverAccessError(.invalidInvitationCode)
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        accessError = nil
    }
    
    // MARK: - Cleanup
    func cleanupExpiredInvitations(for userId: String) async {
        let expiredInvitations = pendingInvitations.filter { $0.isExpired }
        
        for invitation in expiredInvitations {
            do {
                try await firestore.collection("caregiverInvitations").document(invitation.id).delete()
            } catch {
                // Log error but continue cleanup
                continue
            }
        }
        
        pendingInvitations.removeAll { $0.isExpired }
    }
}

// MARK: - Access Control Extensions
extension AccessControl {
    func getCaregiverSummary() -> CaregiverAccessSummary {
        return CaregiverAccessSummary(
            isEnabled: caregiverAccess.enabled,
            totalCaregivers: caregiverAccess.caregivers.count,
            activeCaregivers: caregiverAccess.activeCaregivers.count,
            pendingInvitations: pendingInvitations.filter { $0.isValid }.count,
            availableSlots: caregiverAccess.maxCaregivers - caregiverAccess.activeCaregivers.count
        )
    }
}

// MARK: - Wrapper for Firestore Codable Support
// This wrapper is needed to update nested fields in Firestore documents
private struct CaregiverAccessWrapper: Codable {
    let caregiverAccess: CaregiverAccess
}

// MARK: - Caregiver Access Summary
struct CaregiverAccessSummary {
    let isEnabled: Bool
    let totalCaregivers: Int
    let activeCaregivers: Int
    let pendingInvitations: Int
    let availableSlots: Int
    
    var hasActiveManagement: Bool {
        return isEnabled && (activeCaregivers > 0 || pendingInvitations > 0)
    }
    
    var statusText: String {
        if !isEnabled {
            return AppStrings.Caregivers.accessDisabled
        } else if activeCaregivers == 0 && pendingInvitations == 0 {
            return AppStrings.Caregivers.noCaregiversMessage
        } else if activeCaregivers > 0 {
            return AppStrings.Caregivers.activeCaregiversCount(activeCaregivers)
        } else {
            return AppStrings.Caregivers.pendingInvitationsCount(pendingInvitations)
        }
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension AccessControl {
    static let mockAccessControl: AccessControl = {
        let control = AccessControl()
        control.caregiverAccess = CaregiverAccess.sampleCaregiverAccess
        control.pendingInvitations = [CaregiverInvitation.sampleInvitation]
        return control
    }()
}
#endif
