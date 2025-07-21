//
//  SendableUser.swift
//  MedicationManagerKit
//
//  Created by Claude on 2025/01/14.
//  Copyright © 2025 MedicationManager. All rights reserved.
//

import Foundation

/// Minimal, thread-safe user model for extensions containing only essential information
/// Designed to minimize memory usage and comply with Swift 6 Sendable requirements
@available(iOS 18.0, *)
public struct SendableUser: Sendable, Codable, Identifiable, Hashable {
    
    // MARK: - Core Properties
    
    /// Unique identifier for the user
    public let id: String
    
    /// User's email address (used for display only in extensions)
    public let email: String
    
    /// User's display name
    public let displayName: String?
    
    /// User's preferred language code (e.g., "en-US", "es-ES")
    public let preferredLanguage: String
    
    /// User's timezone identifier (e.g., "America/New_York")
    public let timeZone: String
    
    /// Medication time preferences
    public let medicationTimePreferences: MedicationTimePreferences
    
    /// Voice preferences for Siri interactions
    public let voicePreferences: VoicePreferences
    
    /// Account type/subscription status (simplified for extensions)
    public let accountType: AccountType
    
    /// Whether user has completed onboarding
    public let hasCompletedOnboarding: Bool
    
    /// Last sync timestamp
    public let lastSyncDate: Date?
    
    // MARK: - Computed Properties
    
    /// User's first name extracted from display name
    public var firstName: String {
        displayName?.components(separatedBy: " ").first ?? "User"
    }
    
    /// Formatted timezone for display
    public var formattedTimeZone: String {
        TimeZone(identifier: timeZone)?.abbreviation() ?? "UTC"
    }
    
    /// Locale based on preferred language
    public var locale: Locale {
        Locale(identifier: preferredLanguage)
    }
    
    /// Check if user has premium features
    public var hasPremiumAccess: Bool {
        accountType == .premium || accountType == .trial
    }
    
    /// Voice greeting for Siri responses
    public var voiceGreeting: String {
        if let displayName = displayName?.components(separatedBy: " ").first {
            return displayName
        }
        return "there"
    }
    
    // MARK: - Initialization
    
    public init(
        id: String,
        email: String,
        displayName: String? = nil,
        preferredLanguage: String = "en-US",
        timeZone: String = "America/New_York",
        medicationTimePreferences: MedicationTimePreferences = .default,
        voicePreferences: VoicePreferences = .default,
        accountType: AccountType = .free,
        hasCompletedOnboarding: Bool = true,
        lastSyncDate: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.preferredLanguage = preferredLanguage
        self.timeZone = timeZone
        self.medicationTimePreferences = medicationTimePreferences
        self.voicePreferences = voicePreferences
        self.accountType = accountType
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.lastSyncDate = lastSyncDate
    }
}

// MARK: - Supporting Types

/// User's medication time preferences
@available(iOS 18.0, *)
public struct MedicationTimePreferences: Codable, Sendable, Hashable {
    
    /// Preferred morning medication time
    public let morningTime: TimeComponents
    
    /// Preferred afternoon medication time
    public let afternoonTime: TimeComponents
    
    /// Preferred evening medication time
    public let eveningTime: TimeComponents
    
    /// Preferred bedtime
    public let bedtimeTime: TimeComponents
    
    /// Whether to receive reminders
    public let remindersEnabled: Bool
    
    /// Advance reminder time in minutes
    public let reminderAdvanceMinutes: Int
    
    /// Default preferences
    public static let `default` = MedicationTimePreferences(
        morningTime: TimeComponents(hour: 8, minute: 0),
        afternoonTime: TimeComponents(hour: 12, minute: 0),
        eveningTime: TimeComponents(hour: 18, minute: 0),
        bedtimeTime: TimeComponents(hour: 22, minute: 0),
        remindersEnabled: true,
        reminderAdvanceMinutes: 15
    )
    
    /// Get time for a specific meal
    public func timeFor(meal: MealTime) -> TimeComponents {
        switch meal {
        case .breakfast:
            return morningTime
        case .lunch:
            return afternoonTime
        case .dinner:
            return eveningTime
        case .bedtime:
            return bedtimeTime
        case .snack:
            return TimeComponents(hour: 15, minute: 0) // Default snack time
        }
    }
}

/// Simple time components for medication scheduling
@available(iOS 18.0, *)
public struct TimeComponents: Codable, Sendable, Hashable {
    public let hour: Int
    public let minute: Int
    
    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
    
    /// Format as string for display
    public var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        let components = DateComponents(hour: hour, minute: minute)
        
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        
        return "\(hour):\(String(format: "%02d", minute))"
    }
    
    /// Convert to Date in user's timezone
    public func toDate(in timeZone: TimeZone) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let components = DateComponents(hour: hour, minute: minute)
        return calendar.date(from: components)
    }
}

/// Voice preferences for Siri interactions
@available(iOS 18.0, *)
public struct VoicePreferences: Codable, Sendable, Hashable {
    
    /// Preferred speech rate (0.5 = slow, 1.0 = normal, 1.5 = fast)
    public let speechRate: Float
    
    /// Whether to use phonetic pronunciations for medications
    public let usePhoneticPronunciations: Bool
    
    /// Whether to repeat important information
    public let repeatImportantInfo: Bool
    
    /// Preferred response verbosity
    public let verbosity: VoiceVerbosity
    
