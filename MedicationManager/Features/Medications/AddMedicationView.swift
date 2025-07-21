import SwiftUI
import Observation

@MainActor
struct AddMedicationView: View {
    let initialVoiceText: String?
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddMedicationViewModel()
    
    // Form state
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var selectedFrequency: MedicationFrequency = .once
    @State private var prescribedBy = ""
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    
    // UI state
    @State private var showingError = false
    @State private var showingSuccessMessage = false
    @State private var showingConflictCheck = false
    
    var body: some View {
        NavigationStack {
            Form {
                medicationDetailsSection
                scheduleSection
                additionalInfoSection
                conflictCheckSection
            }
            .navigationTitle(AppStrings.Medications.addMedication)
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
                    .disabled(!isFormValid)
                }
            }
            .alert(AppStrings.Common.error, isPresented: $showingError) {
                Button(AppStrings.Common.ok) { }
            } message: {
                Text(viewModel.errorMessage ?? AppStrings.Common.error)
            }
            .onAppear {
                setupInitialData()
                AnalyticsManager.shared.trackScreenViewed("add_medication")
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
    
    private var medicationDetailsSection: some View {
        Section {
            // Medication Name with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Common.name)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $medicationName,
                    placeholder: AppStrings.Medications.medications,
                    voiceContext: .medicationName,
                    onSubmit: {}
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
                    onSubmit: {}
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
    
    private var additionalInfoSection: some View {
        Section {
            // Prescribed By with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Common.prescribedBy)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $prescribedBy,
                    placeholder: AppStrings.Common.doctorName,
                    voiceContext: .doctorName,
                    onSubmit: {}
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
                    onSubmit: {}
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(AppStrings.Common.additionalInfo)
        }
    }
    
    private var conflictCheckSection: some View {
        Section {
            Button(action: checkConflicts) {
                HStack {
                    Image(systemName: AppIcons.warning)
                        .foregroundColor(AppTheme.Colors.warning)
                    Text(AppStrings.Actions.checkConflicts)
                    Spacer()
                    if viewModel.isCheckingConflicts {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(medicationName.isEmpty || viewModel.isCheckingConflicts)
            
            if let conflictResult = viewModel.conflictCheckResult {
                AIAnalysisCard(
                    analysis: conflictResult,
                    onViewDetails: {
                        showingConflictCheck = true
                    },
                    onDismiss: nil
                )
            }
        } header: {
            Text(AppStrings.Common.safety)
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func setupInitialData() {
        if let voiceText = initialVoiceText {
            parseVoiceInput(voiceText)
        }
    }
    
    private func parseVoiceInput(_ text: String) {
        // Parse voice input to extract medication details
        // This is a simple implementation - could be enhanced with NLP
        let components = text.lowercased().components(separatedBy: " ")
        
        // Try to extract medication name (usually first few words)
        if !components.isEmpty {
            medicationName = components.first?.capitalized ?? ""
        }
        
        // Try to extract dosage (look for numbers with units)
        for (index, component) in components.enumerated() {
            if component.contains("mg") || component.contains("ml") || 
               (index > 0 && components[index-1].rangeOfCharacter(from: .decimalDigits) != nil) {
                dosage = component
                if index > 0 && components[index-1].rangeOfCharacter(from: .decimalDigits) != nil {
                    dosage = components[index-1] + component
                }
            }
        }
        
        // Try to extract frequency
        if text.lowercased().contains("twice") {
            selectedFrequency = .twice
        } else if text.lowercased().contains("three") || text.lowercased().contains("thrice") {
            selectedFrequency = .thrice
        } else if text.lowercased().contains("as needed") {
            selectedFrequency = .asNeeded
        }
    }
    
    private func saveMedication() {
        Task {
            await viewModel.saveMedication(
                name: medicationName.trimmingCharacters(in: .whitespacesAndNewlines),
                dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
                frequency: selectedFrequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                prescribedBy: prescribedBy.isEmpty ? nil : prescribedBy.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                voiceEntryUsed: initialVoiceText != nil
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
    
    private func checkConflicts() {
        Task {
            await viewModel.checkConflicts(for: medicationName)
        }
    }
    
    private func addToSiri() {
        Task { @MainActor in
            SiriIntentsManager.shared.donateIntent(for: .addMedication(name: medicationName, dosage: dosage, frequency: selectedFrequency.displayName))
            
            // Show Siri tips
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                SiriTipPresenter.showTip(for: .addMedication(name: medicationName, dosage: dosage, frequency: nil), in: window)
            }
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class AddMedicationViewModel {
    private let coreDataManager = CoreDataManager.shared
    private let conflictManager = ConflictDetectionManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    var errorMessage: String?
    var isCheckingConflicts = false
    var conflictCheckResult: MedicationConflict?
    
    func saveMedication(
        name: String,
        dosage: String,
        frequency: MedicationFrequency,
        startDate: Date,
        endDate: Date?,
        prescribedBy: String?,
        notes: String?,
        voiceEntryUsed: Bool
    ) async {
        guard let userId = firebaseManager.currentUser?.id else {
            errorMessage = AppStrings.Errors.authenticationRequired
            return
        }
        
        let medication = MedicationModel.create(
            for: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            prescribedBy: prescribedBy,
            notes: notes,
            voiceEntryUsed: voiceEntryUsed
        )
        
        do {
            try await coreDataManager.saveMedication(medication)
            
            // Track analytics
            AnalyticsManager.shared.trackMedicationAdded(
                viaVoice: voiceEntryUsed,
                medicationType: "prescription"
            )
            
            // Donate to Siri
            SiriIntentsManager.shared.donateIntent(for: .addMedication(name: name, dosage: dosage, frequency: frequency.displayName))
            
        } catch {
            errorMessage = error.localizedDescription
            let appError = error as? AppError ?? AppError.data(.saveFailed)
            AnalyticsManager.shared.trackError(
                appError,
                context: "AddMedicationViewModel.saveMedication"
            )
        }
    }
    
    func checkConflicts(for medicationName: String) async {
        isCheckingConflicts = true
        defer { isCheckingConflicts = false }
        
        do {
            // Get current medications
            let medications = try await coreDataManager.fetchMedications(
                for: firebaseManager.currentUser?.id ?? ""
            )
            
            // Get current supplements
            let supplements = try await coreDataManager.fetchSupplements(
                for: firebaseManager.currentUser?.id ?? ""
            )
            
            // Add the new medication to the list for analysis
            var allMedications = medications.map { $0.name }
            allMedications.append(medicationName)
            
            // Check conflicts with all medications
            let analysis = try await conflictManager.analyzeMedications(
                medications: allMedications,
                supplements: supplements.map { $0.name }
            )
            
            // Convert to MedicationConflict
            let result = MedicationConflict.create(
                for: firebaseManager.currentUser?.id ?? "",
                queryText: "Check for \(medicationName)",
                medications: allMedications,
                supplements: supplements.map { $0.name },
                conflictsFound: analysis.conflictsFound,
                severity: ConflictSeverity(from: analysis.severity),
                conflictDetails: [],
                recommendations: analysis.recommendations,
                educationalInfo: analysis.summary,
                source: .realtime
            )
            
            conflictCheckResult = result
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddMedicationView(initialVoiceText: nil)
}
