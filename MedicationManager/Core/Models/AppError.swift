import Foundation

// MARK: - App Error Definitions
enum AppError: LocalizedError, Sendable {
    case authentication(AuthError)
    case network(NetworkError)
    case data(DataError)
    case voice(VoiceError)
    case voiceInteraction(VoiceInteractionError)
    case sync(SyncError)
    case caregiver(CaregiverError)
    case caregiverAccessError(CaregiverAccessError)
    case subscription(SubscriptionError)
    case claudeAPI(ClaudeAPIError)
    
    var errorDescription: String? {
        switch self {
        case .authentication(let authError):
            return authError.localizedDescription
        case .network(let networkError):
            return networkError.localizedDescription
        case .data(let dataError):
            return dataError.localizedDescription
        case .voice(let voiceError):
            return voiceError.localizedDescription
        case .voiceInteraction(let voiceInteractionError):
            return voiceInteractionError.localizedDescription
        case .sync(let syncError):
            return syncError.localizedDescription
        case .caregiver(let caregiverError):
            return caregiverError.localizedDescription
        case .caregiverAccessError(let caregiverAccessError):
            return caregiverAccessError.localizedDescription
        case .subscription(let subscriptionError):
            return subscriptionError.localizedDescription
        case .claudeAPI(let claudeAPIError):
            return claudeAPIError.localizedDescription
        }
    }
}

// MARK: - Authentication Errors
enum AuthError: LocalizedError, Sendable {
    case signInFailed
    case signOutFailed
    case userNotFound
    case invalidCredentials
    case configurationError
    case phoneVerificationFailed
    case phoneCodeVerificationFailed
    case mfaEnrollmentFailed
    case mfaVerificationFailed
    case mfaRequired
    case sessionExpired
    case notAuthenticated
    case tooManyAttempts
    
    var errorDescription: String? {
        switch self {
        case .signInFailed:
            return AppStrings.ErrorMessages.authenticationError
        case .signOutFailed:
            return AppStrings.ErrorMessages.signOutError
        case .userNotFound:
            return AppStrings.ErrorMessages.userNotFound
        case .invalidCredentials:
            return AppStrings.ErrorMessages.invalidCredentials
        case .configurationError:
            return AppStrings.ErrorMessages.configurationError
        case .phoneVerificationFailed:
            return AppStrings.ErrorMessages.phoneVerificationError
        case .phoneCodeVerificationFailed:
            return AppStrings.ErrorMessages.phoneCodeVerificationError
        case .mfaEnrollmentFailed:
            return AppStrings.ErrorMessages.mfaEnrollmentError
        case .mfaVerificationFailed:
            return AppStrings.ErrorMessages.mfaVerificationError
        case .mfaRequired:
            return AppStrings.ErrorMessages.mfaRequiredError
        case .sessionExpired:
            return AppStrings.ErrorMessages.authenticationError
        case .notAuthenticated:
            return AppStrings.ErrorMessages.authenticationError
        case .tooManyAttempts:
            return AppStrings.ErrorMessages.authenticationError
        }
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError, Sendable {
    case noConnection
    case timeout
    case serverError
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noConnection, .timeout:
            return AppStrings.ErrorMessages.networkError
        case .serverError:
            return AppStrings.ErrorMessages.serverError
        case .invalidResponse:
            return AppStrings.ErrorMessages.serverError
        case .unauthorized:
            return AppStrings.ErrorMessages.authenticationError
        case .forbidden:
            return AppStrings.ErrorMessages.permissionDenied
        case .notFound:
            return AppStrings.ErrorMessages.dataError
        case .unknown:
            return AppStrings.ErrorMessages.genericError
        }
    }
}

