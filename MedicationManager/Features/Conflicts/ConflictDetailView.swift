import SwiftUI

@MainActor
struct ConflictDetailView: View {
    let conflictId: String
    @State private var viewModel = ConflictDetailViewModel()
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let navigationManager = NavigationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(conflictId: String) {
        self.conflictId = conflictId
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                if let conflict = viewModel.conflict {
                    // Header with Severity
                    headerSection(conflict)
                    
                    // Involved Items
                    involvedItemsSection(conflict)
                    
                    // Description
                    descriptionSection(conflict)
                    
                    // Recommendations
                    if !conflict.recommendations.isEmpty {
                        recommendationsSection(conflict.recommendations)
                    }
                }
                
                // Source Information
                if let conflict = viewModel.conflict {
                    sourceSection(conflict)
                }
                
                // Actions
                actionsSection()
                
                // Related Conflicts
                if !viewModel.relatedConflicts.isEmpty {
                    relatedConflictsSection()
                }
            }
            .padding()
        }
        .navigationTitle(AppStrings.Conflicts.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButton
            }
        }
        .task {
            await viewModel.loadConflict(id: conflictId)
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private func headerSection(_ conflict: MedicationConflict) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Severity Badge
            HStack {
                Spacer()
                ConflictSeverityBadge(severity: conflict.severity ?? .none)
                    .scaleEffect(1.2)
                Spacer()
            }
            
            // Source and Date
            HStack {
                Label(conflict.source.rawValue.capitalized, systemImage: AppIcons.ai)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Text(conflict.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(conflict.severity?.color.opacity(0.1) ?? Color.clear)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - Involved Items Section
    @ViewBuilder
    private func involvedItemsSection(_ conflict: MedicationConflict) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Medications.medications)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(viewModel.involvedMedications, id: \.id) { medication in
                    involvedItemRow(
                        name: medication.name,
                        dosage: medication.dosage,
                        type: .medication,
                        isActive: medication.isActive
                    )
                }
                
                ForEach(viewModel.involvedSupplements, id: \.id) { supplement in
                    involvedItemRow(
                        name: supplement.name,
                        dosage: supplement.dosage,
                        type: .supplement,
                        isActive: supplement.isActive
                    )
                }
            }
            .padding()
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Involved Item Row
    @ViewBuilder
    private func involvedItemRow(name: String, dosage: String, type: ItemType, isActive: Bool) -> some View {
        HStack {
            Image(systemName: type == .medication ? AppIcons.medication : AppIcons.supplement)
                .foregroundColor(type == .medication ? AppTheme.Colors.primary : AppTheme.Colors.info)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.text)
                Text(dosage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            if !isActive {
                Text(AppStrings.Common.inactive)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                    .background(AppTheme.Colors.neutralBackground)
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }
    
    // MARK: - Description Section
    @ViewBuilder
    private func descriptionSection(_ conflict: MedicationConflict) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: AppIcons.info)
                    .foregroundColor(AppTheme.Colors.primary)
                Text(AppStrings.Common.details)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
            }
            
            Text(conflict.educationalInfo ?? AppStrings.Common.empty)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.text)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Recommendation Section
    @ViewBuilder
    private func recommendationsSection(_ recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: AppIcons.info)
                    .foregroundColor(AppTheme.Colors.warning)
                Text(AppStrings.Conflicts.management)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                        Text("•")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primary)
                        Text(recommendation)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.text)
                    }
                }
                
                // Medical Disclaimer
                HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                    Image(systemName: AppIcons.info)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text(AppStrings.Legal.medicalDisclaimer)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding()
                .background(AppTheme.Colors.warning.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.small)
            }
            .padding()
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Source Section
    @ViewBuilder
    private func sourceSection(_ conflict: MedicationConflict) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.Conflicts.analyzedBy)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            HStack {
                Image(systemName: AppIcons.ai)
                    .foregroundColor(AppTheme.Colors.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.source.displayName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    if let confidence = conflict.confidence {
                        HStack(spacing: AppTheme.Spacing.xSmall) {
                            Text(AppStrings.AI.confidence)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text("\(Int(confidence * 100))%")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Actions Section
    @ViewBuilder
    private func actionsSection() -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Contact Doctor
            Button(action: contactDoctorAction) {
                HStack {
                    Image(systemName: AppIcons.phone)
                    Text(AppStrings.Doctors.contactDoctor)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            // Re-analyze
            Button(action: reanalyzeAction) {
                HStack {
                    Image(systemName: AppIcons.sync)
                    Text(AppStrings.Common.analyze)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isReanalyzing)
            
            // Mark as Reviewed
            if let conflict = viewModel.conflict, !conflict.isResolved {
                Button(action: markAsReviewedAction) {
                    HStack {
                        Image(systemName: AppIcons.success)
                        Text(AppStrings.Common.done)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(AppTheme.Colors.success)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Related Conflicts Section
    @ViewBuilder
    private func relatedConflictsSection() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(NSLocalizedString("conflicts.relatedConflicts", value: "Related Conflicts", comment: "Related conflicts section title"))
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(viewModel.relatedConflicts) { relatedConflict in
                    Button(action: { navigateToConflict(relatedConflict.id) }) {
                        HStack {
                            ConflictSeverityBadge(severity: relatedConflict.severity ?? .none)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(relatedConflict.displaySummary)
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.Colors.text)
                                    .multilineTextAlignment(.leading)
                                
                                Text(relatedConflict.educationalInfo ?? AppStrings.Common.empty)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Image(systemName: AppIcons.chevronRight)
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding()
                        .background(AppTheme.Colors.cardBackground)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private var shareButton: some View {
        Button(action: shareAction) {
            Image(systemName: AppIcons.share)
        }
    }
    
    // MARK: - Actions
    private func contactDoctorAction() {
        guard let conflict = viewModel.conflict else { return }
        // Find the most relevant doctor from medications
        if let firstMedicationName = conflict.medications.first,
           let medication = viewModel.involvedMedications.first(where: { $0.name == firstMedicationName }),
           let doctorName = medication.prescribedBy {
            // TODO: Find doctor by name and navigate
            // For now, just navigate to doctors list
            print("Medication prescribed by: \(doctorName)")
        }
        // Navigate to doctors tab
        print("Navigate to doctors list")
    }
    
    private func reanalyzeAction() {
        Task {
            await viewModel.reanalyzeConflict()
        }
    }
    
    private func markAsReviewedAction() {
        Task {
            await viewModel.markAsReviewed()
        }
    }
    
    private func shareAction() {
        guard let conflict = viewModel.conflict else { return }
        let shareText = """
        Medication Conflict Alert
        
        Severity: \(conflict.severity?.displayName ?? "Unknown")
        Medications: \(conflict.medications.joined(separator: ", "))
        
        Details:
        \(conflict.educationalInfo ?? "No details available")
        
        \(conflict.recommendations.joined(separator: "\n"))
        
        \(AppStrings.Legal.medicalDisclaimer)
        """
        
        // Share functionality would be implemented here
        print("Sharing conflict: \(shareText)")
    }
    
    private func navigateToConflict(_ conflictId: String) {
        // TODO: Update navigation to pass conflict object once NavigationManager is updated
        print("Navigate to conflict: \(conflictId)")
    }
}

// MARK: - Item Type
private enum ItemType {
    case medication
    case supplement
}

// MARK: - View Model
@MainActor
@Observable
final class ConflictDetailViewModel {
    // State
    var conflict: MedicationConflict?
    var involvedMedications: [MedicationModel] = []
    var involvedSupplements: [SupplementModel] = []
    var relatedConflicts: [MedicationConflict] = []
    var isLoading = false
    var isReanalyzing = false
    var error: Error?
    
    // Dependencies
    private let coreDataManager = CoreDataManager.shared
    private let conflictManager = ConflictDetectionManager.shared
    private let analyticsManager = AnalyticsManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    init() {
        // Initialize empty, will load data when view appears
    }
    
    // MARK: - Load Conflict
    func loadConflict(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = firebaseManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            // Load conflict by ID
            conflict = try await coreDataManager.fetchConflict(id: id, userId: userId)
            
            if conflict != nil {
                // Load involved items
                await loadInvolvedItems()
                
                // Load related conflicts
                await loadRelatedConflicts()
            }
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Load Involved Items
    func loadInvolvedItems() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = firebaseManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            guard let conflict = conflict else { return }
            
            // Load medications by name
            let allMedications = try await coreDataManager.fetchMedications(for: userId)
            involvedMedications = allMedications.filter { medication in
                conflict.medications.contains(medication.name)
            }
            
            // Load supplements by name
            let allSupplements = try await coreDataManager.fetchSupplements(for: userId)
            involvedSupplements = allSupplements.filter { supplement in
                conflict.supplements.contains(supplement.name)
            }
            
            // Track view
            analyticsManager.trackEvent(
                "conflict_detail_viewed",
                parameters: [
                    "severity": conflict.severity?.rawValue ?? "unknown",
                    "medications_count": String(conflict.medications.count),
                    "supplements_count": String(conflict.supplements.count)
                ]
            )
        } catch {
            self.error = error
        }
    }
    
    
    // MARK: - Load Related Conflicts
    func loadRelatedConflicts() async {
        guard let userId = firebaseManager.currentUser?.id else { return }
        
        do {
            // Get all conflicts
            let allConflicts = try await coreDataManager.fetchConflicts(for: userId)
            
            guard let conflict = conflict else { return }
            
            // Find related conflicts (same medications/supplements but different conflict)
            relatedConflicts = allConflicts.filter { otherConflict in
                otherConflict.id != conflict.id &&
                (
                    !Set(otherConflict.medications).isDisjoint(with: conflict.medications) ||
                    !Set(otherConflict.supplements).isDisjoint(with: conflict.supplements)
                )
            }
            .prefix(3)
            .map { $0 }
        } catch {
            print("Error loading related conflicts: \(error)")
        }
    }
    
    // MARK: - Re-analyze Conflict
    func reanalyzeConflict() async {
        guard let userId = firebaseManager.currentUser?.id else { return }
        
        isReanalyzing = true
        defer { isReanalyzing = false }
        
        do {
            guard let conflict = conflict else { return }
            
            // Re-run conflict analysis for the medications and supplements in this conflict
            let query = "Check interactions between medications: \(conflict.medications.joined(separator: ", ")) and supplements: \(conflict.supplements.joined(separator: ", "))"
            
            let analysis = try await conflictManager.analyzeQuery(query)
            
            // Convert the analysis to a new MedicationConflict
            let newConflict = MedicationConflict.fromAnalysis(analysis, userId: userId)
            
            // Save the new conflict (creates new record with new ID)
            try await coreDataManager.saveConflict(newConflict)
            
            // Update the view model's conflict to the new one
            self.conflict = newConflict
            
            // Reload involved items with the new conflict data
            await loadInvolvedItems()
            
            // Track re-analysis
            analyticsManager.trackEvent(
                "conflict_reanalyzed",
                parameters: [
                    "conflict_id": conflict.id,
                    "found_update": analysis.conflictsFound ? "yes" : "no"
                ]
            )
        } catch {
            self.error = error
            print("Error re-analyzing conflict: \(error)")
        }
    }
    
    // MARK: - Mark as Reviewed
    func markAsReviewed() async {
        guard var resolvedConflict = conflict else { return }
        resolvedConflict.markAsResolved()
        
        do {
            try await coreDataManager.saveConflict(resolvedConflict)
            
            // Track review
            analyticsManager.trackEvent(
                "conflict_marked_reviewed",
                parameters: [
                    "conflict_id": resolvedConflict.id,
                    "severity": resolvedConflict.severity?.rawValue ?? "unknown"
                ]
            )
        } catch {
            self.error = error
            print("Error marking conflict as reviewed: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        ConflictDetailView(conflictId: "preview-id")
    }
}
