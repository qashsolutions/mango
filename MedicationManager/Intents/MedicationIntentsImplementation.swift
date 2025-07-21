import Foundation
import AppIntents
import os.log

// MARK: - All App Intent Implementations in Single File (Swift 6 Best Practice)
// Based on Apple's guidance and to avoid Swift 6 concurrency issues,
// all intents are consolidated in this single file.

private let logger = Logger(subsystem: Configuration.App.bundleId, category: "Intents")

// MARK: - Medication Entity for App Intents

@available(iOS 18.0, *)
public struct MedicationAppEntity: AppEntity, Sendable {
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Medication"
    public static let defaultQuery = MedicationAppEntityQuery()
    
    public let id: String
    public let name: String
    public let dosage: String?
    public let userId: String
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    public init(id: String, name: String, dosage: String? = nil, userId: String) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.userId = userId
    }
}

// MARK: - Medication Entity Query

@available(iOS 18.0, *)
public struct MedicationAppEntityQuery: EntityQuery {
    public typealias Entity = MedicationAppEntity
    
    public init() {}
    
    public func entities(for identifiers: [String]) async throws -> [MedicationAppEntity] {
        guard let userId = await FirebaseManager.shared.currentUser?.id else {
            return []
        }
        
        let medications = try await CoreDataManager.shared.fetchMedications(for: userId)
        
        return identifiers.compactMap { id in
            guard let medication = medications.first(where: { $0.id == id }) else {
                return nil
            }
            return MedicationAppEntity(
                id: medication.id,
                name: medication.name,
                dosage: medication.dosage,
                userId: userId
            )
        }
    }
    
    public func suggestedEntities() async throws -> [MedicationAppEntity] {
        guard let userId = await FirebaseManager.shared.currentUser?.id else {
            return []
        }
        
        let medications = try await CoreDataManager.shared.fetchMedications(for: userId)
        
        return medications
            .filter { $0.isActive }
            .prefix(10)
            .map { medication in
                MedicationAppEntity(
                    id: medication.id,
                    name: medication.name,
                    dosage: medication.dosage,
                    userId: userId
                )
            }
    }
}

@available(iOS 18.0, *)
extension MedicationAppEntityQuery: EntityStringQuery {
    public func entities(matching string: String) async throws -> [MedicationAppEntity] {
        guard let userId = await FirebaseManager.shared.currentUser?.id else {
            return []
        }
        
        let medications = try await CoreDataManager.shared.fetchMedications(for: userId)
        
        let searchString = string.lowercased()
        return medications
            .filter { $0.name.lowercased().contains(searchString) }
            .map { medication in
                MedicationAppEntity(
                    id: medication.id,
                    name: medication.name,
                    dosage: medication.dosage,
                    userId: userId
                )
            }
    }
}

// MARK: - Check Medications Intent

@available(iOS 18.0, *)
public struct CheckMedicationsIntent: AppIntent {
    public static let title: LocalizedStringResource = "Check Medications"
    public static let description = IntentDescription("Check your active medications and get a count")
    public static let openAppWhenRun: Bool = false
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Check medications")
    }
    
    public func perform() async throws -> some ProvidesDialog {
        logger.info("Executing CheckMedicationsIntent")
        
        let result = await SiriIntentsManager.shared.handleCheckMedications()
        
        return .result(dialog: IntentDialog(stringLiteral: result.message))
    }
}

// MARK: - Add Medication Intent

@available(iOS 18.0, *)
public struct AddMedicationIntent: AppIntent {
    public static let title: LocalizedStringResource = "Add Medication"
    public static let description = IntentDescription("Add a new medication to your list")
    public static let openAppWhenRun: Bool = false
    
    public init() {
        self.medicationName = ""
    }
    
    @Parameter(title: "Medication Name", requestValueDialog: IntentDialog("What medication would you like to add?"))
    public var medicationName: String // Keep as String for new medication entry
    
    @Parameter(title: "Dosage", requestValueDialog: IntentDialog("What's the dosage?"))
    public var dosage: String?
    
    @Parameter(title: "Frequency", requestValueDialog: IntentDialog("How often do you take it?"))
    public var frequency: String?
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$medicationName) to medications") {
            \.$medicationName
            \.$dosage
            \.$frequency
        }
    }
    
    public func perform() async throws -> some ProvidesDialog {
        logger.info("Executing AddMedicationIntent - name: \(medicationName)")
        
        let result = await SiriIntentsManager.shared.handleAddMedication(
            name: medicationName,
            dosage: dosage,
            frequency: frequency
        )
        
        return .result(dialog: IntentDialog(stringLiteral: result.message))
    }
}

// MARK: - Check Conflicts Intent

@available(iOS 18.0, *)
public struct CheckConflictsIntent: AppIntent {
    public static let title: LocalizedStringResource = "Check Medication Conflicts"
    public static let description = IntentDescription("Check for interactions between your medications")
    public static let openAppWhenRun: Bool = false
    
