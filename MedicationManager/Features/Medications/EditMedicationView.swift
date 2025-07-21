import SwiftUI
import Observation

@MainActor
struct EditMedicationView: View {
    let medicationId: String
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = EditMedicationViewModel()
    
    // Form state
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var selectedFrequency: MedicationFrequency = .once
    @State private var prescribedBy = ""
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var isActive = true
    
    // UI state
    @State private var showingError = false
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView(AppStrings.Common.loading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Form {
                        medicationDetailsSection
                        scheduleSection
                        additionalInfoSection
                        statusSection
                        deleteSection
                    }
                }
            }
            .navigationTitle(AppStrings.Actions.editMedication)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.save) {
                        saveMedication()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .alert(AppStrings.Common.error, isPresented: $showingError) {
                Button(AppStrings.Common.ok) { }
            } message: {
                Text(viewModel.errorMessage ?? AppStrings.Common.error)
            }
            .confirmationDialog(
                AppStrings.Common.delete,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(AppStrings.Common.delete, role: .destructive) {
                    deleteMedication()
                }
                Button(AppStrings.Common.cancel, role: .cancel) { }
            } message: {
                Text(NSLocalizedString("medication.deleteConfirmation", value: "Are you sure you want to delete this medication? This action cannot be undone.", comment: "Delete medication confirmation"))
            }
            .task {
                await loadMedication()
            }
        }
    }
    
    // MARK: - Sections
    
    private var medicationDetailsSection: some View {
        SwiftUI.Section {
            // Medication Name with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Common.name)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $medicationName,
                    placeholder: AppStrings.Medications.medications,
                    voiceContext: .medicationName,
                    onSubmit: {
                        // Submit action if needed
                    }
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // Dosage with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Medications.dosage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $dosage,
                    placeholder: AppStrings.Common.dosageHint,
                    voiceContext: .dosage,
                    onSubmit: {
                        // Submit action if needed
                    }
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // Frequency Picker
            Picker(AppStrings.Medications.frequency, selection: $selectedFrequency) {
                ForEach(MedicationFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text(AppStrings.Common.details)
        }
    }
    
    private var scheduleSection: some View {
        SwiftUI.Section {
            DatePicker(
                AppStrings.Common.startDate,
                selection: $startDate,
                displayedComponents: .date
            )
            
            Toggle(AppStrings.Common.hasEndDate, isOn: $hasEndDate)
            
            if hasEndDate {
                DatePicker(
                    AppStrings.Common.endDate,
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: .date
                )
            }
        } header: {
            Text(AppStrings.Medications.schedule)
        }
    }
    
    private var additionalInfoSection: some View {
        SwiftUI.Section {
            // Prescribed By with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Common.prescribedBy)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $prescribedBy,
                    placeholder: AppStrings.Common.doctorName,
                    voiceContext: .doctorName,
                    onSubmit: {
                        // Submit action if needed
                    }
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // Notes with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Medications.notes)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $notes,
                    placeholder: AppStrings.Common.optional,
                    voiceContext: .notes,
                    onSubmit: {
                        // Submit action if needed
                    }
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(AppStrings.Common.additionalInfo)
        }
    }
    
    private var statusSection: some View {
        SwiftUI.Section {
            Toggle(NSLocalizedString("medication.isActive", value: "Active", comment: "Active medication toggle"), isOn: $isActive)
        } header: {
            Text(NSLocalizedString("medication.status", value: "Status", comment: "Status section header"))
        } footer: {
            Text(NSLocalizedString("medication.statusFooter", value: "Inactive medications won't appear in your daily schedule", comment: "Status section footer"))
        }
    }
    
    private var deleteSection: some View {
        SwiftUI.Section {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text(AppStrings.Common.delete)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadMedication() async {
        isLoading = true
        defer { isLoading = false }
        
        await viewModel.loadMedication(id: medicationId)
        
        if let medication = viewModel.medication {
            medicationName = medication.name
            dosage = medication.dosage
            selectedFrequency = medication.frequency
            prescribedBy = medication.prescribedBy ?? ""
            notes = medication.notes ?? ""
            startDate = medication.startDate
            hasEndDate = medication.endDate != nil
            endDate = medication.endDate ?? Date()
            isActive = medication.isActive
        } else if viewModel.errorMessage != nil {
            showingError = true
        }
    }
    
    private func saveMedication() {
        Task {
            await viewModel.updateMedication(
                name: medicationName.trimmingCharacters(in: .whitespacesAndNewlines),
                dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
                frequency: selectedFrequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                prescribedBy: prescribedBy.isEmpty ? nil : prescribedBy.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isActive: isActive
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
    
    private func deleteMedication() {
        Task {
            await viewModel.deleteMedication()
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class EditMedicationViewModel {
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    var medication: MedicationModel?
    var errorMessage: String?
    
    func loadMedication(id: String) async {
        do {
            guard let userId = firebaseManager.currentUser?.id else {
                errorMessage = AppStrings.Errors.authenticationRequired
                return
            }
            
            let medications = try await coreDataManager.fetchMedications(for: userId)
            medication = medications.first { $0.id == id }
            
            if medication == nil {
                errorMessage = NSLocalizedString("medication.notFound", value: "Medication not found", comment: "Medication not found error")
            }
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                error,
                context: "EditMedicationViewModel.loadMedication"
            )
        }
    }
    
    func updateMedication(
        name: String,
        dosage: String,
        frequency: MedicationFrequency,
        startDate: Date,
        endDate: Date?,
        prescribedBy: String?,
        notes: String?,
        isActive: Bool
    ) async {
        guard var medication = medication else {
            errorMessage = NSLocalizedString("medication.notFound", value: "Medication not found", comment: "Medication not found error")
            return
        }
        
        // Update medication properties
        medication.name = name
        medication.dosage = dosage
        medication.frequency = frequency
        medication.startDate = startDate
        medication.endDate = endDate
        medication.prescribedBy = prescribedBy
        medication.notes = notes
        medication.isActive = isActive
        medication.updatedAt = Date()
        medication.markForSync()
        
        do {
            try await coreDataManager.saveMedication(medication)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "medication_updated",
                parameters: ["medicationId": medication.id]
            )
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                error,
                context: "EditMedicationViewModel.updateMedication"
            )
        }
    }
    
    func deleteMedication() async {
        guard let medication = medication else {
            errorMessage = NSLocalizedString("medication.notFound", value: "Medication not found", comment: "Medication not found error")
            return
        }
        
        do {
            try await coreDataManager.deleteMedication(medication.id)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "medication_deleted",
                parameters: ["medicationId": medication.id]
            )
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                error,
                context: "EditMedicationViewModel.deleteMedication"
            )
        }
    }
}

#Preview {
    EditMedicationView(medicationId: "preview-id")
}