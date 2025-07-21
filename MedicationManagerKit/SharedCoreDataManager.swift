//
//  SharedCoreDataManager.swift
//  MedicationManagerKit
//
//  Enhanced with comprehensive error handling and eldercare optimizations
//  Copyright © 2025 MedicationManager. All rights reserved.
//

import CoreData
import Foundation
import OSLog
import UIKit

/// Thread-safe Core Data manager for accessing shared data from extensions
/// Uses App Groups for data sharing and implements Swift 6 actor model with robust error handling
@available(iOS 18.0, *)
public actor SharedCoreDataManager {
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    public static let shared = SharedCoreDataManager()
    
    /// Core Data persistent container (optional for graceful fallback)
    private var container: NSPersistentContainer?
    
    /// App group container URL
    private let appGroupURL: URL?
    
    /// Logger for debugging
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "SharedCoreDataManager")
    
    /// Memory warning observer
    private var memoryWarningObserver: NSObjectProtocol?
    
    /// Current memory usage tracking
    private var currentMemoryUsage: Int = 0
    
    /// Indicates if the shared manager is available
    private(set) var isAvailable: Bool = false
    
    /// Store loading error for diagnostics
    private var lastError: Error?
    
    // MARK: - Initialization
    
    private init() {
        // Safely get App Group container URL
        self.appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Configuration.Extensions.appGroupIdentifier
        )
        
        if appGroupURL == nil {
            logger.error("App Group \(Configuration.Extensions.appGroupIdentifier) not configured properly")
            isAvailable = false
            return
        }
        
        // Initialize Core Data stack with error handling
        setupCoreDataStack()
        
        // Set up memory warning observer
        setupMemoryWarningObserver()
        
        logger.info("SharedCoreDataManager initialized (available: \(self.isAvailable))")
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Core Data Setup
    
    private func setupCoreDataStack() {
        guard let groupURL = appGroupURL else {
            logger.error("Cannot setup Core Data stack - App Group URL not available")
            isAvailable = false
            return
        }
        
        let storeURL = groupURL.appendingPathComponent(Configuration.Extensions.CoreData.sqliteFilename)
        
        // Safely load the model
        guard let modelURL = Bundle.main.url(forResource: Configuration.CoreData.modelName, withExtension: "momd") else {
            logger.error("Failed to find Core Data model URL")
            isAvailable = false
            return
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            logger.error("Failed to load Core Data model from: \(modelURL)")
            isAvailable = false
            return
        }
        
        // Create container
        let newContainer = NSPersistentContainer(name: Configuration.CoreData.modelName, managedObjectModel: model)
        
        // Configure persistent store with comprehensive error handling
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        setupStoreDescription(storeDescription)
        
        newContainer.persistentStoreDescriptions = [storeDescription]
        
        // Load persistent stores with error handling
        loadPersistentStores(container: newContainer, storeURL: storeURL)
    }
    
    private func setupStoreDescription(_ storeDescription: NSPersistentStoreDescription) {
        // Enable persistent history tracking for sync
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Configure for extension access
        storeDescription.shouldAddStoreAsynchronously = false
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        // Configure for SQLite with proper read access
        storeDescription.type = NSSQLiteStoreType
        storeDescription.setOption("WAL" as NSString, forKey: NSSQLitePragmasOption)
        
        logger.debug("Store description configured for shared access")
    }
    
    private func loadPersistentStores(container: NSPersistentContainer, storeURL: URL) {
        var loadError: Error?
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        container.loadPersistentStores { [weak self] storeDescription, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                loadError = error
                self?.logger.error("Failed to load Core Data store: \(error.localizedDescription)")
                self?.lastError = error
            } else {
                self?.logger.info("Core Data store loaded successfully at: \(storeURL.path)")
            }
        }
        
        dispatchGroup.wait()
        
        if let error = loadError {
            handleStoreLoadError(error, storeURL: storeURL)
        } else {
            // Successfully loaded
            self.container = container
            configureViewContext(container)
            isAvailable = true
        }
    }
    
    private func handleStoreLoadError(_ error: Error, storeURL: URL) {
        logger.warning("Attempting to recover from store load error")
        
        // Attempt recovery strategies
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSMigrationMissingSourceModelError, NSMigrationError:
                logger.info("Migration error detected - attempting store reset")
                attemptStoreReset(storeURL: storeURL)
            case NSFileReadCorruptionError, NSSQLiteError:
                logger.info("Corruption detected - attempting store recovery")
                attemptStoreRecovery(storeURL: storeURL)
            default:
                logger.warning("Unknown Core Data error - using fallback mode")
                setupFallbackMode()
            }
        } else {
            setupFallbackMode()
        }
    }
    
    private func attemptStoreReset(storeURL: URL) {
        do {
            // Remove corrupted store files
            try removeStoreFiles(at: storeURL)
            
            // Try to reload
            setupCoreDataStack()
            
            if isAvailable {
                logger.info("Store reset successful")
            } else {
                setupFallbackMode()
            }
        } catch {
            logger.error("Store reset failed: \(error.localizedDescription)")
            setupFallbackMode()
        }
    }
    
    private func attemptStoreRecovery(storeURL: URL) {
        // For now, treat the same as reset
        // In a production app, you might attempt more sophisticated recovery
        attemptStoreReset(storeURL: storeURL)
    }
    
    private func removeStoreFiles(at storeURL: URL) throws {
        let fileManager = FileManager.default
        
        // Remove main store file
        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.removeItem(at: storeURL)
        }
        
        // Remove associated files
        let walURL = storeURL.appendingPathExtension("wal")
        let shmURL = storeURL.appendingPathExtension("shm")
        
        if fileManager.fileExists(atPath: walURL.path) {
            try fileManager.removeItem(at: walURL)
        }
        
        if fileManager.fileExists(atPath: shmURL.path) {
            try fileManager.removeItem(at: shmURL)
        }
        
        logger.debug("Removed corrupted store files")
    }
    
    private func setupFallbackMode() {
        logger.warning("Setting up fallback mode - limited functionality available")
        isAvailable = false
        container = nil
        // Extensions will need to handle this gracefully
    }
    
    private func configureViewContext(_ container: NSPersistentContainer) {
        let context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.shouldDeleteInaccessibleFaults = true
        
        // Configure for read-only access in extensions
        context.stalenessInterval = 0.0
        context.mergePolicy = NSErrorMergePolicy // Don't auto-resolve conflicts in extensions
        
        logger.debug("View context configured for extension access")
    }
    
    // MARK: - Public Methods - Status
    
    /// Check if the shared manager is available and working
    public var status: SharedDataStatus {
        guard isAvailable, let container = container else {
            if let error = lastError {
                return .unavailable(error)
            }
            return .unavailable(AppError.data(.storeNotAvailable))
        }
        
        // Test basic functionality
        do {
            let context = container.viewContext
            let request = NSFetchRequest<NSManagedObject>(entityName: Configuration.CoreData.medicationEntity)
            request.fetchLimit = 1
            _ = try context.fetch(request)
            return .available
        } catch {
            return .degraded(error)
        }
    }
    
    // MARK: - Public Methods - Medications
    
    /// Fetch medications for a specific user
    /// - Parameters:
    ///   - userId: The user ID to fetch medications for
    ///   - isActive: Filter for active medications only (default: true)
    ///   - limit: Maximum number of results (default: 50 for memory efficiency)
    /// - Returns: Array of SendableMedication objects
    public func fetchMedications(
        for userId: String,
        isActive: Bool = true,
        limit: Int = Configuration.Extensions.MemoryLimits.maxFetchBatchSize
    ) async throws -> [SendableMedication] {
        
        guard let container = container, isAvailable else {
            logger.warning("Cannot fetch medications - shared manager not available")
            throw AppError.data(.storeNotAvailable)
        }
        
        guard !userId.isEmpty else {
            logger.error("Cannot fetch medications for empty user ID")
            throw AppError.data(.validationFailed)
        }
        
        try checkMemoryLimit()
        
        return try await withCheckedThrowingContinuation { continuation in
            container.viewContext.perform { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: AppError.data(.storeNotAvailable))
                    return
                }
                
                do {
                    let request = NSFetchRequest<NSManagedObject>(entityName: Configuration.CoreData.medicationEntity)
                    
                    // Build predicate safely
                    var predicates = [NSPredicate(format: "userId == %@", userId)]
                    if isActive {
                        predicates.append(NSPredicate(format: "isActive == true"))
                    }
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                    
                    // Set fetch limit for memory efficiency
                    request.fetchLimit = limit
                    
                    // Sort by name
                    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                    
                    // Fetch only required properties for memory efficiency
                    request.propertiesToFetch = [
                        "id", "userId", "name", "genericName", "dosage", "dosageUnit",
                        "frequency", "scheduledTimes", "isActive", "instructions",
                        "purpose", "startDate", "endDate", "doctorId", "lastModified"
                    ]
                    
                    let results = try container.viewContext.fetch(request)
                    
                    // Convert to Sendable models
                    let medications = results.compactMap { object in
                        self.convertToSendableMedication(from: object)
                    }
                    
                    self.logger.debug("Successfully fetched \(medications.count) medications for user: \(userId)")
                    continuation.resume(returning: medications)
                    
                } catch {
                    self.logger.error("Failed to fetch medications: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    /// Fetch medications for a specific meal time
    public func fetchMedicationsForMealTime(
        _ mealTime: MealTime,
        userId: String
    ) async throws -> [SendableMedication] {
        
        let allMedications = try await fetchMedications(for: userId)
        return allMedications.filter { medication in
            medication.scheduledTimes.contains { scheduledTime in
                scheduledTime.mealTime == mealTime
            }
        }
    }
    
    // MARK: - Public Methods - Supplements
    
    /// Fetch supplements for a specific user
    public func fetchSupplements(
        for userId: String,
        isActive: Bool = true,
        limit: Int = Configuration.Extensions.MemoryLimits.maxFetchBatchSize
    ) async throws -> [SendableSupplement] {
        
        guard let container = container, isAvailable else {
            logger.warning("Cannot fetch supplements - shared manager not available")
            throw AppError.data(.storeNotAvailable)
        }
        
        guard !userId.isEmpty else {
            logger.error("Cannot fetch supplements for empty user ID")
            throw AppError.data(.validationFailed)
        }
        
        try checkMemoryLimit()
        
        return try await withCheckedThrowingContinuation { continuation in
            container.viewContext.perform { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: AppError.data(.storeNotAvailable))
                    return
                }
                
                do {
                    let request = NSFetchRequest<NSManagedObject>(entityName: Configuration.CoreData.supplementEntity)
                    
                    // Build predicate safely
                    var predicates = [NSPredicate(format: "userId == %@", userId)]
                    if isActive {
                        predicates.append(NSPredicate(format: "isActive == true"))
                    }
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                    
                    // Set fetch limit
                    request.fetchLimit = limit
                    
                    // Sort by name
                    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                    
                    let results = try container.viewContext.fetch(request)
                    
                    // Convert to Sendable models
                    let supplements = results.compactMap { object in
                        self.convertToSendableSupplement(from: object)
                    }
                    
                    self.logger.debug("Successfully fetched \(supplements.count) supplements for user: \(userId)")
                    continuation.resume(returning: supplements)
                    
                } catch {
                    self.logger.error("Failed to fetch supplements: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    /// Fetch supplements for a specific meal time
    public func fetchSupplementsForMealTime(
        _ mealTime: MealTime,
        userId: String
    ) async throws -> [SendableSupplement] {
        
        let allSupplements = try await fetchSupplements(for: userId)
        return allSupplements.filter { supplement in
            supplement.scheduledTimes.contains { scheduledTime in
                scheduledTime.mealTime == mealTime
            }
        }
    }
    
    // MARK: - Public Methods - Combined
    
    /// Fetch all medications and supplements for conflict checking
    public func fetchAllMedicationsAndSupplements(
        for userId: String
    ) async throws -> (medications: [SendableMedication], supplements: [SendableSupplement]) {
        
        // Fetch in parallel for efficiency
        async let medications = fetchMedications(for: userId)
        async let supplements = fetchSupplements(for: userId)
        
        return try await (medications, supplements)
    }
    
    // MARK: - Public Methods - Search
    
    /// Search medications by name
    public func searchMedications(
        query: String,
        userId: String
    ) async throws -> [SendableMedication] {
        
        guard let container = container, isAvailable else {
            throw AppError.data(.storeNotAvailable)
        }
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        guard !userId.isEmpty else {
            throw AppError.data(.validationFailed)
        }
        
        try checkMemoryLimit()
        
        return try await withCheckedThrowingContinuation { continuation in
            container.viewContext.perform { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: AppError.data(.storeNotAvailable))
                    return
                }
                
                do {
                    let request = NSFetchRequest<NSManagedObject>(entityName: Configuration.CoreData.medicationEntity)
                    
                    // Search predicate with safe string handling
                    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                    let searchPredicate = NSPredicate(
                        format: "userId == %@ AND (name CONTAINS[cd] %@ OR genericName CONTAINS[cd] %@ OR purpose CONTAINS[cd] %@)",
                        userId, trimmedQuery, trimmedQuery, trimmedQuery
                    )
                    request.predicate = searchPredicate
                    request.fetchLimit = 20 // Limit search results for memory efficiency
                    
                    let results = try container.viewContext.fetch(request)
                    let medications = results.compactMap { self.convertToSendableMedication(from: $0) }
                    
                    self.logger.debug("Search for '\(trimmedQuery)' returned \(medications.count) results")
                    continuation.resume(returning: medications)
                    
                } catch {
                    self.logger.error("Search failed: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Convert NSManagedObject to SendableMedication with comprehensive error handling
    private func convertToSendableMedication(from object: NSManagedObject) -> SendableMedication? {
        // Safely extract required fields
        guard let id = object.value(forKey: "id") as? String,
              let userId = object.value(forKey: "userId") as? String,
              let name = object.value(forKey: "name") as? String,
              let dosage = object.value(forKey: "dosage") as? String else {
            logger.warning("Failed to convert NSManagedObject to SendableMedication - missing required fields")
            return nil
        }
        
        // Safely extract optional enums with fallbacks
        let dosageUnitString = object.value(forKey: "dosageUnit") as? String ?? "mg"
        let dosageUnit = DosageUnit(rawValue: dosageUnitString) ?? .mg
        
        let frequencyString = object.value(forKey: "frequency") as? String ?? "once_daily"
        let frequency = MedicationFrequency(rawValue: frequencyString) ?? .onceDaily
        
        // Parse scheduled times safely
        let scheduledTimes: [ScheduledTime]
        if let timesData = object.value(forKey: "scheduledTimes") as? Data {
            do {
                scheduledTimes = try JSONDecoder().decode([ScheduledTime].self, from: timesData)
            } catch {
                logger.warning("Failed to decode scheduled times: \(error.localizedDescription)")
                scheduledTimes = []
            }
        } else {
            scheduledTimes = []
        }
        
        return SendableMedication(
            id: id,
            userId: userId,
            name: name,
            genericName: object.value(forKey: "genericName") as? String,
            dosage: dosage,
            dosageUnit: dosageUnit,
            frequency: frequency,
            scheduledTimes: scheduledTimes,
            isActive: object.value(forKey: "isActive") as? Bool ?? true,
            instructions: object.value(forKey: "instructions") as? String,
            purpose: object.value(forKey: "purpose") as? String,
            startDate: object.value(forKey: "startDate") as? Date ?? Date(),
            endDate: object.value(forKey: "endDate") as? Date,
            doctorId: object.value(forKey: "doctorId") as? String,
            lastModified: object.value(forKey: "lastModified") as? Date ?? Date(),
            syncStatus: .synced
        )
    }
    
    /// Convert NSManagedObject to SendableSupplement with comprehensive error handling
    private func convertToSendableSupplement(from object: NSManagedObject) -> SendableSupplement? {
        // Safely extract required fields
        guard let id = object.value(forKey: "id") as? String,
              let userId = object.value(forKey: "userId") as? String,
              let name = object.value(forKey: "name") as? String,
              let dosage = object.value(forKey: "dosage") as? String else {
            logger.warning("Failed to convert NSManagedObject to SendableSupplement - missing required fields")
            return nil
        }
        
        // Safely extract optional enums with fallbacks
        let dosageUnitString = object.value(forKey: "dosageUnit") as? String ?? "mg"
        let dosageUnit = SupplementDosageUnit(rawValue: dosageUnitString) ?? .mg
        
        let formString = object.value(forKey: "form") as? String ?? "tablet"
        let form = SupplementForm(rawValue: formString) ?? .tablet
        
        let frequencyString = object.value(forKey: "frequency") as? String ?? "once_daily"
        let frequency = SupplementFrequency(rawValue: frequencyString) ?? .onceDaily
        
        let categoryString = object.value(forKey: "category") as? String ?? "vitamin"
        let category = SupplementCategory(rawValue: categoryString) ?? .vitamin
        
        // Parse scheduled times safely
        let scheduledTimes: [ScheduledTime]
        if let timesData = object.value(forKey: "scheduledTimes") as? Data {
            do {
                scheduledTimes = try JSONDecoder().decode([ScheduledTime].self, from: timesData)
            } catch {
                logger.warning("Failed to decode supplement scheduled times: \(error.localizedDescription)")
                scheduledTimes = []
            }
        } else {
            scheduledTimes = []
        }
        
        return SendableSupplement(
            id: id,
            userId: userId,
            name: name,
            brand: object.value(forKey: "brand") as? String,
            dosage: dosage,
            dosageUnit: dosageUnit,
            form: form,
            frequency: frequency,
            scheduledTimes: scheduledTimes,
            isActive: object.value(forKey: "isActive") as? Bool ?? true,
            instructions: object.value(forKey: "instructions") as? String,
            purpose: object.value(forKey: "purpose") as? String,
            category: category,
            startDate: object.value(forKey: "startDate") as? Date ?? Date(),
            endDate: object.value(forKey: "endDate") as? Date,
            withFood: object.value(forKey: "withFood") as? Bool ?? false,
            lastModified: object.value(forKey: "lastModified") as? Date ?? Date(),
            syncStatus: .synced
        )
    }
    
    // MARK: - Memory Management
    
    /// Check current memory usage against limits
    private func checkMemoryLimit() throws {
        let memoryUsage = getCurrentMemoryUsage()
        currentMemoryUsage = memoryUsage
        
        if memoryUsage > Configuration.Extensions.MemoryLimits.maxExtensionMemoryMB {
            logger.error("Memory limit exceeded: \(memoryUsage)MB / \(Configuration.Extensions.MemoryLimits.maxExtensionMemoryMB)MB")
            throw AppError.data(.storeNotAvailable)
        }
    }
    
    /// Get current memory usage in MB
    private func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Int(info.resident_size / 1024 / 1024) // Convert to MB
        }
        
        return 0
    }
    
    /// Set up memory warning observer
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryWarning()
            }
        }
    }
    
    /// Handle memory warning by clearing caches
    private func handleMemoryWarning() {
        logger.warning("Received memory warning in extension")
        
        // Reset Core Data caches safely
        if let container = container {
            container.viewContext.reset()
        }
        
        // Log current usage
        let usage = getCurrentMemoryUsage()
        logger.info("Current memory usage after reset: \(usage)MB")
    }
    
    // MARK: - Migration Support
    
    /// Check if data exists in shared container
    public func hasSharedData() async -> Bool {
        guard let groupURL = appGroupURL else {
            return false
        }
        
        let storeURL = groupURL.appendingPathComponent(Configuration.Extensions.CoreData.sqliteFilename)
        return FileManager.default.fileExists(atPath: storeURL.path)
    }
    
    /// Get store metadata for debugging
    public func getStoreMetadata() async -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        guard let groupURL = appGroupURL else {
            metadata["error"] = "App Group URL not available"
            return metadata
        }
        
        let storeURL = groupURL.appendingPathComponent(Configuration.Extensions.CoreData.sqliteFilename)
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            metadata["fileSize"] = attributes[.size]
            metadata["modificationDate"] = attributes[.modificationDate]
        } catch {
            metadata["attributesError"] = error.localizedDescription
        }
        
        metadata["storeURL"] = storeURL.path
        metadata["hasData"] = FileManager.default.fileExists(atPath: storeURL.path)
        metadata["isAvailable"] = isAvailable
        metadata["memoryUsage"] = "\(currentMemoryUsage)MB"
        
        return metadata
    }
    
    /// Perform health check on the shared data store
    public func performHealthCheck() async -> SharedDataHealthReport {
        var report = SharedDataHealthReport()
        
        report.isAvailable = isAvailable
        report.memoryUsage = currentMemoryUsage
        report.hasAppGroupAccess = appGroupURL != nil
        report.hasSharedData = await hasSharedData()
        
        if let container = container {
            do {
                // Test basic read operation
                let context = container.viewContext
                let request = NSFetchRequest<NSManagedObject>(entityName: Configuration.CoreData.medicationEntity)
                request.fetchLimit = 1
                _ = try context.fetch(request)
                report.canReadData = true
            } catch {
                report.canReadData = false
                report.lastError = error.localizedDescription
            }
        } else {
            report.canReadData = false
        }
        
        report.timestamp = Date()
        return report
    }
}

// MARK: - Supporting Types

/// Status of the shared data manager
public enum SharedDataStatus: Sendable {
    case available
    case degraded(Error)
    case unavailable(Error)
    
    public var isWorking: Bool {
        switch self {
        case .available:
            return true
        case .degraded, .unavailable:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .available:
            return "Shared data is available"
        case .degraded(let error):
            return "Shared data has issues: \(error.localizedDescription)"
        case .unavailable(let error):
            return "Shared data is unavailable: \(error.localizedDescription)"
        }
    }
}

/// Health report for shared data diagnostics
public struct SharedDataHealthReport: Sendable {
    public var isAvailable: Bool = false
    public var memoryUsage: Int = 0
    public var hasAppGroupAccess: Bool = false
    public var hasSharedData: Bool = false
    public var canReadData: Bool = false
    public var lastError: String?
    public var timestamp: Date = Date()
    
    public var overallHealth: String {
        if isAvailable && canReadData {
            return "Healthy"
        } else if hasAppGroupAccess && hasSharedData {
            return "Degraded"
        } else {
            return "Unavailable"
        }
    }
}

// MARK: - Extension Errors (aligned with your AppError)
public enum ExtensionError: LocalizedError, Sendable {
    case appGroupNotConfigured(identifier: String)
    case dataFetchFailed(entity: String, underlyingError: Error)
    case memoryLimitExceeded(currentUsageMB: Int, limitMB: Int)
    case coreDataUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .appGroupNotConfigured(let identifier):
            return "App Group not configured: \(identifier)"
        case .dataFetchFailed(let entity, let underlyingError):
            return "Failed to fetch \(entity): \(underlyingError.localizedDescription)"
        case .memoryLimitExceeded(let current, let limit):
            return "Memory limit exceeded: \(current)MB / \(limit)MB"
        case .coreDataUnavailable:
            return "Core Data is not available in extension"
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension SharedCoreDataManager {
    /// Print store statistics for debugging
    public func printStoreStatistics() async {
        logger.debug("=== Shared Core Data Statistics ===")
        
        guard let container = container, isAvailable else {
            logger.debug("Shared Core Data not available")
            return
        }
        
        let entities = [
            Configuration.CoreData.medicationEntity,
            Configuration.CoreData.supplementEntity,
            Configuration.CoreData.dietEntryEntity
        ]
        
        for entityName in entities {
            do {
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let count = try container.viewContext.count(for: request)
                logger.debug("\(entityName): \(count) records")
            } catch {
                logger.debug("\(entityName): Error counting - \(error.localizedDescription)")
            }
        }
        
        logger.debug("Memory usage: \(currentMemoryUsage)MB")
        logger.debug("=====================================")
    }
}
#endif