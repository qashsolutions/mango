import SwiftUI

struct SummaryContent: View {
    let analysis: ClaudeAIClient.ConflictAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(analysis.summary)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.onBackground)
                .lineLimit(nil)
            
            // Quick Stats
            HStack(spacing: AppTheme.Spacing.large) {
                QuickStat(
                    label: AppStrings.Conflicts.medications,
                    value: "\(analysis.medications.count)",
                    icon: AppIcons.medications
                )
                
                // Calculate supplements count from analyzed medications
                let supplementsCount = 0 // This would need to be passed or calculated
                QuickStat(
                    label: AppStrings.Conflicts.supplements,
                    value: "\(supplementsCount)",
                    icon: AppIcons.supplements
                )
                
                if analysis.requiresDoctor {
                    QuickStat(
                        label: AppStrings.AI.consultDoctor,
                        value: AppStrings.Common.yes,
                        icon: AppIcons.doctors,
                        valueColor: AppTheme.Colors.warning
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickStat: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = AppTheme.Colors.primary
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: icon)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundColor(valueColor)
            
            Text(label)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}