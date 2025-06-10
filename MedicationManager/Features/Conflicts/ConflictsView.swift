import SwiftUI

struct ConflictsView: View {
    @StateObject private var viewModel = ConflictsViewModel()
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var showingCheckConfirmation: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    LoadingState(message: AppStrings.Conflicts.analyzingConflicts)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.large) {
                            // Conflict Summary Header
                            ConflictSummaryHeader(
                                summary: viewModel.conflictSummary,
                                onCheckConflicts: {
                                    showingCheckConfirmation = true
                                }
                            )
                            
                            if viewModel.conflicts.isEmpty {
                                // No Conflicts State
                                ConflictEmptyState(onCheckConflicts: {
                                    showingCheckConfirmation = true
                                })
                            } else {
                                // Critical Conflicts Section
                                if !viewModel.criticalConflicts.isEmpty {
                                    CriticalConflictsSection(
                                        conflicts: viewModel.criticalConflicts,
                                        onConflictTap: { conflict in
                                            navigationManager.navigate(to: .conflictDetail(id: conflict.id))
                                        },
                                        onResolveConflict: { conflict in
                                            Task {
                                                await viewModel.resolveConflict(conflict)
                                            }
                                        }
                                    )
                                }
                                
                                // All Conflicts Section
                                AllConflictsSection(
                                    conflicts: viewModel.conflicts,
                                    onConflictTap: { conflict in
                                        navigationManager.navigate(to: .conflictDetail(id: conflict.id))
                                    },
                                    onFilterChange: { filter in
                                        viewModel.updateFilter(filter)
                                    }
                                )
                            }
                            
                            // Educational Section
                            ConflictEducationSection()
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.bottom, AppTheme.Spacing.extraLarge)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .navigationTitle(AppStrings.Tabs.conflicts)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        SyncActionButton()
                        
                        Button(action: { showingCheckConfirmation = true }) {
                            Image(systemName: AppIcons.conflicts)
                                .font(.system(size: 18, weight: .medium))
                        }
                        .disabled(viewModel.isAnalyzing)
                    }
                }
            }
            .alert(AppStrings.Conflicts.checkConfirmation, isPresented: $showingCheckConfirmation) {
                Button(AppStrings.Common.analyze) {
                    Task {
                        await viewModel.checkForConflicts()
                    }
                }
                Button(AppStrings.Common.cancel, role: .cancel) {}
            } message: {
                Text(AppStrings.Conflicts.checkConfirmationMessage)
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.error.map { AlertItem.fromError($0) } },
                set: { _ in viewModel.clearError() }
            )) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text(AppStrings.Common.ok))
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Conflict Summary Header
struct ConflictSummaryHeader: View {
    let summary: ConflictAnalysisSummary
    let onCheckConflicts: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(AppStrings.Conflicts.conflictAnalysis)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    if let lastAnalysis = summary.lastAnalysisDate {
                        Text(AppStrings.Conflicts.lastCheckedDate(lastAnalysis))
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    } else {
                        Text(AppStrings.Conflicts.noAnalysisYet)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                ActionButton(
                    title: AppStrings.Conflicts.checkNow,
                    action: onCheckConflicts,
                    style: summary.requiresAttention ? .warning : .primary
                )
                .frame(width: 120)
            }
            
            // Statistics
            HStack(spacing: AppTheme.Spacing.large) {
                ConflictStatistic(
                    title: AppStrings.Conflicts.totalConflicts,
                    value: "\(summary.totalConflicts)",
                    color: summary.hasAnyConflicts ? AppTheme.Colors.warning : AppTheme.Colors.success,
                    icon: AppIcons.conflicts
                )
                
                ConflictStatistic(
                    title: AppStrings.Conflicts.criticalConflicts,
                    value: "\(summary.criticalConflicts)",
                    color: summary.criticalConflicts > 0 ? AppTheme.Colors.error : AppTheme.Colors.success,
                    icon: AppIcons.critical
                )
                
                ConflictStatistic(
                    title: AppStrings.Conflicts.medicationsInvolved,
                    value: "\(summary.totalSubstancesInvolved)",
                    color: AppTheme.Colors.primary,
                    icon: AppIcons.medications
                )
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(summary.requiresAttention ? AppTheme.Colors.warningBackground : AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(
                    summary.requiresAttention ? AppTheme.Colors.warning : AppTheme.Colors.cardBorder,
                    lineWidth: summary.requiresAttention ? 2 : 1
                )
        )
        .shadow(
            color: AppTheme.Shadow.large.color,
            radius: AppTheme.Shadow.large.radius,
            x: AppTheme.Shadow.large.x,
            y: AppTheme.Shadow.large.y
        )
    }
}

struct ConflictStatistic: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack(spacing: AppTheme.Spacing.extraSmall) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(value)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Critical Conflicts Section
struct CriticalConflictsSection: View {
    let conflicts: [MedicationConflict]
    let onConflictTap: (MedicationConflict) -> Void
    let onResolveConflict: (MedicationConflict) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: AppIcons.critical)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.error)
                
                Text(AppStrings.Conflicts.criticalConflicts)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                Text(AppStrings.Conflicts.requiresAttention)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.error)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.extraSmall)
                    .background(AppTheme.Colors.errorBackground)
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(conflicts, id: \.id) { conflict in
                    ConflictCard(
                        conflict: conflict,
                        onTap: { onConflictTap(conflict) },
                        onResolve: { onResolveConflict(conflict) },
                        showResolveAction: !conflict.isResolved
                    )
                }
            }
        }
    }
}

