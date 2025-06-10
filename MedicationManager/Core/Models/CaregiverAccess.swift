import Foundation
import FirebaseFirestore

// MARK: - Caregiver Access Management
struct CaregiverAccess: Codable {
    var enabled: Bool = false
    var caregivers: [CaregiverInfo] = []
    var maxCaregivers: Int = Configuration.App.maxCaregivers
    
    var canAddMoreCaregivers: Bool {
        return caregivers.filter { $0.isActive }.count < maxCaregivers
    }
    
    var activeCaregivers: [CaregiverInfo] {
        return caregivers.filter { $0.isActive }
    }
    
    mutating func addCaregiver(_ caregiver: CaregiverInfo) throws {
        guard canAddMoreCaregivers else {
            throw AppError.caregiver(.maxCaregiversReached)
        }
        
        // Check for duplicate caregiver
        if caregivers.contains(where: { $0.caregiverId == caregiver.caregiverId }) {
            throw AppError.data(.duplicateEntry)
        }
        
        caregivers.append(caregiver)
    }
    
    mutating func removeCaregiver(withId caregiverId: String) {
        caregivers.removeAll { $0.caregiverId == caregiverId }
    }
    
    mutating func updateCaregiverPermissions(caregiverId: String, permissions: [Permission]) {
        if let index = caregivers.firstIndex(where: { $0.caregiverId == caregiverId }) {
            caregivers[index].permissions = permissions
        }
    }
    
    mutating func toggleCaregiverNotifications(caregiverId: String) {
        if let index = caregivers.firstIndex(where: { $0.caregiverId == caregiverId }) {
            caregivers[index].notificationsEnabled.toggle()
        }
    }
    
    mutating func deactivateCaregiver(caregiverId: String) {
        if let index = caregivers.firstIndex(where: { $0.caregiverId == caregiverId }) {
            caregivers[index].isActive = false
        }
    }
}

// MARK: - Caregiver Info
struct CaregiverInfo: Codable, Identifiable {
    let id: String = UUID().uuidString
    let caregiverId: String
    let caregiverEmail: String
    let caregiverName: String
    var accessLevel: AccessLevel = .readonly
    let grantedAt: Date
    var permissions: [Permission] = [.myhealth, .doctorlist]
    var notificationsEnabled: Bool = true
    var isActive: Bool = true
    
    var displayName: String {
        if caregiverName.isEmpty {
            return caregiverEmail
        }
        return caregiverName
    }
    
    var initials: String {
        let nameComponents = caregiverName.components(separatedBy: " ")
        if nameComponents.count >= 2 {
            let firstInitial = nameComponents[0].first?.uppercased() ?? ""
            let lastInitial = nameComponents[1].first?.uppercased() ?? ""
            return "\(firstInitial)\(lastInitial)"
        } else if let firstChar = caregiverName.first {
            return String(firstChar).uppercased()
        } else {
            return String(caregiverEmail.first?.uppercased() ?? "?")
        }
    }
    
    func hasPermission(_ permission: Permission) -> Bool {
        return permissions.contains(permission)
    }
    
    var permissionSummary: String {
        if permissions.isEmpty {
            return "No access"
        } else if permissions.count == Permission.allCases.count {
            return "Full access"
        } else {
            return permissions.map { $0.displayName }.joined(separator: ", ")
        }
    }
}

// MARK: - Access Level
enum AccessLevel: String, Codable {
    case readonly = "readonly"
    // Future: Could add "edit" permissions
    
    var displayName: String {
        switch self {
        case .readonly:
            return "Read Only"
        }
    }
    
    var description: String {
        switch self {
        case .readonly:
            return "Can view information but cannot make changes"
        }
    }
}

// MARK: - Permissions
enum Permission: String, Codable, CaseIterable {
    case myhealth = "myhealth"
    case doctorlist = "doctorlist"
    case groups = "groups"
    case conflicts = "conflicts"
    
