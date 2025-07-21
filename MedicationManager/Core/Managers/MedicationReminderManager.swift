import SwiftUI
import Observation
import UserNotifications

@MainActor
@Observable
final class MedicationReminderManager {
    static let shared = MedicationReminderManager()
    
    // Reminder state
    var activeReminders: [MedicationReminder] = []
    var isLoadingReminders = false
    var lastError: Error?
    
    private let notificationManager = NotificationManager.shared
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    private init() {
        Task {
            await loadActiveReminders()
        }
    }
    
    // MARK: - Reminder Management
    
    func createReminder(
        for medication: MedicationModel,
        times: [Date],
        enableSnooze: Bool = true,
        advanceNotice: TimeInterval = 0
    ) async throws {
        if !notificationManager.isAuthorized {
            let granted = await notificationManager.requestAuthorization()
            if !granted {
                throw AppError.notificationPermissionDenied
            }
        }
        
        let reminder = MedicationReminder(
            id: UUID().uuidString,
            medicationId: medication.id,
            medicationName: medication.name,
            dosage: medication.dosage,
            times: times,
            isActive: true,
            enableSnooze: enableSnooze,
            advanceNoticeMinutes: Int(advanceNotice / 60),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save reminder to Core Data
        try await saveReminder(reminder)
        
        // Schedule notifications
        try await notificationManager.scheduleMedicationReminder(
            medication: medication,
            times: times
        )
        
        // Update local state
        activeReminders.append(reminder)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(
            "medication_reminder_created",
            parameters: [
                "medication_id": medication.id,
                "times_per_day": times.count,
                "advance_notice": advanceNotice > 0
            ]
        )
    }
    
    func updateReminder(_ reminder: MedicationReminder) async throws {
        var updatedReminder = reminder
        updatedReminder.updatedAt = Date()
        
        // Update in Core Data
        try await saveReminder(updatedReminder)
        
        // Update notifications if times changed
        if let userId = firebaseManager.currentUser?.id {
            let medications = try await coreDataManager.fetchMedications(for: userId)
            if let medication = medications.first(where: { $0.id == reminder.medicationId }) {
                try await notificationManager.scheduleMedicationReminder(
                    medication: medication,
                    times: reminder.times
                )
            }
        }
        
        // Update local state
        if let index = activeReminders.firstIndex(where: { $0.id == reminder.id }) {
            activeReminders[index] = updatedReminder
        }
        
        AnalyticsManager.shared.trackEvent(
            "medication_reminder_updated",
            parameters: ["reminder_id": reminder.id]
        )
    }
    
    func deleteReminder(_ reminder: MedicationReminder) async throws {
        // Cancel notifications
        await notificationManager.cancelMedicationReminders(medicationId: reminder.medicationId)
        
        // Delete from Core Data
        try await deleteReminderFromStorage(reminder.id)
        
        // Update local state
        activeReminders.removeAll { $0.id == reminder.id }
        
        AnalyticsManager.shared.trackEvent(
            "medication_reminder_deleted",
            parameters: ["reminder_id": reminder.id]
        )
    }
    
    func toggleReminder(_ reminder: MedicationReminder, isActive: Bool) async throws {
        var updatedReminder = reminder
        updatedReminder.isActive = isActive
        updatedReminder.updatedAt = Date()
        
        if isActive {
            // Re-enable notifications
            if let userId = firebaseManager.currentUser?.id {
                let medications = try await coreDataManager.fetchMedications(for: userId)
                if let medication = medications.first(where: { $0.id == reminder.medicationId }) {
                    try await notificationManager.scheduleMedicationReminder(
                        medication: medication,
                        times: reminder.times
                    )
                }
            }
        } else {
            // Cancel notifications
            await notificationManager.cancelMedicationReminders(medicationId: reminder.medicationId)
        }
        
        try await updateReminder(updatedReminder)
        
        AnalyticsManager.shared.trackEvent(
            "medication_reminder_toggled",
            parameters: [
                "reminder_id": reminder.id,
                "is_active": isActive
            ]
        )
    }
    
    // MARK: - Reminder Queries
    
    func loadActiveReminders() async {
        isLoadingReminders = true
        defer { isLoadingReminders = false }
        
        do {
            guard let userId = firebaseManager.currentUser?.id else { return }
            
            // Load reminders from Core Data
            activeReminders = try await fetchRemindersFromStorage(userId: userId)
                .filter { $0.isActive }
            
        } catch {
            lastError = error
            AnalyticsManager.shared.trackError(
                category: "MedicationReminder",
                error: error
            )
        }
    }
    
    func getRemindersForMedication(_ medicationId: String) -> [MedicationReminder] {
        activeReminders.filter { $0.medicationId == medicationId }
    }
    
    func getUpcomingReminders(within interval: TimeInterval = 3600) -> [(MedicationReminder, Date)] {
        let now = Date()
        let endTime = now.addingTimeInterval(interval)
        var upcomingReminders: [(MedicationReminder, Date)] = []
        
        for reminder in activeReminders where reminder.isActive {
            for time in reminder.times {
                // Create today's reminder time
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                
                if let reminderDate = calendar.date(from: components) {
                    // Check if it's within our interval
                    if reminderDate > now && reminderDate <= endTime {
                        upcomingReminders.append((reminder, reminderDate))
                    }
                    // Check tomorrow's time if today's has passed
                    else if reminderDate <= now,
                            let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: reminderDate),
                            tomorrowDate <= endTime {
                        upcomingReminders.append((reminder, tomorrowDate))
                    }
                }
            }
        }
        
        return upcomingReminders.sorted { $0.1 < $1.1 }
    }
    
