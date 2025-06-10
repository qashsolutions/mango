import Foundation
import CoreData

@MainActor
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MedicationManager")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Core Data Operations
    func save() throws {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw AppError.data(.saveFailed)
            }
        }
    }
    
    func saveContext() async throws {
        try await context.perform {
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }
    
    // MARK: - Medication Operations
    func saveMedication(_ medication: Medication) async throws {
        try await context.perform {
            // Check if medication already exists
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "MedicationEntity")
            request.predicate = NSPredicate(format: "id == %@", medication.id)
            
            let existingMedications = try self.context.fetch(request)
            let medicationEntity: NSManagedObject
            
            if let existing = existingMedications.first {
                medicationEntity = existing
            } else {
                medicationEntity = NSEntityDescription.insertNewObject(forEntityName: "MedicationEntity", into: self.context)
                medicationEntity.setValue(medication.id, forKey: "id")
            }
            
            // Update medication properties
            medicationEntity.setValue(medication.userId, forKey: "userId")
            medicationEntity.setValue(medication.name, forKey: "name")
            medicationEntity.setValue(medication.dosage, forKey: "dosage")
            medicationEntity.setValue(medication.frequency.rawValue, forKey: "frequency")
            medicationEntity.setValue(medication.notes, forKey: "notes")
            medicationEntity.setValue(medication.prescribedBy, forKey: "prescribedBy")
            medicationEntity.setValue(medication.startDate, forKey: "startDate")
            medicationEntity.setValue(medication.endDate, forKey: "endDate")
            medicationEntity.setValue(medication.isActive, forKey: "isActive")
            medicationEntity.setValue(medication.createdAt, forKey: "createdAt")
            medicationEntity.setValue(medication.updatedAt, forKey: "updatedAt")
            medicationEntity.setValue(medication.voiceEntryUsed, forKey: "voiceEntryUsed")
            medicationEntity.setValue(medication.needsSync, forKey: "needsSync")
            medicationEntity.setValue(medication.isDeleted, forKey: "isDeleted")
            
            // Save schedule as JSON data
            if let scheduleData = try? JSONEncoder().encode(medication.schedule) {
                medicationEntity.setValue(scheduleData, forKey: "scheduleData")
            }
            
            try self.context.save()
        }
    }
    
    func fetchMedications(for userId: String) async throws -> [Medication] {
        return try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "MedicationEntity")
            request.predicate = NSPredicate(format: "userId == %@ AND isDeleted == NO", userId)
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try self.context.fetch(request)
            return entities.compactMap { entity in
                self.medicationFromEntity(entity)
            }
        }
    }
    
    func fetchMedicationsNeedingSync() async throws -> [Medication] {
        return try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "MedicationEntity")
            request.predicate = NSPredicate(format: "needsSync == YES")
            
            let entities = try self.context.fetch(request)
            return entities.compactMap { entity in
                self.medicationFromEntity(entity)
            }
        }
    }
    
    func markMedicationSynced(_ medicationId: String) async throws {
        try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "MedicationEntity")
            request.predicate = NSPredicate(format: "id == %@", medicationId)
            
            if let entity = try self.context.fetch(request).first {
                entity.setValue(false, forKey: "needsSync")
                try self.context.save()
            }
        }
    }
    
    func deleteMedication(withId medicationId: String) async throws {
        try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "MedicationEntity")
            request.predicate = NSPredicate(format: "id == %@", medicationId)
            
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
    
    private func medicationFromEntity(_ entity: NSManagedObject) -> Medication? {
        guard
            let id = entity.value(forKey: "id") as? String,
            let userId = entity.value(forKey: "userId") as? String,
            let name = entity.value(forKey: "name") as? String,
            let dosage = entity.value(forKey: "dosage") as? String,
            let frequencyRaw = entity.value(forKey: "frequency") as? String,
            let frequency = MedicationFrequency(rawValue: frequencyRaw),
            let startDate = entity.value(forKey: "startDate") as? Date,
            let createdAt = entity.value(forKey: "createdAt") as? Date,
            let updatedAt = entity.value(forKey: "updatedAt") as? Date,
            let isActive = entity.value(forKey: "isActive") as? Bool,
            let voiceEntryUsed = entity.value(forKey: "voiceEntryUsed") as? Bool,
            let needsSync = entity.value(forKey: "needsSync") as? Bool,
            let isDeleted = entity.value(forKey: "isDeleted") as? Bool
        else {
            return nil
        }
        
        let notes = entity.value(forKey: "notes") as? String
        let prescribedBy = entity.value(forKey: "prescribedBy") as? String
        let endDate = entity.value(forKey: "endDate") as? Date
        
        var schedule: [MedicationSchedule] = []
        if let scheduleData = entity.value(forKey: "scheduleData") as? Data {
            schedule = (try? JSONDecoder().decode([MedicationSchedule].self, from: scheduleData)) ?? []
        }
        
        return Medication(
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: schedule,
            notes: notes,
            prescribedBy: prescribedBy,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            voiceEntryUsed: voiceEntryUsed,
            needsSync: needsSync,
            isDeleted: isDeleted
        )
    }
    
    // MARK: - Supplement Operations
    func saveSupplement(_ supplement: Supplement) async throws {
        try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "SupplementEntity")
            request.predicate = NSPredicate(format: "id == %@", supplement.id)
            
            let existingSupplements = try self.context.fetch(request)
            let supplementEntity: NSManagedObject
            
            if let existing = existingSupplements.first {
                supplementEntity = existing
            } else {
                supplementEntity = NSEntityDescription.insertNewObject(forEntityName: "SupplementEntity", into: self.context)
                supplementEntity.setValue(supplement.id, forKey: "id")
            }
            
            // Update supplement properties
            supplementEntity.setValue(supplement.userId, forKey: "userId")
            supplementEntity.setValue(supplement.name, forKey: "name")
            supplementEntity.setValue(supplement.dosage, forKey: "dosage")
            supplementEntity.setValue(supplement.frequency.rawValue, forKey: "frequency")
            supplementEntity.setValue(supplement.notes, forKey: "notes")
            supplementEntity.setValue(supplement.purpose, forKey: "purpose")
            supplementEntity.setValue(supplement.brand, forKey: "brand")
            supplementEntity.setValue(supplement.isActive, forKey: "isActive")
            supplementEntity.setValue(supplement.createdAt, forKey: "createdAt")
            supplementEntity.setValue(supplement.updatedAt, forKey: "updatedAt")
            supplementEntity.setValue(supplement.voiceEntryUsed, forKey: "voiceEntryUsed")
            supplementEntity.setValue(supplement.needsSync, forKey: "needsSync")
            supplementEntity.setValue(supplement.isDeleted, forKey: "isDeleted")
            
            // Save schedule as JSON data
            if let scheduleData = try? JSONEncoder().encode(supplement.schedule) {
                supplementEntity.setValue(scheduleData, forKey: "scheduleData")
            }
            
            try self.context.save()
        }
    }
    
    func fetchSupplements(for userId: String) async throws -> [Supplement] {
        return try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "SupplementEntity")
            request.predicate = NSPredicate(format: "userId == %@ AND isDeleted == NO", userId)
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try self.context.fetch(request)
            return entities.compactMap { entity in
                self.supplementFromEntity(entity)
            }
        }
    }
    
    private func supplementFromEntity(_ entity: NSManagedObject) -> Supplement? {
        guard
            let id = entity.value(forKey: "id") as? String,
            let userId = entity.value(forKey: "userId") as? String,
            let name = entity.value(forKey: "name") as? String,
            let dosage = entity.value(forKey: "dosage") as? String,
            let frequencyRaw = entity.value(forKey: "frequency") as? String,
            let frequency = SupplementFrequency(rawValue: frequencyRaw),
            let createdAt = entity.value(forKey: "createdAt") as? Date,
            let updatedAt = entity.value(forKey: "updatedAt") as? Date,
            let isActive = entity.value(forKey: "isActive") as? Bool,
            let voiceEntryUsed = entity.value(forKey: "voiceEntryUsed") as? Bool,
            let needsSync = entity.value(forKey: "needsSync") as? Bool,
            let isDeleted = entity.value(forKey: "isDeleted") as? Bool
        else {
            return nil
        }
        
        let notes = entity.value(forKey: "notes") as? String
        let purpose = entity.value(forKey: "purpose") as? String
        let brand = entity.value(forKey: "brand") as? String
        
        var schedule: [SupplementSchedule] = []
        if let scheduleData = entity.value(forKey: "scheduleData") as? Data {
            schedule = (try? JSONDecoder().decode([SupplementSchedule].self, from: scheduleData)) ?? []
        }
        
        return Supplement(
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: schedule,
            notes: notes,
            purpose: purpose,
            brand: brand,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            voiceEntryUsed: voiceEntryUsed,
            needsSync: needsSync,
            isDeleted: isDeleted
        )
    }
    
    // MARK: - Batch Operations
    func clearAllData() async throws {
        try await context.perform {
            let entityNames = ["MedicationEntity", "SupplementEntity", "DietEntryEntity", "DoctorEntity"]
            
            for entityName in entityNames {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                try self.context.execute(deleteRequest)
            }
            
            try self.context.save()
        }
    }
    
    func getDatabaseSize() -> String {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return "Unknown"
        }
        
        do {
            let resources = try storeURL.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resources.fileSize ?? 0
            return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        } catch {
            return "Unknown"
        }
    }
}