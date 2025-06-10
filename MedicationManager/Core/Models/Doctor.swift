import Foundation
import FirebaseFirestore
import Contacts

struct Doctor: Codable, Identifiable, SyncableModel, UserOwnedModel {
    let id: String = UUID().uuidString
    let userId: String
    var name: String
    var specialty: String
    var phoneNumber: String?
    var email: String?
    var address: DoctorAddress?
    var notes: String?
    var isImportedFromContacts: Bool = false
    var contactIdentifier: String?
    let createdAt: Date
    var updatedAt: Date
    
    // Sync properties
    var needsSync: Bool = false
    var isDeleted: Bool = false
}

// MARK: - Doctor Address
struct DoctorAddress: Codable {
    var street: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String = "US"
    
    var fullAddress: String {
        let components = [street, city, state, zipCode, country].compactMap { $0 }
        return components.joined(separator: ", ")
    }
    
    var isEmpty: Bool {
        return street?.isEmpty != false && 
               city?.isEmpty != false && 
               state?.isEmpty != false && 
               zipCode?.isEmpty != false
    }
}

// MARK: - Doctor Extensions
extension Doctor {
    var displayName: String {
        if name.hasPrefix("Dr.") || name.hasPrefix("Dr ") {
            return name
        } else {
            return "Dr. \(name)"
        }
    }
    
    var initials: String {
        let nameComponents = name.components(separatedBy: " ")
        let initials = nameComponents.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    var hasContactInfo: Bool {
        return phoneNumber?.isEmpty == false || email?.isEmpty == false
    }
    
    var formattedPhoneNumber: String? {
        guard let phoneNumber = phoneNumber else { return nil }
        
        // Simple US phone number formatting
        let digits = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digits.count == 10 {
            let area = String(digits.prefix(3))
            let exchange = String(digits.dropFirst(3).prefix(3))
            let number = String(digits.suffix(4))
            return "(\(area)) \(exchange)-\(number)"
        }
        
        return phoneNumber
    }
    
    mutating func updateContactInfo(phone: String?, email: String?) {
        if let phone = phone, !phone.isEmpty {
            self.phoneNumber = phone
        }
        if let email = email, !email.isEmpty {
            self.email = email
        }
        markForSync()
    }
    
    mutating func updateAddress(_ address: DoctorAddress) {
        self.address = address
        markForSync()
    }
    
    mutating func addNote(_ note: String) {
        if let existingNotes = notes, !existingNotes.isEmpty {
            notes = "\(existingNotes)\n\(note)"
        } else {
            notes = note
        }
        markForSync()
    }
}

// MARK: - Doctor Creation Helpers
extension Doctor {
    static func create(
        for userId: String,
        name: String,
        specialty: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        address: DoctorAddress? = nil,
        notes: String? = nil
    ) -> Doctor {
        var doctor = Doctor(
            userId: userId,
            name: name,
            specialty: specialty,
            phoneNumber: phoneNumber,
            email: email,
            address: address,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        doctor.markForSync()
        return doctor
    }
    
    static func createFromContact(
        for userId: String,
        contact: CNContact,
        specialty: String
    ) -> Doctor {
        let phoneNumber = contact.phoneNumbers.first?.value.stringValue
        let email = contact.emailAddresses.first?.value as String?
        
        var address: DoctorAddress?
        if let cnAddress = contact.postalAddresses.first?.value {
            address = DoctorAddress(
                street: cnAddress.street,
                city: cnAddress.city,
                state: cnAddress.state,
                zipCode: cnAddress.postalCode,
                country: cnAddress.country
            )
        }
        
        var doctor = Doctor(
            userId: userId,
            name: "\(contact.givenName) \(contact.familyName)",
            specialty: specialty,
            phoneNumber: phoneNumber,
            email: email,
            address: address,
            notes: nil,
            isImportedFromContacts: true,
            contactIdentifier: contact.identifier,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        doctor.markForSync()
        return doctor
    }
}

// MARK: - Common Specialties
extension Doctor {
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
        
        static var sortedCases: [CommonSpecialty] {
            return [.primaryCare] + allCases.filter { $0 != .primaryCare && $0 != .other }.sorted { $0.rawValue < $1.rawValue } + [.other]
        }
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension Doctor {
    static let sampleDoctor = Doctor(
        userId: "sample-user-id",
        name: "Dr. Sarah Johnson",
        specialty: "Primary Care",
        phoneNumber: "(555) 123-4567",
        email: "dr.johnson@medicalpractice.com",
        address: DoctorAddress(
            street: "123 Medical Center Dr",
            city: "San Francisco",
            state: "CA",
            zipCode: "94103",
            country: "US"
        ),
        notes: "Excellent bedside manner. Accepts most insurance plans.",
        createdAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
        updatedAt: Date()
    )
    
    static let sampleDoctors: [Doctor] = [
        sampleDoctor,
        Doctor(
            userId: "sample-user-id",
            name: "Dr. Michael Chen",
            specialty: "Cardiology",
            phoneNumber: "(555) 987-6543",
            email: "m.chen@heartcenter.com",
            address: DoctorAddress(
                street: "456 Heart Health Blvd",
                city: "San Francisco",
                state: "CA",
                zipCode: "94110",
                country: "US"
            ),
            notes: "Specializes in preventive cardiology. Recommended for annual checkups.",
            createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            updatedAt: Date()
        ),
        Doctor(
            userId: "sample-user-id",
            name: "Dr. Emily Rodriguez",
            specialty: "Endocrinology",
            phoneNumber: "(555) 456-7890",
            email: "e.rodriguez@diabetescenter.org",
            address: DoctorAddress(
                street: "789 Diabetes Care Way",
                city: "Oakland",
                state: "CA",
                zipCode: "94601",
                country: "US"
            ),
            notes: "Diabetes specialist. Very knowledgeable about latest treatments.",
            isImportedFromContacts: true,
            contactIdentifier: "ABC123",
            createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            updatedAt: Date()
        )
    ]
}
#endif