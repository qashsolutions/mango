import Foundation
import CoreData

extension DietEntryEntity {
    
    // MARK: - Update from Model
    func updateFromModel(_ model: DietEntryModel) {
        self.id = model.id
        self.userId = model.userId
        self.mealType = model.mealType.rawValue
        self.notes = model.notes
        self.scheduledTime = model.scheduledTime
        self.actualTime = model.actualTime
        self.date = model.date
        self.createdAt = model.createdAt
        self.updatedAt = model.updatedAt
        self.voiceEntryUsed = model.voiceEntryUsed
        self.needsSync = model.needsSync
        self.isDeletedFlag = model.isDeletedFlag
        
        // Encode foods array as Binary data following app patterns
        if let foodsData = try? JSONEncoder().encode(model.foods) {
            self.foodsData = foodsData
        }
        
        // Encode allergies array as Binary data
        if let allergiesData = try? JSONEncoder().encode(model.allergies) {
            self.allergiesData = allergiesData
        }
    }
    
    // MARK: - Convert to Model
    func toModel() -> DietEntryModel? {
        guard let id = id,
              let userId = userId,
              let mealTypeRaw = mealType,
              let date = date,
              let createdAt = createdAt else {
            return nil
        }
        
        // Decode foods from Binary data
        var foods: [FoodItem] = []
        if let data = foodsData {
            foods = (try? JSONDecoder().decode([FoodItem].self, from: data)) ?? []
        }
        
        // Decode allergies from Binary data
        var allergies: [String] = []
        if let data = allergiesData {
            allergies = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        
        let mealType = MealType(rawValue: mealTypeRaw) ?? .breakfast
        
        return DietEntryModel(
            id: id,
            userId: userId,
            mealType: mealType,
            foods: foods,
            allergies: allergies,
            notes: notes,
            scheduledTime: scheduledTime,
            actualTime: actualTime,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt ?? Date(),
            voiceEntryUsed: voiceEntryUsed,
            needsSync: needsSync,
            isDeletedFlag: isDeletedFlag
        )
    }
}