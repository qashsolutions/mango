import Foundation
import FirebaseFirestore
import Network
import Observation
import OSLog

// MARK: - Sync Data Provider Protocol
/// Protocol defining the data persistence operations needed for syncing
/// This abstraction allows DataSyncManager to work with any data provider
/// without direct coupling to CoreDataManager
@MainActor
protocol SyncDataProvider {
    // MARK: - Fetch Operations
    func fetchMedicationsNeedingSync() async throws -> [MedicationModel]
    func fetchSupplementsNeedingSync() async throws -> [SupplementModel]
    func fetchDietEntriesNeedingSync() async throws -> [DietEntryModel]
    func fetchDoctorsNeedingSync() async throws -> [DoctorModel]
    func fetchConflictsNeedingSync() async throws -> [MedicationConflict]
    
    // MARK: - Mark Synced Operations
    func markMedicationSynced(_ id: String) async throws
    func markSupplementSynced(_ id: String) async throws
    func markDietEntrySynced(_ id: String) async throws
    func markDoctorSynced(_ id: String) async throws
    func markConflictSynced(_ id: String) async throws
}

// MARK: - Sync Request Types
/// Defines all possible sync request types in a type-safe manner
/// This pattern avoids Sendable closure issues while providing clear intent
enum SyncRequest: Sendable {
    case forceSyncAll
    case syncPendingChanges
    case networkReconnected
    case coreDataNotification(reason: String, userId: String?)
    case periodicSync
    case scheduledSync
    
    /// Human-readable description for logging
    var description: String {
        switch self {
        case .forceSyncAll:
            return "Force sync all"
        case .syncPendingChanges:
            return "Sync pending changes"
        case .networkReconnected:
            return "Network reconnected"
        case .coreDataNotification(let reason, let userId):
            return "CoreData notification - reason: \(reason), userId: \(userId ?? "none")"
        case .periodicSync:
            return "Periodic sync"
        case .scheduledSync:
            return "Scheduled sync"
        }
    }
}

// MARK: - Task Storage Actor for Swift 6 Concurrency
private actor TaskStorage {
    private var task: Task<Void, Never>?
    
    func setTask(_ newTask: Task<Void, Never>) {
        task = newTask
    }
    
    func getTask() -> Task<Void, Never>? {
        return task
    }
    
    func cancel() {
        task?.cancel()
    }
}

// MARK: - Sync State Manager Actor
/// Actor responsible for managing sync state atomically to prevent race conditions
/// This ensures only one sync operation can run at a time
private actor SyncStateManager {
    private var isSyncing = false
    private var syncTask: Task<Void, Error>?
    
    /// Attempts to begin a sync operation. Returns true if sync can proceed, false if already syncing
    /// This method is atomic due to actor isolation, preventing race conditions
    func beginSyncIfNeeded() async -> Bool {
        guard !isSyncing else {
            return false
        }
        isSyncing = true
        return true
    }
    
    /// Marks the sync operation as complete and cleans up resources
    func endSync() {
        isSyncing = false
        syncTask = nil
    }
    
    /// Stores the current sync task for potential cancellation
    func setSyncTask(_ task: Task<Void, Error>) {
        syncTask = task
    }
    
    /// Cancels any ongoing sync operation
    func cancelCurrentSync() {
        syncTask?.cancel()
        isSyncing = false
        syncTask = nil
    }
    
    /// Returns the current sync state
    func isCurrentlySyncing() -> Bool {
        return isSyncing
    }
}

// MARK: - Sync Request Queue
/// Actor that manages sync requests with debouncing to prevent rapid successive syncs
/// This helps prevent overwhelming the system with sync requests from multiple sources
private actor SyncQueue {
    private var pendingSyncTask: Task<Void, Never>?
    private let debounceInterval: Duration = .seconds(1)
    
    /// Requests a sync operation with automatic debouncing
    /// If multiple requests come in rapidly, only the last one will execute
    /// Uses explicit request types to avoid Sendable closure issues
    func requestSync(_ request: SyncRequest, manager: DataSyncManager) {
        // Cancel any pending sync to implement debouncing
        pendingSyncTask?.cancel()
        
        // Log the sync request
        print("🔷 [SYNC] Sync requested: \(request.description)")
        
        // Create a new task that waits for the debounce interval
        pendingSyncTask = Task {
            do {
                // Wait for debounce interval
                try await Task.sleep(for: debounceInterval)
                
                // Check if we were cancelled during the wait
                guard !Task.isCancelled else { 
                    print("🔷 [SYNC] Sync request cancelled: \(request.description)")
                    return 
                }
                
                // Process the sync request on MainActor where DataSyncManager lives
                await MainActor.run {
                    print("🔷 [SYNC] Processing sync request (after debounce): \(request.description)")
                }
                
                // Call processSyncRequest directly since manager is MainActor-isolated
                await manager.processSyncRequest(request)
            } catch {
                // Task cancellation is expected during debouncing
                if !(error is CancellationError) {
                    print("🔷 [SYNC] Sync queue error: \(error)")
                }
            }
        }
    }
    
    /// Cancels any pending sync requests
    func cancelPendingSync() {
        pendingSyncTask?.cancel()
        pendingSyncTask = nil
    }
}

