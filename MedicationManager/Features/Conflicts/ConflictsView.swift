import SwiftUI

struct ConflictsView: View {
    @State private var viewModel = ConflictsViewModel()
    @State private var showingCheckConfirmation: Bool = false
    @State private var showingVoiceQuery: Bool = false
    @State private var showingAnalysisHistory: Bool = false
    @State private var showingSiriTips: Bool = false
    @State private var navigationPath = NavigationPath()
    // Use singletons directly - they manage their own lifecycle with @Observable
    private let navigationManager = NavigationManager.shared
    private let siriManager = SiriIntentsManager.shared
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                contentView
                
                // Floating Voice Button
                if !viewModel.isAnalyzing && !viewModel.isLoading {
                    FloatingVoiceCommandButton(
                        action: {
                            showingVoiceQuery = true
                            AnalyticsManager.shared.trackFeatureUsed("voice_conflict_check")
                        },
                        context: .conflictQuery
                    )
                }
            }
            .navigationTitle(AppStrings.TabTitles.conflicts)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        // Siri Button
                        if #available(iOS 18.0, *) {
                            Button(action: { showingSiriTips = true }) {
                                Image(systemName: AppIcons.siri)
                                    .font(AppTheme.Typography.callout)
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                        }
                        
                        // History Button
                        if viewModel.hasCachedResults {
                            Button(action: { showingAnalysisHistory = true }) {
                                Image(systemName: AppIcons.history)
                                    .font(AppTheme.Typography.callout)
                            }
                        }
                        
                        // Manual Check Button
                        Button(action: { showingCheckConfirmation = true }) {
                            Image(systemName: AppIcons.conflicts)
                                .font(AppTheme.Typography.callout)
                        }
                        .disabled(viewModel.isAnalyzing)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .onAppear {
                // TODO: Fix DynamicShortcutsManager reference - class not found
                // DynamicShortcutsManager.trackConflictViewOpened()
                // Update Siri shortcuts based on user behavior
                if FirebaseManager.shared.currentUser?.id != nil {
                    Task {
                        // TODO: Fix DynamicShortcutsManager reference - class not found
                        // await DynamicShortcutsManager.shared.updateShortcuts(for: userId)
                    }
                }
            }
            .sheet(isPresented: $showingVoiceQuery) {
                VoiceQueryView(
                    onAnalyze: { query in
                        Task {
                            await viewModel.analyzeQuery(query)
                            // Donate intent after voice query
                            siriManager.donateIntent(for: .voiceQuery(query))
                        }
                    }
                )
            }
            .sheet(isPresented: $showingAnalysisHistory) {
                ConflictHistoryView(
                    analysisHistory: viewModel.analysisHistory,
                    onSelectAnalysis: { analysis in
                        viewModel.currentAnalysis = analysis
                        showingAnalysisHistory = false
                    }
                )
            }
            .sheet(isPresented: $showingSiriTips) {
                // TODO: Fix SiriTipsView reference - class not found
                // if #available(iOS 18.0, *) {
                //     SiriTipsView()
                //         .presentationDetents([.large])
                //         .presentationDragIndicator(.visible)
                //         .overlay(alignment: .top) {
                //             HStack {
                //                 Text(AppStrings.Siri.siriTipsTitle)
                //                     .font(AppTheme.Typography.headline)
                //                 Spacer()
                //                 Button(AppStrings.Common.done) {
                //                     showingSiriTips = false
                //                 }
                //                 .font(AppTheme.Typography.body)
                //                 .foregroundColor(AppTheme.Colors.primary)
                //             }
                //             .padding()
                //         }
                // }
                EmptyView()
            }
            .navigationDestination(for: ConflictDetectionManager.MedicationConflictAnalysis.self) { analysis in
                ConflictAnalysisView(analysis: analysis)
            }
            .alert(AppStrings.Conflicts.checkConfirmation, isPresented: $showingCheckConfirmation) {
                Button(AppStrings.Common.analyze) {
                    Task {
                        await viewModel.checkForConflicts()
                        // Donate intent after conflict check
                        siriManager.donateIntent(for: .checkConflicts)
                        // TODO: Fix DynamicShortcutsManager reference - class not found
                        // DynamicShortcutsManager.trackConflictAnalysisCompleted()
                    }
                }
                Button(AppStrings.Common.cancel, role: .cancel) {}
            } message: {
                Text(AppStrings.Conflicts.checkConfirmationMessage)
            }
            .alert(
                AppStrings.Errors.title,
                isPresented: Binding<Bool>(
                    get: { viewModel.error != nil },
                    set: { _ in viewModel.clearError() }
                )
            ) {
                Button(AppStrings.Common.ok) {
                    viewModel.clearError()
                }
                if viewModel.error?.isRetryable == true {
                    Button(AppStrings.Common.retry) {
                        Task {
                            await viewModel.retryLastAction()
                        }
                    }
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? AppStrings.ErrorMessages.genericError)
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView()
            } else if viewModel.isAnalyzing {
                analyzingView()
            } else {
                mainContentView()
            }
        }
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: AppTheme.Spacing.large) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
            
            Text(AppStrings.Common.loading)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Analyzing View
    private func analyzingView() -> some View {
        VStack(spacing: AppTheme.Spacing.large) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
            
            if viewModel.voiceQueryText.isEmpty {
                Text(AppStrings.AI.analyzingMedications)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            } else {
                Text(AppStrings.AI.analyzingQuery)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private func mainContentView() -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.large) {
                // Voice Query Section
                if Configuration.Voice.showVoicePrompt {
                    VoiceQueryPromptCard(onTap: {
                        showingVoiceQuery = true
                    })
                }
                
                // Current Analysis Result
                if let analysis = viewModel.currentAnalysis {
                    let medicationConflict = MedicationConflict.fromAnalysis(
                        analysis,
                        userId: FirebaseManager.shared.currentUser?.id ?? ""
                    )
                    AIAnalysisCard(
                        analysis: medicationConflict,
                        onViewDetails: {
                            navigationPath.append(analysis)
                        },
                        onDismiss: {
                            withAnimation {
                                viewModel.currentAnalysis = nil
                            }
                        }
                    )
                }
                
                // Conflict Summary Header
                ConflictSummaryHeader(
                    summary: viewModel.conflictSummary,
                    onCheckConflicts: {
                        showingCheckConfirmation = true
                        AnalyticsManager.shared.trackFeatureUsed("conflict_check_button")
                    }
                )
                
                if viewModel.conflicts.isEmpty {
                    emptyStateView()
                } else {
                    // Critical Conflicts Section
                    if !viewModel.criticalConflicts.isEmpty {
                        CriticalConflictsSection(
                            conflicts: viewModel.criticalConflicts,
                            onResolveConflict: { conflict in
                                Task {
                                    await viewModel.resolveConflict(conflict)
                                }
                            }
                        )
                    }
                    
                    // All Conflicts Section
                    AllConflictsSection(
                        conflicts: viewModel.filteredConflicts,
                        currentFilter: viewModel.currentFilter,
                        filterCounts: viewModel.filterCounts,
                        onFilterChange: { filter in
                            viewModel.updateFilter(filter)
                        }
                    )
                }
                
                // Educational Section
                ConflictEducationSection()
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.extraLarge + 80) // Extra space for floating button
        }
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private func emptyStateView() -> some View {
        ConflictEmptyState(
            onCheckConflicts: {
                showingCheckConfirmation = true
            }
        )
        .padding(.vertical, AppTheme.Spacing.extraLarge)
    }
}

