import SwiftUI

struct AIAnalysisCard: View {
    let analysis: MedicationConflict
    let onViewDetails: () -> Void
    let onDismiss: (() -> Void)?
    
    @State private var isExpanded: Bool = false
    @State private var showingShareSheet: Bool = false
    private let analyticsManager = AnalyticsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            cardHeader()
            
            // Content
            if isExpanded {
                expandedContent()
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                collapsedContent()
            }
            
            // Actions
            cardActions()
        }
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(
            color: AppTheme.Shadow.medium.color,
            radius: AppTheme.Shadow.medium.radius,
            x: AppTheme.Shadow.medium.x,
            y: AppTheme.Shadow.medium.y
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Header
    @ViewBuilder
    private func cardHeader() -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // AI Icon
            Image(systemName: AppIcons.ai)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                .background(AppTheme.Colors.primaryBackground)
                .clipShape(Circle())
            
            // Title and timestamp
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(AppStrings.AI.analysisTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    if analysis.createdAt < Date().addingTimeInterval(-3600) { // Show cached if older than 1 hour
                        CacheBadge()
                    }
                }
                
                Text(analysis.createdAt.formatted(.relative(presentation: .named)))
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            // Severity badge
            ConflictSeverityBadge(
                severity: analysis.severity ?? .none,
                size: .small
            )
            
            // Expand/collapse button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
                if isExpanded {
                    analyticsManager.trackFeatureUsed("ai_analysis_expanded")
                }
            }) {
                Image(systemName: isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
                    .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
            }
        }
        .padding(AppTheme.Spacing.medium)
    }
    
    // MARK: - Collapsed Content
    @ViewBuilder
    private func collapsedContent() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Summary
            Text(analysis.educationalInfo ?? AppStrings.Conflicts.noAnalysisYet)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(3)
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            // Quick stats
            HStack(spacing: AppTheme.Spacing.large) {
                StatItem(
                    icon: AppIcons.conflicts,
                    value: "\(analysis.conflictDetails.count)",
                    label: AppStrings.Conflicts.conflictsDetected
                )
                
                if !analysis.recommendations.isEmpty {
                    StatItem(
                        icon: AppIcons.info,
                        value: "\(analysis.recommendations.count)",
                        label: AppStrings.AI.recommendations
                    )
                }
                
                if analysis.severity == .high || analysis.severity == .critical {
                    StatItem(
                        icon: AppIcons.doctors,
                        value: "!",
                        label: AppStrings.AI.consultDoctor
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.medium)
        }
    }
    
    // MARK: - Expanded Content
    @ViewBuilder
    private func expandedContent() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            // Full summary
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.AI.summary)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Text(analysis.educationalInfo ?? AppStrings.Conflicts.noAnalysisYet)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            
            // Conflicts
            if !analysis.conflictDetails.isEmpty {
                conflictsList()
            }
            
            // Recommendations
            if !analysis.recommendations.isEmpty {
                recommendationsList()
            }
            
            // Additional information (using summary as additional info)
            if let educationalInfo = analysis.educationalInfo, !educationalInfo.isEmpty {
                AdditionalInfoSection(info: educationalInfo)
            }
            
            // Disclaimer
            DisclaimerSection()
        }
        .padding(.bottom, AppTheme.Spacing.medium)
    }
    
    // MARK: - Conflicts List
    @ViewBuilder
    private func conflictsList() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Conflicts.detectedConflicts)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(Array(analysis.conflictDetails.enumerated()), id: \.offset) { index, conflict in
                    ConflictDetailRow(conflict: conflict)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
    }
    
    // MARK: - Recommendations List
    @ViewBuilder
    private func recommendationsList() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.AI.recommendations)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ForEach(analysis.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                        Image(systemName: AppIcons.info)
                            .font(AppTheme.Typography.footnote)
                            .foregroundColor(AppTheme.Colors.info)
                            .padding(.top, 2)
                        
                        Text(recommendation)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .lineLimit(nil)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
    }
    
    // MARK: - Card Actions
    @ViewBuilder
    private func cardActions() -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Button(action: {
                onViewDetails()
                analyticsManager.trackFeatureUsed("ai_analysis_view_details")
            }) {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: AppIcons.info)
                        .font(AppTheme.Typography.footnote)
                    Text(AppStrings.Common.viewDetails)
                        .font(AppTheme.Typography.caption1)
                }
                .foregroundColor(AppTheme.Colors.primary)
            }
            
            Spacer()
            
            Button(action: {
                showingShareSheet = true
                analyticsManager.trackFeatureUsed("ai_analysis_share")
            }) {
                Image(systemName: AppIcons.share)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: AppIcons.close)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.inputBackground)
    }
}

