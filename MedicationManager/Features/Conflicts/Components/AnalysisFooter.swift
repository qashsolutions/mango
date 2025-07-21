import SwiftUI

struct AnalysisFooter: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Disclaimer
            DisclaimerCard()
            
            // Source Attribution
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: AppIcons.ai)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Text(AppStrings.AI.analysisAttribution)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .padding(.top, AppTheme.Spacing.small)
        }
        .padding(.top, AppTheme.Spacing.extraLarge)
    }
}

// MARK: - Disclaimer Card

struct DisclaimerCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: AppIcons.info)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.warning)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.AI.importantNote)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.warning)
                    .fontWeight(.medium)
                
                Text(AppStrings.AI.disclaimer)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(nil)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.warning.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}