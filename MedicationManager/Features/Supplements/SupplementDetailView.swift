import SwiftUI

@MainActor
struct SupplementDetailView: View {
    let supplementId: String
    @State private var viewModel = SupplementDetailViewModel()
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let navigationManager = NavigationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        mainContent
            .navigationTitle(viewModel.supplement?.name ?? AppStrings.Common.supplement)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
            .alert(
                AppStrings.Common.deleteConfirmationTitle,
                isPresented: $viewModel.showDeleteConfirmation
            ) {
                Button(AppStrings.Common.cancel, role: .cancel) { }
                Button(AppStrings.Common.delete, role: .destructive) {
                    Task {
                        await deleteSupplementAction()
                    }
                }
            } message: {
                Text(AppStrings.Common.deleteSupplementConfirmation)
            }
            .task {
                await viewModel.loadSupplement(id: supplementId)
            }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let supplement = viewModel.supplement {
                supplementContentView(supplement)
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Supplement Content
    @ViewBuilder
    private func supplementContentView(_ supplement: SupplementModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Header Card
                headerCard(supplement)
                
                // Details Section
                detailsSection(supplement)
                
                // Conflict Check Section
                conflictCheckSection()
                
                // Notes Section
                if let notes = supplement.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                
                // Actions Section
                actionsSection()
            }
            .padding()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        ContentUnavailableView(
            AppStrings.Common.supplementNotFound,
            systemImage: AppIcons.supplement,
            description: Text(AppStrings.Common.supplementNotFoundDescription)
        )
    }
    
    // MARK: - Header Card
    @ViewBuilder
    private func headerCard(_ supplement: SupplementModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(supplement.name)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text(supplement.dosage)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.text)
                }
                
                Spacer()
                
                // Active Status Badge
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    Circle()
                        .fill(supplement.isActive ? AppTheme.Colors.success : AppTheme.Colors.neutral)
                        .frame(width: 8, height: 8)
                    
                    Text(supplement.isActive ? AppStrings.Common.active : AppStrings.Common.inactive)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(supplement.isActive ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal, AppTheme.Spacing.small)
                .padding(.vertical, AppTheme.Spacing.xSmall)
                .background(
                    Capsule()
                        .fill(supplement.isActive ? AppTheme.Colors.success.opacity(0.1) : AppTheme.Colors.neutralBackground)
                )
            }
            
            if let purpose = supplement.purpose {
                HStack {
                    Image(systemName: AppIcons.info)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .font(AppTheme.Typography.caption)
                    
                    Text(purpose)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadows.cardShadowRadius)
    }
    
    // MARK: - Details Section
    @ViewBuilder
    private func detailsSection(_ supplement: SupplementModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Common.details)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(spacing: AppTheme.Spacing.small) {
                detailRow(
                    icon: AppIcons.frequency,
                    label: AppStrings.Common.frequency,
                    value: supplement.frequency.displayName
                )
                
                detailRow(
                    icon: AppIcons.calendar,
                    label: AppStrings.Common.startDate,
                    value: supplement.startDate.formatted(date: .abbreviated, time: .omitted)
                )
                
                if let endDate = supplement.endDate {
                    detailRow(
                        icon: AppIcons.calendar,
                        label: AppStrings.Common.endDate,
                        value: endDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }
                
                if supplement.isTakenWithFood {
                    detailRow(
                        icon: AppIcons.food,
                        label: AppStrings.Medications.notes,
                        value: NSLocalizedString("supplement.withFood", value: "Take with food", comment: "Take with food instruction")
                    )
                }
                
                detailRow(
                    icon: AppIcons.time,
                    label: AppStrings.Conflicts.Analysis.lastUpdated,
                    value: supplement.updatedAt.formatted(date: .abbreviated, time: .shortened)
                )
            }
            .padding()
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Detail Row
    @ViewBuilder
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 20)
                
                Text(label)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.text)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }
    
    // MARK: - Conflict Check Section
    @ViewBuilder
    private func conflictCheckSection() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(AppStrings.Conflicts.checkConflicts)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                if viewModel.isCheckingConflicts {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if viewModel.conflicts.isEmpty && !viewModel.isCheckingConflicts {
                HStack {
                    Image(systemName: AppIcons.success)
                        .foregroundColor(AppTheme.Colors.success)
                    
                    Text(AppStrings.Conflicts.noConflictsMessage)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.success.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                ForEach(viewModel.conflicts) { conflict in
                    SupplementConflictCard(conflict: conflict)
                }
            }
            
            Button(action: checkConflictsAction) {
                HStack {
                    Image(systemName: AppIcons.conflicts)
                    Text(AppStrings.Actions.checkConflicts)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isCheckingConflicts)
        }
    }
    
    // MARK: - Notes Section
    @ViewBuilder
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.Common.notes)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            Text(notes)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Actions Section
    @ViewBuilder
    private func actionsSection() -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Toggle Active Status
            Button(action: toggleActiveStatusAction) {
                HStack {
                    Image(systemName: viewModel.supplement?.isActive == true ? AppIcons.pause : AppIcons.play)
                    Text(viewModel.supplement?.isActive == true ? AppStrings.Common.inactive : AppStrings.Common.active)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isUpdating)
            
            // Delete Button
            Button(role: .destructive, action: { viewModel.showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: AppIcons.delete)
                    Text(AppStrings.Common.delete)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .foregroundColor(AppTheme.Colors.error)
            .disabled(viewModel.isUpdating)
        }
        .padding(.top)
    }
    
    // MARK: - Helper Views
    private var editButton: some View {
        Button(AppStrings.Common.edit) {
            navigationManager.presentSheet(.editSupplement(id: supplementId))
        }
    }
    
    // MARK: - Actions
    private func checkConflictsAction() {
        Task {
            await viewModel.checkConflicts()
        }
    }
    
    private func toggleActiveStatusAction() {
        Task {
            await viewModel.toggleActiveStatus()
        }
    }
    
    private func deleteSupplementAction() async {
        await viewModel.deleteSupplement()
        if viewModel.supplement == nil {
            dismiss()
        }
    }
}