// MARK: - Supporting Views
struct CacheBadge: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.tiny) {
            Image(systemName: AppIcons.cached)
                .font(AppTheme.Typography.caption)
            Text(AppStrings.AI.cached)
                .font(AppTheme.Typography.caption2)
        }
        .foregroundColor(AppTheme.Colors.secondaryText)
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(AppTheme.Colors.inputBackground)
        )
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.extraSmall) {
            HStack(spacing: AppTheme.Spacing.extraSmall) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text(value)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
            }
            
            Text(label)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
    }
}

struct ConflictRow: View {
    let conflict: ClaudeAIClient.DrugConflict
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            ConflictSeverityBadge(
                severity: ConflictSeverity(rawValue: conflict.severity.rawValue) ?? .medium,
                size: .small,
                showLabel: false
            )
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(conflict.drug1)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Image(systemName: AppIcons.conflicts)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                    
                    Text(conflict.drug2)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                }
                
                Text(conflict.description)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill((ConflictSeverity(rawValue: conflict.severity.rawValue) ?? .medium).color.opacity(AppTheme.Opacity.medium))
        )
    }
}

struct ConflictDetailRow: View {
    let conflict: ConflictDetail
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            ConflictSeverityBadge(
                severity: conflict.severity,
                size: .small,
                showLabel: false
            )
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(conflict.displayTitle)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(conflict.description)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(2)
                
                if let management = conflict.management {
                    Text(management)
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(conflict.severity.color.opacity(AppTheme.Opacity.medium))
        )
    }
}

struct AdditionalInfoSection: View {
    let info: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.AI.additionalInfo)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Text(info)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.primaryText)
                .padding(AppTheme.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(AppTheme.Colors.inputBackground)
                )
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }
}

struct DisclaimerSection: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Image(systemName: AppIcons.info)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.warning)
            
            Text(AppStrings.AI.disclaimer)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .lineLimit(nil)
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.warningBackground)
        )
        .padding(.horizontal, AppTheme.Spacing.medium)
    }
}

// MARK: - AI Analysis Summary Card
struct AIAnalysisSummaryCard: View {
    let analysisCount: Int
    let lastAnalysis: Date?
    let onViewHistory: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: AppIcons.ai)
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text(AppStrings.AI.aiPoweredAnalysis)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                Image(systemName: AppIcons.claudeSonnet)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            HStack(spacing: AppTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text("\(analysisCount)")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .fontWeight(.semibold)
                    
                    Text(AppStrings.AI.totalAnalyses)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                if let lastAnalysis = lastAnalysis {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                        Text(lastAnalysis.formatted(.relative(presentation: .named)))
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        Text(AppStrings.AI.lastAnalysis)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            Button(action: onViewHistory) {
                HStack {
                    Text(AppStrings.AI.viewHistory)
                        .font(AppTheme.Typography.caption1)
                    Image(systemName: AppIcons.chevronRight)
                        .font(AppTheme.Typography.caption)
                }
                .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(
            color: AppTheme.Shadow.small.color,
            radius: AppTheme.Shadow.small.radius,
            x: AppTheme.Shadow.small.x,
            y: AppTheme.Shadow.small.y
        )
    }
}

// MARK: - Loading Analysis Card
struct LoadingAnalysisCard: View {
    let message: String
    
    @State private var dots: String = ""
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            HStack(spacing: AppTheme.Spacing.medium) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(message + dots)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text(AppStrings.AI.pleaseWait)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            // AI indicator
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: AppIcons.ai)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text(AppStrings.AI.poweredByClaude)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .onAppear {
            animateDots()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func animateDots() {
        // Note: No [weak self] needed here because LoadingAnalysisCard is a struct (value type).
        // Structs don't create retain cycles like classes do. The timer will be properly
        // invalidated in onDisappear, preventing any potential issues.
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    dots = dots.count < 3 ? dots + "." : ""
                }
            }
        }
    }
}

struct AIAnalysisCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Sample analysis card
                #if DEBUG
                AIAnalysisCard(
                    analysis: MedicationConflict.sampleConflict,
                    onViewDetails: {},
                    onDismiss: {}
                )
                #endif
                
                // Summary card
                AIAnalysisSummaryCard(
                    analysisCount: 12,
                    lastAnalysis: Date().addingTimeInterval(-3600),
                    onViewHistory: {}
                )
                
                // Loading card
                LoadingAnalysisCard(
                    message: AppStrings.AI.checkingInteractions
                )
            }
            .padding()
        }
        .background(AppTheme.Colors.background)
    }
}
