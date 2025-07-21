import Foundation
import FirebaseFirestore

struct SupplementModel: Codable, Identifiable, Sendable, SyncableModel, VoiceInputCapable, UserOwnedModel {
    let id: String
    let userId: String
    var name: String
    var dosage: String
    var frequency: SupplementFrequency
    var schedule: [SupplementSchedule]
    var notes: String?
    var purpose: String?
    var brand: String?
    var isActive: Bool
    var isTakenWithFood: Bool
    var startDate: Date
    var endDate: Date?
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool
    
    // Sync properties
    var needsSync: Bool
    var isDeletedFlag: Bool
    
    // MARK: - Initializer
    init(id: String = UUID().uuidString,
         userId: String,
         name: String,
         dosage: String,
         frequency: SupplementFrequency,
         schedule: [SupplementSchedule],
         notes: String? = nil,
         purpose: String? = nil,
         brand: String? = nil,
         isActive: Bool = true,
         isTakenWithFood: Bool = false,
         startDate: Date,
         endDate: Date? = nil,
         createdAt: Date,
         updatedAt: Date,
         voiceEntryUsed: Bool = false,
         needsSync: Bool = false,
         isDeletedFlag: Bool = false) {
        self.id = id
        self.userId = userId
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.schedule = schedule
        self.notes = notes
        self.purpose = purpose
        self.brand = brand
        self.isActive = isActive
        self.isTakenWithFood = isTakenWithFood
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.voiceEntryUsed = voiceEntryUsed
        self.needsSync = needsSync
        self.isDeletedFlag = isDeletedFlag
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, userId, name, dosage, frequency, schedule, notes, purpose, brand
        case isActive, isTakenWithFood, startDate, endDate, createdAt, updatedAt
        case voiceEntryUsed, needsSync, isDeletedFlag
    }
}

// MARK: - Supplement Frequency
enum SupplementFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case asNeeded = "as_needed"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .asNeeded:
            return "As needed"
        case .custom:
            return "Custom schedule"
        }
    }
}

// MARK: - Supplement Schedule
struct SupplementSchedule: Codable, Identifiable, Sendable {
    let id: String = UUID().uuidString
    var time: Date
    var amount: String
    var withMeal: Bool = false
    var isCompleted: Bool = false
    var completedAt: Date?
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case time, amount, withMeal, isCompleted, completedAt
    }
}

// MARK: - Supplement Extensions
extension SupplementModel {
    var isDueToday: Bool {
        let calendar = Calendar.current
        let today = Date()
        
        return schedule.contains { scheduleItem in
            calendar.isDate(scheduleItem.time, inSameDayAs: today) && !scheduleItem.isCompleted
        }
    }
    
    var nextDose: SupplementSchedule? {
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
    
    var displayPurpose: String {
        purpose ?? "General health"
    }
    
    mutating func markDoseCompleted(scheduleId: String) {
        if let index = schedule.firstIndex(where: { $0.id == scheduleId }) {
            schedule[index].isCompleted = true
            schedule[index].completedAt = Date()
            markForSync()
        }
    }
}

// MARK: - Supplement Creation Helpers
extension SupplementModel {
    static func create(
        for userId: String,
        name: String,
        dosage: String,
        frequency: SupplementFrequency,
        purpose: String? = nil,
        brand: String? = nil,
        notes: String? = nil,
        voiceEntryUsed: Bool = false
    ) -> SupplementModel {
        let now = Date()
        var supplement = SupplementModel(
            id: UUID().uuidString,
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: [],
            notes: notes,
            purpose: purpose,
            brand: brand,
            isActive: true,
            startDate: now,
            createdAt: now,
            updatedAt: now,
            voiceEntryUsed: voiceEntryUsed,
            needsSync: true,
            isDeletedFlag: false
        )
        
        // Generate default schedule based on frequency
        supplement.schedule = generateDefaultSchedule(for: frequency)
        
        return supplement
    }
    
    private static func generateDefaultSchedule(for frequency: SupplementFrequency) -> [SupplementSchedule] {
        let calendar = Calendar.current
        var schedules: [SupplementSchedule] = []
        let now = Date()
        
        switch frequency {
        case .daily:
            let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
            schedules.append(SupplementSchedule(time: morningTime, amount: "1", withMeal: true))
            
        case .weekly:
            let sundayMorning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
            schedules.append(SupplementSchedule(time: sundayMorning, amount: "1", withMeal: true))
            
        case .asNeeded, .custom:
            // No default schedule for as-needed or custom supplements
            break
        }
        
        return schedules
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension SupplementModel {
    static let sampleSupplement = SupplementModel(
        id: "sample-supplement-1",
        userId: "sample-user-id",
        name: "Vitamin D3",
        dosage: "2000 IU",
        frequency: .daily,
        schedule: [
            SupplementSchedule(
                time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
                amount: "1 capsule",
                withMeal: true
            )
        ],
        notes: "Take with breakfast for better absorption",
        purpose: "Bone health and immune support",
        brand: "Nature Made",
        isActive: true,
        startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        updatedAt: Date(),
        voiceEntryUsed: false,
        needsSync: false,
        isDeletedFlag: false
    )
    
    static let sampleSupplements: [SupplementModel] = [
        sampleSupplement,
        SupplementModel(
            id: "sample-supplement-2",
            userId: "sample-user-id",
            name: "Omega-3",
            dosage: "1000mg",
            frequency: .daily,
            schedule: [
                SupplementSchedule(
                    time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
                    amount: "2 capsules",
                    withMeal: true
                )
            ],
            notes: "EPA/DHA for heart health",
            purpose: "Heart and brain health",
            brand: "Nordic Naturals",
            isActive: true,
            startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            updatedAt: Date(),
            voiceEntryUsed: true,
            needsSync: false,
            isDeletedFlag: false
        ),
        SupplementModel(
            id: "sample-supplement-3",
            userId: "sample-user-id",
            name: "Vitamin B12",
            dosage: "1000mcg",
            frequency: .weekly,
            schedule: [
                SupplementSchedule(
                    time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
                    amount: "1 tablet",
                    withMeal: false
                )
            ],
            notes: "Sublingual tablet",
            purpose: "Energy and nervous system support",
            brand: "Solgar",
            isActive: true,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            updatedAt: Date(),
            voiceEntryUsed: false,
            needsSync: false,
            isDeletedFlag: false
        )
    ]
}
#endif
