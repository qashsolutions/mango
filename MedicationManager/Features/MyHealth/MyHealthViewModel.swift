import Foundation
import SwiftUI

@MainActor
class MyHealthViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var supplements: [Supplement] = []
    @Published var dietEntries: [DietEntry] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    private let coreDataManager = CoreDataManager.shared
    private let dataSyncManager = DataSyncManager.shared
    private let authManager = FirebaseManager.shared
    private let analyticsManager = AnalyticsManager.shared
    
    // MARK: - Computed Properties
    var todaysMedications: [Medication] {
        medications.filter { medication in
            medication.isActive && hasDoseToday(medication)
        }
    }
    
    var todaysSupplements: [Supplement] {
        supplements.filter { supplement in
            supplement.isActive && hasDoseToday(supplement)
        }
    }
    
    var todaysDietEntries: [DietEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        return dietEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }.sorted { $0.scheduledTime ?? $0.createdAt < $1.scheduledTime ?? $1.createdAt }
    }
    
    var adherenceRate: Double {
        // Calculate today's adherence rate
        let totalMedications = todaysMedications.count
        let totalSupplements = todaysSupplements.count
        let totalItems = totalMedications + totalSupplements
        
        guard totalItems > 0 else { return 1.0 }
        
        // TODO: Implement actual adherence calculation based on taken status
        return 0.85 // Placeholder
    }
    
    // MARK: - Data Loading
    func loadData() async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            async let medicationsTask = loadMedications(for: userId)
            async let supplementsTask = loadSupplements(for: userId)
            async let dietEntriesTask = loadDietEntries(for: userId)
            
            medications = try await medicationsTask
            supplements = try await supplementsTask
            dietEntries = try await dietEntriesTask
            
            analyticsManager.trackScreenViewed("my_health")
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.loadFailed)
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        // Force sync and reload data
        await dataSyncManager.syncPendingChanges()
        await loadData()
    }
    
    private func loadMedications(for userId: String) async throws -> [Medication] {
        return try await coreDataManager.fetchMedications(for: userId)
    }
    
    private func loadSupplements(for userId: String) async throws -> [Supplement] {
        return try await coreDataManager.fetchSupplements(for: userId)
    }
    
    private func loadDietEntries(for userId: String) async throws -> [DietEntry] {
        // TODO: Implement diet entries fetching in CoreDataManager
        return []
    }
    
    // MARK: - Medication Actions
    func markMedicationTaken(_ medication: Medication) async {
        do {
            var updatedMedication = medication
            // TODO: Add taken tracking to medication model
            // updatedMedication.markAsTaken(at: Date())
            
            try await coreDataManager.saveMedication(updatedMedication)
            
            analyticsManager.trackMedicationTaken(onTime: true)
            
            // Update local state
            if let index = medications.firstIndex(where: { $0.id == medication.id }) {
                medications[index] = updatedMedication
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    func markSupplementTaken(_ supplement: Supplement) async {
        do {
            var updatedSupplement = supplement
            // TODO: Add taken tracking to supplement model
            // updatedSupplement.markAsTaken(at: Date())
            
            try await coreDataManager.saveSupplement(updatedSupplement)
            
            analyticsManager.trackSupplementTaken(onTime: true)
            
            // Update local state
            if let index = supplements.firstIndex(where: { $0.id == supplement.id }) {
                supplements[index] = updatedSupplement
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    // MARK: - Diet Actions
    func logMeal(_ dietEntry: DietEntry) async {
        do {
            var updatedEntry = dietEntry
            updatedEntry.markAsEaten()
            
            // TODO: Implement diet entry saving in CoreDataManager
            // try await coreDataManager.saveDietEntry(updatedEntry)
            
            analyticsManager.trackMealLogged(
                mealType: dietEntry.mealType.rawValue,
                onTime: dietEntry.wasOnTime
            )
            
            // Update local state
            if let index = dietEntries.firstIndex(where: { $0.id == dietEntry.id }) {
                dietEntries[index] = updatedEntry
            } else {
                dietEntries.append(updatedEntry)
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    // MARK: - Quick Actions
    func performVoiceEntry() async {
        analyticsManager.trackFeatureUsed("voice_quick_entry")
        // Voice entry will be handled by the voice input sheet
    }
    
    func checkMedicationConflicts() async {
        guard !medications.isEmpty else {
            error = AppError.data(.noData)
            return
        }
        
        analyticsManager.trackFeatureUsed("quick_conflict_check")
        
        // TODO: Implement conflict checking logic
        // This would integrate with MedGemma AI in the future
    }
    
    // MARK: - Helper Methods
    private func hasDoseToday(_ medication: Medication) -> Bool {
        guard !medication.schedule.isEmpty else { return false }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if any schedule item is for today using schema logic: !isCompleted && !skipped
        return medication.schedule.contains { scheduleItem in
            !scheduleItem.isCompleted && !scheduleItem.skipped &&
            calendar.isDate(scheduleItem.time, inSameDayAs: today)
        }
    }
    
    private func hasDoseToday(_ supplement: Supplement) -> Bool {
        guard !supplement.schedule.isEmpty else { return false }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if any schedule item is for today using schema logic: !isCompleted
        return supplement.schedule.contains { scheduleItem in
            !scheduleItem.isCompleted &&
            calendar.isDate(scheduleItem.time, inSameDayAs: today)
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
    
    func retryLastAction() async {
        await loadData()
    }
    
    // MARK: - Statistics
    func getHealthSummary() -> HealthSummary {
        return HealthSummary(
            totalMedications: medications.count,
            activeMedications: medications.filter { $0.isActive }.count,
            totalSupplements: supplements.count,
            activeSupplements: supplements.filter { $0.isActive }.count,
            todaysMeals: todaysDietEntries.count,
            adherenceRate: adherenceRate,
            lastUpdated: Date()
        )
    }
}

// MARK: - Health Summary Model
struct HealthSummary {
    let totalMedications: Int
    let activeMedications: Int
    let totalSupplements: Int
    let activeSupplements: Int
    let todaysMeals: Int
    let adherenceRate: Double
    let lastUpdated: Date
    
    var hasActiveItems: Bool {
        activeMedications > 0 || activeSupplements > 0
    }
    
    var totalActiveItems: Int {
        activeMedications + activeSupplements
    }
    
    var adherenceText: String {
        let percentage = Int(adherenceRate * 100)
        return "\(percentage)%"
    }
    
    var adherenceColor: Color {
        switch adherenceRate {
        case 0.9...1.0:
            return AppTheme.Colors.success
        case 0.7..<0.9:
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.error
        }
    }
}

// MARK: - Sample Data Extension
#if DEBUG
extension MyHealthViewModel {
    static let sampleViewModel: MyHealthViewModel = {
        let viewModel = MyHealthViewModel()
        viewModel.medications = Medication.sampleMedications
        viewModel.supplements = Supplement.sampleSupplements
        viewModel.dietEntries = DietEntry.sampleDietEntries
        return viewModel
    }()
}

extension HealthSummary {
    static let sampleSummary = HealthSummary(
        totalMedications: 5,
        activeMedications: 4,
        totalSupplements: 3,
        activeSupplements: 3,
        todaysMeals: 2,
        adherenceRate: 0.85,
        lastUpdated: Date()
    )
}
#endif
