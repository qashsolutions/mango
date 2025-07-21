import Foundation
import FirebaseFirestore

struct MedicationModel: Codable, Identifiable, Sendable, SyncableModel, VoiceInputCapable, UserOwnedModel {
    let id: String
    let userId: String
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var schedule: [MedicationSchedule]
    var notes: String?
    var prescribedBy: String?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool
    var takeWithFood: Bool
    
    // Sync properties
    var needsSync: Bool
    var isDeletedFlag: Bool
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, userId, name, dosage, frequency, schedule, notes
        case prescribedBy, startDate, endDate, isActive, createdAt, updatedAt
        case voiceEntryUsed, needsSync, isDeletedFlag = "deleted", takeWithFood
    }
    
    // MARK: - Computed Properties
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
    
    // MARK: - Mutating Methods
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
    
    // MARK: - Static Factory Methods
    static func create(
        for userId: String,
        name: String,
        dosage: String,
        frequency: MedicationFrequency,
        startDate: Date = Date(),
        endDate: Date? = nil,
        prescribedBy: String? = nil,
        notes: String? = nil,
        voiceEntryUsed: Bool = false,
        takeWithFood: Bool = false
    ) -> MedicationModel {
        let schedules = generateDefaultSchedule(for: frequency, startDate: startDate)
        
        return MedicationModel(
            id: UUID().uuidString,
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: schedules,
            notes: notes,
            prescribedBy: prescribedBy,
            startDate: startDate,
            endDate: endDate,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: voiceEntryUsed,
            takeWithFood: takeWithFood,
            needsSync: true,
            isDeletedFlag: false
        )
    }
    
    private static func generateDefaultSchedule(for frequency: MedicationFrequency, startDate: Date) -> [MedicationSchedule] {
        let calendar = Calendar.current
        var schedules: [MedicationSchedule] = []
        
        switch frequency {
        case .once:
            if let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: startDate) {
                schedules.append(MedicationSchedule(
                    time: morningTime,
                    dosageAmount: AppStrings.Medications.dosage,
                    instructions: AppStrings.Medications.notes
                ))
            }
            
        case .twice:
            if let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: startDate),
               let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: startDate) {
                schedules.append(MedicationSchedule(
                    time: morningTime,
                    dosageAmount: AppStrings.Medications.dosage,
                    instructions: AppStrings.Medications.notes
                ))
                schedules.append(MedicationSchedule(
                    time: eveningTime,
                    dosageAmount: AppStrings.Medications.dosage,
                    instructions: AppStrings.Medications.notes
                ))
            }
            
        case .thrice:
            if let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: startDate),
               let noonTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startDate),
               let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: startDate) {
                schedules.append(MedicationSchedule(
                    time: morningTime,
                    dosageAmount: AppStrings.Medications.dosage,
                    instructions: AppStrings.Medications.notes
                ))
                schedules.append(MedicationSchedule(
                    time: noonTime,
                    dosageAmount: AppStrings.Medications.dosage,
                    instructions: AppStrings.Medications.notes
                ))
                schedules.append(MedicationSchedule(
                    time: eveningTime,
                    dosageAmount: AppStrings.Medications.dosage,
                    instructions: AppStrings.Medications.notes
                ))
            }
            
        case .asNeeded, .custom:
            break
        }
        
        return schedules
    }
}

// MARK: - Medication Frequency
public enum MedicationFrequency: String, Codable, CaseIterable, Sendable {
    case once = "once_daily"
    case twice = "twice_daily"
    case thrice = "three_times_daily"
    case asNeeded = "as_needed"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .once:
            return NSLocalizedString("medication.frequency.once", value: "Once Daily", comment: "Once daily frequency")
        case .twice:
            return NSLocalizedString("medication.frequency.twice", value: "Twice Daily", comment: "Twice daily frequency")
        case .thrice:
            return NSLocalizedString("medication.frequency.thrice", value: "Three Times Daily", comment: "Three times daily frequency")
        case .asNeeded:
            return NSLocalizedString("medication.frequency.asNeeded", value: "As Needed", comment: "As needed frequency")
        case .custom:
            return NSLocalizedString("medication.frequency.custom", value: "Custom Schedule", comment: "Custom frequency")
        }
    }
}

// MARK: - Medication Schedule
struct MedicationSchedule: Codable, Identifiable, Sendable {
    let id: String
    var time: Date
    var dosageAmount: String
    var instructions: String?
    var isCompleted: Bool
    var completedAt: Date?
    var skipped: Bool
    var skippedReason: String?
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, time, dosageAmount, instructions, isCompleted, completedAt, skipped, skippedReason
    }
    
    // MARK: - Initializer
    init(
        time: Date,
        dosageAmount: String,
        instructions: String? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        skipped: Bool = false,
        skippedReason: String? = nil
    ) {
        self.id = UUID().uuidString
        self.time = time
        self.dosageAmount = dosageAmount
        self.instructions = instructions
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.skipped = skipped
        self.skippedReason = skippedReason
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension MedicationModel {
    static let sampleMedication = MedicationModel(
        id: "sample-medication-1",
        userId: "sample-user-id",
        name: "Lisinopril",
        dosage: "10mg",
        frequency: .once,
        schedule: [
            MedicationSchedule(
                time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
                dosageAmount: "1 tablet"
            )
        ],
        notes: AppStrings.Medications.notes,
        prescribedBy: "Dr. Smith",
        startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
        endDate: nil,
        isActive: true,
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
        updatedAt: Date(),
        voiceEntryUsed: false,
        takeWithFood: false,
        needsSync: false,
        isDeletedFlag: false
    )
    
    static let sampleMedications: [MedicationModel] = [
        sampleMedication,
        MedicationModel(
            id: "sample-medication-2",
            userId: "sample-user-id",
            name: "Metformin",
            dosage: "500mg",
            frequency: .twice,
            schedule: [
                MedicationSchedule(
                    time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
                    dosageAmount: "1 tablet"
                ),
                MedicationSchedule(
                    time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
                    dosageAmount: "1 tablet"
                )
            ],
            notes: AppStrings.Medications.notes,
            prescribedBy: "Dr. Johnson",
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            endDate: nil,
            isActive: true,
            createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            updatedAt: Date(),
            voiceEntryUsed: true,
            takeWithFood: true,
            needsSync: false,
            isDeletedFlag: false
        )
    ]
}
#endif
