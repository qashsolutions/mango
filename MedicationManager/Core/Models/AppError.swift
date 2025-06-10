import Foundation

// MARK: - App Error Definitions
enum AppError: LocalizedError {
    case authentication(AuthError)
    case network(NetworkError)
    case data(DataError)
    case voice(VoiceError)
    case sync(SyncError)
    case caregiver(CaregiverError)
    case caregiverAccessError(CaregiverAccessError)
    case subscription(SubscriptionError)
    
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
        case .sync(let syncError):
            return syncError.localizedDescription
        case .caregiver(let caregiverError):
            return caregiverError.localizedDescription
        case .caregiverAccessError(let caregiverAccessError):
            return caregiverAccessError.localizedDescription
        case .subscription(let subscriptionError):
            return subscriptionError.localizedDescription
        }
    }
}

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
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
        }
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
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
enum DataError: LocalizedError {
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
        }
    }
}

// MARK: - Voice Input Errors
enum VoiceError: LocalizedError {
    case microphonePermissionDenied
    case speechRecognitionFailed
    case noSpeechDetected
    case speechRecognitionUnavailable
    case audioSessionError
    case transcriptionTimeout
    
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
        }
    }
}

// MARK: - Sync Errors
enum SyncError: LocalizedError {
    case firebaseConnectionFailed
    case coreDataError
    case syncTimeout
    case conflictResolutionFailed
    case dataInconsistency
    case offlineModeRequired
    case uploadFailed
    case downloadFailed
    
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
        }
    }
}

// MARK: - Caregiver Errors
enum CaregiverError: LocalizedError {
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
enum CaregiverAccessError: LocalizedError {
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
enum SubscriptionError: LocalizedError {
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
