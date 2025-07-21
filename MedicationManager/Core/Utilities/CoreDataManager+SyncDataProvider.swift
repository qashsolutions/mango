import Foundation

// MARK: - SyncDataProvider Protocol Conformance
/// NOTE: CoreDataManager already conforms to SyncDataProvider in the main file (CoreDataManager.swift:919)
/// This extension file is kept for documentation purposes only.
///
/// All required SyncDataProvider methods are implemented in the main CoreDataManager class:
///
/// ✅ Fetch Methods:
/// - fetchMedicationsNeedingSync() async throws -> [MedicationModel]
/// - fetchSupplementsNeedingSync() async throws -> [SupplementModel]
/// - fetchDietEntriesNeedingSync() async throws -> [DietEntryModel]
/// - fetchDoctorsNeedingSync() async throws -> [DoctorModel]
/// - fetchConflictsNeedingSync() async throws -> [MedicationConflict]
///
/// ✅ Mark Synced Methods:
/// - markMedicationSynced(_ id: String) async throws
/// - markSupplementSynced(_ id: String) async throws
/// - markDietEntrySynced(_ id: String) async throws
/// - markDoctorSynced(_ id: String) async throws
/// - markConflictSynced(_ id: String) async throws
///
/// Following Apple's Core Data guidance: @MainActor class with Core Data's 
/// built-in threading, not Sendable conformance.