import SwiftUI
import Observation

@MainActor
struct EditDoctorView: View {
    let doctorId: String
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditDoctorViewModel
    
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
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    init(doctorId: String) {
        self.doctorId = doctorId
        self._viewModel = State(initialValue: EditDoctorViewModel(doctorId: doctorId))
    }
    
    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    doctorDetailsSection
                    contactInfoSection
                    addressSection
                    notesSection
                    deleteSection
                }
                .navigationTitle(AppStrings.Actions.editDoctor)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(AppStrings.Common.cancel) {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(AppStrings.Common.save) {
                            saveChanges()
                        }
                        .disabled(!isFormValid || !hasChanges)
                    }
                }
                .alert(AppStrings.Common.error, isPresented: $showingError) {
                    Button(AppStrings.Common.ok) { }
                } message: {
                    Text(viewModel.errorMessage ?? AppStrings.Common.error)
                }
                .alert(AppStrings.Common.confirmDelete, isPresented: $showingDeleteAlert) {
                    Button(AppStrings.Common.cancel, role: .cancel) { }
                    Button(AppStrings.Common.delete, role: .destructive) {
                        deleteDoctor()
                    }
                } message: {
                    Text(NSLocalizedString("doctor.edit.deleteConfirmation", value: "Are you sure you want to delete this doctor? This action cannot be undone.", comment: "Delete doctor confirmation"))
                }
                .onAppear {
                    loadDoctorData()
                    AnalyticsManager.shared.trackScreenViewed("edit_doctor")
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var doctorDetailsSection: some View {
        Section {
            // Doctor Name with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Common.name)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
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
                    voiceContext: .notes,
                    onSubmit: {}
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(AppStrings.Common.additionalInfo)
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(AppStrings.Actions.editDoctor)
                    }
                    Spacer()
                }
            }
            .disabled(isDeleting)
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        let nameValid = !doctorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let specialtyValid = selectedSpecialty != .other || !customSpecialty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return nameValid && specialtyValid
    }
    
    private var hasChanges: Bool {
        guard let originalDoctor = viewModel.originalDoctor else { return false }
        
        let currentSpecialty = selectedSpecialty == .other ? customSpecialty : selectedSpecialty.localizedName
        
        return doctorName != originalDoctor.name ||
               currentSpecialty != originalDoctor.specialty ||
               phoneNumber != (originalDoctor.phoneNumber ?? "") ||
               email != (originalDoctor.email ?? "") ||
               street != (originalDoctor.address?.street ?? "") ||
               city != (originalDoctor.address?.city ?? "") ||
               state != (originalDoctor.address?.state ?? "") ||
               zipCode != (originalDoctor.address?.zipCode ?? "") ||
               notes != (originalDoctor.notes ?? "")
    }
    
    private func loadDoctorData() {
        Task {
            await viewModel.loadDoctor()
            
            if let doctor = viewModel.originalDoctor {
                doctorName = doctor.name
                
                // Set specialty
                if let commonSpecialty = DoctorModel.CommonSpecialty.allCases.first(where: { $0.localizedName == doctor.specialty }) {
                    selectedSpecialty = commonSpecialty
                } else {
                    selectedSpecialty = .other
                    customSpecialty = doctor.specialty
                }
                
                phoneNumber = doctor.phoneNumber ?? ""
                email = doctor.email ?? ""
                
                if let address = doctor.address {
                    street = address.street ?? ""
                    city = address.city ?? ""
                    state = address.state ?? ""
                    zipCode = address.zipCode ?? ""
                }
                
                notes = doctor.notes ?? ""
            } else {
                showingError = true
            }
        }
    }
    
    private func saveChanges() {
        let address = DoctorAddress(
            street: street.isEmpty ? nil : street.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.isEmpty ? nil : city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: state.isEmpty ? nil : state.trimmingCharacters(in: .whitespacesAndNewlines),
            zipCode: zipCode.isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        let specialty = selectedSpecialty == .other ? customSpecialty : selectedSpecialty.localizedName
        
        Task {
            await viewModel.updateDoctor(
                name: doctorName.trimmingCharacters(in: .whitespacesAndNewlines),
                specialty: specialty.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address.isEmpty ? nil : address,
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
    
    private func deleteDoctor() {
        isDeleting = true
        
        Task {
            await viewModel.deleteDoctor()
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
                isDeleting = false
            }
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class EditDoctorViewModel {
    private let doctorId: String
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    var originalDoctor: DoctorModel?
    var isLoading = true
    var errorMessage: String?
    
    init(doctorId: String) {
        self.doctorId = doctorId
    }
    
    func loadDoctor() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get current user ID
            guard let userId = firebaseManager.currentUser?.id else {
                errorMessage = AppStrings.ErrorMessages.userNotFound
                return
            }
            
            // Fetch all doctors and find the one we need
            let doctors = try await coreDataManager.fetchDoctors(for: userId)
            originalDoctor = doctors.first { $0.id == doctorId }
            
            if originalDoctor == nil {
                errorMessage = AppStrings.ErrorMessages.genericError
            }
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                AppError.data(.loadFailed),
                context: "EditDoctorViewModel.loadDoctor"
            )
        }
    }
    
    func updateDoctor(
        name: String,
        specialty: String,
        phoneNumber: String?,
        email: String?,
        address: DoctorAddress?,
        notes: String?
    ) async {
        guard var doctor = originalDoctor else {
            errorMessage = AppStrings.ErrorMessages.genericError
            return
        }
        
        // Update doctor properties
        doctor.name = name
        doctor.specialty = specialty
        doctor.phoneNumber = phoneNumber
        doctor.email = email
        doctor.address = address
        doctor.notes = notes
        doctor.updatedAt = Date()
        
        do {
            try await coreDataManager.saveDoctor(doctor)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "doctor_updated",
                parameters: ["doctor_id": doctorId]
            )
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                AppError.data(.saveFailed),
                context: "EditDoctorViewModel.updateDoctor"
            )
        }
    }
    
    func deleteDoctor() async {
        guard var doctor = originalDoctor else {
            errorMessage = AppStrings.ErrorMessages.genericError
            return
        }
        
        // Soft delete by setting flag
        doctor.isDeletedFlag = true
        doctor.updatedAt = Date()
        
        do {
            try await coreDataManager.saveDoctor(doctor)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "doctor_deleted",
                parameters: ["doctor_id": doctorId]
            )
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                AppError.data(.saveFailed),
                context: "EditDoctorViewModel.deleteDoctor"
            )
        }
    }
}

#Preview {
    EditDoctorView(doctorId: "preview-id")
}
