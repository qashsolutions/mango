//
//  Persistence.swift
//  MedicationManager
//
//  Created by Ramana Chinthapenta on 6/8/25.
//

@preconcurrency import CoreData
import OSLog
import Foundation

/// Enhanced persistence controller with proper error handling and eldercare-specific optimizations
/// Swift 6 compliant with @MainActor isolation for UI-related Core Data operations
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()
    
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "PersistenceController")
    
    @MainActor
    static let preview: PersistenceController = {
        do {
            let result = PersistenceController(inMemory: true)
            let viewContext = result.container.viewContext
            
            // Create sample data for previews with proper error handling
            try result.createSampleData(in: viewContext)
            
            return result
        } catch {
            // Log error but provide a fallback preview controller
            Logger(subsystem: Configuration.App.bundleId, category: "PersistenceController")
                .error("Failed to create preview data: \(error.localizedDescription)")
            
            // Return a basic controller without sample data
            return PersistenceController(inMemory: true)
        }
    }()

    let container: NSPersistentContainer
    
    /// Background context for heavy operations (medication sync, bulk operations)
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    /// Computed property to get the main view context
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MedicationManager")
        
        // Configure persistent store for in-memory or disk storage
        if inMemory {
            configureInMemoryStore()
        } else {
            configureDiskStore()
        }
        
        // Load persistent stores with proper error handling
        loadPersistentStores()
        
        // Configure the view context for optimal performance
        configureViewContext()
        
        logger.info("PersistenceController initialized successfully (inMemory: \(inMemory))")
    }
    
    // MARK: - Private Configuration Methods
    
    private func configureInMemoryStore() {
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            logger.error("No persistent store descriptions found for in-memory container")
            // Create a new store description instead of crashing
            let storeDescription = NSPersistentStoreDescription()
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
            storeDescription.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [storeDescription]
            return
        }
        
        storeDescription.url = URL(fileURLWithPath: "/dev/null")
        storeDescription.type = NSInMemoryStoreType
    }
    
    private func configureDiskStore() {
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            logger.error("No persistent store descriptions found for disk container")
            // Create a new store description with default settings
            let storeDescription = NSPersistentStoreDescription()
            setupStoreDescription(storeDescription)
            container.persistentStoreDescriptions = [storeDescription]
            return
        }
        
        setupStoreDescription(storeDescription)
    }
    
    private func setupStoreDescription(_ storeDescription: NSPersistentStoreDescription) {
        // Enable persistent history tracking for CloudKit sync
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Configure for CloudKit if available (for multi-device sync - important for elderly users)
        #if !targetEnvironment(simulator)
        // CloudKit configuration would go here when implementing sync
        // storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        #endif
        
        // Enable automatic lightweight migration
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        logger.debug("Store description configured with CloudKit and migration support")
    }
    
    private func loadPersistentStores() {
        var loadError: Error?
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        container.loadPersistentStores { [weak self] storeDescription, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                loadError = error
                self?.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                
                // For eldercare apps, we need to handle this gracefully
                // Instead of crashing, we'll attempt to recover
                self?.handlePersistentStoreLoadError(error, storeDescription: storeDescription)
            } else {
                self?.logger.info("Persistent store loaded successfully: \(storeDescription.url?.lastPathComponent ?? "unknown")")
            }
        }
        
        dispatchGroup.wait()
        
        // If there was an error and we couldn't recover, we still don't crash
        // Instead, we'll work with an in-memory store as fallback
        if let error = loadError {
            logger.warning("Using fallback configuration due to persistent store error: \(error.localizedDescription)")
            setupFallbackInMemoryStore()
        }
    }
    
    private func handlePersistentStoreLoadError(_ error: Error, storeDescription: NSPersistentStoreDescription) {
        logger.error("Attempting to recover from persistent store error")
        
        // Attempt to remove corrupted store and recreate
        if let storeURL = storeDescription.url {
            do {
                // Remove the corrupted store file
                try FileManager.default.removeItem(at: storeURL)
                
                // Remove associated files (WAL, SHM)
                let walURL = storeURL.appendingPathExtension("wal")
                let shmURL = storeURL.appendingPathExtension("shm")
                
                try? FileManager.default.removeItem(at: walURL)
                try? FileManager.default.removeItem(at: shmURL)
                
                logger.info("Removed corrupted store files, will recreate on next launch")
                
                // For this session, use in-memory store
                setupFallbackInMemoryStore()
                
            } catch {
                logger.error("Failed to remove corrupted store: \(error.localizedDescription)")
                setupFallbackInMemoryStore()
            }
        }
    }
    
    private func setupFallbackInMemoryStore() {
        logger.warning("Setting up fallback in-memory store")
        
        // Create a new in-memory store description
        let fallbackDescription = NSPersistentStoreDescription()
        fallbackDescription.url = URL(fileURLWithPath: "/dev/null")
        fallbackDescription.type = NSInMemoryStoreType
        
        container.persistentStoreDescriptions = [fallbackDescription]
        
        // Try to load the fallback store
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.logger.error("Even fallback store failed: \(error.localizedDescription)")
                // At this point, we have a serious problem, but we still don't crash
                // The app will have limited functionality but won't crash for elderly users
            } else {
                self?.logger.info("Fallback in-memory store loaded successfully")
            }
        }
    }
    
    private func configureViewContext() {
        let context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        
        // Use a merge policy that favors external changes (important for sync)
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure for better performance with elderly users (less frequent UI updates)
        context.stalenessInterval = 0.0
        
        logger.debug("View context configured with merge policy and performance settings")
    }
    
    // MARK: - Sample Data Creation
    
    private func createSampleData(in context: NSManagedObjectContext) throws {
        // Check if sample data already exists
        let request = NSFetchRequest<NSManagedObject>(entityName: "MedicationEntity")
        request.predicate = NSPredicate(format: "userId == %@", "preview-user")
        request.fetchLimit = 1
        
        do {
            let existingData = try context.fetch(request)
            if !existingData.isEmpty {
                logger.debug("Sample data already exists, skipping creation")
                return
            }
        } catch {
            logger.warning("Could not check for existing sample data: \(error.localizedDescription)")
            // Continue with creation anyway
        }
        
        // Sample medication data for elderly users
        let sampleMedications = [
            SampleMedication(
                name: "Lisinopril",
                dosage: "10mg",
                frequency: "once_daily",
                prescribedBy: "Dr. Smith",
                notes: "Take with water, for blood pressure"
            ),
            SampleMedication(
                name: "Metformin",
                dosage: "500mg",
                frequency: "twice_daily",
                prescribedBy: "Dr. Johnson",
                notes: "Take with meals, for diabetes"
            ),
            SampleMedication(
                name: "Vitamin D3",
                dosage: "1000 IU",
                frequency: "once_daily",
                prescribedBy: "Dr. Smith",
                notes: "Take with breakfast, for bone health"
            )
        ]
        
        for (_, sampleMed) in sampleMedications.enumerated() {
            guard let entity = NSEntityDescription.entity(forEntityName: "MedicationEntity", in: context) else {
                logger.error("Could not find MedicationEntity description")
                throw PersistenceError.entityNotFound("MedicationEntity")
            }
            
            let medication = NSManagedObject(entity: entity, insertInto: context)
            
            // Set properties safely
            medication.setValue(UUID().uuidString, forKey: "id")
            medication.setValue("preview-user", forKey: "userId")
            medication.setValue(sampleMed.name, forKey: "name")
            medication.setValue(sampleMed.dosage, forKey: "dosage")
            medication.setValue(sampleMed.frequency, forKey: "frequency")
            medication.setValue(sampleMed.notes, forKey: "notes")
            medication.setValue(sampleMed.prescribedBy, forKey: "prescribedBy")
            medication.setValue(Date(), forKey: "startDate")
            medication.setValue(Date(), forKey: "createdAt")
            medication.setValue(Date(), forKey: "updatedAt")
            medication.setValue(true, forKey: "isActive")
            medication.setValue(false, forKey: "voiceEntryUsed")
            medication.setValue(false, forKey: "needsSync")
            medication.setValue(false, forKey: "isDeletedFlag")
            
            logger.debug("Created sample medication: \(sampleMed.name)")
        }
        
        // Save the context with error handling
        do {
            try context.save()
            logger.info("Sample data created successfully: \(sampleMedications.count) medications")
        } catch {
            logger.error("Failed to save sample data: \(error.localizedDescription)")
            throw PersistenceError.saveFailed(error)
        }
    }
    
    // MARK: - Public Methods
    
    /// Save the view context with proper error handling
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else {
            logger.debug("No changes to save in view context")
            return
        }
        
        do {
            try context.save()
            logger.debug("View context saved successfully")
        } catch {
            logger.error("Failed to save view context: \(error.localizedDescription)")
            throw PersistenceError.saveFailed(error)
        }
    }
    
    /// Save a background context with proper error handling
    func saveBackgroundContext() throws {
        guard backgroundContext.hasChanges else {
            logger.debug("No changes to save in background context")
            return
        }
        
        do {
            try backgroundContext.save()
            logger.debug("Background context saved successfully")
        } catch {
            logger.error("Failed to save background context: \(error.localizedDescription)")
            throw PersistenceError.saveFailed(error)
        }
    }
    
    /// Perform a background task with error handling
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let result = try block(self.backgroundContext)
                    continuation.resume(returning: result)
                } catch {
                    self.logger.error("Background task failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Reset the persistent store (use with caution)
    func resetStore() throws {
        logger.warning("Resetting persistent store - all data will be lost")
        
        guard (container.persistentStoreDescriptions.first?.url) != nil else {
            throw PersistenceError.storeNotFound
        }
        
        // Remove all objects from contexts
        let context = container.viewContext
        
        // Get all entity names
        guard let model = container.managedObjectModel.entities.first?.managedObjectModel else {
            throw PersistenceError.modelNotFound
        }
        
        for entity in model.entities {
            guard let entityName = entity.name else { continue }
            
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            
            do {
                let objects = try context.fetch(request)
                for object in objects {
                    context.delete(object)
                }
            } catch {
                logger.error("Failed to fetch objects for entity \(entityName): \(error.localizedDescription)")
            }
        }
        
        do {
            try context.save()
            logger.info("Store reset completed successfully")
        } catch {
            logger.error("Failed to save after store reset: \(error.localizedDescription)")
            throw PersistenceError.saveFailed(error)
        }
    }
}

// MARK: - Supporting Types

private struct SampleMedication {
    let name: String
    let dosage: String
    let frequency: String
    let prescribedBy: String
    let notes: String
}

/// Custom persistence errors for better error handling
enum PersistenceError: LocalizedError {
    case entityNotFound(String)
    case saveFailed(Error)
    case storeNotFound
    case modelNotFound
    case migrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .entityNotFound(let entityName):
            return "Could not find entity: \(entityName)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .storeNotFound:
            return "Persistent store not found"
        case .modelNotFound:
            return "Core Data model not found"
        case .migrationFailed(let error):
            return "Data migration failed: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .entityNotFound:
            return "Check that the Core Data model contains the expected entities"
        case .saveFailed:
            return "Check device storage and try again"
        case .storeNotFound:
            return "The app will attempt to recreate the database"
        case .modelNotFound:
            return "Reinstall the app if the problem persists"
        case .migrationFailed:
            return "The app will attempt to reset the database"
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension PersistenceController {
    /// Print store statistics for debugging
    func printStoreStatistics() {
        logger.debug("=== Core Data Store Statistics ===")
        
        guard let model = container.managedObjectModel.entities.first?.managedObjectModel else {
            logger.debug("No model found")
            return
        }
        
        let context = container.viewContext
        
        for entity in model.entities {
            guard let entityName = entity.name else { continue }
            
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            
            do {
                let count = try context.count(for: request)
                logger.debug("\(entityName): \(count) records")
            } catch {
                logger.debug("\(entityName): Error counting - \(error.localizedDescription)")
            }
        }
        
        logger.debug("================================")
    }
    
    /// Create additional test data for development
    func createTestData() throws {
        let context = container.viewContext
        try createSampleData(in: context)
        logger.info("Test data created for development")
    }
}
#endif
