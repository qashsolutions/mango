import Foundation
import FirebaseFirestore
import Contacts

struct DoctorModel: Codable, Identifiable, Sendable, SyncableModel, VoiceInputCapable, UserOwnedModel {
    let id: String
    let userId: String
    var name: String
    var specialty: String
    var phoneNumber: String?
    var email: String?
    var address: DoctorAddress?
    var notes: String?
    var isImportedFromContacts: Bool
    var contactIdentifier: String?
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool
    
    // Sync properties
    var needsSync: Bool
    var isDeletedFlag: Bool
    
    // MARK: - Initializer
    init(id: String = UUID().uuidString,
         userId: String,
         name: String,
         specialty: String,
         phoneNumber: String? = nil,
         email: String? = nil,
         address: DoctorAddress? = nil,
         notes: String? = nil,
         isImportedFromContacts: Bool = false,
         contactIdentifier: String? = nil,
         createdAt: Date,
         updatedAt: Date,
         voiceEntryUsed: Bool = false,
         needsSync: Bool = false,
         isDeletedFlag: Bool = false) {
        self.id = id
        self.userId = userId
        self.name = name
        self.specialty = specialty
        self.phoneNumber = phoneNumber
        self.email = email
        self.address = address
        self.notes = notes
        self.isImportedFromContacts = isImportedFromContacts
        self.contactIdentifier = contactIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.voiceEntryUsed = voiceEntryUsed
        self.needsSync = needsSync
        self.isDeletedFlag = isDeletedFlag
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, userId, name, specialty, phoneNumber, email, address, notes
        case isImportedFromContacts, contactIdentifier, createdAt, updatedAt
        case voiceEntryUsed, needsSync, isDeletedFlag
    }
}

// MARK: - Doctor Address
struct DoctorAddress: Codable {
    var street: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String = Configuration.App.defaultCountry
    
    var fullAddress: String {
        let components = [street, city, state, zipCode, country].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return components.joined(separator: AppStrings.Common.addressSeparator)
    }
    
    var isEmpty: Bool {
        return street?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
               city?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
               state?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
               zipCode?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
    }
}

// MARK: - Doctor Extensions
extension DoctorModel {
    var displayName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.hasPrefix(AppStrings.Doctors.drPrefix) || trimmedName.hasPrefix(AppStrings.Doctors.drPrefixShort) {
            return trimmedName
        } else {
            return "\(AppStrings.Doctors.drPrefix) \(trimmedName)"
        }
    }
    
    var initials: String {
        let nameComponents = name.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let initials = nameComponents.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    var hasContactInfo: Bool {
        return phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
               email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
    
    var formattedPhoneNumber: String? {
        guard let phoneNumber = phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
              !phoneNumber.isEmpty else { return nil }
        
        // Simple US phone number formatting
        let digits = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digits.count == Configuration.App.phoneNumberLength {
            let area = String(digits.prefix(3))
            let exchange = String(digits.dropFirst(3).prefix(3))
            let number = String(digits.suffix(4))
            return AppStrings.Doctors.phoneFormat
                .replacingOccurrences(of: "{area}", with: area)
                .replacingOccurrences(of: "{exchange}", with: exchange)
                .replacingOccurrences(of: "{number}", with: number)
        }
        
        return phoneNumber
    }
    
    var isValidEmail: Bool {
        guard let email = email?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else { return true }
        
        let emailRegex = Configuration.App.emailRegex
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    var isValidPhone: Bool {
        guard let phone = phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
              !phone.isEmpty else { return true }
        
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digits.count == Configuration.App.phoneNumberLength
    }
    
    mutating func updateContactInfo(phone: String?, email: String?) {
        if let phone = phone?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty {
            self.phoneNumber = phone
        }
        if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            self.email = email
        }
        markForSync()
    }
    
    mutating func updateAddress(_ address: DoctorAddress) {
        self.address = address
        markForSync()
    }
    
    mutating func addNote(_ note: String) {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else { return }
        
        if let existingNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines), !existingNotes.isEmpty {
            notes = "\(existingNotes)\n\(trimmedNote)"
        } else {
            notes = trimmedNote
        }
        markForSync()
    }
    
    mutating func clearNotes() {
        notes = nil
        markForSync()
    }
}

