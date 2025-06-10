import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    let displayName: String
    let profileImageURL: String?
    var subscriptionStatus: SubscriptionStatus
    var subscriptionType: SubscriptionType?
    let trialEndDate: Date?
    let createdAt: Date
    var lastLoginAt: Date
    var preferences: UserPreferences
    var caregiverAccess: CaregiverAccess
    
    // MFA Fields
    var mfaEnabled: Bool = false
    var mfaEnrolledAt: Date?
    var backupCodes: [String]?
    
    enum SubscriptionStatus: String, Codable, CaseIterable {
        case trial = "trial"
        case active = "active"
        case expired = "expired"
    }
    
    enum SubscriptionType: String, Codable, CaseIterable {
        case monthly = "monthly"
        case annual = "annual"
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var notificationsEnabled: Bool = true
    var voiceInputEnabled: Bool = true
    var reminderFrequency: ReminderFrequency = .threeDaily
    var timeZone: String = TimeZone.current.identifier
    var language: String = "en"
}

enum ReminderFrequency: String, Codable, CaseIterable {
    case threeDaily = "three_daily"   // Breakfast, lunch, dinner
    case custom = "custom"
}

// MARK: - Caregiver Access (Moving to separate file)
extension User {
    struct CaregiverAccess: Codable {
        var enabled: Bool
        var caregivers: [CaregiverInfo]
        
        struct CaregiverInfo: Codable, Identifiable {
            let id: String
            let caregiverId: String
            let accessLevel: AccessLevel
            let grantedAt: Date
            var permissions: [Permission]
            
            enum AccessLevel: String, Codable {
                case readonly = "readonly"
            }
            
            enum Permission: String, Codable, CaseIterable {
                case myhealth = "myhealth"
                case doctorlist = "doctorlist"
            }
        }
    }
}

// MARK: - User Extensions
extension User {
    var isTrialActive: Bool {
        guard subscriptionStatus == .trial,
              let trialEndDate = trialEndDate else {
            return false
        }
        return Date() < trialEndDate
    }
    
    var isSubscriptionActive: Bool {
        return subscriptionStatus == .active || isTrialActive
    }
    
    var canAddCaregivers: Bool {
        return isSubscriptionActive && caregiverAccess.caregivers.count < Configuration.App.maxCaregivers
    }
    
    var displayInitials: String {
        let components = displayName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension User {
    static let sampleUser = User(
        id: "sample-user-id",
        email: "john.doe@example.com",
        displayName: "John Doe",
        profileImageURL: nil,
        subscriptionStatus: .trial,
        subscriptionType: nil,
        trialEndDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
        lastLoginAt: Date(),
        preferences: UserPreferences(),
        caregiverAccess: User.CaregiverAccess(
            enabled: true,
            caregivers: [
                User.CaregiverAccess.CaregiverInfo(
                    id: UUID().uuidString,
                    caregiverId: "caregiver-1",
                    accessLevel: .readonly,
                    grantedAt: Date(),
                    permissions: [.myhealth, .doctorlist]
                )
            ]
        ),
        mfaEnabled: false,
        mfaEnrolledAt: nil,
        backupCodes: nil
    )
}
#endif
