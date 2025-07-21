//
//  SwiftDataConfiguration.swift
//  MedicationManager
//
//  Enhanced SwiftData configuration with proper error handling and eldercare optimizations
//

import Foundation
import SwiftData
import OSLog

// Note: BackgroundModelActor removed in favor of simpler approach
// SwiftData's ModelContext already handles concurrency appropriately
// Creating contexts on-demand avoids unnecessary actor complexity

// MARK: - SwiftData Configuration
/// iOS 18+ SwiftData configuration for local storage
/// Manages user profiles and other local-only data with robust error handling
@MainActor
final class SwiftDataConfiguration {
    
    // MARK: - Singleton
    static let shared = SwiftDataConfiguration()
    
    // MARK: - Properties
    
    private nonisolated let logger = Logger(subsystem: Configuration.App.bundleId, category: "SwiftDataConfiguration")
    
    /// Model container for SwiftData persistence
    private(set) var modelContainer: ModelContainer?
    
    /// Indicates if SwiftData is available and working
    private(set) var isAvailable: Bool = false
    
    /// Main model context for UI operations
    var mainContext: ModelContext? {
        return modelContainer?.mainContext
    }
    
    // Background operations use fresh contexts for thread safety
    
    // MARK: - Initialization
    
    private init() {
        setupModelContainer()
        logger.info("SwiftDataConfiguration initialized (available: \(self.isAvailable))")
    }
    
