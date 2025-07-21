import Foundation

/// Context for voice input to provide appropriate prompts and processing
enum VoiceInteractionContext: String, CaseIterable {
    case general = "general"
    case medicationName = "medication_name"
    case supplementName = "supplement_name"
    case dosage = "dosage"
    case conflictQuery = "conflict_query"
    case notes = "notes"
    case doctorName = "doctor_name"
    case frequency = "frequency"
    case foodName = "food_name"
    
    /// User-friendly prompt for each context
    var prompt: String {
        switch self {
        case .general:
            return AppStrings.Voice.askAnything
        case .medicationName:
            return AppStrings.Voice.tapToSpeakMedication
        case .supplementName:
            return AppStrings.Voice.tapToSpeakSupplement
        case .dosage:
            return AppStrings.Voice.tapToSpeakDosage
        case .conflictQuery:
            return AppStrings.Voice.tapToAskQuestion
        case .notes:
            return AppStrings.Voice.notesPrompt
        case .doctorName:
            return AppStrings.Voice.doctorNamePrompt
        case .frequency:
            return AppStrings.Voice.frequencyPrompt
        case .foodName:
            return AppStrings.Voice.foodNamePrompt
        }
    }
    
    /// Determines if medical vocabulary enhancement should be applied
    var usesMedicalVocabulary: Bool {
        switch self {
        case .medicationName, .supplementName, .dosage, .conflictQuery:
            return true
        default:
            return false
        }
    }
    
    /// Suggested maximum recording duration for context
    var maxDuration: TimeInterval {
        switch self {
        case .conflictQuery, .notes:
            return Configuration.Voice.maxRecordingDuration
        case .medicationName, .supplementName, .doctorName, .foodName:
            return 10.0
        case .dosage, .frequency:
            return 5.0
        default:
            return 15.0
        }
    }
}