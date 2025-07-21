import Foundation
import Contacts
import MessageUI
import OSLog
import Observation

@MainActor
@Observable
final class DoctorListViewModel {
    var doctors: [DoctorModel] = []
    var isLoading: Bool = false
    var error: AppError?
    
    private let coreDataManager = CoreDataManager.shared
    private let dataSyncManager = DataSyncManager.shared
    private let authManager = FirebaseManager.shared
    private let analyticsManager = AnalyticsManager.shared
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MedicationManager", category: "DoctorListViewModel")
    
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
            logger.info("Loaded \(self.doctors.count) doctors for user")
        } catch {
            self.error = error as? AppError ?? AppError.data(.loadFailed)
            logger.error("Failed to load doctors: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        do {
            try await dataSyncManager.syncPendingChanges()
        } catch {
            // Handle error or ignore if sync failure is acceptable
            logger.warning("Sync failed during refresh: \(error)")
        }
        await loadData()
    }
    
    private func loadDoctors(for userId: String) async throws -> [DoctorModel] {
        // TODO: Implement fetchDoctors in CoreDataManager
        // For now, return sample data filtered by userId
        let allDoctors = DoctorModel.sampleDoctors.filter { $0.userId == userId }
        logger.debug("Fetched \(allDoctors.count) doctors from sample data")
        return allDoctors
    }
    
    // MARK: - Doctor Management
    func addDoctor(_ doctor: DoctorModel) async {
        // Validate required fields
        guard validateDoctor(doctor) else {
            error = AppError.data(.validationFailed)
            return
        }
        
        var newDoctor = doctor
        newDoctor.markForSync()
        
        // TODO: Implement saveDoctor in CoreDataManager
        // try await coreDataManager.saveDoctor(newDoctor)
        
        analyticsManager.trackDoctorAdded(
            method: "manual",
            fromContacts: false
        )
        
        // Update local state
        doctors.append(newDoctor)
        logger.info("Added new doctor: \(newDoctor.name)")
    }
    
    func importDoctor(from contact: CNContact, specialty: String) async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        let doctor = createDoctorFromContact(
            for: userId,
            contact: contact,
            specialty: specialty
        )
        
        // Validate the imported doctor
        guard validateDoctor(doctor) else {
            error = AppError.data(.validationFailed)
            return
        }
        
        // TODO: Implement saveDoctor in CoreDataManager
        // try await coreDataManager.saveDoctor(doctor)
        
        analyticsManager.trackDoctorAdded(
            method: "import",
            fromContacts: true
        )
        
        // Update local state
        doctors.append(doctor)
        logger.info("Imported doctor from contacts: \(doctor.name)")
    }
    
    func updateDoctor(_ doctor: DoctorModel) async {
        // Validate required fields
        guard validateDoctor(doctor) else {
            error = AppError.data(.validationFailed)
            return
        }
        
        var updatedDoctor = doctor
        updatedDoctor.updatedAt = Date()
        updatedDoctor.markForSync()
        
        // TODO: Implement saveDoctor in CoreDataManager
        // try await coreDataManager.saveDoctor(updatedDoctor)
        
        // Update local state
        if let index = doctors.firstIndex(where: { $0.id == doctor.id }) {
            doctors[index] = updatedDoctor
        }
        
        logger.info("Updated doctor: \(updatedDoctor.name)")
    }
    
    func deleteDoctor(_ doctor: DoctorModel) async {
        var deletedDoctor = doctor
        deletedDoctor.isDeletedFlag = true
        deletedDoctor.markForSync()
        
        // TODO: Implement saveDoctor in CoreDataManager
        // try await coreDataManager.saveDoctor(deletedDoctor)
        
        // Update local state
        doctors.removeAll { $0.id == doctor.id }
        
        analyticsManager.trackFeatureUsed("doctor_deleted")
        logger.info("Deleted doctor: \(doctor.name)")
    }
    
    // MARK: - Emergency Doctor Management
    func toggleEmergencyStatus(_ doctor: DoctorModel) async {
        var updatedDoctor = doctor
        updatedDoctor.notes = doctor.notes == "Emergency Contact" ? nil : "Emergency Contact"
        await updateDoctor(updatedDoctor)
        
        analyticsManager.trackFeatureUsed("doctor_emergency_toggled")
        logger.info("Toggled emergency status for doctor: \(doctor.name)")
    }
    
    func getEmergencyDoctors() -> [DoctorModel] {
        let emergencyDoctors = doctors.filter { $0.notes == "Emergency Contact" }
        logger.debug("Found \(emergencyDoctors.count) emergency doctors")
        return emergencyDoctors
    }
    
    func markAsEmergencyContact(_ doctor: DoctorModel) async {
        var updatedDoctor = doctor
        updatedDoctor.notes = "Emergency Contact"
        await updateDoctor(updatedDoctor)
        
        analyticsManager.trackFeatureUsed("doctor_mark_emergency")
        logger.info("Marked doctor as emergency contact: \(doctor.name)")
    }
    
    func removeFromEmergencyContacts(_ doctor: DoctorModel) async {
        var updatedDoctor = doctor
        updatedDoctor.notes = updatedDoctor.notes == "Emergency Contact" ? nil : updatedDoctor.notes
        await updateDoctor(updatedDoctor)
        
        analyticsManager.trackFeatureUsed("doctor_remove_emergency")
        logger.info("Removed doctor from emergency contacts: \(doctor.name)")
    }
    
    // MARK: - Validation
    private func validateDoctor(_ doctor: DoctorModel) -> Bool {
        // Name is required
        guard !doctor.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = AppError.data(.validationFailed)
            logger.warning("Doctor validation failed: Name is required")
            return false
        }
        
        // Contact info (email OR phone) is required
        let hasEmail = doctor.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasPhone = doctor.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        
        guard hasEmail || hasPhone else {
            error = AppError.data(.validationFailed)
            logger.warning("Doctor validation failed: Email or phone number is required")
            return false
        }
        
        // Validate email format if provided
        if let email = doctor.email, !email.isEmpty {
            let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            guard emailPredicate.evaluate(with: email) else {
                error = AppError.data(.validationFailed)
                logger.warning("Doctor validation failed: Invalid email format")
                return false
            }
        }
        
        // Validate phone format if provided
        if let phone = doctor.phoneNumber, !phone.isEmpty {
            let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            guard cleanPhone.count >= 10 && cleanPhone.count <= 15 else {
                error = AppError.data(.validationFailed)
                logger.warning("Doctor validation failed: Invalid phone number format")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Doctor Communication
    func contactDoctor(_ doctor: DoctorModel) async {
        guard hasContactInfo(doctor) else {
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
            logger.info("Initiated phone call to doctor: \(doctor.name)")
        } else {
            error = AppError.data(.validationFailed)
            logger.warning("Failed to initiate phone call - invalid number")
        }
    }
    
    func emailDoctor(_ doctor: DoctorModel) async {
        guard let email = doctor.email else {
            error = AppError.data(.validationFailed)
            return
        }
        
        analyticsManager.trackDoctorContacted(method: "email")
        
        if let emailURL = URL(string: "mailto:\(email)"),
           UIApplication.shared.canOpenURL(emailURL) {
            await UIApplication.shared.open(emailURL)
            logger.info("Opened email client for doctor: \(doctor.name)")
        } else {
            error = AppError.data(.validationFailed)
            logger.warning("Failed to open email client - invalid email")
        }
    }
    
    func shareDoctor(_ doctor: DoctorModel) -> [Any] {
        analyticsManager.trackFeatureUsed("doctor_share")
        
        var shareItems: [Any] = []
        
        // Create contact card text
        var contactText = "\(displayName(doctor))\n"
        if !doctor.specialty.isEmpty {
            contactText += "\(doctor.specialty)\n"
        }
        
        if let phone = formattedPhoneNumber(doctor) {
            contactText += "\(AppStrings.Doctors.phone): \(phone)\n"
        }
        
        if let email = doctor.email {
            contactText += "\(AppStrings.Doctors.email): \(email)\n"
        }
        
        if let address = doctor.address, !isAddressEmpty(address) {
            contactText += "Address: \(fullAddress(address))\n"
        }
        
        if doctor.notes == "Emergency Contact" {
            contactText += "⚠️ \(AppStrings.Doctors.emergencyContact)\n"
        }
        
        contactText += "\nShared from MyGuide"
        
        shareItems.append(contactText)
        logger.info("Prepared doctor info for sharing: \(doctor.name)")
        
        return shareItems
    }
    
    // MARK: - Search and Filter
    func searchDoctors(query: String) -> [DoctorModel] {
        if query.isEmpty {
            return doctors
        }
        
        let results = doctors.filter { doctor in
            doctor.name.localizedCaseInsensitiveContains(query) ||
            doctor.specialty.localizedCaseInsensitiveContains(query) ||
            (doctor.phoneNumber?.localizedCaseInsensitiveContains(query) ?? false) ||
            (doctor.email?.localizedCaseInsensitiveContains(query) ?? false)
        }
        
        logger.debug("Search for '\(query)' returned \(results.count) results")
        return results
    }
    
    func filterDoctorsBySpecialty(_ specialty: String) -> [DoctorModel] {
        if specialty.isEmpty {
            return doctors
        }
        
        return doctors.filter { $0.specialty.localizedCaseInsensitiveContains(specialty) }
    }
    
    func getDoctorsBySpecialty() -> [String: [DoctorModel]] {
        return Dictionary(grouping: doctors) { $0.specialty.isEmpty ? AppStrings.Doctors.noSpecialty : $0.specialty }
    }
    
    func getUniqueSpecialties() -> [String] {
        let specialties = Set(doctors.map { $0.specialty.isEmpty ? AppStrings.Doctors.noSpecialty : $0.specialty })
        return Array(specialties).sorted()
    }
    
    // MARK: - Statistics
    func getDoctorStatistics() -> DoctorListStatistics {
        return DoctorListStatistics(
            totalDoctors: doctors.count,
            emergencyDoctors: getEmergencyDoctors().count,
            doctorsWithEmail: doctors.filter { doctor in
                if let email = doctor.email, !email.isEmpty {
                    return true
                }
                return false
            }.count,
            doctorsWithPhone: doctors.filter { doctor in
                if let phoneNumber = doctor.phoneNumber, !phoneNumber.isEmpty {
                    return true
                }
                return false
            }.count,
            doctorsFromContacts: doctors.filter { $0.isImportedFromContacts }.count,
            uniqueSpecialties: getUniqueSpecialties().count,
            recentlyAdded: getDoctorsByRecency().prefix(3).count
        )
    }
    
    func getSpecialtyDistribution() -> [(String, Int)] {
        let grouped = Dictionary(grouping: doctors) {
            $0.specialty.isEmpty ? AppStrings.Doctors.noSpecialty : $0.specialty
        }
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
    
    // MARK: - Contacts Integration
    func requestContactsPermission() async -> Bool {
        let store = CNContactStore()
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            self.error = AppError.data(.validationFailed)
            return false
        }
    }
    
    func importFromContacts() async -> [CNContact] {
        do {
            let hasPermission = await requestContactsPermission()
            guard hasPermission else {
                error = AppError.data(.validationFailed)
                return []
            }
            
            let store = CNContactStore()
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keys)
            
            var contacts: [CNContact] = []
            try store.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
            
            logger.info("Fetched \(contacts.count) contacts for import")
            return contacts
        } catch {
            self.error = error as? AppError ?? AppError.data(.loadFailed)
            logger.error("Failed to import contacts: \(error)")
            return []
        }
    }
    
    func searchContacts(query: String) async -> [CNContact] {
        do {
            let hasPermission = await requestContactsPermission()
            guard hasPermission else {
                error = AppError.data(.validationFailed)
                return []
            }
            
            let store = CNContactStore()
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let predicate = CNContact.predicateForContacts(matchingName: query)
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
            
            logger.info("Found \(contacts.count) contacts matching '\(query)'")
            return contacts
        } catch {
            self.error = error as? AppError ?? AppError.data(.loadFailed)
            logger.error("Failed to search contacts: \(error)")
            return []
        }
    }
    
    func exportDoctorToContacts(_ doctor: DoctorModel) async {
        do {
            let hasPermission = await requestContactsPermission()
            guard hasPermission else {
                error = AppError.data(.validationFailed)
                return
            }
            
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
            
            // Set organization
            contact.organizationName = doctor.specialty
            
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)
            try store.execute(saveRequest)
            
            analyticsManager.trackFeatureUsed("doctor_export_contacts")
            logger.info("Exported doctor to contacts: \(doctor.name)")
        } catch {
            self.error = AppError.data(.saveFailed)
            logger.error("Failed to export doctor to contacts: \(error)")
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
    
    func retryLastAction() async {
        await loadData()
    }
    
    // MARK: - Navigation Helpers
    func getDoctorsByRecency() -> [DoctorModel] {
        return doctors.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getDoctorsWithUpcomingAppointments() -> [DoctorModel] {
        // No appointment features planned
        return []
    }
    
    func getRecentlyContactedDoctors() -> [DoctorModel] {
        // Return recently added doctors as proxy for recent contact
        return Array(getDoctorsByRecency().prefix(3))
    }
    
    func getMostContactedDoctors() -> [DoctorModel] {
        // Return emergency doctors as they would be most contacted
        let emergency = getEmergencyDoctors()
        if emergency.count >= 3 {
            return Array(emergency.prefix(3))
        }
        
        // Fill with recent doctors if not enough emergency contacts
        let recent = getDoctorsByRecency().filter { doctor in
            !emergency.contains { $0.id == doctor.id }
        }
        return emergency + Array(recent.prefix(3 - emergency.count))
    }
    
    // MARK: - Helper Functions
    private func hasContactInfo(_ doctor: DoctorModel) -> Bool {
        let hasEmail = doctor.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasPhone = doctor.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        return hasEmail || hasPhone
    }
    
    private func displayName(_ doctor: DoctorModel) -> String {
        return doctor.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formattedPhoneNumber(_ doctor: DoctorModel) -> String? {
        guard let phone = doctor.phoneNumber else { return nil }
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if cleanPhone.count == 10 {
            let area = cleanPhone.prefix(3)
            let exchange = cleanPhone.dropFirst(3).prefix(3)
            let number = cleanPhone.suffix(4)
            return "(\(area)) \(exchange)-\(number)"
        } else if cleanPhone.count == 11 && cleanPhone.hasPrefix("1") {
            let area = cleanPhone.dropFirst().prefix(3)
            let exchange = cleanPhone.dropFirst(4).prefix(3)
            let number = cleanPhone.suffix(4)
            return "+1 (\(area)) \(exchange)-\(number)"
        }
        
        return phone
    }
    
    private func createDoctorFromContact(for userId: String, contact: CNContact, specialty: String) -> DoctorModel {
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        
        let address: DoctorAddress? = {
            guard let postalAddress = contact.postalAddresses.first?.value else {
                return nil
            }
            
            return DoctorAddress(
                street: postalAddress.street.isEmpty ? nil : postalAddress.street,
                city: postalAddress.city.isEmpty ? nil : postalAddress.city,
                state: postalAddress.state.isEmpty ? nil : postalAddress.state,
                zipCode: postalAddress.postalCode.isEmpty ? nil : postalAddress.postalCode,
                country: postalAddress.country.isEmpty ? "US" : postalAddress.country
            )
        }()
        
        return DoctorModel(
            userId: userId,
            name: fullName.isEmpty ? "Unknown Contact" : fullName,
            specialty: specialty.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: contact.phoneNumbers.first?.value.stringValue,
            email: contact.emailAddresses.first?.value as String?,
            address: address,
            notes: contact.organizationName.isEmpty ? nil : "Organization: \(contact.organizationName)",
            isImportedFromContacts: true,
            contactIdentifier: contact.identifier,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func isAddressEmpty(_ address: DoctorAddress) -> Bool {
        return address.street == nil && address.city == nil && address.state == nil && address.zipCode == nil
    }
    
    private func fullAddress(_ address: DoctorAddress) -> String {
        var components: [String] = []
        
        if let street = address.street, !street.isEmpty {
            components.append(street)
        }
        if let city = address.city, !city.isEmpty {
            components.append(city)
        }
        if let state = address.state, !state.isEmpty {
            components.append(state)
        }
        if let zipCode = address.zipCode, !zipCode.isEmpty {
            components.append(zipCode)
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Supporting Models
struct DoctorListStatistics {
    let totalDoctors: Int
    let emergencyDoctors: Int
    let doctorsWithEmail: Int
    let doctorsWithPhone: Int
    let doctorsFromContacts: Int
    let uniqueSpecialties: Int
    let recentlyAdded: Int
    
    var emergencyPercentage: Int {
        guard totalDoctors > 0 else { return 0 }
        return Int((Double(emergencyDoctors) / Double(totalDoctors)) * 100)
    }
    
    var contactsImportPercentage: Int {
        guard totalDoctors > 0 else { return 0 }
        return Int((Double(doctorsFromContacts) / Double(totalDoctors)) * 100)
    }
    
    var hasCompleteContactInfo: Int {
        return min(doctorsWithEmail, doctorsWithPhone)
    }
}

// MARK: - Sample Data Extension
#if DEBUG
extension DoctorListViewModel {
    static let sampleViewModel: DoctorListViewModel = {
        let viewModel = DoctorListViewModel()
        viewModel.doctors = DoctorModel.sampleDoctors
        return viewModel
    }()
}

extension DoctorListStatistics {
    static let sampleStatistics = DoctorListStatistics(
        totalDoctors: 8,
        emergencyDoctors: 2,
        doctorsWithEmail: 6,
        doctorsWithPhone: 8,
        doctorsFromContacts: 4,
        uniqueSpecialties: 5,
        recentlyAdded: 2
    )
}
#endif
