import Foundation
import FirebaseFirestore

struct Medication: Codable, Identifiable, SyncableModel, VoiceInputCapable, UserOwnedModel {
    let id: String = UUID().uuidString
    let userId: String
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var schedule: [MedicationSchedule]
    var notes: String?
    var prescribedBy: String?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool = true
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool = false
    
    // Sync properties
    var needsSync: Bool = false
    var isDeleted: Bool = false
}

// MARK: - Medication Frequency
enum MedicationFrequency: String, Codable, CaseIterable {
    case once = "once_daily"
    case twice = "twice_daily"
    case thrice = "three_times_daily"
    case asNeeded = "as_needed"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .once:
            return "Once daily"
        case .twice:
            return "Twice daily"
        case .thrice:
            return "Three times daily"
        case .asNeeded:
            return "As needed"
        case .custom:
            return "Custom schedule"
        }
    }
}

// MARK: - Medication Schedule
struct MedicationSchedule: Codable, Identifiable {
    let id: String = UUID().uuidString
    var time: Date
    var dosageAmount: String
    var instructions: String?
    var isCompleted: Bool = false
    var completedAt: Date?
    var skipped: Bool = false
    var skippedReason: String?
}

// MARK: - Medication Extensions
extension Medication {
    var isDueToday: Bool {
        let calendar = Calendar.current
        let today = Date()
        
        return schedule.contains { scheduleItem in
            calendar.isDate(scheduleItem.time, inSameDayAs: today) && !scheduleItem.isCompleted
        }
    }
    
    var nextDose: MedicationSchedule? {
        let now = Date()
        return schedule
            .filter { !$0.isCompleted && $0.time > now }
            .sorted { $0.time < $1.time }
            .first
    }
    
    var completionRate: Double {
        guard !schedule.isEmpty else { return 0.0 }
        let completedCount = schedule.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(schedule.count)
    }
    
    var displayFrequency: String {
        frequency.displayName
    }
    
    mutating func markDoseCompleted(scheduleId: String) {
        if let index = schedule.firstIndex(where: { $0.id == scheduleId }) {
            schedule[index].isCompleted = true
            schedule[index].completedAt = Date()
            markForSync()
        }
    }
    
    mutating func markDoseSkipped(scheduleId: String, reason: String?) {
        if let index = schedule.firstIndex(where: { $0.id == scheduleId }) {
            schedule[index].skipped = true
            schedule[index].skippedReason = reason
            markForSync()
        }
    }
}

// MARK: - Medication Creation Helpers
extension Medication {
    static func create(
        for userId: String,
        name: String,
        dosage: String,
        frequency: MedicationFrequency,
        startDate: Date = Date(),
        endDate: Date? = nil,
        prescribedBy: String? = nil,
        notes: String? = nil,
        voiceEntryUsed: Bool = false
    ) -> Medication {
        var medication = Medication(
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: [],
            notes: notes,
            prescribedBy: prescribedBy,
            startDate: startDate,
            endDate: endDate,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: voiceEntryUsed
        )
        
        // Generate default schedule based on frequency
        medication.schedule = generateDefaultSchedule(for: frequency, startDate: startDate)
        medication.markForSync()
        
        return medication
    }
    
    private static func generateDefaultSchedule(for frequency: MedicationFrequency, startDate: Date) -> [MedicationSchedule] {
        let calendar = Calendar.current
        var schedules: [MedicationSchedule] = []
        
        switch frequency {
        case .once:
            let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: startDate) ?? startDate
            schedules.append(MedicationSchedule(time: morningTime, dosageAmount: "1", instructions: "Take with breakfast"))
            
        case .twice:
            let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: startDate) ?? startDate
            let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: startDate) ?? startDate
            schedules.append(MedicationSchedule(time: morningTime, dosageAmount: "1", instructions: "Take with breakfast"))
            schedules.append(MedicationSchedule(time: eveningTime, dosageAmount: "1", instructions: "Take with dinner"))
            
        case .thrice:
            let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: startDate) ?? startDate
            let noonTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startDate) ?? startDate
            let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: startDate) ?? startDate
            schedules.append(MedicationSchedule(time: morningTime, dosageAmount: "1", instructions: "Take with breakfast"))
            schedules.append(MedicationSchedule(time: noonTime, dosageAmount: "1", instructions: "Take with lunch"))
            schedules.append(MedicationSchedule(time: eveningTime, dosageAmount: "1", instructions: "Take with dinner"))
            
        case .asNeeded, .custom:
            // No default schedule for as-needed or custom medications
            break
        }
        
        return schedules
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension Medication {
    static let sampleMedication = Medication(
        userId: "sample-user-id",
        name: "Lisinopril",
        dosage: "10mg",
        frequency: .once,
        schedule: [
            MedicationSchedule(
                time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
                dosageAmount: "1 tablet",
                instructions: "Take with breakfast"
            )
        ],
        notes: "For blood pressure management",
        prescribedBy: "Dr. Smith",
        startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
        endDate: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
        updatedAt: Date(),
        voiceEntryUsed: false
    )
    
    static let sampleMedications: [Medication] = [
        sampleMedication,
        Medication(
            userId: "sample-user-id",
            name: "Metformin",
            dosage: "500mg",
            frequency: .twice,
            schedule: [
                MedicationSchedule(
                    time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
                    dosageAmount: "1 tablet",
                    instructions: "Take with breakfast"
                ),
                MedicationSchedule(
                    time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
                    dosageAmount: "1 tablet",
                    instructions: "Take with dinner"
                )
            ],
            notes: "For diabetes management",
            prescribedBy: "Dr. Johnson",
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            endDate: nil,
            createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            updatedAt: Date(),
            voiceEntryUsed: true
        )
    ]
}
#endif