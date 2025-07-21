import Foundation
import AppIntents
import OSLog
import Observation

// MARK: - Siri Intents Manager
@MainActor
@Observable
final class SiriIntentsManager {
    static let shared = SiriIntentsManager()
    
    // MARK: - Observable Properties
    private(set) var shortcutsEnabled = true // Always enabled for App Intents
    private(set) var recentQueries: [String] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "SiriIntentsManager")
    private let analyticsManager = AnalyticsManager.shared
    
    private init() {
        setupAppIntents()
    }
    
    // MARK: - Setup
    
    private func setupAppIntents() {
        logger.info("App Intents setup complete - Modern Siri integration ready")
        
        // App Intents are automatically available once defined
        // No explicit authorization needed like legacy SiriKit
        
        // Load recent queries from UserDefaults
        loadRecentQueries()
    }
    
    // MARK: - App Intent Donation
    
    /// Donate app intents based on user actions
    func donateIntent(for action: UserAction) {
        switch action {
        case .checkMedications:
            // App Intents are automatically discovered by the system
            // No explicit donation needed, but we track usage
            analyticsManager.trackFeatureUsed("app_intent_check_medications")
            
        case .addMedication(_, _, _):
            // Track usage for intelligent suggestions
            analyticsManager.trackMedicationAdded(
                viaVoice: true,
                medicationType: "prescription"
            )
            
        case .checkConflicts:
            analyticsManager.trackFeatureUsed("app_intent_check_conflicts")
            
        case .logMedication(_, let taken):
            analyticsManager.trackMedicationTaken(onTime: taken)
            
        case .setReminder(_, _):
            analyticsManager.trackFeatureUsed("app_intent_set_reminder")
            
        case .voiceQuery(let query):
            addRecentQuery(query)
            analyticsManager.trackFeatureUsed("app_intent_voice_query")
        }
    }
    
    // MARK: - Intent Handling Support
    
    /// Handle check medications request
    func handleCheckMedications() async -> IntentResult {
        logger.info("Handling check medications via App Intent")
        
        guard let userId = FirebaseManager.shared.currentUser?.id else {
            return IntentResult(
                success: false,
                message: AppStrings.Siri.notSignedInResponse
            )
        }
        
        do {
            let medications = try await CoreDataManager.shared.fetchMedications(for: userId)
            let activeMedications = medications.filter { $0.isActive }
            let medicationCount = activeMedications.count
            
            let response = String(format: AppStrings.Siri.medicationCountResponse, medicationCount)
            
            donateIntent(for: .checkMedications)
            
            return IntentResult(
                success: true,
                message: response
            )
        } catch {
            logger.error("Failed to fetch medications: \(error.localizedDescription)")
            return IntentResult(
                success: false,
                message: AppStrings.Siri.checkMedicationsError
            )
        }
    }
    
    /// Handle add medication request
    func handleAddMedication(name: String, dosage: String?, frequency: String?) async -> IntentResult {
        logger.info("Handling add medication via App Intent")
        
        guard let userId = FirebaseManager.shared.currentUser?.id else {
            return IntentResult(
                success: false,
                message: AppStrings.Siri.notSignedInResponse
            )
        }
        
        do {
            let medFrequency = parseFrequency(frequency) ?? .once
            
            let medication = MedicationModel.create(
                for: userId,
                name: name,
                dosage: dosage ?? AppStrings.Medications.defaultDosage,
                frequency: medFrequency,
                voiceEntryUsed: true
            )
            
            try await CoreDataManager.shared.saveMedication(medication)
            
            let response = String(format: AppStrings.Siri.medicationAddedResponse, name)
            
            donateIntent(for: .addMedication(name: name, dosage: dosage, frequency: frequency))
            
            return IntentResult(
                success: true,
                message: response
            )
        } catch {
            logger.error("Failed to add medication: \(error)")
            return IntentResult(
                success: false,
                message: AppStrings.Siri.addMedicationError
            )
        }
    }
    
    /// Handle check conflicts request
    func handleCheckConflicts(medications: [String]?) async -> IntentResult {
        logger.info("Handling check conflicts via App Intent")
        
        guard let userId = FirebaseManager.shared.currentUser?.id else {
            return IntentResult(
                success: false,
                message: AppStrings.Siri.notSignedInResponse
            )
        }
        
        do {
            var meds = medications ?? []
            
            if meds.isEmpty {
                let userMedications = try await CoreDataManager.shared.fetchMedications(for: userId)
                let userSupplements = try await CoreDataManager.shared.fetchSupplements(for: userId)
                
                meds = userMedications.filter { $0.isActive }.map { $0.name }
                meds += userSupplements.filter { $0.isActive }.map { $0.name }
            }
            
            guard !meds.isEmpty else {
                return IntentResult(
                    success: true,
                    message: AppStrings.Siri.noMedicationsToCheck
                )
            }
            
            let conflictManager = ConflictDetectionManager.shared
            let analysis = try await conflictManager.analyzeConflicts(for: meds)
            let response = conflictManager.getVoiceResponse(for: analysis)
            
            donateIntent(for: .checkConflicts)
            
            return IntentResult(
                success: true,
                message: response
            )
        } catch {
            logger.error("Failed to check conflicts: \(error)")
            return IntentResult(
                success: false,
                message: AppStrings.Siri.checkConflictsError
            )
        }
    }
    
    /// Handle log medication request
    func handleLogMedication(name: String, taken: Bool) async -> IntentResult {
        logger.info("Handling log medication via App Intent")
        
        guard let userId = FirebaseManager.shared.currentUser?.id else {
            return IntentResult(
                success: false,
                message: AppStrings.Siri.notSignedInResponse
            )
        }
        
        do {
            let medications = try await CoreDataManager.shared.fetchMedications(for: userId)
            guard var medication = medications.first(where: { 
                $0.name.localizedCaseInsensitiveContains(name) 
            }) else {
                return IntentResult(
                    success: false,
                    message: String(format: AppStrings.Siri.medicationNotFoundResponse, name)
                )
            }
            
            let calendar = Calendar.current
            let today = Date()
            if let todaySchedule = medication.schedule.first(where: { schedule in
                calendar.isDate(schedule.time, inSameDayAs: today) && !schedule.isCompleted
            }) {
                if taken {
                    medication.markDoseCompleted(scheduleId: todaySchedule.id)
                } else {
                    medication.markDoseSkipped(scheduleId: todaySchedule.id, reason: AppStrings.Siri.voiceSkippedReason)
                }
                
                try await CoreDataManager.shared.saveMedication(medication)
            }
            
            let response = taken
                ? String(format: AppStrings.Siri.medicationLoggedResponse, name)
                : String(format: AppStrings.Siri.medicationSkippedResponse, name)
            
            donateIntent(for: .logMedication(name: name, taken: taken))
            
            return IntentResult(
                success: true,
                message: response
            )
        } catch {
            logger.error("Failed to log medication: \(error)")
            return IntentResult(
                success: false,
                message: AppStrings.Siri.logMedicationError
            )
        }
    }
    
    /// Handle set reminder request
    func handleSetReminder(name: String, time: Date?) async -> IntentResult {
        logger.info("Handling set reminder via App Intent")
        
        guard (FirebaseManager.shared.currentUser?.id) != nil else {
            return IntentResult(
                success: false,
                message: AppStrings.Siri.notSignedInResponse
            )
        }
        
        // Note: Actual reminder implementation would integrate with iOS Notifications
        // For now, we acknowledge the request and track it
        
        let timeString = time?.formatted(date: .omitted, time: .shortened) ?? AppStrings.Siri.defaultReminderTime
        let response = String(format: AppStrings.Siri.reminderSetResponse, name, timeString)
        
        donateIntent(for: .setReminder(name: name, time: time))
        
        return IntentResult(
            success: true,
            message: response
        )
    }
    
    /// Handle voice query request
    func handleVoiceQuery(_ query: String) async -> IntentResult {
        logger.info("Handling voice query via App Intent: \(query)")
        
        guard let userId = FirebaseManager.shared.currentUser?.id else {
            return IntentResult(
                success: false,
                message: AppStrings.Siri.notSignedInResponse
            )
        }
        
        do {
            // Determine query type and route appropriately
            let lowerQuery = query.lowercased()
            
            if lowerQuery.contains("medication") && (lowerQuery.contains("breakfast") || 
                                                     lowerQuery.contains("lunch") || 
                                                     lowerQuery.contains("dinner")) {
                // Meal-based query
                let mealType = parseMealType(from: lowerQuery)
                let allMedications = try await CoreDataManager.shared.fetchMedications(for: userId)
                
                // Filter medications by comparing schedule times with typical meal times
                let calendar = Calendar.current
                let mealHour = mealType.defaultTime.hour
                
                let medications = allMedications.filter { medication in
                    medication.schedule.contains { schedule in
                        let scheduleHour = calendar.component(.hour, from: schedule.time)
                        // Check if medication is within 2 hours of typical meal time
                        return abs(scheduleHour - mealHour) <= 2
                    }
                }
                
                let response = formatMealMedicationsResponse(medications, mealType: mealType)
                donateIntent(for: .voiceQuery(query))
                
                return IntentResult(
                    success: true,
                    message: response
                )
            } else if lowerQuery.contains("conflict") || lowerQuery.contains("interaction") {
                // Conflict check query
                return await handleCheckConflicts(medications: nil)
            } else {
                // General medication query
                return await handleCheckMedications()
            }
        } catch {
            logger.error("Voice query error: \(error)")
            return IntentResult(
                success: false,
                message: AppStrings.Siri.voiceQueryError
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseFrequency(_ frequency: String?) -> MedicationFrequency? {
        guard let frequency = frequency?.lowercased() else { return nil }
        
        if frequency.contains("once") || frequency.contains("daily") {
            return .once
        } else if frequency.contains("twice") || frequency.contains("2") {
            return .twice
        } else if frequency.contains("three") || frequency.contains("thrice") || frequency.contains("3") {
            return .thrice
        } else if frequency.contains("need") {
            return .asNeeded
        }
        
        return nil
    }
    
    private func parseMealType(from query: String) -> MealType {
        let lowerQuery = query.lowercased()
        
        if lowerQuery.contains("breakfast") {
            return .breakfast
        } else if lowerQuery.contains("lunch") {
            return .lunch
        } else if lowerQuery.contains("dinner") {
            return .dinner
        } else if lowerQuery.contains("snack") {
            return .snack
        }
        
        return .breakfast // Default
    }
    
    private func formatMealMedicationsResponse(_ medications: [MedicationModel], mealType: MealType) -> String {
        guard !medications.isEmpty else {
            return String(format: AppStrings.Siri.noMedicationsForMealResponse, mealType.rawValue)
        }
        
        let medicationNames = medications.map { $0.name }.joined(separator: ", ")
        return String(format: AppStrings.Siri.mealMedicationsResponse, mealType.rawValue, medicationNames)
    }
    
    // MARK: - Recent Queries Management
    
    private func addRecentQuery(_ query: String) {
        recentQueries.insert(query, at: 0)
        
        // Keep only last 10 queries
        if recentQueries.count > 10 {
            recentQueries = Array(recentQueries.prefix(10))
        }
        
        saveRecentQueries()
    }
    
    private func loadRecentQueries() {
        recentQueries = UserDefaults.standard.stringArray(forKey: "RecentVoiceQueries") ?? []
    }
    
    private func saveRecentQueries() {
        UserDefaults.standard.set(recentQueries, forKey: "RecentVoiceQueries")
    }
}

// MARK: - Supporting Types

enum UserAction {
    case checkMedications
    case addMedication(name: String, dosage: String?, frequency: String?)
    case checkConflicts
    case logMedication(name: String, taken: Bool)
    case setReminder(name: String, time: Date?)
    case voiceQuery(_ query: String)
}

struct IntentResult: Sendable {
    let success: Bool
    let message: String
    
    init(success: Bool, message: String) {
        self.success = success
        self.message = message
    }
}