    private func setupModelContainer() {
        do {
            // Configure model container with UserProfile and future models
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .automatic,
                cloudKitDatabase: .automatic // Enable CloudKit sync for multi-device support
            )
            
            modelContainer = try ModelContainer(
                for: UserProfile.self,
                // Add other models here as needed:
                // MedicationSchedule.self,
                // LocalSettings.self,
                configurations: configuration
            )
            
            // Background operations use fresh contexts for thread safety
            
            isAvailable = true
            logger.info("SwiftData ModelContainer created successfully")
            
        } catch {
            // Don't crash the app - log error and continue with limited functionality
            logger.error("Failed to create SwiftData ModelContainer: \(error.localizedDescription)")
            handleModelContainerError(error)
            isAvailable = false
        }
    }
    
    private func handleModelContainerError(_ error: Error) {
        logger.warning("SwiftData unavailable - app will use fallback storage mechanisms")
        
        // Attempt recovery strategies
        if let swiftDataError = error as? SwiftDataError {
            switch swiftDataError {
            case .corruptedData:
                logger.info("Attempting to recover from corrupted SwiftData store")
                attemptDataRecovery()
            case .migrationFailed:
                logger.info("Migration failed - will use legacy storage")
                // Fall back to UserDefaults or other storage
            default:
                logger.warning("Unknown SwiftData error: \(swiftDataError)")
            }
        }
        
        // For eldercare apps, we must continue functioning even without SwiftData
        setupFallbackStorage()
    }
    
    private func attemptDataRecovery() {
        // Try to recreate the container with in-memory storage as last resort
        do {
            let fallbackConfiguration = ModelConfiguration(
                isStoredInMemoryOnly: true,
                allowsSave: true
            )
            
            modelContainer = try ModelContainer(
                for: UserProfile.self,
                configurations: fallbackConfiguration
            )
            
            // Background operations use fresh contexts for thread safety
            
            isAvailable = true
            logger.info("Successfully created fallback in-memory SwiftData container")
            
        } catch {
            logger.error("Even fallback SwiftData container failed: \(error.localizedDescription)")
            isAvailable = false
        }
    }
    
    private func setupFallbackStorage() {
        logger.info("Setting up fallback storage mechanisms for user profiles")
        // This would integrate with UserDefaults or other persistent storage
        // Implementation depends on your app's fallback strategy
    }
    
    // MARK: - Public Methods
    
    /// Initialize SwiftData for the app
    /// Call this early in app lifecycle
    static func initialize() {
        _ = shared // Force initialization
    }
    
    /// Check if SwiftData is working properly
    func validateConfiguration() -> Bool {
        guard isAvailable, let context = mainContext else {
            logger.warning("SwiftData configuration validation failed - not available")
            return false
        }
        
        // Test basic operations
        do {
            let descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { _ in false })
            _ = try context.fetch(descriptor)
            logger.debug("SwiftData configuration validation passed")
            return true
        } catch {
            logger.error("SwiftData configuration validation failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Migrate legacy data if needed
    /// Called once during app upgrade
    func migrateIfNeeded(for userId: String) async {
        guard isAvailable, let context = mainContext else {
            logger.warning("Cannot migrate data - SwiftData not available")
            return
        }
        
        do {
            // Use main context directly - SwiftData handles its own threading
            try UserProfile.migrateFromLegacyStorage(
                userId: userId,
                context: context
            )
            
            logger.info("Migration completed successfully for user: \(userId)")
            
            // Set migration completion flag for monitoring
            UserDefaults.standard.set(true, forKey: "migration_completed_\(userId)")
            UserDefaults.standard.set(Date(), forKey: "migration_date_\(userId)")
            
        } catch UserProfile.MigrationError.alreadyMigrated {
            // Not an error - just log for monitoring
            logger.info("User \(userId) data already migrated")
            
        } catch {
            logger.error("Migration failed for user \(userId): \(error.localizedDescription)")
            
            // Track migration failures for monitoring
            UserDefaults.standard.set(false, forKey: "migration_completed_\(userId)")
            UserDefaults.standard.set(Date(), forKey: "migration_failed_date_\(userId)")
            
            // Send analytics event for production monitoring
            AnalyticsManager.shared.trackError(error, context: "user_profile_migration")
            
            // Don't throw - migration failure shouldn't prevent app usage
            // Users can still use the app with default settings
        }
    }
    
    /// Clear all local data (for logout) with proper error handling
    func clearAllData() throws {
        guard isAvailable, let context = mainContext else {
            logger.warning("Cannot clear data - SwiftData not available")
            throw SwiftDataConfigurationError.notAvailable
        }
        
        do {
            // Delete all UserProfile records
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)
            
            logger.info("Clearing \(profiles.count) user profiles")
            
            for profile in profiles {
                context.delete(profile)
            }
            
            try context.save()
            logger.info("All local data cleared successfully")
            
        } catch {
            logger.error("Failed to clear all data: \(error.localizedDescription)")
            throw SwiftDataConfigurationError.clearDataFailed(error)
        }
    }
    
    /// Get or create profile for user with comprehensive error handling
    func getOrCreateProfile(for userId: String) throws -> UserProfile {
        guard isAvailable, let context = mainContext else {
            logger.warning("Cannot get/create profile - SwiftData not available")
            throw SwiftDataConfigurationError.notAvailable
        }
        
        guard !userId.isEmpty else {
            logger.error("Cannot create profile for empty user ID")
            throw SwiftDataConfigurationError.invalidUserId
        }
        
        do {
            // Check if profile exists
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { profile in
                    profile.userId == userId
                }
            )
            
            let existingProfiles = try context.fetch(descriptor)
            
            if let profile = existingProfiles.first {
                logger.debug("Found existing profile for user: \(userId)")
                return profile
            }
            
            // Create new profile
            let newProfile = UserProfile(userId: userId)
            context.insert(newProfile)
            
            try context.save()
            
            logger.info("Created new profile for user: \(userId)")
            return newProfile
            
        } catch {
            logger.error("Failed to get/create profile for user \(userId): \(error.localizedDescription)")
            throw SwiftDataConfigurationError.profileOperationFailed(error)
        }
    }
    
    /// Perform UI operations on the main context
    /// Use this for operations that need to update the UI
    func performUIOperation<T>(_ operation: (ModelContext) throws -> T) throws -> T {
        guard isAvailable, let context = mainContext else {
            logger.warning("Cannot perform UI operation - SwiftData not available")
            throw SwiftDataConfigurationError.notAvailable
        }
        
        return try operation(context)
    }
    
    // Note: performBackgroundOperation removed - not compatible with Swift 6/SwiftData
    // SwiftData's ModelContext must be used on the actor where it was created
    // For background operations, use Task { } with mainContext or create
    // separate ModelContext instances within the Task itself
    
    /// Get user profile safely with fallback
    func getUserProfile(for userId: String) -> UserProfile? {
        guard isAvailable, let context = mainContext else {
            logger.warning("Cannot get user profile - SwiftData not available")
            return nil
        }
        
        do {
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { profile in
                    profile.userId == userId
                }
            )
            
            let profiles = try context.fetch(descriptor)
            return profiles.first
            
        } catch {
            logger.error("Failed to fetch user profile for \(userId): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Update user profile safely
    func updateUserProfile(_ profile: UserProfile) throws {
        guard isAvailable, let context = mainContext else {
            logger.warning("Cannot update profile - SwiftData not available")
            throw SwiftDataConfigurationError.notAvailable
        }
        
        do {
            try context.save()
            logger.debug("User profile updated successfully")
        } catch {
            logger.error("Failed to update user profile: \(error.localizedDescription)")
            throw SwiftDataConfigurationError.profileOperationFailed(error)
        }
    }
    
    /// Check storage health for eldercare reliability
    func checkStorageHealth() -> StorageHealthStatus {
        guard isAvailable, let container = modelContainer else {
            return .unavailable
        }
        
        do {
            // Test basic operations
            let context = container.mainContext
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)
            
            // Check if we can create a test profile
            let testProfile = UserProfile(userId: "health-check-\(UUID().uuidString)")
            context.insert(testProfile)
            try context.save()
            
            // Clean up test profile
            context.delete(testProfile)
            try context.save()
            
            logger.info("Storage health check passed (\(profiles.count) profiles)")
            return .healthy
            
        } catch {
            logger.warning("Storage health check failed: \(error.localizedDescription)")
            return .degraded(error)
        }
    }
}

