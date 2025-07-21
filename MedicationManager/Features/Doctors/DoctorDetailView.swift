import SwiftUI
import Observation

@MainActor
struct DoctorDetailView: View {
    let doctorId: String
    @State private var viewModel: DoctorDetailViewModel
    
    init(doctorId: String) {
        self.doctorId = doctorId
        self._viewModel = State(initialValue: DoctorDetailViewModel(doctorId: doctorId))
    }
    
    var body: some View {
        DoctorDetailContainer(viewModel: viewModel)
            .task {
                await viewModel.loadDoctor()
            }
    }
}

// MARK: - Container View
@MainActor
private struct DoctorDetailContainer: View {
    @Bindable var viewModel: DoctorDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            contentView
        }
        .navigationTitle(viewModel.doctor?.name ?? AppStrings.Common.loading)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingEditSheet) {
            if let doctor = viewModel.doctor {
                EditDoctorView(doctorId: doctor.id)
            }
        }
        .alert(AppStrings.Common.confirmDelete, isPresented: $showingDeleteAlert) {
            deleteAlertButtons
        } message: {
            Text(AppStrings.Doctors.deleteConfirmation)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            LoadingStateView()
        } else if let doctor = viewModel.doctor {
            DoctorDetailContent(
                doctor: doctor,
                prescribedMedications: viewModel.prescribedMedications,
                isLoadingMedications: viewModel.isLoadingMedications,
                onCall: { viewModel.callDoctor() },
                onEmail: { viewModel.emailDoctor() },
                onOpenAddress: { viewModel.openAddressInMaps() },
                onEdit: { showingEditSheet = true }
            )
        } else {
            DoctorNotFoundView()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label(AppStrings.Common.edit, systemImage: AppIcons.edit)
                }
                
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label(AppStrings.Common.delete, systemImage: AppIcons.delete)
                }
            } label: {
                Image(systemName: AppIcons.more)
            }
        }
    }
    
    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button(AppStrings.Common.cancel, role: .cancel) { }
        Button(AppStrings.Common.delete, role: .destructive) {
            Task {
                await viewModel.deleteDoctor()
                if viewModel.errorMessage == nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Content View
private struct DoctorDetailContent: View {
    let doctor: DoctorModel
    let prescribedMedications: [MedicationModel]
    let isLoadingMedications: Bool
    let onCall: () -> Void
    let onEmail: () -> Void
    let onOpenAddress: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            DoctorHeaderSection(doctor: doctor)
            DoctorContactSection(
                doctor: doctor,
                onCall: onCall,
                onEmail: onEmail
            )
            
            if let address = doctor.address {
                DoctorAddressSection(
                    address: address,
                    onTap: onOpenAddress
                )
            }
            
            if let notes = doctor.notes, !notes.isEmpty {
                DoctorNotesSection(notes: notes)
            }
            
            DoctorMedicationsSection(
                medications: prescribedMedications,
                isLoading: isLoadingMedications,
                doctorName: doctor.name
            )
            
            DoctorActionSection(
                doctor: doctor,
                onCall: onCall,
                onEdit: onEdit
            )
        }
        .padding(.horizontal)
        .padding(.bottom, AppTheme.Spacing.extraLarge)
    }
}

// MARK: - Header Section
private struct DoctorHeaderSection: View {
    let doctor: DoctorModel
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(doctor.name)
                        .font(AppTheme.Typography.title)
                    
                    Text(doctor.specialty)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: AppIcons.doctorEmpty)
                    .font(.system(size: AppTheme.IconSize.extraLarge))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            if doctor.isImportedFromContacts {
                ContactImportBadge()
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Contact Section
private struct DoctorContactSection: View {
    let doctor: DoctorModel
    let onCall: () -> Void
    let onEmail: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Doctors.contactInfo)
                .font(AppTheme.Typography.headline)
            
            VStack(spacing: AppTheme.Spacing.small) {
                if let phone = doctor.phoneNumber {
                    ContactInfoRow(
                        icon: AppIcons.phone,
                        text: phone,
                        action: onCall
                    )
                }
                
                if let email = doctor.email {
                    ContactInfoRow(
                        icon: AppIcons.email,
                        text: email,
                        action: onEmail
                    )
                }
                
                if doctor.phoneNumber == nil && doctor.email == nil {
                    NoContactInfoView()
                }
            }
        }
    }
}

// MARK: - Address Section
private struct DoctorAddressSection: View {
    let address: DoctorAddress
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Doctors.address)
                .font(AppTheme.Typography.headline)
            
            Button(action: onTap) {
                AddressCard(address: address)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Notes Section
private struct DoctorNotesSection: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Doctors.notes)
                .font(AppTheme.Typography.headline)
            
            Text(notes)
                .font(AppTheme.Typography.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
}

// MARK: - Medications Section
private struct DoctorMedicationsSection: View {
    let medications: [MedicationModel]
    let isLoading: Bool
    let doctorName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(AppStrings.Doctors.prescribedMedications)
                    .font(AppTheme.Typography.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(AppTheme.Animation.loadingScale)
                }
            }
            
            if medications.isEmpty {
                EmptyMedicationsView(doctorName: doctorName)
            } else {
                MedicationsList(medications: medications)
            }
        }
    }
}

