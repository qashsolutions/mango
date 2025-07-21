import SwiftUI

struct ActionsSection: View {
    let analysis: ClaudeAIClient.ConflictAnalysis
    @State private var showingShareSheet = false
    @State private var showingExportOptions = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Primary Actions
            if analysis.requiresDoctor {
                ConflictActionButton(
                    title: AppStrings.AI.consultDoctor,
                    icon: AppIcons.doctors,
                    style: .primary,
                    action: consultDoctor
                )
            }
            
            // Secondary Actions
            HStack(spacing: AppTheme.Spacing.medium) {
                ActionButton(
                    title: AppStrings.Common.share,
                    action: { showingShareSheet = true },
                    style: .secondary
                )
                
                ActionButton(
                    title: AppStrings.Common.export,
                    action: { showingExportOptions = true },
                    style: .secondary
                )
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareText = generateShareText() {
                ShareSheet(items: [shareText])
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(analysis: analysis)
        }
    }
    
    private func consultDoctor() {
        // Navigate to doctor list or send analysis
        AnalyticsManager.shared.trackFeatureUsed("consult_doctor_from_analysis")
    }
    
    private func generateShareText() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var shareText = AppStrings.AI.analysisReport + "\n"
        shareText += "Date: \(dateFormatter.string(from: analysis.timestamp))\n\n"
        shareText += "Summary:\n\(analysis.summary)\n\n"
        
        if !analysis.conflicts.isEmpty {
            shareText += "Conflicts Found: \(analysis.conflicts.count)\n"
            for conflict in analysis.conflicts {
                shareText += "• \(conflict.drug1) + \(conflict.drug2): \(conflict.description)\n"
            }
            shareText += "\n"
        }
        
        if !analysis.recommendations.isEmpty {
            shareText += "Recommendations:\n"
            for (index, recommendation) in analysis.recommendations.enumerated() {
                shareText += "\(index + 1). \(recommendation)\n"
            }
        }
        
        shareText += "\n" + AppStrings.AI.disclaimer
        
        return shareText
    }
}

// MARK: - Action Button

private struct ConflictActionButton: View {
    enum ButtonStyle {
        case primary
        case secondary
        case danger
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppTheme.Colors.primary
            case .secondary: return AppTheme.Colors.surface
            case .danger: return AppTheme.Colors.error
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return AppTheme.Colors.onPrimary
            case .secondary: return AppTheme.Colors.onBackground
            case .danger: return AppTheme.Colors.onError
            }
        }
    }
    
    let title: String
    let icon: String
    let style: ButtonStyle
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(AppTheme.Typography.body)
                
                Text(title)
                    .font(AppTheme.Typography.body)
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.medium)
            .background(style.backgroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(
                        style == .secondary ? AppTheme.Colors.divider : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}