// MARK: - Voice Query Prompt Card
struct VoiceQueryPromptCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: AppIcons.voiceInput)
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.voiceActive)
                    .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                    .background(AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.low))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(AppStrings.Voice.askAboutMedications)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text(AppStrings.Voice.exampleQueries)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: AppIcons.chevronRight)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.voiceActive.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.low), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Updated Conflict Summary Header
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
                
                Button(action: onCheckConflicts) {
                    HStack(spacing: AppTheme.Spacing.extraSmall) {
                        Image(systemName: AppIcons.conflicts)
                            .font(AppTheme.Typography.caption)
                        Text(AppStrings.Conflicts.checkNow)
                            .font(AppTheme.Typography.caption1)
                    }
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.extraSmall)
                    .foregroundColor(AppTheme.Colors.onPrimary)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .buttonStyle(PlainButtonStyle())
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
                    .font(AppTheme.Typography.caption)
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

// MARK: - Updated All Conflicts Section
struct AllConflictsSection: View {
    let conflicts: [MedicationConflict]
    let currentFilter: ConflictFilterType
    let filterCounts: [ConflictFilterType: Int]
    let onFilterChange: (ConflictFilterType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(AppStrings.Conflicts.allConflicts)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                // Filter Menu
                Menu {
                    ForEach(ConflictFilterType.allCases, id: \.self) { filter in
                        Button(action: { onFilterChange(filter) }) {
                            HStack {
                                Text(filter.displayName)
                                if let count = filterCounts[filter] {
                                    Spacer()
                                    Text("\(count)")
                                        .foregroundColor(AppTheme.Colors.secondaryText)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.extraSmall) {
                        Text(currentFilter.displayName)
                            .font(AppTheme.Typography.caption1)
                        Image(systemName: AppIcons.chevronDown)
                            .font(AppTheme.Typography.caption)
                    }
                    .foregroundColor(AppTheme.Colors.primary)
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
                            onResolve: nil,
                            showResolveAction: false
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Critical Conflicts Section (unchanged)
struct CriticalConflictsSection: View {
    let conflicts: [MedicationConflict]
    let onResolveConflict: (MedicationConflict) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: AppIcons.critical)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.error)
                
                Text(AppStrings.Conflicts.criticalConflicts)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                SeverityAlertBanner(
                    severity: .critical,
                    message: AppStrings.Conflicts.requiresAttention,
                    onDismiss: nil
                )
            }
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(conflicts, id: \.id) { conflict in
                    ConflictCard(
                        conflict: conflict,
                        onResolve: { onResolveConflict(conflict) },
                        showResolveAction: !conflict.isResolved
                    )
                }
            }
        }
    }
}

