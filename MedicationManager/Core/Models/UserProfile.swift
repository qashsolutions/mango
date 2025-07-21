import Foundation
import SwiftData

// MARK: - User Profile Model
/// Local user profile storage using SwiftData (iOS 17+)
/// Stores user preferences and emergency contact information
/// HIPAA Compliance: Emergency contacts stored locally by default
@Model
final class UserProfile {
    // MARK: - Properties
    
    /// Unique identifier linked to Firebase User ID
    @Attribute(.unique) var userId: String
    
    // MARK: Personal Information
    /// Display name (synced with Firebase Auth)
    var displayName: String = ""
    
    // MARK: Emergency Contact Information
    /// Emergency contact name (stored locally by default)
    var emergencyContactName: String?
    
    /// Emergency contact phone (stored locally by default)
    var emergencyContactPhone: String?
    
    /// User consent to share emergency contact with caregivers
    /// When true, emergency contact data can be synced to Firebase (encrypted)
    var shareEmergencyWithCaregivers: Bool = false
    
    // MARK: User Preferences
    /// Whether push notifications are enabled
    var notificationsEnabled: Bool = true
    
    /// Whether medication conflict alerts are enabled
    var conflictAlertsEnabled: Bool = true
    
    /// Whether voice shortcuts (Siri) are enabled
    var voiceShortcutsEnabled: Bool = true
    
    // MARK: Metadata
    /// Last modification timestamp
    var lastModified: Date = Date()
    
    // MARK: - Initialization
    init(userId: String) {
        self.userId = userId
    }
}

// MARK: - UserProfile Extensions
extension UserProfile {
    /// Check if emergency contact information is complete
    var hasEmergencyContact: Bool {
        return emergencyContactName?.isEmpty == false && 
               emergencyContactPhone?.isEmpty == false
    }
    
    /// Format emergency contact for display
    var formattedEmergencyContact: String? {
        guard hasEmergencyContact else { return nil }
        return "\(emergencyContactName ?? "") - \(emergencyContactPhone ?? "")"
    }
    
    /// Create preferences dictionary for Firebase sync
    /// Only includes non-sensitive preference data
    func preferencesForSync() -> [String: Any] {
        return [
            "notificationsEnabled": notificationsEnabled,
            "conflictAlertsEnabled": conflictAlertsEnabled,
            "voiceInputEnabled": voiceShortcutsEnabled, // Maps to existing field name
            "lastPreferenceUpdate": lastModified
        ]
    }
    
    /// Emergency contact data for encrypted sync (only if user consents)
    func emergencyContactForSync() -> [String: Any]? {
        guard shareEmergencyWithCaregivers, hasEmergencyContact else { return nil }
        
        return [
            "emergencyContactName": emergencyContactName ?? "",
            "emergencyContactPhone": emergencyContactPhone ?? "",
            "encryptedAt": Date(),
            "consentGiven": true
        ]
    }
}

// MARK: - Migration Support
extension UserProfile {
    /// Migration errors specific to UserProfile
    enum MigrationError: LocalizedError {
        case migrationFailed(underlying: Error)
        case userNotFound
        case invalidData
        case alreadyMigrated
        case integrityCheckFailed
        
        var errorDescription: String? {
            switch self {
            case .migrationFailed(let error):
                return AppStrings.ErrorMessages.dataError + ": \(error.localizedDescription)"
            case .userNotFound:
                return "User profile not found for migration"
            case .invalidData:
                return "Invalid data encountered during migration"
            case .alreadyMigrated:
                return "User data already migrated"
            case .integrityCheckFailed:
                return "Data integrity check failed after migration"
            }
        }
    }
    
    /// Migrate from existing UserDefaults or Core Data if needed
    /// Called once during app upgrade
    /// - Parameters:
    ///   - userId: The user ID to migrate data for
    ///   - context: The ModelContext to use for migration
    /// - Throws: MigrationError if migration fails
    static func migrateFromLegacyStorage(userId: String, context: ModelContext) throws {
        // Check if profile already exists
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.userId == userId
            }
        )
        
        do {
            let existingProfiles = try context.fetch(descriptor)
            guard existingProfiles.isEmpty else {
                // Already migrated - this is not an error
                return
            }
            
            // Extract legacy data without modifying it first
            let defaults = UserDefaults.standard
            let legacyDisplayName = defaults.string(forKey: "userDisplayName")
            
            // Create new profile with defaults
            let newProfile = UserProfile(userId: userId)
            
            // Apply legacy data if exists
            if let displayName = legacyDisplayName {
                newProfile.displayName = displayName
            }
            
            // Insert new profile
            context.insert(newProfile)
            
            // Save the context
            try context.save()
            
            // Verify migration succeeded
            let verifyDescriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { profile in
                    profile.userId == userId
                }
            )
            let savedProfiles = try context.fetch(verifyDescriptor)
            guard !savedProfiles.isEmpty else {
                throw MigrationError.integrityCheckFailed
            }
            
            // Only clean up legacy data after successful verification
            defaults.removeObject(forKey: "userDisplayName")
            
        } catch let error as MigrationError {
            // Re-throw our custom errors
            throw error
        } catch {
            // Wrap other errors
            throw MigrationError.migrationFailed(underlying: error)
        }
    }
}