import SwiftUI

struct AnalysisHeaderCard: View {
    let analysis: ClaudeAIClient.ConflictAnalysis
    let query: String?
    let fromCache: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Severity Badge
            ConflictSeverityBadge(
                severity: ConflictSeverity(from: analysis.overallSeverity),
                size: .large
            )
            
            // Query Text if available
            if let query = query {
                Text(query)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.onBackground)
                    .multilineTextAlignment(.center)
            }
            
            // Metadata
            HStack(spacing: AppTheme.Spacing.large) {
                MetadataItem(
                    icon: AppIcons.ai,
                    text: AppStrings.AI.poweredByClaude
                )
                
                MetadataItem(
                    icon: AppIcons.schedule,
                    text: analysis.timestamp.formatted(.relative(presentation: .named))
                )
                
                if fromCache {
                    MetadataItem(
                        icon: AppIcons.cached,
                        text: AppStrings.AI.cached
                    )
                }
            }
            .font(AppTheme.Typography.caption1)
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
}

// MARK: - Supporting Views

struct MetadataItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: icon)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Text(text)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
    }
}