// MARK: - Updated Conflict Card
struct ConflictCard: View {
    let conflict: MedicationConflict
    let onResolve: (() -> Void)?
    let showResolveAction: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        ConflictSeverityBadge(
                            severity: conflict.highestSeverity,
                            size: .small,
                            showLabel: false
                        )
                        
                        Text(conflict.displaySummary)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: AppIcons.ai)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        Text(AppStrings.Conflicts.analyzedBySource(conflict.source.displayName))
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.extraSmall) {
                    ConflictSeverityBadge(
                        severity: conflict.highestSeverity,
                        size: .small
                    )
                    
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
                        .font(AppTheme.Typography.caption)
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
                    
                    Button(action: onResolve) {
                        Text(AppStrings.Conflicts.markResolved)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.onPrimary)
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.vertical, AppTheme.Spacing.small)
                            .background(AppTheme.Colors.success)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
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

// MARK: - Medications Involved View (unchanged)
struct MedicationsInvolvedView: View {
    let medications: [String]
    let supplements: [String]
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: AppIcons.medications)
                .font(AppTheme.Typography.caption)
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
            if medications.count == 1, let firstMedication = medications.first {
                components.append(firstMedication)
            } else {
                components.append(AppStrings.Conflicts.medicationCountValue(medications.count))
            }
        }
        
        if !supplements.isEmpty {
            if supplements.count == 1, let firstSupplement = supplements.first {
                components.append(firstSupplement)
            } else {
                components.append(AppStrings.Conflicts.supplementCountValue(supplements.count))
            }
        }
        
        return components.joined(separator: " + ")
    }
}

// MARK: - Updated Conflict Education Section
struct ConflictEducationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Conflicts.educationalInfo)
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            VStack(spacing: AppTheme.Spacing.small) {
                EducationCard(
                    icon: AppIcons.ai,
                    title: AppStrings.AI.poweredByClaude,
                    description: AppStrings.AI.claudeDescription
                )
                
                EducationCard(
                    icon: AppIcons.voiceInput,
                    title: AppStrings.Voice.voiceFirst,
                    description: AppStrings.Voice.voiceFirstDescription
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
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
            
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
        .background(AppTheme.Colors.primaryBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

#Preview {
    ConflictsView()
}
