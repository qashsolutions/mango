import Foundation
import UIKit

enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

struct Configuration {
    // MARK: - Firebase
    struct Firebase {
        static var projectId: String {
            switch AppEnvironment.current {
            case .development:
                return "medication-manager-dev"
            case .staging:
                return "medication-manager-staging"
            case .production:
                return "medication-manager-prod"
            }
        }
    }
    
    // MARK: - Claude API
    struct ClaudeAPI {
        static let endpoint = "https://api.anthropic.com/v1/messages"
        static let modelName = "claude-sonnet-4"
        static let apiVersion = "2023-06-01"
        static let maxTokens = 4096
        static let temperature = 0.1
        static let cacheExpirationHours = 24
        static let maxRetries = 3
        static let timeoutSeconds = 30
        
        // Voice-first settings
        static let voiceQueryMaxTokens = 2048
        static let voiceResponseOptimized = true
        
        // Medical context settings
        static let medicalContextSystemPrompt = """
            You are a medical interaction expert analyzing drug interactions and medication conflicts. 
            Provide clear, concise responses optimized for voice output. 
            Always include severity levels: Critical, High, Medium, or Low.
            Format responses to be easily spoken by text-to-speech.
            """
    }
    
    // MARK: - Subscription
    struct Subscription {
        static let monthlyProductId = "com.medicationmanager.monthly"
        static let annualProductId = "com.medicationmanager.annual"
        static let trialDurationDays = 7
    }
    
    // MARK: - App Settings
    struct App {
        static let maxCaregivers = 3
        static let maxFamilyMembers = 2
        static let notificationsPerDay = 3
        static let conflictCacheExpiryHours = 24
        static let trialDurationDays = 7
        static let maxAuthenticationAttempts = 3
        static let breakfastHour = 8
        static let lunchHour = 12
        static let dinnerHour = 18
        static let snackHour = 15
        static let defaultCountry = "US"
        static let phoneNumberLength = 10
        static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        static let urlScheme: String = "myguide"
        static let bundleId: String = "com.medicationmanager.MedicationManager"
        static let privacyPolicyURL = Bundle.main.url(forResource: "privacy-policy", withExtension: "html", subdirectory: "Legal")?.absoluteString ?? ""
        static let termsOfServiceURL = Bundle.main.url(forResource: "terms-of-service", withExtension: "html", subdirectory: "Legal")?.absoluteString ?? ""
        
        // AI Analysis Limits
        static let freeUserAnalysisLimit = 5
        static let freeUserAnalysisResetHours = 24
        static let maxCacheSize = 100
        static let maxHistorySize = 50
        
        // API Retry Delays (in seconds)
        static let apiRetryBaseDelay = 1.0
        static let apiRetryShortDelay = 0.5
        
        // Siri Shortcut Thresholds
        static let shortcutSuggestionThreshold = 3
        static let medicationCountThreshold = 2
        static let medicationLogThreshold = 5
        
        // Suggestion Limits
        static let suggestionLimit = 5
        static let spellCheckSuggestionLimit = 3
    }
    
    // MARK: - Voice Settings
    struct Voice {
        static let autoStartListening = true
        static let silenceDetectionSeconds = 2.0
        static let maxRecordingDuration = 30.0
        static let medicalVocabularyEnabled = true
        static let showTranscriptionInRealTime = true
        static let hapticFeedbackEnabled = true
        static let continuousListeningMode = false
        static let voiceConfidenceThreshold = 0.8
        static let showPulseAnimation = true
        static let autoPromptPermission = true
        static let showVoicePrompt = true
        
        // Voice UI Settings
        static let waveformAnimationEnabled = true
        static let primaryInputMethod = "voice" // "voice" or "text"
        static let voiceButtonProminence = "large" // "small", "medium", "large"
        
        // Floating Button
        struct FloatingButton {
            // Position offsets from edges (calculate actual position in views)
            static let defaultOffsetFromTrailing = AppTheme.Spacing.extraLarge + AppTheme.Spacing.medium // 24 + 16 = 40
            static let defaultOffsetFromBottom = AppTheme.Layout.floatingButtonBottomOffset // Will need to add this
            static let edgeConstraint = AppTheme.Layout.floatingButtonEdgeConstraint // Will need to add this
        }
        
        // Locales
        struct Locales {
            static let us = "en-US"
            static let uk = "en-GB"
        }
        
        // Audio Settings
        struct Audio {
            static let bufferSize: UInt32 = 1024
            static let minDecibels: Float = -80
        }
        
        // Error Codes
        struct ErrorCodes {
            static let noSpeechDetected = 203
        }
        
        // Medical Vocabulary
        struct MedicalVocabulary {
            static let commonMedications = [
                "aspirin", "ibuprofen", "acetaminophen", "metformin",
                "lisinopril", "atorvastatin", "levothyroxine", "omeprazole",
                "amlodipine", "metoprolol", "simvastatin", "losartan",
                "gabapentin", "hydrochlorothiazide", "sertraline", "warfarin"
            ]
            
            static let dosageTerms = [
                "milligrams", "mg", "micrograms", "mcg", "grams",
                "milliliters", "ml", "tablets", "capsules", "pills",
                "once daily", "twice daily", "three times", "four times",
                "morning", "evening", "bedtime", "with food"
            ]
            