// MARK: - Action Section
private struct DoctorActionSection: View {
    let doctor: DoctorModel
    let onCall: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if doctor.phoneNumber != nil {
                Button(action: onCall) {
                    HStack {
                        Image(systemName: AppIcons.phone)
                        Text(AppStrings.Common.call)
                    }
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Layout.buttonHeight)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
            
            Button(action: onEdit) {
                HStack {
                    Image(systemName: AppIcons.edit)
                    Text(AppStrings.Doctors.editDoctor)
                }
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Layout.buttonHeight)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
}

// MARK: - Supporting Components
private struct ContactInfoRow: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.primary)
                Text(text)
                    .font(AppTheme.Typography.body)
                Spacer()
                Image(systemName: AppIcons.chevronRight)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .padding()
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

private struct AddressCard: View {
    let address: DoctorAddress
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
            if let street = address.street {
                Text(street)
                    .font(AppTheme.Typography.body)
            }
            
            HStack(spacing: AppTheme.Spacing.small) {
                if let city = address.city {
                    Text(city)
                }
                if let state = address.state {
                    Text(state)
                }
                if let zip = address.zipCode {
                    Text(zip)
                }
            }
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

private struct MedicationsList: View {
    let medications: [MedicationModel]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(medications) { medication in
                NavigationLink(value: NavigationDestination.medicationDetail(id: medication.id)) {
                    MedicationRowView(medication: medication)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct MedicationRowView: View {
    let medication: MedicationModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(medication.name)
                    .font(AppTheme.Typography.body)
                Text(medication.dosage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            Spacer()
            Image(systemName: AppIcons.chevronRight)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .padding()
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Empty States
private struct LoadingStateView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, AppTheme.Spacing.xxxLarge)
    }
}

private struct DoctorNotFoundView: View {
    var body: some View {
        EmptyStateView(
            icon: AppIcons.doctorEmpty,
            title: AppStrings.Doctors.notFound,
            message: AppStrings.Doctors.notFoundDescription
        )
    }
}

private struct NoContactInfoView: View {
    var body: some View {
        Text(AppStrings.Doctors.noContactInfo)
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}

private struct EmptyMedicationsView: View {
    let doctorName: String
    
    var body: some View {
        Text(AppStrings.Doctors.noPrescribedMedications)
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}

private struct ContactImportBadge: View {
    var body: some View {
        HStack {
            Image(systemName: AppIcons.contactImported)
                .font(AppTheme.Typography.caption)
            Text(AppStrings.Doctors.importedFromContacts)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
            Spacer()
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class DoctorDetailViewModel {
    private let doctorId: String
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    private let analyticsManager = AnalyticsManager.shared
    
    var doctor: DoctorModel?
    var prescribedMedications: [MedicationModel] = []
    var isLoading = true
    var isLoadingMedications = false
    var errorMessage: String?
    @ObservationIgnored private var showingCallAlert = false
    
    init(doctorId: String) {
        self.doctorId = doctorId
    }
    
    func loadDoctor() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = firebaseManager.currentUser?.id else {
            errorMessage = AppStrings.Errors.userNotAuthenticated
            return
        }
        
        do {
            // Fetch all doctors and find the one with matching ID
            let allDoctors = try await coreDataManager.fetchDoctors(for: userId)
            doctor = allDoctors.first { $0.id == doctorId }
            
            if doctor == nil {
                errorMessage = AppStrings.Doctors.notFound
            } else {
                await loadPrescribedMedications()
            }
        } catch {
            errorMessage = error.localizedDescription
            analyticsManager.trackError(
                error,
                context: "DoctorDetailViewModel.loadDoctor"
            )
        }
    }
    
    private func loadPrescribedMedications() async {
        guard let doctor = doctor,
              let userId = firebaseManager.currentUser?.id else { return }
        
        isLoadingMedications = true
        defer { isLoadingMedications = false }
        
        do {
            let allMedications = try await coreDataManager.fetchMedications(for: userId)
            prescribedMedications = allMedications.filter { $0.prescribedBy == doctor.name }
        } catch {
            analyticsManager.trackError(
                error,
                context: "DoctorDetailViewModel.loadPrescribedMedications"
            )
        }
    }
    
    func deleteDoctor() async {
        do {
            // Since deleteDoctor is not implemented in CoreDataManager,
            // we'll use the save method with isDeleted flag pattern
            if var doctorToDelete = doctor {
                doctorToDelete.isDeletedFlag = true
                doctorToDelete.markForSync()
                try await coreDataManager.saveDoctor(doctorToDelete)
            }
            
            analyticsManager.trackEvent(
                "doctor_deleted",
                parameters: ["doctor_id": doctorId]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func callDoctor() {
        guard let phone = doctor?.phoneNumber else { return }
        
        let cleanedNumber = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(cleanedNumber)") {
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
            
            analyticsManager.trackEvent(
                "doctor_called",
                parameters: ["doctor_id": doctorId]
            )
        }
    }
    
    func emailDoctor() {
        guard let email = doctor?.email else { return }
        
        if let url = URL(string: "mailto:\(email)") {
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
            
            analyticsManager.trackEvent(
                "doctor_emailed",
                parameters: ["doctor_id": doctorId]
            )
        }
    }
    
    func openAddressInMaps() {
        guard let address = doctor?.address else { return }
        
        let addressString = [
            address.street,
            address.city,
            address.state,
            address.zipCode
        ].compactMap { $0 }.joined(separator: ", ")
        
        let escapedAddress = addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "maps://?address=\(escapedAddress)") {
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
            
            analyticsManager.trackEvent(
                "doctor_address_opened_in_maps",
                parameters: ["doctor_id": doctorId]
            )
        }
    }
}

#Preview {
    NavigationStack {
        DoctorDetailView(doctorId: "preview-id")
    }
}