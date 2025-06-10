import Foundation
import FirebaseFirestore

struct DietEntry: Codable, Identifiable, SyncableModel, VoiceInputCapable, UserOwnedModel {
    let id: String = UUID().uuidString
    let userId: String
    var mealType: MealType
    var foods: [FoodItem]
    var allergies: [String]
    var notes: String?
    var scheduledTime: Date?
    var actualTime: Date?
    let date: Date
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool = false
    
    // Sync properties
    var needsSync: Bool = false
    var isDeleted: Bool = false
}

// MARK: - Meal Type
enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    
    var displayName: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        case .snack:
            return "Snack"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast:
            return "sun.and.horizon"
        case .lunch:
            return "sun.max"
        case .dinner:
            return "moon"
        case .snack:
            return "leaf"
        }
    }
    
    var defaultTime: (hour: Int, minute: Int) {
        switch self {
        case .breakfast:
            return (8, 0)
        case .lunch:
            return (12, 0)
        case .dinner:
            return (18, 0)
        case .snack:
            return (15, 0)
        }
    }
}

// MARK: - Food Item
struct FoodItem: Codable, Identifiable {
    let id: String = UUID().uuidString
    var name: String
    var quantity: String?
    var calories: Int?
    var notes: String?
}

// MARK: - Diet Entry Extensions
extension DietEntry {
    var totalCalories: Int {
        foods.compactMap { $0.calories }.reduce(0, +)
    }
    
    var isScheduled: Bool {
        scheduledTime != nil
    }
    
    var isCompleted: Bool {
        actualTime != nil
    }
    
    var wasOnTime: Bool {
        guard let scheduledTime = scheduledTime,
              let actualTime = actualTime else {
            return false
        }
        
        let timeDifference = abs(actualTime.timeIntervalSince(scheduledTime))
        return timeDifference <= 30 * 60 // Within 30 minutes
    }
    
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if let actualTime = actualTime {
            return formatter.string(from: actualTime)
        } else if let scheduledTime = scheduledTime {
            return "Scheduled: \(formatter.string(from: scheduledTime))"
        } else {
            return "No time set"
        }
    }
    
    var foodSummary: String {
        if foods.isEmpty {
            return "No foods added"
        } else if foods.count == 1 {
            return foods.first?.name ?? "Unknown food"
        } else {
            return "\(foods.count) items"
        }
    }
    
    mutating func addFood(_ food: FoodItem) {
        foods.append(food)
        markForSync()
    }
    
    mutating func removeFood(withId foodId: String) {
        foods.removeAll { $0.id == foodId }
        markForSync()
    }
    
    mutating func markAsEaten(at time: Date = Date()) {
        actualTime = time
        markForSync()
    }
    
    mutating func addAllergy(_ allergy: String) {
        if !allergies.contains(allergy) {
            allergies.append(allergy)
            markForSync()
        }
    }
    
    mutating func removeAllergy(_ allergy: String) {
        allergies.removeAll { $0 == allergy }
        markForSync()
    }
}

// MARK: - Diet Entry Creation Helpers
extension DietEntry {
    static func create(
        for userId: String,
        mealType: MealType,
        date: Date = Date(),
        scheduledTime: Date? = nil,
        foods: [FoodItem] = [],
        allergies: [String] = [],
        notes: String? = nil,
        voiceEntryUsed: Bool = false
    ) -> DietEntry {
        let entry = DietEntry(
            userId: userId,
            mealType: mealType,
            foods: foods,
            allergies: allergies,
            notes: notes,
            scheduledTime: scheduledTime ?? defaultScheduledTime(for: mealType, on: date),
            actualTime: nil,
            date: date,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: voiceEntryUsed
        )
        
        var mutableEntry = entry
        mutableEntry.markForSync()
        return mutableEntry
    }
    
    private static func defaultScheduledTime(for mealType: MealType, on date: Date) -> Date? {
        let calendar = Calendar.current
        let defaultTime = mealType.defaultTime
        return calendar.date(bySettingHour: defaultTime.hour, minute: defaultTime.minute, second: 0, of: date)
    }
}

// MARK: - Food Item Helpers
extension FoodItem {
    static func create(
        name: String,
        quantity: String? = nil,
        calories: Int? = nil,
        notes: String? = nil
    ) -> FoodItem {
        return FoodItem(
            name: name,
            quantity: quantity,
            calories: calories,
            notes: notes
        )
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension DietEntry {
    static let sampleDietEntry = DietEntry(
        userId: "sample-user-id",
        mealType: .breakfast,
        foods: [
            FoodItem(name: "Oatmeal", quantity: "1 cup", calories: 150, notes: "With blueberries"),
            FoodItem(name: "Greek Yogurt", quantity: "6 oz", calories: 100, notes: "Plain"),
            FoodItem(name: "Coffee", quantity: "8 oz", calories: 5, notes: "Black")
        ],
        allergies: [],
        notes: "Healthy breakfast with protein and fiber",
        scheduledTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()),
        actualTime: Calendar.current.date(bySettingHour: 8, minute: 15, second: 0, of: Date()),
        date: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        voiceEntryUsed: false
    )
    
    static let sampleDietEntries: [DietEntry] = [
        sampleDietEntry,
        DietEntry(
            userId: "sample-user-id",
            mealType: .lunch,
            foods: [
                FoodItem(name: "Grilled Chicken", quantity: "4 oz", calories: 200, notes: "No skin"),
                FoodItem(name: "Brown Rice", quantity: "1/2 cup", calories: 110, notes: nil),
                FoodItem(name: "Steamed Broccoli", quantity: "1 cup", calories: 25, notes: nil)
            ],
            allergies: [],
            notes: "Balanced meal with lean protein",
            scheduledTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()),
            actualTime: nil,
            date: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: true
        ),
        DietEntry(
            userId: "sample-user-id",
            mealType: .snack,
            foods: [
                FoodItem(name: "Apple", quantity: "1 medium", calories: 80, notes: "Honeycrisp"),
                FoodItem(name: "Almonds", quantity: "10 pieces", calories: 70, notes: "Raw")
            ],
            allergies: ["Tree nuts"],
            notes: "Afternoon snack",
            scheduledTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()),
            actualTime: Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date()),
            date: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: false
        )
    ]
}
#endif