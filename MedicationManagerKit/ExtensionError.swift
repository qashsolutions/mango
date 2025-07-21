//
//  ExtensionError.swift
//  MedicationManagerKit
//
//  Created by Claude on 2025/01/14.
//  Copyright © 2025 MedicationManager. All rights reserved.
//

import Foundation

/// Comprehensive error types for extension operations with detailed context
/// Swift 6 compliant with Sendable conformance for cross-actor usage
@available(iOS 18.0, *)
public enum ExtensionError: LocalizedError, Sendable {
    
    // MARK: - Authentication & Authorization Errors
    
    /// User is not authenticated or session has expired
    case userNotAuthenticated(reason: AuthenticationFailureReason)
    
    /// API key is missing or invalid
    case apiKeyMissing(service: APIService)
    
    /// Insufficient permissions for requested operation
    case insufficientPermissions(operation: String, requiredPermission: String)
    
    // MARK: - Data Access Errors
    
    /// Core Data fetch operation failed
    case dataFetchFailed(entity: String, underlyingError: Error?)
    
    /// No data found for the requested query
    case dataNotFound(query: String, filters: [String: Any])
    
    /// Data corruption detected
    case dataCorrupted(entity: String, recordId: String?)
    
    // MARK: - Network & API Errors
    
    /// Network request failed
    case networkError(NetworkErrorType)
    
    /// API response was invalid or unexpected
    case invalidAPIResponse(statusCode: Int?, responseBody: String?)
    
    /// API rate limit exceeded
    case rateLimitExceeded(retryAfter: TimeInterval?)
    
    // MARK: - Extension-Specific Errors
    
    /// Extension memory limit exceeded
    case memoryLimitExceeded(currentUsageMB: Int, limitMB: Int)
    
    /// Extension runtime timeout
    case extensionTimeout(operation: String, timeoutSeconds: Double)
    
    /// App group not configured properly
    case appGroupNotConfigured(identifier: String)
    
    // MARK: - Siri Intent Errors
    
    /// Intent parameter validation failed
    case invalidIntentParameter(parameter: String, value: String?, reason: String)
    
    /// Intent execution failed
    case intentExecutionFailed(intentName: String, underlyingError: Error?)
    
    /// Speech recognition error
    case speechRecognitionFailed(reason: SpeechRecognitionFailureReason)
    
    // MARK: - Keychain Errors
    
    /// Keychain access failed
    case keychainError(KeychainErrorType)
    
    // MARK: - Medication-Specific Errors
    
    /// Invalid medication data
    case invalidMedication(field: String, value: String?, validationRule: String)
    
    /// Medication conflict detected
    case medicationConflict(medication1: String, medication2: String, severity: String)
    
    // MARK: - Error Details
    
    public var errorDescription: String? {
        switch self {
        case .userNotAuthenticated(let reason):
            return "Authentication failed: \(reason.localizedDescription)"
            
        case .apiKeyMissing(let service):
            return "\(service.rawValue) API key is missing. Please configure in app settings."
            
        case .insufficientPermissions(let operation, let requiredPermission):
            return "Cannot perform '\(operation)'. Required permission: \(requiredPermission)"
            
        case .dataFetchFailed(let entity, let underlyingError):
            let errorDetail = underlyingError?.localizedDescription ?? "Unknown error"
            return "Failed to fetch \(entity) data: \(errorDetail)"
            
        case .dataNotFound(let query, let filters):
            let filterDescription = filters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return "No data found for query '\(query)' with filters: \(filterDescription)"
            
        case .dataCorrupted(let entity, let recordId):
            let recordInfo = recordId ?? "unknown record"
            return "Data corruption detected in \(entity) for \(recordInfo)"
            
        case .networkError(let type):
            return type.localizedDescription
            
        case .invalidAPIResponse(let statusCode, let responseBody):
            let status = statusCode != nil ? "Status: \(statusCode!)" : "Unknown status"
            let body = responseBody ?? "No response body"
            return "Invalid API response. \(status). Body: \(body)"
            
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "API rate limit exceeded. Retry after \(Int(retryAfter)) seconds."
            }
            return "API rate limit exceeded. Please try again later."
            
        case .memoryLimitExceeded(let currentUsageMB, let limitMB):
            return "Memory limit exceeded: Using \(currentUsageMB)MB of \(limitMB)MB allowed"
            
        case .extensionTimeout(let operation, let timeoutSeconds):
            return "Operation '\(operation)' timed out after \(Int(timeoutSeconds)) seconds"
            
        case .appGroupNotConfigured(let identifier):
            return "App group '\(identifier)' is not properly configured"
            
        case .invalidIntentParameter(let parameter, let value, let reason):
            let valueInfo = value ?? "nil"
            return "Invalid intent parameter '\(parameter)' with value '\(valueInfo)': \(reason)"
            
        case .intentExecutionFailed(let intentName, let underlyingError):
            let errorDetail = underlyingError?.localizedDescription ?? "Unknown error"
            return "Failed to execute intent '\(intentName)': \(errorDetail)"
            
        case .speechRecognitionFailed(let reason):
            return "Speech recognition failed: \(reason.localizedDescription)"
            
        case .keychainError(let type):
            return "Keychain error: \(type.localizedDescription)"
            
        case .invalidMedication(let field, let value, let validationRule):
            let valueInfo = value ?? "empty"
            return "Invalid medication \(field): '\(valueInfo)'. \(validationRule)"
            
        case .medicationConflict(let medication1, let medication2, let severity):
            return "\(severity) conflict detected between \(medication1) and \(medication2)"
        }
    }
    
    public var failureReason: String? {
        errorDescription
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .userNotAuthenticated:
            return "Please sign in to the main app first."
            
        case .apiKeyMissing:
            return "Open the main app and ensure API keys are configured in Settings."
            
        case .insufficientPermissions:
            return "Request the necessary permissions from your account administrator."
            
        case .dataFetchFailed:
            return "Try closing and reopening the app. If the problem persists, reinstall the app."
            
        case .dataNotFound:
            return "Ensure you have added medications in the main app first."
            
        case .dataCorrupted:
            return "Data recovery may be needed. Please contact support."
            
        case .networkError:
            return "Check your internet connection and try again."
            
        case .invalidAPIResponse:
            return "The service may be temporarily unavailable. Please try again later."
            
        case .rateLimitExceeded:
            return "You've made too many requests. Please wait before trying again."
            
        case .memoryLimitExceeded:
            return "Close other apps and try again."
            
        case .extensionTimeout:
            return "The operation took too long. Try with fewer items or simpler queries."
            
        case .appGroupNotConfigured:
            return "Reinstall the app to fix configuration issues."
            
        case .invalidIntentParameter:
            return "Please rephrase your request with valid information."
            
        case .intentExecutionFailed:
            return "Try opening the main app to complete this action."
            
        case .speechRecognitionFailed:
            return "Speak clearly and try again, or use text input instead."
            
        case .keychainError:
            return "Sign out and sign back in to refresh credentials."
            
        case .invalidMedication:
            return "Check the medication details and try again."
            
        case .medicationConflict:
            return "Consult your healthcare provider about this interaction."
        }
    }
}

