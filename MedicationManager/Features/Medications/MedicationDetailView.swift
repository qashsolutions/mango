import SwiftUI
import Observation

@MainActor
struct MedicationDetailView: View {
    let medicationId: String
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MedicationDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingConflictAnalysis = false
    @State private var firebaseManager = FirebaseManager.shared
    
    init(medicationId: String) {
        self.medicationId = medicationId
        self._viewModel = State(initialValue: MedicationDetailViewModel(medicationId: medicationId))
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let medication = viewModel.medication {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Header Card
                    medicationHeaderCard(medication)
                    
                    // Schedule Section
                    scheduleSection(medication)
                    
                    // Prescriber Section
                    if let prescribedBy = medication.prescribedBy {
                        prescriberSection(prescribedBy)
                    }
                    
                    // Notes Section
                    if let notes = medication.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    
                    // Conflict Analysis
                    conflictAnalysisSection(medication)
                    
                    // Actions
                    actionButtons()
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            } else {
                ContentUnavailableView(
                    AppStrings.Errors.medicationNotFound,
                    systemImage: AppIcons.medicationEmpty,
                    description: Text(NSLocalizedString("medication.detail.notFoundDescription", value: "The medication could not be found", comment: "Medication not found description"))
                )
            }
        }
        .navigationTitle(viewModel.medication?.name ?? AppStrings.Common.loading)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarItems(
            trailing: Menu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label {
                        Text(AppStrings.Common.edit as String)
                    } icon: {
                        Image(systemName: AppIcons.edit as String)
                    }
                }
                
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label {
                        Text(AppStrings.Common.delete as String)
                    } icon: {
                        Image(systemName: AppIcons.delete as String)
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        )
        .sheet(isPresented: $showingEditSheet) {
            if let medication = viewModel.medication {
                EditMedicationView(medicationId: medication.id)
            }
        }
        .alert(AppStrings.Common.confirmDelete, isPresented: $showingDeleteAlert) {
            Button(AppStrings.Common.cancel, role: .cancel) { }
            Button(AppStrings.Common.delete as String, role: .destructive) {
                deleteMedication()
            }
        } message: {
            Text(NSLocalizedString("medication.detail.deleteConfirmation", value: "Are you sure you want to delete this medication? This action cannot be undone.", comment: "Delete medication confirmation"))
        }
        .task {
            await viewModel.loadMedication()
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func medicationHeaderCard(_ medication: MedicationModel) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(medication.name)
                        .font(AppTheme.Typography.title)
                    
                    Text(medication.dosage)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: AppIcons.medication)
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            Divider()
            
            HStack {
                Label {
                    Text(medication.frequency.displayName)
                } icon: {
                    Image(systemName: AppIcons.schedule)
                }
                .font(AppTheme.Typography.body)
                
                Spacer()
                
                if medication.isActive {
                    Label {
                        Text(AppStrings.Common.active)
                    } icon: {
                        Image(systemName: AppIcons.success)
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.success)
                } else {
                    Label {
                        Text(AppStrings.Common.inactive)
                    } icon: {
                        Image(systemName: AppIcons.info)
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    @ViewBuilder
    private func scheduleSection(_ medication: MedicationModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Medications.schedule)
                .font(AppTheme.Typography.headline)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Text(AppStrings.Common.startDate)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    Spacer()
                    Text(medication.startDate, style: .date)
                        .font(AppTheme.Typography.body)
                }
                
                if let endDate = medication.endDate {
                    HStack {
                        Text(AppStrings.Common.endDate)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        Spacer()
                        Text(endDate, style: .date)
                            .font(AppTheme.Typography.body)
                    }
                }
                
                if medication.schedule.count > 0 {
                    HStack {
                        Text(AppStrings.Medications.reminders)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        Spacer()
                        Text("\(medication.schedule.count) " + AppStrings.Common.active.lowercased())
                            .font(AppTheme.Typography.body)
                    }
                }
            }
            .padding()
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
    
    @ViewBuilder
    private func prescriberSection(_ prescribedBy: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Common.prescribedBy)
                .font(AppTheme.Typography.headline)
            
            HStack {
                Image(systemName: AppIcons.doctorEmpty)
                    .foregroundColor(AppTheme.Colors.primary)
                Text(prescribedBy)
                    .font(AppTheme.Typography.body)
                Spacer()
            }
            .padding()
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
    
    @ViewBuilder
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Medications.notes)
                .font(AppTheme.Typography.headline)
            