// MARK: - Doctor Creation Helpers
extension DoctorModel{
    static func create(
        for userId: String,
        name: String,
        specialty: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        address: DoctorAddress? = nil,
        notes: String? = nil,
        voiceEntryUsed: Bool = false
    ) -> DoctorModel {
        let now = Date()
        let doctor = DoctorModel(
            id: UUID().uuidString,
            userId: userId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            specialty: specialty.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email?.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address,
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines),
            isImportedFromContacts: false,
            contactIdentifier: nil,
            createdAt: now,
            updatedAt: now,
            voiceEntryUsed: voiceEntryUsed,
            needsSync: true,
            isDeletedFlag: false
        )
        
        return doctor
    }
    
    static func createFromContact(
        for userId: String,
        contact: CNContact,
        specialty: String
    ) -> DoctorModel {
        let phoneNumber = contact.phoneNumbers.first?.value.stringValue
        let email = contact.emailAddresses.first?.value as String?
        
        var address: DoctorAddress?
        if let cnAddress = contact.postalAddresses.first?.value {
            address = DoctorAddress(
                street: cnAddress.street.trimmingCharacters(in: .whitespacesAndNewlines),
                city: cnAddress.city.trimmingCharacters(in: .whitespacesAndNewlines),
                state: cnAddress.state.trimmingCharacters(in: .whitespacesAndNewlines),
                zipCode: cnAddress.postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
                country: cnAddress.country.isEmpty ? Configuration.App.defaultCountry : cnAddress.country
            )
        }
        
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        
        let now = Date()
        let doctor = DoctorModel(
            id: UUID().uuidString,
            userId: userId,
            name: fullName,
            specialty: specialty.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber,
            email: email,
            address: address,
            notes: nil,
            isImportedFromContacts: true,
            contactIdentifier: contact.identifier,
            createdAt: now,
            updatedAt: now,
            voiceEntryUsed: false,
            needsSync: true,
            isDeletedFlag: false
        )
        
        return doctor
    }
}

// MARK: - Validation
extension DoctorModel {
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !userId.isEmpty &&
        isValidEmail &&
        isValidPhone
    }
}

// MARK: - Common Specialties
extension DoctorModel {
    enum CommonSpecialty: String, CaseIterable {
        case primaryCare = "Primary Care"
        case cardiology = "Cardiology"
        case endocrinology = "Endocrinology"
        case neurology = "Neurology"
        case psychiatry = "Psychiatry"
        case dermatology = "Dermatology"
        case orthopedics = "Orthopedics"
        case ophthalmology = "Ophthalmology"
        case gastroenterology = "Gastroenterology"
        case pulmonology = "Pulmonology"
        case nephrology = "Nephrology"
        case rheumatology = "Rheumatology"
        case oncology = "Oncology"
        case urology = "Urology"
        case gynecology = "Gynecology"
        case pediatrics = "Pediatrics"
        case emergency = "Emergency Medicine"
        case anesthesiology = "Anesthesiology"
        case radiology = "Radiology"
        case pathology = "Pathology"
        case other = "Other"
        
        var localizedName: String {
            switch self {
            case .primaryCare:
                return AppStrings.Doctors.specialtyPrimaryCare
            case .cardiology:
                return AppStrings.Doctors.specialtyCardiology
            case .endocrinology:
                return AppStrings.Doctors.specialtyEndocrinology
            case .neurology:
                return AppStrings.Doctors.specialtyNeurology
            case .psychiatry:
                return AppStrings.Doctors.specialtyPsychiatry
            case .dermatology:
                return AppStrings.Doctors.specialtyDermatology
            case .orthopedics:
                return AppStrings.Doctors.specialtyOrthopedics
            case .ophthalmology:
                return AppStrings.Doctors.specialtyOphthalmology
            case .gastroenterology:
                return AppStrings.Doctors.specialtyGastroenterology
            case .pulmonology:
                return AppStrings.Doctors.specialtyPulmonology
            case .nephrology:
                return AppStrings.Doctors.specialtyNephrology
            case .rheumatology:
                return AppStrings.Doctors.specialtyRheumatology
            case .oncology:
                return AppStrings.Doctors.specialtyOncology
            case .urology:
                return AppStrings.Doctors.specialtyUrology
            case .gynecology:
                return AppStrings.Doctors.specialtyGynecology
            case .pediatrics:
                return AppStrings.Doctors.specialtyPediatrics
            case .emergency:
                return AppStrings.Doctors.specialtyEmergency
            case .anesthesiology:
                return AppStrings.Doctors.specialtyAnesthesiology
            case .radiology:
                return AppStrings.Doctors.specialtyRadiology
            case .pathology:
                return AppStrings.Doctors.specialtyPathology
            case .other:
                return AppStrings.Doctors.specialtyOther
            }
        }
        
