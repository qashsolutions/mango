import Foundation
import FirebaseFirestore

struct DietEntryModel: Codable, Identifiable, Sendable, SyncableModel, VoiceInputCapable, UserOwnedModel {
    let id: String
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
    var voiceEntryUsed: Bool
    
    // Sync properties
    var needsSync: Bool
    var isDeletedFlag: Bool
    
    // MARK: - Initializer
    init(id: String = UUID().uuidString,
         userId: String,
         mealType: MealType,
         foods: [FoodItem],
         allergies: [String],
         notes: String? = nil,
         scheduledTime: Date? = nil,
         actualTime: Date? = nil,
         date: Date,
         createdAt: Date,
         updatedAt: Date,
         voiceEntryUsed: Bool = false,
         needsSync: Bool = false,
         isDeletedFlag: Bool = false) {
        self.id = id
        self.userId = userId
        self.mealType = mealType
        self.foods = foods
        self.allergies = allergies
        self.notes = notes
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.voiceEntryUsed = voiceEntryUsed
        self.needsSync = needsSync
        self.isDeletedFlag = isDeletedFlag
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, userId, mealType, foods, allergies, notes
        case scheduledTime, actualTime, date, createdAt, updatedAt
        case voiceEntryUsed, needsSync, isDeletedFlag
    }
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
            return AppStrings.Diet.breakfast
        case .lunch:
            return AppStrings.Diet.lunch
        case .dinner:
            return AppStrings.Diet.dinner
        case .snack:
            return AppStrings.Diet.snack
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
struct FoodItem: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var quantity: String?
    var calories: Int?
    var notes: String?
    
    // MARK: - Initializer
    init(id: String = UUID().uuidString,
         name: String,
         quantity: String? = nil,
         calories: Int? = nil,
         notes: String? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.calories = calories
        self.notes = notes
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, calories, notes
    }
}

// MARK: - Diet Entry Extensions
extension DietEntryModel {
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
    
    var foodItems: String {
        foods.map { $0.name }.joined(separator: ", ")
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
extension DietEntryModel {
    static func create(
        for userId: String,
        mealType: MealType,
        date: Date = Date(),
        scheduledTime: Date? = nil,
        foods: [FoodItem] = [],
        allergies: [String] = [],
        notes: String? = nil,
        voiceEntryUsed: Bool = false
    ) -> DietEntryModel {
        let now = Date()
        let entry = DietEntryModel(
            id: UUID().uuidString,
            userId: userId,
            mealType: mealType,
            foods: foods,
            allergies: allergies,
            notes: notes,
            scheduledTime: scheduledTime ?? defaultScheduledTime(for: mealType, on: date),
            actualTime: nil,
            date: date,
            createdAt: now,
            updatedAt: now,
            voiceEntryUsed: voiceEntryUsed,
            needsSync: true,
            isDeletedFlag: false
        )
        
        return entry
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
            id: UUID().uuidString,
            name: name,
            quantity: quantity,
            calories: calories,
            notes: notes
        )
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension DietEntryModel {
    static let sampleDietEntry = DietEntryModel(
        id: "sample-diet-entry-1",
        userId: "sample-user-id",
        mealType: .breakfast,
        foods: [
            FoodItem(id: "sample-food-1", name: "Oatmeal", quantity: "1 cup", calories: 150, notes: "With blueberries"),
            FoodItem(id: "sample-food-2", name: "Greek Yogurt", quantity: "6 oz", calories: 100, notes: "Plain"),
            FoodItem(id: "sample-food-3", name: "Coffee", quantity: "8 oz", calories: 5, notes: "Black")
        ],
        allergies: [],
        notes: "Healthy breakfast with protein and fiber",
        scheduledTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()),
        actualTime: Calendar.current.date(bySettingHour: 8, minute: 15, second: 0, of: Date()),
        date: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        voiceEntryUsed: false,
        needsSync: false,
        isDeletedFlag: false
    )
    
    static let sampleDietEntries: [DietEntryModel] = [
        sampleDietEntry,
        DietEntryModel(
            id: "sample-diet-entry-2",
            userId: "sample-user-id",
            mealType: .lunch,
            foods: [
                FoodItem(id: "sample-food-4", name: "Grilled Chicken", quantity: "4 oz", calories: 200, notes: "No skin"),
                FoodItem(id: "sample-food-5", name: "Brown Rice", quantity: "1/2 cup", calories: 110, notes: nil),
                FoodItem(id: "sample-food-6", name: "Steamed Broccoli", quantity: "1 cup", calories: 25, notes: nil)
            ],
            allergies: [],
            notes: "Balanced meal with lean protein",
            scheduledTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()),
            actualTime: nil,
            date: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: true,
            needsSync: false,
            isDeletedFlag: false
        ),
        DietEntryModel(
            id: "sample-diet-entry-3",
            userId: "sample-user-id",
            mealType: .snack,
            foods: [
                FoodItem(id: "sample-food-7", name: "Apple", quantity: "1 medium", calories: 80, notes: "Honeycrisp"),
                FoodItem(id: "sample-food-8", name: "Almonds", quantity: "10 pieces", calories: 70, notes: "Raw")
            ],
            allergies: ["Tree nuts"],
            notes: "Afternoon snack",
            scheduledTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()),
            actualTime: Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date()),
            date: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: false,
            needsSync: false,
            isDeletedFlag: false
        )
    ]
}
#endif
