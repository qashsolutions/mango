//
//  ExtensionKeychain.swift
//  MedicationManagerKit
//
//  Created by Claude on 2025/01/14.
//  Copyright © 2025 MedicationManager. All rights reserved.
//

import Foundation
import Security

/// Thread-safe keychain manager for secure credential access from extensions
/// Implements Swift 6 Sendable compliance and comprehensive error handling
@available(iOS 18.0, *)
public final class ExtensionKeychain: Sendable {
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    public static let shared = ExtensionKeychain()
    
    /// Keychain access group identifier from Configuration
    private let keychainAccessGroup: String
    
    /// Service identifier prefix for keychain items
    private let servicePrefix: String
    
    /// Queue for thread-safe keychain operations
    private let keychainQueue = DispatchQueue(
        label: "com.medicationmanager.extension.keychain",
        qos: .userInitiated
    )
    
    // MARK: - Service Identifiers
    
    /// Service identifiers for different API keys
    private enum ServiceIdentifier: String {
        case claudeAPI = "com.medicationmanager.claudeAPIKey"
        case stripePublishable = "com.medicationmanager.stripePublishableKey"
        case firebaseAPI = "com.medicationmanager.firebaseAPIKey"
        
        /// Full service name with prefix
        func fullServiceName(prefix: String) -> String {
            return "\(prefix).\(self.rawValue)"
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Import Configuration values (assuming they're available in the framework)
        self.keychainAccessGroup = "$(AppIdentifierPrefix)com.medicationmanager.shared"
        self.servicePrefix = "extension"
    }
    
    // MARK: - Public API Methods
    
    /// Retrieves the Claude API key from the keychain
    /// - Throws: ExtensionError if key is not found or access fails
    /// - Returns: The Claude API key as a String
    public func getClaudeAPIKey() async throws -> String {
        try await getAPIKey(for: .claudeAPI, service: .claude)
    }
    
    /// Retrieves the Stripe publishable key from the keychain
    /// - Throws: ExtensionError if key is not found or access fails
    /// - Returns: The Stripe publishable key as a String
    public func getStripePublishableKey() async throws -> String {
        try await getAPIKey(for: .stripePublishable, service: .stripe)
    }
    
    /// Stores an API key in the keychain (used by main app)
    /// - Parameters:
    ///   - key: The API key to store
    ///   - service: The service type for the key
    /// - Throws: ExtensionError if storage fails
    public func setAPIKey(_ key: String, for service: APIService) async throws {
        let serviceIdentifier = serviceIdentifierFor(service)
        try await setKeychainValue(key, for: serviceIdentifier)
    }
    
    /// Checks if an API key exists in the keychain
    /// - Parameter service: The service to check
    /// - Returns: true if the key exists, false otherwise
    public func hasAPIKey(for service: APIService) async -> Bool {
        let serviceIdentifier = serviceIdentifierFor(service)
        
        return await withCheckedContinuation { continuation in
            keychainQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                let exists = self.keychainItemExists(service: serviceIdentifier)
                continuation.resume(returning: exists)
            }
        }
    }
    
    /// Removes an API key from the keychain
    /// - Parameter service: The service whose key should be removed
    /// - Throws: ExtensionError if removal fails
    public func removeAPIKey(for service: APIService) async throws {
        let serviceIdentifier = serviceIdentifierFor(service)
        try await removeKeychainItem(service: serviceIdentifier)
    }
    
    // MARK: - Private Helper Methods
    
    /// Maps APIService to ServiceIdentifier
    private func serviceIdentifierFor(_ service: APIService) -> ServiceIdentifier {
        switch service {
        case .claude:
            return .claudeAPI
        case .stripe:
            return .stripePublishable
        case .firebase:
            return .firebaseAPI
        }
    }
    
    /// Generic method to retrieve an API key
    private func getAPIKey(
        for identifier: ServiceIdentifier,
        service: APIService
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            keychainQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ExtensionError.appGroupNotConfigured(
                        identifier: "ExtensionKeychain deallocated"
                    ))
                    return
                }
                
                do {
                    let key = try self.retrieveKeychainValue(service: identifier)
                    continuation.resume(returning: key)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Retrieves a value from the keychain
    private func retrieveKeychainValue(service: ServiceIdentifier) throws -> String {
        // Build the query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.fullServiceName(prefix: servicePrefix),
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        // Attempt to retrieve the item
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Handle the result
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let string = String(data: data, encoding: .utf8) else {
                throw ExtensionError.keychainError(.invalidData)
            }
            return string
            
        case errSecItemNotFound:
            throw ExtensionError.apiKeyMissing(service: serviceFor(identifier: service))
            
        case errSecUserCanceled:
            throw ExtensionError.keychainError(.accessDenied)
            
        case errSecInteractionNotAllowed:
            throw ExtensionError.keychainError(.accessDenied)
            
        default:
            throw ExtensionError.keychainError(.unknown(status))
        }
    }
    
