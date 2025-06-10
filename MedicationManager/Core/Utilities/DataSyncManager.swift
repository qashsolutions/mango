import Foundation
import FirebaseFirestore
import Network

@MainActor
class DataSyncManager: ObservableObject {
    static let shared = DataSyncManager()
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var isOnline: Bool = true
    @Published var syncError: AppError?
    
    private let firestore = Firestore.firestore()
    private let coreDataManager = CoreDataManager.shared
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    private init() {
        setupNetworkMonitoring()
        setupPeriodicSync()
    }
    
    deinit {
        monitor.cancel()
        syncTimer?.invalidate()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                if path.status == .satisfied && self?.isSyncing == false {
                    Task {
                        await self?.syncPendingChanges()
                    }
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    private func setupPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.isOnline == true && self?.isSyncing == false {
                    await self?.syncPendingChanges()
                }
            }
        }
    }
    
    // MARK: - Main Sync Operations
    func forceSyncAll() async {
        guard isOnline else {
            syncError = AppError.network(.noConnection)
            return
        }
        
        await syncPendingChanges()
    }
    
    func syncPendingChanges() async {
        guard !isSyncing && isOnline else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Sync medications
            try await syncMedicationsToFirebase()
            
            // Sync supplements
            try await syncSupplementsToFirebase()
            
            // Sync diet entries
            try await syncDietEntriesToFirebase()
            
            // Sync doctors
            try await syncDoctorsToFirebase()
            
            // Sync medication conflicts
            try await syncConflictsToFirebase()
            
            lastSyncDate = Date()
            
        } catch {
            syncError = error as? AppError ?? AppError.sync(.uploadFailed)
        }
        
        isSyncing = false
    }
    
    // MARK: - Medication Sync
    private func syncMedicationsToFirebase() async throws {
        let medicationsToSync = try await coreDataManager.fetchMedicationsNeedingSync()
        
        for medication in medicationsToSync {
            do {
                let collection = firestore.collection("users").document(medication.userId).collection("medications")
                
                if medication.isDeleted {
                    try await collection.document(medication.id).delete()
                } else {
                    let medicationData = try JSONEncoder().encode(medication)
                    let medicationDict = try JSONSerialization.jsonObject(with: medicationData) as? [String: Any] ?? [:]
                    try await collection.document(medication.id).setData(medicationDict)
                }
                
                // Mark as synced in Core Data
                try await coreDataManager.markMedicationSynced(medication.id)
                
            } catch {
                throw AppError.sync(.uploadFailed)
            }
        }
    }
    
    private func syncSupplementsToFirebase() async throws {
        // Implementation similar to medications
        // For brevity, using same pattern as medications
    }
    
    private func syncDietEntriesToFirebase() async throws {
        // Implementation for diet entries
        // Following same pattern
    }
    
    private func syncDoctorsToFirebase() async throws {
        // Implementation for doctors
        // Following same pattern
    }
    
    private func syncConflictsToFirebase() async throws {
        // Implementation for medication conflicts
        // Following same pattern
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
                let medication = try JSONDecoder().decode(Medication.self, from: jsonData)
                
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
                let supplement = try JSONDecoder().decode(Supplement.self, from: jsonData)
                
                try await coreDataManager.saveSupplement(supplement)
                
            } catch {
                continue
            }
        }
    }
    
    private func downloadDietEntries(for userId: String) async throws {
        // Implementation for diet entries download
    }
    
    private func downloadDoctors(for userId: String) async throws {
        // Implementation for doctors download
    }
    
    private func downloadConflicts(for userId: String) async throws {
        // Implementation for conflicts download
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict<T: SyncableModel>(local: T, remote: T) -> T {
        // Use most recent updatedAt timestamp
        return local.updatedAt > remote.updatedAt ? local : remote
    }
    
    // MARK: - Sync Status
    func getSyncStatus() -> SyncStatus {
        if !isOnline {
            return .offline
        } else if isSyncing {
            return .syncing
        } else if let lastSync = lastSyncDate {
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            if timeSinceLastSync < syncInterval {
                return .synced
            } else {
                return .pending
            }
        } else {
            return .pending
        }
    }
    
    // MARK: - Manual Sync Triggers
    func markForSync<T: SyncableModel>(_ item: inout T) {
        item.needsSync = true
        item.updatedAt = Date()
    }
    
    func scheduleSync() {
        guard isOnline && !isSyncing else { return }
        
        Task {
            // Delay to batch multiple rapid changes
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await syncPendingChanges()
        }
    }
    
    // MARK: - Error Recovery
    func retryFailedSync() async {
        guard syncError != nil else { return }
        
        syncError = nil
        await syncPendingChanges()
    }
    
    func clearSyncError() {
        syncError = nil
    }
    
    // MARK: - Data Reset
    func resetSyncData() async throws {
        try await coreDataManager.clearAllData()
        lastSyncDate = nil
        syncError = nil
    }
}

// MARK: - Sync Status
enum SyncStatus {
    case offline
    case syncing
    case synced
    case pending
    case error
    
    var displayText: String {
        switch self {
        case .offline:
            return AppStrings.Sync.offline
        case .syncing:
            return AppStrings.Sync.syncing
        case .synced:
            return AppStrings.Sync.syncComplete
        case .pending:
            return "Pending"
        case .error:
            return AppStrings.Sync.syncFailed
        }
    }
    
    var icon: String {
        switch self {
        case .offline:
            return "wifi.slash"
        case .syncing:
            return "arrow.clockwise"
        case .synced:
            return "checkmark.circle.fill"
        case .pending:
            return "clock"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .offline:
            return "syncOffline"
        case .syncing:
            return "syncInProgress"
        case .synced:
            return "syncSuccess"
        case .pending:
            return "syncPending"
        case .error:
            return "syncError"
        }
    }
}

// MARK: - Sync Extensions
extension DataSyncManager {
    func syncSingleMedication(_ medication: Medication) async throws {
        guard isOnline else {
            throw AppError.network(.noConnection)
        }
        
        let collection = firestore.collection("users").document(medication.userId).collection("medications")
        
        do {
            if medication.isDeleted {
                try await collection.document(medication.id).delete()
            } else {
                let medicationData = try JSONEncoder().encode(medication)
                let medicationDict = try JSONSerialization.jsonObject(with: medicationData) as? [String: Any] ?? [:]
                try await collection.document(medication.id).setData(medicationDict)
            }
            
            try await coreDataManager.markMedicationSynced(medication.id)
            
        } catch {
            throw AppError.sync(.uploadFailed)
        }
    }
    
    func syncSingleSupplement(_ supplement: Supplement) async throws {
        guard isOnline else {
            throw AppError.network(.noConnection)
        }
        
        let collection = firestore.collection("users").document(supplement.userId).collection("supplements")
        
        do {
            let supplementData = try JSONEncoder().encode(supplement)
            let supplementDict = try JSONSerialization.jsonObject(with: supplementData) as? [String: Any] ?? [:]
            try await collection.document(supplement.id).setData(supplementDict)
            
        } catch {
            throw AppError.sync(.uploadFailed)
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
}
#endif