    // MARK: - Smart Reminder Suggestions
    
    func suggestReminderTimes(for medication: MedicationModel) -> [Date] {
        var suggestedTimes: [Date] = []
        
        switch medication.frequency {
        case .once:
            // Suggest 9 AM
            suggestedTimes = [createTime(hour: 9, minute: 0)]
            
        case .twice:
            // Suggest 9 AM and 9 PM
            suggestedTimes = [
                createTime(hour: 9, minute: 0),
                createTime(hour: 21, minute: 0)
            ]
            
        case .thrice:
            // Suggest 8 AM, 2 PM, 8 PM
            suggestedTimes = [
                createTime(hour: 8, minute: 0),
                createTime(hour: 14, minute: 0),
                createTime(hour: 20, minute: 0)
            ]
            
        case .fourTimes:
            // Suggest 8 AM, 12 PM, 4 PM, 8 PM
            suggestedTimes = [
                createTime(hour: 8, minute: 0),
                createTime(hour: 12, minute: 0),
                createTime(hour: 16, minute: 0),
                createTime(hour: 20, minute: 0)
            ]
            
        case .asNeeded:
            // No automatic reminders for as-needed medications
            suggestedTimes = []
            
        case .custom:
            // Default to once daily at 9 AM
            suggestedTimes = [createTime(hour: 9, minute: 0)]
        }
        
        return suggestedTimes
    }
    
    private func createTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - Conflict Detection
    
    func checkForTimeConflicts(
        medication: MedicationModel,
        proposedTimes: [Date]
    ) -> [TimeConflict] {
        var conflicts: [TimeConflict] = []
        let calendar = Calendar.current
        
        for proposedTime in proposedTimes {
            let proposedComponents = calendar.dateComponents([.hour, .minute], from: proposedTime)
            
            // Check against existing reminders
            for reminder in activeReminders where reminder.medicationId != medication.id {
                for existingTime in reminder.times {
                    let existingComponents = calendar.dateComponents([.hour, .minute], from: existingTime)
                    
                    // Check if times are within 30 minutes of each other
                    let proposedMinutes = (proposedComponents.hour ?? 0) * 60 + (proposedComponents.minute ?? 0)
                    let existingMinutes = (existingComponents.hour ?? 0) * 60 + (existingComponents.minute ?? 0)
                    
                    let difference = abs(proposedMinutes - existingMinutes)
                    if difference < 30 {
                        conflicts.append(TimeConflict(
                            medicationName: reminder.medicationName,
                            conflictingTime: existingTime,
                            proposedTime: proposedTime,
                            minutesDifference: difference
                        ))
                    }
                }
            }
        }
        
        return conflicts
    }
    
    // MARK: - Storage Methods
    
    private func saveReminder(_ reminder: MedicationReminder) async throws {
        // Save to Core Data
        // This would integrate with your Core Data stack
        // For now, we'll simulate with UserDefaults
        
        var reminders = UserDefaults.standard.object(forKey: "MedicationReminders") as? [Data] ?? []
        let encoded = try JSONEncoder().encode(reminder)
        
        // Update or add
        if let index = reminders.firstIndex(where: {
            if let decoded = try? JSONDecoder().decode(MedicationReminder.self, from: $0) {
                return decoded.id == reminder.id
            }
            return false
        }) {
            reminders[index] = encoded
        } else {
            reminders.append(encoded)
        }
        
        UserDefaults.standard.set(reminders, forKey: "MedicationReminders")
    }
    
    private func fetchRemindersFromStorage(userId: String) async throws -> [MedicationReminder] {
        // Fetch from Core Data
        // For now, using UserDefaults
        
        guard let data = UserDefaults.standard.object(forKey: "MedicationReminders") as? [Data] else {
            return []
        }
        
        return data.compactMap { try? JSONDecoder().decode(MedicationReminder.self, from: $0) }
    }
    
    private func deleteReminderFromStorage(_ reminderId: String) async throws {
        var reminders = UserDefaults.standard.object(forKey: "MedicationReminders") as? [Data] ?? []
        
        reminders.removeAll { data in
            if let decoded = try? JSONDecoder().decode(MedicationReminder.self, from: data) {
                return decoded.id == reminderId
            }
            return false
        }
        
        UserDefaults.standard.set(reminders, forKey: "MedicationReminders")
    }
}

// MARK: - Models
struct MedicationReminder: Identifiable, Codable {
    let id: String
    let medicationId: String
    let medicationName: String
    let dosage: String
    var times: [Date]
    var isActive: Bool
    var enableSnooze: Bool
    var advanceNoticeMinutes: Int
    let createdAt: Date
    var updatedAt: Date
}

struct TimeConflict {
    let medicationName: String
    let conflictingTime: Date
    let proposedTime: Date
    let minutesDifference: Int
}

// MARK: - MedicationFrequency Extension
extension MedicationFrequency {
    static let fourTimes = MedicationFrequency.custom // Placeholder for 4x daily
}