    var displayName: String {
        switch self {
        case .myhealth:
            return "MyHealth"
        case .doctorlist:
            return "Doctor List"
        case .groups:
            return "Groups"
        case .conflicts:
            return "Conflicts"
        }
    }
    
    var description: String {
        switch self {
        case .myhealth:
            return "Access to medications, supplements, and diet information"
        case .doctorlist:
            return "Access to doctor contact information"
        case .groups:
            return "Access to family group settings"
        case .conflicts:
            return "Access to medication conflict reports"
        }
    }
    
    var icon: String {
        switch self {
        case .myhealth:
            return "heart.fill"
        case .doctorlist:
            return "stethoscope"
        case .groups:
            return "person.3.fill"
        case .conflicts:
            return "exclamationmark.triangle.fill"
        }
    }
    
    static var defaultPermissions: [Permission] {
        return [.myhealth, .doctorlist]
    }
}

// MARK: - Caregiver Invitation
struct CaregiverInvitation: Codable {
    let id: String = UUID().uuidString
    let inviterId: String
    let inviterName: String
    let inviterEmail: String
    let caregiverEmail: String
    let permissions: [Permission]
    let invitationCode: String
    let expiresAt: Date
    let createdAt: Date
    var isAccepted: Bool = false
    var acceptedAt: Date?
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var isValid: Bool {
        return !isAccepted && !isExpired
    }
    
    static func create(
        inviterId: String,
        inviterName: String,
        inviterEmail: String,
        caregiverEmail: String,
        permissions: [Permission] = Permission.defaultPermissions
    ) -> CaregiverInvitation {
        let expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let invitationCode = generateInvitationCode()
        
        return CaregiverInvitation(
            inviterId: inviterId,
            inviterName: inviterName,
            inviterEmail: inviterEmail,
            caregiverEmail: caregiverEmail,
            permissions: permissions,
            invitationCode: invitationCode,
            expiresAt: expirationDate,
            createdAt: Date()
        )
    }
    
    private static func generateInvitationCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

// MARK: - Caregiver Access Extensions
extension CaregiverAccess {
    static func create() -> CaregiverAccess {
        return CaregiverAccess(
            enabled: false,
            caregivers: [],
            maxCaregivers: Configuration.App.maxCaregivers
        )
    }
}

extension CaregiverInfo {
    static func create(
        caregiverId: String,
        caregiverEmail: String,
        caregiverName: String,
        permissions: [Permission] = Permission.defaultPermissions
    ) -> CaregiverInfo {
        return CaregiverInfo(
            caregiverId: caregiverId,
            caregiverEmail: caregiverEmail,
            caregiverName: caregiverName,
            grantedAt: Date(),
            permissions: permissions
        )
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension CaregiverAccess {
    static let sampleCaregiverAccess = CaregiverAccess(
        enabled: true,
        caregivers: [
            CaregiverInfo(
                caregiverId: "caregiver-1",
                caregiverEmail: "spouse@example.com",
                caregiverName: "Jane Doe",
                grantedAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                permissions: [.myhealth, .doctorlist, .conflicts]
            ),
            CaregiverInfo(
                caregiverId: "caregiver-2",
                caregiverEmail: "daughter@example.com",
                caregiverName: "Sarah Doe",
                grantedAt: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date(),
                permissions: [.myhealth, .doctorlist],
                notificationsEnabled: false
            )
        ],
        maxCaregivers: Configuration.App.maxCaregivers
    )
}

extension CaregiverInvitation {
    static let sampleInvitation = CaregiverInvitation(
        inviterId: "sample-user-id",
        inviterName: "John Doe",
        inviterEmail: "john.doe@example.com",
        caregiverEmail: "caregiver@example.com",
        permissions: [.myhealth, .doctorlist],
        invitationCode: "ABC12345",
        expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        createdAt: Date()
    )
}
#endif