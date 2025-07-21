import SwiftUI

struct ConflictsContent: View {
    let analysis: ClaudeAIClient.ConflictAnalysis
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ForEach(analysis.conflicts, id: \.id) { conflict in
                DetailedConflictCard(conflict: conflict)
            }
        }
    }
}

// MARK: - Detailed Conflict Card

struct DetailedConflictCard: View {
    let conflict: ClaudeAIClient.DrugConflict
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Header
            HStack {
                // Severity Icon
                Image(systemName: severityIcon)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(severityColor)
                
                // Drug Names
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("\(conflict.drug1) + \(conflict.drug2)")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.onBackground)
                    
                    Text(conflict.severity.rawValue.capitalized)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(severityColor)
                }
                
                Spacer()
                
                // Expand/Collapse Button
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            
            // Description
            Text(conflict.description)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .lineLimit(isExpanded ? nil : 2)
            
            // Expanded Details
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    // Mechanism
                    if let mechanism = conflict.mechanism {
                        DetailRow(
                            title: AppStrings.Conflicts.mechanism,
                            content: mechanism
                        )
                    }
                    
                    // Clinical Significance
                    if let significance = conflict.clinicalSignificance {
                        DetailRow(
                            title: AppStrings.Conflicts.clinicalSignificance,
                            content: significance
                        )
                    }
                    
                    // Management
                    if let management = conflict.management {
                        DetailRow(
                            title: AppStrings.Conflicts.management,
                            content: management
                        )
                    }
                    
                    // References
                    if !conflict.references.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                            Text(AppStrings.Conflicts.references)
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            
                            ForEach(conflict.references, id: \.self) { reference in
                                Text("• \(reference)")
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                            }
                        }
                    }
                }
                .padding(.top, AppTheme.Spacing.small)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .animation(AppTheme.Animation.standard, value: isExpanded)
    }
    
    private var severityIcon: String {
        switch conflict.severity {
        case .critical: return AppIcons.conflictCritical
        case .high: return AppIcons.conflictHigh
        case .medium: return AppIcons.conflictMedium
        case .low: return AppIcons.conflictLow
        case .none: return AppIcons.info
        }
    }
    
    private var severityColor: Color {
        conflict.severity.color
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(title)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Text(content)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.onBackground)
        }
    }
}