// MARK: - Data Errors
enum DataError: LocalizedError, Sendable {
    case saveFailed
    case loadFailed
    case corruptedData
    case medicationNotFound
    case invalidDosageFormat
    case scheduleConflict
    case duplicateEntry
    case validationFailed
    case noData
    case unknown
    case conflictAnalysisFailed
    case cacheExpired
    case analysisTimeout
    case migrationFailed
    case invalidDate
    case dataRecovered
    case inMemoryOnly
    case storeNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .saveFailed, .loadFailed:
            return AppStrings.ErrorMessages.dataError
        case .corruptedData:
            return AppStrings.ErrorMessages.corruptedDataError
        case .medicationNotFound:
            return AppStrings.ErrorMessages.dataError
        case .invalidDosageFormat:
            return AppStrings.ErrorMessages.dataError
        case .scheduleConflict:
            return AppStrings.ErrorMessages.dataError
        case .duplicateEntry:
            return AppStrings.ErrorMessages.dataError
        case .validationFailed:
            return AppStrings.ErrorMessages.dataError
        case .noData:
            return AppStrings.ErrorMessages.dataError
        case .unknown:
            return AppStrings.ErrorMessages.genericError
        case .conflictAnalysisFailed:
            return AppStrings.ErrorMessages.conflictAnalysisError
        case .cacheExpired:
            return AppStrings.ErrorMessages.dataError
        case .analysisTimeout:
            return AppStrings.ErrorMessages.analysisTimeoutError
        case .migrationFailed:
            return AppStrings.ErrorMessages.dataError
        case .invalidDate:
            return AppStrings.ErrorMessages.dataError
        case .dataRecovered:
            return "Data has been recovered. Some information may be missing."
        case .inMemoryOnly:
            return "Working offline. Changes will be lost when app closes."
        case .storeNotAvailable:
            return "Local storage is unavailable. Please try again."
        }
    }
}

// MARK: - Voice Input Errors
enum VoiceError: LocalizedError, Sendable {
    case microphonePermissionDenied
    case speechRecognitionFailed
    case noSpeechDetected
    case speechRecognitionUnavailable
    case audioSessionError
    case transcriptionTimeout
    case invalidState
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return AppStrings.ErrorMessages.permissionDenied
        case .speechRecognitionFailed:
            return AppStrings.ErrorMessages.genericError
        case .noSpeechDetected:
            return AppStrings.ErrorMessages.genericError
        case .speechRecognitionUnavailable:
            return AppStrings.ErrorMessages.genericError
        case .audioSessionError:
            return AppStrings.ErrorMessages.genericError
        case .transcriptionTimeout:
            return AppStrings.ErrorMessages.genericError
        case .invalidState:
            return AppStrings.ErrorMessages.genericError
        }
    }
}

// MARK: - Voice Interaction Errors (for VoiceInteractionManager)
enum VoiceInteractionError: LocalizedError, Sendable {
    case permissionDenied
    case recordingFailed
    case transcriptionFailed
    case noSpeechDetected
    case microphoneUnavailable
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return AppStrings.Voice.permissionMessage
        case .recordingFailed:
            return AppStrings.ErrorMessages.genericError
        case .transcriptionFailed:
            return AppStrings.ErrorMessages.genericError
        case .noSpeechDetected:
            return AppStrings.Voice.noSpeechDetected
        case .microphoneUnavailable:
            return AppStrings.ErrorMessages.genericError
        }
    }
}

// MARK: - Sync Errors
enum SyncError: LocalizedError, Sendable {
    case firebaseConnectionFailed
    case coreDataError
    case syncTimeout
    case conflictResolutionFailed
    case dataInconsistency
    case offlineModeRequired
    case uploadFailed
    case downloadFailed
    case syncInProgress
    
    var errorDescription: String? {
        switch self {
        case .firebaseConnectionFailed:
            return AppStrings.ErrorMessages.networkError
        case .coreDataError:
            return AppStrings.ErrorMessages.dataError
        case .syncTimeout:
            return AppStrings.ErrorMessages.networkError
        case .conflictResolutionFailed:
            return AppStrings.ErrorMessages.dataError
        case .dataInconsistency:
            return AppStrings.ErrorMessages.corruptedDataError
        case .offlineModeRequired:
            return AppStrings.ErrorMessages.networkError
        case .uploadFailed:
            return AppStrings.ErrorMessages.networkError
        case .downloadFailed:
            return AppStrings.ErrorMessages.networkError
        case .syncInProgress:
            return "Sync is already in progress. Please wait."
        }
    }
}

