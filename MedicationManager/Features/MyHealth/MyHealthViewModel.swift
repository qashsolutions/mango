import Foundation
import SwiftUI
import OSLog
import Observation

// MARK: - MyHealthViewModel
/// ViewModel for MyHealthView using modern @Observable macro (iOS 17+)
/// Manages health data including medications, supplements, and diet entries
@Observable
@MainActor
final class MyHealthViewModel {
    // MARK: - Observable Properties
    // No @Published needed with @Observable - all stored properties are automatically observable
    var medications: [MedicationModel] = []
    var supplements: [SupplementModel] = []
    var dietEntries: [DietEntryModel] = []
    var isLoading: Bool = false
    var error: AppError?
    
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "MyHealthViewModel")
    private let coreDataManager = CoreDataManager.shared
    private let dataSyncManager = DataSyncManager.shared
    private let authManager = FirebaseManager.shared
    private let analyticsManager = AnalyticsManager.shared
    
    // MARK: - Computed Properties
    var todaysMedications: [MedicationModel] {
        medications.filter { medication in
            medication.isActive && hasDoseToday(medication)
        }
    }
    
    var todaysSupplements: [SupplementModel] {
        supplements.filter { supplement in
            supplement.isActive && hasDoseToday(supplement)
        }
    }
    
    var todaysDietEntries: [DietEntryModel] {
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
        // For now, calculate based on completed vs total scheduled items
        let completedMedications = todaysMedications.filter { medication in
            medication.schedule.allSatisfy { $0.isCompleted }
        }.count
        
        let completedSupplements = todaysSupplements.filter { supplement in
            supplement.schedule.allSatisfy { $0.isCompleted }
        }.count
        
        let completedItems = completedMedications + completedSupplements
        return totalItems > 0 ? Double(completedItems) / Double(totalItems) : 1.0
    }
    
    // MARK: - Data Loading
    func loadData() async {
        guard let userId = authManager.currentUser?.id else {
            await handleError(AppError.authentication(.notAuthenticated), operation: "authentication check")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Use async let for concurrent loading - better performance for elderly users
            async let medicationsTask = loadMedications(for: userId)
            async let supplementsTask = loadSupplements(for: userId)
            async let dietEntriesTask = loadDietEntries(for: userId)
            
            medications = try await medicationsTask
            supplements = try await supplementsTask
            dietEntries = try await dietEntriesTask
            
            analyticsManager.trackScreenViewed("my_health")
            logger.info("Successfully loaded health data for user: \(userId)")
            
        } catch {
            await handleError(error, operation: "data loading")
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        // Force sync and reload data
        do {
            try await dataSyncManager.syncPendingChanges()
            logger.info("Successfully synced pending changes")
        } catch {
            // Log sync error but continue with data refresh
            // Sync errors shouldn't prevent viewing local data
            logger.warning("Sync failed during refresh: \(error)")
        }
        await loadData()
    }
    
    private func loadMedications(for userId: String) async throws -> [MedicationModel] {
        let medications = try await coreDataManager.fetchMedications(for: userId)
        logger.debug("Loaded \(medications.count) medications")
        return medications
    }
    
    private func loadSupplements(for userId: String) async throws -> [SupplementModel] {
        let supplements = try await coreDataManager.fetchSupplements(for: userId)
        logger.debug("Loaded \(supplements.count) supplements")
        return supplements
    }
    
    private func loadDietEntries(for userId: String) async throws -> [DietEntryModel] {
        let entries = try await coreDataManager.fetchDietEntries(for: userId)
        logger.debug("Loaded \(entries.count) diet entries")
        return entries
    }
    
    // MARK: - Medication Actions
    func markMedicationTaken(_ medication: MedicationModel) async {
        let updatedMedication = medication
        // TODO: Add taken tracking to medication model
        // updatedMedication.markAsTaken(at: Date())
        
        do {
            try await coreDataManager.saveMedication(updatedMedication)
            
            analyticsManager.trackMedicationTaken(onTime: true)
            logger.info("Marked medication as taken: \(medication.name)")
            
            // Update local state
            if let index = medications.firstIndex(where: { $0.id == medication.id }) {
                medications[index] = updatedMedication
            }
            
        } catch {
            await handleError(error, operation: "marking medication as taken")
        }
    }
    
    func markSupplementTaken(_ supplement: SupplementModel) async {
        let updatedSupplement = supplement
        // TODO: Add taken tracking to supplement model
        // updatedSupplement.markAsTaken(at: Date())
        
        do {
            try await coreDataManager.saveSupplement(updatedSupplement)
            
            analyticsManager.trackSupplementTaken(onTime: true)
            logger.info("Marked supplement as taken: \(supplement.name)")
            
            // Update local state
            if let index = supplements.firstIndex(where: { $0.id == supplement.id }) {
                supplements[index] = updatedSupplement
            }
            
        } catch {
            await handleError(error, operation: "marking supplement as taken")
        }
    }
    
    // MARK: - Diet Actions
    func logMeal(_ dietEntry: DietEntryModel) async {
        var updatedEntry = dietEntry
        updatedEntry.markAsEaten()
        
        do {
            try await coreDataManager.saveDietEntry(updatedEntry)
            
            analyticsManager.trackMealLogged(
                mealType: dietEntry.mealType.rawValue,
                onTime: dietEntry.wasOnTime
            )
            
            logger.info("Logged meal: \(dietEntry.mealType.rawValue)")
            
            // Update local state
            if let index = dietEntries.firstIndex(where: { $0.id == dietEntry.id }) {
                dietEntries[index] = updatedEntry
            } else {
                dietEntries.append(updatedEntry)
            }
        } catch {
            await handleError(error, operation: "logging meal")
        }
    }
    
    // MARK: - Quick Actions
    func performVoiceEntry() async {
        analyticsManager.trackFeatureUsed("voice_quick_entry")
        logger.info("Voice entry feature used")
        // Voice entry will be handled by the voice input sheet
    }
    
    func checkMedicationConflicts() async {
        guard !medications.isEmpty else {
            await handleError(AppError.data(.noData), operation: "conflict check - no medications")
            return
        }
        
        analyticsManager.trackFeatureUsed("quick_conflict_check")
        logger.info("Medication conflict check initiated")
        
        // TODO: Implement conflict checking logic
        // This would integrate with Claude AI in the future
        // For now, we can check basic interactions locally
    }
    
    // MARK: - Helper Methods
    private func hasDoseToday(_ medication: MedicationModel) -> Bool {
        guard !medication.schedule.isEmpty else { return false }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if any schedule item is for today using schema logic: !isCompleted && !skipped
        return medication.schedule.contains { scheduleItem in
            !scheduleItem.isCompleted && !scheduleItem.skipped &&
            calendar.isDate(scheduleItem.time, inSameDayAs: today)
        }
    }
    
    private func hasDoseToday(_ supplement: SupplementModel) -> Bool {
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
    private func handleError(_ error: Error, operation: String) async {
        let appError = error as? AppError ?? AppError.data(.loadFailed)
        logger.error("Failed \(operation): \(error.localizedDescription)")
        
        // Update UI on main actor
        self.error = appError
        
        // Track error for analytics (helps improve app for elderly users)
        analyticsManager.trackError(error, context: operation)
    }
    
    func clearError() {
        error = nil
        logger.debug("Error cleared by user")
    }
    
    func retryLastAction() async {
        logger.info("Retrying last action - reloading data")
        await loadData()
    }
    
    // MARK: - Statistics
    func getHealthSummary() -> HealthSummary {
        let summary = HealthSummary(
            totalMedications: medications.count,
            activeMedications: medications.filter { $0.isActive }.count,
            totalSupplements: supplements.count,
            activeSupplements: supplements.filter { $0.isActive }.count,
            todaysMeals: todaysDietEntries.count,
            adherenceRate: adherenceRate,
            lastUpdated: Date()
        )
        
        logger.debug("Health summary generated: \(summary.totalActiveItems) active items")
        return summary
    }
    
    // MARK: - Voice Query Methods
    
    /// Fetches medications for a specific meal time - used by voice queries
    func getMedicationsForMealTime(_ mealTime: MealType) async -> [MedicationModel] {
        guard let userId = authManager.currentUser?.id else {
            logger.warning("No authenticated user for medication fetch")
            return []
        }
        
        do {
            let medications = try await coreDataManager.fetchMedicationsForTime(userId: userId, mealTime: mealTime)
            logger.debug("Fetched \(medications.count) medications for \(mealTime.rawValue)")
            return medications
        } catch {
            logger.error("Failed to fetch medications for meal time: \(error)")
            return []
        }
    }
    
    /// Fetches supplements for a specific meal time - used by voice queries
    func getSupplementsForMealTime(_ mealTime: MealType) async -> [SupplementModel] {
        guard let userId = authManager.currentUser?.id else {
            logger.warning("No authenticated user for supplement fetch")
            return []
        }
        
        do {
            let supplements = try await coreDataManager.fetchSupplementsForTime(userId: userId, mealTime: mealTime)
            logger.debug("Fetched \(supplements.count) supplements for \(mealTime.rawValue)")
            return supplements
        } catch {
            logger.error("Failed to fetch supplements for meal time: \(error)")
            return []
        }
    }
    
    /// Gets all items (medications and supplements) for a meal time
    func getAllItemsForMealTime(_ mealTime: MealType) async -> (medications: [MedicationModel], supplements: [SupplementModel]) {
        guard let userId = authManager.currentUser?.id else {
            logger.warning("No authenticated user for items fetch")
            return ([], [])
        }
        
        // Use async let for concurrent fetching - better performance
        async let medicationsTask = coreDataManager.fetchMedicationsForTime(userId: userId, mealTime: mealTime)
        async let supplementsTask = coreDataManager.fetchSupplementsForTime(userId: userId, mealTime: mealTime)
        
        do {
            let medications = try await medicationsTask
            let supplements = try await supplementsTask
            logger.debug("Fetched \(medications.count) medications and \(supplements.count) supplements for \(mealTime.rawValue)")
            return (medications, supplements)
        } catch {
            logger.error("Failed to fetch items for meal time: \(error)")
            return ([], [])
        }
    }
    
    // MARK: - Elderly-Specific Helper Methods
    
    /// Check if user needs reminders for upcoming medications
    func getUpcomingReminders(within timeInterval: TimeInterval = 3600) async -> [MedicationModel] {
        let now = Date()
        let futureTime = now.addingTimeInterval(timeInterval)
        
        return todaysMedications.filter { medication in
            medication.schedule.contains { scheduleItem in
                !scheduleItem.isCompleted && 
                scheduleItem.time >= now && 
                scheduleItem.time <= futureTime
            }
        }
    }
    
    /// Get medications that are overdue
    func getOverdueMedications() async -> [MedicationModel] {
        let now = Date()
        
        return todaysMedications.filter { medication in
            medication.schedule.contains { scheduleItem in
                !scheduleItem.isCompleted && 
                !scheduleItem.skipped &&
                scheduleItem.time < now
            }
        }
    }
    
    /// Check for potential issues that elderly users should be aware of
    func performHealthChecks() async -> [HealthAlert] {
        var alerts: [HealthAlert] = []
        
        // Check for overdue medications
        let overdue = await getOverdueMedications()
        if !overdue.isEmpty {
            alerts.append(HealthAlert(
                type: .overdueMedication,
                message: "You have \(overdue.count) overdue medication(s)",
                severity: .high
            ))
        }
        
        // Check adherence rate
        if adherenceRate < 0.7 {
            alerts.append(HealthAlert(
                type: .lowAdherence,
                message: "Your medication adherence is below 70%",
                severity: .medium
            ))
        }
        
        // Check for missing meals
        if todaysDietEntries.count < 2 {
            alerts.append(HealthAlert(
                type: .missedMeals,
                message: "You may have missed some meals today",
                severity: .low
            ))
        }
        
        logger.info("Health checks completed: \(alerts.count) alerts generated")
        return alerts
    }
}

// MARK: - Health Summary Model
struct HealthSummary: Sendable {
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
    
    var adherenceDescription: String {
        switch adherenceRate {
        case 0.9...1.0:
            return "Excellent adherence"
        case 0.7..<0.9:
            return "Good adherence"
        case 0.5..<0.7:
            return "Needs improvement"
        default:
            return "Poor adherence"
        }
    }
}

// MARK: - Health Alert Model
struct HealthAlert: Sendable, Identifiable {
    let id = UUID()
    let type: AlertType
    let message: String
    let severity: Severity
    let timestamp = Date()
    
    enum AlertType: Sendable {
        case overdueMedication
        case lowAdherence
        case missedMeals
        case medicationConflict
    }
    
    enum Severity: Sendable {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return AppTheme.Colors.warning
            case .medium: return AppTheme.Colors.warning
            case .high: return AppTheme.Colors.error
            }
        }
    }
}

// MARK: - Sample Data Extension
#if DEBUG
extension MyHealthViewModel {
    static let sampleViewModel: MyHealthViewModel = {
        let viewModel = MyHealthViewModel()
        viewModel.medications = MedicationModel.sampleMedications
        viewModel.supplements = SupplementModel.sampleSupplements
        viewModel.dietEntries = DietEntryModel.sampleDietEntries
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

extension HealthAlert {
    static let sampleAlerts: [HealthAlert] = [
        HealthAlert(
            type: .overdueMedication,
            message: "Blood pressure medication is 2 hours overdue",
            severity: .high
        ),
        HealthAlert(
            type: .lowAdherence,
            message: "Weekly adherence rate has dropped to 65%",
            severity: .medium
        ),
        HealthAlert(
            type: .missedMeals,
            message: "No breakfast logged today",
            severity: .low
        )
    ]
}
#endif