            Text(notes)
                .font(AppTheme.Typography.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
    
    @ViewBuilder
    private func conflictAnalysisSection(_ medication: MedicationModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(AppStrings.Conflicts.title)
                    .font(AppTheme.Typography.headline)
                Spacer()
                if viewModel.isCheckingConflicts {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let conflictAnalysis = viewModel.lastConflictCheck {
                // Convert ClaudeAIClient.ConflictAnalysis to MedicationConflict
                let conflictResult = MedicationConflict.create(
                    for: firebaseManager.currentUser?.id ?? "",
                    queryText: "Conflict check for \(medication.name)",
                    medications: viewModel.allMedications,
                    supplements: viewModel.allSupplements,
                    conflictsFound: conflictAnalysis.conflictsFound,
                    severity: ConflictSeverity(from: conflictAnalysis.severity),
                    conflictDetails: [],
                    recommendations: conflictAnalysis.recommendations,
                    educationalInfo: conflictAnalysis.summary,
                    source: .realtime
                )
                
                AIAnalysisCard(
                    analysis: conflictResult,
                    onViewDetails: {
                        showingConflictAnalysis = true
                    },
                    onDismiss: nil
                )
            } else {
                Button(action: checkConflicts) {
                    HStack {
                        Image(systemName: AppIcons.ai)
                        Text(AppStrings.Actions.checkConflicts)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingConflictAnalysis) {
            if let result = viewModel.lastConflictCheck {
                NavigationStack {
                    ConflictAnalysisView(
                        analysis: result,
                        query: "Checking medications: \(viewModel.allMedications.joined(separator: ", "))\(viewModel.allSupplements.isEmpty ? "" : " with supplements: \(viewModel.allSupplements.joined(separator: ", "))")"
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func actionButtons() -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Button(action: { showingEditSheet = true }) {
                HStack {
                    Image(systemName: AppIcons.edit)
                    Text(AppStrings.Medications.editMedication)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            Button(action: { viewModel.toggleActiveStatus() }) {
                HStack {
                    Image(systemName: viewModel.medication?.isActive == true ? "pause.circle" : "play.circle")
                    Text(viewModel.medication?.isActive == true ? 
                         NSLocalizedString("medication.detail.markInactive", value: "Mark as Inactive", comment: "Mark inactive button") :
                         NSLocalizedString("medication.detail.markActive", value: "Mark as Active", comment: "Mark active button"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.secondaryBackground)
                .foregroundColor(AppTheme.Colors.primaryText)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    // MARK: - Actions
    
    private func checkConflicts() {
        Task {
            await viewModel.checkConflicts()
        }
    }
    
    private func deleteMedication() {
        Task { [viewModel, dismiss] in
            await viewModel.deleteMedication()
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class MedicationDetailViewModel {
    private let medicationId: String
    private let coreDataManager = CoreDataManager.shared
    private let conflictManager = ConflictDetectionManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    var medication: MedicationModel?
    var isLoading = true
    var isCheckingConflicts = false
    var lastConflictCheck: ClaudeAIClient.ConflictAnalysis?
    var allMedications: [String] = []
    var allSupplements: [String] = []
    var errorMessage: String?
    
    init(medicationId: String) {
        self.medicationId = medicationId
    }
    
    func loadMedication() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let medications = try await coreDataManager.fetchMedications(for: firebaseManager.currentUser?.id ?? "")
            medication = medications.first { $0.id == medicationId }
            
            // Load other medications and supplements for conflict checking
            if let userId = firebaseManager.currentUser?.id {
                let meds = try await coreDataManager.fetchMedications(for: userId)
                allMedications = meds.map { $0.name }
                
                let supps = try await coreDataManager.fetchSupplements(for: userId)
                allSupplements = supps.map { $0.name }
            }
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                AppError.data(.loadFailed),
                context: "MedicationDetailViewModel.loadMedication"
            )
        }
    }
    
    func checkConflicts() async {
        guard medication != nil else { return }
        
        isCheckingConflicts = true
        defer { isCheckingConflicts = false }
        
        do {
            let analysis = try await conflictManager.analyzeMedications(
                medications: allMedications,
                supplements: allSupplements
            )
            lastConflictCheck = analysis
            
            AnalyticsManager.shared.trackEvent(
                "medication_detail_conflict_check",
                parameters: ["medication_id": medicationId]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleActiveStatus() {
        guard var medication = medication else { return }
        
        Task { [weak self] in
            guard let self else { return }
            medication.isActive.toggle()
            medication.updatedAt = Date()
            
            do {
                try await coreDataManager.saveMedication(medication)
                self.medication = medication
                
                AnalyticsManager.shared.trackEvent(
                    "medication_status_toggled",
                    parameters: [
                        "medication_id": medicationId,
                        "new_status": medication.isActive ? "active" : "inactive"
                    ]
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteMedication() async {
        guard let userId = firebaseManager.currentUser?.id else {
            errorMessage = AppStrings.Errors.authenticationRequired
            return
        }
        
        do {
            // Fetch all medications and find the one to delete
            let medications = try await coreDataManager.fetchMedications(for: userId)
            guard var medicationToDelete = medications.first(where: { $0.id == medicationId }) else {
                errorMessage = AppStrings.Errors.medicationNotFound
                return
            }
            
            // Mark as deleted and save
            medicationToDelete.isDeletedFlag = true
            medicationToDelete.updatedAt = Date()
            medicationToDelete.needsSync = true
            
            try await coreDataManager.saveMedication(medicationToDelete)
            
            AnalyticsManager.shared.trackEvent(
                "medication_deleted",
                parameters: ["medication_id": medicationId]
            )
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                AppError.data(.saveFailed),
                context: "MedicationDetailViewModel.deleteMedication"
            )
        }
    }
}

#Preview {
    NavigationStack {
        MedicationDetailView(medicationId: "preview-id")
    }
}
