import Foundation
import Contacts
import MessageUI

@MainActor
class DoctorListViewModel: ObservableObject {
    @Published var doctors: [Doctor] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    private let coreDataManager = CoreDataManager.shared
    private let dataSyncManager = DataSyncManager.shared
    private let authManager = FirebaseManager.shared
    private let analyticsManager = AnalyticsManager.shared
    
    // MARK: - Data Loading
    func loadData() async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            doctors = try await loadDoctors(for: userId)
            analyticsManager.trackScreenViewed("doctor_list")
        } catch {
            self.error = error as? AppError ?? AppError.data(.loadFailed)
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await dataSyncManager.syncPendingChanges()
        await loadData()
    }
    
    private func loadDoctors(for userId: String) async throws -> [Doctor] {
        // TODO: Implement doctor fetching in CoreDataManager
        // For now, return sample data
        return Doctor.sampleDoctors.filter { $0.userId == userId }
    }
    
    // MARK: - Doctor Management
    func addDoctor(_ doctor: Doctor) async {
        do {
            var newDoctor = doctor
            newDoctor.markForSync()
            
            // TODO: Implement doctor saving in CoreDataManager
            // try await coreDataManager.saveDoctor(newDoctor)
            
            analyticsManager.trackDoctorAdded(
                method: "manual",
                fromContacts: false
            )
            
            // Update local state
            doctors.append(newDoctor)
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    func importDoctor(from contact: CNContact, specialty: String) async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            let doctor = Doctor.createFromContact(
                for: userId,
                contact: contact,
                specialty: specialty
            )
            
            // TODO: Implement doctor saving in CoreDataManager
            // try await coreDataManager.saveDoctor(doctor)
            
            analyticsManager.trackDoctorAdded(
                method: "import",
                fromContacts: true
            )
            
            // Update local state
            doctors.append(doctor)
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    func updateDoctor(_ doctor: Doctor) async {
        do {
            var updatedDoctor = doctor
            updatedDoctor.markForSync()
            
            // TODO: Implement doctor updating in CoreDataManager
            // try await coreDataManager.saveDoctor(updatedDoctor)
            
            // Update local state
            if let index = doctors.firstIndex(where: { $0.id == doctor.id }) {
                doctors[index] = updatedDoctor
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    func deleteDoctor(_ doctor: Doctor) async {
        do {
            var deletedDoctor = doctor
            deletedDoctor.isDeleted = true
            deletedDoctor.markForSync()
            
            // TODO: Implement doctor deletion in CoreDataManager
            // try await coreDataManager.saveDoctor(deletedDoctor)
            
            // Update local state
            doctors.removeAll { $0.id == doctor.id }
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    // MARK: - Doctor Communication
    func contactDoctor(_ doctor: Doctor) async {
        guard doctor.hasContactInfo else {
            error = AppError.data(.validationFailed)
            return
        }
        
        // Track the contact attempt
        analyticsManager.trackDoctorContacted(method: "phone")
        
        // Attempt to make phone call
        if let phoneNumber = doctor.phoneNumber,
           let phoneURL = URL(string: "tel://\(phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())"),
           UIApplication.shared.canOpenURL(phoneURL) {
            
            await UIApplication.shared.open(phoneURL)
        } else {
            error = AppError.data(.validationFailed)
        }
    }
    
    func emailDoctor(_ doctor: Doctor) async {
        guard let email = doctor.email else {
            error = AppError.data(.validationFailed)
            return
        }
        
        analyticsManager.trackDoctorContacted(method: "email")
        
        if let emailURL = URL(string: "mailto:\(email)"),
           UIApplication.shared.canOpenURL(emailURL) {
            await UIApplication.shared.open(emailURL)
        } else {
            error = AppError.data(.validationFailed)
        }
    }
    
    func shareDoctor(_ doctor: Doctor) -> [Any] {
        analyticsManager.trackFeatureUsed("doctor_share")
        
        var shareItems: [Any] = []
        
        // Create contact card text
        var contactText = "\(doctor.displayName)\n"
        contactText += "\(doctor.specialty)\n"
        
        if let phone = doctor.formattedPhoneNumber {
            contactText += "Phone: \(phone)\n"
        }
        
        if let email = doctor.email {
            contactText += "Email: \(email)\n"
        }
        
        if let address = doctor.address, !address.isEmpty {
            contactText += "Address: \(address.fullAddress)\n"
        }
        
        shareItems.append(contactText)
        
        return shareItems
    }
    
    // MARK: - Search and Filter
    func searchDoctors(query: String) -> [Doctor] {
        if query.isEmpty {
            return doctors
        }
        
        return doctors.filter { doctor in
            doctor.name.localizedCaseInsensitiveContains(query) ||
            doctor.specialty.localizedCaseInsensitiveContains(query) ||
            (doctor.phoneNumber?.localizedCaseInsensitiveContains(query) ?? false) ||
            (doctor.email?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func filterDoctorsBySpecialty(_ specialty: String) -> [Doctor] {
        if specialty.isEmpty {
            return doctors
        }
        
        return doctors.filter { $0.specialty == specialty }
    }
    
    func getDoctorsBySpecialty() -> [String: [Doctor]] {
        return Dictionary(grouping: doctors) { $0.specialty }
    }
    
    // MARK: - Statistics
    func getDoctorStatistics() -> DoctorStatistics {
        return DoctorStatistics(doctors: doctors)
    }
    
    func getSpecialtyDistribution() -> [(String, Int)] {
        let grouped = Dictionary(grouping: doctors) { $0.specialty }
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
    
    // MARK: - Contacts Integration
    func requestContactsPermission() async -> Bool {
        let store = CNContactStore()
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted
        } catch {
            self.error = AppError.data(.validationFailed)
            return false
        }
    }
    
    func exportDoctorToContacts(_ doctor: Doctor) async {
        let hasPermission = await requestContactsPermission()
        guard hasPermission else {
            error = AppError.data(.validationFailed)
            return
        }
        
        do {
            let store = CNContactStore()
            let contact = CNMutableContact()
            
            // Parse name
            let nameComponents = doctor.name.components(separatedBy: " ")
            if nameComponents.count >= 2 {
                contact.givenName = nameComponents.first ?? ""
                contact.familyName = nameComponents.dropFirst().joined(separator: " ")
            } else {
                contact.givenName = doctor.name
            }
            
            // Add phone number
            if let phoneNumber = doctor.phoneNumber {
                let phone = CNLabeledValue<CNPhoneNumber>(
                    label: CNLabelWork,
                    value: CNPhoneNumber(stringValue: phoneNumber)
                )
                contact.phoneNumbers = [phone]
            }
            
            // Add email
            if let email = doctor.email {
                let emailValue = CNLabeledValue<NSString>(
                    label: CNLabelWork,
                    value: email as NSString
                )
                contact.emailAddresses = [emailValue]
            }
            
            // Add address
            if let address = doctor.address, !address.isEmpty {
                let postalAddress = CNMutablePostalAddress()
                postalAddress.street = address.street ?? ""
                postalAddress.city = address.city ?? ""
                postalAddress.state = address.state ?? ""
                postalAddress.postalCode = address.zipCode ?? ""
                postalAddress.country = address.country
                
                let addressValue = CNLabeledValue<CNPostalAddress>(
                    label: CNLabelWork,
                    value: postalAddress
                )
                contact.postalAddresses = [addressValue]
            }
            
            // Set organization
            contact.organizationName = doctor.specialty
            
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)
            
            try store.execute(saveRequest)
            
            analyticsManager.trackFeatureUsed("doctor_export_contacts")
            
        } catch {
            self.error = AppError.data(.saveFailed)
        }
    }
    
    // MARK: - Emergency Contacts
    func getEmergencyDoctors() -> [Doctor] {
        // TODO: Implement emergency doctor logic
        // For now, return primary care doctors
        return doctors.filter { $0.specialty.contains("Primary") }
    }
    
    func markAsEmergencyContact(_ doctor: Doctor) async {
        // TODO: Implement emergency contact marking
        analyticsManager.trackFeatureUsed("doctor_mark_emergency")
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
    
    func retryLastAction() async {
        await loadData()
    }
    
    // MARK: - Navigation Helpers
    func getDoctorsByRecency() -> [Doctor] {
        return doctors.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getDoctorsWithUpcomingAppointments() -> [Doctor] {
        // TODO: Implement appointment integration
        // For now, return empty array
        return []
    }
    
    func getRecentlyContactedDoctors() -> [Doctor] {
        // TODO: Implement recent contact tracking
        // For now, return first 3 doctors
        return Array(doctors.prefix(3))
    }
}

// MARK: - Sample Data Extension
#if DEBUG
extension DoctorListViewModel {
    static let sampleViewModel: DoctorListViewModel = {
        let viewModel = DoctorListViewModel()
        viewModel.doctors = Doctor.sampleDoctors
        return viewModel
    }()
}
#endif
