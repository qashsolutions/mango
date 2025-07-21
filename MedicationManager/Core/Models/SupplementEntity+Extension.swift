import Foundation
import CoreData

extension SupplementEntity {
    
    // MARK: - Update from Model
    func updateFromModel(_ model: SupplementModel) {
        self.id = model.id
        self.userId = model.userId
        self.name = model.name
        self.dosage = model.dosage
        self.frequency = model.frequency.rawValue
        self.notes = model.notes
        self.purpose = model.purpose
        self.brand = model.brand
        self.isActive = model.isActive
        self.isTakenWithFood = model.isTakenWithFood
        self.startDate = model.startDate
        self.endDate = model.endDate
        self.createdAt = model.createdAt
        self.updatedAt = model.updatedAt
        self.voiceEntryUsed = model.voiceEntryUsed
        self.needsSync = model.needsSync
        self.isDeletedFlag = model.isDeletedFlag
        
        // Encode schedule array as Binary data following app patterns
        if let scheduleData = try? JSONEncoder().encode(model.schedule) {
            self.scheduleData = scheduleData
        }
    }
    
    // MARK: - Convert to Model
    func toModel() -> SupplementModel? {
        guard let id = id,
              let userId = userId,
              let name = name,
              let dosage = dosage,
              let frequencyRaw = frequency,
              let createdAt = createdAt else {
            return nil
        }
        
        // Decode schedule from Binary data
        var schedules: [SupplementSchedule] = []
        if let data = scheduleData {
            schedules = (try? JSONDecoder().decode([SupplementSchedule].self, from: data)) ?? []
        }
        
        let frequency = SupplementFrequency(rawValue: frequencyRaw) ?? .daily
        
        return SupplementModel(
            id: id,
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: schedules,
            notes: notes,
            purpose: purpose,
            brand: brand,
            isActive: isActive,
            isTakenWithFood: isTakenWithFood,
            startDate: startDate ?? Date(),
            endDate: endDate,
            createdAt: createdAt,
            updatedAt: updatedAt ?? Date(),
            voiceEntryUsed: voiceEntryUsed,
            needsSync: needsSync,
            isDeletedFlag: isDeletedFlag
        )
    }
}