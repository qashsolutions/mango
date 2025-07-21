import Foundation
import CoreData

extension MedicationEntity {
    
    // MARK: - Update from Model
    func updateFromModel(_ model: MedicationModel) {
        self.id = model.id
        self.userId = model.userId
        self.name = model.name
        self.dosage = model.dosage
        self.frequency = model.frequency.rawValue
        self.notes = model.notes
        self.prescribedBy = model.prescribedBy
        self.startDate = model.startDate
        self.endDate = model.endDate
        self.isActive = model.isActive
        self.createdAt = model.createdAt
        self.updatedAt = model.updatedAt
        self.voiceEntryUsed = model.voiceEntryUsed
        // Note: takeWithFood is not stored in Core Data for medications
        self.needsSync = model.needsSync
        self.isDeletedFlag = model.isDeletedFlag
        
        // Encode schedule array as Binary data following app patterns
        if let scheduleData = try? JSONEncoder().encode(model.schedule) {
            self.scheduleData = scheduleData
        }
    }
    
    // MARK: - Convert to Model
    func toModel() -> MedicationModel? {
        guard let id = id, 
              let userId = userId,
              let name = name,
              let dosage = dosage,
              let frequencyRaw = frequency,
              let createdAt = createdAt else { 
            return nil 
        }
        
        // Decode schedule from Binary data
        var schedules: [MedicationSchedule] = []
        if let data = scheduleData {
            schedules = (try? JSONDecoder().decode([MedicationSchedule].self, from: data)) ?? []
        }
        
        let frequency = MedicationFrequency(rawValue: frequencyRaw) ?? .once
        
        return MedicationModel(
            id: id,
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: schedules,
            notes: notes,
            prescribedBy: prescribedBy,
            startDate: startDate ?? Date(),
            endDate: endDate,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt ?? Date(),
            voiceEntryUsed: voiceEntryUsed,
            takeWithFood: false, // Default value - not stored in Core Data
            needsSync: needsSync,
            isDeletedFlag: isDeletedFlag
        )
    }
}