@Observable
@MainActor
final class DataSyncManager: DataSyncManagerProtocol {
    // Static shared instance with default data provider
    static let shared = DataSyncManager()
    
    // Logger for this class
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "DataSync")
    
    // Observable properties (no @Published needed with @Observable)
    var isSyncing = false
    var lastSyncDate: Date?
    var isOnline = true
    var syncError: AppError?
    
    // Computed property to check if there are pending changes
    var hasPendingChanges: Bool {
        // Check if any entities need syncing
        // This is a simple implementation - you may want to enhance this based on your sync logic
        return lastSyncDate == nil || Date().timeIntervalSince(lastSyncDate ?? Date()) > 300
    }
    
    // MARK: - Dependencies
    // Use protocol instead of concrete type for better testability and decoupling
    private let dataProvider: SyncDataProvider
    private let coreDataManager = CoreDataManager.shared
    private var _firestore: Firestore?
    
    private var firestore: Firestore {
        if _firestore == nil {
            _firestore = Firestore.firestore()
        }
        return _firestore!
    }
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    // Modern async approach with proper actor isolation
    private let syncTaskStorage = TaskStorage()
    private let syncInterval: Duration = .seconds(300)
    
    // Actors for managing sync state and preventing race conditions
    private let syncStateManager = SyncStateManager()
    private let syncQueue = SyncQueue()
    
    // MARK: - Initialization
    /// Initialize with a data provider (defaults to CoreDataManager for production)
    /// This allows injection of mock providers for testing
    init(dataProvider: SyncDataProvider = CoreDataManager.shared) {
        self.dataProvider = dataProvider
        
        // Setup monitoring and sync after initialization
        setupNetworkMonitoring()
        setupPeriodicSync()
        observeCoreSyncNotifications()
    }
    
    /// Private convenience initializer for shared instance
    private convenience init() {
        self.init(dataProvider: CoreDataManager.shared)
    }
    
    deinit {
        // Cancel sync task - capture the actors before deinit
        let storage = syncTaskStorage
        let stateManager = syncStateManager
        let queue = syncQueue
        
        Task {
            // Cancel all ongoing operations
            await storage.cancel()
            await stateManager.cancelCurrentSync()
            await queue.cancelPendingSync()
        }
        
        monitor.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Core Data Sync Notification Observer
    /// Observe notifications from CoreDataManager for sync requests
    private func observeCoreSyncNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCoreSyncNotification),
            name: .coreDataNeedsSync,
            object: nil
        )
    }
    
    @objc private func handleCoreSyncNotification(_ notification: Notification) {
        print("🔷 [SYNC] handleCoreSyncNotification called")
        print("🔷 [SYNC] Called on thread: \(Thread.current), isMain: \(Thread.isMainThread)")
        
        // Extract userInfo for the sync request
        let reason = notification.userInfo?["reason"] as? String ?? "unknown"
        let userId = notification.userInfo?["userId"] as? String
        
        // Create a sync request with the notification details
        let syncRequest = SyncRequest.coreDataNotification(reason: reason, userId: userId)
        
        // Use sync queue to handle the request with debouncing
        // This prevents multiple rapid sync requests from overwhelming the system
        Task { [weak self] in
            guard let self else { return }
            await self.syncQueue.requestSync(syncRequest, manager: self)
        }
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            
            // Update online status on MainActor
            Task { @MainActor in
                self.isOnline = path.status == .satisfied
            }
            
            // Only trigger sync if network comes back online after being offline
            if path.status == .satisfied {
                Task { [weak self] in
                    guard let self else { return }
                    
                    // Check if we should sync (have previous sync date)
                    let shouldSync = await MainActor.run {
                        self.lastSyncDate != nil
                    }
                    
                    guard shouldSync else { return }
                    
                    // Check Core Data status before syncing
                    guard case .ready = await CoreDataManager.shared.dataStoreStatus else {
                        print("🔷 [SYNC] Network monitor: Core Data not ready, skipping sync")
                        return
                    }
                    
                    // Use sync queue with network reconnected request type
                    await self.syncQueue.requestSync(.networkReconnected, manager: self)
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    private func setupPeriodicSync() {
        print("🔷 [SYNC] setupPeriodicSync() called")
        let interval = syncInterval  // Capture the value before the Task
        let task = Task { [weak self] in
            print("🔷 [SYNC] Periodic sync task started")
            while !Task.isCancelled {
                do {
                    print("🔷 [SYNC] Periodic sync sleeping for \(interval)")
                    try await Task.sleep(for: interval)  // Use captured value directly
                    
                    print("🔷 [SYNC] Periodic sync woke up, checking conditions...")
                    
                    // Check conditions
                    guard let self else { return }
                    
                    let canSync = await MainActor.run {
                        self.isOnline
                    }
                    
                    guard canSync else {
                        print("🔷 [SYNC] Periodic sync skipped - not online")
                        continue
                    }
                    
                    // Use sync queue to prevent conflicts with other sync triggers
                    // The sync queue will handle debouncing if other syncs are pending
                    await self.syncQueue.requestSync(.periodicSync, manager: self)
                } catch {
                    // Task cancellation - exit the loop
                    break
                }
            }
            print("🔷 [SYNC] Periodic sync task ended")
        }
        
        // Store the task in the actor
        Task {
            await syncTaskStorage.setTask(task)
        }
    }
    
    // MARK: - Main Sync Operations
    func forceSyncAll() async throws {
        guard isOnline else {
            let error = AppError.network(.noConnection)
            syncError = error
            throw error
        }
        
        try await syncPendingChanges()
    }
    
    // MARK: - Sync Request Processing
    /// Processes sync requests based on their type
    /// This method is called by the SyncQueue actor after debouncing
    @MainActor
    func processSyncRequest(_ request: SyncRequest) async {
        print("🔷 [SYNC] Processing sync request: \(request.description)")
        
        do {
            switch request {
            case .forceSyncAll:
                try await forceSyncAll()
                
            case .syncPendingChanges:
                try await syncPendingChanges()
                
            case .networkReconnected:
                // Only sync if we have a previous sync date
                if lastSyncDate != nil {
                    try await syncPendingChanges()
                }
                
            case .coreDataNotification(let reason, let userId):
                // Log the notification details
                print("🔷 [SYNC] Processing CoreData notification - reason: \(reason), userId: \(userId ?? "none")")
                try await forceSyncAll()
                
            case .periodicSync:
                // Periodic sync only runs if online and not already syncing
                if isOnline && !isSyncing {
                    try await syncPendingChanges()
                }
                
            case .scheduledSync:
                // Scheduled sync for batching rapid changes
                try await syncPendingChanges()
            }
        } catch {
            // Handle sync errors
            print("🔷 [SYNC] Sync request failed: \(request.description), error: \(error)")
            syncError = error as? AppError ?? AppError.sync(.uploadFailed)
        }
    }
    
    func syncPendingChanges() async throws {
        print("🔷 [SYNC] syncPendingChanges() called")
        
        // Use actor to atomically check and set sync state
        // This prevents race conditions where multiple syncs could start simultaneously
        let canSync = await syncStateManager.beginSyncIfNeeded()
        
        guard canSync else {
            print("🔷 [SYNC] Skipping - sync already in progress (checked atomically via actor)")
            throw AppError.sync(.syncInProgress)
        }
        
        // Ensure we always clean up sync state, even if an error occurs
        defer {
            Task {
                await syncStateManager.endSync()
                // Update UI state on MainActor
                await MainActor.run {
                    self.isSyncing = false
                }
            }
        }
        
        // Check network status
        guard isOnline else {
            print("🔷 [SYNC] Skipping - not online")
            throw AppError.network(.noConnection)
        }
        
        print("🔷 [SYNC] Starting sync process...")
        
        // Update UI state on MainActor
        await MainActor.run {
            self.isSyncing = true
            self.syncError = nil
        }
        
        do {
            // Create a sync task that can be cancelled if needed
            let syncTask = Task {
                // Support cancellation throughout
                try Task.checkCancellation()
                
                // Sync medications
                try await syncMedicationsToFirebase()
                
                try Task.checkCancellation()
                
                // Sync supplements
                try await syncSupplementsToFirebase()
                
                try Task.checkCancellation()
                
                // Sync diet entries
                try await syncDietEntriesToFirebase()
                
                try Task.checkCancellation()
                
                // Sync doctors
                try await syncDoctorsToFirebase()
                
                try Task.checkCancellation()
                
                // Sync medication conflicts
                try await syncConflictsToFirebase()
            }
            
            // Store the task in case we need to cancel it later
            await syncStateManager.setSyncTask(syncTask)
            
            // Wait for the sync task to complete
            try await syncTask.value
            
            // Update last sync date on success
            await MainActor.run {
                self.lastSyncDate = Date()
            }
            
            print("🔷 [SYNC] Sync completed successfully")
            
        } catch {
            let appError = error as? AppError ?? AppError.sync(.uploadFailed)
            
            // Update error state on MainActor
            await MainActor.run {
                self.syncError = appError
            }
            
            print("🔷 [SYNC] Sync failed with error: \(appError)")
            throw appError
        }
    }
    
    // MARK: - Medication Sync
    private func syncMedicationsToFirebase() async throws {
        print("🔷 [SYNC] syncMedicationsToFirebase() called")
        // Use protocol-based data provider instead of direct CoreDataManager reference
        print("🔷 [SYNC] About to call fetchMedicationsNeedingSync()...")
        let medicationsToSync = try await dataProvider.fetchMedicationsNeedingSync()
        print("🔷 [SYNC] fetchMedicationsNeedingSync returned \(medicationsToSync.count) items")
        
        for medication in medicationsToSync {
            try Task.checkCancellation() // Support cooperative cancellation
            
            let collection = firestore.collection("users")
                .document(medication.userId)
                .collection("medications")
            
            if medication.isDeletedFlag {
                try await collection.document(medication.id).delete()
            } else {
                // Use Firebase's Codable support - no manual serialization
                try collection.document(medication.id).setData(from: medication)
            }
            
            // Mark as synced using protocol method
            try await dataProvider.markMedicationSynced(medication.id)
        }
    }
    
    private func syncSupplementsToFirebase() async throws {
        let supplementsToSync = try await dataProvider.fetchSupplementsNeedingSync()
        
        for supplement in supplementsToSync {
            try Task.checkCancellation()
            
            let collection = firestore.collection("users")
                .document(supplement.userId)
                .collection("supplements")
            
            if supplement.isDeletedFlag {
                try await collection.document(supplement.id).delete()
            } else {
                try collection.document(supplement.id).setData(from: supplement)
            }
            
            try await dataProvider.markSupplementSynced(supplement.id)
        }
    }
    
    private func syncDietEntriesToFirebase() async throws {
        let dietEntriesToSync = try await dataProvider.fetchDietEntriesNeedingSync()
        
        for dietEntry in dietEntriesToSync {
            try Task.checkCancellation()
            
            let collection = firestore.collection("users")
                .document(dietEntry.userId)
                .collection("dietEntries")
            
            if dietEntry.isDeletedFlag {
                try await collection.document(dietEntry.id).delete()
            } else {
                try collection.document(dietEntry.id).setData(from: dietEntry)
            }
            
            try await dataProvider.markDietEntrySynced(dietEntry.id)
        }
    }
    
    private func syncDoctorsToFirebase() async throws {
        let doctorsToSync = try await dataProvider.fetchDoctorsNeedingSync()
        
        for doctor in doctorsToSync {
            try Task.checkCancellation()
            
            let collection = firestore.collection("users")
                .document(doctor.userId)
                .collection("doctors")
            
            if doctor.isDeletedFlag {
                try await collection.document(doctor.id).delete()
            } else {
                try collection.document(doctor.id).setData(from: doctor)
            }
            
            try await dataProvider.markDoctorSynced(doctor.id)
        }
    }
    
    private func syncConflictsToFirebase() async throws {
        let conflictsToSync = try await dataProvider.fetchConflictsNeedingSync()
        
        for conflict in conflictsToSync {
            try Task.checkCancellation()
            
            let collection = firestore.collection("users")
                .document(conflict.userId)
                .collection("conflicts")
            
            if conflict.isDeletedFlag {
                try await collection.document(conflict.id).delete()
            } else {
                try collection.document(conflict.id).setData(from: conflict)
            }
            
            try await dataProvider.markConflictSynced(conflict.id)
        }
    }
    
    // MARK: - Batch Operations
    private func performBatchSync<T: Codable & Identifiable>(
        items: [T],
        collectionPath: (String) -> CollectionReference,
        markSynced: ((String) async throws -> Void)?
    ) async throws where T.ID == String {
        let batchSize = 10
        let chunks = items.chunked(into: batchSize)
        
        for chunk in chunks {
            try Task.checkCancellation()
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let batch = firestore.batch()
                
                for item in chunk {
                    let docRef = collectionPath(item.id).document(item.id)
                    do {
                        try batch.setData(from: item, forDocument: docRef)
                    } catch {
                        continuation.resume(throwing: error)
                        return
                    }
                }
                
                batch.commit { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            
            // Mark items as synced
            if let markSynced = markSynced {
                for item in chunk {
                    try await markSynced(item.id)
                }
            }
        }
    }
    
    // MARK: - Download Sync
    func downloadUserData(for userId: String) async throws {
        guard isOnline else {
            throw AppError.network(.noConnection)
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Download medications
            try await downloadMedications(for: userId)
            
            // Download supplements
            try await downloadSupplements(for: userId)
            
            // Download diet entries
            try await downloadDietEntries(for: userId)
            
            // Download doctors
            try await downloadDoctors(for: userId)
            
            // Download conflicts
            try await downloadConflicts(for: userId)
            
            lastSyncDate = Date()
            
        } catch {
            throw AppError.sync(.downloadFailed)
        }
    }
    
    private func downloadMedications(for userId: String) async throws {
        let collection = firestore.collection("users").document(userId).collection("medications")
        let snapshot = try await collection.getDocuments()
        
        for document in snapshot.documents {
            do {
                let data = document.data()
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let medication = try JSONDecoder().decode(MedicationModel.self, from: jsonData)
                
                try await coreDataManager.saveMedication(medication)
                
            } catch {
                // Log error but continue with other documents
                continue
            }
        }
    }
    
    private func downloadSupplements(for userId: String) async throws {
        let collection = firestore.collection("users").document(userId).collection("supplements")
        let snapshot = try await collection.getDocuments()
        
        for document in snapshot.documents {
            do {
                let data = document.data()
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let supplement = try JSONDecoder().decode(SupplementModel.self, from: jsonData)
                
                try await coreDataManager.saveSupplement(supplement)
                
            } catch {
                continue
            }
        }
    }
    
    private func downloadDietEntries(for userId: String) async throws {
        let collection = firestore.collection("users").document(userId).collection("dietEntries")
        let snapshot = try await collection.getDocuments()
        
        for document in snapshot.documents {
            do {
                let data = document.data()
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let dietEntry = try JSONDecoder().decode(DietEntryModel.self, from: jsonData)
                
                try await coreDataManager.saveDietEntry(dietEntry)
                
            } catch {
                continue
            }
        }
    }
    
    private func downloadDoctors(for userId: String) async throws {
        let collection = firestore.collection("users").document(userId).collection("doctors")
        let snapshot = try await collection.getDocuments()
        
        for document in snapshot.documents {
            do {
                let data = document.data()
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let doctor = try JSONDecoder().decode(DoctorModel.self, from: jsonData)
                
                try await coreDataManager.saveDoctor(doctor)
                
            } catch {
                continue
            }
        }
    }
    
    private func downloadConflicts(for userId: String) async throws {
        let collection = firestore.collection("users").document(userId).collection("conflicts")
        let snapshot = try await collection.getDocuments()
        
        for document in snapshot.documents {
            do {
                let data = document.data()
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let conflict = try JSONDecoder().decode(MedicationConflict.self, from: jsonData)
                
                try await coreDataManager.saveConflict(conflict)
                
            } catch {
                continue
            }
        }
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict<T: SyncableModel>(local: T, remote: T) -> T {
        // Use most recent updatedAt timestamp
        return local.updatedAt > remote.updatedAt ? local : remote
    }
    
    // MARK: - Sync Status
    func getSyncStatus() -> SyncStatus {
        if !isOnline {
            return SyncStatus(displayText: AppStrings.Sync.offline, icon: "wifi.slash", color: "syncOffline")
        } else if isSyncing {
            return SyncStatus(displayText: AppStrings.Sync.syncing, icon: "arrow.clockwise", color: "syncInProgress")
        } else if let lastSync = lastSyncDate {
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            let syncIntervalSeconds = 300.0 // 5 minutes
            if timeSinceLastSync < syncIntervalSeconds {
                return SyncStatus(displayText: AppStrings.Sync.syncComplete, icon: "checkmark.circle.fill", color: "syncSuccess")
            } else {
                return SyncStatus(displayText: "Pending", icon: "clock", color: "syncPending")
            }
        } else {
            return SyncStatus(displayText: "Pending", icon: "clock", color: "syncPending")
        }
    }
    
    // MARK: - Manual Sync Triggers
    func markForSync<T: SyncableModel>(_ item: inout T) {
        item.needsSync = true
        item.updatedAt = Date()
    }
    
    func scheduleSync() {
        guard isOnline else { return }
        
        print("🔷 [SYNC] scheduleSync() called - using sync queue for debouncing")
        
        // Use sync queue which handles debouncing automatically
        Task { [weak self] in
            guard let self else { return }
            await self.syncQueue.requestSync(.scheduledSync, manager: self)
        }
    }
    
    // MARK: - Error Recovery
    func retryFailedSync() async {
        guard syncError != nil else { return }
        
        syncError = nil
        do {
            try await syncPendingChanges()
        } catch {
            // Error will be set by syncPendingChanges
        }
    }
    
    func clearSyncError() {
        syncError = nil
    }
    
    // MARK: - Sync Control
    /// Cancels any ongoing sync operation
    /// This is useful when the app is going to background or user wants to stop sync
    func cancelSync() async {
        print("🔷 [SYNC] Cancelling ongoing sync operations...")
        
        // Cancel at all levels
        await syncStateManager.cancelCurrentSync()
        await syncQueue.cancelPendingSync()
        
        // Update UI state
        await MainActor.run {
            self.isSyncing = false
        }
        
        print("🔷 [SYNC] Sync operations cancelled")
    }
    
    // MARK: - Data Reset
    @available(*, deprecated, message: "This method is dangerous. Use clearUserSyncData(userId:) instead.")
    func resetSyncData() async throws {
        // This method should not be used as it could delete all users' data
        logger.critical("⚠️ DEPRECATED: resetSyncData() called - this method is dangerous")
        throw AppError.caregiver(.accessDenied)
    }
    
    // Safe version that only clears current user's data
    func clearUserSyncData(userId: String) async throws {
        try await coreDataManager.clearUserData(for: userId)
        lastSyncDate = nil
        syncError = nil
        
        logger.info("[DataSyncManager] Cleared sync data for user: \(userId)")
    }
}

// MARK: - Sync Status Struct
struct SyncStatus {
    let displayText: String
    let icon: String
    let color: String
}

// MARK: - Sync Extensions
extension DataSyncManager {
    func syncSingleMedication(_ medication: MedicationModel) async throws {
        guard isOnline else {
            throw AppError.network(.noConnection)
        }
        
        let collection = firestore.collection("users")
            .document(medication.userId)
            .collection("medications")
        
        if medication.isDeletedFlag {
            try await collection.document(medication.id).delete()
        } else {
            // Use Firebase's Codable support
            try collection.document(medication.id).setData(from: medication)
        }
        
        try await coreDataManager.markMedicationSynced(medication.id)
    }
    
    func syncSingleSupplement(_ supplement: SupplementModel) async throws {
        guard isOnline else {
            throw AppError.network(.noConnection)
        }
        
        let collection = firestore.collection("users")
            .document(supplement.userId)
            .collection("supplements")
        
        // Use Firebase's Codable support
        try collection.document(supplement.id).setData(from: supplement)
    }
}

// MARK: - Array Extension
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension DataSyncManager {
    static let mockSyncManager: DataSyncManager = {
        let manager = DataSyncManager()
        manager.isOnline = true
        manager.lastSyncDate = Calendar.current.date(byAdding: .minute, value: -5, to: Date())
        return manager
    }()
    
    @MainActor
    static func createMockManager() -> DataSyncManager {
        let manager = DataSyncManager()
        manager.isOnline = true
        manager.lastSyncDate = Calendar.current.date(byAdding: .minute, value: -5, to: Date())
        return manager
    }
}
#endif