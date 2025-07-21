import Foundation
import CoreData

extension ConflictEntity {
    
    // MARK: - Update from Model
    func updateFromModel(_ model: MedicationConflict) {
        self.id = model.id
        self.userId = model.userId
        self.queryText = model.queryText
        self.conflictsFound = model.conflictsFound
        self.severity = model.severity?.rawValue
        self.educationalInfo = model.educationalInfo
        self.source = model.source.rawValue
        self.confidence = model.confidence ?? 0.0
        self.createdAt = model.createdAt
        self.lastUpdated = model.updatedAt
        self.isResolved = model.isResolved
        self.userNotes = model.userNotes
        self.needsSync = false // Local only, never sync
        self.isDeletedFlag = model.isDeletedFlag
        
        // Encode arrays as Binary data following app patterns
        if !model.medications.isEmpty {
            self.medicationsData = try? JSONEncoder().encode(model.medications)
        }
        
        if !model.supplements.isEmpty {
            self.supplementsData = try? JSONEncoder().encode(model.supplements)
        }
        
        if !model.recommendations.isEmpty {
            self.recommendationsData = try? JSONEncoder().encode(model.recommendations)
        }
        
        // Handle conflictDetails encoding
        if !model.conflictDetails.isEmpty {
            self.conflictDetailsData = try? JSONEncoder().encode(model.conflictDetails)
        }
    }
    
    // MARK: - Convert to Model
    func toModel() -> MedicationConflict? {
        guard id != nil, let userId = userId else { return nil }
        
        // Decode arrays from Binary data following app patterns
        var medications: [String] = []
        if let data = medicationsData {
            medications = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        
        var supplements: [String] = []
        if let data = supplementsData {
            supplements = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        
        var recommendations: [String] = []
        if let data = recommendationsData {
            recommendations = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        
        var conflictDetails: [ConflictDetail] = []
        if let data = conflictDetailsData {
            conflictDetails = (try? JSONDecoder().decode([ConflictDetail].self, from: data)) ?? []
        }
        
        return MedicationConflict(
            userId: userId,
            queryText: queryText ?? "",
            medications: medications,
            supplements: supplements,
            conflictsFound: conflictsFound,
            severity: severity.flatMap { ConflictSeverity(rawValue: $0) },
            conflictDetails: conflictDetails,
            recommendations: recommendations,
            educationalInfo: educationalInfo,
            source: ConflictSource(rawValue: source ?? "") ?? .manual,
            confidence: confidence > 0 ? confidence : nil,
            createdAt: createdAt ?? Date(),
            updatedAt: lastUpdated ?? Date(),
            isResolved: isResolved,
            userNotes: userNotes,
            needsSync: false,
            isDeletedFlag: isDeletedFlag
        )
    }
}
