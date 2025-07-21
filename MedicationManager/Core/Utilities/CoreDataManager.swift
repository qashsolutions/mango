import Foundation
import CoreData
import FirebaseAuth
import os.log
import Observation

// MARK: - Notification Extension
extension Notification.Name {
    static let coreDataNeedsSync = Notification.Name("coreDataNeedsSync")
}

// MARK: - Data Store Status
@MainActor
enum DataStoreStatus: Equatable {
    case initializing
    case loadingPersistentStore
    case migrating
    case ready
    case failed(String)
    
    var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }
}

// MARK: - Core Data Manager Protocol
@MainActor
protocol CoreDataManagerProtocol: AnyObject {
    var dataStoreStatus: DataStoreStatus { get }
    
    // MARK: - Context Management
    func saveContext() async throws
    
    // MARK: - Medication Operations
    func fetchMedications(for userId: String) async throws -> [MedicationModel]
    func saveMedication(_ medication: MedicationModel) async throws
    func deleteMedication(_ medicationId: String) async throws
    func updateMedication(_ medication: MedicationModel) async throws
    func medicationExists(withId id: String) async throws -> Bool
    func markMedicationTaken(medicationId: String, userId: String, takenAt: Date) async throws
    
    // MARK: - Supplement Operations
    func fetchSupplements(for userId: String) async throws -> [SupplementModel]
    func saveSupplement(_ supplement: SupplementModel) async throws
    func deleteSupplement(_ supplementId: String) async throws
    func updateSupplement(_ supplement: SupplementModel) async throws
    
    // MARK: - Diet Entry Operations
    func fetchDietEntries(for userId: String) async throws -> [DietEntryModel]
    func fetchDietEntry(id: String, userId: String) async throws -> DietEntryModel?
    func saveDietEntry(_ dietEntry: DietEntryModel) async throws
    func deleteDietEntry(_ dietEntryId: String) async throws
    func updateDietEntry(_ dietEntry: DietEntryModel) async throws
    
    // MARK: - Doctor Operations
    func fetchDoctors(for userId: String) async throws -> [DoctorModel]
    func saveDoctor(_ doctor: DoctorModel) async throws
    func deleteDoctor(_ doctorId: String) async throws
    func updateDoctor(_ doctor: DoctorModel) async throws
    
    // MARK: - Conflict Operations
    func fetchConflicts(for userId: String) async throws -> [MedicationConflict]
    func fetchConflict(id: String, userId: String) async throws -> MedicationConflict?
    func saveConflict(_ conflict: MedicationConflict) async throws
    func deleteConflict(_ conflictId: String) async throws
    func updateConflict(_ conflict: MedicationConflict) async throws
    
    // MARK: - Meal Time Based Operations
    func fetchMedicationsForTime(userId: String, mealTime: MealType) async throws -> [MedicationModel]
    func fetchSupplementsForTime(userId: String, mealTime: MealType) async throws -> [SupplementModel]
    
    // MARK: - Data Management
    func clearUserData(for userId: String) async throws
    func migrateToAppGroupIfNeeded() async throws
}

// MARK: - Core Data Manager
@Observable
@MainActor
final class CoreDataManager: CoreDataManagerProtocol {
    // MARK: - Singleton
    static let shared = CoreDataManager()
    
    // MARK: - Initialization State
    private enum InitializationPhase: String {
        case notStarted = "NOT_STARTED"
        case creatingContainer = "CREATING_CONTAINER"
        case loadingStores = "LOADING_STORES"
        case ready = "READY"
        case failed = "FAILED"
    }
    