// MARK: - Caregiver Errors
enum CaregiverError: LocalizedError, Sendable {
    case accessDenied
    case invitationFailed
    case maxCaregiversReached
    case invalidPermission
    case caregiverNotFound
    case qrCodeGenerationFailed
    case saveFailed
    case revokeFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return AppStrings.ErrorMessages.permissionDenied
        case .invitationFailed:
            return AppStrings.ErrorMessages.genericError
        case .maxCaregiversReached:
            return AppStrings.ErrorMessages.genericError
        case .invalidPermission:
            return AppStrings.ErrorMessages.permissionDenied
        case .caregiverNotFound:
            return AppStrings.ErrorMessages.dataError
        case .qrCodeGenerationFailed:
            return AppStrings.ErrorMessages.genericError
        case .saveFailed:
            return AppStrings.ErrorMessages.dataError
        case .revokeFailed:
            return AppStrings.ErrorMessages.dataError
        case .loadFailed:
            return AppStrings.ErrorMessages.dataError
        }
    }
}

// MARK: - Caregiver Access Error
enum CaregiverAccessError: LocalizedError, Sendable {
    case loadFailed, saveFailed, alreadyInvited, maxCaregiversReached
    case invitationFailed, invitationExpired, acceptFailed, declineFailed
    case revokeFailed, invalidInvitationCode
    
    var errorDescription: String? {
        switch self {
        case .loadFailed, .saveFailed:
            return AppStrings.ErrorMessages.dataError
        case .alreadyInvited:
            return AppStrings.ErrorMessages.genericError
        case .maxCaregiversReached:
            return AppStrings.ErrorMessages.genericError
        case .invitationFailed:
            return AppStrings.ErrorMessages.genericError
        case .invitationExpired:
            return AppStrings.ErrorMessages.genericError
        case .acceptFailed, .declineFailed:
            return AppStrings.ErrorMessages.dataError
        case .revokeFailed:
            return AppStrings.ErrorMessages.dataError
        case .invalidInvitationCode:
            return AppStrings.ErrorMessages.genericError
        }
    }
}

// MARK: - Subscription Errors
enum SubscriptionError: LocalizedError, Sendable {
    case subscriptionExpired
    case paymentFailed
    case productNotFound
    case restoreFailed
    case trialAlreadyUsed
    case refundProcessingError
    
    var errorDescription: String? {
        switch self {
        case .subscriptionExpired:
            return AppStrings.ErrorMessages.genericError
        case .paymentFailed:
            return AppStrings.ErrorMessages.genericError
        case .productNotFound:
            return AppStrings.ErrorMessages.genericError
        case .restoreFailed:
            return AppStrings.ErrorMessages.genericError
        case .trialAlreadyUsed:
            return AppStrings.ErrorMessages.genericError
        case .refundProcessingError:
            return AppStrings.ErrorMessages.genericError
        }
    }
}

// MARK: - Claude API Errors
enum ClaudeAPIError: LocalizedError, Sendable {
    case unauthorized
    case rateLimited
    case invalidResponse
    case networkTimeout
    case modelUnavailable
    case tokenLimitExceeded
    case apiKeyMissing
    case invalidRequest
    case serverError
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return AppStrings.ErrorMessages.claudeAPIUnauthorized
        case .rateLimited:
            return AppStrings.ErrorMessages.claudeAPIRateLimited
        case .invalidResponse:
            return AppStrings.ErrorMessages.claudeAPIInvalidResponse
        case .networkTimeout:
            return AppStrings.ErrorMessages.networkError
        case .modelUnavailable:
            return AppStrings.ErrorMessages.claudeAPIModelUnavailable
        case .tokenLimitExceeded:
            return AppStrings.ErrorMessages.claudeAPITokenLimit
        case .apiKeyMissing:
            return AppStrings.ErrorMessages.claudeAPIKeyMissing
        case .invalidRequest:
            return AppStrings.ErrorMessages.claudeAPIInvalidRequest
        case .serverError:
            return AppStrings.ErrorMessages.serverError
        case .parsingError:
            return AppStrings.ErrorMessages.claudeAPIParsingError
        }
    }
}

// MARK: - App Error Extension
extension AppError {
    // MARK: - Convenience Static Properties
    static var userNotAuthenticated: AppError {
        return .authentication(.notAuthenticated)
    }
    
    // MARK: - Retryable Errors
    var isRetryable: Bool {
        switch self {
        case .network:
            return true
        case .sync:
            return true
        case .data(let dataError):
            switch dataError {
            case .loadFailed, .cacheExpired, .analysisTimeout:
                return true
            default:
                return false
            }
        case .claudeAPI(let apiError):
            switch apiError {
            case .rateLimited, .networkTimeout, .serverError:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