            static let frequencyTerms = [
                "daily", "twice", "three times", "four times",
                "every", "hours", "morning", "noon", "evening",
                "bedtime", "as needed", "with meals", "before meals"
            ]
            
            static let mgIdentifier = "mg"
            static let mcgIdentifier = "mcg"
            static let dailyIdentifier = "daily"
            static let twiceIdentifier = "twice"
        }
        
        // Phonetic Corrections
        struct PhoneticCorrections {
            static let medications: [String: String] = [
                "i be profen": "ibuprofen",
                "i buprofen": "ibuprofen",
                "met form in": "metformin",
                "met formin": "metformin",
                "as pirin": "aspirin",
                "as prin": "aspirin",
                "tylenol": "acetaminophen",
                "advil": "ibuprofen",
                "vitamin d": "vitamin D",
                "vitamin b 12": "vitamin B12",
                "mg": "mg",
                "milligram": "mg",
                "milligrams": "mg",
                "microgram": "mcg",
                "micrograms": "mcg"
            ]
        }
    }
    
    // MARK: - Siri Integration
    struct Siri {
        struct Intents {
            static let bundleIdentifier = "com.medicationmanager.intents"
            static let groupIdentifier = "group.com.medicationmanager"
            static let checkInteractionsIntent = "CheckMedicationInteractions"
            static let addMedicationIntent = "AddMedication"
            static let medicationReminderIntent = "MedicationReminder"
            static let medicationFrequency = "com.medicationmanager.frequency"
            
            // Activities
            static let checkConflictsActivity = "com.myguide.checkconflicts"
            
            // Identifiers
            static let checkMedicationsIdentifier = "com.medicationmanager.checkmedications"
            static let addMedicationIdentifier = "com.medicationmanager.addmedication"
            static let checkConflictsIdentifier = "com.medicationmanager.checkconflicts"
            static let logMedicationIdentifier = "com.medicationmanager.logmedication"
            static let reminderIdentifier = "com.medicationmanager.reminder"
        }
    }
    
    // Keep old name for backward compatibility
    struct SiriIntents {
        static let bundleIdentifier = "com.medicationmanager.intents"
        static let groupIdentifier = "group.com.medicationmanager"
        static let checkInteractionsIntent = "CheckMedicationInteractions"
        static let addMedicationIntent = "AddMedication"
        static let medicationReminderIntent = "MedicationReminder"
        
        // Activities
        static let checkConflictsActivity = "com.mangohealth.checkconflicts"
        
        // Identifiers
        static let checkMedicationsIdentifier = "com.medicationmanager.checkmedications"
        static let addMedicationIdentifier = "com.medicationmanager.addmedication"
        static let checkConflictsIdentifier = "com.medicationmanager.checkconflicts"
        static let logMedicationIdentifier = "com.medicationmanager.logmedication"
        static let reminderIdentifier = "com.medicationmanager.reminder"
    }
    
    // MARK: - App Groups & Extension Configuration
    struct Extensions {
        /// Shared App Group identifier for data sharing between app and extensions
        static let appGroupIdentifier = "group.com.medicationmanager.shared"
        
        /// Shared keychain access group for secure credential sharing
        static let keychainAccessGroup = "com.medicationmanager.shared"
        
        /// UserDefaults keys for shared data
        struct UserDefaultsKeys {
            static let currentUserId = "extension.currentUserId"
            static let userEmail = "extension.userEmail"
            static let lastSyncDate = "extension.lastSyncDate"
            static let preferredLanguage = "extension.preferredLanguage"
            static let medicationTimePreferences = "extension.medicationTimePreferences"
        }
        
        /// Extension memory limits
        struct MemoryLimits {
            static let maxExtensionMemoryMB = 60
            static let maxFetchBatchSize = 50
            static let maxCachedItems = 100
        }
        
        /// Extension timeouts
        struct Timeouts {
            static let maxExtensionRuntime = 30.0 // seconds
            static let apiCallTimeout = 10.0 // seconds
            static let coreDataFetchTimeout = 5.0 // seconds
        }
        
        /// Shared Core Data configuration
        struct CoreData {
            static let containerName = "MedicationManager"
            static let sqliteFilename = "MedicationManager.sqlite"
            static let sqliteSHMFilename = "MedicationManager.sqlite-shm"
            static let sqliteWALFilename = "MedicationManager.sqlite-wal"
        }
    }
    
    // MARK: - Conflicts
    struct Conflicts {
        static let maxSeverityLevels = 4
    }
    
    // MARK: - Text
    struct Text {
        static let newlineCharacter = "\n"
    }
    
    struct Debug {
        static let sampleUserId = "sample-user-id"
        static let defaultUserId = ""
    }
    struct CoreData {
        static let modelName = "MedicationManager"
        static let medicationEntity = "MedicationEntity"
        static let supplementEntity = "SupplementEntity"
        static let dietEntryEntity = "DietEntryEntity"
        static let doctorEntity = "DoctorEntity"
        static let deletedFlag = "isDeletedFlag"
    }
    
    // MARK: - Meal Times
    struct MealTimes {
        static let breakfastStart = 5  // 5 AM
        static let breakfastEnd = 10   // 10 AM
        static let lunchStart = 11     // 11 AM
        static let lunchEnd = 14       // 2 PM
        static let dinnerStart = 17    // 5 PM
        static let dinnerEnd = 21      // 9 PM
        static let snackStart = 14     // 2 PM
        static let snackEnd = 16       // 4 PM
    }
}