    /// Whether to include medication purposes in responses
    public let includePurposes: Bool
    
    /// Default preferences
    public static let `default` = VoicePreferences(
        speechRate: 1.0,
        usePhoneticPronunciations: true,
        repeatImportantInfo: false,
        verbosity: .normal,
        includePurposes: true
    )
}

/// Voice response verbosity levels
@available(iOS 18.0, *)
public enum VoiceVerbosity: String, Codable, Sendable {
    case minimal = "minimal"    // Just the essentials
    case normal = "normal"      // Standard responses
    case detailed = "detailed"  // Include extra context
    
    /// Description for settings
    public var description: String {
        switch self {
        case .minimal: return "Brief responses"
        case .normal: return "Standard responses"
        case .detailed: return "Detailed responses"
        }
    }
}

/// Simplified account types for extensions
@available(iOS 18.0, *)
public enum AccountType: String, Codable, Sendable {
    case free = "free"
    case trial = "trial"
    case premium = "premium"
    case expired = "expired"
    
    /// Check if account has access to feature
    public func hasAccessTo(feature: PremiumFeature) -> Bool {
        switch self {
        case .free:
            return feature.availableInFreeVersion
        case .trial, .premium:
            return true
        case .expired:
            return false
        }
    }
}

/// Premium features enumeration
@available(iOS 18.0, *)
public enum PremiumFeature: String, Sendable {
    case unlimitedMedications = "unlimited_medications"
    case advancedConflictAnalysis = "advanced_conflict_analysis"
    case familySharing = "family_sharing"
    case exportReports = "export_reports"
    case prioritySupport = "priority_support"
    case siriShortcuts = "siri_shortcuts"
    
    /// Whether feature is available in free version
    public var availableInFreeVersion: Bool {
        switch self {
        case .unlimitedMedications:
            return false // Limited to 5 in free version
        case .advancedConflictAnalysis:
            return false // Basic analysis only
        case .familySharing:
            return false
        case .exportReports:
            return false
        case .prioritySupport:
            return false
        case .siriShortcuts:
            return true // Basic Siri features available to all
        }
    }
}

// MARK: - Extension Helpers

@available(iOS 18.0, *)
public extension SendableUser {
    
    /// Create from UserDefaults in extension
    static func fromSharedDefaults() -> SendableUser? {
        guard let sharedDefaults = UserDefaults(suiteName: Configuration.Extensions.appGroupIdentifier),
              let userId = sharedDefaults.string(forKey: Configuration.Extensions.UserDefaultsKeys.currentUserId),
              let email = sharedDefaults.string(forKey: Configuration.Extensions.UserDefaultsKeys.userEmail) else {
            return nil
        }
        
        // Decode stored preferences if available
        if let preferencesData = sharedDefaults.data(forKey: Configuration.Extensions.UserDefaultsKeys.medicationTimePreferences),
           let preferences = try? JSONDecoder().decode(MedicationTimePreferences.self, from: preferencesData) {
            
            return SendableUser(
                id: userId,
                email: email,
                displayName: sharedDefaults.string(forKey: "userDisplayName"),
                preferredLanguage: sharedDefaults.string(forKey: Configuration.Extensions.UserDefaultsKeys.preferredLanguage) ?? "en-US",
                timeZone: TimeZone.current.identifier,
                medicationTimePreferences: preferences,
                lastSyncDate: sharedDefaults.object(forKey: Configuration.Extensions.UserDefaultsKeys.lastSyncDate) as? Date
            )
        }
        
        // Return with defaults if preferences not found
        return SendableUser(
            id: userId,
            email: email,
            displayName: sharedDefaults.string(forKey: "userDisplayName"),
            preferredLanguage: sharedDefaults.string(forKey: Configuration.Extensions.UserDefaultsKeys.preferredLanguage) ?? "en-US",
            timeZone: TimeZone.current.identifier,
            lastSyncDate: sharedDefaults.object(forKey: Configuration.Extensions.UserDefaultsKeys.lastSyncDate) as? Date
        )
    }
    
    /// Save to UserDefaults for sharing with extension
    func saveToSharedDefaults() {
        guard let sharedDefaults = UserDefaults(suiteName: Configuration.Extensions.appGroupIdentifier) else {
            return
        }
        
        sharedDefaults.set(id, forKey: Configuration.Extensions.UserDefaultsKeys.currentUserId)
        sharedDefaults.set(email, forKey: Configuration.Extensions.UserDefaultsKeys.userEmail)
        sharedDefaults.set(displayName, forKey: "userDisplayName")
        sharedDefaults.set(preferredLanguage, forKey: Configuration.Extensions.UserDefaultsKeys.preferredLanguage)
        
        // Encode and save preferences
        if let preferencesData = try? JSONEncoder().encode(medicationTimePreferences) {
            sharedDefaults.set(preferencesData, forKey: Configuration.Extensions.UserDefaultsKeys.medicationTimePreferences)
        }
        
        sharedDefaults.set(Date(), forKey: Configuration.Extensions.UserDefaultsKeys.lastSyncDate)
    }
    
    /// Create a minimal version for logging/analytics
    var minimalInfo: [String: Any] {
        [
            "userId": id,
            "accountType": accountType.rawValue,
            "language": preferredLanguage,
            "timezone": timeZone,
            "hasOnboarded": hasCompletedOnboarding
        ]
    }
}