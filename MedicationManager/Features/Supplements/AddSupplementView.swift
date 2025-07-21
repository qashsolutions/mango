import SwiftUI
import Observation

@MainActor
struct AddSupplementView: View {
    let initialVoiceText: String?
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddSupplementViewModel()
    
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
    
    // UI state
    @State private var showingError = false
    @State private var showingConflictCheck = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Supplement Details Section
                Section(header: Text(AppStrings.Common.details)) {
                    // Supplement Name with Voice Input
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text(AppStrings.Supplements.name)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        VoiceFirstInputView(
                            text: $supplementName,
                            placeholder: NSLocalizedString("supplements.namePlaceholder", value: "Vitamin D, Omega-3, etc.", comment: "Supplement name placeholder"),
                            voiceContext: .supplementName,
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
                        ForEach(SupplementFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Take with food toggle
                    Toggle(NSLocalizedString("supplements.takeWithFood", value: "Take with food", comment: "Take with food toggle"), isOn: $isTakenWithFood)
                }
                
                // Schedule Section
                Section(header: Text(AppStrings.Medications.schedule)) {
                    DatePicker(
                        "Start Date",
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
                }
                
                // Additional Info Section
                Section(header: Text(AppStrings.Common.notes)) {
                    // Purpose with Voice Input
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text(NSLocalizedString("supplements.purpose", value: "Purpose", comment: "Purpose label"))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        VoiceFirstInputView(
                            text: $purpose,
                            placeholder: NSLocalizedString("supplements.purposePlaceholder", value: "Immune support, bone health, etc.", comment: "Purpose placeholder"),
                            voiceContext: .general,
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
                }
                
                // Conflict Check Section
                Section(
                    header: Text(AppStrings.Supplements.safety),
                    footer: Text(NSLocalizedString("supplements.conflictCheckNote", value: "Check interactions with your medications and other supplements", comment: "Conflict check note"))
                        .font(AppTheme.Typography.caption2)
                ) {
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
                    .disabled(supplementName.isEmpty || viewModel.isCheckingConflicts)
                    
                    if let conflictResult = viewModel.conflictCheckResult {
                        AIAnalysisCard(
                            analysis: conflictResult,
                            onViewDetails: {
                                showingConflictCheck = true
                            },
                            onDismiss: nil
                        )
                    }
                }
            }
            .navigationTitle(AppStrings.Actions.addSupplement)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Group {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(AppStrings.Common.cancel) {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(AppStrings.Common.save) {
                            saveSupplement()
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
            .alert(AppStrings.Common.error, isPresented: $showingError) {
                Button(AppStrings.Common.ok) { }
            } message: {
                Text(viewModel.errorMessage ?? AppStrings.Common.error)
            }
            .onAppear {
                setupInitialData()
                AnalyticsManager.shared.trackScreenViewed("add_supplement")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !supplementName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func setupInitialData() {
        if let voiceText = initialVoiceText {
            parseVoiceInput(voiceText)
        }
    }
    
    private func parseVoiceInput(_ text: String) {
        // Parse voice input to extract supplement details
        let components = text.lowercased().components(separatedBy: " ")
        
        // Try to extract supplement name (usually first few words)
        if !components.isEmpty {
            // Common supplement keywords
            let supplementKeywords = ["vitamin", "omega", "calcium", "iron", "zinc", "magnesium", "probiotics"]
            
            for (index, component) in components.enumerated() {
                if supplementKeywords.contains(where: { component.contains($0) }) {
                    // Found a supplement keyword, extract name
                    var nameComponents = [component]
                    if index + 1 < components.count {
                        nameComponents.append(components[index + 1])
                    }
                    supplementName = nameComponents.joined(separator: " ").capitalized
                    break
                }
            }
            
            // If no keyword found, use first word
            if supplementName.isEmpty {
                supplementName = components.first?.capitalized ?? ""
            }
        }
        
        // Try to extract dosage
        for (index, component) in components.enumerated() {
            if component.contains("mg") || component.contains("iu") || component.contains("mcg") ||
               (index > 0 && components[index-1].rangeOfCharacter(from: .decimalDigits) != nil) {
                dosage = component
                if index > 0 && components[index-1].rangeOfCharacter(from: .decimalDigits) != nil {
                    dosage = components[index-1] + component
                }
            }
        }
        
        // Try to extract frequency
        if text.lowercased().contains("daily") {
            selectedFrequency = .daily
        } else if text.lowercased().contains("weekly") {
            selectedFrequency = .weekly
        } else if text.lowercased().contains("as needed") {
            selectedFrequency = .asNeeded
        }
        
        // Check for "with food"
        if text.lowercased().contains("with food") || text.lowercased().contains("with meal") {
            isTakenWithFood = true
        }
    }
    
    private func saveSupplement() {
        Task {
            await viewModel.saveSupplement(
                name: supplementName.trimmingCharacters(in: .whitespacesAndNewlines),
                dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
                frequency: selectedFrequency,
                purpose: purpose.isEmpty ? nil : purpose.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isTakenWithFood: isTakenWithFood,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
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
            await viewModel.checkConflicts(for: supplementName)
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class AddSupplementViewModel {
    private let coreDataManager = CoreDataManager.shared
    private let conflictManager = ConflictDetectionManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    var errorMessage: String?
    var isCheckingConflicts = false
    var conflictCheckResult: MedicationConflict?
    
    func saveSupplement(
        name: String,
        dosage: String,
        frequency: SupplementFrequency,
        purpose: String?,
        notes: String?,
        isTakenWithFood: Bool,
        startDate: Date,
        endDate: Date?,
        voiceEntryUsed: Bool
    ) async {
        guard let userId = firebaseManager.currentUser?.id else {
            errorMessage = AppStrings.Errors.authenticationRequired
            return
        }
        
        let supplement = SupplementModel(
            id: UUID().uuidString,
            userId: userId,
            name: name,
            dosage: dosage,
            frequency: frequency,
            schedule: [],
            notes: notes,
            purpose: purpose,
            brand: nil,
            isActive: true,
            isTakenWithFood: isTakenWithFood,
            startDate: startDate,
            endDate: endDate,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: voiceEntryUsed,
            needsSync: true,
            isDeletedFlag: false
        )
        
        do {
            try await coreDataManager.saveSupplement(supplement)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "supplement_added",
                parameters: [
                    "voice_used": voiceEntryUsed,
                    "has_purpose": purpose != nil,
                    "with_food": isTakenWithFood
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            let appError = error as? AppError ?? AppError.data(.unknown)
            AnalyticsManager.shared.trackError(
                appError,
                context: "AddSupplementViewModel.saveSupplement"
            )
        }
    }
    
    func checkConflicts(for supplementName: String) async {
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
            
            // Check conflicts with the new supplement
            let analysis = try await conflictManager.analyzeMedications(
                medications: medications.map { $0.name },
                supplements: supplements.map { $0.name } + [supplementName]
            )
            
            // Convert to MedicationConflict
            let result = MedicationConflict.create(
                for: firebaseManager.currentUser?.id ?? "",
                queryText: "Check for \(supplementName)",
                medications: medications.map { $0.name },
                supplements: supplements.map { $0.name } + [supplementName],
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
    AddSupplementView(initialVoiceText: nil)
}
