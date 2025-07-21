import SwiftUI

struct RecommendationsContent: View {
    let analysis: ClaudeAIClient.ConflictAnalysis
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(Array(analysis.recommendations.enumerated()), id: \.offset) { index, recommendation in
                RecommendationRow(
                    recommendation: recommendation,
                    index: index + 1
                )
            }
        }
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let recommendation: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            // Number Badge
            Text("\(index)")
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.onPrimary)
                .frame(width: 24, height: 24)
                .background(AppTheme.Colors.primary)
                .clipShape(Circle())
            
            // Recommendation Text
            Text(recommendation)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.onBackground)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}