        static var sortedCases: [CommonSpecialty] {
            return [.primaryCare] + allCases.filter { $0 != .primaryCare && $0 != .other }.sorted { $0.localizedName < $1.localizedName } + [.other]
        }
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension DoctorModel {
    static let sampleDoctor = DoctorModel(
        id: "sample-doctor-1",
        userId: Configuration.Debug.sampleUserId,
        name: AppStrings.Doctors.sampleName1,
        specialty: AppStrings.Doctors.specialtyPrimaryCare,
        phoneNumber: AppStrings.Doctors.samplePhone1,
        email: AppStrings.Doctors.sampleEmail1,
        address: DoctorAddress(
            street: AppStrings.Doctors.sampleStreet1,
            city: AppStrings.Doctors.sampleCity1,
            state: AppStrings.Doctors.sampleState1,
            zipCode: AppStrings.Doctors.sampleZip1,
            country: Configuration.App.defaultCountry
        ),
        notes: AppStrings.Doctors.sampleNotes1,
        isImportedFromContacts: false,
        contactIdentifier: nil,
        createdAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
        updatedAt: Date(),
        voiceEntryUsed: false,
        needsSync: false,
        isDeletedFlag: false
    )
    
    static let sampleDoctors: [DoctorModel] = [
        sampleDoctor,
        DoctorModel(
            id: "sample-doctor-2",
            userId: Configuration.Debug.sampleUserId,
            name: AppStrings.Doctors.sampleName2,
            specialty: AppStrings.Doctors.specialtyCardiology,
            phoneNumber: AppStrings.Doctors.samplePhone2,
            email: AppStrings.Doctors.sampleEmail2,
            address: DoctorAddress(
                street: AppStrings.Doctors.sampleStreet2,
                city: AppStrings.Doctors.sampleCity2,
                state: AppStrings.Doctors.sampleState2,
                zipCode: AppStrings.Doctors.sampleZip2,
                country: Configuration.App.defaultCountry
            ),
            notes: AppStrings.Doctors.sampleNotes2,
            isImportedFromContacts: false,
            contactIdentifier: nil,
            createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            updatedAt: Date(),
            voiceEntryUsed: false,
            needsSync: false,
            isDeletedFlag: false
        ),
        DoctorModel(
            id: "sample-doctor-3",
            userId: Configuration.Debug.sampleUserId,
            name: AppStrings.Doctors.sampleName3,
            specialty: AppStrings.Doctors.specialtyEndocrinology,
            phoneNumber: AppStrings.Doctors.samplePhone3,
            email: AppStrings.Doctors.sampleEmail3,
            address: DoctorAddress(
                street: AppStrings.Doctors.sampleStreet3,
                city: AppStrings.Doctors.sampleCity3,
                state: AppStrings.Doctors.sampleState3,
                zipCode: AppStrings.Doctors.sampleZip3,
                country: Configuration.App.defaultCountry
            ),
            notes: AppStrings.Doctors.sampleNotes3,
            isImportedFromContacts: true,
            contactIdentifier: AppStrings.Doctors.sampleContactId,
            createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            updatedAt: Date(),
            voiceEntryUsed: false,
            needsSync: false,
            isDeletedFlag: false
        )
    ]
}
#endif