// MARK: - Supporting Types

/// Reasons for authentication failure
@available(iOS 18.0, *)
public enum AuthenticationFailureReason: String, LocalizedError, Sendable {
    case sessionExpired = "Session has expired"
    case userNotFound = "User account not found"
    case invalidCredentials = "Invalid credentials"
    case accountLocked = "Account is locked"
    case networkUnavailable = "Network unavailable for authentication"
    
    public var errorDescription: String? { rawValue }
}

/// API services that require keys
@available(iOS 18.0, *)
public enum APIService: String, Sendable {
    case claude = "Claude AI"
    case stripe = "Stripe Payment"
    case firebase = "Firebase"
    
    public var configurationKey: String {
        switch self {
        case .claude: return "CLAUDE_API_KEY"
        case .stripe: return "STRIPE_PUBLISHABLE_KEY"
        case .firebase: return "FIREBASE_API_KEY"
        }
    }
}

/// Types of network errors
@available(iOS 18.0, *)
public enum NetworkErrorType: LocalizedError, Sendable {
    case noInternet
    case timeout(seconds: TimeInterval)
    case serverError(statusCode: Int)
    case sslError
    case unknown(Error?)
    
    public var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection available"
        case .timeout(let seconds):
            return "Request timed out after \(Int(seconds)) seconds"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .sslError:
            return "Secure connection failed"
        case .unknown(let error):
            return error?.localizedDescription ?? "Unknown network error"
        }
    }
}

/// Speech recognition failure reasons
@available(iOS 18.0, *)
public enum SpeechRecognitionFailureReason: String, LocalizedError, Sendable {
    case noSpeechDetected = "No speech was detected"
    case languageNotSupported = "Language not supported"
    case microphoneAccessDenied = "Microphone access denied"
    case recognizerUnavailable = "Speech recognizer unavailable"
    case audioSessionError = "Audio session configuration error"
    
    public var errorDescription: String? { rawValue }
}

/// Keychain-specific errors
@available(iOS 18.0, *)
public enum KeychainErrorType: LocalizedError, Sendable {
    case itemNotFound
    case duplicateItem
    case invalidData
    case accessDenied
    case unknown(OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Keychain item not found"
        case .duplicateItem:
            return "Keychain item already exists"
        case .invalidData:
            return "Invalid data in keychain"
        case .accessDenied:
            return "Keychain access denied"
        case .unknown(let status):
            return "Keychain error with status: \(status)"
        }
    }
}

// MARK: - Error Code Mapping

@available(iOS 18.0, *)
public extension ExtensionError {
    /// Maps error to a numeric code for analytics
    var errorCode: Int {
        switch self {
        case .userNotAuthenticated: return 1001
        case .apiKeyMissing: return 1002
        case .insufficientPermissions: return 1003
        case .dataFetchFailed: return 2001
        case .dataNotFound: return 2002
        case .dataCorrupted: return 2003
        case .networkError: return 3001
        case .invalidAPIResponse: return 3002
        case .rateLimitExceeded: return 3003
        case .memoryLimitExceeded: return 4001
        case .extensionTimeout: return 4002
        case .appGroupNotConfigured: return 4003
        case .invalidIntentParameter: return 5001
        case .intentExecutionFailed: return 5002
        case .speechRecognitionFailed: return 5003
        case .keychainError: return 6001
        case .invalidMedication: return 7001
        case .medicationConflict: return 7002
        }
    }
    
    /// Severity level for error tracking
    var severity: ErrorSeverity {
        switch self {
        case .userNotAuthenticated, .apiKeyMissing, .appGroupNotConfigured:
            return .critical
        case .dataCorrupted, .keychainError:
            return .high
        case .networkError, .invalidAPIResponse, .dataFetchFailed:
            return .medium
        case .dataNotFound, .invalidIntentParameter, .speechRecognitionFailed:
            return .low
        default:
            return .medium
        }
    }
}

/// Error severity levels
@available(iOS 18.0, *)
public enum ErrorSeverity: String, Sendable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}