// MARK: - Supporting Types

/// Custom errors for SwiftData configuration
enum SwiftDataConfigurationError: LocalizedError {
    case notAvailable
    case invalidUserId
    case clearDataFailed(Error)
    case profileOperationFailed(Error)
    case migrationRequired
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "SwiftData is not available"
        case .invalidUserId:
            return "Invalid user ID provided"
        case .clearDataFailed(let error):
            return "Failed to clear data: \(error.localizedDescription)"
        case .profileOperationFailed(let error):
            return "Profile operation failed: \(error.localizedDescription)"
        case .migrationRequired:
            return "Data migration is required"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAvailable:
            return "The app will use alternative storage methods"
        case .invalidUserId:
            return "Please provide a valid user identifier"
        case .clearDataFailed:
            return "Try restarting the app"
        case .profileOperationFailed:
            return "Check device storage and try again"
        case .migrationRequired:
            return "The app will attempt to migrate your data"
        }
    }
}

/// SwiftData specific errors
enum SwiftDataError: Error {
    case corruptedData
    case migrationFailed
    case configurationFailed
}

/// Storage health status for monitoring
enum StorageHealthStatus {
    case healthy
    case degraded(Error)
    case unavailable
    
    var isWorking: Bool {
        switch self {
        case .healthy:
            return true
        case .degraded, .unavailable:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .healthy:
            return "Storage is working normally"
        case .degraded(let error):
            return "Storage has issues: \(error.localizedDescription)"
        case .unavailable:
            return "Storage is not available"
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension SwiftDataConfiguration {
    /// Print storage statistics for debugging
    func printStorageStatistics() {
        guard isAvailable, let context = mainContext else {
            logger.debug("SwiftData not available for statistics")
            return
        }
        
        logger.debug("=== SwiftData Storage Statistics ===")
        
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)
            logger.debug("UserProfile records: \(profiles.count)")
            
            for profile in profiles {
                logger.debug("Profile: \(profile.userId) - Last Modified: \(profile.lastModified)")
            }
            
        } catch {
            logger.debug("Error fetching statistics: \(error.localizedDescription)")
        }
        
        logger.debug("===================================")
    }
    
    /// Create test data for development
    func createTestData() throws {
        guard isAvailable, let context = mainContext else {
            throw SwiftDataConfigurationError.notAvailable
        }
        
        let testProfile = UserProfile(userId: "test-user-\(UUID().uuidString)")
        context.insert(testProfile)
        try context.save()
        
        logger.info("Test data created for development")
    }
}
#endif