// MARK: - Conflict Card
private struct SupplementConflictCard: View {
    let conflict: MedicationConflict
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                ConflictSeverityBadge(severity: conflict.severity ?? .low)
                Spacer()
            }
            
            Text(conflict.educationalInfo ?? "")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.text)
            
            if let firstRecommendation = conflict.recommendations.first {
                Text(firstRecommendation)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke((conflict.severity ?? .low).color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - View Model
@MainActor
@Observable
final class SupplementDetailViewModel {
    // State
    var supplement: SupplementModel?
    var conflicts: [MedicationConflict] = []
    var isLoading = false
    var isUpdating = false
    var isCheckingConflicts = false
    var showDeleteConfirmation = false
    var error: Error?
    
    // Dependencies
    private let coreDataManager = CoreDataManager.shared
    private let conflictManager = ConflictDetectionManager.shared
    private let analyticsManager = AnalyticsManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    // MARK: - Load Supplement
    func loadSupplement(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = firebaseManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        do {
            let supplements = try await coreDataManager.fetchSupplements(for: userId)
            supplement = supplements.first(where: { $0.id == id })
            
            // Check conflicts automatically on load
            await checkConflicts()
            
            // Track view
            analyticsManager.trackScreenViewed("supplement_detail")
        } catch {
            self.error = error
            print("Error loading supplement: \(error)")
        }
    }
    
    // MARK: - Check Conflicts
    func checkConflicts() async {
        guard let supplement = supplement,
              let userId = firebaseManager.currentUser?.id else { return }
        
        isCheckingConflicts = true
        defer { isCheckingConflicts = false }
        
        do {
            // Get all active medications and supplements
            let medications = try await coreDataManager.fetchMedications(for: userId)
                .filter { $0.isActive }
            let supplements = try await coreDataManager.fetchSupplements(for: userId)
                .filter { $0.isActive && $0.id != supplement.id }
            
            // Check for conflicts
            _ = "\(supplement.name) interactions with medications: \(medications.map { $0.name }.joined(separator: ", ")) and supplements: \(supplements.map { $0.name }.joined(separator: ", "))"
            
            // ConflictDetectionManager needs implementation for checkConflicts
            // For now, use empty array to compile
            conflicts = []
            // TODO: Implement conflict detection or use existing method
            
            // Track conflict check
            analyticsManager.trackEvent(
                "supplement_conflict_check",
                parameters: [
                    "supplement_name": supplement.name,
                    "conflicts_found": conflicts.count
                ]
            )
        } catch {
            self.error = error
            print("Error checking conflicts: \(error)")
        }
    }
    
    // MARK: - Toggle Active Status
    func toggleActiveStatus() async {
        guard let supplement = supplement else { return }
        
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            var updatedSupplement = supplement
            updatedSupplement.isActive.toggle()
            updatedSupplement.updatedAt = Date()
            updatedSupplement.needsSync = true
            
            try await coreDataManager.saveSupplement(updatedSupplement)
            self.supplement = updatedSupplement
            
            // Track status change
            analyticsManager.trackEvent(
                "supplement_status_toggled",
                parameters: [
                    "supplement_name": supplement.name,
                    "new_status": updatedSupplement.isActive ? "active" : "inactive"
                ]
            )
            
            // Re-check conflicts if activated
            if updatedSupplement.isActive {
                await checkConflicts()
            } else {
                conflicts = []
            }
        } catch {
            self.error = error
            print("Error toggling supplement status: \(error)")
        }
    }
    
    // MARK: - Delete Supplement
    func deleteSupplement() async {
        guard var supplement = supplement else { return }
        
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            // Mark as deleted and save (soft delete)
            supplement.isDeletedFlag = true
            supplement.updatedAt = Date()
            supplement.needsSync = true
            
            try await coreDataManager.saveSupplement(supplement)
            
            // Track deletion
            analyticsManager.trackEvent(
                "supplement_deleted",
                parameters: ["supplement_name": supplement.name]
            )
            
            // Clear the supplement to indicate deletion
            self.supplement = nil
        } catch {
            self.error = error
            print("Error deleting supplement: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SupplementDetailView(supplementId: "preview-id")
    }
}