    public init() {}
    
    @Parameter(title: "Medications", requestValueDialog: IntentDialog("Which medications should I check? (Leave empty to check all)"))
    public var medications: [String]?
    
    public static var parameterSummary: some ParameterSummary {
        When(\.$medications, .notEqualTo, nil) {
            Summary("Check conflicts for \(\.$medications)") {
                \.$medications
            }
        } otherwise: {
            Summary("Check all medication conflicts")
        }
    }
    
    public func perform() async throws -> some ProvidesDialog {
        logger.info("Executing CheckConflictsIntent")
        
        let result = await SiriIntentsManager.shared.handleCheckConflicts(medications: medications)
        
        return .result(dialog: IntentDialog(stringLiteral: result.message))
    }
}

// MARK: - Log Medication Intent

@available(iOS 18.0, *)
public struct LogMedicationIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log Medication"
    public static let description = IntentDescription("Mark a medication as taken or skipped")
    public static let openAppWhenRun: Bool = false
    
    public init() {
        self.medication = MedicationAppEntity(id: "", name: "", userId: "")
        self.taken = true
    }
    
    @Parameter(title: "Medication", requestValueDialog: IntentDialog("Which medication?"))
    public var medication: MedicationAppEntity
    
    @Parameter(title: "Taken", default: true, requestValueDialog: IntentDialog("Did you take it?"))
    public var taken: Bool
    
    public static var parameterSummary: some ParameterSummary {
        When(\.$taken, .equalTo, true) {
            Summary("Log \(\.$medication) as taken") {
                \.$medication
            }
        } otherwise: {
            Summary("Skip \(\.$medication)") {
                \.$medication
            }
        }
    }
    
    public func perform() async throws -> some ProvidesDialog {
        logger.info("Executing LogMedicationIntent - name: \(medication.name), taken: \(taken)")
        
        let result = await SiriIntentsManager.shared.handleLogMedication(
            name: medication.name,
            taken: taken
        )
        
        return .result(dialog: IntentDialog(stringLiteral: result.message))
    }
}

// MARK: - Set Reminder Intent

@available(iOS 18.0, *)
public struct SetReminderIntent: AppIntent {
    public static let title: LocalizedStringResource = "Set Medication Reminder"
    public static let description = IntentDescription("Set a reminder for a medication")
    public static let openAppWhenRun: Bool = false
    
    public init() {
        self.medication = MedicationAppEntity(id: "", name: "", userId: "")
    }
    
    @Parameter(title: "Medication", requestValueDialog: IntentDialog("Which medication?"))
    public var medication: MedicationAppEntity
    
    @Parameter(title: "Time", requestValueDialog: IntentDialog("When should I remind you?"))
    public var reminderTime: Date?
    
    public static var parameterSummary: some ParameterSummary {
        When(\.$reminderTime, .notEqualTo, nil) {
            Summary("Remind me to take \(\.$medication) at \(\.$reminderTime)") {
                \.$medication
                \.$reminderTime
            }
        } otherwise: {
            Summary("Set reminder for \(\.$medication)") {
                \.$medication
            }
        }
    }
    
    public func perform() async throws -> some ProvidesDialog {
        logger.info("Executing SetReminderIntent - name: \(medication.name)")
        
        let result = await SiriIntentsManager.shared.handleSetReminder(
            name: medication.name,
            time: reminderTime
        )
        
        return .result(dialog: IntentDialog(stringLiteral: result.message))
    }
}

// MARK: - Voice Query Intent

@available(iOS 18.0, *)
public struct VoiceQueryIntent: AppIntent {
    public static let title: LocalizedStringResource = "Ask About Medications"
    public static let description = IntentDescription("Ask a question about your medications")
    public static let openAppWhenRun: Bool = false
    
    public init() {
        self.query = ""
    }
    
    @Parameter(title: "Question", requestValueDialog: IntentDialog("What would you like to know about your medications?"))
    public var query: String // Keep as String for free-form queries
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Ask: \(\.$query)") {
            \.$query
        }
    }
    
    public func perform() async throws -> some ProvidesDialog {
        logger.info("Executing VoiceQueryIntent - query: \(query)")
        
        let result = await SiriIntentsManager.shared.handleVoiceQuery(query)
        
        return .result(dialog: IntentDialog(stringLiteral: result.message))
    }
}

// MARK: - Intent Donation Helper

@available(iOS 18.0, *)
extension AppIntent {
    /// Donate this intent to the system for Siri suggestions
    func donateToSystem() async {
        do {
            try await self.donate()
            logger.debug("Successfully donated \(String(describing: type(of: self))) to system")
        } catch {
            logger.error("Failed to donate intent: \(error.localizedDescription)")
        }
    }
}