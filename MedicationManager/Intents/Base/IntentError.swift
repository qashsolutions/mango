import Foundation

// MARK: - Intent Error Handling

/// Errors that can occur during intent execution
@available(iOS 18.0, *)
public enum IntentError: LocalizedError {
    case notAuthenticated
    case medicationNotFound(String)
    case invalidDosage(String)
    case invalidFrequency(String)
    case conflictCheckFailed
    case networkError
    case dataError
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return AppStrings.Siri.notSignedInResponse
        case .medicationNotFound(let name):
            return String(format: AppStrings.Siri.medicationNotFoundResponse, name)
        case .invalidDosage(let dosage):
            return "Invalid dosage: \(dosage). Please use format like '100mg' or '2 tablets'"
        case .invalidFrequency(let frequency):
            return "Invalid frequency: \(frequency). Try 'once daily', 'twice daily', or 'as needed'"
        case .conflictCheckFailed:
            return AppStrings.Siri.checkConflictsError
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .dataError:
            return "Unable to access your medication data. Please try again."
        case .unknown(let message):
            return message
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Please open the app and sign in first."
        case .medicationNotFound:
            return "Check the medication name or add it first using the app."
        case .invalidDosage:
            return "Use a format like '100mg', '2 tablets', or '5ml'."
        case .invalidFrequency:
            return "Use phrases like 'once daily', 'twice daily', 'three times daily', or 'as needed'."
        case .conflictCheckFailed:
            return "Try checking individual medications or open the app for detailed analysis."
        case .networkError:
            return "Check your internet connection and try again."
        case .dataError:
            return "Open the app to ensure your data is synced."
        case .unknown:
            return "Please try again or open the app for more options."
        }
    }
}

// MARK: - Intent Error Analytics

@available(iOS 18.0, *)
extension IntentError {
    /// Track error occurrence for analytics
    func trackError() async {
        let errorType: String
        let details: [String: Any]
        
        switch self {
        case .notAuthenticated:
            errorType = "not_authenticated"
            details = [:]
        case .medicationNotFound(let name):
            errorType = "medication_not_found"
            details = ["medication": name]
        case .invalidDosage(let dosage):
            errorType = "invalid_dosage"
            details = ["dosage": dosage]
        case .invalidFrequency(let frequency):
            errorType = "invalid_frequency"
            details = ["frequency": frequency]
        case .conflictCheckFailed:
            errorType = "conflict_check_failed"
            details = [:]
        case .networkError:
            errorType = "network_error"
            details = [:]
        case .dataError:
            errorType = "data_error"
            details = [:]
        case .unknown(let message):
            errorType = "unknown_error"
            details = ["message": message]
        }
        
        await MainActor.run {
            AnalyticsManager.shared.trackEvent(
                "intent_error",
                parameters: [
                    "error_type": errorType,
                    "details": details
                ]
            )
        }
    }
}