    /// Stores a value in the keychain
    private func setKeychainValue(_ value: String, for service: ServiceIdentifier) async throws {
        try await withCheckedThrowingContinuation { continuation in
            keychainQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ExtensionError.appGroupNotConfigured(
                        identifier: "ExtensionKeychain deallocated"
                    ))
                    return
                }
                
                do {
                    // Convert string to data
                    guard let data = value.data(using: .utf8) else {
                        throw ExtensionError.keychainError(.invalidData)
                    }
                    
                    // Build the attributes dictionary
                    let attributes: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrService as String: service.fullServiceName(prefix: self.servicePrefix),
                        kSecAttrAccessGroup as String: self.keychainAccessGroup,
                        kSecValueData as String: data,
                        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                        kSecAttrSynchronizable as String: false
                    ]
                    
                    // Try to add the item
                    var status = SecItemAdd(attributes as CFDictionary, nil)
                    
                    // If it already exists, update it
                    if status == errSecDuplicateItem {
                        let query: [String: Any] = [
                            kSecClass as String: kSecClassGenericPassword,
                            kSecAttrService as String: service.fullServiceName(prefix: self.servicePrefix),
                            kSecAttrAccessGroup as String: self.keychainAccessGroup
                        ]
                        
                        let updateAttributes: [String: Any] = [
                            kSecValueData as String: data
                        ]
                        
                        status = SecItemUpdate(
                            query as CFDictionary,
                            updateAttributes as CFDictionary
                        )
                    }
                    
                    // Check final status
                    if status == errSecSuccess {
                        continuation.resume()
                    } else {
                        throw ExtensionError.keychainError(.unknown(status))
                    }
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Checks if a keychain item exists
    private func keychainItemExists(service: ServiceIdentifier) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.fullServiceName(prefix: servicePrefix),
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Removes a keychain item
    private func removeKeychainItem(service: ServiceIdentifier) async throws {
        try await withCheckedThrowingContinuation { continuation in
            keychainQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ExtensionError.appGroupNotConfigured(
                        identifier: "ExtensionKeychain deallocated"
                    ))
                    return
                }
                
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service.fullServiceName(prefix: self.servicePrefix),
                    kSecAttrAccessGroup as String: self.keychainAccessGroup
                ]
                
                let status = SecItemDelete(query as CFDictionary)
                
                if status == errSecSuccess || status == errSecItemNotFound {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: ExtensionError.keychainError(.unknown(status)))
                }
            }
        }
    }
    
    /// Maps ServiceIdentifier to APIService
    private func serviceFor(identifier: ServiceIdentifier) -> APIService {
        switch identifier {
        case .claudeAPI:
            return .claude
        case .stripePublishable:
            return .stripe
        case .firebaseAPI:
            return .firebase
        }
    }
}

// MARK: - Convenience Methods

@available(iOS 18.0, *)
public extension ExtensionKeychain {
    
    /// Validates that all required API keys are present
    /// - Returns: Dictionary of service names and their availability status
    func validateAllKeys() async -> [String: Bool] {
        let services: [APIService] = [.claude, .stripe, .firebase]
        
        var results: [String: Bool] = [:]
        
        for service in services {
            results[service.rawValue] = await hasAPIKey(for: service)
        }
        
        return results
    }
    
    /// Retrieves all available API keys (for debugging purposes only)
    /// - Warning: Use with caution and never log the returned values
    /// - Returns: Dictionary of available services (keys not included for security)
    func availableServices() async -> [String] {
        let services: [APIService] = [.claude, .stripe, .firebase]
        
        var available: [String] = []
        
        for service in services {
            if await hasAPIKey(for: service) {
                available.append(service.rawValue)
            }
        }
        
        return available
    }
}

// MARK: - Migration Support

@available(iOS 18.0, *)
public extension ExtensionKeychain {
    
    /// Migrates API keys from old keychain format to new shared format
    /// Called by main app during update process
    func migrateFromLegacyKeychain() async throws {
        // Define legacy service names
        let legacyMappings: [(old: String, new: ServiceIdentifier)] = [
            ("claudeAPIKey", .claudeAPI),
            ("stripeKey", .stripePublishable),
            ("firebaseKey", .firebaseAPI)
        ]
        
        for mapping in legacyMappings {
            // Try to retrieve from old location
            let oldQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: mapping.old,
                kSecReturnData as String: true
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(oldQuery as CFDictionary, &result)
            
            if status == errSecSuccess,
               let data = result as? Data,
               let value = String(data: data, encoding: .utf8) {
                
                // Store in new location
                try await setKeychainValue(value, for: mapping.new)
                
                // Remove from old location
                SecItemDelete(oldQuery as CFDictionary)
            }
        }
    }
}