    // MARK: - Properties
    private(set) var dataStoreStatus: DataStoreStatus = .initializing
    
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "CoreData")
    
    @ObservationIgnored
    private var initPhase = InitializationPhase.notStarted
    
    @ObservationIgnored
    private var isStoreLoaded = false
    
    @ObservationIgnored
    private var loadError: Error?
    
    @ObservationIgnored
    private var loadingTask: Task<Void, Error>?
    
    // Thread-safe stored properties
    private let persistentContainer: NSPersistentContainer
    private let _viewContext: NSManagedObjectContext
    
    // Safe context accessor that ensures store is available
    private var viewContext: NSManagedObjectContext {
        if !isStoreLoaded && loadError == nil {
            logger.warning("[CoreDataManager] Accessing viewContext before store is loaded")
        }
        return _viewContext
    }
    
    // MARK: - Initialization
    private init() {
        logger.info("CoreDataManager initializing")
        
        // Initialize container synchronously for thread safety
        self.persistentContainer = CoreDataManager.createPersistentContainer()
        self._viewContext = persistentContainer.viewContext
        
        // Configure context immediately
        configureContext()
        
        // NOTE: Removed Task launch from init() to prevent memory spike at startup
        // Store will be loaded on first access via ensureStoreLoaded()
        // Notification observers will be set up after store loading completes
    }
    
    // MARK: - Store Loading
    private func ensureStoreLoaded() async throws {
        // If already loaded successfully, return immediately
        guard !isStoreLoaded else {
            if let error = loadError {
                throw error
            }
            return
        }
        
        // If already failed, throw the stored error
        if let error = loadError {
            throw error
        }
        
        // If loading is already in progress, wait for it
        if let existingTask = loadingTask {
            try await existingTask.value
            return
        }
        
        // Create loading task to prevent concurrent loads
        let task = Task { @MainActor in
            await initializePersistentStore()
            
            // Check if loading failed
            if let error = loadError {
                throw error
            }
            
            isStoreLoaded = true
        }
        
        loadingTask = task
        try await task.value
    }
    
    // MARK: - Store Setup
    private func initializePersistentStore() async {
        logger.info("[CoreData] Initializing persistent store - START")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        logger.info("[COREDATA-INIT] Starting persistent store initialization")
        dataStoreStatus = .loadingPersistentStore
        initPhase = .loadingStores
        
        // First, ensure migration if needed
        if needsAppGroupMigration() {
            dataStoreStatus = .migrating
            do {
                try await performAppGroupMigration()
            } catch {
                logger.error("[COREDATA-INIT] App group migration failed: \(error.localizedDescription)")
                dataStoreStatus = .failed("Migration failed: \(error.localizedDescription)")
                initPhase = .failed
                return
            }
        }
        
        // Load persistent store
        await withCheckedContinuation { continuation in
            persistentContainer.loadPersistentStores { [weak self] storeDescription, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                Task { @MainActor in
                    if let error = error {
                        self.logger.error("[COREDATA-INIT] Failed to load persistent store: \(error.localizedDescription)")
                        self.dataStoreStatus = .failed(error.localizedDescription)
                        self.initPhase = .failed
                        self.loadError = error
                    } else {
                        let storeURL = storeDescription.url?.absoluteString ?? "unknown"
                        self.logger.info("[COREDATA-INIT] Persistent store loaded successfully: \(storeURL)")
                        self.dataStoreStatus = .ready
                        self.initPhase = .ready
                        
                        // Configure context
                        self.configureContext()
                        
                        // Set up notification observers after store is loaded
                        self.setupNotificationObservers()
                        
                        // Trigger initial sync if authenticated
                        if Auth.auth().currentUser != nil {
                            self.notifyDataSyncNeeded(reason: "Store initialized")
                        }
                    }
                    
                    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                    self.logger.info("[COREDATA-INIT] initializePersistentStore() completed in \(elapsed)s")
                    
                    continuation.resume()
                }
            }
        }
    }
    
    private static func createPersistentContainer() -> NSPersistentContainer {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let logger = Logger(subsystem: Configuration.App.bundleId, category: "CoreData")
        logger.info("[COREDATA-INIT] Creating NSPersistentContainer")
        let container = NSPersistentContainer(name: "MedicationManager")
        
        // Use App Group container for data sharing with extensions
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Configuration.Extensions.appGroupIdentifier) {
            let storeURL = appGroupURL.appendingPathComponent("MedicationManager.sqlite")
            logger.info("[COREDATA-INIT] App Group store URL: \(storeURL.path)")
            
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            
            // Configure for better performance
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            container.persistentStoreDescriptions = [storeDescription]
        } else {
            logger.warning("[COREDATA-INIT] App Group container not available")
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("[COREDATA-INIT] createPersistentContainer() completed in \(elapsed)s")
        
        return container
    }
    
    private func configureContext() {
        _viewContext.automaticallyMergesChangesFromParent = true
        _viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        _viewContext.undoManager = nil
        _viewContext.shouldDeleteInaccessibleFaults = true
        _viewContext.name = "MainViewContext"
    }
    
    // MARK: - Notification Observers
    private func setupNotificationObservers() {
        // Observe remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePersistentStoreRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
    }
    
    @objc private func handlePersistentStoreRemoteChange(_ notification: Notification) {
        logger.debug("Received remote change notification")
        
        // Process changes on the correct context
        _viewContext.perform { [weak self] in
            self?._viewContext.refreshAllObjects()
        }
    }
    
    // MARK: - Context Management
    func saveContext() async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.saveFailed)
        }
        
        let context = viewContext
        
        // Perform save on context's queue
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                guard context.hasChanges else {
                    continuation.resume()
                    return
                }
                
                do {
                    try context.save()
                    self.logger.debug("Context saved successfully")
                    
                    // Notify sync manager
                    Task { @MainActor in
                        self.notifyDataSyncNeeded(reason: "Context saved")
                    }
                    
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to save context: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    // MARK: - Sync Notification
    private func notifyDataSyncNeeded(reason: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        logger.debug("Notifying sync needed - reason: \(reason)")
        
        NotificationCenter.default.post(
            name: .coreDataNeedsSync,
            object: nil,
            userInfo: [
                "reason": reason,
                "userId": userId,
                "timestamp": Date()
            ]
        )
    }
    
    // MARK: - Medication Operations
    func fetchMedications(for userId: String) async throws -> [MedicationModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "MedicationEntity")
        request.predicate = NSPredicate(format: "userId == %@ AND isDeletedFlag == NO", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[MedicationModel], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let medications = entities.compactMap { ($0 as? MedicationEntity)?.toModel() }
                    continuation.resume(returning: medications)
                } catch {
                    self.logger.error("Failed to fetch medications: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func saveMedication(_ medication: MedicationModel) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                // Check if exists
                let request = NSFetchRequest<NSManagedObject>(entityName: "MedicationEntity")
                request.predicate = NSPredicate(format: "id == %@", medication.id)
                request.fetchLimit = 1
                
                do {
                    let existing = try context.fetch(request).first
                    let entity = existing ?? NSEntityDescription.insertNewObject(forEntityName: "MedicationEntity", into: context)
                    
                    // Update entity
                    if let medicationEntity = entity as? MedicationEntity {
                        medicationEntity.updateFromModel(medication)
                    }
                    
                    try context.save()
                    self.logger.debug("Medication saved: \(medication.id)")
                    
                    Task { @MainActor in
                        self.notifyDataSyncNeeded(reason: "Medication saved")
                    }
                    
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to save medication: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func deleteMedication(_ medicationId: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = MedicationEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", medicationId)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        // Soft delete
                        entity.isDeletedFlag = true
                        entity.needsSync = true
                        
                        try context.save()
                        self.logger.debug("Medication soft deleted: \(medicationId)")
                        
                        Task { @MainActor in
                            self.notifyDataSyncNeeded(reason: "Medication deleted")
                        }
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to delete medication: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func updateMedication(_ medication: MedicationModel) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        // Use saveMedication which handles both create and update
        try await saveMedication(medication)
    }
    
    func medicationExists(withId id: String) async throws -> Bool {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND isDeletedFlag == NO", id)
        request.fetchLimit = 1
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            context.perform {
                do {
                    let count = try context.count(for: request)
                    continuation.resume(returning: count > 0)
                } catch {
                    self.logger.error("Failed to check medication existence: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func markMedicationTaken(medicationId: String, userId: String, takenAt: Date) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        // Fetch the medication
        let medications = try await fetchMedications(for: userId)
        guard var medication = medications.first(where: { $0.id == medicationId }) else {
            throw AppError.data(.medicationNotFound)
        }
        
        // Find the closest schedule item to mark as taken
        _ = Calendar.current
        var updatedSchedules = medication.schedule
        
        // Find the schedule item closest to takenAt that isn't already completed
        if let scheduleIndex = updatedSchedules
            .enumerated()
            .filter({ !$0.element.isCompleted })
            .min(by: { abs($0.element.time.timeIntervalSince(takenAt)) < abs($1.element.time.timeIntervalSince(takenAt)) })?
            .offset {
            
            // Mark as completed
            updatedSchedules[scheduleIndex].isCompleted = true
            updatedSchedules[scheduleIndex].completedAt = takenAt
            
            // Update the medication with the new schedule
            medication.schedule = updatedSchedules
            medication.updatedAt = Date()
            medication.needsSync = true
            
            // Save the updated medication
            try await updateMedication(medication)
            
            logger.info("Marked medication \(medication.name) as taken at \(takenAt)")
        } else {
            logger.warning("No uncompleted schedule found for medication \(medicationId)")
        }
    }
    
    // MARK: - Supplement Operations
    func fetchSupplements(for userId: String) async throws -> [SupplementModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = SupplementEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND isDeletedFlag == NO", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SupplementEntity.createdAt, ascending: false)]
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[SupplementModel], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let supplements = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: supplements)
                } catch {
                    self.logger.error("Failed to fetch supplements: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func saveSupplement(_ supplement: SupplementModel) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let request = SupplementEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", supplement.id)
                request.fetchLimit = 1
                
                do {
                    let existing = try context.fetch(request).first
                    let entity = existing ?? SupplementEntity(context: context)
                    
                    entity.updateFromModel(supplement)
                    
                    try context.save()
                    self.logger.debug("Supplement saved: \(supplement.id)")
                    
                    Task { @MainActor in
                        self.notifyDataSyncNeeded(reason: "Supplement saved")
                    }
                    
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to save supplement: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func deleteSupplement(_ supplementId: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let request = SupplementEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", supplementId)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.isDeletedFlag = true
                        entity.needsSync = true
                        
                        try context.save()
                        self.logger.debug("Supplement soft deleted: \(supplementId)")
                        
                        Task { @MainActor in
                            self.notifyDataSyncNeeded(reason: "Supplement deleted")
                        }
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to delete supplement: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func updateSupplement(_ supplement: SupplementModel) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        try await saveSupplement(supplement)
    }
    
    // MARK: - Diet Entry Operations
    func fetchDietEntries(for userId: String) async throws -> [DietEntryModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = DietEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND isDeletedFlag == NO", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DietEntryEntity.createdAt, ascending: false)]
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[DietEntryModel], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let dietEntries = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: dietEntries)
                } catch {
                    self.logger.error("Failed to fetch diet entries: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func saveDietEntry(_ dietEntry: DietEntryModel) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = DietEntryEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", dietEntry.id)
                request.fetchLimit = 1
                
                do {
                    let existing = try context.fetch(request).first
                    let entity = existing ?? DietEntryEntity(context: context)
                    
                    entity.updateFromModel(dietEntry)
                    
                    try context.save()
                    self.logger.debug("Diet entry saved: \(dietEntry.id)")
                    
                    Task { @MainActor in
                        self.notifyDataSyncNeeded(reason: "Diet entry saved")
                    }
                    
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to save diet entry: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func deleteDietEntry(_ dietEntryId: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = DietEntryEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", dietEntryId)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.isDeletedFlag = true
                        entity.needsSync = true
                        
                        try context.save()
                        self.logger.debug("Diet entry soft deleted: \(dietEntryId)")
                        
                        Task { @MainActor in
                            self.notifyDataSyncNeeded(reason: "Diet entry deleted")
                        }
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to delete diet entry: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func updateDietEntry(_ dietEntry: DietEntryModel) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        try await saveDietEntry(dietEntry)
    }
    
    // MARK: - Doctor Operations
    func fetchDoctors(for userId: String) async throws -> [DoctorModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = DoctorEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND isDeletedFlag == NO", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DoctorEntity.createdAt, ascending: false)]
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[DoctorModel], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let doctors = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: doctors)
                } catch {
                    self.logger.error("Failed to fetch doctors: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func saveDoctor(_ doctor: DoctorModel) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = DoctorEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", doctor.id)
                request.fetchLimit = 1
                
                do {
                    let existing = try context.fetch(request).first
                    let entity = existing ?? DoctorEntity(context: context)
                    
                    entity.updateFromModel(doctor)
                    
                    try context.save()
                    self.logger.debug("Doctor saved: \(doctor.id)")
                    
                    Task { @MainActor in
                        self.notifyDataSyncNeeded(reason: "Doctor saved")
                    }
                    
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to save doctor: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func deleteDoctor(_ doctorId: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = DoctorEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", doctorId)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.isDeletedFlag = true
                        entity.needsSync = true
                        
                        try context.save()
                        self.logger.debug("Doctor soft deleted: \(doctorId)")
                        
                        Task { @MainActor in
                            self.notifyDataSyncNeeded(reason: "Doctor deleted")
                        }
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to delete doctor: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func updateDoctor(_ doctor: DoctorModel) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        try await saveDoctor(doctor)
    }
    
    // MARK: - Conflict Operations
    func fetchConflicts(for userId: String) async throws -> [MedicationConflict] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = ConflictEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND isDeletedFlag == NO", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConflictEntity.createdAt, ascending: false)]
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[MedicationConflict], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let conflicts = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: conflicts)
                } catch {
                    self.logger.error("Failed to fetch conflicts: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func fetchConflict(id: String, userId: String) async throws -> MedicationConflict? {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            logger.error("[CoreDataManager] fetchConflict failed - store not ready")
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = ConflictEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND userId == %@ AND isDeletedFlag == NO", id, userId)
        request.fetchLimit = 1
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MedicationConflict?, Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let conflict = entities.first?.toModel()
                    self.logger.debug("[CoreDataManager] fetchConflict completed - found: \(conflict != nil), id: \(id)")
                    continuation.resume(returning: conflict)
                } catch {
                    self.logger.error("[CoreDataManager] fetchConflict failed - error: \(error.localizedDescription), id: \(id)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func saveConflict(_ conflict: MedicationConflict) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = ConflictEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", conflict.id)
                request.fetchLimit = 1
                
                do {
                    let existing = try context.fetch(request).first
                    let entity = existing ?? ConflictEntity(context: context)
                    
                    entity.updateFromModel(conflict)
                    
                    try context.save()
                    self.logger.debug("Conflict saved: \(conflict.id)")
                    
                    Task { @MainActor in
                        self.notifyDataSyncNeeded(reason: "Conflict saved")
                    }
                    
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to save conflict: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func deleteConflict(_ conflictId: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = ConflictEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", conflictId)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.isDeletedFlag = true
                        entity.needsSync = true
                        
                        try context.save()
                        self.logger.debug("Conflict soft deleted: \(conflictId)")
                        
                        Task { @MainActor in
                            self.notifyDataSyncNeeded(reason: "Conflict deleted")
                        }
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to delete conflict: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func updateConflict(_ conflict: MedicationConflict) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        try await saveConflict(conflict)
    }
    
    // MARK: - Data Management
    func clearUserData(for userId: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            logger.error("[CoreDataManager] clearUserData failed - store not ready")
            throw AppError.data(.storeNotAvailable)
        }
        
        // Verify the requesting user has permission
        guard let currentUserId = FirebaseManager.shared.currentUser?.id else {
            logger.error("[CoreDataManager] clearUserData failed - user not authenticated")
            throw AppError.authentication(.notAuthenticated)
        }
        
        // Users can only clear their own data OR caregivers with dataManagement permission
        if userId != currentUserId {
            let userModeManager = UserModeManager.shared
            
            // Check if caregiver has permission
            guard userModeManager.currentMode == .caregiver,
                  AccessControl.shared.hasPermission(.dataManagement, caregiverId: currentUserId) else {
                logger.error("[CoreDataManager] clearUserData failed - permission denied for caregiver: \(currentUserId)")
                throw AppError.caregiver(.accessDenied)
            }
        }
        
        logger.info("[CoreDataManager] Clearing data for user: \(userId)")
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    // Delete user-specific data with predicates
                    let entities = [
                        ("MedicationEntity", "userId == %@"),
                        ("SupplementEntity", "userId == %@"),
                        ("DietEntryEntity", "userId == %@"),
                        ("DoctorEntity", "userId == %@"),
                        ("ConflictEntity", "userId == %@")
                    ]
                    
                    var totalDeleted = 0
                    
                    for (entityName, predicateFormat) in entities {
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                        fetchRequest.predicate = NSPredicate(format: predicateFormat, userId)
                        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                        deleteRequest.resultType = .resultTypeObjectIDs
                        
                        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                        let deletedObjectIDs = result?.result as? [NSManagedObjectID] ?? []
                        totalDeleted += deletedObjectIDs.count
                        
                        // Merge changes
                        let changes = [NSDeletedObjectsKey: deletedObjectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                        
                        self.logger.debug("[CoreDataManager] Deleted \(deletedObjectIDs.count) \(entityName) records for user: \(userId)")
                    }
                    
                    try context.save()
                    self.logger.info("[CoreDataManager] Successfully cleared \(totalDeleted) records for user: \(userId)")
                    
                    // Track analytics
                    AnalyticsManager.shared.trackEvent(
                        "user_data_cleared",
                        parameters: [
                            "userId": userId,
                            "clearedBy": currentUserId,
                            "totalRecords": totalDeleted
                        ]
                    )
                    
                    continuation.resume()
                } catch {
                    self.logger.error("[CoreDataManager] Failed to clear user data: \(error.localizedDescription), userId: \(userId)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    // DEPRECATED: This method is dangerous and should not be used in production
    @available(*, deprecated, message: "Use clearUserData(for:) instead. This method will be removed in a future version.")
    func clearAllData() async throws {
        logger.critical("⚠️ DEPRECATED: clearAllData() called - this method is dangerous and will be removed")
        
        // Log who's calling this for investigation
        if let userId = FirebaseManager.shared.currentUser?.id {
            logger.critical("clearAllData called by user: \(userId)")
            AnalyticsManager.shared.trackEvent("dangerous_clear_all_data_called", 
                parameters: ["userId": userId])
        }
        
        // Only allow in DEBUG mode for testing
        #if DEBUG
        logger.warning("clearAllData() executing in DEBUG mode only")
        
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    // Delete all entities
                    let entityNames = ["MedicationEntity", "SupplementEntity", "DietEntryEntity", "DoctorEntity", "ConflictEntity"]
                    
                    for entityName in entityNames {
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                        deleteRequest.resultType = .resultTypeObjectIDs
                        
                        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                        let deletedObjectIDs = result?.result as? [NSManagedObjectID] ?? []
                        
                        // Merge changes
                        let changes = [NSDeletedObjectsKey: deletedObjectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                    }
                    
                    try context.save()
                    self.logger.info("All data cleared successfully (DEBUG mode)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to clear all data: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
        #else
        // Block in production
        logger.error("clearAllData() blocked in production - use clearUserData(for:) instead")
        throw AppError.caregiver(.accessDenied)
        #endif
    }
    
    // MARK: - Migration
    private func needsAppGroupMigration() -> Bool {
        // Check if we have data in the old location but not in the new location
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Configuration.Extensions.appGroupIdentifier) else {
            return false
        }
        
        let newStoreURL = appGroupURL.appendingPathComponent("MedicationManager.sqlite")
        let oldStoreURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("MedicationManager.sqlite")
        
        return FileManager.default.fileExists(atPath: oldStoreURL.path) &&
               !FileManager.default.fileExists(atPath: newStoreURL.path)
    }
    
    private func performAppGroupMigration() async throws {
        logger.info("Starting App Group migration")
        
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Configuration.Extensions.appGroupIdentifier) else {
            throw AppError.data(.migrationFailed)
        }
        
        let coordinator = persistentContainer.persistentStoreCoordinator
        let oldStoreURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("MedicationManager.sqlite")
        let newStoreURL = appGroupURL.appendingPathComponent("MedicationManager.sqlite")
        
        // Ensure old store exists
        guard FileManager.default.fileExists(atPath: oldStoreURL.path) else {
            logger.info("No old store to migrate")
            return
        }
        
        do {
            // Create app group directory if needed
            try FileManager.default.createDirectory(at: appGroupURL, withIntermediateDirectories: true)
            
            // Add old store
            let oldStore = try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: oldStoreURL,
                options: [NSMigratePersistentStoresAutomaticallyOption: true,
                         NSInferMappingModelAutomaticallyOption: true]
            )
            
            // Migrate to new location
            try coordinator.migratePersistentStore(
                oldStore,
                to: newStoreURL,
                options: nil,
                withType: NSSQLiteStoreType
            )
            
            // Remove old store files
            let oldStoreFiles = [
                oldStoreURL,
                oldStoreURL.appendingPathExtension("shm"),
                oldStoreURL.appendingPathExtension("wal")
            ]
            
            for fileURL in oldStoreFiles {
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            logger.info("App Group migration completed successfully")
        } catch {
            logger.error("App Group migration failed: \(error.localizedDescription)")
            throw AppError.data(.migrationFailed)
        }
    }
    
    func migrateToAppGroupIfNeeded() async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        if needsAppGroupMigration() {
            try await performAppGroupMigration()
        }
    }
}

// MARK: - SyncDataProvider Conformance
extension CoreDataManager: SyncDataProvider {
    func fetchMedicationsNeedingSync() async throws -> [MedicationModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[MedicationModel], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let medications = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: medications)
                } catch {
                    self.logger.error("Failed to fetch medications needing sync: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func fetchSupplementsNeedingSync() async throws -> [SupplementModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = SupplementEntity.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[SupplementModel], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let supplements = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: supplements)
                } catch {
                    self.logger.error("Failed to fetch supplements needing sync: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func fetchDietEntriesNeedingSync() async throws -> [DietEntryModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = DietEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[DietEntryModel], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let dietEntries = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: dietEntries)
                } catch {
                    self.logger.error("Failed to fetch diet entries needing sync: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func fetchDoctorsNeedingSync() async throws -> [DoctorModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = DoctorEntity.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[DoctorModel], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let doctors = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: doctors)
                } catch {
                    self.logger.error("Failed to fetch doctors needing sync: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func fetchConflictsNeedingSync() async throws -> [MedicationConflict] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        let request = ConflictEntity.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[MedicationConflict], Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let conflicts = entities.compactMap { $0.toModel() }
                    continuation.resume(returning: conflicts)
                } catch {
                    self.logger.error("Failed to fetch conflicts needing sync: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    func markMedicationSynced(_ id: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = MedicationEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.needsSync = false
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to mark medication synced: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func markSupplementSynced(_ id: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = SupplementEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.needsSync = false
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to mark supplement synced: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func markDietEntrySynced(_ id: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = DietEntryEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.needsSync = false
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to mark diet entry synced: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func markDoctorSynced(_ id: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = DoctorEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.needsSync = false
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to mark doctor synced: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    func markConflictSynced(_ id: String) async throws {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            throw AppError.data(.storeNotAvailable)
        }
        
        let context = viewContext
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = ConflictEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.needsSync = false
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to mark conflict synced: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.data(.saveFailed))
                }
            }
        }
    }
    
    // MARK: - Diet Entry Specific Fetches
    func fetchDietEntry(id: String, userId: String) async throws -> DietEntryModel? {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            logger.error("[CoreDataManager] fetchDietEntry failed - store not ready. Status: \(String(describing: self.dataStoreStatus))")
            throw AppError.data(.storeNotAvailable)
        }
        
        logger.debug("[CoreDataManager] fetchDietEntry starting - id: \(id), userId: \(userId)")
        
        let context = viewContext
        let request = DietEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND userId == %@ AND isDeletedFlag == NO", id, userId)
        request.fetchLimit = 1
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DietEntryModel?, Error>) in
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let dietEntry = entities.first?.toModel()
                    self.logger.debug("[CoreDataManager] fetchDietEntry completed - found: \(dietEntry != nil), id: \(id)")
                    continuation.resume(returning: dietEntry)
                } catch {
                    self.logger.error("[CoreDataManager] fetchDietEntry failed - error: \(error.localizedDescription), id: \(id)")
                    continuation.resume(throwing: AppError.data(.loadFailed))
                }
            }
        }
    }
    
    // MARK: - Meal Time Based Fetches
    func fetchMedicationsForTime(userId: String, mealTime: MealType) async throws -> [MedicationModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            logger.error("[CoreDataManager] fetchMedicationsForTime failed - store not ready. Status: \(String(describing: self.dataStoreStatus))")
            throw AppError.data(.storeNotAvailable)
        }
        
        logger.debug("[CoreDataManager] fetchMedicationsForTime starting - userId: \(userId), mealTime: \(mealTime.rawValue)")
        
        // First fetch all medications for the user
        let allMedications = try await fetchMedications(for: userId)
        logger.debug("[CoreDataManager] fetchMedicationsForTime - fetched \(allMedications.count) total medications")
        
        // Filter by meal time window
        let mealHour = mealTime.defaultTime.hour
        let calendar = Calendar.current
        
        let filtered = allMedications.filter { medication in
            medication.schedule.contains { schedule in
                let scheduleHour = calendar.component(.hour, from: schedule.time)
                // Check if medication is within 2 hours of typical meal time
                let isWithinMealWindow = abs(scheduleHour - mealHour) <= 2
                
                if isWithinMealWindow {
                    self.logger.debug("[CoreDataManager] Medication '\(medication.name)' scheduled at hour \(scheduleHour) matches meal time \(mealTime.rawValue)")
                }
                
                return isWithinMealWindow
            }
        }
        
        logger.info("[CoreDataManager] fetchMedicationsForTime completed - found \(filtered.count) medications for \(mealTime.rawValue) out of \(allMedications.count) total")
        return filtered
    }
    
    func fetchSupplementsForTime(userId: String, mealTime: MealType) async throws -> [SupplementModel] {
        // Ensure store is loaded before any operation
        try await ensureStoreLoaded()
        
        guard dataStoreStatus.isReady else {
            logger.error("[CoreDataManager] fetchSupplementsForTime failed - store not ready. Status: \(String(describing: self.dataStoreStatus))")
            throw AppError.data(.storeNotAvailable)
        }
        
        logger.debug("[CoreDataManager] fetchSupplementsForTime starting - userId: \(userId), mealTime: \(mealTime.rawValue)")
        
        // First fetch all supplements for the user
        let allSupplements = try await fetchSupplements(for: userId)
        logger.debug("[CoreDataManager] fetchSupplementsForTime - fetched \(allSupplements.count) total supplements")
        
        // Filter by meal time
        let mealHour = mealTime.defaultTime.hour
        let calendar = Calendar.current
        
        let filtered = allSupplements.filter { supplement in
            // Check if supplement is taken with food
            if supplement.isTakenWithFood {
                self.logger.debug("[CoreDataManager] Supplement '\(supplement.name)' is taken with food - including for \(mealTime.rawValue)")
                return true
            }
            
            // Otherwise check specific timing from schedule
            let hasMatchingSchedule = supplement.schedule.contains { schedule in
                // Check if this schedule item is marked for meal time
                if schedule.withMeal {
                    self.logger.debug("[CoreDataManager] Supplement '\(supplement.name)' has schedule marked withMeal")
                    return true
                }
                
                // Check if the time matches the meal window
                let scheduleHour = calendar.component(.hour, from: schedule.time)
                let isWithinMealWindow = abs(scheduleHour - mealHour) <= 2
                
                if isWithinMealWindow {
                    self.logger.debug("[CoreDataManager] Supplement '\(supplement.name)' scheduled at hour \(scheduleHour) matches meal time \(mealTime.rawValue)")
                }
                
                return isWithinMealWindow
            }
            
            return hasMatchingSchedule
        }
        
        logger.info("[CoreDataManager] fetchSupplementsForTime completed - found \(filtered.count) supplements for \(mealTime.rawValue) out of \(allSupplements.count) total")
        return filtered
    }
}
