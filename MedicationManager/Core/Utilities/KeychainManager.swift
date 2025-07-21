import Foundation
import Security

// MARK: - Keychain Manager
@MainActor
final class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Key Types
    enum KeyType: String {
        case claudeAPI = "com.medicationmanager.claudeAPIKey"
        case stripePublishable = "com.medicationmanager.stripePublishableKey"
        case stripeSecret = "com.medicationmanager.stripeSecretKey"
        case databaseEncryption = "com.medicationmanager.databaseEncryptionKey"
    }
    
    // MARK: - Error Types
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }
    
    // MARK: - Public Methods
    
    /// Store API key securely in keychain
    func setAPIKey(_ key: String, for keyType: KeyType) throws {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyType.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Try to add the item
        var status = SecItemAdd(query as CFDictionary, nil)
        
        // If it already exists, update it
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keyType.rawValue
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Retrieve API key from keychain
    func getAPIKey(for keyType: KeyType) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyType.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Delete API key from keychain
    func deleteAPIKey(for keyType: KeyType) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyType.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Check if API key exists
    func hasAPIKey(for keyType: KeyType) -> Bool {
        return getAPIKey(for: keyType) != nil
    }
    
    /// Clear all stored keys (use with caution)
    func clearAllKeys() throws {
        let keyTypes: [KeyType] = [.claudeAPI, .stripePublishable, .stripeSecret, .databaseEncryption]
        
        for keyType in keyTypes {
            try? deleteAPIKey(for: keyType)
        }
    }
    
    // MARK: - Development Helpers
    
    #if DEBUG
    /// Initialize with development API key
    func setupDevelopmentKeys() {
        // In DEBUG mode, you can set a development key
        // This should be replaced with actual key management in production
        print("⚠️ KeychainManager: Development mode - API keys should be set manually")
    }
    #endif
}

// MARK: - Convenience Extensions
extension KeychainManager {
    /// Get Claude API key with validation
    func getClaudeAPIKey() throws -> String {
        guard let apiKey = getAPIKey(for: .claudeAPI) else {
            throw AppError.claudeAPI(.apiKeyMissing)
        }
        
        // Basic validation
        guard !apiKey.isEmpty else {
            throw AppError.claudeAPI(.apiKeyMissing)
        }
        
        return apiKey
    }
    
    /// Check if Claude API is configured
    var isClaudeAPIConfigured: Bool {
        return hasAPIKey(for: .claudeAPI)
    }
    
    /// Get or create database encryption key
    func getDatabaseEncryptionKey() -> String {
        // Check if key already exists
        if let existingKey = getAPIKey(for: .databaseEncryption) {
            return existingKey
        }
        
        // Generate new secure key
        let newKey = generateSecureDatabaseKey()
        
        // Store it (ignore errors as we'll return the generated key anyway)
        try? setAPIKey(newKey, for: .databaseEncryption)
        
        return newKey
    }
    
    /// Generate a secure database encryption key
    private func generateSecureDatabaseKey() -> String {
        // Generate 32 bytes (256 bits) of random data for AES-256
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            // Fallback to UUID-based key if SecRandom fails
            return UUID().uuidString + UUID().uuidString
        }
        
        // Convert to hex string for storage
        return keyData.map { String(format: "%02hhx", $0) }.joined()
    }
}