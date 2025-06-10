import Foundation
import FirebaseFirestore

struct Supplement: Codable, Identifiable, SyncableModel, VoiceInputCapable, UserOwnedModel {
    let id: String = UUID().uuidString
    let userId: String
    var name: String
    var dosage: String
    var frequency: SupplementFrequency
    var schedule: [SupplementSchedule]
    var notes: String?
    var purpose: String?
    var brand: String?
    var isActive: Bool = true
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool = false
    
    // Sync properties
    var needsSync: Bool = false
    var isDeleted: Bool = false
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
struct SupplementSchedule: Codable, Identifiable {
    let id: String = UUID().uuidString
    var time: Date
    var amount: String
    var withMeal: Bool = false
    var isCompleted: Bool = false
    var completedAt: Date?
}

// MARK: - Supplement Extensions
extension Supplement {
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
extension Supplement {
    static func create(
        for userId: String,
        name: String,
        dosage: String,
        frequency: SupplementFrequency,
        purpose: String? = nil,
        brand: String? = nil,
        notes: String? = nil,
        voiceEntryUsed: Bool = false
    ) -> Supplement {
        var supplement = Supplement(
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: [],
            notes: notes,
            purpose: purpose,
            brand: brand,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: voiceEntryUsed
        )
        
        // Generate default schedule based on frequency
        supplement.schedule = generateDefaultSchedule(for: frequency)
        supplement.markForSync()
        
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
extension Supplement {
    static let sampleSupplement = Supplement(
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
        createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        updatedAt: Date(),
        voiceEntryUsed: false
    )
    
    static let sampleSupplements: [Supplement] = [
        sampleSupplement,
        Supplement(
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
            createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            updatedAt: Date(),
            voiceEntryUsed: true
        ),
        Supplement(
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
            createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            updatedAt: Date(),
            voiceEntryUsed: false
        )
    ]
}
#endif