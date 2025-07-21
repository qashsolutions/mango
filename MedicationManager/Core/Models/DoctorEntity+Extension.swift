import Foundation
import CoreData

extension DoctorEntity {
    
    // MARK: - Update from Model
    func updateFromModel(_ model: DoctorModel) {
        self.id = model.id
        self.userId = model.userId
        self.name = model.name
        self.specialty = model.specialty
        self.phoneNumber = model.phoneNumber
        self.email = model.email
        self.notes = model.notes
        self.isImportedFromContacts = model.isImportedFromContacts
        self.contactIdentifier = model.contactIdentifier
        self.createdAt = model.createdAt
        self.updatedAt = model.updatedAt
        self.needsSync = model.needsSync
        self.isDeletedFlag = model.isDeletedFlag
        
        // Encode address as Binary data following app patterns
        if let addressData = try? JSONEncoder().encode(model.address) {
            self.addressData = addressData
        }
    }
    
    // MARK: - Convert to Model
    func toModel() -> DoctorModel? {
        guard let id = id,
              let userId = userId,
              let name = name,
              let specialty = specialty,
              let createdAt = createdAt else {
            return nil
        }
        
        // Decode address from Binary data
        var address: DoctorAddress?
        if let data = addressData {
            address = try? JSONDecoder().decode(DoctorAddress.self, from: data)
        }
        
        return DoctorModel(
            id: id,
            userId: userId,
            name: name,
            specialty: specialty,
            phoneNumber: phoneNumber,
            email: email,
            address: address,
            notes: notes,
            isImportedFromContacts: isImportedFromContacts,
            contactIdentifier: contactIdentifier,
            createdAt: createdAt,
            updatedAt: updatedAt ?? Date(),
            voiceEntryUsed: false, // Not stored in Core Data for doctors
            needsSync: needsSync,
            isDeletedFlag: isDeletedFlag
        )
    }
}