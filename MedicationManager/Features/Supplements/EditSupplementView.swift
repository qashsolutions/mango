import SwiftUI
import Observation

@MainActor
struct EditSupplementView: View {
    let supplementId: String
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditSupplementViewModel
    
    // Constants to resolve ambiguity
    private let detailsHeaderText = AppStrings.Common.details
    private let optionalPlaceholderText = AppStrings.Common.optional
    
    // Form state
    @State private var supplementName = ""
    @State private var dosage = ""
    @State private var selectedFrequency: SupplementFrequency = .daily
    @State private var purpose = ""
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var isTakenWithFood = false
    @State private var isActive = true
    
    // UI state
    @State private var showingError = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    init(supplementId: String) {
        self.supplementId = supplementId
        self._viewModel = State(initialValue: EditSupplementViewModel(supplementId: supplementId))
    }
    
    var body: some View {
        NavigationStack {
            formBasedOnLoadingState
        }
    }
    
    @ViewBuilder
    private var formBasedOnLoadingState: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Form {
                supplementDetailsSection
                scheduleSection
                additionalInfoSection
                statusSection
                deleteSection
            }
            .configureEditSupplementForm(
                viewModel: viewModel,
                showingError: $showingError,
                showingDeleteAlert: $showingDeleteAlert,
                errorMessage: viewModel.errorMessage,
                isFormValid: isFormValid,
                hasChanges: hasChanges,
                onCancel: { dismiss() },
                onSave: { saveChanges() },
                onDelete: { deleteSupplement() },
                onAppear: {
                    loadSupplementData()
                    AnalyticsManager.shared.trackScreenViewed("edit_supplement")
                }
            )
        }
    }
    
    // MARK: - Sections
    
    private var supplementDetailsSection: some View {
        Section {
            // Supplement Name with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Common.name)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $supplementName,
                    placeholder: NSLocalizedString("supplements.namePlaceholder", value: "Vitamin D, Omega-3, etc.", comment: "Supplement name placeholder"),
                    voiceContext: .supplementName,
                    onSubmit: { }
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
                    onSubmit: { }
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // Frequency Picker
            Picker(AppStrings.Medications.frequency, selection: $selectedFrequency) {
                ForEach(SupplementFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            .pickerStyle(.menu)
            
            // Take with food toggle
            Toggle(NSLocalizedString("supplements.takeWithFood", value: "Take with food", comment: "Take with food toggle"), isOn: $isTakenWithFood)
        } header: {
            Text(detailsHeaderText)
        }
    }
    
    private var scheduleSection: some View {
        Section {
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
    
    @ViewBuilder
    private var additionalInfoSection: some View {
        Section {
            // Purpose with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("supplements.purpose", value: "Purpose", comment: "Purpose label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $purpose,
                    placeholder: NSLocalizedString("supplements.purposePlaceholder", value: "Immune support, bone health, etc.", comment: "Purpose placeholder"),
                    voiceContext: .general,
                    onSubmit: { }
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
                    placeholder: optionalPlaceholderText,
                    voiceContext: .notes,
                    onSubmit: { }
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(AppStrings.Common.additionalInfo)
        }
    }
    
    private var statusSection: some View {
        Section {
            Toggle(isOn: $isActive) {
                VStack(alignment: .leading) {
                    Text(AppStrings.Common.active)
                        .font(AppTheme.Typography.body)
                    Text(NSLocalizedString("supplement.edit.activeDescription", value: "Toggle to temporarily stop tracking this supplement", comment: "Active toggle description"))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        } header: {
            Text(AppStrings.Common.status)
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
                        Text(NSLocalizedString("supplement.delete", value: "Delete Supplement", comment: "Delete supplement button"))
                    }
                    Spacer()
                }
            }
            .disabled(isDeleting)
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !supplementName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasChanges: Bool {
        guard let original = viewModel.originalSupplement else { return false }
        
        return supplementName != original.name ||
               dosage != original.dosage ||
               selectedFrequency != original.frequency ||
               purpose != (original.purpose ?? "") ||
               notes != (original.notes ?? "") ||
               startDate != original.startDate ||
               (hasEndDate ? endDate : nil) != original.endDate ||
               isTakenWithFood != original.isTakenWithFood ||
               isActive != original.isActive
    }
    
    private func loadSupplementData() {
        Task {
            await viewModel.loadSupplement()
            
            if let supplement = viewModel.originalSupplement {
                supplementName = supplement.name
                dosage = supplement.dosage
                selectedFrequency = supplement.frequency
                purpose = supplement.purpose ?? ""
                notes = supplement.notes ?? ""
                startDate = supplement.startDate
                hasEndDate = supplement.endDate != nil
                if let endDate = supplement.endDate {
                    self.endDate = endDate
                }
                isTakenWithFood = supplement.isTakenWithFood
                isActive = supplement.isActive
            } else {
                showingError = true
            }
        }
    }
    
    private func saveChanges() {
        Task {
            await viewModel.updateSupplement(
                name: supplementName.trimmingCharacters(in: .whitespacesAndNewlines),
                dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
                frequency: selectedFrequency,
                purpose: purpose.isEmpty ? nil : purpose.trimmingCharacters(in: .whitespacesAndNewlines),
                isTakenWithFood: isTakenWithFood,
                isActive: isActive,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
    
    private func deleteSupplement() {
        isDeleting = true
        
        Task {
            await viewModel.deleteSupplement()
            
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
final class EditSupplementViewModel {
    private let supplementId: String
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    var originalSupplement: SupplementModel?
    var isLoading = true
    var errorMessage: String?
    
    init(supplementId: String) {
        self.supplementId = supplementId
    }
    
    func loadSupplement() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let supplements = try await coreDataManager.fetchSupplements(for: firebaseManager.currentUser?.id ?? "")
            originalSupplement = supplements.first { $0.id == supplementId }
            if originalSupplement == nil {
                errorMessage = AppStrings.Errors.genericErrorMessage
            }
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                AppError.data(.loadFailed),
                context: "EditSupplementViewModel.loadSupplement"
            )
        }
    }
    
    func updateSupplement(
        name: String,
        dosage: String,
        frequency: SupplementFrequency,
        purpose: String?,
        isTakenWithFood: Bool,
        isActive: Bool,
        startDate: Date,
        endDate: Date?,
        notes: String?
    ) async {
        guard var supplement = originalSupplement else {
            errorMessage = AppStrings.Errors.genericErrorMessage
            return
        }
        
        // Update supplement properties
        supplement.name = name
        supplement.dosage = dosage
        supplement.frequency = frequency
        supplement.purpose = purpose
        supplement.isTakenWithFood = isTakenWithFood
        supplement.isActive = isActive
        supplement.startDate = startDate
        supplement.endDate = endDate
        supplement.notes = notes
        supplement.updatedAt = Date()
        
        do {
            try await coreDataManager.saveSupplement(supplement)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "supplement_updated",
                parameters: [
                    "supplement_id": supplementId,
                    "status_changed": originalSupplement?.isActive != isActive
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                AppError.data(.saveFailed),
                context: "EditSupplementViewModel.updateSupplement"
            )
        }
    }
    
    func deleteSupplement() async {
        guard let userId = firebaseManager.currentUser?.id else {
            errorMessage = AppStrings.Errors.authenticationRequired
            return
        }
        
        do {
            // Fetch all supplements and find the one to delete
            let supplements = try await coreDataManager.fetchSupplements(for: userId)
            guard var supplementToDelete = supplements.first(where: { $0.id == supplementId }) else {
                errorMessage = AppStrings.Errors.genericErrorMessage
                return
            }
            
            // Mark as deleted and save
            supplementToDelete.isDeletedFlag = true
            supplementToDelete.updatedAt = Date()
            supplementToDelete.needsSync = true
            
            try await coreDataManager.saveSupplement(supplementToDelete)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "supplement_deleted",
                parameters: ["supplement_id": supplementId]
            )
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                AppError.data(.saveFailed),
                context: "EditSupplementViewModel.deleteSupplement"
            )
        }
    }
}

// MARK: - View Extension for Form Configuration
extension View {
    func configureEditSupplementForm(
        viewModel: EditSupplementViewModel,
        showingError: Binding<Bool>,
        showingDeleteAlert: Binding<Bool>,
        errorMessage: String?,
        isFormValid: Bool,
        hasChanges: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onAppear: @escaping () -> Void
    ) -> some View {
        self
            .navigationTitle(AppStrings.Actions.editSupplement)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(AppStrings.Common.cancel) {
                    onCancel()
                },
                trailing: Button(AppStrings.Common.save) {
                    onSave()
                }
                .disabled(!isFormValid || !hasChanges)
            )
            .alert(AppStrings.Common.error, isPresented: showingError) {
                Button(AppStrings.Common.ok) { }
            } message: {
                Text(errorMessage ?? AppStrings.Common.error)
            }
            .alert(AppStrings.Common.confirmDelete, isPresented: showingDeleteAlert) {
                Button(AppStrings.Common.cancel, role: .cancel) { }
                Button(AppStrings.Common.delete, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text(NSLocalizedString("supplement.edit.deleteConfirmation", value: "Are you sure you want to delete this supplement? This action cannot be undone.", comment: "Delete supplement confirmation"))
            }
            .onAppear(perform: onAppear)
    }
}

#Preview {
    EditSupplementView(supplementId: "preview-id")
}
