import Foundation
import AppIntents

// MARK: - Public Exports for Main App Usage
// This file provides type aliases and utilities for using App Intents
// throughout the main application

@available(iOS 18.0, *)
public typealias CheckMedicationsIntentType = CheckMedicationsIntent

@available(iOS 18.0, *)
public typealias AddMedicationIntentType = AddMedicationIntent

@available(iOS 18.0, *)
public typealias CheckConflictsIntentType = CheckConflictsIntent

@available(iOS 18.0, *)
public typealias LogMedicationIntentType = LogMedicationIntent

@available(iOS 18.0, *)
public typealias SetReminderIntentType = SetReminderIntent

@available(iOS 18.0, *)
public typealias VoiceQueryIntentType = VoiceQueryIntent

// MARK: - Intent Registration

@available(iOS 18.0, *)
public struct MedicationIntentsRegistration {
    
    /// Register all medication intents with the system
    public static func registerIntents() {
        // App Intents are automatically discovered by the system
        // This method is for any additional setup if needed
        print("Medication intents registered with system")
    }
    
    /// Donate common intents based on user behavior
    public static func donateCommonIntents() async {
        // Donate check medications intent as it's commonly used
        let checkIntent = CheckMedicationsIntent()
        await checkIntent.donateToSystem()
        
        // Donate check conflicts intent for safety-conscious users
        let conflictIntent = CheckConflictsIntent()
        await conflictIntent.donateToSystem()
    }
}

// MARK: - Intent Factory

@available(iOS 18.0, *)
public struct MedicationIntentFactory {
    
    /// Create an add medication intent with pre-filled values
    public static func createAddMedicationIntent(
        name: String,
        dosage: String? = nil,
        frequency: String? = nil
    ) -> AddMedicationIntent {
        let intent = AddMedicationIntent()
        intent.medicationName = name
        intent.dosage = dosage
        intent.frequency = frequency
        return intent
    }
    
    /// Create a voice query intent
    public static func createVoiceQueryIntent(query: String) -> VoiceQueryIntent {
        let intent = VoiceQueryIntent()
        intent.query = query
        return intent
    }
}