// MARK: - All Conflicts Section
struct AllConflictsSection: View {
    let conflicts: [MedicationConflict]
    let onConflictTap: (MedicationConflict) -> Void
    let onFilterChange: (ConflictFilter) -> Void
    @State private var selectedFilter: ConflictFilter = .all
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(AppStrings.Conflicts.allConflicts)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                // Filter Picker
                Picker(AppStrings.Common.filter, selection: $selectedFilter) {
                    ForEach(ConflictFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedFilter) { _, newFilter in
                    onFilterChange(newFilter)
                }
            }
            
            if conflicts.isEmpty {
                CompactEmptyState(
                    icon: AppIcons.conflicts,
                    message: AppStrings.Conflicts.noConflictsForFilter
                )
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(conflicts, id: \.id) { conflict in
                        ConflictCard(
                            conflict: conflict,
                            onTap: { onConflictTap(conflict) },
                            onResolve: nil,
                            showResolveAction: false
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Conflict Card
struct ConflictCard: View {
    let conflict: MedicationConflict
    let onTap: () -> Void
    let onResolve: (() -> Void)?
    let showResolveAction: Bool
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                        HStack(spacing: AppTheme.Spacing.small) {
                            Image(systemName: conflict.highestSeverity.icon)
                                .font(.system(size: 14))
                                .foregroundColor(severityColor)
                            
                            Text(conflict.displaySummary)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.primaryText)
                                .lineLimit(1)
                        }
                        
                        Text(AppStrings.Conflicts.analyzedBySource(conflict.source.displayName))
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.extraSmall) {
                        Text(conflict.highestSeverity.displayName)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(severityColor)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.vertical, AppTheme.Spacing.extraSmall)
                            .background(severityColor.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.small)
                        
                        if conflict.isResolved {
                            Text(AppStrings.Conflicts.resolved)
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                    }
                }
                
                // Involved Medications
                MedicationsInvolvedView(
                    medications: conflict.medications,
                    supplements: conflict.supplements
                )
                
                // Quick Info
                if conflict.hasActionableRecommendations {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: AppIcons.recommendations)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text(AppStrings.Conflicts.recommendationsCount(conflict.recommendations.count))
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text(conflict.createdAt.formatted(.relative(presentation: .numeric)))
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                }
                
                // Action Button
                if showResolveAction, let onResolve = onResolve {
                    HStack {
                        Spacer()
                        
                        CompactActionButton(
                            title: AppStrings.Conflicts.markResolved,
                            action: onResolve,
                            style: .success
                        )
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(cardBackgroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityColor: Color {
        switch conflict.highestSeverity {
        case .low:
            return AppTheme.Colors.success
        case .medium:
            return AppTheme.Colors.warning
        case .high:
            return AppTheme.Colors.error
        case .critical:
            return AppTheme.Colors.critical
        }
    }
    
    private var cardBackgroundColor: Color {
        if conflict.isResolved {
            return AppTheme.Colors.successBackground
        } else if conflict.requiresUrgentAttention {
            return AppTheme.Colors.errorBackground
        } else {
            return AppTheme.Colors.cardBackground
        }
    }
    
    private var borderColor: Color {
        if conflict.requiresUrgentAttention {
            return AppTheme.Colors.error
        } else {
            return AppTheme.Colors.cardBorder
        }
    }
    
    private var borderWidth: CGFloat {
        conflict.requiresUrgentAttention ? 2.0 : 1.0
    }
}

// MARK: - Medications Involved View
struct MedicationsInvolvedView: View {
    let medications: [String]
    let supplements: [String]
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: AppIcons.medications)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(involvementText)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .lineLimit(2)
            
            Spacer()
        }
    }
    
    private var involvementText: String {
        var components: [String] = []
        
        if !medications.isEmpty {
            if medications.count == 1 {
                components.append(medications.first!)
            } else {
                components.append(AppStrings.Conflicts.medicationCountValue(medications.count))
            }
        }
        
        if !supplements.isEmpty {
            if supplements.count == 1 {
                components.append(supplements.first!)
            } else {
                components.append(AppStrings.Conflicts.supplementCountValue(supplements.count))
            }
        }
        
        return components.joined(separator: " + ")
    }
}

// MARK: - Conflict Education Section
struct ConflictEducationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Conflicts.educationalInfo)
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            VStack(spacing: AppTheme.Spacing.small) {
                EducationCard(
                    icon: AppIcons.ai,
                    title: AppStrings.Conflicts.aiPowered,
                    description: AppStrings.Conflicts.aiPoweredDescription
                )
                
                EducationCard(
                    icon: AppIcons.realtime,
                    title: AppStrings.Conflicts.realtimeChecking,
                    description: AppStrings.Conflicts.realtimeCheckingDescription
                )
                
                EducationCard(
                    icon: AppIcons.medical,
                    title: AppStrings.Conflicts.medicalGuidance,
                    description: AppStrings.Conflicts.medicalGuidanceDescription
                )
            }
        }
    }
}

struct EducationCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(description)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(3)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.infoBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Conflict Filter
enum ConflictFilter: String, CaseIterable {
    case all = "all"
    case critical = "critical"
    case high = "high"
    case unresolved = "unresolved"
    case resolved = "resolved"
    case recent = "recent"
    
    var displayName: String {
        switch self {
        case .all:
            return AppStrings.Common.all
        case .critical:
            return AppStrings.Conflicts.critical
        case .high:
            return AppStrings.Conflicts.high
        case .unresolved:
            return AppStrings.Conflicts.unresolved
        case .resolved:
            return AppStrings.Conflicts.resolved
        case .recent:
            return AppStrings.Conflicts.recent
        }
    }
}

#Preview {
    ConflictsView()
}
