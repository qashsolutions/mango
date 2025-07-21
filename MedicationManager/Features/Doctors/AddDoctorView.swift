import SwiftUI
import Contacts
import ContactsUI
import Observation

@MainActor
struct AddDoctorView: View {
    let initialContact: Contact?
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddDoctorViewModel()
    
    // Form state
    @State private var doctorName = ""
    @State private var selectedSpecialty: DoctorModel.CommonSpecialty = .primaryCare
    @State private var customSpecialty = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var notes = ""
    
    // Address
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    
    // UI state
    @State private var showingError = false
    @State private var showingContactPicker = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                doctorDetailsSection
                contactInfoSection
                addressSection
                notesSection
            }
            .navigationTitle(AppStrings.Actions.addDoctor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.save) {
                        saveDoctor()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(AppStrings.Common.error, isPresented: $showingError) {
                Button(AppStrings.Common.ok) { }
            } message: {
                Text(viewModel.errorMessage ?? AppStrings.Common.error)
            }
            .alert(NSLocalizedString("contacts.permissionRequired", value: "Contacts Access Required", comment: "Contacts permission alert title"), isPresented: $showingPermissionAlert) {
                Button(AppStrings.Common.settings) {
                    openSettings()
                }
                Button(AppStrings.Common.cancel, role: .cancel) { }
            } message: {
                Text(NSLocalizedString("contacts.permissionMessage", value: "Please allow access to your contacts to import doctor information.", comment: "Contacts permission message"))
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { contact in
                    fillFromContact(contact)
                }
            }
            .onAppear {
                setupInitialData()
                AnalyticsManager.shared.trackScreenViewed("add_doctor")
                
                // App Intents are automatically available - no authorization needed
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    // Add to Siri button
                    Button {
                        addToSiri()
                    } label: {
                        Label(AppStrings.Siri.addToSiri, systemImage: "mic.badge.plus")
                            .font(AppTheme.Typography.caption)
                    }
                    .tint(AppTheme.Colors.primary)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var doctorDetailsSection: some View {
        Section {
            // Doctor Name with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Text(AppStrings.Common.name)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Spacer()
                    
                    Button(NSLocalizedString("contacts.importFromContacts", value: "Import from Contacts", comment: "Import from contacts button")) {
                        checkContactsPermission()
                    }
                    .font(AppTheme.Typography.caption)
                }
                
                VoiceFirstInputView(
                    text: $doctorName,
                    placeholder: AppStrings.Common.doctorName,
                    voiceContext: .doctorName,
                    onSubmit: {}
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // Specialty Picker
            Picker(AppStrings.Doctors.specialty, selection: $selectedSpecialty) {
                ForEach(DoctorModel.CommonSpecialty.sortedCases, id: \.self) { specialty in
                    Text(specialty.localizedName).tag(specialty)
                }
            }
            .pickerStyle(.menu)
            
            // Custom Specialty (if Other is selected)
            if selectedSpecialty == .other {
                VoiceFirstInputView(
                    text: $customSpecialty,
                    placeholder: NSLocalizedString("doctors.enterSpecialty", value: "Enter specialty", comment: "Enter specialty placeholder"),
                    voiceContext: .general,
                    onSubmit: {}
                )
                .padding(.vertical, AppTheme.Spacing.extraSmall)
            }
        } header: {
            Text(AppStrings.Common.details)
        }
    }
    
    private var contactInfoSection: some View {
        Section {
            // Phone Number
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Doctors.phone)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(
                    AppStrings.Doctors.phoneFormat
                        .replacingOccurrences(of: "{area}", with: "555")
                        .replacingOccurrences(of: "{exchange}", with: "555")
                        .replacingOccurrences(of: "{number}", with: "5555"),
                    text: $phoneNumber
                )
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // Email
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Doctors.email)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(AppStrings.Doctors.emailPlaceholder, text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(NSLocalizedString("doctors.contactInfo", value: "Contact Information", comment: "Contact info section header"))
        } footer: {
            Text(AppStrings.Common.optional)
                .font(AppTheme.Typography.caption2)
        }
    }
    
    private var addressSection: some View {
        Section {
            // Street
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("doctors.street", value: "Street", comment: "Street label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(NSLocalizedString("doctors.streetPlaceholder", value: "123 Main St", comment: "Street placeholder"), text: $street)
                    .textContentType(.streetAddressLine1)
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // City
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("doctors.city", value: "City", comment: "City label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(NSLocalizedString("doctors.cityPlaceholder", value: "City", comment: "City placeholder"), text: $city)
                    .textContentType(.addressCity)
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // State and Zip in HStack
            HStack(spacing: AppTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(NSLocalizedString("doctors.state", value: "State", comment: "State label"))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    TextField(NSLocalizedString("doctors.statePlaceholder", value: "State", comment: "State placeholder"), text: $state)
                        .textContentType(.addressState)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(NSLocalizedString("doctors.zipCode", value: "Zip Code", comment: "Zip code label"))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    TextField(NSLocalizedString("doctors.zipPlaceholder", value: "12345", comment: "Zip placeholder"), text: $zipCode)
                        .textContentType(.postalCode)
                        .keyboardType(.numberPad)
                }
                .frame(maxWidth: 120)
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(AppStrings.Doctors.address)
        } footer: {
            Text(AppStrings.Common.optional)
                .font(AppTheme.Typography.caption2)
        }
    }
    
    private var notesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Doctors.notes)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $notes,
                    placeholder: NSLocalizedString("doctors.notesPlaceholder", value: "Additional notes", comment: "Notes placeholder"),
                    voiceContext: VoiceInteractionContext.notes,
                    onSubmit: {}
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(AppStrings.Common.additionalInfo)
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        let nameValid = !doctorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let specialtyValid = selectedSpecialty != .other || !customSpecialty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return nameValid && specialtyValid
    }
    
    private func setupInitialData() {
        if let contact = initialContact {
            doctorName = contact.name
            phoneNumber = contact.phoneNumbers.first ?? ""
            email = contact.emailAddresses.first ?? ""
        }
    }
    
    private func checkContactsPermission() {
        Task {
            let authorized = await viewModel.checkContactsPermission()
            if authorized {
                showingContactPicker = true
            } else {
                showingPermissionAlert = true
            }
        }
    }
    
    private func fillFromContact(_ contact: CNContact) {
        doctorName = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
        
        if let phone = contact.phoneNumbers.first {
            phoneNumber = phone.value.stringValue
        }
        
        if let emailAddress = contact.emailAddresses.first {
            email = emailAddress.value as String
        }
        
        if let postalAddress = contact.postalAddresses.first?.value {
            street = postalAddress.street
            city = postalAddress.city
            state = postalAddress.state
            zipCode = postalAddress.postalCode
        }
    }
    
    private func saveDoctor() {
        let address = DoctorAddress(
            street: street.isEmpty ? nil : street.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.isEmpty ? nil : city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: state.isEmpty ? nil : state.trimmingCharacters(in: .whitespacesAndNewlines),
            zipCode: zipCode.isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        let specialty = selectedSpecialty == .other ? customSpecialty : selectedSpecialty.localizedName
        
        Task {
            await viewModel.saveDoctor(
                name: doctorName.trimmingCharacters(in: .whitespacesAndNewlines),
                specialty: specialty.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address.isEmpty ? nil : address,
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isImportedFromContacts: initialContact != nil,
                contactIdentifier: nil
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func addToSiri() {
        // Show Siri tips for viewing doctors
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            SiriTipPresenter.showTip(for: .viewDoctors, in: window)
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class AddDoctorViewModel {
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    var errorMessage: String?
    
    func checkContactsPermission() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            do {
                // Create a new instance to avoid data races
                let contactStore = CNContactStore()
                try await contactStore.requestAccess(for: .contacts)
                return true
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        case .denied:
            errorMessage = AppStrings.ErrorMessages.permissionDenied
            return false
        case .restricted:
            errorMessage = AppStrings.ErrorMessages.permissionDenied
            return false
        case .limited:
            // Limited access still allows basic functionality
            return true
        @unknown default:
            errorMessage = AppStrings.ErrorMessages.genericError
            return false
        }
    }
    
    func saveDoctor(
        name: String,
        specialty: String,
        phoneNumber: String?,
        email: String?,
        address: DoctorAddress?,
        notes: String?,
        isImportedFromContacts: Bool,
        contactIdentifier: String?
    ) async {
        guard let userId = firebaseManager.currentUser?.id else {
            errorMessage = AppStrings.Errors.authenticationRequired
            return
        }
        
        let doctor = DoctorModel.create(
            for: userId,
            name: name,
            specialty: specialty,
            phoneNumber: phoneNumber,
            email: email,
            address: address,
            notes: notes,
            voiceEntryUsed: false
        )
        
        do {
            try await coreDataManager.saveDoctor(doctor)
            
            // Track analytics
            AnalyticsManager.shared.trackDoctorAdded(
                method: "manual",
                fromContacts: isImportedFromContacts
            )
        } catch {
            errorMessage = error.localizedDescription
            let appError = error as? AppError ?? AppError.data(.saveFailed)
            AnalyticsManager.shared.trackError(
                appError,
                context: "AddDoctorViewModel.saveDoctor"
            )
        }
    }
}

// MARK: - Contact Picker View
struct ContactPickerView: UIViewControllerRepresentable {
    let onContactSelected: (CNContact) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0 OR emailAddresses.@count > 0")
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey
        ]
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onContactSelected: onContactSelected,
            dismissPicker: {
                Task { @MainActor in
                    dismiss()
                }
            }
        )
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (CNContact) -> Void
        let dismissPicker: () -> Void
        
        init(onContactSelected: @escaping (CNContact) -> Void, dismissPicker: @escaping () -> Void) {
            self.onContactSelected = onContactSelected
            self.dismissPicker = dismissPicker
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onContactSelected(contact)
            dismissPicker()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            dismissPicker()
        }
    }
}

#Preview {
    AddDoctorView(initialContact: nil)
}
